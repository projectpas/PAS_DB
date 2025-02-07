/*************************************************************             
 ** File:   [USP_UpdateWorkFlowTaskInstructionSequenceNumber]             
 ** Author:  Vishal Suthar 
 ** Description: This stored procedure is used to update Sequence of Task Instruction Master For WorkFlow
 ** Date:   07-Feb-2025
 
 ** RETURN VALUE:             
 **************************************************************             
 ** Change History             
 **************************************************************             
 ** PR   Date				Author							Change Description              
 ** --   --------			-------						--------------------------------            
	 1    07-Feb-2025		Devendra Shekh					Created

	exec dbo.USP_UpdateWorkFlowTaskInstructionSequenceNumber 
	@WorkflowDirectionId=26,@SequenceNumber=N'3',@NewWorkflowDirectionId=24,@NewSequenceNumber=2,@UpdatedBy=N'Jim Roberts'
************************************************************************/
CREATE   PROCEDURE [dbo].[USP_UpdateWorkFlowTaskInstructionSequenceNumber]
(
	@WorkflowDirectionId BIGINT = NULL,
	@SequenceNumber BIGINT = NULL,
	@NewWorkflowDirectionId BIGINT = NULL,
	@NewSequenceNumber BIGINT = NULL,
	@UpdatedBy VARCHAR(50) = NULL
)
AS
BEGIN 
	BEGIN TRY
	BEGIN	
		UPDATE dbo.WorkflowDirection SET 
		[Sequence] = @NewSequenceNumber,
		UpdatedBy = @UpdatedBy,
		UpdatedDate = GETUTCDATE() 
		WHERE [WorkflowDirectionId] = @WorkflowDirectionId
		
		UPDATE dbo.WorkflowDirection SET 
		[Sequence] = @SequenceNumber,
		UpdatedBy = @UpdatedBy,
		UpdatedDate = GETUTCDATE() 
		WHERE [WorkflowDirectionId] = @NewWorkflowDirectionId
	END
	END TRY
	BEGIN CATCH
		SELECT ERROR_NUMBER() AS ErrorNumber, ERROR_STATE() AS ErrorState, ERROR_SEVERITY() AS ErrorSeverity, ERROR_PROCEDURE() AS ErrorProcedure,  ERROR_LINE() AS ErrorLine, ERROR_MESSAGE() AS ErrorMessage;        
		IF @@trancount > 0        
		PRINT 'ROLLBACK'        
		DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()         
		-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------        
		, @AdhocComments     VARCHAR(150)    = 'USP_UpdateWorkFlowTaskInstructionSequenceNumber'         
		, @ProcedureParameters VARCHAR(3000)  = '@WorkflowDirectionId = '''+ ISNULL(@WorkflowDirectionId, '') + ''        
		, @ApplicationName VARCHAR(100) = 'PAS'        
		-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------        
		exec spLogException         
		@DatabaseName           = @DatabaseName        
		, @AdhocComments          = @AdhocComments        
		, @ProcedureParameters = @ProcedureParameters        
		, @ApplicationName        =  @ApplicationName        
		, @ErrorLogID             = @ErrorLogID OUTPUT ;        
		RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)        
		RETURN(1);       
	END CATCH
END