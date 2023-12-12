  /*************************************************************           
 ** File:   [USP_CheckLegalEntity_Exist]          
 ** Author:    
 ** Description: This stored procedure is used to Restore Deleted Records
 ** Purpose:         
 ** Date:   
          
 ** PARAMETERS:          

 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		-------------------------------- 
    1   10/08/2023 Bhargav Saliya   UTC Date Changes
     
**************************************************************/
CREATE   PROCEDURE [dbo].[UpdateDeletedRecords]  
@TableName VARCHAR(50),  
@Parameter1 VARCHAR(50),  
@Parameter2 VARCHAR(50)  
AS  
BEGIN  
 SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED  
 SET NOCOUNT ON;  
  
 BEGIN TRY  
 BEGIN TRANSACTION  
  BEGIN  
   DECLARE @Sql NVARCHAR(MAX);    
   IF @Parameter1 IS NOT NULL  AND @Parameter1 !='' AND  @Parameter2 IS NOT NULL  AND @Parameter2 !=''  
   BEGIN  
   SET @Sql = N'UPDATE ' + @TableName+ ' SET IsDeleted = 0, UpdatedDate = GETUTCDATE() WHERE IsDeleted = 1 AND CAST ( '+ @Parameter1 +' AS VARCHAR) = '+@Parameter2+'';  
   END  
   --PRINT @Sql  
   EXEC sp_executesql @Sql;  
   Select  @Parameter2 as [Value]   
  END  
  COMMIT  TRANSACTION  
  
 END TRY      
 BEGIN CATCH        
  IF @@trancount > 0  
   PRINT 'ROLLBACK'  
   ROLLBACK TRAN;  
   DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()   
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------  
            , @AdhocComments     VARCHAR(150)    = 'UpdateDeletedRecords'   
            , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@TableName, '') + ''  
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