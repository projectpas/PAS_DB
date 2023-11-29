/*************************************************************             
 ** File:   [USP_DeleteNonPOInvoicePart_ById]             
 ** Author:   Devendra Shekh  
 ** Description: This stored procedure is used delete nonpoinvoicepart byid  
 ** Purpose:           
 ** Date:      22nd September 2023  
            
 ** PARAMETERS:             
 @WorkOrderId BIGINT     
 @WFWOId BIGINT    
           
 ** RETURN VALUE:             
    
 **************************************************************             
  ** Change History             
 **************************************************************             
 ** PR   Date			Author				Change Description              
 ** --   --------		-------			--------------------------------            
	1	O9/22/2023		Devendra Shekh		Modified to return SUM of all the records before paging  

**************************************************************/  

Create   PROCEDURE [dbo].[USP_DeleteNonPOInvoicePart_ById]
@NonPOInvoicePartDetailsId BIGINT,
@MasterCompanyId BIGINT
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;
		BEGIN TRY
		BEGIN TRANSACTION
			BEGIN 
				DELETE FROM NonPOInvoicePartDetails WHERE NonPOInvoicePartDetailsId = @NonPOInvoicePartDetailsId AND MasterCompanyId = @MasterCompanyId
			END
		COMMIT  TRANSACTION

		END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
				--PRINT 'ROLLBACK'
				ROLLBACK TRAN;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_DeleteNonPOInvoicePart_ById' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@NonPOInvoicePartDetailsId, '') + ''
              , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------

              exec spLogException 
                       @DatabaseName			= @DatabaseName
                     , @AdhocComments			= @AdhocComments
                     , @ProcedureParameters		= @ProcedureParameters
                     , @ApplicationName         = @ApplicationName
                     , @ErrorLogID              = @ErrorLogID OUTPUT ;
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
              RETURN(1);
		END CATCH
END