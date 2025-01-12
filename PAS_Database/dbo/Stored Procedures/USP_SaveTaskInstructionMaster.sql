/***************************************************************  
 ** File:   [USP_SaveTaskInstructionMaster]             
 ** Author:   Devendra Shekh
 ** Description: This stored procedure is used to save task Instruction Master
 ** Date:  26-Dec-2024
            
  ** Change History             
 **************************************************************             
 ** PR   Date				Author  				Change Description              
 ** --   --------			-------				--------------------------------            
    1    26-Dec-2024		Devendra Shekh			Created

exec dbo.USP_SaveTaskInstructionMaster 
@TaskInstructionId=0,@Title=N'fsefse',@Description=N'fefse',@TaskId=272,@SequenceNumber=1,@ParentId=default,@IsParent=default,
@MasterCompanyId=1,@CreatedBy=N'DEVENDRASILVER MICKSILVER',@UpdatedBy=N'DEVENDRASILVER MICKSILVER',
@CreatedDate='2024-12-26 17:48:38.943',@UpdatedDate='2024-12-26 17:48:38.943',@IsActive=1,@IsDeleted=0
**************************************************************/
CREATE   PROCEDURE [dbo].[USP_SaveTaskInstructionMaster]
    @TaskInstructionId BIGINT = NULL,
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
	@IsAddChildNode BIT = NULL
AS
BEGIN
    SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	BEGIN TRY

		IF (ISNULL(@TaskInstructionId, 0) = 0)
		BEGIN
			DECLARE @MaxSequence INT;
			DECLARE @InsertedTaskInstructionId BIGINT = 0;

			SELECT @MaxSequence = ISNULL(MAX(TIM.SequenceNumber), 0)
			FROM DBO.TaskInstructionMaster TIM WITH (NOLOCK)
			WHERE TIM.MasterCompanyId = @MasterCompanyId AND TIM.IsParent = 1;

			INSERT INTO DBO.TaskInstructionMaster ([Title], [Description], [TaskId], [SequenceNumber], [ParentId], [IsParent], 
			[MasterCompanyId], [CreatedBy], [UpdatedBy], [CreatedDate], [UpdatedDate], [IsActive], [IsDeleted])
			SELECT @Title, @Description, ISNULL(@TaskId, 0), (@MaxSequence + 1), NULL, 1, 
			@MasterCompanyId, @CreatedBy, @CreatedBy, GETUTCDATE(), GETUTCDATE(), 1, 0;
		END
		ELSE IF (@IsAddChildNode = 1)
		BEGIN
			-- Find the maximum sequence number under the specific parent
			DECLARE @MaxSequenceNumber INT;
			SELECT @MaxSequenceNumber = ISNULL(MAX(SequenceNumber), 0)
			FROM DBO.TaskInstructionMaster
			WHERE ParentId = @TaskInstructionId;

			-- Determine the new sequence number for the child
			DECLARE @NewSequenceNumber INT = @MaxSequenceNumber + 1;

			-- Insert the new child node with the next sequence number
			INSERT INTO DBO.TaskInstructionMaster ([Title], [Description], [TaskId],  [SequenceNumber],  [ParentId],  [IsParent], 
			[MasterCompanyId], [CreatedBy], [UpdatedBy], [CreatedDate], [UpdatedDate], [IsActive], [IsDeleted])
			VALUES (@Title, @Description,  ISNULL(@TaskId, 0), @NewSequenceNumber, @TaskInstructionId, 0, 
			@MasterCompanyId, @CreatedBy, @CreatedBy, GETUTCDATE(), GETUTCDATE(), 1, 0);
		END
		ELSE
		BEGIN
			UPDATE [dbo].[TaskInstructionMaster]
			SET 
				[Title] = @Title,
				[Description] = @Description,
				[TaskId] = @TaskId,
				[UpdatedBy] = @UpdatedBy,
				[UpdatedDate] = GETUTCDATE()
			WHERE [TaskInstructionId] = @TaskInstructionId AND [MasterCompanyId] = @MasterCompanyId;
		END

	END TRY   
	BEGIN CATCH      
	         DECLARE @ErrorLogID INT
			,@DatabaseName VARCHAR(100) = db_name()
			-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
			,@AdhocComments VARCHAR(150) = 'USP_SaveTaskInstructionMaster'
			,@ProcedureParameters VARCHAR(3000) =
					'@Parameter1 = ''' + ISNULL(CAST(@TaskInstructionId AS VARCHAR(100)), '') + ''', ' +
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