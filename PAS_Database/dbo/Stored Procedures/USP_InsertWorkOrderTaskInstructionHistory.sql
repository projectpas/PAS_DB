/*************************************************************
 ** File:   [USP_InsertWorkOrderTaskInstructionHistory]
 ** Author:  Ekta Chandegra
 ** Description: This stored procedure is used to InsertWorkOrderTaskInstructionHistory by id
 ** Purpose:
 ** Date:   02/17/2025
    
 ** PARAMETERS:

 ** RETURN VALUE:

 **************************************************************
  ** Change History               
 **************************************************************
 ** PR   Date         Author			Change Description
 ** --   --------     -------			--------------------------------
    1    02/17/2025   Ekta Chandegra	Created
    2    04/28/2025   Ekta Chandegra	Add history when change sequence

-- EXEC dbo.USP_InsertWorkOrderTaskInstructionHistory @WorkOrderTaskInstructionId=1142,@UpdatedBy=N'EKTA CHANDEGRA'
**************************************************************/
CREATE    PROCEDURE [dbo].[USP_InsertWorkOrderTaskInstructionHistory]
	@WorkOrderTaskInstructionId BIGINT,
	@UpdatedBy VARCHAR(100),
	@InstructionListId VARCHAR(250),
	@NewWorkOrderTaskInstructionId BIGINT
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;	
	BEGIN TRY
		BEGIN
			IF(@WorkOrderTaskInstructionId > 0 AND ISNULL(@InstructionListId, '') <> '')
			BEGIN

				;WITH RecursiveCTE AS (
					-- Anchor member (base case)
					SELECT 
					  WOTI.WorkOrderTaskInstructionId,
					  WOTI.WorkOrderTaskId,
					  WOT.TaskId,
					  WOT.TaskName,
					  WOTI.InstructionTitle,
					  WOTI.InstructionDetails,
					  WOTI.SequenceNumber,
					  WOTI.TechId,
					  WOTI.TechName,
					  WOTI.TechUpdatedDate,
					  WOTI.InspectorId,
					  WOTI.InspectorName,
					  WOTI.InspectorUpdatedDate,
					  WOTI.PrintInWO,
					  WOTI.PrintInWOQ,
					  WOTI.MasterCompanyId,
					  WOTI.IsActive,
					  WOTI.IsDeleted,
					  WOTI.IsParent,
					  WOTI.ParentId,
					  WOTI.ParentSequenceNumber,
					  WOTI.InstructionListId
					FROM [dbo].[WorkOrderTaskInstruction] WOTI WITH (NOLOCK)
					LEFT JOIN [dbo].[WorkOrderTask] WOT WITH (NOLOCK) ON WOT.WorkOrderTaskId = WOTI.WorkOrderTaskId
					WHERE WOTI.WorkOrderTaskInstructionId = @WorkOrderTaskInstructionId

					UNION ALL

					-- Recursive member
					SELECT 
					  WOTI.WorkOrderTaskInstructionId,
					  WOTI.WorkOrderTaskId,
					  WOT.TaskId,
					  WOT.TaskName,
					  WOTI.InstructionTitle,
					  WOTI.InstructionDetails,
					  WOTI.SequenceNumber,
					  WOTI.TechId,
					  WOTI.TechName,
					  WOTI.TechUpdatedDate,
					  WOTI.InspectorId,
					  WOTI.InspectorName,
					  WOTI.InspectorUpdatedDate,
					  WOTI.PrintInWO,
					  WOTI.PrintInWOQ,
					  WOTI.MasterCompanyId,
					  WOTI.IsActive,
					  WOTI.IsDeleted,
					  WOTI.IsParent,
					  WOTI.ParentId,
					  WOTI.ParentSequenceNumber,
					  WOTI.InstructionListId
					FROM [dbo].[WorkOrderTaskInstruction] WOTI WITH (NOLOCK)
					INNER JOIN [dbo].[WorkOrderTask] WOT WITH (NOLOCK) ON WOT.WorkOrderTaskId = WOTI.WorkOrderTaskId
					INNER JOIN RecursiveCTE R ON WOTI.ParentId = R.WorkOrderTaskInstructionId
				)

				INSERT INTO [dbo].[WorkOrderTaskInstructionHistory]
				(	
					[WorkOrderTaskInstructionId],[WorkOrderTaskId],[TaskId] ,[TaskName],[InstructionTitle],
					[InstructionDetails],[SequenceNumber],[TechId],[TechName],[TechUpdatedDate],[InspectorId],[InspectorName],
					[InspectorUpdatedDate],[PrintInWO],[PrintInWOQ],[MasterCompanyId],[UpdatedBy],
					[UpdatedDate],[IsActive],[IsDeleted],[ParentId],[IsParent],[ParentSequenceNumber],[InstructionListId]
				)
				
				SELECT 
					[WorkOrderTaskInstructionId],[WorkOrderTaskId],[TaskId],[TaskName],[InstructionTitle],
					[InstructionDetails],[SequenceNumber],[TechId],[TechName],[TechUpdatedDate],[InspectorId],[InspectorName],
					[InspectorUpdatedDate],[PrintInWO],[PrintInWOQ],[MasterCompanyId],@UpdatedBy,
					GETUTCDATE(),[IsActive],[IsDeleted],[ParentId],[IsParent],[ParentSequenceNumber],[InstructionListId]
				FROM [RecursiveCTE];
			END
			ELSE
			BEGIN
				INSERT INTO [dbo].[WorkOrderTaskInstructionHistory]
				(	
					[WorkOrderTaskInstructionId],[WorkOrderTaskId],[TaskId] ,[TaskName],[InstructionTitle],
					[InstructionDetails],[SequenceNumber],[TechId],[TechName],[TechUpdatedDate],[InspectorId],[InspectorName],
					[InspectorUpdatedDate],[PrintInWO],[PrintInWOQ],[MasterCompanyId],[UpdatedBy],
					[UpdatedDate],[IsActive],[IsDeleted],[ParentId],[IsParent],[ParentSequenceNumber],[InstructionListId]
				)
				
				SELECT 
					WOTI.[WorkOrderTaskInstructionId],WOTI.[WorkOrderTaskId],WOT.[TaskId],WOT.[TaskName],WOTI.[InstructionTitle],
					WOTI.[InstructionDetails],WOTI.[SequenceNumber],WOTI.[TechId],WOTI.[TechName],WOTI.[TechUpdatedDate],WOTI.[InspectorId],WOTI.[InspectorName],
					WOTI.[InspectorUpdatedDate],WOTI.[PrintInWO],WOTI.[PrintInWOQ],WOTI.[MasterCompanyId],@UpdatedBy,
					GETUTCDATE(),WOTI.[IsActive],WOTI.[IsDeleted],WOTI.[ParentId],WOTI.[IsParent],WOTI.[ParentSequenceNumber],WOTI.[InstructionListId]
				FROM [dbo].[WorkOrderTaskInstruction] WOTI WITH (NOLOCK)
				LEFT JOIN [dbo].[WorkOrderTask] WOT WITH (NOLOCK) ON WOT.WorkOrderTaskId = WOTI.WorkOrderTaskId
				WHERE WOTI.WorkOrderTaskInstructionId = @WorkOrderTaskInstructionId
			END
			IF(@NewWorkOrderTaskInstructionId > 0 AND ISNULL(@InstructionListId, '') <> '')
			BEGIN

				;WITH RecursiveCTE AS (
					-- Anchor member (base case)
					SELECT 
					  WOTI.WorkOrderTaskInstructionId,
					  WOTI.WorkOrderTaskId,
					  WOT.TaskId,
					  WOT.TaskName,
					  WOTI.InstructionTitle,
					  WOTI.InstructionDetails,
					  WOTI.SequenceNumber,
					  WOTI.TechId,
					  WOTI.TechName,
					  WOTI.TechUpdatedDate,
					  WOTI.InspectorId,
					  WOTI.InspectorName,
					  WOTI.InspectorUpdatedDate,
					  WOTI.PrintInWO,
					  WOTI.PrintInWOQ,
					  WOTI.MasterCompanyId,
					  WOTI.IsActive,
					  WOTI.IsDeleted,
					  WOTI.IsParent,
					  WOTI.ParentId,
					  WOTI.ParentSequenceNumber,
					  WOTI.InstructionListId
					FROM [dbo].[WorkOrderTaskInstruction] WOTI WITH (NOLOCK)
					LEFT JOIN [dbo].[WorkOrderTask] WOT WITH (NOLOCK) ON WOT.WorkOrderTaskId = WOTI.WorkOrderTaskId
					WHERE WOTI.WorkOrderTaskInstructionId = @NewWorkOrderTaskInstructionId

					UNION ALL

					-- Recursive member
					SELECT 
					  WOTI.WorkOrderTaskInstructionId,
					  WOTI.WorkOrderTaskId,
					  WOT.TaskId,
					  WOT.TaskName,
					  WOTI.InstructionTitle,
					  WOTI.InstructionDetails,
					  WOTI.SequenceNumber,
					  WOTI.TechId,
					  WOTI.TechName,
					  WOTI.TechUpdatedDate,
					  WOTI.InspectorId,
					  WOTI.InspectorName,
					  WOTI.InspectorUpdatedDate,
					  WOTI.PrintInWO,
					  WOTI.PrintInWOQ,
					  WOTI.MasterCompanyId,
					  WOTI.IsActive,
					  WOTI.IsDeleted,
					  WOTI.IsParent,
					  WOTI.ParentId,
					  WOTI.ParentSequenceNumber,
					  WOTI.InstructionListId
					FROM [dbo].[WorkOrderTaskInstruction] WOTI WITH (NOLOCK)
					INNER JOIN [dbo].[WorkOrderTask] WOT WITH (NOLOCK) ON WOT.WorkOrderTaskId = WOTI.WorkOrderTaskId
					INNER JOIN RecursiveCTE R ON WOTI.ParentId = R.WorkOrderTaskInstructionId
				)

				INSERT INTO [dbo].[WorkOrderTaskInstructionHistory]
				(	
					[WorkOrderTaskInstructionId],[WorkOrderTaskId],[TaskId] ,[TaskName],[InstructionTitle],
					[InstructionDetails],[SequenceNumber],[TechId],[TechName],[TechUpdatedDate],[InspectorId],[InspectorName],
					[InspectorUpdatedDate],[PrintInWO],[PrintInWOQ],[MasterCompanyId],[UpdatedBy],
					[UpdatedDate],[IsActive],[IsDeleted],[ParentId],[IsParent],[ParentSequenceNumber],[InstructionListId]
				)
				
				SELECT 
					[WorkOrderTaskInstructionId],[WorkOrderTaskId],[TaskId],[TaskName],[InstructionTitle],
					[InstructionDetails],[SequenceNumber],[TechId],[TechName],[TechUpdatedDate],[InspectorId],[InspectorName],
					[InspectorUpdatedDate],[PrintInWO],[PrintInWOQ],[MasterCompanyId],@UpdatedBy,
					GETUTCDATE(),[IsActive],[IsDeleted],[ParentId],[IsParent],[ParentSequenceNumber],[InstructionListId]
				FROM [RecursiveCTE]; 
			END
			ELSE
			BEGIN
				INSERT INTO [dbo].[WorkOrderTaskInstructionHistory]
				(	
					[WorkOrderTaskInstructionId],[WorkOrderTaskId],[TaskId] ,[TaskName],[InstructionTitle],
					[InstructionDetails],[SequenceNumber],[TechId],[TechName],[TechUpdatedDate],[InspectorId],[InspectorName],
					[InspectorUpdatedDate],[PrintInWO],[PrintInWOQ],[MasterCompanyId],[UpdatedBy],
					[UpdatedDate],[IsActive],[IsDeleted],[ParentId],[IsParent],[ParentSequenceNumber],[InstructionListId]
				)
				
				SELECT 
					WOTI.[WorkOrderTaskInstructionId],WOTI.[WorkOrderTaskId],WOT.[TaskId],WOT.[TaskName],WOTI.[InstructionTitle],
					WOTI.[InstructionDetails],WOTI.[SequenceNumber],WOTI.[TechId],WOTI.[TechName],WOTI.[TechUpdatedDate],WOTI.[InspectorId],WOTI.[InspectorName],
					WOTI.[InspectorUpdatedDate],WOTI.[PrintInWO],WOTI.[PrintInWOQ],WOTI.[MasterCompanyId],@UpdatedBy,
					GETUTCDATE(),WOTI.[IsActive],WOTI.[IsDeleted],WOTI.[ParentId],WOTI.[IsParent],WOTI.[ParentSequenceNumber],WOTI.[InstructionListId]
				FROM [dbo].[WorkOrderTaskInstruction] WOTI WITH (NOLOCK)
				LEFT JOIN [dbo].[WorkOrderTask] WOT WITH (NOLOCK) ON WOT.WorkOrderTaskId = WOTI.WorkOrderTaskId
				WHERE WOTI.WorkOrderTaskInstructionId = @NewWorkOrderTaskInstructionId
			END
		END
	END TRY
	BEGIN CATCH
	DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
        , @AdhocComments     VARCHAR(150)    = 'USP_InsertWorkOrderTaskInstructionHistory'
        , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = ' + ISNULL(CAST(@WorkOrderTaskInstructionId AS varchar(100)) ,'') +''

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