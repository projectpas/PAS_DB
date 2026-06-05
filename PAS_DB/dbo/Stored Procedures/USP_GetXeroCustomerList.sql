/*************************************************************           
 ** File:   [USP_GetXeroCustomerList]           
 ** Author:   Moin Bloch
 ** Description: Get Customer List to Create Customer in Xero    
 ** Purpose:         
 ** Date:   06-06-2026      
         
 ** RETURN VALUE: 
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date			Author			Change Description            
 ** --   --------		-------			--------------------------------          
    1    06-06-2026     Moin Bloch   	Created

 EXECUTE [USP_GetXeroCustomerList] 3,1
**************************************************************/ 
CREATE   PROCEDURE [dbo].[USP_GetXeroCustomerList]
@IntegrationTypeId INT = NULL,
@MasterCompanyId INT = NULL
AS
BEGIN
	
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED	
	BEGIN TRY

		DECLARE @QBIntegrationTypeId INT=1, @NSIntegrationTypeId INT=2, @XeroIntegrationTypeId INT=3

		SELECT @QBIntegrationTypeId = [IntegrationTypeId] FROM [dbo].[AccountingIntegrationType] WITH(NOLOCK) WHERE [IntegrationType] = 'QuickBooks';
		SELECT @NSIntegrationTypeId = [IntegrationTypeId] FROM [dbo].[AccountingIntegrationType] WITH(NOLOCK) WHERE [IntegrationType] = 'NetSuite';
		SELECT @XeroIntegrationTypeId = [IntegrationTypeId] FROM [dbo].[AccountingIntegrationType] WITH(NOLOCK) WHERE [IntegrationType] = 'Xero';

		-- For Xero	
		IF (ISNULL(@IntegrationTypeId, 0) = @XeroIntegrationTypeId) 
		BEGIN			
			SELECT
				CST.[CustomerId],
				CST.[Name],
				CST.[CustomerCode],				
				CST.[QuickBooksReferenceId],
				CST.[MasterCompanyId],
				CST.[UpdatedBy]
			FROM [dbo].[Customer] CST WITH(NOLOCK)			
			WHERE CST.[IntegrationTypeId] = @XeroIntegrationTypeId
			  AND ISNULL(CST.[QuickBooksReferenceId], '') <> ''  
			  AND ISNULL(CST.[IsUpdated], 0) <> 1  
			  AND CST.[MasterCompanyId] = @MasterCompanyId
			  AND CST.[IsActive]        = 1
			  AND CST.[IsDeleted]       = 0;
		END
	END TRY    
	BEGIN CATCH      

	         DECLARE @ErrorLogID INT
			,@DatabaseName VARCHAR(100) = db_name()
			-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
			,@AdhocComments VARCHAR(150) = 'USP_GetXeroCustomerList'
			,@ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@IntegrationTypeId, '') AS varchar(100))  			                                           
			,@ApplicationName VARCHAR(100) = 'PAS'
		-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
		EXEC spLogException @DatabaseName = @DatabaseName
			,@AdhocComments = @AdhocComments
			,@ProcedureParameters = @ProcedureParameters
			,@ApplicationName = @ApplicationName
			,@ErrorLogID = @ErrorLogID OUTPUT;

		RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)

		RETURN (1);           
	END CATCH
END