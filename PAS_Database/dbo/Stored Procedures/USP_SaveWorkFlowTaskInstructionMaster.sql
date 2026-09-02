/***************************************************************  
 ** File:   [USP_SaveWorkFlowTaskInstructionMaster]             
 ** Author:   Devendra Shekh
 ** Description: This stored procedure is used to save task Instruction Master For Work Flow
 ** Date:  07-Feb-2025
            
  ** Change History             
 **************************************************************             
 ** PR   Date				Author  					Change Description              
 ** --   --------			-------					--------------------------------            
    1    07-Feb-2025		Devendra Shekh					Created
    2    10-Feb-2025		Devendra Shekh					Modified (Checking TaskId as Well While Getting Max Sequence)
    3    11-Feb-2025		Devendra Shekh					Modified (Copying TaskInstructionMaster Data if @InstructionListId has value)
    4    05-March-2025		Devendra Shekh					Modified (Description related Issue resolved while add new)
    5    06-March-2025		Devendra Shekh					Modified ([Sequence] related Issue resolved)
    6    11-March-2025		Devendra Shekh					Modified (adding WorkFlowTask if not exists)
    7    24-March-2025		Ekta Chandegra					Cast GETUTCDATE value as DATE
    8    02-Sep-2026		SUMIT KUMAR						[PN-17813] Modified (Copying TaskInstructionImage to WorkFlowDirectionImage and linking WorkFlowTaskId)

exec dbo.USP_SaveWorkFlowTaskInstructionMaster 
@WorkflowDirectionId=0,@Title=N'RECEIVING',@Description=N'<p>RECEIVING</p>',@TaskId=11,@SequenceNumber=default,
@ParentId=default,@IsParent=default,@MasterCompanyId=1,@CreatedBy=N'Jim Roberts',@UpdatedBy=N'Jim Roberts',
@CreatedDate='2025-02-05 19:13:54.720',@UpdatedDate='2025-02-05 19:13:54.720',@IsActive=1,@IsDeleted=0,@WorkflowId=43
**************************************************************/
CREATE    PROCEDURE [dbo].[USP_SaveWorkFlowTaskInstructionMaster]
    @WorkflowDirectionId BIGINT = NULL,
    @Title VARCHAR(8000) = NULL,
    @Description VARCHAR(MAX) = NULL,
    @TaskId BIGINT = NULL,
    @SequenceNumber INT = NULL,
    @ParentId BIGINT = NULL,
    @IsParent BIT = NULL,
    @MasterCompanyId INT,
    @CreatedBy VARCHAR(100),
    @UpdatedBy VARCHAR(100),
    @CreatedDate DATETIME2,
    @UpdatedDate DATETIME2,
    @IsActive BIT,
    @IsDeleted BIT,
	@IsAddChildNode BIT = NULL,
	@IsTaskDetails BIT = NULL,
	@WorkflowId BIGINT = NULL,
	@InstructionListId BIGINT = NULL
