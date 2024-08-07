/*************************************************************           
 ** File:   [GetCustomerList]           
 ** Author:   Hemant Saliya
 ** Description: Update QuickBooks Customer Id In PAS    
 ** Purpose:         
 ** Date:   04-July-2024        
         
 ** RETURN VALUE: 
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date			Author			Change Description            
 ** --   --------		-------			--------------------------------          
    1    04-July-2024   Hemant Saliya	Created (Update QuickBooks Customer Id In PAS)
     
 EXECUTE [QuickBooks_UpdateCustomerReferenceDetails] 1, 10, '150'
**************************************************************/ 
CREATE   PROCEDURE [dbo].[QuickBooks_UpdateCustomerReferenceDetails]
@IntegrationTypeId INT = NULL,
@CustomerId BIGINT = NULL,
@ReferenceId VARCHAR(100)
AS
BEGIN
	
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED	
	BEGIN TRY

		-- FOR QuickBooks
		IF(ISNULL(@IntegrationTypeId, 0) = 1) 
		BEGIN
			UPDATE Customer SET QuickBooksReferenceId =  @ReferenceId, IsUpdated = 0 WHERE CustomerId = @CustomerId			
		END

	END TRY    
	BEGIN CATCH      

	         DECLARE @ErrorLogID INT
			,@DatabaseName VARCHAR(100) = db_name()
			-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
			,@AdhocComments VARCHAR(150) = 'QuickBooks_UpdateCustomerReferenceDetails'
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