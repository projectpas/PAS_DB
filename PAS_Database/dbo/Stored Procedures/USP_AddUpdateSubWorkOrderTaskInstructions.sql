/***************************************************************  
 ** File:   [USP_AddUpdateSubWorkOrderTaskInstructions]
 ** Author:   Vishal Suthar
 ** Description: This stored procedure is used add or update Work Order Task Instruction
 ** Purpose:
 ** Date:   03/20/2025

 ** Change History
 **************************************************************
 ** PR   Date         Author  		 Change Description
 ** --   --------     -------		 --------------------------------
    1    03/20/2025   Vishal Suthar	   Created
    2    03/25/2025   Vishal Suthar	   Fix for adding child node for Instruction
    3    03/27/2025   EKTA CHANDEGRA   Add history call for Sub Work Order Task Instructions and  Sub Work Order Task

**************************************************************/
CREATE   PROCEDURE [dbo].[USP_AddUpdateSubWorkOrderTaskInstructions]
	@SubWorkOrderTaskInstructionId BIGINT = NULL,
	@SubWorkOrderTaskId BIGINT,
	@TechId BIGINT = NULL,
	@TechName VARCHAR(100) = NULL,
	@TechUpdatedDate DATETIME2(7) = NULL,
	@InspectorId BIGINT = NULL,
	@InspectorName VARCHAR(100) = NULL,
	@InspectorUpdatedDate DATETIME2(7) = NULL,
	@PrintInWO BIT = NULL,
	@PrintInWOQ BIT = NULL,
	@InstructionListId VARCHAR(250) = NULL,
	@InstructionTitle VARCHAR(1000) = NULL,
	@InstructionDetails VARCHAR(MAX) = NULL,
	@CreatedBy VARCHAR(100) = NULL,
	@MasterCompanyId BIGINT = NULL,
	@IsAddChildNode BIT = NULL
