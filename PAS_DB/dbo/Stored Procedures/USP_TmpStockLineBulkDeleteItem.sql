/*************************************************************           
 ** File:   [USP_TmpStockLineBulkDeleteItem]           
 ** Author:  Amit Ghediya
 ** Description: This stored procedure is used to delete data from stkbulk temp record.
 ** Purpose:         
 ** Date:   07/20/2022      
          
 ** PARAMETERS: @tmpStockLineBulkUploadId
         
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    07/20/2023  Amit Ghediya     Created
     
-- EXEC USP_TmpStockLineBulkDeleteItem
************************************************************************/
CREATE   PROCEDURE [dbo].[USP_TmpStockLineBulkDeleteItem]  
	@tmpStockLineBulkUploadId BIGINT
AS  
BEGIN  
 DECLARE @isDeleted INT;
 SET NOCOUNT ON;  
 SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED  
  
  BEGIN TRY  
    BEGIN TRANSACTION  
    BEGIN  
		IF EXISTS( SELECT * FROM TmpStockLineBulkUpload WITH (NOLOCK) WHERE TmpStockLineBulkUploadId = @tmpStockLineBulkUploadId)
		BEGIN
			-- Delete data from stkbulk temp table. 
			DELETE FROM TmpStockLineBulkUpload WHERE TmpStockLineBulkUploadId = @tmpStockLineBulkUploadId;
			
			SET @isDeleted = 1;

			--Select  success message 
			SELECT 'Record Deleted' AS message, @isDeleted AS isDeleted;
		END
		ELSE
		BEGIN
			SET @isDeleted = 0;
			SELECT 'Record Not Found.' AS message, @isDeleted AS isDeleted;
		END
    END  
    COMMIT  TRANSACTION  
  END TRY      
  BEGIN CATCH        
   IF @@trancount > 0  
    PRINT 'ROLLBACK'  
                    ROLLBACK TRAN;  
              DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()   
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------  
              , @AdhocComments     VARCHAR(150)    = 'USP_TmpStockLineBulkDeleteItem'   
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''  
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