--  EXEC [dbo].[UpdateLeafNodeGLAccount] 3    
CREATE    PROCEDURE [dbo].[UpdateLeafNodeGLAccount]    
@LeafNodeId int    
AS    
BEGIN    
 SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED    
 SET NOCOUNT ON;    
    
 BEGIN TRY      
  BEGIN     
   IF EXISTS(SELECT TOP 1 * FROM LeafNode WITH(NOLOCK) WHERE LeafNodeId=@LeafNodeId AND IsLeafNode=1)    
   BEGIN    
    --print '1';    
    UPDATE LeafNode SET IsLeafNode=0,GLAccountId=NULL WHERE LeafNodeId=@LeafNodeId;    
  
	DELETE FROM GLAccountLeafNodeMapping WHERE LeafNodeId=@LeafNodeId   
   END    
  END     
    
 END TRY        
 BEGIN CATCH          
  IF @@trancount > 0    
   PRINT 'ROLLBACK'    
   DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()     
    
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------    
            , @AdhocComments     VARCHAR(150)    = 'UpdateLeafNodeGLAccount'     
            , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@LeafNodeId, '') + ''    
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