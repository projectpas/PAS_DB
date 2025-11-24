/***************************************************************  
 ** File:   [USP_SaveWorkFlowMappingDetails]             
 ** Author:   Devendra Shekh
 ** Description: This stored procedure is used to save Work FLow Task Details
 ** Date:  27-Feb-2025
            
  ** Change History             
 **************************************************************             
 ** PR   Date				Author  				Change Description              
 ** --   --------			-------				--------------------------------            
    1    27-Feb-2025		Devendra Shekh			Created
    2    28-Feb-2025		Devendra Shekh			Added New Fields([Descrepancy], [Resolution], [IsVersionIncrease])

**************************************************************/
CREATE     PROCEDURE [dbo].[USP_SaveWorkFlowMappingDetails]
	@tbl_WorkFlowTaskType WorkFlowTaskType READONLY,
    @WorkFlowTaskIds VARCHAR(1000) = NULL,
    @SequenceUpdate BIT = NULL
AS
BEGIN
    SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	BEGIN TRY

		DECLARE @rowCount INT, @currentRow INT;
		DECLARE @MaxSequence INT;
		DECLARE @WorkFlowTaskId bigint,
				@WorkFlowId bigint,
				@WorkFlowNumber varchar(256),
				@TaskId bigint,
				@TaskDescription varchar(200),
				@SequenceNumber [decimal](10,3),
				@Descrepancy nvarchar(max),
				@Resolution nvarchar(max),
				@IsVersionIncrease bit,
				@MasterCompanyId int,
				@CreatedBy varchar(256),
				@UpdatedBy varchar(256);

		IF OBJECT_ID('tempdb..#TempWorkFlowTasks') IS NOT NULL
			DROP TABLE #TempWorkFlowTasks

		CREATE TABLE #TempWorkFlowTasks
		(
			[RecordId] [bigint] IDENTITY(1,1) NOT NULL,
			[WorkFlowTaskId] [bigint] NULL,
			[WorkFlowId] [bigint] NULL,
			[WorkFlowNumber] [varchar](256) NULL,
			[TaskId] [bigint] NULL,
			[TaskDescription] [varchar](200) NULL,
			[SequenceNumber] [decimal](10,3) NULL,
			[Descrepancy] [nvarchar](MAX) NULL,
			[Resolution] [nvarchar](MAX) NULL,
			[IsVersionIncrease] [bit] NULL,
			[MasterCompanyId] [int] NULL,
			[CreatedBy] [varchar](256) NULL,
			[CreatedDate] [datetime2](7) NULL,
			[UpdatedBy] [varchar](256) NULL,
			[UpdatedDate] [datetime2](7) NULL,
			[IsActive] [bit] NULL,
			[IsDeleted] [bit] NULL
		);

		IF(ISNULL(@SequenceUpdate, 0) = 0)
		BEGIN
			INSERT INTO #TempWorkFlowTasks
			([WorkFlowTaskId], [WorkFlowId], [WorkFlowNumber], [TaskId], [TaskDescription], [SequenceNumber], [Descrepancy], [Resolution], [IsVersionIncrease], [MasterCompanyId], 
			[CreatedBy], [CreatedDate], [UpdatedBy], [UpdatedDate], [IsActive], [IsDeleted])
			SELECT	[WorkFlowTaskId], [WorkFlowId], [WorkFlowNumber], [TaskId], [TaskDescription], [SequenceNumber], [Descrepancy], [Resolution], [IsVersionIncrease], [MasterCompanyId],
					[CreatedBy], [CreatedDate], [UpdatedBy], [UpdatedDate], [IsActive], [IsDeleted]
			FROM @tbl_WorkFlowTaskType
			WHERE [TaskId] IN (SELECT value FROM STRING_SPLIT(@WorkFlowTaskIds, ',')) ;
		END
		ELSE 
		BEGIN
			INSERT INTO #TempWorkFlowTasks
			([WorkFlowTaskId], [WorkFlowId], [WorkFlowNumber], [TaskId], [TaskDescription], [SequenceNumber], [Descrepancy], [Resolution], [IsVersionIncrease], [MasterCompanyId], 
			[CreatedBy], [CreatedDate], [UpdatedBy], [UpdatedDate], [IsActive], [IsDeleted])
			SELECT	[WorkFlowTaskId], [WorkFlowId], [WorkFlowNumber], [TaskId], [TaskDescription], [SequenceNumber], [Descrepancy], [Resolution], [IsVersionIncrease], [MasterCompanyId],
					[CreatedBy], [CreatedDate], [UpdatedBy], [UpdatedDate], [IsActive], [IsDeleted]
			FROM @tbl_WorkFlowTaskType
		END

		SELECT @rowCount = COUNT(RecordId), @currentRow = MIN(RecordId) FROM #TempWorkFlowTasks;

		WHILE @currentRow <= @rowCount
		BEGIN
			SELECT
				@WorkFlowTaskId = WorkFlowTaskId,
				@WorkFlowId = WorkFlowId,
				@WorkFlowNumber = WorkFlowNumber,
				@TaskId = TaskId,
				@TaskDescription = TaskDescription,
				@SequenceNumber = SequenceNumber,
				@Descrepancy = Descrepancy,
				@Resolution = Resolution,
				@IsVersionIncrease = IsVersionIncrease,
				@MasterCompanyId = MasterCompanyId,
				@CreatedBy = CreatedBy,
				@UpdatedBy = UpdatedBy
			FROM #TempWorkFlowTasks
			WHERE [RecordId] = @currentRow;

			IF(@currentRow = 1 AND ISNULL(@SequenceUpdate, 0) = 0)
			BEGIN
				DELETE FROM [dbo].[WorkFlowTask] WHERE [MasterCompanyId] = @MasterCompanyId AND [WorkFlowId] = @WorkFlowId AND [TaskId] NOT IN (SELECT value FROM STRING_SPLIT(@WorkFlowTaskIds, ',')) AND ISNULL([IsVersionIncrease], 0) = 0
			END

			IF EXISTS (SELECT [WorkFlowTaskId] FROM [dbo].[WorkFlowTask] WHERE [MasterCompanyId] = @MasterCompanyId AND [TaskId] = @TaskId AND [WorkFlowId] = @WorkFlowId AND [WorkFlowTaskId] = @WorkFlowTaskId)
			BEGIN
				UPDATE [dbo].[WorkFlowTask]
				SET	[SequenceNumber] = CASE WHEN ISNULL(@SequenceNumber, 0) = 0 THEN [SequenceNumber] ELSE @SequenceNumber END,
					[Descrepancy] = @Descrepancy,
					[Resolution] = @Resolution,
					[IsVersionIncrease] = @IsVersionIncrease,
					[UpdatedBy] = @UpdatedBy,
					[UpdatedDate] = GETUTCDATE()					
				WHERE	[MasterCompanyId] = @MasterCompanyId AND [TaskId] = @TaskId AND [WorkFlowId] = @WorkFlowId AND [WorkFlowTaskId] = @WorkFlowTaskId;
			END
			ELSE
			BEGIN

				SELECT @MaxSequence = ISNULL(MAX(WFT.SequenceNumber), 0)
				FROM [dbo].[WorkFlowTask] WFT WITH (NOLOCK)
				WHERE WFT.MasterCompanyId = @MasterCompanyId AND WFT.WorkFlowId = @WorkFlowId;
				
				SET @SequenceNumber = CASE WHEN ISNULL(@SequenceNumber, 0) > ISNULL(@MaxSequence, 0) THEN @SequenceNumber ELSE ISNULL(@MaxSequence, 0) + 1 END;

				SELECT @Descrepancy = [Descrepancy], @Resolution = [Resolution] FROM [dbo].[Task] WITH(NOLOCK) WHERE [TaskId] = @TaskId AND [MasterCompanyId] = @MasterCompanyId;

				INSERT INTO [dbo].[WorkFlowTask]
				(	[WorkFlowId], [WorkFlowNumber], [TaskId], [TaskDescription], [SequenceNumber], [Descrepancy], [Resolution], [IsVersionIncrease], [MasterCompanyId],
					[CreatedBy], [CreatedDate], [UpdatedBy], [UpdatedDate], [IsActive], [IsDeleted]
				)
				VALUES
				(	@WorkFlowId, @WorkFlowNumber, @TaskId, @TaskDescription, @SequenceNumber, @Descrepancy, @Resolution, @IsVersionIncrease, @MasterCompanyId,
					@CreatedBy, GETUTCDATE(), @UpdatedBy, GETUTCDATE(), 1, 0
				);
			END

			SET @currentRow = @currentRow + 1;
		END

	END TRY   
	BEGIN CATCH      
	         DECLARE @ErrorLogID INT
			,@DatabaseName VARCHAR(100) = db_name()
			-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
			,@AdhocComments VARCHAR(150) = 'USP_SaveWorkFlowMappingDetails'
			,@ProcedureParameters VARCHAR(3000) =
					'@Parameter1 = ''' + ISNULL(CAST(@WorkFlowTaskIds AS VARCHAR(100)), '') + ''', '
			,@ApplicationName VARCHAR(100) = 'PAS'

		-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
		EXEC spLogException @DatabaseName = @DatabaseName
			,@AdhocComments = @AdhocComments
			,@ProcedureParameters = @ProcedureParameters
			,@ApplicationName = @ApplicationName
			,@ErrorLogID = @ErrorLogID OUTPUT;

		RAISERROR (
				'Unexpected Error Occured in the database. Please let the support team know of the error number : %d'
				,16
				,1
				,@ErrorLogID
				)
		RETURN (1);           
	END CATCH
END;