AS
BEGIN
    SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	BEGIN TRY

		IF (ISNULL(@WorkflowDirectionId, 0) = 0)
		BEGIN
			-- Resolve existing WorkFlowTaskId for this Workflow and Task if already present
			DECLARE @WorkFlowTaskId BIGINT = NULL;
			SELECT TOP 1 @WorkFlowTaskId = WorkFlowTaskId 
			FROM [dbo].[WorkFlowTask] WITH (NOLOCK) 
			WHERE WorkFlowId = @WorkflowId AND TaskId = @TaskId AND ISNULL(IsDeleted, 0) = 0;

			IF (ISNULL(@InstructionListId, '') <> '')
			BEGIN

				IF OBJECT_ID(N'tempdb..#TempTaskInstructions') IS NOT NULL
				BEGIN
					DROP TABLE #TempTaskInstructions
				END

				-- Create temporary table to store task instruction hierarchy
				CREATE TABLE #TempTaskInstructions (
					TaskInstructionId INT, 
					Title NVARCHAR(MAX), 
					ParentId INT, 
					IsParent BIT, 
					SequenceNumber INT,
					[Description] NVARCHAR(MAX)
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
					WHERE TaskInstructionId IN (SELECT Item FROM DBO.SPLITSTRING(@InstructionListId, ','))
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

				-- Cursor to process records in the correct parent-child sequence
				DECLARE TaskCursor CURSOR FOR
				SELECT 
					TaskInstructionId, 
					Title, 
					ParentId, 
					IsParent, 
					SequenceNumber,
					[Description]
				FROM #TempTaskInstructions;

				-- Variables to hold row data
				DECLARE @TaskInstructionId INT,
						@InstructionTitle VARCHAR(8000),
						@InstructionkDescription VARCHAR(MAX),
						@InstructionParentId INT,
						@IsInstructionParent BIT,
						@InstructionSequenceNumber INT,
						@NewParentId INT;

				OPEN TaskCursor;
				FETCH NEXT FROM TaskCursor INTO @TaskInstructionId, @InstructionTitle, @InstructionParentId, @IsInstructionParent, @InstructionSequenceNumber, @InstructionkDescription;

				WHILE @@FETCH_STATUS = 0
				BEGIN
					-- Get the new ParentId from mapping if the current record has a ParentId
					SET @NewParentId = NULL;
					IF @InstructionParentId IS NOT NULL
					BEGIN
						SELECT @NewParentId = WorkflowDirectionId FROM @IdMapping WHERE TaskInstructionId = @InstructionParentId;
					END
					
					IF EXISTS (SELECT 1 FROM DBO.SPLITSTRING(@InstructionListId, ',') WHERE Item = @TaskInstructionId)
					BEGIN
						SELECT @InstructionSequenceNumber = ISNULL(MAX(TIM.Sequence), 0)
						FROM DBO.WorkFlowDirection TIM WITH (NOLOCK)
						WHERE TIM.MasterCompanyId = @MasterCompanyId AND ISNULL(TIM.ParentId, 0) = 0 AND TIM.WorkflowId = @WorkflowId AND [TaskId] = @TaskId;

						SET @InstructionSequenceNumber = ISNULL(@InstructionSequenceNumber, 0) + 1;
						SET @IsInstructionParent = 1;
					END

					SET @InstructionkDescription = CASE WHEN ISNULL(@Description, '') = '' THEN @InstructionkDescription ELSE @Description END;
				
					-- Insert the record into WorkFlowDirection table
					INSERT INTO DBO.WorkFlowDirection (
						[WorkflowId], [Action], [Description], [TaskId], [Sequence], [ParentId], [IsParent], 
						[MasterCompanyId], [CreatedBy], [UpdatedBy], [CreatedDate], [UpdatedDate], [IsActive], [IsDeleted], [IsTaskDetails]
					)
					VALUES (
						@WorkflowId, @InstructionTitle, @InstructionkDescription, @TaskId, @InstructionSequenceNumber, @NewParentId, @IsInstructionParent,
						@MasterCompanyId, @CreatedBy, @CreatedBy,  CAST(GETUTCDATE() AS DATE), CAST(GETUTCDATE() AS DATE), 1, 0, 0
					);

					-- Get the newly generated ID
					DECLARE @NewWorkflowDirectionId INT = SCOPE_IDENTITY();

					-- Store the mapping of TaskInstructionId to the new WorkflowDirectionId
					INSERT INTO @IdMapping (TaskInstructionId, WorkflowDirectionId)
					VALUES (@TaskInstructionId, @NewWorkflowDirectionId);

					-- Copy images from TaskInstructionImage to WorkFlowDirectionImage if available
					INSERT INTO [dbo].[WorkFlowDirectionImage]
						([WorkflowDirectionId], [WorkflowId], [TaskId], [WorkFlowTaskId], [FileName], [Link], [FileType], [FileSize], [MasterCompanyId], [CreatedBy], [UpdatedBy], [CreatedDate], [UpdatedDate], [IsActive], [IsDeleted])
					SELECT 
						@NewWorkflowDirectionId, @WorkflowId, @TaskId, @WorkFlowTaskId, [FileName], [Link], [FileType], [FileSize], @MasterCompanyId, @CreatedBy, @CreatedBy, GETUTCDATE(), GETUTCDATE(), 1, 0
					FROM [dbo].[TaskInstructionImage] WITH (NOLOCK)
					WHERE [TaskInstructionId] = @TaskInstructionId
					  AND ISNULL([IsActive], 1) = 1
					  AND ISNULL([IsDeleted], 0) = 0;

					-- Move to the next record
					FETCH NEXT FROM TaskCursor INTO @TaskInstructionId, @InstructionTitle, @InstructionParentId, @IsInstructionParent, @InstructionSequenceNumber, @InstructionkDescription;
				END
				-- Close and deallocate cursor resources to prevent memory leaks and cursor collision errors
				CLOSE TaskCursor;
				DEALLOCATE TaskCursor;
			END
			ELSE
			BEGIN
				DECLARE @MaxSequence INT;
				DECLARE @InsertedWorkflowDirectionId BIGINT = 0;

				SELECT @MaxSequence = ISNULL(MAX(TIM.Sequence), 0)
				FROM DBO.WorkFlowDirection TIM WITH (NOLOCK)
				WHERE TIM.MasterCompanyId = @MasterCompanyId AND ISNULL(TIM.ParentId, 0) = 0 AND TIM.WorkflowId = @WorkflowId AND [TaskId] = @TaskId;

				-- Insert new standalone top-level instruction node
				INSERT INTO DBO.WorkFlowDirection ([WorkflowId], [Action], [Description], [TaskId], [Sequence], [ParentId], [IsParent], 
				[MasterCompanyId], [CreatedBy], [UpdatedBy], [CreatedDate], [UpdatedDate], [IsActive], [IsDeleted], [IsTaskDetails])
				SELECT @WorkflowId, @Title, @Description, ISNULL(@TaskId, 0), (@MaxSequence + 1), NULL, 1, 
				@MasterCompanyId, @CreatedBy, @CreatedBy, GETUTCDATE(), GETUTCDATE(), 1, 0, @IsTaskDetails;

				SET @InsertedWorkflowDirectionId = SCOPE_IDENTITY();
			END

			IF NOT EXISTS(SELECT [WorkFlowTaskId] FROM [dbo].[WorkFlowTask] WITH(NOLOCK) WHERE [TaskId] = @TaskId AND [WorkFlowId] = @WorkflowId AND [MasterCompanyId] = @MasterCompanyId)
			BEGIN
				-- Storing Task To WorkFlowTask if Default TaskInstruction is Added
				DECLARE @WorkFlowNumber VARCHAR(256),
						@TaskDescription VARCHAR(200),
						@TaskSequenceNumber INT,
						@Descrepancy NVARCHAR(MAX) = '',
						@Resolution NVARCHAR(MAX) = '',
						@IsVersionIncrease BIT = 0;

				SELECT @MaxSequence = ISNULL(MAX(WFT.SequenceNumber), 0)
				FROM [dbo].[WorkFlowTask] WFT WITH (NOLOCK)
				WHERE WFT.MasterCompanyId = @MasterCompanyId AND WFT.WorkFlowId = @WorkFlowId;

				SELECT @WorkFlowNumber = [WorkOrderNumber] FROM [dbo].[Workflow] WITH(NOLOCK) WHERE [WorkflowId] = @WorkflowId;
				
				SET @TaskSequenceNumber = CASE WHEN ISNULL(@TaskSequenceNumber, 0) > ISNULL(@MaxSequence, 0) THEN @TaskSequenceNumber ELSE ISNULL(@MaxSequence, 0) + 1 END;

				SELECT @Descrepancy = [Descrepancy], @Resolution = [Resolution], @TaskDescription = [Description] FROM [dbo].[Task] WITH(NOLOCK) WHERE [TaskId] = @TaskId AND [MasterCompanyId] = @MasterCompanyId;

				INSERT INTO [dbo].[WorkFlowTask]
				(	[WorkFlowId], [WorkFlowNumber], [TaskId], [TaskDescription], [SequenceNumber], [Descrepancy], [Resolution], [IsVersionIncrease], [MasterCompanyId],
					[CreatedBy], [CreatedDate], [UpdatedBy], [UpdatedDate], [IsActive], [IsDeleted]
				)
				VALUES
				(	@WorkflowId, @WorkFlowNumber, @TaskId, @TaskDescription, @TaskSequenceNumber, @Descrepancy, @Resolution, @IsVersionIncrease, @MasterCompanyId,
					@CreatedBy, GETUTCDATE(), @CreatedBy, GETUTCDATE(), 1, 0
				);

				SET @WorkFlowTaskId = SCOPE_IDENTITY();

				-- Update any copied images with the newly created WorkFlowTaskId
				UPDATE [dbo].[WorkFlowDirectionImage]
				SET [WorkFlowTaskId] = @WorkFlowTaskId
				WHERE [WorkflowId] = @WorkflowId AND [TaskId] = @TaskId AND [WorkFlowTaskId] IS NULL;
			END
		END
		ELSE IF (@IsAddChildNode = 1)
		BEGIN
			-- Find the maximum sequence number under the specific parent
			DECLARE @MaxSequenceNumber INT;
			SELECT @MaxSequenceNumber = ISNULL(MAX(Sequence), 0)
			FROM DBO.WorkFlowDirection
			WHERE ParentId = @WorkflowDirectionId AND WorkflowId = @WorkflowId AND [TaskId] = @TaskId;

			-- Determine the new sequence number for the child
			DECLARE @NewSequenceNumber INT = @MaxSequenceNumber + 1;

			-- Insert the new child node with the next sequence number
			INSERT INTO DBO.WorkFlowDirection ([WorkflowId], [Action], [Description], [TaskId],  [Sequence],  [ParentId],  [IsParent], 
			[MasterCompanyId], [CreatedBy], [UpdatedBy], [CreatedDate], [UpdatedDate], [IsActive], [IsDeleted], [IsTaskDetails])
			VALUES (@WorkflowId, @Title, @Description,  ISNULL(@TaskId, 0), @NewSequenceNumber, @WorkflowDirectionId, 0, 
			@MasterCompanyId, @CreatedBy, @CreatedBy, GETUTCDATE(), GETUTCDATE(), 1, 0, @IsTaskDetails);

			SET @InsertedWorkflowDirectionId = SCOPE_IDENTITY();
		END
		ELSE
		BEGIN
			-- Update existing instruction details
			UPDATE [dbo].[WorkFlowDirection]
			SET 
				[Action] = @Title,
				[Description] = @Description,
				[TaskId] = @TaskId,
				[UpdatedBy] = @UpdatedBy,
				[UpdatedDate] = GETUTCDATE()
			WHERE [WorkflowDirectionId] = @WorkflowDirectionId AND [MasterCompanyId] = @MasterCompanyId AND WorkflowId = @WorkflowId;
		END

		-- Output created or updated WorkflowDirectionId result set
		SELECT ISNULL(NULLIF(@WorkflowDirectionId, 0), @InsertedWorkflowDirectionId) AS WorkflowDirectionId;

	END TRY   
	BEGIN CATCH      
	         DECLARE @ErrorLogID INT
			,@DatabaseName VARCHAR(100) = db_name()
			-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
			,@AdhocComments VARCHAR(150) = 'USP_SaveWorkFlowTaskInstructionMaster'
			,@ProcedureParameters VARCHAR(3000) =
					'@Parameter1 = ''' + ISNULL(CAST(@WorkflowDirectionId AS VARCHAR(100)), '') + ''', ' +
					'@Parameter2 = ''' + ISNULL(@Title, '') + ''', ' +
					'@Parameter3 = ''' + ISNULL(@Description, '') + ''', ' +
					'@Parameter4 = ''' + ISNULL(CAST(@TaskId AS VARCHAR(100)), '') + ''', ' +
					'@Parameter5 = ''' + ISNULL(CAST(@SequenceNumber AS VARCHAR(100)), '') + ''', ' +
					'@Parameter6 = ''' + ISNULL(CAST(@ParentId AS VARCHAR(100)), '') + ''', ' +
					'@Parameter7 = ''' + ISNULL(CAST(@IsParent AS VARCHAR(100)), '') + ''', ' +
					'@Parameter8 = ''' + ISNULL(CAST(@MasterCompanyId AS VARCHAR(100)), '') + ''', ' +
					'@Parameter9 = ''' + ISNULL(@CreatedBy, '') + ''', ' +
					'@Parameter10 = ''' + ISNULL(@UpdatedBy, '') + ''', ' +
					'@Parameter11 = ''' + ISNULL(CAST(@CreatedDate AS VARCHAR(100)), '') + ''', ' +
					'@Parameter12 = ''' + ISNULL(CAST(@UpdatedDate AS VARCHAR(100)), '') + ''', ' +
					'@Parameter13 = ''' + ISNULL(CAST(@IsActive AS VARCHAR(100)), '') + ''', ' +
					'@Parameter14 = ''' + ISNULL(CAST(@IsDeleted AS VARCHAR(100)), '') + ''''			                                           
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