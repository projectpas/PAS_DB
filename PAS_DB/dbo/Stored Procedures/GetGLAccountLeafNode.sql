CREATE   PROCEDURE [dbo].[GetGLAccountLeafNode]
@MasterCompanyId int,
@LeafNodeId bigint
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;
	BEGIN TRY
		select LeafNodeId,[Name] from LeafNode where LeafNodeId NOT IN (select ISNULL(ParentId,0) from LeafNode) AND (IsLeafNode=0 OR IsLeafNode is null)
                UNION
		select LeafNodeId,[Name] from LeafNode where LeafNodeId = @LeafNodeId;
    END TRY    
	BEGIN CATCH      
		IF @@trancount > 0
			PRINT 'ROLLBACK'
			ROLLBACK TRAN;
			DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            , @AdhocComments     VARCHAR(150)    = 'GetGLAccountLeafNode' 
            , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ '' + ''
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