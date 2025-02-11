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

exec dbo.USP_SaveWorkFlowTaskInstructionMaster 
@WorkflowDirectionId=0,@Title=N'RECEIVING',@Description=N'<p>RECEIVING</p>',@TaskId=11,@SequenceNumber=default,
@ParentId=default,@IsParent=default,@MasterCompanyId=1,@CreatedBy=N'Jim Roberts',@UpdatedBy=N'Jim Roberts',
@CreatedDate='2025-02-05 19:13:54.720',@UpdatedDate='2025-02-05 19:13:54.720',@IsActive=1,@IsDeleted=0,@WorkflowId=43
**************************************************************/
CREATE   PROCEDURE [dbo].[USP_SaveWorkFlowTaskInstructionMaster]
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
	@WorkflowId BIGINT = NULL
AS
BEGIN
    SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	BEGIN TRY

		IF (ISNULL(@WorkflowDirectionId, 0) = 0)
		BEGIN
			DECLARE @MaxSequence INT;
			DECLARE @InsertedWorkflowDirectionId BIGINT = 0;

			SELECT @MaxSequence = ISNULL(MAX(TIM.Sequence), 0)
			FROM DBO.WorkFlowDirection TIM WITH (NOLOCK)
			WHERE TIM.MasterCompanyId = @MasterCompanyId AND TIM.IsParent = 1 AND TIM.WorkflowId = @WorkflowId AND [TaskId] = @TaskId;

			INSERT INTO DBO.WorkFlowDirection ([WorkflowId], [Action], [Description], [TaskId], [Sequence], [ParentId], [IsParent], 
			[MasterCompanyId], [CreatedBy], [UpdatedBy], [CreatedDate], [UpdatedDate], [IsActive], [IsDeleted], [IsTaskDetails])
			SELECT @WorkflowId, @Title, @Description, ISNULL(@TaskId, 0), (@MaxSequence + 1), NULL, 1, 
			@MasterCompanyId, @CreatedBy, @CreatedBy, GETUTCDATE(), GETUTCDATE(), 1, 0, @IsTaskDetails;
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
		END
		ELSE
		BEGIN
			UPDATE [dbo].[WorkFlowDirection]
			SET 
				[Action] = @Title,
				[Description] = @Description,
				[TaskId] = @TaskId,
				[UpdatedBy] = @UpdatedBy,
				[UpdatedDate] = GETUTCDATE()
			WHERE [WorkflowDirectionId] = @WorkflowDirectionId AND [MasterCompanyId] = @MasterCompanyId AND WorkflowId = @WorkflowId;
		END

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