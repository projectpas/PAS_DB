/*************************************************************           
 ** File:		 [USP_GetLegalEntityShipViaAudit]           
 ** Author:		 Divyesh Kathiriya
 ** Description: This Stored Procedure Is Used To Get Legal Entity ShipVia History.
 ** Purpose:         
 ** Date:   24-June-2025 
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date				Author				Change Description            
 ** --   -------------		----------------	--------------------------------          
    1    24-June-2025		Divyesh Kathiriya	Created
    
 -- EXEC [USP_GetLegalEntityShipViaAudit] @LegalEntityId=41,@LegalEntityShippingAddressId=49,@LegalEntityShippingId=79,@EmployeeId=226
**************************************************************/
CREATE   PROCEDURE [DBO].[USP_GetLegalEntityShipViaAudit]
@LegalEntityId BIGINT,
@LegalEntityShippingAddressId BIGINT,
@LegalEntityShippingId BIGINT,
@EmployeeId BIGINT
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
			[DBO].[Employee] E WITH (NOLOCK) 
		LEFT JOIN 
			[DBO].[TimeZone] ETZ WITH (NOLOCK) 
			ON E.[TimeZoneId] = ETZ.[TimeZoneId]
		LEFT JOIN 
			[DBO].[LegalEntity] LE WITH (NOLOCK) 
			ON E.[LegalEntityId] = LE.LegalEntityId
		LEFT JOIN 
			[DBO].[TimeZone] LTZ WITH (NOLOCK) 
			ON LE.[TimeZoneId] = LTZ.[TimeZoneId]
		WHERE 
			E.[EmployeeId] = @EmployeeId; -- Use appropriate filter for the specific employee


		SELECT 
			LESA.[SiteName],
			LESAUD.[LegalEntityShippingId],
			LESAUD.[Memo],
			LESAUD.[ShippingAccountinfo] AS ShippingAccountInfo,
			ISNULL(LESAUD.[IsPrimary], 0) AS IsPrimary,
			ISNULL(LESAUD.[IsActive], 1) AS IsActive,
			ISNULL(LESAUD.[IsDeleted], 0) AS IsDeleted,
			LESAUD.[LegalEntityId],
			LESAUD.[LegalEntityShippingAddressId],
			CASE WHEN @EmployeeId != 0 AND @CurrntEmpTimeZoneDesc != '' THEN 
				 CASE WHEN CAST(LESAUD.[CreatedDate] AS DATE) = CAST('0001-01-01 00:00:00' AS DATE) THEN NULL ELSE (CAST(DBO.ConvertUTCtoLocal(LESAUD.[CreatedDate], @CurrntEmpTimeZoneDesc) AS DATETIME)) END 
			ELSE (CAST(LESAUD.[CreatedDate] AS DATETIME)) END AS CreatedDate,
			CASE WHEN @EmployeeId != 0 AND @CurrntEmpTimeZoneDesc != '' THEN 
				 CASE WHEN CAST(LESAUD.[UpdatedDate] AS DATE) = CAST('0001-01-01 00:00:00' AS DATE) THEN NULL ELSE (CAST(DBO.ConvertUTCtoLocal(LESAUD.[UpdatedDate], @CurrntEmpTimeZoneDesc) AS DATETIME)) END 
			ELSE (CAST(LESAUD.[UpdatedDate] AS DATETIME)) END AS UpdatedDate,
			LESAUD.[CreatedBy],
			LESAUD.[UpdatedBy],
			LESAUD.[AuditLegalEntityShippingId],
			SV.[Name] AS ShipViaName,
			SV.[ShippingViaId] AS ShipViaId,
			ISNULL(LESAUD.[ShippingTermsId], 0) AS ShippingTermsId,
			NULLIF(ST.[Name], '') AS ShippingTerms
		FROM [DBO].[LegalEntityShippingAudit] LESAUD WITH(NOLOCK) 
		LEFT JOIN [DBO].[ShippingVia] SV WITH(NOLOCK) ON LESAUD.[ShipViaId] = SV.[ShippingViaId]
		LEFT JOIN [DBO].[LegalEntityShippingAddress] LESA WITH(NOLOCK) ON LESAUD.[LegalEntityShippingAddressId] = LESA.[LegalEntityShippingAddressId]
		LEFT JOIN [DBO].[ShippingTerms] ST WITH(NOLOCK) ON LESAUD.[ShippingTermsId] = ST.[ShippingTermsId]
		WHERE 
			LESAUD.[LegalEntityId] = @LegalEntityId AND 
			LESAUD.[LegalEntityShippingAddressId] = @LegalEntityShippingAddressId AND 
			LESAUD.[LegalEntityShippingId] = @LegalEntityShippingId
		ORDER BY LESAUD.[AuditLegalEntityShippingId] DESC;

	END TRY 
	BEGIN CATCH
	
		DECLARE @ErrorLogID INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_GetLegalEntityShipViaAudit'
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