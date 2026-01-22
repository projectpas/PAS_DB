/***************************************************************  
 ** File:   [USP_CreateNewVersionWorkFlowTaskInstructionMaster]             
 ** Author:   Devendra Shekh
 ** Description: This stored procedure is used to save task Instruction Master For New Version Work Flow
 ** Date:  10-Feb-2025
            
  ** Change History             
 **************************************************************             
 ** PR   Date				Author  					Change Description              
 ** --   --------			-------					--------------------------------            
    1    10-Feb-2025		Devendra Shekh					Created
  
**************************************************************/
CREATE   PROCEDURE [dbo].[USP_CreateNewVersionWorkFlowTaskInstructionMaster]
	@tbl_WorkflowDirectionType [WorkflowDirectionType] READONLY
AS
BEGIN
    SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	BEGIN TRY

		DECLARE @TotalRecords BIGINT = 0, @CurrentRecordId BIGINT = 0, @CurrentWorkflowDirectionId BIGINT = 0, @NewWorkflowDirectionId BIGINT = 0;

		IF OBJECT_ID('tempdb..#WorkFlowDirectionsData') IS NOT NULL
			DROP TABLE #WorkFlowDirectionsData

		CREATE TABLE #WorkFlowDirectionsData (
			[TempWorkflowDirectionId] [bigint] IDENTITY(1,1) NOT NULL,
			[WorkflowDirectionId] [bigint] NULL,
			[WorkflowId] [bigint] NULL,
			[Action] [nvarchar](max) NULL,
			[Description] [nvarchar](max) NULL,
			[Sequence] [varchar](100) NULL,
			[Memo] [nvarchar](max) NULL,
			[TaskId] [bigint] NULL,
			[MasterCompanyId] [int] NULL,
			[CreatedBy] [varchar](256) NULL,
			[UpdatedBy] [varchar](256) NULL,
			[CreatedDate] [datetime2](7) NULL,
			[UpdatedDate] [datetime2](7) NULL,
			[IsActive] [bit] NULL,
			[IsDeleted] [bit] NULL,
			[Order] [int] NULL,
			[WFParentId] [bigint] NULL,
			[IsVersionIncrease] [bit] NULL,
			[TaskName] [varchar](200) NULL,
			[ParentId] [bigint] NULL,
			[IsParent] [bit] NULL,
			[IsTaskDetails] [bit] NULL,
			[NewParentId] [bigint] NULL,
		)

		INSERT INTO #WorkFlowDirectionsData(
				[WorkflowDirectionId], [WorkflowId], [Action],[Description], [Sequence], [Memo], [TaskId], [MasterCompanyId], [CreatedBy], [UpdatedBy], [CreatedDate],
				[UpdatedDate], [IsActive], [IsDeleted], [Order], [WFParentId], [IsVersionIncrease], [TaskName], [ParentId], [IsParent], [IsTaskDetails])
		SELECT	[WorkflowDirectionId], [WorkflowId], [Action],[Description], [Sequence], [Memo], [TaskId], [MasterCompanyId], [CreatedBy], [UpdatedBy], [CreatedDate],
				[UpdatedDate], [IsActive], [IsDeleted], [Order], [WFParentId], [IsVersionIncrease], [TaskName], [ParentId], [IsParent], [IsTaskDetails]
		FROM @tbl_WorkflowDirectionType ORDER BY [WorkflowDirectionId] ASC

		SELECT @TotalRecords = MAX([TempWorkflowDirectionId]), @CurrentRecordId = MIN([TempWorkflowDirectionId]) FROM #WorkFlowDirectionsData;

		WHILE(ISNULL(@TotalRecords, 0) >= ISNULL(@CurrentRecordId, 0))
		BEGIN

			SELECT @CurrentWorkflowDirectionId = WorkflowDirectionId FROM #WorkFlowDirectionsData WHERE [TempWorkflowDirectionId] = @CurrentRecordId;

			INSERT INTO [DBO].[WorkflowDirection] (
					[WorkflowId], [Action],[Description], [Sequence], [Memo], [TaskId], [MasterCompanyId], [CreatedBy], [UpdatedBy], [CreatedDate],
					[UpdatedDate], [IsActive], [IsDeleted], [Order], [WFParentId], [IsVersionIncrease], [TaskName], [ParentId], [IsParent], [IsTaskDetails])
			SELECT	[WorkflowId], [Action],[Description], [Sequence], [Memo], [TaskId], [MasterCompanyId], [CreatedBy], [UpdatedBy], [CreatedDate],
					[UpdatedDate], [IsActive], [IsDeleted], [Order], [WFParentId], [IsVersionIncrease], [TaskName], [NewParentId], [IsParent], [IsTaskDetails]
			FROM #WorkFlowDirectionsData WHERE [TempWorkflowDirectionId] = @CurrentRecordId;

			SET @NewWorkflowDirectionId = SCOPE_IDENTITY()

			UPDATE WF
			SET WF.NewParentId = @NewWorkflowDirectionId
			FROM #WorkFlowDirectionsData WF WHERE WF.ParentId = @CurrentWorkflowDirectionId;

			SET @CurrentRecordId += 1;
		END

	END TRY   
	BEGIN CATCH      
	         DECLARE @ErrorLogID INT
			,@DatabaseName VARCHAR(100) = db_name()
			-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
			,@AdhocComments VARCHAR(150) = 'USP_CreateNewVersionWorkFlowTaskInstructionMaster'
			,@ProcedureParameters VARCHAR(3000) = ''
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