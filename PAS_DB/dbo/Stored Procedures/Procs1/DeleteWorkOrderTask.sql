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
	2   04/10/2024   Ekta Chandegra		Add history when rearrange sequence number

EXEC [DeleteWorkOrderTask] 3
**************************************************************/
CREATE   PROCEDURE [dbo].[DeleteWorkOrderTask]
	@WorkOrderTaskId BIGINT,
	@UpdatedBy VARCHAR(100)
AS
	BEGIN
	BEGIN TRY
	BEGIN TRANSACTION
		DECLARE @StatusCode VARCHAR(100), @TemplateBody VARCHAR(MAX);
		DECLARE @TaskName VARCHAR(500);
		DECLARE @ModuleId INT, @SubModuleId INT, @MasterCompanyId INT;
		DECLARE @WorkOrderId BIGINT, @WorkOrderPartNoId BIGINT;

		SELECT @ModuleId = ModuleId FROM dbo.Module WITH(NOLOCK) WHERE ModuleId = 15;
		SELECT @SubModuleId = ModuleId FROM dbo.Module WITH(NOLOCK) WHERE [ModuleName] = 'WorkOrderTask';

		SELECT @TaskName = WOT.TaskName, @WorkOrderId = WOT.WorkOrderId, @WorkOrderPartNoId = WOT.WorkOrderPartNumberId, @MasterCompanyId = WOT.MasterCompanyId FROM DBO.WorkOrderTask WOT WITH (NOLOCK) WHERE WOT.WorkOrderTaskId = @WorkOrderTaskId

		/* Teardown deletion */
		DELETE FROM DBO.WorkOrderTask WHERE WorkOrderTaskId = @WorkOrderTaskId;
			
		/* Work Order Task */
		DELETE FROM DBO.WorkOrderTaskDetails WHERE WorkOrderTaskId = @WorkOrderTaskId;

		/* Add Entry in History Table */
		SET @StatusCode = 'DeleteWorkOrderTask';

		SELECT @TemplateBody = TemplateBody FROM dbo.HistoryTemplate WITH(NOLOCK) WHERE TemplateCode = @StatusCode;

		SET @TemplateBody = REPLACE(@TemplateBody, '##TaskName##', ISNULL(@TaskName,''));

		EXEC USP_History @ModuleId, @WorkOrderId, @SubModuleId, @WorkOrderPartNoId, @TaskName, '', @TemplateBody, @StatusCode, @MasterCompanyId, @UpdatedBy, NULL, @UpdatedBy, NULL

		/* Resequence the remaining tasks */
		DECLARE @TempSequence TABLE (WorkOrderTaskId BIGINT, SequenceNumber INT);

		INSERT INTO @TempSequence (WorkOrderTaskId, SequenceNumber)
		SELECT WorkOrderTaskId, 
			   ROW_NUMBER() OVER (ORDER BY SequenceNumber)
		FROM [dbo].[WorkOrderTask] WITH(NOLOCK)
		WHERE WorkOrderId = @WorkOrderId;

		-- Update the sequence numbers
		UPDATE WOT
		SET WOT.SequenceNumber = TS.SequenceNumber
		FROM [dbo].[WorkOrderTask] WOT
		INNER JOIN @TempSequence TS ON WOT.WorkOrderTaskId = TS.WorkOrderTaskId;

		-- Add sequence change history
		DECLARE @WOTID BIGINT, @SeqNum INT;
			DECLARE cur CURSOR FOR 
				SELECT WorkOrderTaskId, SequenceNumber 
				FROM @TempSequence;

			OPEN cur;
			FETCH NEXT FROM cur INTO @WOTID, @SeqNum;

			WHILE @@FETCH_STATUS = 0
			BEGIN
				EXEC [dbo].[USP_AddWorkOrderTaskHistory] @WOTID, @UpdatedBy, 0, @SeqNum;
				FETCH NEXT FROM cur INTO @WOTID, @SeqNum;
			END

			CLOSE cur;
			DEALLOCATE cur;

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