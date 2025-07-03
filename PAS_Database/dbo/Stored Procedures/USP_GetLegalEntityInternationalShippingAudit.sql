/*************************************************************           
 ** File:		 [USP_GetLegalEntityInternationalShippingAudit]           
 ** Author:		 Divyesh Kathiriya
 ** Description: This Stored Procedure Is Used To Get Legal Entity International Shipping History.
 ** Purpose:         
 ** Date:   02-July-2025 
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date				Author				Change Description            
 ** --   -------------		----------------	--------------------------------          
    1    02-July-2025		Divyesh Kathiriya	Created
    
 -- EXEC [USP_GetLegalEntityInternationalShippingAudit] @LegalEntityId=41,@InternationalShippingId=9,@EmployeeId=226
**************************************************************/
CREATE   PROCEDURE [DBO].[USP_GetLegalEntityInternationalShippingAudit]
@LegalEntityId BIGINT,
@InternationalShippingId BIGINT,
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
			c.[InternationalShippingId],
			c.[LegalEntityInternationalShippingAuditId],
			c.[LegalEntityId],
			c.[ExportLicense],
			c.[StartDate],
			c.[ExpirationDate],
			c.[Amount],
			con.[countries_name] AS Country,
			c.[Description],
			ISNULL(c.[IsPrimary], 0) AS IsPrimary,
			c.[CreatedBy],
			c.[UpdatedBy],
			CASE WHEN @EmployeeId != 0 AND @CurrntEmpTimeZoneDesc != '' THEN 
				 CASE WHEN CAST(c.[CreatedDate] AS DATE) = CAST('0001-01-01 00:00:00' AS DATE) THEN NULL ELSE (CAST(DBO.ConvertUTCtoLocal(c.[CreatedDate], @CurrntEmpTimeZoneDesc) AS DATETIME)) END 
			ELSE (CAST(c.[CreatedDate] AS DATETIME)) END AS CreatedDate,
			CASE WHEN @EmployeeId != 0 AND @CurrntEmpTimeZoneDesc != '' THEN 
				 CASE WHEN CAST(c.[UpdatedDate] AS DATE) = CAST('0001-01-01 00:00:00' AS DATE) THEN NULL ELSE (CAST(DBO.ConvertUTCtoLocal(c.[UpdatedDate], @CurrntEmpTimeZoneDesc) AS DATETIME)) END 
			ELSE (CAST(c.[UpdatedDate] AS DATETIME)) END AS UpdatedDate,
			ISNULL(c.[IsActive], 1) AS IsActive,
			ISNULL(c.[IsDeleted], 0) AS IsDeleted,
			c.[MasterCompanyId]
		FROM [DBO].[LegalEntityInternationalShippingAudit] AS c WITH (NOLOCK)
		INNER JOIN [DBO].[Countries] AS con WITH (NOLOCK) ON c.[ShipToCountryId] = con.[countries_id]
		WHERE c.[LegalEntityId] = @LegalEntityId AND c.[InternationalShippingId] = @InternationalShippingId
		ORDER BY c.[LegalEntityInternationalShippingAuditId] DESC;		

	END TRY 
	BEGIN CATCH
	
		DECLARE @ErrorLogID INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_GetLegalEntityInternationalShippingAudit'
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