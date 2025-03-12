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
    2    04-Mar-2025		RAJESH GAMI			 Implement the logic for insert ParentId based on the taskId
	3    07-Mar-2025		RAJESH GAMI			 Resovle duplicate child entry issue
	4    11-Mar-2025		RAJESH GAMI			 IsDefaultInstruction implemented
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
    @IsAddChildNode BIT = NULL,
	@IsDefaultInstruction BIT = NULL,
	@IsParentInstruction BIT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

    BEGIN TRY
        IF (ISNULL(@TaskInstructionId, 0) = 0)
        BEGIN
            DECLARE @MaxSequence INT;
            DECLARE @InsertedTaskInstructionId BIGINT = 0;
            DECLARE @ParentTaskInsId BIGINT = NULL, @IsParentTask BIT = 1, @ParentIntructionId BIGINT = 0;

            SELECT @ParentIntructionId = TaskInstructionId
            FROM DBO.TaskInstructionMaster TIM WITH (NOLOCK)
            WHERE TIM.MasterCompanyId = @MasterCompanyId AND TIM.IsParent = 1 AND TaskId = @TaskId;

            SELECT @MaxSequence = ISNULL(MAX(TIM.SequenceNumber), 0)
            FROM DBO.TaskInstructionMaster TIM WITH (NOLOCK)
            WHERE TIM.MasterCompanyId = @MasterCompanyId AND ParentId = @ParentIntructionId; 

			IF(@IsDefaultInstruction = 1)
			BEGIN
				   UPDATE [dbo].[TaskInstructionMaster]
					SET 
						[IsDefaultInstruction] = 0
					WHERE [MasterCompanyId] = @MasterCompanyId 
					AND TaskId = @TaskId;
			END

            IF((SELECT COUNT(1) FROM DBO.TaskInstructionMaster WHERE MasterCompanyId = @MasterCompanyId AND TaskId = @TaskId AND ISNULL(ParentId,0) = 0) > 0)
            BEGIN
                SET @ParentTaskInsId = (SELECT TOP 1 TaskInstructionId FROM DBO.TaskInstructionMaster WITH(NOLOCK) WHERE MasterCompanyId = @MasterCompanyId AND TaskId = @TaskId AND ISNULL(ParentId,0) = 0);
                SET @IsParentTask = 0;
            END

            -- Insert the parent instruction
            INSERT INTO DBO.TaskInstructionMaster ([Title], [Description], [TaskId], [SequenceNumber], [ParentId], [IsParent], 
            [MasterCompanyId], [CreatedBy], [UpdatedBy], [CreatedDate], [UpdatedDate], [IsActive], [IsDeleted],[IsDefaultInstruction],[IsParentInstruction])
            VALUES (@Title, @Description, ISNULL(@TaskId, 0), @MaxSequence +1, @ParentTaskInsId, @IsParentTask, 
            @MasterCompanyId, @CreatedBy, @CreatedBy, GETUTCDATE(), GETUTCDATE(), 1, 0,@IsDefaultInstruction,1);
			SET @InsertedTaskInstructionId = SCOPE_IDENTITY();

			IF((SELECT COUNT(1) FROM dbo.TaskInstructionMaster WITH(NOLOCK) WHERE TaskInstructionId = @ParentIntructionId AND ISNULL(SequenceNumber,0) = 0) = 0)
			BEGIN
				IF @ParentId IS NULL AND @MaxSequence = 0
				BEGIN
					UPDATE DBO.TaskInstructionMaster
					SET SequenceNumber = 0,[IsDefaultInstruction] = 0,[IsParentInstruction] = 0
					WHERE TaskInstructionId = @InsertedTaskInstructionId;

					INSERT INTO DBO.TaskInstructionMaster ([Title], [Description], [TaskId], [SequenceNumber], [ParentId], [IsParent], 
					[MasterCompanyId], [CreatedBy], [UpdatedBy], [CreatedDate], [UpdatedDate], [IsActive], [IsDeleted],[IsDefaultInstruction],[IsParentInstruction])
					VALUES (@Title, @Description, @TaskId, (@MaxSequence + 1), @InsertedTaskInstructionId, 0, 
					@MasterCompanyId, @CreatedBy, @CreatedBy, GETUTCDATE(), GETUTCDATE(), 1, 0,1,1);
				END
			END
		
         
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
            INSERT INTO DBO.TaskInstructionMaster ([Title], [Description], [TaskId], [SequenceNumber], [ParentId], [IsParent], 
            [MasterCompanyId], [CreatedBy], [UpdatedBy], [CreatedDate], [UpdatedDate], [IsActive], [IsDeleted])
            VALUES (@Title, @Description, ISNULL(@TaskId, 0), @NewSequenceNumber, @TaskInstructionId, 0, 
            @MasterCompanyId, @CreatedBy, @CreatedBy, GETUTCDATE(), GETUTCDATE(), 1, 0);
        END
        ELSE
        BEGIN
			IF(@IsDefaultInstruction = 1)
			BEGIN
				   UPDATE [dbo].[TaskInstructionMaster]
					SET 
						[IsDefaultInstruction] = 0
					WHERE [MasterCompanyId] = @MasterCompanyId 
					AND TaskId = @TaskId;
			END
            UPDATE [dbo].[TaskInstructionMaster]
            SET 
                [Title] = @Title,
                [Description] = @Description,
                [TaskId] = @TaskId,
                [UpdatedBy] = @UpdatedBy,
                [UpdatedDate] = GETUTCDATE(),
				[IsDefaultInstruction] = @IsDefaultInstruction
            WHERE [TaskInstructionId] = @TaskInstructionId AND [MasterCompanyId] = @MasterCompanyId;
		
        END

    END TRY   
    BEGIN CATCH      
        DECLARE @ErrorLogID INT
        ,@DatabaseName VARCHAR(100) = db_name()
        ,@AdhocComments VARCHAR(150) = 'USP_SaveTaskInstructionMaster'
        ,@ProcedureParameters VARCHAR(3000) =
                '@TaskInstructionId = ''' + ISNULL(CAST(@TaskInstructionId AS VARCHAR(100)), '') + ''', ' +
                '@Title = ''' + ISNULL(@Title, '') + ''', ' +
                '@Description = ''' + ISNULL(@Description, '') + ''', ' +
                '@TaskId = ''' + ISNULL(CAST(@TaskId AS VARCHAR(100)), '') + ''', ' +
                '@SequenceNumber = ''' + ISNULL(CAST(@SequenceNumber AS VARCHAR(100)), '') + ''', ' +
                '@ParentId = ''' + ISNULL(CAST(@ParentId AS VARCHAR(100)), '') + ''', ' +
                '@IsParent = ''' + ISNULL(CAST(@IsParent AS VARCHAR(100)), '') + ''', ' +
                '@MasterCompanyId = ''' + ISNULL(CAST(@MasterCompanyId AS VARCHAR(100)), '') + ''', ' +
                '@CreatedBy = ''' + ISNULL(@CreatedBy, '') + ''', ' +
                '@UpdatedBy = ''' + ISNULL(@UpdatedBy, '') + ''', ' +
                '@CreatedDate = ''' + ISNULL(CAST(@CreatedDate AS VARCHAR(100)), '') + ''', ' +
                '@UpdatedDate = ''' + ISNULL(CAST(@UpdatedDate AS VARCHAR(100)), '') + ''', ' +
                '@IsActive = ''' + ISNULL(CAST(@IsActive AS VARCHAR(100)), '') + ''', ' +
                '@IsDeleted = ''' + ISNULL(CAST(@IsDeleted AS VARCHAR(100)), '') + ''''                                           
        ,@ApplicationName VARCHAR(100) = 'PAS'

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