  /*************************************************************             
 ** File:   [DeleteVendorCreditMemoDetailsById]             
 ** Author:  Devendra Shekh  
 ** Description: This stored procedure is used to delete vendor Credit Memo Details  
 ** Purpose:           
 ** Date:   28/06/2023       
            
 ** PARAMETERS: @VendorCreditMemoDetailId bigint  
           
 ** RETURN VALUE:             
 **************************************************************             
 ** Change History             
 **************************************************************             
 ** PR   Date         Author				Change Description              
 ** --   --------     -------			--------------------------------            
    1    28/06/2023  Devendra SHekh			Created  
       
-- EXEC DeleteVendorCreditMemoDetailsById 3  
************************************************************************/  
CREATE   PROCEDURE [dbo].[DeleteVendorCreditMemoDetailsById]  
@VendorCreditMemoDetailId bigint  
AS  
BEGIN  
 SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED  
 SET NOCOUNT ON;  
 BEGIN TRY  
  DELETE FROM [dbo].[VendorCreditMemoDetail]  WHERE VendorCreditMemoDetailId = @VendorCreditMemoDetailId;  
    END TRY      
 BEGIN CATCH        
  IF @@trancount > 0  
   PRINT 'ROLLBACK'  
   ROLLBACK TRAN;  
   DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()   
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------  
            , @AdhocComments     VARCHAR(150)    = 'DeleteVendorCreditMemoDetailsById'   
            , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@VendorCreditMemoDetailId, '') + ''  
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