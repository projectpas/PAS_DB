CREATE    PROCEDURE [dbo].[UpdateGLAccountLeafNode]    
@LeafNodeId bigint,    
@GLAccountId varchar(max),    
@ParentId bigint,    
@IsLeafNode bigint    
AS    
BEGIN    
 SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED    
 SET NOCOUNT ON;    
    
 BEGIN TRY       
  BEGIN     
   IF(ISNULL(@GLAccountId,'') <> '' AND @LeafNodeId > 0)    
   BEGIN    
    UPDATE GLAccount SET GLAccountNodeId=@LeafNodeId  Where GlaccountId IN (SELECT ITEM FROM SplitString(@GlAccountId,','));    
   END    
   UPDATE GLAccount SET GLAccountNodeId=0  Where GLAccountNodeId=@ParentId;    
    
   IF(@IsLeafNode = 0)    
   BEGIN    
    UPDATE GLAccount SET GLAccountNodeId=0  Where GlaccountId IN (SELECT ITEM FROM SplitString(@GLAccountId,','));    
   END    
  END       
    
 END TRY        
 BEGIN CATCH          
  IF @@trancount > 0    
   PRINT 'ROLLBACK'     
   DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()     
    
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------    
            , @AdhocComments     VARCHAR(150)    = 'UpdateGLAccountLeafNode'     
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