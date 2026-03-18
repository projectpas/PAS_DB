/*************************************************************             
** File:   [DeleteRRHeaderById]
** Author:   Amit Ghediya
** Description: This procedre is used to delete ReceivingReconciliation header
** Purpose:
** Date:   18/03/2026
**************************************************************
** Change History
**************************************************************
** PR   Date         Author				Change Description
** --   --------     -------			----------------------
	1   18/03/2026   Amit Ghediya		Created

EXEC [DeleteRRHeaderById] 3
**************************************************************/
CREATE     PROCEDURE [dbo].[DeleteRRHeaderById]
	@ReceivingReconciliationId BIGINT
AS
	BEGIN
	BEGIN TRY
	BEGIN TRANSACTION
		
		DELETE FROM DBO.ReceivingReconciliationHeader WHERE [ReceivingReconciliationId] = @ReceivingReconciliationId;

	COMMIT TRANSACTION

	END TRY
	BEGIN CATCH
		IF @@trancount > 0
		PRINT 'ROLLBACK'
		ROLLBACK TRANSACTION;
		DECLARE @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
        , @AdhocComments     VARCHAR(150)    = 'DeleteRRHeaderById' 
        , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@ReceivingReconciliationId, '') + ''
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