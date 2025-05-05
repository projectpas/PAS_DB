/*************************************************************           
 ** File:		 [USP_GetLegalEntityHistory]           
 ** Author:		 Divyesh Kathiriya
 ** Description: This Stored Procedure Is Used To Get Legal Entity History.
 ** Purpose:         
 ** Date:   28-April-2025 
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date				Author				Change Description            
 ** --   -------------		----------------	--------------------------------          
    1    28-April-2025		Divyesh Kathiriya	Created
    
 -- EXEC [USP_GetLegalEntityHistory] @LegalEntityId=34, @EmployeeId=226
**************************************************************/
CREATE   PROCEDURE [DBO].[USP_GetLegalEntityHistory]
@LegalEntityId BIGINT = Null,
@EmployeeId BIGINT = Null
AS
BEGIN
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	BEGIN TRY
	
	DECLARE @CurrntEmpTimeZoneDesc VARCHAR(100) = '';
				
		SELECT 
			@CurrntEmpTimeZoneDesc = COALESCE(
				ETZ.[Description],  -- Prefer Employee's TimeZone description if available
				LTZ.[Description]   -- Fallback to LegalEntity's TimeZone description
			)
		FROM 
			dbo.Employee E WITH (NOLOCK) 
		LEFT JOIN 
			dbo.TimeZone ETZ WITH (NOLOCK) 
			ON E.TimeZoneId = ETZ.TimeZoneId
		LEFT JOIN 
			dbo.LegalEntity LE WITH (NOLOCK) 
			ON E.LegalEntityId = LE.LegalEntityId
		LEFT JOIN 
			dbo.TimeZone LTZ WITH (NOLOCK) 
			ON LE.TimeZoneId = LTZ.TimeZoneId
		WHERE 
			E.EmployeeId = @EmployeeId; -- Use appropriate filter for the specific employee


		 SELECT
			lea.[LegalEntityAuditId],
			lea.[LegalEntityId],
			ISNULL(lea.[Name], '') AS [Name],
			ISNULL(lea.[CompanyCode], '') AS CompanyCode,
			lea.[DoingLegalAs],
			lea.[AttachmentId],
			ISNULL(atd.[FileName], '') AS AttachmentName,
			ISNULL(le.[Name], '') AS MasterCompany,
			ISNULL(ad.[Line1], '') AS Address1,
			ISNULL(ad.[Line2], '') AS Address2,
			ISNULL(ad.[City], '') AS City,
			ISNULL(ad.[StateOrProvince], '') AS StateOrProvince,
			ISNULL(ad.[PostalCode], '') AS PostalCode,
			ISNULL(cont.[countries_name], '') AS Country,
			CASE WHEN lea.[InvoiceAddressPosition] != 0 THEN lea.[InvoiceAddressPosition] ELSE 0 END AS InvoiceAddressPosition,
			CASE WHEN lea.[InvoiceFaxPhonePosition] != 0 THEN lea.[InvoiceFaxPhonePosition] ELSE 0 END AS InvoiceFaxPhonePosition,
			ISNULL(lea.[FaxNumber], '') AS FaxNumber,
			ISNULL(lea.[PhoneNumber], '') AS PhoneNumber,
			ISNULL(lea.[PhoneExt], '') AS PhoneExt,
			ISNULL(cur.[DisplayName], '') AS FunctionalCurrencyName,
			ISNULL(cur.[DisplayName], '') AS ReportingCurrencyName,
			ISNULL(Led.[LedgerName], '') AS LedgerName,
			ISNULL(lea.[CageCode], '') AS CageCode,
			ISNULL(lea.[FAALicense], '') AS FAALicense,
			ISNULL(lea.[TaxId], '') AS TaxId,
			lea.[IsBalancingEntity],
			lea.[IsAddressForShipping],
			lea.[IsAddressForBilling],
			lea.[LastLevel],
			ISNULL(lea.[CreatedBy], '') AS CreatedBy,		
			CASE WHEN @EmployeeId != 0 AND @CurrntEmpTimeZoneDesc != '' THEN 
				CASE WHEN CAST(lea.[CreatedDate] AS DATE) = CAST('0001-01-01 00:00:00' AS DATE) THEN NULL ELSE (CAST(DBO.ConvertUTCtoLocal(lea.[CreatedDate], @CurrntEmpTimeZoneDesc) AS DATETIME)) END 
			ELSE (CAST(lea.[CreatedDate] AS DATETIME)) END CreatedDate,
			ISNULL(lea.[UpdatedBy], '') AS UpdatedBy,
			CASE WHEN @EmployeeId != 0 AND @CurrntEmpTimeZoneDesc != '' THEN 
				CASE WHEN CAST(lea.[UpdatedDate] AS DATE) = CAST('0001-01-01 00:00:00' AS DATE) THEN NULL ELSE (CAST(DBO.ConvertUTCtoLocal(lea.[UpdatedDate], @CurrntEmpTimeZoneDesc) AS DATETIME)) END 
			ELSE (CAST(lea.[UpdatedDate] AS DATETIME)) END UpdatedDate,
			ISNULL(atd.[Link], '') AS Link,
			lea.[IsActive],
			lea.[IsDeleted],
			ISNULL(lea.[CompanyName], '') AS CompanyName,
			ISNULL(lea.[TagName], '') AS TagName,
			ISNULL(TZ.[TimeZoneName], '') AS TimeZoneName,
			lea.[IsPrintCheckNumber]
		FROM [DBO].[LegalEntityAudit] lea WITH(NOLOCK)
		LEFT JOIN [DBO].[LegalEntity] le WITH(NOLOCK) ON lea.[LegalEntityId] = le.[LegalEntityId]
		LEFT JOIN [DBO].[Address] ad WITH(NOLOCK) ON lea.[AddressId] = ad.[AddressId]
		LEFT JOIN [DBO].[Countries] cont WITH(NOLOCK) ON ad.[CountryId] = cont.[countries_id]
		LEFT JOIN [DBO].[AttachmentDetails] atd WITH(NOLOCK) ON lea.[AttachmentId] = atd.[AttachmentId]
		LEFT JOIN [DBO].[Currency] cur WITH(NOLOCK) ON lea.[FunctionalCurrencyId] = cur.[CurrencyId]
		LEFT JOIN [DBO].[Ledger] Led WITH(NOLOCK) ON lea.[LedgerId] = Led.[LedgerId]
		LEFT JOIN [DBO].[TimeZone] TZ WITH(NOLOCK) ON lea.[TimeZoneId] = TZ.[TimeZoneId]
		WHERE
			lea.[LegalEntityId] = @LegalEntityId
		ORDER BY
			lea.[LegalEntityAuditId] DESC; 			 		  		  		 	   			   	  

	
	END TRY 
	BEGIN CATCH
	
		DECLARE @ErrorLogID INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_GetLegalEntityHistory'
			  , @ProcedureParameters VARCHAR(3000) = '@Parameter1 = '''
              , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
		EXEC spLogException @DatabaseName = @DatabaseName
			,@AdhocComments = @AdhocComments
			,@ProcedureParameters = @ProcedureParameters
			,@ApplicationName = @ApplicationName
			,@ErrorLogID = @ErrorLogID OUTPUT;

		RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)

		RETURN (1); 
	END CATCH

END