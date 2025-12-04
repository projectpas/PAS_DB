/***************************************************************  
 ** File:   [USP_DeleteWorkFlowTaskById]             
 ** Author:   Vishal Suthar
 ** Description: This stored procedure is used to delete work flow task by id
 ** Date:  03-Dec-2025
            
  ** Change History             
 **************************************************************             
 ** PR   Date				Author  			Change Description              
 ** --   --------			-------				--------------------------------            
    1    03-Dec-2025		Vishal Suthar		Created
 
**************************************************************/
CREATE   PROCEDURE [dbo].[USP_DeleteWorkFlowTaskById]
	@WorkFlowId bigint,
	@TaskId bigint,
	@UpdatedBy varchar(50)
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;
		BEGIN TRY
			BEGIN
				DECLARE @WorkFlowTaskId BIGINT;
				SELECT @WorkFlowTaskId = WorkFlowTaskId FROM DBO.WorkFlowTask WITH(NOLOCK) WHERE WorkFlowId = @WorkFlowId AND TaskId = @TaskId;

				DELETE FROM DBO.WorkflowDirection WHERE WorkflowId = @WorkFlowId AND TaskId = @TaskId;
				DELETE FROM DBO.WorkflowChargesList WHERE WorkflowId = @WorkFlowId AND TaskId = @TaskId;
				DELETE FROM DBO.WorkflowEquipmentList WHERE WorkflowId = @WorkFlowId AND TaskId = @TaskId;
				DELETE FROM DBO.WorkflowMaterial WHERE WorkflowId = @WorkFlowId AND TaskId = @TaskId;
				DELETE FROM DBO.WorkflowExpertiseList WHERE WorkflowId = @WorkFlowId AND TaskId = @TaskId;
				DELETE FROM DBO.WorkflowMeasurement WHERE WorkflowId = @WorkFlowId AND TaskId = @TaskId;
				DELETE FROM DBO.WorkflowPublications WHERE WorkflowId = @WorkFlowId AND TaskId = @TaskId;
				DELETE FROM DBO.WorkFlowTask WHERE WorkFlowTaskId = @WorkFlowTaskId;

			END
		END TRY    
		BEGIN CATCH      
		IF @@trancount > 0
			DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            , @AdhocComments     VARCHAR(150)    = 'USP_DeleteWorkFlowTaskById' 
            , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@WorkFlowTaskId, '') + ''
            , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW---------------------------------------------------------------------
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
