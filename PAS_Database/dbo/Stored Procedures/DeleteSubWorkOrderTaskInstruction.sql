/*************************************************************             
** File:   [DeleteSubWorkOrderTaskInstruction]
** Author:   Vishal Suthar
** Description: This procedre is used to delete sub work order task instruction
** Purpose:
** Date:   03/21/2025
**************************************************************
** Change History
**************************************************************
** PR   Date         Author				Change Description
** --   --------     -------			----------------------
	1   03/21/2025   Vishal Suthar		Created
	2   03/28/2025   Ekta Chandegra		Add Sub Work Order Task History

EXEC [DeleteSubWorkOrderTaskInstruction] 3
**************************************************************/
CREATE   PROCEDURE [dbo].[DeleteSubWorkOrderTaskInstruction]
	@SubWorkOrderTaskInstructionId BIGINT,
	@CreatedBy VARCHAR(256),
	@SubWorkOrderTaskId BIGINT
AS
	BEGIN
	BEGIN TRY

		EXEC dbo.USP_AddSubWorkOrderTaskHistory @SubWorkOrderTaskId, @CreatedBy, @SubWorkOrderTaskInstructionId, NULL

		;WITH CTE AS (
			-- Anchor member: Start with the record to be deleted
			SELECT SubWorkOrderTaskInstructionId
			FROM DBO.SubWorkOrderTaskInstruction WITH (NOLOCK)
			WHERE SubWorkOrderTaskInstructionId = @SubWorkOrderTaskInstructionId

			UNION ALL

			-- Recursive member: Get all child records
			SELECT w.SubWorkOrderTaskInstructionId
			FROM DBO.SubWorkOrderTaskInstruction w WITH (NOLOCK)
			INNER JOIN CTE c
			ON w.ParentId = c.SubWorkOrderTaskInstructionId
		)
		-- Delete all identified records
		DELETE FROM DBO.SubWorkOrderTaskInstruction
		WHERE SubWorkOrderTaskInstructionId IN (SELECT SubWorkOrderTaskInstructionId FROM CTE);

		UPDATE [dbo].[SubWorkOrderTaskHistory]
		SET IsDeleted = 1
		WHERE [SubWorkOrderTaskHistoryId] IN
		(
			SELECT TOP 1 [SubWorkOrderTaskHistoryId]
			FROM [dbo].[SubWorkOrderTaskHistory] WITH (NOLOCK)
			WHERE SubWorkOrderTaskInstructionId = @SubWorkOrderTaskInstructionId
			ORDER BY [SubWorkOrderTaskHistoryId] DESC
		) 
	END TRY
	BEGIN CATCH
			IF @@trancount > 0
			PRINT 'ROLLBACK'
			ROLLBACK TRANSACTION;
				DECLARE @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'DeleteSubWorkOrderTaskInstruction' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@SubWorkOrderTaskInstructionId, '') + ''
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