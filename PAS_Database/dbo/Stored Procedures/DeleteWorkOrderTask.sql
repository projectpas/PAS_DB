/*************************************************************             
** File:   [DeleteWorkOrderTask]
** Author:   Vishal Suthar
** Description: This procedre is used to delete work order task
** Purpose:
** Date:   12/25/2024
**************************************************************
** Change History
**************************************************************
** PR   Date         Author				Change Description
** --   --------     -------			----------------------
	1   12/25/2024   Vishal Suthar		Created

EXEC [DeleteWorkOrderTask] 3
**************************************************************/
CREATE   PROCEDURE [dbo].[DeleteWorkOrderTask]
	@WorkOrderTaskId BIGINT
AS
	BEGIN
	BEGIN TRY
	BEGIN TRANSACTION
		/* Teardown deletion */
		DELETE FROM DBO.WorkOrderTask WHERE WorkOrderTaskId = @WorkOrderTaskId;
			
		/* Work Order Task */
		DELETE FROM DBO.WorkOrderTaskDetails WHERE WorkOrderTaskId = @WorkOrderTaskId;
	COMMIT TRANSACTION

	END TRY
	BEGIN CATCH
			IF @@trancount > 0
			PRINT 'ROLLBACK'
			ROLLBACK TRANSACTION;
				DECLARE @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'DeleteWorkOrderTask' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@WorkOrderTaskId, '') + ''
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