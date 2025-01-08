/***************************************************************  
 ** File:   [USP_AddUpdateWorkOrderTaskInstructions]
 ** Author:   Vishal Suthar
 ** Description: This stored procedure is used add or update sales order part details
 ** Purpose:
 ** Date:   12/24/2024

 ** Change History
 **************************************************************
 ** PR   Date         Author  		 Change Description
 ** --   --------     -------		 --------------------------------
    1    01/01/2025   Vishal Suthar	 Created

**************************************************************/
CREATE   PROCEDURE [dbo].[USP_AddUpdateWorkOrderTaskInstructions]
	@WorkOrderTaskInstructionId BIGINT = NULL,
	@WorkOrderTaskId BIGINT,
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
	
	IF (ISNULL(@WorkOrderTaskInstructionId, 0) = 0)
	BEGIN
		DECLARE @InsertedWorkOrderTaskInstructionId BIGINT = 0;
		DECLARE @TaskMasterLoopID AS INT;

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
			;WITH RecursiveCTE AS (
				SELECT * 
				FROM DBO.TaskInstructionMaster WITH (NOLOCK)
				WHERE TaskInstructionId IN (SELECT Item FROM DBO.SPLITSTRING(@InstructionListId, ','))
    
				UNION ALL
    
				SELECT t.*
				FROM DBO.TaskInstructionMaster t WITH (NOLOCK)
				INNER JOIN RecursiveCTE r
				ON t.ParentId = r.TaskInstructionId
			)

			INSERT INTO #TaskMaster ([TaskInstructionId],[Title],[Description],[TaskId],[SequenceNumber],[ParentId],[IsParent],[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],
			[UpdatedDate],[IsActive],[IsDeleted])
			SELECT [TaskInstructionId],[Title],[Description],[TaskId],[SequenceNumber],[ParentId],[IsParent],[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],
			[UpdatedDate],[IsActive],[IsDeleted]
			FROM RecursiveCTE ORDER BY ParentId DESC;
		
			SELECT @TaskMasterLoopID = MAX(ID) FROM #TaskMaster;

			WHILE (@TaskMasterLoopID > 0)
			BEGIN
				DECLARE @OldTaskInstructionId BIGINT = 0;
				DECLARE @OldParentId BIGINT = 0;
				DECLARE @OldTitle VARCHAR(8000) = NULL;
				DECLARE @OldDescription VARCHAR(MAX) = NULL;

				SELECT @OldTaskInstructionId = TaskInstructionId, @OldParentId = ParentId FROM #TaskMaster WHERE ID = @TaskMasterLoopID;

				IF (ISNULL(@OldParentId, 0) > 0)
				BEGIN
					SELECT @OldTitle = Title, @OldDescription = [Description] FROM DBO.TaskInstructionMaster WITH (NOLOCK) WHERE TaskInstructionId = @OldParentId;
				END

				INSERT INTO DBO.WorkOrderTaskInstruction ([WorkOrderTaskId],[ParentId],[IsParent],[InstructionTitle],[SequenceNumber],[InstructionDetails],[TechId],[TechName],[TechUpdatedDate],[InspectorId],[InspectorName],
				[InspectorUpdatedDate],[PrintInWO],[PrintInWOQ],[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted])
				SELECT @WorkOrderTaskId, [ParentId], [IsParent], Title, [SequenceNumber], [Description],@TechId,@TechName,@TechUpdatedDate,@InspectorId,@InspectorName,
				@InspectorUpdatedDate,@PrintInWO,@PrintInWOQ,@MasterCompanyId,@CreatedBy,@CreatedBy,GETUTCDATE(),GETUTCDATE(),1,0
				FROM #TaskMaster WHERE ID = @TaskMasterLoopID;

				SET @InsertedWorkOrderTaskInstructionId = SCOPE_IDENTITY();

				IF (ISNULL(@OldParentId, 0) > 0)
				BEGIN
					UPDATE DBO.WorkOrderTaskInstruction
					SET ParentId = (SELECT WorkOrderTaskInstructionId FROM DBO.WorkOrderTaskInstruction WHERE InstructionTitle = @OldTitle AND InstructionDetails = @OldDescription AND WorkOrderTaskId = @WorkOrderTaskId)
					WHERE WorkOrderTaskInstructionId = @InsertedWorkOrderTaskInstructionId;
				END

				SET @TaskMasterLoopID = @TaskMasterLoopID - 1;
			END
		END
		ELSE
		BEGIN
			INSERT INTO DBO.WorkOrderTaskInstruction ([WorkOrderTaskId],[ParentId],[IsParent],[InstructionTitle],[SequenceNumber],[InstructionDetails],[TechId],[TechName],[TechUpdatedDate],[InspectorId],[InspectorName],
			[InspectorUpdatedDate],[PrintInWO],[PrintInWOQ],[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted])
			SELECT @WorkOrderTaskId, NULL, 1, @InstructionTitle, 1, @InstructionDetails, @TechId, @TechName,@TechUpdatedDate,@InspectorId,@InspectorName,
			@InspectorUpdatedDate,@PrintInWO,@PrintInWOQ,@MasterCompanyId,@CreatedBy,@CreatedBy,GETUTCDATE(),GETUTCDATE(),1,0;
		END
	END
	ELSE IF (@IsAddChildNode = 1)
	BEGIN
		-- Find the maximum sequence number under the specific parent
        DECLARE @MaxSequenceNumber INT;
        SELECT @MaxSequenceNumber = ISNULL(MAX(SequenceNumber), 0)
        FROM DBO.WorkOrderTaskInstruction
        WHERE ParentId = @WorkOrderTaskInstructionId;

        -- Determine the new sequence number for the child
        DECLARE @NewSequenceNumber INT = @MaxSequenceNumber + 1;

		-- Insert the new child node with the next sequence number
		INSERT INTO WorkOrderTaskInstruction ([WorkOrderTaskId],[ParentId],[IsParent],[InstructionTitle],[SequenceNumber],[InstructionDetails],[TechId],[TechName],[TechUpdatedDate],[InspectorId],[InspectorName],
			[InspectorUpdatedDate],[PrintInWO],[PrintInWOQ],[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted])
		VALUES (@WorkOrderTaskId, @WorkOrderTaskInstructionId, 0, @InstructionTitle, @NewSequenceNumber, @InstructionDetails, @TechId, @TechName, @TechUpdatedDate, @InspectorId, @InspectorName, 
			@InspectorUpdatedDate, @PrintInWO, @PrintInWOQ, @MasterCompanyId, @CreatedBy, @CreatedBy, GETDATE(), GETDATE(), 1, 0);
	END
	ELSE
	BEGIN
		UPDATE DBO.WorkOrderTaskInstruction
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
		WHERE WorkOrderTaskInstructionId = @WorkOrderTaskInstructionId;

		SELECT @WorkOrderTaskInstructionId AS WorkOrderTaskInstructionId;
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
            ,@AdhocComments varchar(150) = 'USP_AddUpdateWorkOrderTaskInstructions',
            @ProcedureParameters varchar(3000) = '@WorkOrderTaskId = ''' + CAST(ISNULL(@WorkOrderTaskId, '') AS varchar(100)),
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