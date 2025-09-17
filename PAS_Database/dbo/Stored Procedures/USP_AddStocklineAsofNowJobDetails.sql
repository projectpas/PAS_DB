/*************************************************************             
 ** File:  [USP_AddBillingInvoicingDetails]
 ** Author:  Moin Bloch  
 ** Description: This stored procedure is used to store Billing Details
 ** Purpose:           
 ** Date:   10/09/2025            
 ** PARAMETERS:            
 ** RETURN VALUE:             
 **************************************************************             
 ** Change History             
 **************************************************************             
 ** PR   Date         Author		Change Description              
 ** --   --------     -------		--------------------------------            
    1    10/09/2025   MOIN BLOCH     Created  

--  EXEC [dbo].[USP_AddStocklineAsofNowJobDetails] 'Job1','C:\Jobs\Job1.csv','2025-09-10',1
************************************************************************/    
CREATE   PROCEDURE [dbo].[USP_AddStocklineAsofNowJobDetails]
@Name NVARCHAR(100),
@Path NVARCHAR(100),
@TotalInventory DECIMAL(18,2),
@JobDate DATETIME2(7),
@NextRunDate DATETIME2(7),
@MasterCompanyId INT
AS
BEGIN  
 SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED  
 SET NOCOUNT ON;   
 BEGIN TRY  
 BEGIN TRANSACTION  
 BEGIN    
	
	INSERT INTO [dbo].[StocklineAsofNowJobDetails]([Name],[Path],[TotalInventory],[JobDate],[NextRunDate],[MasterCompanyId],[CreatedDate])
                                            VALUES(@Name,@Path,@TotalInventory,@JobDate,@NextRunDate,@MasterCompanyId,GETUTCDATE());
	   	
 END   
 COMMIT  TRANSACTION  
 END TRY   
 BEGIN CATCH        
  IF @@trancount > 0  
  PRINT 'ROLLBACK'  
    ROLLBACK TRANSACTION;  
	SELECT
    ERROR_NUMBER() AS ErrorNumber,
    ERROR_STATE() AS ErrorState,
    ERROR_SEVERITY() AS ErrorSeverity,
    ERROR_PROCEDURE() AS ErrorProcedure,
    ERROR_LINE() AS ErrorLine,
    ERROR_MESSAGE() AS ErrorMessage;
    DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()   
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------  
              , @AdhocComments     VARCHAR(150)    = 'USP_AddStocklineAsofNowJobDetails'   
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ CAST(ISNULL(@Name, '') AS VARCHAR(100))  
             + '@Parameter2 = ''' + CAST(ISNULL(@Path, '') AS VARCHAR(100))   
             + '@Parameter3 = ''' + CAST(ISNULL(@JobDate, '') AS VARCHAR(100))   
             + '@Parameter4 = ''' + CAST(ISNULL(@MasterCompanyId, '') AS VARCHAR(100))              
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