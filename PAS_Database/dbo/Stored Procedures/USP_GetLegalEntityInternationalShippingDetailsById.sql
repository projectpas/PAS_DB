/*************************************************************           
 ** File:		 [USP_GetLegalEntityInternationalShippingDetailsById]           
 ** Author:		 Divyesh Kathiriya
 ** Description: This Stored Procedure Is Used To Get Legal Entity International Shipping Details By Id.
 ** Purpose:         
 ** Date:   09-July-2025 
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date				Author				Change Description            
 ** --   -------------		----------------	--------------------------------          
    1    09-July-2025		Divyesh Kathiriya	Created
    
 -- EXEC [USP_GetLegalEntityInternationalShippingDetailsById] @InternationalShippingId=9
**************************************************************/
CREATE   PROCEDURE [DBO].[USP_GetLegalEntityInternationalShippingDetailsById]
@InternationalShippingId BIGINT
AS
BEGIN
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	BEGIN TRY

		SELECT TOP 1
			CIS.[LegalEntityInternationalShippingId],			
			CIS.[ExportLicense],
			CIS.[StartDate],
			CIS.[Amount],				
			ISNULL(CIS.[IsPrimary], 0) AS IsPrimary,
			CIS.[Description],
			CIS.[ExpirationDate],
			CIS.[ShipToCountryId],
			C.[countries_name] AS [ShipToCountry],			
			CIS.[CreatedBy],
			CIS.[UpdatedBy],
			ISNULL(CIS.[IsActive], 0) AS IsActive,
			ISNULL(CIS.[IsDeleted], 0) AS IsDeleted
		FROM [DBO].[LegalEntityInternationalShipping] CIS WITH (NOLOCK)
			INNER JOIN [DBO].[Countries] C WITH (NOLOCK) ON CIS.[ShipToCountryId] = C.[countries_id]
			INNER JOIN [DBO].[LegalEntity] CUST WITH (NOLOCK) ON CIS.[LegalEntityId] = CUST.[LegalEntityId]
		WHERE CIS.[LegalEntityInternationalShippingId] = @InternationalShippingId;

	END TRY 
	BEGIN CATCH
	
		DECLARE @ErrorLogID INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_GetLegalEntityInternationalShippingDetailsById'
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