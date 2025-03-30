/*************************************************************
 ** File:   [USP_AddSubWorkOrderTaskHistory]
 ** Author:  Ekta Chandegra
 ** Description: This stored procedure is used to AddSubWorkOrderTaskHistory by id
 ** Purpose:
 ** Date:   03/27/2025
    
 ** PARAMETERS: @SubWorkOrderTaskId BIGINT, @CreatedBy VARCHAR(256), @SubWorkOrderTaskInstructionId BIGINT, @NewSubWorkOrderTaskId BIGINT

 ** RETURN VALUE:

 **************************************************************
  ** Change History               
 **************************************************************
 ** PR   Date         Author			Change Description
 ** --   --------     -------			--------------------------------
    1    03/27/2025   Ekta Chandegra	Created

exec dbo.USP_AddSubWorkOrderTaskHistory @WorkOrderTaskId=978,@CreatedBy=N'EKTA CHANDEGRA',@SubWorkOrderTaskInstructionId = 17 , @NewSubWorkOrderTaskId = 0
**************************************************************/
CREATE    PROCEDURE [dbo].[USP_AddSubWorkOrderTaskHistory]
@SubWorkOrderTaskId BIGINT,
@CreatedBy VARCHAR(256),
@SubWorkOrderTaskInstructionId BIGINT,
@NewSubWorkOrderTaskId BIGINT
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
	SET NOCOUNT ON;
	BEGIN TRY  

		IF(@SubWorkOrderTaskInstructionId IS NULL)
		BEGIN
			SET @SubWorkOrderTaskInstructionId  = 0
		END

		IF(@NewSubWorkOrderTaskId IS NULL)
		BEGIN
			SET @NewSubWorkOrderTaskId  = 0
		END

		-- Insert data into SubWorkOrderTaskHistory when add or remove Sub work order task instuction
		IF(@SubWorkOrderTaskInstructionId > 0)
		BEGIN
			INSERT INTO [dbo].[SubWorkOrderTaskHistory]
			(
				[SubWorkOrderTaskId], [TaskName], [Descrepancy], [Resolution], [TechId], 
				[TechName], [TechUpdatedDate], [InspectorId], [InspectorName], [InspectorUpdatedDate],
				[PrintInWO], [PrintInWOQ], [IsParent], [ParentId], [InstructionTitle], [InstructionDetails],
				[SequenceNumber],[IsActive], [IsDeleted], [UpdatedBy], [UpdatedDate],[SubWorkOrderTaskInstructionId],
				[SubWorkOrderTaskInstructionTechId], [SubWorkOrderTaskInstructionTechName],[SubWorkOrderTaskInstructionTechUpdatedDate],
				[SubWorkOrderTaskInstructionInspectorId], [SubWorkOrderTaskInstructionInspectorName],[SubWorkOrderTaskInstructionInspectorUpdatedDate] ,
				[SubWorkOrderTaskInstructionPrintInWO], [SubWorkOrderTaskInstructionPrintInWOQ]
			)
			SELECT TOP 1
				@SubWorkOrderTaskId, SWOT.[TaskName], SWOTD.[Descrepancy], SWOTD.[Resolution],SWOTD.[TechId],
				SWOTD.[TechName], SWOTD.[TechUpdatedDate], SWOTD.[InspectorId], SWOTD.[InspectorName], SWOTD.[InspectorUpdatedDate],
				SWOTD.[PrintInWO], SWOTD.[PrintInWOQ], SWOTI.[IsParent], SWOTI.[ParentId], SWOTI.[InstructionTitle], SWOTI.[InstructionDetails],
				SWOT.[SequenceNumber],SWOTI.[IsActive], SWOTI.[IsDeleted],@CreatedBy, GETUTCDATE(),@SubWorkOrderTaskInstructionId,
				SWOTI.TechId, SWOTI.TechName, SWOTI.TechUpdatedDate,
				SWOTI.InspectorId, SWOTI.InspectorName, SWOTI.InspectorUpdatedDate,
				SWOTI.PrintInWO, SWOTI.PrintInWOQ
			FROM
			[dbo].[SubWorkOrderTask] SWOT WITH (NOLOCK)
			LEFT JOIN [dbo].[SubWorkOrderTaskDetails] SWOTD WITH (NOLOCK) ON SWOTD.SubWorkOrderTaskId = SWOT.SubWorkOrderTaskId
			LEFT JOIN [dbo].[SubWorkOrderTaskInstruction] SWOTI WITH (NOLOCK) ON SWOTI.SubWorkOrderTaskId = SWOT.SubWorkOrderTaskId AND (SWOTI.IsParent = 1 OR (SWOTI.IsParent = 0 AND SWOTI.ParentId IS NULL))
			WHERE SWOT.SubWorkOrderTaskId = @SubWorkOrderTaskId AND SWOTI.SubWorkOrderTaskInstructionId = @SubWorkOrderTaskInstructionId;
		END
		ELSE
		-- Insert data into SubWorkOrderTaskHistory when change Sub work order task 
		BEGIN
			INSERT INTO [dbo].[SubWorkOrderTaskHistory]
			(
				[SubWorkOrderTaskId], [TaskName], [Descrepancy], [Resolution], [TechId], 
				[TechName], [TechUpdatedDate], [InspectorId], [InspectorName], [InspectorUpdatedDate],
				[PrintInWO], [PrintInWOQ], [IsParent], [ParentId], [InstructionTitle], [InstructionDetails],
				[SequenceNumber],[IsActive], [IsDeleted], [UpdatedBy], [UpdatedDate],[SubWorkOrderTaskInstructionId],
				[SubWorkOrderTaskInstructionTechId], [SubWorkOrderTaskInstructionTechName],[SubWorkOrderTaskInstructionTechUpdatedDate],
				[SubWorkOrderTaskInstructionInspectorId], [SubWorkOrderTaskInstructionInspectorName],[SubWorkOrderTaskInstructionInspectorUpdatedDate] ,
				[SubWorkOrderTaskInstructionPrintInWO], [SubWorkOrderTaskInstructionPrintInWOQ]
			)
			SELECT TOP 1
				@SubWorkOrderTaskId, SWOT.[TaskName], SWOTD.[Descrepancy], SWOTD.[Resolution], SWOTD.[TechId],
				SWOTD.[TechName], SWOTD.[TechUpdatedDate], SWOTD.[InspectorId], SWOTD.[InspectorName], SWOTD.[InspectorUpdatedDate],
				SWOTD.[PrintInWO], SWOTD.[PrintInWOQ], SWOTI.[IsParent], SWOTI.[ParentId], SWOTI.[InstructionTitle], SWOTI.[InstructionDetails],
				SWOT.[SequenceNumber],SWOTI.[IsActive], SWOTI.[IsDeleted],@CreatedBy, GETUTCDATE(),SWOTI.[SubWorkOrderTaskInstructionId],
				SWOTI.TechId, SWOTI.TechName, SWOTI.TechUpdatedDate,
				SWOTI.InspectorId, SWOTI.InspectorName, SWOTI.InspectorUpdatedDate,
				SWOTI.PrintInWO, SWOTI.PrintInWOQ
			FROM
			[dbo].[SubWorkOrderTask] SWOT WITH (NOLOCK)
			LEFT JOIN [dbo].[SubWorkOrderTaskDetails] SWOTD WITH (NOLOCK) ON SWOTD.SubWorkOrderTaskId = SWOT.SubWorkOrderTaskId
			LEFT JOIN [dbo].[SubWorkOrderTaskInstruction] SWOTI WITH (NOLOCK) ON SWOTI.SubWorkOrderTaskId = SWOT.SubWorkOrderTaskId AND (SWOTI.IsParent = 1 OR (SWOTI.IsParent = 0 AND SWOTI.ParentId IS NULL))
			WHERE SWOT.SubWorkOrderTaskId = @SubWorkOrderTaskId
			ORDER BY SWOTI.SubWorkOrderTaskInstructionId DESC
		END
		-- Insert data into SubWorkOrderTaskHistory when change Sub work order task sequence
		IF(@NewSubWorkOrderTaskId > 0)
		BEGIN
			INSERT INTO [dbo].[SubWorkOrderTaskHistory]
			(
				[SubWorkOrderTaskId], [TaskName], [Descrepancy], [Resolution], [TechId], 
				[TechName], [TechUpdatedDate], [InspectorId], [InspectorName], [InspectorUpdatedDate],
				[PrintInWO], [PrintInWOQ], [IsParent], [ParentId], [InstructionTitle], [InstructionDetails],
				[SequenceNumber],[IsActive], [IsDeleted], [UpdatedBy], [UpdatedDate],[SubWorkOrderTaskInstructionId],
				[SubWorkOrderTaskInstructionTechId], [SubWorkOrderTaskInstructionTechName],[SubWorkOrderTaskInstructionTechUpdatedDate],
				[SubWorkOrderTaskInstructionInspectorId], [SubWorkOrderTaskInstructionInspectorName],[SubWorkOrderTaskInstructionInspectorUpdatedDate] ,
				[SubWorkOrderTaskInstructionPrintInWO], [SubWorkOrderTaskInstructionPrintInWOQ]
			)
			SELECT TOP 1
				@NewSubWorkOrderTaskId, SWOT.[TaskName], SWOTD.[Descrepancy], SWOTD.[Resolution], SWOTD.[TechId],
				SWOTD.[TechName], SWOTD.[TechUpdatedDate], SWOTD.[InspectorId], SWOTD.[InspectorName], SWOTD.[InspectorUpdatedDate],
				SWOTD.[PrintInWO], SWOTD.[PrintInWOQ], SWOTI.[IsParent], SWOTI.[ParentId], SWOTI.[InstructionTitle], SWOTI.[InstructionDetails],
				SWOT.[SequenceNumber],SWOTI.[IsActive], SWOTI.[IsDeleted],@CreatedBy, GETUTCDATE(),SWOTI.[SubWorkOrderTaskInstructionId],
				SWOTI.TechId, SWOTI.TechName, SWOTI.TechUpdatedDate,
				SWOTI.InspectorId, SWOTI.InspectorName, SWOTI.InspectorUpdatedDate,
				SWOTI.PrintInWO, SWOTI.PrintInWOQ
			FROM
			[dbo].[SubWorkOrderTask] SWOT WITH (NOLOCK)
			LEFT JOIN [dbo].[SubWorkOrderTaskDetails] SWOTD WITH (NOLOCK) ON SWOTD.SubWorkOrderTaskId = SWOT.SubWorkOrderTaskId
			LEFT JOIN [dbo].[SubWorkOrderTaskInstruction] SWOTI WITH (NOLOCK) ON SWOTI.SubWorkOrderTaskId = SWOT.SubWorkOrderTaskId AND (SWOTI.IsParent = 1 OR (SWOTI.IsParent = 0 AND SWOTI.ParentId IS NULL))
			WHERE SWOT.SubWorkOrderTaskId = @NewSubWorkOrderTaskId 
			ORDER BY SWOTI.SubWorkOrderTaskInstructionId DESC
		END

		SELECT Scope_Identity() AS 'SubWorkOrderTaskHistoryId';

	END TRY
	BEGIN CATCH
		DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
        , @AdhocComments     VARCHAR(150)    = 'USP_AddSubWorkOrderTaskHistory'
        , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = ' + ISNULL(CAST(@SubWorkOrderTaskId AS varchar(10)) ,'') +'''
												 @Parameter2 = ' + ISNULL(CAST(@CreatedBy AS varchar(10)) ,'') +'''
												 @Parameter3 = ' + ISNULL(CAST(@SubWorkOrderTaskInstructionId AS varchar(10)) ,'') +'''
												 @Parameter4 = ' + ISNULL(CAST(@NewSubWorkOrderTaskId AS varchar(10)) ,'') +''
        , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
        exec spLogException
                @DatabaseName           =  @DatabaseName
                , @AdhocComments          =  @AdhocComments
                , @ProcedureParameters    =  @ProcedureParameters
                , @ApplicationName        =  @ApplicationName
                , @ErrorLogID             =  @ErrorLogID OUTPUT;
        RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
        RETURN(1);
	END CATCH
END;