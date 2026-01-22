/***************************************************************  
 ** File:   [USP_InsertSubWorkOrderTaskInstructionHistory]
 ** Author:   Ekta Chandegra
 ** Description: This stored procedure is used to InsertSubWorkOrderTaskInstructionHistory 
 ** Purpose:
 ** Date:   03/27/2025

 ** PARAMETERS: @SubWorkOrderTaskInstructionId BIGINT, @UpdatedBy VARCHAR(100),@InstructionListId VARCHAR(250)

 ** RETURN VALUE:

 ** Change History
 **************************************************************
 ** PR   Date         Author  		 Change Description
 ** --   --------     -------		 --------------------------------
    1    03/27/2025   Ekta Chandegra	 Created
    2    03/28/2025   Ekta Chandegra	 Insert history when change instruction sequence

EXEC USP_InsertSubWorkOrderTaskInstructionHistory 12,N'EKTA CHANDEGRA',16
**************************************************************/
CREATE   PROCEDURE [dbo].[USP_InsertSubWorkOrderTaskInstructionHistory]
	@SubWorkOrderTaskInstructionId BIGINT,
	@UpdatedBy VARCHAR(100),
	@InstructionListId VARCHAR(250),
	@NewSubWorkOrderTaskInstructionId BIGINT
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;	
	BEGIN TRY
		BEGIN
			IF(@SubWorkOrderTaskInstructionId > 0 AND ISNULL(@InstructionListId, '') <> '')
			BEGIN
			;WITH RecursiveCTE AS (
					-- Anchor member (base case)
					SELECT 
					  SWOTI.SubWorkOrderTaskInstructionId,
					  SWOTI.SubWorkOrderTaskId,
					  SWOT.TaskId,
					  SWOT.TaskName,
					  SWOTI.InstructionTitle,
					  SWOTI.InstructionDetails,
					  SWOTI.SequenceNumber,
					  SWOTI.TechId,
					  SWOTI.TechName,
					  SWOTI.TechUpdatedDate,
					  SWOTI.InspectorId,
					  SWOTI.InspectorName,
					  SWOTI.InspectorUpdatedDate,
					  SWOTI.PrintInWO,
					  SWOTI.PrintInWOQ,
					  SWOTI.MasterCompanyId,
					  SWOTI.IsActive,
					  SWOTI.IsDeleted,
					  SWOTI.IsParent,
					  SWOTI.ParentId,
					  SWOTI.ParentSequenceNumber,
					  SWOTI.InstructionListId
					FROM [dbo].[SubWorkOrderTaskInstruction] SWOTI WITH (NOLOCK)
					LEFT JOIN [dbo].[SubWorkOrderTask] SWOT WITH (NOLOCK) ON SWOT.SubWorkOrderTaskId = SWOTI.SubWorkOrderTaskId
					WHERE SWOTI.SubWorkOrderTaskInstructionId = @SubWorkOrderTaskInstructionId

					UNION ALL

					-- Recursive member
					SELECT 
					  SWOTI.SubWorkOrderTaskInstructionId,
					  SWOTI.SubWorkOrderTaskId,
					  SWOT.TaskId,
					  SWOT.TaskName,
					  SWOTI.InstructionTitle,
					  SWOTI.InstructionDetails,
					  SWOTI.SequenceNumber,
					  SWOTI.TechId,
					  SWOTI.TechName,
					  SWOTI.TechUpdatedDate,
					  SWOTI.InspectorId,
					  SWOTI.InspectorName,
					  SWOTI.InspectorUpdatedDate,
					  SWOTI.PrintInWO,
					  SWOTI.PrintInWOQ,
					  SWOTI.MasterCompanyId,
					  SWOTI.IsActive,
					  SWOTI.IsDeleted,
					  SWOTI.IsParent,
					  SWOTI.ParentId,
					  SWOTI.ParentSequenceNumber,
					  SWOTI.InstructionListId
					FROM [dbo].[SubWorkOrderTaskInstruction] SWOTI WITH (NOLOCK)
					INNER JOIN [dbo].[SubWorkOrderTask] SWOT WITH (NOLOCK) ON SWOT.SubWorkOrderTaskId = SWOTI.SubWorkOrderTaskId
					INNER JOIN RecursiveCTE R ON SWOTI.ParentId = R.SubWorkOrderTaskInstructionId

				)

				INSERT INTO [dbo].[SubWorkOrderTaskInstructionHistory]
				(	
					[SubWorkOrderTaskInstructionId],[SubWorkOrderTaskId],[TaskId] ,[TaskName],[InstructionTitle],
					[InstructionDetails],[SequenceNumber],[TechId],[TechName],[TechUpdatedDate],[InspectorId],[InspectorName],
					[InspectorUpdatedDate],[PrintInWO],[PrintInWOQ],[MasterCompanyId],[UpdatedBy],
					[UpdatedDate],[IsActive],[IsDeleted],[ParentId],[IsParent],[ParentSequenceNumber],[InstructionListId]
				)
				
				SELECT 
					[SubWorkOrderTaskInstructionId],[SubWorkOrderTaskId],[TaskId],[TaskName],[InstructionTitle],
					[InstructionDetails],[SequenceNumber],[TechId],[TechName],[TechUpdatedDate],[InspectorId],[InspectorName],
					[InspectorUpdatedDate],[PrintInWO],[PrintInWOQ],[MasterCompanyId],@UpdatedBy,
					GETUTCDATE(),[IsActive],[IsDeleted],[ParentId],[IsParent],[ParentSequenceNumber],[InstructionListId]
				FROM [RecursiveCTE];

			END
			ELSE
			BEGIN
				INSERT INTO [dbo].[SubWorkOrderTaskInstructionHistory]
				(	
					[SubWorkOrderTaskInstructionId],[SubWorkOrderTaskId],[TaskId] ,[TaskName],[InstructionTitle],
					[InstructionDetails],[SequenceNumber],[TechId],[TechName],[TechUpdatedDate],[InspectorId],[InspectorName],
					[InspectorUpdatedDate],[PrintInWO],[PrintInWOQ],[MasterCompanyId],[UpdatedBy],
					[UpdatedDate],[IsActive],[IsDeleted],[ParentId],[IsParent],[ParentSequenceNumber],[InstructionListId]
				)
				
				SELECT 
					SWOTI.[SubWorkOrderTaskInstructionId],SWOTI.[SubWorkOrderTaskId],SWOT.[TaskId],SWOT.[TaskName],SWOTI.[InstructionTitle],
					SWOTI.[InstructionDetails],SWOTI.[SequenceNumber],SWOTI.[TechId],SWOTI.[TechName],SWOTI.[TechUpdatedDate],SWOTI.[InspectorId],SWOTI.[InspectorName],
					SWOTI.[InspectorUpdatedDate],SWOTI.[PrintInWO],SWOTI.[PrintInWOQ],SWOTI.[MasterCompanyId],@UpdatedBy,
					GETUTCDATE(),SWOTI.[IsActive],SWOTI.[IsDeleted],SWOTI.[ParentId],SWOTI.[IsParent],SWOTI.[ParentSequenceNumber],SWOTI.[InstructionListId]
				FROM [dbo].[SubWorkOrderTaskInstruction] SWOTI WITH (NOLOCK)
				LEFT JOIN [dbo].[SubWorkOrderTask] SWOT WITH (NOLOCK) ON SWOT.SubWorkOrderTaskId = SWOTI.SubWorkOrderTaskId
				WHERE SWOTI.SubWorkOrderTaskInstructionId = @SubWorkOrderTaskInstructionId
			END
		END
		IF(@NewSubWorkOrderTaskInstructionId > 0 AND ISNULL(@InstructionListId, '') <> '')
		BEGIN
		;WITH RecursiveCTE AS (
			-- Anchor member (base case)
			SELECT 
			  SWOTI.SubWorkOrderTaskInstructionId,
			  SWOTI.SubWorkOrderTaskId,
			  SWOT.TaskId,
			  SWOT.TaskName,
			  SWOTI.InstructionTitle,
			  SWOTI.InstructionDetails,
			  SWOTI.SequenceNumber,
			  SWOTI.TechId,
			  SWOTI.TechName,
			  SWOTI.TechUpdatedDate,
			  SWOTI.InspectorId,
			  SWOTI.InspectorName,
			  SWOTI.InspectorUpdatedDate,
			  SWOTI.PrintInWO,
			  SWOTI.PrintInWOQ,
			  SWOTI.MasterCompanyId,
			  SWOTI.IsActive,
			  SWOTI.IsDeleted,
			  SWOTI.IsParent,
			  SWOTI.ParentId,
			  SWOTI.ParentSequenceNumber,
			  SWOTI.InstructionListId
			FROM [dbo].[SubWorkOrderTaskInstruction] SWOTI WITH (NOLOCK)
			LEFT JOIN [dbo].[SubWorkOrderTask] SWOT WITH (NOLOCK) ON SWOT.SubWorkOrderTaskId = SWOTI.SubWorkOrderTaskId
			WHERE SWOTI.SubWorkOrderTaskInstructionId = @NewSubWorkOrderTaskInstructionId 

			UNION ALL

			-- Recursive member
			SELECT 
			  SWOTI.SubWorkOrderTaskInstructionId,
			  SWOTI.SubWorkOrderTaskId,
			  SWOT.TaskId,
			  SWOT.TaskName,
			  SWOTI.InstructionTitle,
			  SWOTI.InstructionDetails,
			  SWOTI.SequenceNumber,
			  SWOTI.TechId,
			  SWOTI.TechName,
			  SWOTI.TechUpdatedDate,
			  SWOTI.InspectorId,
			  SWOTI.InspectorName,
			  SWOTI.InspectorUpdatedDate,
			  SWOTI.PrintInWO,
			  SWOTI.PrintInWOQ,
			  SWOTI.MasterCompanyId,
			  SWOTI.IsActive,
			  SWOTI.IsDeleted,
			  SWOTI.IsParent,
			  SWOTI.ParentId,
			  SWOTI.ParentSequenceNumber,
			  SWOTI.InstructionListId
			FROM [dbo].[SubWorkOrderTaskInstruction] SWOTI WITH (NOLOCK)
			INNER JOIN [dbo].[SubWorkOrderTask] SWOT WITH (NOLOCK) ON SWOT.SubWorkOrderTaskId = SWOTI.SubWorkOrderTaskId
			INNER JOIN RecursiveCTE R ON SWOTI.ParentId = R.SubWorkOrderTaskInstructionId
		)

		INSERT INTO [dbo].[SubWorkOrderTaskInstructionHistory]
		(	
			[SubWorkOrderTaskInstructionId],[SubWorkOrderTaskId],[TaskId] ,[TaskName],[InstructionTitle],
			[InstructionDetails],[SequenceNumber],[TechId],[TechName],[TechUpdatedDate],[InspectorId],[InspectorName],
			[InspectorUpdatedDate],[PrintInWO],[PrintInWOQ],[MasterCompanyId],[UpdatedBy],
			[UpdatedDate],[IsActive],[IsDeleted],[ParentId],[IsParent],[ParentSequenceNumber],[InstructionListId]
		)
	
		SELECT 
			[SubWorkOrderTaskInstructionId],[SubWorkOrderTaskId],[TaskId],[TaskName],[InstructionTitle],
			[InstructionDetails],[SequenceNumber],[TechId],[TechName],[TechUpdatedDate],[InspectorId],[InspectorName],
			[InspectorUpdatedDate],[PrintInWO],[PrintInWOQ],[MasterCompanyId],@UpdatedBy,
			GETUTCDATE(),[IsActive],[IsDeleted],[ParentId],[IsParent],[ParentSequenceNumber],[InstructionListId]
		FROM [RecursiveCTE]; 
	END
	ELSE
	BEGIN
		INSERT INTO [dbo].[SubWorkOrderTaskInstructionHistory]
		(	
			[SubWorkOrderTaskInstructionId],[SubWorkOrderTaskId],[TaskId] ,[TaskName],[InstructionTitle],
			[InstructionDetails],[SequenceNumber],[TechId],[TechName],[TechUpdatedDate],[InspectorId],[InspectorName],
			[InspectorUpdatedDate],[PrintInWO],[PrintInWOQ],[MasterCompanyId],[UpdatedBy],
			[UpdatedDate],[IsActive],[IsDeleted],[ParentId],[IsParent],[ParentSequenceNumber],[InstructionListId]
		)
	
		SELECT 
			SWOTI.[SubWorkOrderTaskInstructionId],SWOTI.[SubWorkOrderTaskId],SWOT.[TaskId],SWOT.[TaskName],SWOTI.[InstructionTitle],
			SWOTI.[InstructionDetails],SWOTI.[SequenceNumber],SWOTI.[TechId],SWOTI.[TechName],SWOTI.[TechUpdatedDate],SWOTI.[InspectorId],SWOTI.[InspectorName],
			SWOTI.[InspectorUpdatedDate],SWOTI.[PrintInWO],SWOTI.[PrintInWOQ],SWOTI.[MasterCompanyId],@UpdatedBy,
			GETUTCDATE(),SWOTI.[IsActive],SWOTI.[IsDeleted],SWOTI.[ParentId],SWOTI.[IsParent],SWOTI.[ParentSequenceNumber],SWOTI.[InstructionListId]
		FROM [dbo].[SubWorkOrderTaskInstruction] SWOTI WITH (NOLOCK)
		LEFT JOIN [dbo].[SubWorkOrderTask] SWOT WITH (NOLOCK) ON SWOT.SubWorkOrderTaskId = SWOTI.SubWorkOrderTaskId
		WHERE SWOTI.SubWorkOrderTaskInstructionId = @NewSubWorkOrderTaskInstructionId
	END
	END TRY
	BEGIN CATCH
	DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
        , @AdhocComments     VARCHAR(150)    = 'USP_InsertSubWorkOrderTaskInstructionHistory'
        , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = ''' + ISNULL(CAST(@SubWorkOrderTaskInstructionId AS varchar(100)) ,'') +''',
												 @Parameter2 = ' + ISNULL(CAST(@UpdatedBy AS varchar(100)) ,'') +''',
												 @Parameter3 = ' + ISNULL(CAST(@InstructionListId AS varchar(100)) ,'') +''

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
END