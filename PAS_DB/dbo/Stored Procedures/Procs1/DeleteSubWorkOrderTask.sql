/*************************************************************             
** File:   [DeleteSubWorkOrderTask]
** Author:   Vishal Suthar
** Description: This procedre is used to delete sub work order task
** Purpose:
** Date:   03/27/2025
**************************************************************
** Change History
**************************************************************
** PR   Date         Author				Change Description
** --   --------     -------			----------------------
	1   03/27/2025   Vishal Suthar		Created
	2   04/28/2025   Ekta Chandegra		Add history when rearrange sequence number

EXEC [DeleteSubWorkOrderTask] 3
**************************************************************/
CREATE   PROCEDURE [dbo].[DeleteSubWorkOrderTask]
	@SubWorkOrderTaskId BIGINT,
	@UpdatedBy VARCHAR(100)
AS
	BEGIN
	BEGIN TRY
	BEGIN TRANSACTION
		DECLARE @StatusCode VARCHAR(100), @TemplateBody VARCHAR(MAX);
		DECLARE @TaskName VARCHAR(500);
		DECLARE @ModuleId INT, @SubModuleId INT, @MasterCompanyId INT;
		DECLARE @WorkOrderId BIGINT, @SubWorkOrderPartNoId BIGINT;

		--SELECT @ModuleId = ModuleId FROM dbo.Module WITH(NOLOCK) WHERE ModuleId = 15;
		--SELECT @SubModuleId = ModuleId FROM dbo.Module WITH(NOLOCK) WHERE [ModuleName] = 'WorkOrderTask';

		SELECT @TaskName = WOT.TaskName, @WorkOrderId = WOT.WorkOrderId, @SubWorkOrderPartNoId = WOT.SubWOPartNoId, @MasterCompanyId = WOT.MasterCompanyId FROM DBO.SubWorkOrderTask WOT WITH (NOLOCK) WHERE WOT.SubWorkOrderTaskId = @SubWorkOrderTaskId

		/* Teardown deletion */
		DELETE FROM DBO.SubWorkOrderTask WHERE SubWorkOrderTaskId = @SubWorkOrderTaskId;
			
		/* Work Order Task */
		DELETE FROM DBO.SubWorkOrderTaskDetails WHERE SubWorkOrderTaskId = @SubWorkOrderTaskId;

		--/* Add Entry in History Table */
		--SET @StatusCode = 'DeleteWorkOrderTask';

		--SELECT @TemplateBody = TemplateBody FROM dbo.HistoryTemplate WITH(NOLOCK) WHERE TemplateCode = @StatusCode;

		--SET @TemplateBody = REPLACE(@TemplateBody, '##TaskName##', ISNULL(@TaskName,''));

		--EXEC USP_History @ModuleId, @WorkOrderId, @SubModuleId, @SubWorkOrderPartNoId, @TaskName, '', @TemplateBody, @StatusCode, @MasterCompanyId, @UpdatedBy, NULL, @UpdatedBy, NULL

		/* Resequence the remaining tasks */
		DECLARE @TempSequence TABLE (SubWorkOrderTaskId BIGINT, SequenceNumber INT);

		INSERT INTO @TempSequence (SubWorkOrderTaskId, SequenceNumber)
		SELECT SubWorkOrderTaskId, 
			   ROW_NUMBER() OVER (ORDER BY SequenceNumber)
		FROM [dbo].[SubWorkOrderTask] WITH(NOLOCK)
		WHERE WorkOrderId = @WorkOrderId;

		-- Update the sequence numbers
		UPDATE SWOT
		SET SWOT.SequenceNumber = TS.SequenceNumber
		FROM [dbo].[SubWorkOrderTask] SWOT
		INNER JOIN @TempSequence TS ON SWOT.SubWorkOrderTaskId = TS.SubWorkOrderTaskId;

		-- Add sequence change history
		DECLARE @WOTID BIGINT, @SeqNum INT;
			DECLARE cur CURSOR FOR 
				SELECT SubWorkOrderTaskId, SequenceNumber 
				FROM @TempSequence;

			OPEN cur;
			FETCH NEXT FROM cur INTO @WOTID, @SeqNum;

			WHILE @@FETCH_STATUS = 0
			BEGIN
				EXEC [dbo].[USP_AddSubWorkOrderTaskHistory] @WOTID, @UpdatedBy, 0, @SeqNum;
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
              , @AdhocComments     VARCHAR(150)    = 'DeleteSubWorkOrderTask' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@SubWorkOrderTaskId, '') + ''
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