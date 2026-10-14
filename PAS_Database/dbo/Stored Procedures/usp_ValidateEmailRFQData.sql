/*************************************************************
 ** File:   [usp_ValidateEmailRFQData]
 ** Author:  Bhargav Saliya
 ** Description: Validates RFQ data extracted from (or corrected on) an IntegrationEmail BEFORE any RFQ is created.
 **              Returns one row: [ErrorMessage] = NULL when valid, otherwise all specific reasons joined by '; '.
 ** Purpose:     RFQ Email List - Error Message / Edit / Re-Sync
 ** Date:   12 Oct 2026
 **************************************************************
 ** Change History
 **************************************************************
 ** PR   Date			Author				Change Description
 ** --   --------		-------				--------------------------------
    1    12 Oct 2026	Bhargav Saliya		Created

 -- Condition matching is the same rule usp_SaveEmailRFQ uses (Description OR Code, per MasterCompany),
 -- so an email that passes here will not silently skip SOQ creation because of the condition.
************************************************************************/
CREATE   PROCEDURE [dbo].[usp_ValidateEmailRFQData]
	@IntegrationEmailID BIGINT,
	@RfqType VARCHAR(50),
	@tbl_RfqCustomerType dbo.RfqCustomerType READONLY,
	@tbl_RfqPartDetailType dbo.RfqPartDetailType READONLY,
	@tbl_VendorRFQType dbo.VendorRFQType READONLY,
	@tbl_VendorPartRFQType dbo.VendorPartRFQType READONLY
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;
	BEGIN TRY
		DECLARE @MasterCompanyId INT;
		DECLARE @CustomerRFQType VARCHAR(50) = 'CustomerRFQ', @VendorRFQType VARCHAR(50) = 'VendorRFQ';

		DECLARE @Errors TABLE ([Seq] INT IDENTITY(1,1), [ErrorMessage] NVARCHAR(MAX));

		SELECT @MasterCompanyId = [MasterCompanyId] FROM [dbo].[IntegrationEmail] WITH(NOLOCK) WHERE [IntegrationEmailID] = @IntegrationEmailID;

		IF(@MasterCompanyId IS NULL)
		BEGIN
			INSERT INTO @Errors ([ErrorMessage]) VALUES ('Email not found');
		END
		ELSE IF(ISNULL(@RfqType, '') NOT IN (@CustomerRFQType, @VendorRFQType))
		BEGIN
			INSERT INTO @Errors ([ErrorMessage]) VALUES ('Email is not a recognised RFQ');
		END
		ELSE IF(@RfqType = @CustomerRFQType)
		BEGIN
			-- Customer
			IF NOT EXISTS(SELECT 1 FROM @tbl_RfqCustomerType
						  WHERE ISNULL(LTRIM(RTRIM([CustomerName])), '') <> '' OR ISNULL(LTRIM(RTRIM([CompanyName])), '') <> '' OR ISNULL(LTRIM(RTRIM([BuyerName])), '') <> '')
			BEGIN
				INSERT INTO @Errors ([ErrorMessage]) VALUES ('Customer is missing');
			END

			-- Part lines
			IF NOT EXISTS(SELECT 1 FROM @tbl_RfqPartDetailType)
			BEGIN
				INSERT INTO @Errors ([ErrorMessage]) VALUES ('Part Number is missing');
			END
			ELSE
			BEGIN
				;WITH Parts AS (
					SELECT ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS [LineNo],
						   LTRIM(RTRIM(ISNULL([PartNumber], ''))) AS [PartNumber], [Quantity], LTRIM(RTRIM(ISNULL([Condition], ''))) AS [Condition]
					FROM @tbl_RfqPartDetailType
				)
				INSERT INTO @Errors ([ErrorMessage])
				SELECT E.[ErrorMessage]
				FROM Parts P
				CROSS APPLY (SELECT CASE WHEN P.[PartNumber] = '' THEN 'Line ' + CAST(P.[LineNo] AS VARCHAR(10)) ELSE 'Part Number ' + P.[PartNumber] END AS [Ref]) R
				CROSS APPLY (
					SELECT 1 AS [Ord], 'Part Number is missing (Line ' + CAST(P.[LineNo] AS VARCHAR(10)) + ')' AS [ErrorMessage] WHERE P.[PartNumber] = ''
					UNION ALL
					SELECT 2, 'Quantity is missing for ' + R.[Ref] WHERE ISNULL(P.[Quantity], 0) <= 0
					UNION ALL
					SELECT 3, 'Condition is missing for ' + R.[Ref] WHERE P.[Condition] = ''
					UNION ALL
					SELECT 4, 'Unable to map Condition ''' + P.[Condition] + ''' for ' + R.[Ref]
					WHERE P.[Condition] <> ''
					  AND NOT EXISTS(SELECT 1 FROM [dbo].[Condition] CD WITH(NOLOCK)
									 WHERE CD.[MasterCompanyId] = @MasterCompanyId
									   AND (LOWER(TRIM(CD.[Description])) = LOWER(P.[Condition]) OR LOWER(TRIM(CD.[Code])) = LOWER(P.[Condition])))
				) E
				ORDER BY P.[LineNo], E.[Ord];
			END
		END
		ELSE
		BEGIN
			-- Vendor
			IF NOT EXISTS(SELECT 1 FROM @tbl_VendorRFQType WHERE ISNULL(LTRIM(RTRIM([VendorName])), '') <> '')
			BEGIN
				INSERT INTO @Errors ([ErrorMessage]) VALUES ('Vendor information is missing');
			END

			IF NOT EXISTS(SELECT 1 FROM @tbl_VendorPartRFQType)
			BEGIN
				INSERT INTO @Errors ([ErrorMessage]) VALUES ('Part Number is missing');
			END
			ELSE
			BEGIN
				INSERT INTO @Errors ([ErrorMessage])
				SELECT 'Part Number is missing (Line ' + CAST(P.[LineNo] AS VARCHAR(10)) + ')'
				FROM (SELECT ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS [LineNo], [PartNumber] FROM @tbl_VendorPartRFQType) P
				WHERE ISNULL(LTRIM(RTRIM(P.[PartNumber])), '') = ''
				ORDER BY P.[LineNo];
			END
		END

		SELECT CAST(LEFT(STRING_AGG(CAST([ErrorMessage] AS NVARCHAR(MAX)), '; ') WITHIN GROUP (ORDER BY [Seq]), 1000) AS NVARCHAR(1000)) AS [ErrorMessage]
		FROM @Errors;
	END TRY
	BEGIN CATCH
		DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
		, @AdhocComments     VARCHAR(150)    = 'usp_ValidateEmailRFQData'
		, @ProcedureParameters VARCHAR(3000) = '@IntegrationEmailID = ''' + CAST(ISNULL(@IntegrationEmailID, '') AS VARCHAR(100))
										   + '@RfqType = ''' + ISNULL(@RfqType, '')
		, @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
		EXEC spLogException
                    @DatabaseName           = @DatabaseName
                    , @AdhocComments          = @AdhocComments
                    , @ProcedureParameters = @ProcedureParameters
                    , @ApplicationName        =  @ApplicationName
                    , @ErrorLogID                    = @ErrorLogID OUTPUT ;
		RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
		RETURN(1);
	END CATCH
END
