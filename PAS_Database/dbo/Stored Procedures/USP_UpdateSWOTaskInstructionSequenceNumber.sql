/*************************************************************             
 ** File:   [USP_UpdateSWOTaskInstructionSequenceNumber]             
 ** Author:  Vishal Suthar 
 ** Description: This stored procedure is used to update Sequence of WO Task Instruction
 ** Purpose:           
 ** Date:   03/21/2025
 
 ** RETURN VALUE:             
 **************************************************************             
 ** Change History             
 **************************************************************             
 ** PR   Date         Author			Change Description              
 ** --   --------     -------			--------------------------------            
	1    03/21/2025   Vishal Suthar		Created
	2    04/28/2025   Ekta Chandegra 	Fix parent-child sequence update issue

************************************************************************/
CREATE   PROCEDURE [dbo].[USP_UpdateSWOTaskInstructionSequenceNumber]
(
	@SubWorkOrderTaskInstructionId BIGINT,
	@NewSubWorkOrderTaskInstructionId BIGINT,
	@SequenceNumber BIGINT,
	@NewSequenceNumber BIGINT,
	@UpdatedBy VARCHAR(50),
	@InstructionListId VARCHAR(250),
	@SubWorkOrderTaskId BIGINT
)
AS
BEGIN 
	BEGIN TRY
	BEGIN	
		UPDATE dbo.SubWorkOrderTaskInstruction SET 
		SequenceNumber = @NewSequenceNumber,
		UpdatedBy = @UpdatedBy,
		UpdatedDate = GETUTCDATE() 
		WHERE SubWorkOrderTaskInstructionId = @SubWorkOrderTaskInstructionId
		
		UPDATE dbo.SubWorkOrderTaskInstruction SET 
		SequenceNumber = @SequenceNumber,
		UpdatedBy = @UpdatedBy,
		UpdatedDate = GETUTCDATE() 
		WHERE SubWorkOrderTaskInstructionId = @NewSubWorkOrderTaskInstructionId

		-- Recursive CTE to update both ParentSequenceNumber and SequenceNumber
		;WITH RecursiveCTE AS (
			-- Anchor member (top-level instructions)
			SELECT 
				SWOTI.SubWorkOrderTaskInstructionId,
				SWOTI.SubWorkOrderTaskId,
				SWOT.TaskId,
				SWOT.TaskName,
				SWOTI.InstructionTitle,
				SWOTI.InstructionDetails,
				SWOTI.SequenceNumber,
				SWOTI.TechId,
				SWOTI.TechName,
				SWOTI.TechUpdatedDate,
				SWOTI.InspectorId,
				SWOTI.InspectorName,
				SWOTI.InspectorUpdatedDate,
				SWOTI.PrintInWO,
				SWOTI.PrintInWOQ,
				SWOTI.MasterCompanyId,
				SWOTI.IsActive,
				SWOTI.IsDeleted,
				SWOTI.IsParent,
				SWOTI.ParentId,
				CAST(SWOTI.SequenceNumber AS VARCHAR(MAX)) AS ParentSequenceNumber
			FROM [dbo].[SubWorkOrderTaskInstruction] SWOTI WITH (NOLOCK)
			LEFT JOIN [dbo].[SubWorkOrderTask] SWOT WITH (NOLOCK) ON SWOT.SubWorkOrderTaskId = SWOTI.SubWorkOrderTaskId
			WHERE SWOTI.ParentId IS NULL

			UNION ALL

			-- Recursive member (child instructions)
			SELECT 
				SWOTI.SubWorkOrderTaskInstructionId,
				SWOTI.SubWorkOrderTaskId,
				SWOT.TaskId,
				SWOT.TaskName,
				SWOTI.InstructionTitle,
				SWOTI.InstructionDetails,
				SWOTI.SequenceNumber,
				SWOTI.TechId,
				SWOTI.TechName,
				SWOTI.TechUpdatedDate,
				SWOTI.InspectorId,
				SWOTI.InspectorName,
				SWOTI.InspectorUpdatedDate,
				SWOTI.PrintInWO,
				SWOTI.PrintInWOQ,
				SWOTI.MasterCompanyId,
				SWOTI.IsActive,
				SWOTI.IsDeleted,
				SWOTI.IsParent,
				SWOTI.ParentId,
				CAST(R.ParentSequenceNumber + '.' + CAST(SWOTI.SequenceNumber AS VARCHAR(MAX)) AS VARCHAR(MAX)) AS ParentSequenceNumber
			FROM [dbo].[SubWorkOrderTaskInstruction] SWOTI WITH (NOLOCK)
			INNER JOIN [dbo].[SubWorkOrderTask] SWOT WITH (NOLOCK) ON SWOT.SubWorkOrderTaskId = SWOTI.SubWorkOrderTaskId
			INNER JOIN RecursiveCTE R ON SWOTI.ParentId = R.SubWorkOrderTaskInstructionId
		)

		UPDATE SWOTI
		SET 
			SWOTI.SequenceNumber = R.SequenceNumber,
			SWOTI.ParentSequenceNumber = R.ParentSequenceNumber,
			SWOTI.UpdatedBy = @UpdatedBy,
			SWOTI.UpdatedDate = GETUTCDATE()
		FROM [dbo].[SubWorkOrderTaskInstruction] SWOTI
		INNER JOIN RecursiveCTE R ON SWOTI.SubWorkOrderTaskInstructionId = R.SubWorkOrderTaskInstructionId;

		-- Add Work Order Task Instruction History
		EXEC dbo.USP_InsertSubWorkOrderTaskInstructionHistory @SubWorkOrderTaskInstructionId , @UpdatedBy , @InstructionListId , @NewSubWorkOrderTaskInstructionId;

		-- Add Work Order Task History
		EXEC dbo.USP_AddSubWorkOrderTaskHistory @SubWorkOrderTaskId , @UpdatedBy , @SubWorkOrderTaskInstructionId , NULL;

	END
	END TRY
	BEGIN CATCH
		SELECT        
	   ERROR_NUMBER() AS ErrorNumber,        
	   ERROR_STATE() AS ErrorState,        
	   ERROR_SEVERITY() AS ErrorSeverity,        
	   ERROR_PROCEDURE() AS ErrorProcedure,        
	   ERROR_LINE() AS ErrorLine,        
	   ERROR_MESSAGE() AS ErrorMessage;        
	   IF @@trancount > 0        
	   PRINT 'ROLLBACK'        
	   DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()         
		-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------        
	   , @AdhocComments     VARCHAR(150)    = 'USP_UpdateSWOTaskInstructionSequenceNumber'         
	   , @ProcedureParameters VARCHAR(3000)  = '@SubWorkOrderTaskInstructionId = '''+ ISNULL(@SubWorkOrderTaskInstructionId, '') + ''        
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