/***************************************************************  
 ** File:   [USP_SaveDefaultTemplateTaskInstruction]             
 ** Author:   Devendra Shekh
 ** Description: This stored procedure is used to save Default Task Instruction to Work FLow Task Details
 ** Date:  11-March-2025
            
  ** Change History             
 **************************************************************             
 ** PR   Date				Author  				Change Description              
 ** --   --------			-------				--------------------------------            
    1    11-March-2025		Devendra Shekh			Created
    2    12-March-2025		Devendra Shekh			Changed Cursor to While Loop
    3    14-May-2025		Devendra Shekh			passing Selected TaskIds to Save task if not exists
	4    23-May-2025        Sahdev Saliya           Setting Value For @IsNewAdded to 1
	5    02-Sep-2026		SUMIT KUMAR				[PN-17813] Copy images from TaskInstructionImage to WorkFlowDirectionImage for each inserted WorkflowDirectionId           

declare @p5 bit
set @p5=NULL
exec dbo.USP_SaveDefaultTemplateTaskInstruction @WorkflowId=5195,@UserName=N'ADMIN User',@TaskId=10,@MasterCompanyId=1,@IsNewAdded=@p5 output
select @p5
**************************************************************/
CREATE   PROCEDURE [dbo].[USP_SaveDefaultTemplateTaskInstruction]
    @WorkflowId BIGINT = NULL,
    @UserName VARCHAR(256) = NULL,
    @TaskId BIGINT = NULL,
    @MasterCompanyId INT = NULL,
	@TaskIds VARCHAR(500) = NULL,
	@IsNewAdded BIT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	BEGIN TRY

		DECLARE @MaxSequence INT;
		DECLARE @TotalRow INT, @CurrentRow INT;
		DECLARE @NewWorkflowDirectionId BIGINT;
		DECLARE @WorkFlowNumber VARCHAR(256),
				@TaskDescription VARCHAR(200),
				@SequenceNumber INT,
				@Descrepancy NVARCHAR(MAX) = '',
				@Resolution NVARCHAR(MAX) = '',
				@IsVersionIncrease BIT = 0;

		IF OBJECT_ID(N'tempdb..#TempTaskInstructions') IS NOT NULL
		BEGIN
			DROP TABLE #TempTaskInstructions
		END

		CREATE TABLE #TempTaskInstructions (
			RowId INT IDENTITY(1,1) NOT NULL,
			TaskInstructionId BIGINT NULL,
			Title VARCHAR(8000) NULL,
			ParentId INT NULL,
			IsParent BIT NULL,
			SequenceNumber INT NULL,
			[Description] VARCHAR(MAX) NULL,
		);

		-- Temporary table to store mapping of old TaskInstructionId to new WorkflowDirectionId
		DECLARE @IdMapping TABLE (
			TaskInstructionId INT,
			WorkflowDirectionId INT
		);
			
		-- CTE to get the hierarchy of tasks based on @InstructionListId
		;WITH RecursiveCTE AS (
			SELECT * 
			FROM DBO.TaskInstructionMaster WITH (NOLOCK)
			WHERE TaskId = @TaskId AND ISNULL(IsDefaultInstruction, 0) = 1
			AND IsDeleted = 0

			UNION ALL

			SELECT t.*
			FROM DBO.TaskInstructionMaster t WITH (NOLOCK)
			INNER JOIN RecursiveCTE r
			ON t.ParentId = r.TaskInstructionId
			WHERE t.IsDeleted = 0
		)

		INSERT INTO #TempTaskInstructions ([TaskInstructionId], [Title], [ParentId], [IsParent], [SequenceNumber], [Description])
		SELECT TaskInstructionId, Title, ParentId, IsParent, SequenceNumber, [Description] FROM RecursiveCTE ORDER BY ISNULL(ParentId, TaskInstructionId), SequenceNumber;

		-- Variables to hold row data
		DECLARE @TaskInstructionId INT,
				@InstructionTitle VARCHAR(8000),
				@InstructionkDescription VARCHAR(MAX),
				@InstructionParentId INT,
				@IsInstructionParent BIT,
				@InstructionSequenceNumber INT,
				@NewParentId INT;

		SELECT @TotalRow = COUNT(RowId), @CurrentRow = MIN(RowId) FROM #TempTaskInstructions;

		WHILE (ISNULL(@TotalRow, 0) >= ISNULL(@CurrentRow, 0)) AND ISNULL(@TotalRow, 0) > 0
		BEGIN

			SELECT	@TaskInstructionId = TaskInstructionId,
					@InstructionTitle = Title,
					@InstructionParentId = ParentId,
					@IsInstructionParent = IsParent,
					@InstructionSequenceNumber = SequenceNumber,
					@InstructionkDescription = [Description]
			FROM #TempTaskInstructions WHERE [RowId] = @CurrentRow;

			-- Get the new ParentId from mapping if the current record has a ParentId
			SET @NewParentId = NULL;
			IF @InstructionParentId IS NOT NULL
			BEGIN
				SELECT @NewParentId = WorkflowDirectionId FROM @IdMapping WHERE TaskInstructionId = @InstructionParentId;
			END

			-- Insert the record into WorkFlowDirection table
			INSERT INTO DBO.WorkFlowDirection (
				[WorkflowId], [Action], [Description], [TaskId], [Sequence], [ParentId], [IsParent], 
				[MasterCompanyId], [CreatedBy], [UpdatedBy], [CreatedDate], [UpdatedDate], [IsActive], [IsDeleted], [IsTaskDetails]
			)
			VALUES (
				@WorkflowId, @InstructionTitle, @InstructionkDescription, @TaskId, @InstructionSequenceNumber, @NewParentId, @IsInstructionParent,
				@MasterCompanyId, @UserName, @UserName, GETUTCDATE(), GETUTCDATE(), 1, 0, 0
			);

			-- Get the newly generated ID
			SET @NewWorkflowDirectionId = SCOPE_IDENTITY();

			-- Store the mapping of TaskInstructionId to the new WorkflowDirectionId
			INSERT INTO @IdMapping (TaskInstructionId, WorkflowDirectionId)
			VALUES (@TaskInstructionId, @NewWorkflowDirectionId);

			SET @CurrentRow += 1;
		END

		SET @IsNewAdded = 0;
		 
		IF(ISNULL(@NewWorkflowDirectionId, 0) > 0)
		BEGIN
			-- Storing Task To WorkFlowTask if Default TaskInstruction is Added
			SELECT @MaxSequence = ISNULL(MAX(CAST(WFT.SequenceNumber AS DECIMAL)), 0)
			FROM [dbo].[WorkFlowTask] WFT WITH (NOLOCK)
			WHERE WFT.MasterCompanyId = @MasterCompanyId AND WFT.WorkFlowId = @WorkFlowId;

			SELECT @WorkFlowNumber = [WorkOrderNumber] FROM [dbo].[Workflow] WITH(NOLOCK) WHERE [WorkflowId] = @WorkflowId;
				
			SET @SequenceNumber = CASE WHEN ISNULL(CAST(@SequenceNumber AS DECIMAL), 0) > ISNULL(@MaxSequence, 0) THEN @SequenceNumber ELSE ISNULL(@MaxSequence, 0) + 1 END;

			SELECT @Descrepancy = [Descrepancy], @Resolution = [Resolution], @TaskDescription = [Description] FROM [dbo].[Task] WITH(NOLOCK) WHERE [TaskId] = @TaskId AND [MasterCompanyId] = @MasterCompanyId;

			INSERT INTO [dbo].[WorkFlowTask]
			(	[WorkFlowId], [WorkFlowNumber], [TaskId], [TaskDescription], [SequenceNumber], [Descrepancy], [Resolution], [IsVersionIncrease], [MasterCompanyId],
				[CreatedBy], [CreatedDate], [UpdatedBy], [UpdatedDate], [IsActive], [IsDeleted]
			)
			VALUES
			(	@WorkflowId, @WorkFlowNumber, @TaskId, @TaskDescription, CAST(@SequenceNumber AS VARCHAR(10)), @Descrepancy, @Resolution, @IsVersionIncrease, @MasterCompanyId,
				@UserName, GETUTCDATE(), @UserName, GETUTCDATE(), 1, 0
			);

			-- Copy images from TaskInstructionImage to WorkFlowDirectionImage using @IdMapping and direct WorkFlowTask JOIN
			INSERT INTO [dbo].[WorkFlowDirectionImage]
				([WorkflowDirectionId], [WorkflowId], [TaskId], [WorkFlowTaskId], [FileName], [Link], [FileType], [FileSize], [MasterCompanyId], [CreatedBy], [UpdatedBy], [CreatedDate], [UpdatedDate], [IsActive], [IsDeleted])
			SELECT 
				MAP.WorkflowDirectionId, @WorkflowId, @TaskId, WFT.WorkFlowTaskId, TIMG.[FileName], TIMG.[Link], TIMG.[FileType], TIMG.[FileSize], @MasterCompanyId, @UserName, @UserName, GETUTCDATE(), GETUTCDATE(), 1, 0
			FROM [dbo].[TaskInstructionImage] TIMG WITH (NOLOCK)
			INNER JOIN @IdMapping MAP ON TIMG.TaskInstructionId = MAP.TaskInstructionId
			LEFT JOIN [dbo].[WorkFlowTask] WFT WITH (NOLOCK) ON WFT.WorkFlowId = @WorkflowId AND WFT.TaskId = @TaskId AND ISNULL(WFT.IsDeleted, 0) = 0
			WHERE ISNULL(TIMG.[IsActive], 1) = 1 AND ISNULL(TIMG.[IsDeleted], 0) = 0;

			SET @IsNewAdded = 1;
		END

		IF(ISNULL(@TaskIds, '') <> '')
		BEGIN
			DECLARE @TotalRows INT, @CurrentRowId INT;

			IF OBJECT_ID(N'tempdb..#TempWorkFlowTask') IS NOT NULL
			BEGIN
				DROP TABLE #TempWorkFlowTask
			END

			SELECT ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS RowId, value AS TaskId INTO #TempWorkFlowTask FROM STRING_SPLIT(@TaskIds, ',')

			SELECT @TotalRows = COUNT(RowId), @CurrentRowId = MIN(RowId) FROM #TempWorkFlowTask;

			IF(ISNULL(@TotalRows, 0) > 0)
			BEGIN
				WHILE(@TotalRows >= @CurrentRowId)
				BEGIN
					-- Storing Task To WorkFlowTask
					SELECT @TaskId = [TaskId] FROM #TempWorkFlowTask WHERE [RowId] = @CurrentRowId;

					SELECT @MaxSequence = ISNULL(MAX(CAST(WFT.SequenceNumber AS DECIMAL)), 0)
					FROM [dbo].[WorkFlowTask] WFT WITH (NOLOCK)
					WHERE WFT.MasterCompanyId = @MasterCompanyId AND WFT.WorkFlowId = @WorkFlowId;

					SELECT @WorkFlowNumber = [WorkOrderNumber] FROM [dbo].[Workflow] WITH(NOLOCK) WHERE [WorkflowId] = @WorkflowId;
				
					SET @SequenceNumber = CASE WHEN ISNULL(CAST(@SequenceNumber AS DECIMAL), 0) > ISNULL(@MaxSequence, 0) THEN @SequenceNumber ELSE ISNULL(@MaxSequence, 0) + 1 END;

					SELECT @Descrepancy = [Descrepancy], @Resolution = [Resolution], @TaskDescription = [Description] FROM [dbo].[Task] WITH(NOLOCK) WHERE [TaskId] = @TaskId AND [MasterCompanyId] = @MasterCompanyId;

					IF NOT EXISTS(SELECT 1 FROM [DBO].[WorkFlowTask] WITH(NOLOCK) WHERE [WorkFlowId] = @WorkflowId AND [TaskId] = @TaskId AND [MasterCompanyId] = @MasterCompanyId)
					BEGIN
						INSERT INTO [dbo].[WorkFlowTask]
						(	[WorkFlowId], [WorkFlowNumber], [TaskId], [TaskDescription], [SequenceNumber], [Descrepancy], [Resolution], [IsVersionIncrease], [MasterCompanyId],
							[CreatedBy], [CreatedDate], [UpdatedBy], [UpdatedDate], [IsActive], [IsDeleted]
						)
						VALUES
						(	@WorkflowId, @WorkFlowNumber, @TaskId, @TaskDescription, CAST(@SequenceNumber AS VARCHAR(10)), @Descrepancy, @Resolution, @IsVersionIncrease, @MasterCompanyId,
							@UserName, GETUTCDATE(), @UserName, GETUTCDATE(), 1, 0
						);

						SET @IsNewAdded = 1;
					END

					SET @CurrentRowId += 1;
				END
			END
		END

	END TRY   
	BEGIN CATCH      
	         DECLARE @ErrorLogID INT
			,@DatabaseName VARCHAR(100) = db_name()
			-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
			,@AdhocComments VARCHAR(150) = 'USP_SaveDefaultTemplateTaskInstruction'
			,@ProcedureParameters VARCHAR(3000) =
					'@Parameter1 = ''' + ISNULL(CAST(@WorkflowId AS VARCHAR(100)), '') + ''', '
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