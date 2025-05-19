/*************************************************************           
 ** File:		 [USP_GetLegalEntityContacts]           
 ** Author:		 Divyesh Kathiriya
 ** Description: This Stored Procedure Is Used To Get Legal Entity Contacts By Id.
 ** Purpose:         
 ** Date:   19-MAY-2025 
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date				Author				Change Description            
 ** --   -------------		----------------	--------------------------------          
    1    19-MAY-2025		Divyesh Kathiriya	Created
    
 -- EXEC [USP_GetLegalEntityContacts] @ContactId=10599
**************************************************************/
CREATE   PROCEDURE [DBO].[USP_GetLegalEntityContacts]
@ContactId BIGINT
AS
BEGIN
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	BEGIN TRY

		SELECT 
			C.[ContactId],
			C.[ContactTitle],
			C.[AlternatePhone],
			C.[CreatedBy],
			C.[UpdatedBy],
			C.[Email],
			C.[Tag],
			C.[Fax],
			C.[FirstName],
			C.[LastName],
			C.[MiddleName],
			C.[MobilePhone],
			C.[Notes],
			C.[Prefix],
			C.[Suffix],
			C.[WebsiteURL],
			C.[WorkPhone],
			ISNULL(C.[IsActive], 0) AS IsActive,
			VC.[LegalEntityContactId],
			ISNULL(VC.[IsDefaultContact], 0) AS IsDefaultContact,
			VC.[LegalEntityId],
			C.[CreatedDate],
			C.[UpdatedDate],
			C.[WorkPhoneExtn],
			C.[ContactTagId],
			C.[Attention],
			FullContactNo = CONCAT(C.[WorkPhone], ' - ', C.[WorkPhoneExtn])
		FROM [DBO].[Contact] C WITH(NOLOCK)
		INNER JOIN [DBO].[LegalEntityContact] VC WITH(NOLOCK) ON C.[ContactId] = VC.[ContactId]
		WHERE C.[ContactId] = @ContactId;			  		 	   			   	  
	
	END TRY 
	BEGIN CATCH
	
		DECLARE @ErrorLogID INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_GetLegalEntityContacts'
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