/*************************************************************             
** File:   [USP_GetWorkOrderTasksForTemplateCopy]
** Author:   SUMIT KUMAR
** Description: Retrieve streamlined task data for Step 3 in Work Order Template Copy wizard.
** Purpose: Optimized task fetch for wizard review stage.
** Date:   07/07/2026
**************************************************************
** Change History
**************************************************************
** PR   Date         Author				Change Description
** --   --------     -------			----------------------
	1   07/07/2026   Sumit Kumar		Created
	
**************************************************************/
CREATE PROCEDURE [dbo].[USP_GetWorkOrderTasksForTemplateCopy]
(
	@WorkOrderId BIGINT,
	@WorkOrderPartNumberId BIGINT
)
AS
BEGIN
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

	BEGIN TRY
		-- Step 1: Collect all active task IDs for this Work Order Part Number
		DECLARE @TargetTasks TABLE (WorkOrderTaskId BIGINT PRIMARY KEY);

		INSERT INTO @TargetTasks (WorkOrderTaskId)
		SELECT WorkOrderTaskId
		FROM dbo.WorkOrderTask WITH(NOLOCK)
		WHERE WorkOrderId = @WorkOrderId 
		  AND WorkOrderPartNumberId = @WorkOrderPartNumberId
		  AND IsActive = 1 
		  AND IsDeleted = 0;

		-- Step 2: Collect only task IDs that have associated child data using short-circuiting
		DECLARE @TasksWithData TABLE (WorkOrderTaskId BIGINT PRIMARY KEY);
		DECLARE @TargetCount INT = (SELECT COUNT(1) FROM @TargetTasks);

		IF @TargetCount > 0
		BEGIN
			-- Query 1: WorkOrderMaterials
			INSERT INTO @TasksWithData (WorkOrderTaskId)
			SELECT DISTINCT TaskId FROM dbo.WorkOrderMaterials WITH(NOLOCK) 
			WHERE TaskId IN (SELECT WorkOrderTaskId FROM @TargetTasks) AND IsDeleted = 0;

			-- Query 2: WorkOrderMaterialsKit
			IF (SELECT COUNT(1) FROM @TasksWithData) < @TargetCount
			BEGIN
				INSERT INTO @TasksWithData (WorkOrderTaskId)
				SELECT DISTINCT TaskId FROM dbo.WorkOrderMaterialsKit WITH(NOLOCK) 
				WHERE TaskId IN (SELECT WorkOrderTaskId FROM @TargetTasks)
				  AND TaskId NOT IN (SELECT WorkOrderTaskId FROM @TasksWithData)
				  AND IsDeleted = 0;
			END

			-- Query 3: WorkOrderLaborTracking
			IF (SELECT COUNT(1) FROM @TasksWithData) < @TargetCount
			BEGIN
				INSERT INTO @TasksWithData (WorkOrderTaskId)
				SELECT DISTINCT TaskId FROM dbo.WorkOrderLaborTracking WITH(NOLOCK) 
				WHERE TaskId IN (SELECT WorkOrderTaskId FROM @TargetTasks)
				  AND TaskId NOT IN (SELECT WorkOrderTaskId FROM @TasksWithData)
				  AND IsDeleted = 0;
			END

			-- Query 4: WorkOrderAssets
			IF (SELECT COUNT(1) FROM @TasksWithData) < @TargetCount
			BEGIN
				INSERT INTO @TasksWithData (WorkOrderTaskId)
				SELECT DISTINCT TaskId FROM dbo.WorkOrderAssets WITH(NOLOCK) 
				WHERE TaskId IN (SELECT WorkOrderTaskId FROM @TargetTasks)
				  AND TaskId NOT IN (SELECT WorkOrderTaskId FROM @TasksWithData)
				  AND IsDeleted = 0;
			END

			-- Query 5: WorkOrderFreight
			IF (SELECT COUNT(1) FROM @TasksWithData) < @TargetCount
			BEGIN
				INSERT INTO @TasksWithData (WorkOrderTaskId)
				SELECT DISTINCT TaskId FROM dbo.WorkOrderFreight WITH(NOLOCK) 
				WHERE TaskId IN (SELECT WorkOrderTaskId FROM @TargetTasks)
				  AND TaskId NOT IN (SELECT WorkOrderTaskId FROM @TasksWithData)
				  AND IsDeleted = 0;
			END

			-- Query 6: WorkOrderCharges
			IF (SELECT COUNT(1) FROM @TasksWithData) < @TargetCount
			BEGIN
				INSERT INTO @TasksWithData (WorkOrderTaskId)
				SELECT DISTINCT TaskId FROM dbo.WorkOrderCharges WITH(NOLOCK) 
				WHERE TaskId IN (SELECT WorkOrderTaskId FROM @TargetTasks)
				  AND TaskId NOT IN (SELECT WorkOrderTaskId FROM @TasksWithData)
				  AND IsDeleted = 0;
			END

			-- Query 7: WorkOrderTaskInstruction
			IF (SELECT COUNT(1) FROM @TasksWithData) < @TargetCount
			BEGIN
				INSERT INTO @TasksWithData (WorkOrderTaskId)
				SELECT DISTINCT WorkOrderTaskId FROM dbo.WorkOrderTaskInstruction WITH(NOLOCK) 
				WHERE WorkOrderTaskId IN (SELECT WorkOrderTaskId FROM @TargetTasks)
				  AND WorkOrderTaskId NOT IN (SELECT WorkOrderTaskId FROM @TasksWithData)
				  AND IsDeleted = 0;
			END
		END

		-- Step 3: Run the final query joining the pre-aggregated results
		SELECT 
			WOT.WorkOrderTaskId,
			WOT.TaskId,
			WOT.SequenceNumber,
			WOT.TaskName,
			WS.WorkScopeCode AS WorkScope,
			WOTD.TechId,
			WOTD.InspectorId,
			CAST(CASE WHEN TWD.WorkOrderTaskId IS NOT NULL THEN 1 ELSE 0 END AS BIT) AS HasAssociatedData
		FROM dbo.WorkOrderTask WOT WITH(NOLOCK)
		INNER JOIN dbo.WorkOrderTaskDetails WOTD WITH(NOLOCK) ON WOT.WorkOrderTaskId = WOTD.WorkOrderTaskId
		LEFT JOIN  dbo.Task TSK WITH(NOLOCK) ON TSK.TaskId = WOT.TaskId
		LEFT JOIN  dbo.WorkOrderPartNumber WOPN WITH(NOLOCK) ON WOT.WorkOrderPartNumberId = WOPN.ID
		LEFT JOIN  dbo.WorkScope WS WITH(NOLOCK) ON WOPN.WorkOrderScopeId = WS.WorkScopeId
		LEFT JOIN  @TasksWithData TWD ON WOT.WorkOrderTaskId = TWD.WorkOrderTaskId
		WHERE WOT.WorkOrderId = @WorkOrderId 
		  AND WOT.WorkOrderPartNumberId = @WorkOrderPartNumberId
		  AND WOT.IsActive = 1 
		  AND WOT.IsDeleted = 0
		ORDER BY TRY_CAST(WOT.SequenceNumber AS DECIMAL(10, 4));
	END TRY
	BEGIN CATCH
		DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()
		, @AdhocComments     VARCHAR(150)    = 'USP_GetWorkOrderTasksForTemplateCopy'
		, @ProcedureParameters VARCHAR(3000)  = '@WorkOrderId = ' + ISNULL(CAST(@WorkOrderId AS VARCHAR(100)), '') + ', @WorkOrderPartNumberId = ' + ISNULL(CAST(@WorkOrderPartNumberId AS VARCHAR(100)), '')
		, @ApplicationName VARCHAR(100) = 'PAS'

		exec spLogException 
			@DatabaseName           = @DatabaseName
			, @AdhocComments          = @AdhocComments
			, @ProcedureParameters    = @ProcedureParameters
			, @ApplicationName        = @ApplicationName
			, @ErrorLogID             = @ErrorLogID OUTPUT ;
		RAISERROR ('Unexpected Error Occured in the database.', 16, 1)
		RETURN(1);
	END CATCH
END
GO
