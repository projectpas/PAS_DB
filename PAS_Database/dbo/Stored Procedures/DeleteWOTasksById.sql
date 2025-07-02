/*************************************************************             
** File:   [DeleteWOTasksById]
** Author:   Vishal Suthar
** Description: This procedre is used to delete all the work order tasks
** Purpose:
** Date:   07/01/2025
**************************************************************
** Change History
**************************************************************
** PR   Date         Author				Change Description
** --   --------     -------			----------------------
	1   07/01/2025   Vishal Suthar		Created

EXEC [DeleteWOTasksById] 3
**************************************************************/
CREATE   PROCEDURE [dbo].[DeleteWOTasksById]
	@WOPartNoId BIGINT
AS
	BEGIN
	BEGIN TRY
	BEGIN TRANSACTION
		
		DELETE FROM DBO.WorkOrderTaskDetails WHERE WorkOrderTaskId IN (SELECT WorkOrderTaskId FROM WorkOrderTask WHERE WorkOrderPartNumberId = @WOPartNoId);
		DELETE FROM DBO.WorkOrderTask WHERE WorkOrderPartNumberId = @WOPartNoId;

	COMMIT TRANSACTION

	END TRY
	BEGIN CATCH
		IF @@trancount > 0
		PRINT 'ROLLBACK'
		ROLLBACK TRANSACTION;
		DECLARE @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
        , @AdhocComments     VARCHAR(150)    = 'DeleteWOTasksById' 
        , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@WOPartNoId, '') + ''
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