AS
BEGIN
  SET NOCOUNT ON;
  SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
  BEGIN TRY
  BEGIN TRANSACTION
	
	IF (ISNULL(@SubWorkOrderTaskInstructionId, 0) = 0)
	BEGIN
		DECLARE @WorkOrderId BIGINT;
		DECLARE @MaxSequence INT;
		DECLARE @InsertedSubWorkOrderTaskInstructionId BIGINT = 0;
		DECLARE @TaskMasterLoopID AS INT;
		DECLARE @StatusCode VARCHAR(100), @TemplateBody VARCHAR(MAX), @TaskName VARCHAR(250), @InstructionTitleNew VARCHAR(MAX);
		DECLARE @ModuleId INT, @SubModuleId INT;
		DECLARE @WorkOrderPartNumberId BIGINT;

		SELECT @ModuleId = ModuleId FROM dbo.Module WITH(NOLOCK) WHERE ModuleId = 15;
		SELECT @SubModuleId = ModuleId FROM dbo.Module WITH(NOLOCK) WHERE [ModuleName] = 'WorkOrderTask';

		IF OBJECT_ID(N'tempdb..#TaskMaster') IS NOT NULL
		BEGIN
			DROP TABLE #TaskMaster
		END

		CREATE TABLE #TaskMaster
		(
			ID bigint NOT NULL IDENTITY,
			[TaskInstructionId] [bigint] NOT NULL,
			[Title] [varchar](8000) NULL,
			[Description] [varchar](max) NULL,
			[TaskId] [bigint] NOT NULL,
			[SequenceNumber] [int] NULL,
			[ParentId] [bigint] NULL,
			[IsParent] [bit] NULL,
			[MasterCompanyId] [int] NOT NULL,
			[CreatedBy] [varchar](100) NOT NULL,
			[UpdatedBy] [varchar](100) NOT NULL,
			[CreatedDate] [datetime2](7) NOT NULL,
			[UpdatedDate] [datetime2](7) NOT NULL,
			[IsActive] [bit] NOT NULL,
			[IsDeleted] [bit] NOT NULL
		)

		IF (ISNULL(@InstructionListId, '') <> '')
		BEGIN
			-- Temporary table to store mapping of old TaskInstructionId to new WorkOrderTaskInstructionId
			DECLARE @IdMapping TABLE (
				TaskInstructionId INT,
				WorkOrderTaskInstructionId INT
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

			SELECT 
				TaskInstructionId, 
				Title, 
				ParentId, 
				IsParent, 
				SequenceNumber,
				[Description]
			INTO #TempTaskInstructions
			FROM RecursiveCTE
			ORDER BY ISNULL(ParentId, TaskInstructionId), SequenceNumber;

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
					@Title NVARCHAR(MAX),
					@Description NVARCHAR(MAX),
					@ParentId INT,
					@IsParent BIT,
					@SequenceNumber INT,
					@NewParentId INT;

			OPEN TaskCursor;
			FETCH NEXT FROM TaskCursor INTO @TaskInstructionId, @Title, @ParentId, @IsParent, @SequenceNumber, @Description;

			WHILE @@FETCH_STATUS = 0
			BEGIN
				-- Get the new ParentId from mapping if the current record has a ParentId
				SET @NewParentId = NULL;
				IF @ParentId IS NOT NULL
				BEGIN
					SELECT @NewParentId = WorkOrderTaskInstructionId FROM @IdMapping WHERE TaskInstructionId = @ParentId;
				END

				-- Insert the record into WorkOrderTaskInstruction table
				INSERT INTO SubWorkOrderTaskInstruction (
					SubWorkOrderTaskId, 
					ParentId, 
					IsParent, 
					InstructionTitle, 
					SequenceNumber,
					[InstructionDetails],[TechId],[TechName],[TechUpdatedDate],[InspectorId],[InspectorName],
					[InspectorUpdatedDate],[PrintInWO],[PrintInWOQ],[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted]
				)
				VALUES (
					@SubWorkOrderTaskId, 
					@NewParentId, 
					@IsParent, 
					@Title, 
					@SequenceNumber,
					@Description,@TechId,@TechName,@TechUpdatedDate,@InspectorId,@InspectorName,
					@InspectorUpdatedDate,@PrintInWO,@PrintInWOQ,@MasterCompanyId,@CreatedBy,@CreatedBy,GETUTCDATE(),GETUTCDATE(),1,0
				);

				-- Get the newly generated ID
				DECLARE @NewSubWorkOrderTaskInstructionId INT = SCOPE_IDENTITY();

				-- Store the mapping of TaskInstructionId to the new WorkOrderTaskInstructionId
				INSERT INTO @IdMapping (TaskInstructionId, WorkOrderTaskInstructionId)
				VALUES (@TaskInstructionId, @NewSubWorkOrderTaskInstructionId);

				-- Add Sub Work Order Task Instruction History 
				EXEC USP_InsertSubWorkOrderTaskInstructionHistory @NewSubWorkOrderTaskInstructionId , @CreatedBy, @InstructionListId

				-- Add Sub Work Order Task history
				EXEC dbo.USP_AddSubWorkOrderTaskHistory @SubWorkOrderTaskId , @CreatedBy, @NewSubWorkOrderTaskInstructionId , NULL

				--IF (@ParentId IS NULL)
				--BEGIN
				--	/* START: Add Entry in History Table */
				--	SET @StatusCode = 'CreateWorkOrderTaskInstruction';

				--	SELECT @TaskName = WOT.TaskName, @WorkOrderPartNumberId = WOT.WorkOrderPartNumberId FROM DBO.WorkOrderTask WOT WITH (NOLOCK) WHERE WOT.WorkOrderTaskId = @WorkOrderTaskId;
				
				--	SELECT @InstructionTitleNew = InstructionTitle FROM DBO.WorkOrderTaskInstruction WITH (NOLOCK) WHERE WorkOrderTaskInstructionId = @NewWorkOrderTaskInstructionId;

				--	SELECT @TemplateBody = TemplateBody FROM dbo.HistoryTemplate WITH(NOLOCK) WHERE TemplateCode = @StatusCode

				--	SET @TemplateBody = REPLACE(@TemplateBody, '##TaskName##', ISNULL(@TaskName,''));
				--	SET @TemplateBody = REPLACE(@TemplateBody, '##InstructionTitle##', ISNULL(@InstructionTitleNew,''));

				--	EXEC USP_History @ModuleId, @WorkOrderId, @SubModuleId, @WorkOrderPartNumberId, '', @InstructionTitleNew, @TemplateBody, @StatusCode, @MasterCompanyId, @CreatedBy, NULL, @CreatedBy, NULL					
				--	/* END: Add Entry in History Table */
				--END

				-- Move to the next record
				FETCH NEXT FROM TaskCursor INTO @TaskInstructionId, @Title, @ParentId, @IsParent, @SequenceNumber, @Description;
			END

			CLOSE TaskCursor;
			DEALLOCATE TaskCursor;

			-- Clean up the temporary table
			DROP TABLE #TempTaskInstructions;
		END
		ELSE
		BEGIN
			SELECT TOP 1 @WorkOrderId = WorkOrderId FROM DBO.SubWorkOrderTask WOT WITH (NOLOCK) WHERE WOT.SubWorkOrderTaskId = @SubWorkOrderTaskId;

			SELECT @MaxSequence = ISNULL(MAX(WOTI.SequenceNumber), 0)
			FROM DBO.WorkOrderTaskInstruction WOTI WITH (NOLOCK)
			INNER JOIN DBO.WorkOrderTask WOT WITH (NOLOCK) ON WOTI.WorkOrderTaskId = WOT.WorkOrderTaskId AND WOTI.IsParent = 1
			WHERE WOT.WorkOrderId = @WorkOrderId;

			INSERT INTO DBO.SubWorkOrderTaskInstruction ([SubWorkOrderTaskId],[ParentId],[IsParent],[InstructionTitle],[SequenceNumber],[InstructionDetails],[TechId],[TechName],[TechUpdatedDate],[InspectorId],[InspectorName],
			[InspectorUpdatedDate],[PrintInWO],[PrintInWOQ],[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted])
			SELECT @SubWorkOrderTaskId, NULL, 1, @InstructionTitle, (@MaxSequence + 1), @InstructionDetails, @TechId, @TechName,@TechUpdatedDate,@InspectorId,@InspectorName,
			@InspectorUpdatedDate,@PrintInWO,@PrintInWOQ,@MasterCompanyId,@CreatedBy,@CreatedBy,GETUTCDATE(),GETUTCDATE(),1,0;

			-- Get new generated WorkOrderTaskInstructionId
			DECLARE @Id INT = SCOPE_IDENTITY();

			-- Add Sub Work Order Task Instruction History 
			EXEC USP_InsertSubWorkOrderTaskInstructionHistory @Id , @CreatedBy, @InstructionListId

			-- Add Sub Work Order Task history
			EXEC dbo.USP_AddSubWorkOrderTaskHistory @SubWorkOrderTaskId , @CreatedBy, @Id , NULL

			--/* START: Add Entry in History Table */
			--SET @StatusCode = 'CreateWorkOrderTaskInstruction';

			--SELECT @TaskName = WOT.TaskName, @WorkOrderPartNumberId = WOT.WorkOrderPartNumberId FROM DBO.WorkOrderTask WOT WITH (NOLOCK) WHERE WOT.WorkOrderTaskId = @WorkOrderTaskId;

			--SELECT @TemplateBody = TemplateBody FROM dbo.HistoryTemplate WITH(NOLOCK) WHERE TemplateCode = @StatusCode

			--SET @TemplateBody = REPLACE(@TemplateBody, '##TaskName##', ISNULL(@TaskName,''));
			--SET @TemplateBody = REPLACE(@TemplateBody, '##InstructionTitle##', ISNULL(@InstructionTitle,''));

			--EXEC USP_History @ModuleId, @WorkOrderId, @SubModuleId, @WorkOrderPartNumberId, '', @InstructionTitle, @TemplateBody, @StatusCode, @MasterCompanyId, @CreatedBy, NULL, @CreatedBy, NULL
			--/* END: Add Entry in History Table */
		END
	END
	ELSE IF (@IsAddChildNode = 1)
	BEGIN
		IF (ISNULL(@InstructionListId, '') <> '')
		BEGIN
			-- Temporary table to store mapping of old TaskInstructionId to new WorkOrderTaskInstructionId
			DECLARE @IdMapping_1 TABLE (
				TaskInstructionId INT,
				WorkOrderTaskInstructionId INT
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

			SELECT 
				TaskInstructionId, 
				Title, 
				ParentId, 
				IsParent, 
				SequenceNumber,
				[Description]
			INTO #TempTaskInstructions_1
			FROM RecursiveCTE
			ORDER BY ISNULL(ParentId, TaskInstructionId), SequenceNumber;

			SELECT * FROM #TempTaskInstructions_1

			-- Cursor to process records in the correct parent-child sequence
			DECLARE TaskCursor CURSOR FOR
			SELECT 
				TaskInstructionId, 
				Title, 
				ParentId, 
				IsParent, 
				SequenceNumber,
				[Description]
			FROM #TempTaskInstructions_1;

			OPEN TaskCursor;
			FETCH NEXT FROM TaskCursor INTO @TaskInstructionId, @Title, @ParentId, @IsParent, @SequenceNumber, @Description;

			WHILE @@FETCH_STATUS = 0
			BEGIN
				-- Get the new ParentId from mapping if the current record has a ParentId
				SET @NewParentId = NULL;
				IF @ParentId IS NOT NULL
				BEGIN
					SELECT @NewParentId = WorkOrderTaskInstructionId FROM @IdMapping_1 WHERE TaskInstructionId = @ParentId;

					IF ISNULL(@NewParentId, 0) = 0
					BEGIN
						SET @NewParentId = @SubWorkOrderTaskInstructionId;
					END
				END

				-- Insert the record into WorkOrderTaskInstruction table
				INSERT INTO SubWorkOrderTaskInstruction (
					SubWorkOrderTaskId, 
					ParentId, 
					IsParent, 
					InstructionTitle, 
					SequenceNumber,
					[InstructionDetails],[TechId],[TechName],[TechUpdatedDate],[InspectorId],[InspectorName],
					[InspectorUpdatedDate],[PrintInWO],[PrintInWOQ],[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted]
				)
				VALUES (
					@SubWorkOrderTaskId, 
					@NewParentId, 
					@IsParent, 
					@Title, 
					@SequenceNumber,
					@Description,@TechId,@TechName,@TechUpdatedDate,@InspectorId,@InspectorName,
					@InspectorUpdatedDate,@PrintInWO,@PrintInWOQ,@MasterCompanyId,@CreatedBy,@CreatedBy,GETUTCDATE(),GETUTCDATE(),1,0
				);

				-- Get the newly generated ID
				DECLARE @NewSubWorkOrderTaskInstructionId_1 INT = SCOPE_IDENTITY();

				-- Store the mapping of TaskInstructionId to the new SubWorkOrderTaskInstructionId
				INSERT INTO @IdMapping_1 (TaskInstructionId, WorkOrderTaskInstructionId)
				VALUES (@TaskInstructionId, @NewSubWorkOrderTaskInstructionId_1);

				--IF (@ParentId IS NULL)
				--BEGIN
				--	/* START: Add Entry in History Table */
				--	SET @StatusCode = 'CreateWorkOrderTaskInstruction';

				--	SELECT @TaskName = WOT.TaskName, @WorkOrderPartNumberId = WOT.WorkOrderPartNumberId FROM DBO.WorkOrderTask WOT WITH (NOLOCK) WHERE WOT.WorkOrderTaskId = @WorkOrderTaskId;
				
				--	SELECT @InstructionTitleNew = InstructionTitle FROM DBO.WorkOrderTaskInstruction WITH (NOLOCK) WHERE WorkOrderTaskInstructionId = @NewWorkOrderTaskInstructionId_1;

				--	SELECT @TemplateBody = TemplateBody FROM dbo.HistoryTemplate WITH(NOLOCK) WHERE TemplateCode = @StatusCode

				--	SET @TemplateBody = REPLACE(@TemplateBody, '##TaskName##', ISNULL(@TaskName,''));
				--	SET @TemplateBody = REPLACE(@TemplateBody, '##InstructionTitle##', ISNULL(@InstructionTitleNew,''));

				--	EXEC USP_History @ModuleId, @WorkOrderId, @SubModuleId, @WorkOrderPartNumberId, '', @InstructionTitleNew, @TemplateBody, @StatusCode, @MasterCompanyId, @CreatedBy, NULL, @CreatedBy, NULL
				--	/* END: Add Entry in History Table */
				--END

				-- Move to the next record
				FETCH NEXT FROM TaskCursor INTO @TaskInstructionId, @Title, @ParentId, @IsParent, @SequenceNumber, @Description;
			END

			CLOSE TaskCursor;
			DEALLOCATE TaskCursor;

			-- Clean up the temporary table
			DROP TABLE #TempTaskInstructions_1;
		END
		ELSE
		BEGIN
			-- Find the maximum sequence number under the specific parent
			DECLARE @MaxSequenceNumber INT;
			SELECT @MaxSequenceNumber = ISNULL(MAX(SequenceNumber), 0)
			FROM DBO.SubWorkOrderTaskInstruction
			WHERE ParentId = @SubWorkOrderTaskInstructionId;

			-- Determine the new sequence number for the child
			DECLARE @NewSequenceNumber INT = @MaxSequenceNumber + 1;

			-- Insert the new child node with the next sequence number
			INSERT INTO SubWorkOrderTaskInstruction ([SubWorkOrderTaskId],[ParentId],[IsParent],[InstructionTitle],[SequenceNumber],[InstructionDetails],[TechId],[TechName],[TechUpdatedDate],[InspectorId],[InspectorName],
				[InspectorUpdatedDate],[PrintInWO],[PrintInWOQ],[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted])
			VALUES (@SubWorkOrderTaskId, @SubWorkOrderTaskInstructionId, 0, @InstructionTitle, @NewSequenceNumber, @InstructionDetails, @TechId, @TechName, @TechUpdatedDate, @InspectorId, @InspectorName, 
				@InspectorUpdatedDate, @PrintInWO, @PrintInWOQ, @MasterCompanyId, @CreatedBy, @CreatedBy, GETDATE(), GETDATE(), 1, 0);
			 	
			-- Get new generated WorkOrderTaskInstructionId
			DECLARE @NewWOTIID INT = SCOPE_IDENTITY();
		
			-- Add Sub Work Order Task Instruction History 
			EXEC USP_InsertSubWorkOrderTaskInstructionHistory @NewWOTIID , @CreatedBy, @InstructionListId

			-- Add Sub Work Order Task history
			EXEC dbo.USP_AddSubWorkOrderTaskHistory @SubWorkOrderTaskId , @CreatedBy, @NewWOTIID , NULL

			--/* START: Add Entry in History Table */
			--SET @StatusCode = 'CreateWorkOrderTaskInstruction';

			--SELECT @TaskName = WOT.TaskName, @WorkOrderPartNumberId = WOT.WorkOrderPartNumberId FROM DBO.WorkOrderTask WOT WITH (NOLOCK) WHERE WOT.WorkOrderTaskId = @WorkOrderTaskId;

			--SELECT @TemplateBody = TemplateBody FROM dbo.HistoryTemplate WITH(NOLOCK) WHERE TemplateCode = @StatusCode

			--SET @TemplateBody = REPLACE(@TemplateBody, '##TaskName##', ISNULL(@TaskName,''));
			--SET @TemplateBody = REPLACE(@TemplateBody, '##InstructionTitle##', ISNULL(@InstructionTitle,''));

			--EXEC USP_History @ModuleId, @WorkOrderId, @SubModuleId, @WorkOrderPartNumberId, '', @InstructionTitle, @TemplateBody, @StatusCode, @MasterCompanyId, @CreatedBy, NULL, @CreatedBy, NULL
			/* END: Add Entry in History Table */
		END
	END
	ELSE
	BEGIN
		UPDATE DBO.SubWorkOrderTaskInstruction
		SET [InstructionTitle] = @InstructionTitle,
		[InstructionDetails] = @InstructionDetails,
		InspectorId = @InspectorId,
		InspectorName = @InspectorName,
		InspectorUpdatedDate = @InspectorUpdatedDate,
		TechId = @TechId,
		TechName = @TechName,
		TechUpdatedDate = @TechUpdatedDate,
		[PrintInWO] = @PrintInWO,
		[PrintInWOQ] = @PrintInWOQ
		WHERE SubWorkOrderTaskInstructionId = @SubWorkOrderTaskInstructionId;

		-- Add Sub Work Order Task Instruction History 
		EXEC USP_InsertSubWorkOrderTaskInstructionHistory @SubWorkOrderTaskInstructionId , @CreatedBy, @InstructionListId

		-- Add Sub Work Order Task history
		EXEC dbo.USP_AddSubWorkOrderTaskHistory @SubWorkOrderTaskId , @CreatedBy, @SubWorkOrderTaskInstructionId , NULL

		SELECT @SubWorkOrderTaskInstructionId AS SubWorkOrderTaskInstructionId;
	END
  COMMIT  TRANSACTION
  END TRY
  BEGIN CATCH
	IF @@trancount > 0
		PRINT 'ROLLBACK'
		ROLLBACK TRAN;
    DECLARE @ErrorLogID int,
            @DatabaseName varchar(100) = DB_NAME()
            -----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            ,@AdhocComments varchar(150) = 'USP_AddUpdateSubWorkOrderTaskInstructions',
            @ProcedureParameters varchar(3000) = '@WorkOrderTaskId = ''' + CAST(ISNULL(@SubWorkOrderTaskId, '') AS varchar(100)),
            @ApplicationName varchar(100) = 'PAS'
    -----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
    EXEC spLogException @DatabaseName = @DatabaseName,
                        @AdhocComments = @AdhocComments,
                        @ProcedureParameters = @ProcedureParameters,
                        @ApplicationName = @ApplicationName,
                        @ErrorLogID = @ErrorLogID OUTPUT;
    RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)
    RETURN (1);
  END CATCH
END