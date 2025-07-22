/*************************************************************           
 ** File:		 [USP_GetLegalEntityAddressById]           
 ** Author:		 Divyesh Kathiriya
 ** Description: This Stored Procedure Is Used To Get Legal Entity Address By Id.
 ** Purpose:         
 ** Date:   07-July-2025 
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date				Author				Change Description            
 ** --   -------------		----------------	--------------------------------          
    1    07-July-2025		Divyesh Kathiriya	Created
    
 -- EXEC [USP_GetLegalEntityAddressById] @LegalEntityId=1
**************************************************************/
CREATE   PROCEDURE [DBO].[USP_GetLegalEntityAddressById]
@LegalEntityId BIGINT
AS
BEGIN
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	BEGIN TRY	

		SELECT DISTINCT 
			lsa.[LegalEntityShippingAddressId],
			lsa.[SiteName],
			ad.[Line1],
			ad.[Line2],
			ad.[Line3],
			ad.[City],
			ad.[StateOrProvince],
			ad.[PostalCode],
			ad.[CountryId],
			ad.[AddressId]
		FROM [DBO].[LegalEntityShippingAddress] AS lsa WITH (NOLOCK)
		INNER JOIN [DBO].[Address] AS ad WITH (NOLOCK) ON lsa.[AddressId] = ad.[AddressId]
		WHERE lsa.[LegalEntityId] = @LegalEntityId;			  		 	   			   	  
	
	END TRY 
	BEGIN CATCH
	
		DECLARE @ErrorLogID INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_GetLegalEntityAddressById'
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