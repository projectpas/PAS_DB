/***************************************************************
 ** File:   [USP_SaveWorkOrderTaskSequence]
 ** Author:   Vishal Suthar
 ** Description: This stored procedure is used to update Work Order Task Sequences
 ** Date:  28-Feb-2025
            
  ** Change History
 **************************************************************             
 ** PR   Date				Author  		Change Description              
 ** --   --------			-------			--------------------------------            
    1    28-Feb-2025		Vishal Suthar	Created

**************************************************************/
CREATE     PROCEDURE [dbo].[USP_SaveWorkOrderTaskSequence]
	@tbl_WorkOrderTasks WorkOrderTasks READONLY
AS
BEGIN
    SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	BEGIN TRY

		DECLARE @rowCount INT, @currentRow INT;
		DECLARE @MaxSequence INT;
		DECLARE @WorkOrderTaskId bigint,
				@TaskId bigint,
				@SequenceNumber int,
				@MasterCompanyId int,
				@UpdatedBy varchar(256);

		IF OBJECT_ID('tempdb..#TempWorkOrderTasks') IS NOT NULL
			DROP TABLE #TempWorkOrderTasks

		CREATE TABLE #TempWorkOrderTasks
		(
			[RecordId] [bigint] IDENTITY(1,1) NOT NULL,
			[WorkOrderTaskId] [bigint] NULL,
			[WorkOrderId] [bigint] NULL,
			[TaskId] [bigint] NULL,
			[SequenceNumber] [int] NULL,
			[MasterCompanyId] [int] NULL,
			[UpdatedBy] [varchar](256) NULL
		);

		INSERT INTO #TempWorkOrderTasks ([WorkOrderTaskId], [WorkOrderId], [TaskId], [SequenceNumber], [UpdatedBy], [MasterCompanyId])
		SELECT	[WorkOrderTaskId], [WorkOrderId], [TaskId], [SequenceNumber], [UpdatedBy], [MasterCompanyId] FROM @tbl_WorkOrderTasks
		
		SELECT @rowCount = COUNT(RecordId), @currentRow = MIN(RecordId) FROM #TempWorkOrderTasks;

		WHILE @currentRow <= @rowCount
		BEGIN
			SELECT
				@WorkOrderTaskId = WorkOrderTaskId,
				@TaskId = TaskId,
				@SequenceNumber = SequenceNumber,
				@UpdatedBy = UpdatedBy,
				@MasterCompanyId = MasterCompanyId
			FROM #TempWorkOrderTasks
			WHERE [RecordId] = @currentRow;

			UPDATE [dbo].[WorkOrderTask]
			SET	[SequenceNumber] = @SequenceNumber,
				[UpdatedBy] = @UpdatedBy,
				[UpdatedDate] = GETUTCDATE()					
			WHERE [MasterCompanyId] = @MasterCompanyId AND [WorkOrderTaskId] = @WorkOrderTaskId;

			SET @currentRow = @currentRow + 1;
		END

	END TRY   
	BEGIN CATCH      
	         DECLARE @ErrorLogID INT
			,@DatabaseName VARCHAR(100) = db_name()
			-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
			,@AdhocComments VARCHAR(150) = 'USP_SaveWorkOrderTaskSequence'
			,@ProcedureParameters VARCHAR(3000) = '@Parameter1 = '', '
			,@ApplicationName VARCHAR(100) = 'PAS'
		-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
		EXEC spLogException @DatabaseName = @DatabaseName
			,@AdhocComments = @AdhocComments
			,@ProcedureParameters = @ProcedureParameters
			,@ApplicationName = @ApplicationName
			,@ErrorLogID = @ErrorLogID OUTPUT;

		RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d',16,1,@ErrorLogID)
		RETURN (1);           
	END CATCH
END;