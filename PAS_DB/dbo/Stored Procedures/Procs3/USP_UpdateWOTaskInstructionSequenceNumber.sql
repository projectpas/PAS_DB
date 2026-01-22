/*************************************************************             
 ** File:   [USP_UpdateWOTaskInstructionSequenceNumber]             
 ** Author:  Vishal Suthar 
 ** Description: This stored procedure is used to update Sequence of WO Task Instruction
 ** Purpose:           
 ** Date:   01/08/2024
 
 ** RETURN VALUE:             
 **************************************************************             
 ** Change History             
 **************************************************************             
 ** PR   Date         Author			Change Description              
 ** --   --------     -------			--------------------------------            
	1    01/08/2024   Vishal Suthar		Created
	2    04/28/2025   Ekta Chandegra 	Fix parent-child sequence update issue
	3    05/12/2025   Ekta Chandegra 	Add @IsFromWorkFlow

************************************************************************/
CREATE   PROCEDURE [dbo].[USP_UpdateWOTaskInstructionSequenceNumber]
(
	@WorkOrderTaskInstructionId BIGINT,
	@NewWorkOrderTaskInstructionId BIGINT,
	@SequenceNumber BIGINT,
	@NewSequenceNumber BIGINT,
	@UpdatedBy VARCHAR(50),
	@InstructionListId VARCHAR(250),
	@WorkOrderTaskId BIGINT,
	@IsFromWorkFlow BIT
)
AS
BEGIN 
	BEGIN TRY
	BEGIN	

		-- Update parents first (work on top-level instructions)
		UPDATE dbo.WorkOrderTaskInstruction
		SET 
			SequenceNumber = @NewSequenceNumber,
			UpdatedBy = @UpdatedBy,
			UpdatedDate = GETUTCDATE()
		WHERE WorkOrderTaskInstructionId = @WorkOrderTaskInstructionId;

		UPDATE dbo.WorkOrderTaskInstruction
		SET 
			SequenceNumber = @SequenceNumber,
			UpdatedBy = @UpdatedBy,
			UpdatedDate = GETUTCDATE()
		WHERE WorkOrderTaskInstructionId = @NewWorkOrderTaskInstructionId;

		-- Recursive CTE to update both ParentSequenceNumber and SequenceNumber
		;WITH RecursiveCTE AS (
			-- Anchor member (top-level instructions)
			SELECT 
				WOTI.WorkOrderTaskInstructionId,
				WOTI.WorkOrderTaskId,
				WOT.TaskId,
				WOT.TaskName,
				WOTI.InstructionTitle,
				WOTI.InstructionDetails,
				WOTI.SequenceNumber,
				WOTI.TechId,
				WOTI.TechName,
				WOTI.TechUpdatedDate,
				WOTI.InspectorId,
				WOTI.InspectorName,
				WOTI.InspectorUpdatedDate,
				WOTI.PrintInWO,
				WOTI.PrintInWOQ,
				WOTI.MasterCompanyId,
				WOTI.IsActive,
				WOTI.IsDeleted,
				WOTI.IsParent,
				WOTI.ParentId,
				CAST(WOTI.SequenceNumber AS VARCHAR(MAX)) AS ParentSequenceNumber
			FROM [dbo].[WorkOrderTaskInstruction] WOTI WITH (NOLOCK)
			LEFT JOIN [dbo].[WorkOrderTask] WOT WITH (NOLOCK) ON WOT.WorkOrderTaskId = WOTI.WorkOrderTaskId
			WHERE WOTI.ParentId IS NULL

			UNION ALL

			-- Recursive member (child instructions)
			SELECT 
				WOTI.WorkOrderTaskInstructionId,
				WOTI.WorkOrderTaskId,
				WOT.TaskId,
				WOT.TaskName,
				WOTI.InstructionTitle,
				WOTI.InstructionDetails,
				WOTI.SequenceNumber,
				WOTI.TechId,
				WOTI.TechName,
				WOTI.TechUpdatedDate,
				WOTI.InspectorId,
				WOTI.InspectorName,
				WOTI.InspectorUpdatedDate,
				WOTI.PrintInWO,
				WOTI.PrintInWOQ,
				WOTI.MasterCompanyId,
				WOTI.IsActive,
				WOTI.IsDeleted,
				WOTI.IsParent,
				WOTI.ParentId,
				CAST(R.ParentSequenceNumber + '.' + CAST(WOTI.SequenceNumber AS VARCHAR(MAX)) AS VARCHAR(MAX)) AS ParentSequenceNumber
			FROM [dbo].[WorkOrderTaskInstruction] WOTI WITH (NOLOCK)
			INNER JOIN [dbo].[WorkOrderTask] WOT WITH (NOLOCK) ON WOT.WorkOrderTaskId = WOTI.WorkOrderTaskId
			INNER JOIN RecursiveCTE R ON WOTI.ParentId = R.WorkOrderTaskInstructionId
		)

		UPDATE WOTI
		SET 
			WOTI.SequenceNumber = R.SequenceNumber,
			WOTI.ParentSequenceNumber = R.ParentSequenceNumber,
			WOTI.UpdatedBy = @UpdatedBy,
			WOTI.UpdatedDate = GETUTCDATE()
		FROM [dbo].[WorkOrderTaskInstruction] WOTI
		INNER JOIN RecursiveCTE R ON WOTI.WorkOrderTaskInstructionId = R.WorkOrderTaskInstructionId;

		-- Add Work Order Task Instruction History
		EXEC dbo.USP_InsertWorkOrderTaskInstructionHistory @WorkOrderTaskInstructionId , @UpdatedBy , @InstructionListId , @NewWorkOrderTaskInstructionId, @IsFromWorkFlow;

		-- Add Work Order Task History
		EXEC dbo.USP_AddWorkOrderTaskHistory @WorkOrderTaskId , @UpdatedBy , @WorkOrderTaskInstructionId , NULL;

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
	   , @AdhocComments     VARCHAR(150)    = 'USP_UpdateWOTaskInstructionSequenceNumber'         
	   , @ProcedureParameters VARCHAR(3000)  = '@WorkOrderTaskInstructionId = '''+ ISNULL(@WorkOrderTaskInstructionId, '') + ''        
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