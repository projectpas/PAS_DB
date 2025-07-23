
/************************************************************************             
 ** File:  [USP_UpdateBillingInvoicingPdfPath]
 ** Author:  Moin Bloch  
 ** Description: This stored procedure is used to update Billing Details
 ** Purpose:           
 ** Date:   19/05/2025                      
 ** PARAMETERS:            
 ** RETURN VALUE:             
 ************************************************************************             
 ** Change History             
 ************************************************************************             
 ** PR   Date         Author  Change Description              
 ** --   --------     -------  --------------------------------            
    1    19/05/2025   Moin Bloch     Created  
    2    23-07-2025   Rajesh Gami       Remove Transactio     
-- EXEC USP_UpdateBillingInvoicingPdfPath
************************************************************************/  
CREATE      PROCEDURE [dbo].[USP_UpdateBillingInvoicingPdfPath]
-------------------------------------------BillingInvoicing-------------------------------------------
@BillingInvoicingId BIGINT = NULL,  
@ModuleId INT = NULL,
@PDFPath NVARCHAR(500)='',
@Opr INT = NULL
AS  
BEGIN  
 SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED  
 SET NOCOUNT ON;   
 BEGIN TRY  
 --BEGIN TRANSACTION  
 BEGIN    
	--DECLARE @WOModuleId INT,@SOModuleId INT,@EXModuleId INT	
	--SELECT @WOModuleId = [ModuleId] FROM [dbo].[Module] WITH(NOLOCK) WHERE [ModuleName] = 'WorkOrder';
	--SELECT @SOModuleId = [ModuleId] FROM [dbo].[Module] WITH(NOLOCK) WHERE [ModuleName] = 'SalesOrder';
	--SELECT @EXModuleId = [ModuleId] FROM [dbo].[Module] WITH(NOLOCK) WHERE [ModuleName] = 'ExchangeSalesOrder';
	IF(@Opr = 1)
	BEGIN
		UPDATE [dbo].[BillingInvoicing] SET [InvoiceFilePath] = @PDFPath WHERE [BillingInvoicingId] = @BillingInvoicingId; 	
	END	
	IF(@Opr = 2)
	BEGIN
		UPDATE [dbo].[BillingInvoicingItems] SET [PDFPath] = @PDFPath WHERE [BillingInvoicingId] = @BillingInvoicingId; 	
	END
 END   
 --COMMIT  TRANSACTION  
 END TRY   
 BEGIN CATCH        
  IF @@trancount > 0  
  PRINT 'ROLLBACK'  
    --ROLLBACK TRANSACTION;  
    DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()   
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------  
              , @AdhocComments     VARCHAR(150)    = 'USP_UpdateBillingInvoicingDetails'   
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ CAST(ISNULL(@BillingInvoicingId, '') AS VARCHAR(100))  
             + '@Parameter2 = ''' + CAST(ISNULL(@ModuleId, '') AS VARCHAR(100))                
              , @ApplicationName VARCHAR(100) = 'PAS'  
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------------------------------------  
              exec spLogException   
                       @DatabaseName           = @DatabaseName  
                     , @AdhocComments          = @AdhocComments  
                     , @ProcedureParameters    = @ProcedureParameters  
                     , @ApplicationName        =  @ApplicationName  
                     , @ErrorLogID                    = @ErrorLogID OUTPUT ;  
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)  
              RETURN(1);  
 END CATCH  
END