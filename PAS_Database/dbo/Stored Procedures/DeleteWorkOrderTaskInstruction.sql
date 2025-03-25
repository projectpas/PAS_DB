/*************************************************************             
** File:   [DeleteWorkOrderTaskInstruction]
** Author:   Vishal Suthar
** Description: This procedre is used to delete work order task instruction
** Purpose:
** Date:   01/13/2025
**************************************************************
** Change History
**************************************************************
** PR   Date         Author				Change Description
** --   --------     -------			----------------------
	1   01/13/2025   Vishal Suthar		Created
	2   03/21/2025   Ekta Chandegra		Add dbo.USP_AddWorkOrderTaskHistory call to add history
	3   03/24/2025   Ekta Chandegra		Update IsDeleted value of deleted Work Order Task Instruction in WorkOrderTaskHistory 

EXEC [DeleteWorkOrderTaskInstruction] 3
**************************************************************/
CREATE   PROCEDURE [dbo].[DeleteWorkOrderTaskInstruction]
	@WorkOrderTaskInstructionId BIGINT,
	@CreatedBy VARCHAR(256),
	@WorkOrderTaskId BIGINT
AS
	BEGIN
	BEGIN TRY

		EXEC dbo.USP_AddWorkOrderTaskHistory @WorkOrderTaskId,@CreatedBy,@WorkOrderTaskInstructionId,NULL

		;WITH CTE AS (
			-- Anchor member: Start with the record to be deleted
			SELECT WorkOrderTaskInstructionId
			FROM DBO.WorkOrderTaskInstruction WITH (NOLOCK)
			WHERE WorkOrderTaskInstructionId = @WorkOrderTaskInstructionId

			UNION ALL

			-- Recursive member: Get all child records
			SELECT w.WorkOrderTaskInstructionId
			FROM DBO.WorkOrderTaskInstruction w WITH (NOLOCK)
			INNER JOIN CTE c
			ON w.ParentId = c.WorkOrderTaskInstructionId
		)

		-- Delete all identified records
		DELETE FROM DBO.WorkOrderTaskInstruction
		WHERE WorkOrderTaskInstructionId IN (SELECT WorkOrderTaskInstructionId FROM CTE);

		UPDATE [dbo].[WorkOrderTaskHistory]
		SET IsDeleted = 1
		WHERE [WorkOrderTaskHistoryId] IN
		(
			SELECT TOP 1 [WorkOrderTaskHistoryId]
			FROM [dbo].[WorkOrderTaskHistory]
			WHERE WorkOrderTaskInstructionId = @WorkOrderTaskInstructionId
			ORDER BY [WorkOrderTaskHistoryId] DESC
		) 

	END TRY
	BEGIN CATCH
			IF @@trancount > 0
			PRINT 'ROLLBACK'
			ROLLBACK TRANSACTION;
				DECLARE @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'DeleteWorkOrderTaskInstruction' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@WorkOrderTaskInstructionId, '') + ''
              , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
              exec spLogException 
                       @DatabaseName           = @DatabaseName
                     , @AdhocComments          = @AdhocComments
                     , @ProcedureParameters = @ProcedureParameters
                     , @ApplicationName        =  @ApplicationName
                     , @ErrorLogID             = @ErrorLogID OUTPUT;
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
              RETURN(1);
	END CATCH
END