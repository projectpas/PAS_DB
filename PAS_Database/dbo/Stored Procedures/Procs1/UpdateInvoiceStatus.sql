/*************************************************************           
 ** File:  [UpdateInvoiceStatus]           
 ** Author:	  Moin Bloch
 ** Description: 
 ** Purpose:         
 ** Date:   05/24/2023          
 ** PARAMETERS: 
 ** RETURN VALUE: 
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author			Change Description            
 ** --   --------     -------			--------------------------------     
	1    05/24/2023    		            Created
	2    07-07-2025     Moin Bloch      Changed Old To New Billing Table
**************************************************************/
CREATE   PROCEDURE [dbo].[UpdateInvoiceStatus]  
 @SalesOrderId bigint,  
 @SOBillingInvoicingId bigint  
AS  
BEGIN  
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED  
SET NOCOUNT ON;  
  
 BEGIN TRY 

	UPDATE dbo.BillingInvoicing
	SET InvoiceStatus = 'Reviewed',
		InvoiceStatusId = (SELECT InvoiceStatusId FROM dbo.InvoiceStatus WITH(NOLOCK) WHERE [Status] = 'Reviewed')
	WHERE ReferenceId = @SalesOrderId AND BillingInvoicingId = @SOBillingInvoicingId

 END TRY      
 BEGIN CATCH        
  IF @@trancount > 0  
   PRINT 'ROLLBACK'  
   ROLLBACK TRAN;  
   DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()   
  
 -----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------  
   , @AdhocComments     VARCHAR(150)    = 'UpdateInvoiceStatus'   
   , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@SalesOrderId, '') + '@Parameter2= '''+ ISNULL(@SOBillingInvoicingId, '')  + ''  
   , @ApplicationName VARCHAR(100) = 'PAS'  
 -----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------  
   exec spLogException   
     @DatabaseName           = @DatabaseName  
     , @AdhocComments          = @AdhocComments  
     , @ProcedureParameters = @ProcedureParameters  
     , @ApplicationName        =  @ApplicationName  
     , @ErrorLogID                    = @ErrorLogID OUTPUT ;  
   RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)  
   RETURN(1);  
 END CATCH  
END