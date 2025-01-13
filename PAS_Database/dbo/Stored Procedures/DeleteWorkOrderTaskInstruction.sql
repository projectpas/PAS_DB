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

EXEC [DeleteWorkOrderTaskInstruction] 3
**************************************************************/
CREATE   PROCEDURE [dbo].[DeleteWorkOrderTaskInstruction]
	@WorkOrderTaskInstructionId BIGINT
AS
	BEGIN
	BEGIN TRY
		DELETE FROM DBO.WorkOrderTaskInstruction WHERE WorkOrderTaskInstructionId = @WorkOrderTaskInstructionId;
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