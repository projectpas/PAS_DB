/*************************************************************
** File:   [USP_DeleteAllWorkOrderTasks]
** Author:   Bhargav Saliya
** Description: "Delete All Tasks" for a Dynamic Work Order part number. Every task WITHOUT transaction
**              data is deleted; every task WITH transaction data is kept and returned with its reasons.
**              If every task has transaction data, nothing is deleted.
**
**              A task is KEPT when it has any of (checked on soft-deleted child rows too):
**                1. Materials : qty currently reserved / issued, sub WO, PO / RO link, or stockline
**                               received against the material (stock + kit). Old reserve/issue history of a
**                               material that was unreserved / returned does NOT block and is cleaned up.
**                2. Labor     : clock-in / time tracking, labor started (IsBegin / StartDate),
**                               IN-PROCESS / COMPLETED status, manual hours or adjustments
**                3. Freight   : any freight entry
**                4. Charges   : any charge entry
**                5. Tools     : any tool check-out / check-in
**
**              Deleted tasks are removed together with their PLANNED (non-transactional) children:
**              planned materials / kit materials, planned labor, planned tools, instructions.
**              Kept tasks are resequenced.
**
** Parameters:  @ValidateOnly = 1 -> only validate, never delete (used by the UI before asking to confirm).
**                                   Runs without a transaction so it holds no locks.
**
** Result sets: 1) Status : IsDeleted, TaskCount, DeletableCount, KeptCount, IsBlocked, Message
**              2) Kept tasks : WorkOrderTaskId, SequenceNumber, TaskName, Reasons
** Date:   10/14/2026
**************************************************************
** Change History
**************************************************************
** PR   Date         Author				Change Description
** --   --------     -------			----------------------
	1   10/14/2026   Bhargav Saliya		Created - Delete All Tasks on Dynamic Work Order

EXEC [USP_DeleteAllWorkOrderTasks] 10730, 10959, 'ADMIN', 1
**************************************************************/
CREATE   PROCEDURE [dbo].[USP_DeleteAllWorkOrderTasks]
	@WorkOrderId BIGINT,
	@WorkOrderPartNumberId BIGINT,
	@UpdatedBy VARCHAR(100),
	@ValidateOnly BIT = 0
AS
BEGIN
	SET NOCOUNT ON;
	SET XACT_ABORT ON;

	DECLARE @Message VARCHAR(500) = '';
	DECLARE @TaskCount INT = 0;
	DECLARE @IsDeleted BIT = 0;
	DECLARE @IsBlocked BIT = 0;
	DECLARE @OwnTran BIT = 0;
	DECLARE @DeletableCount INT = 0;
	DECLARE @KeptCount INT = 0;

	DECLARE @Tasks TABLE (WorkOrderTaskId BIGINT PRIMARY KEY, SequenceNumber VARCHAR(50) NULL, TaskName VARCHAR(500) NULL, MasterCompanyId INT NULL);
	DECLARE @Blockers TABLE (WorkOrderTaskId BIGINT, Reason VARCHAR(200));
	DECLARE @Result TABLE (WorkOrderTaskId BIGINT, SequenceNumber VARCHAR(50), TaskName VARCHAR(500), Reasons VARCHAR(MAX));
	/* Child rows of the tasks, INCLUDING soft-deleted ones (their history still blocks); IsDeleted = 0 rows get removed */
	DECLARE @Materials TABLE (WorkOrderMaterialsId BIGINT PRIMARY KEY, TaskId BIGINT, IsDeleted BIT);
	DECLARE @KitMaterials TABLE (WorkOrderMaterialsKitId BIGINT PRIMARY KEY, TaskId BIGINT, WorkOrderMaterialsKitMappingId BIGINT NULL, IsDeleted BIT);
	DECLARE @LaborHeaders TABLE (WorkOrderLaborHeaderId BIGINT PRIMARY KEY);
	DECLARE @Labor TABLE (WorkOrderLaborId BIGINT PRIMARY KEY, TaskId BIGINT, IsDeleted BIT);
	DECLARE @Assets TABLE (WorkOrderAssetId BIGINT PRIMARY KEY, TaskId BIGINT, IsDeleted BIT);

	BEGIN TRY
		/* Validate-only takes no locks; the real delete re-validates everything inside its transaction */
		IF @ValidateOnly = 0
		BEGIN
			BEGIN TRANSACTION;
			SET @OwnTran = 1;
		END

		/* Only Dynamic Work Orders (WorkOrderFormTypeId = 1) use WorkOrderTask */
		IF NOT EXISTS (SELECT 1 FROM [dbo].[WorkOrder] WITH(NOLOCK) WHERE [WorkOrderId] = @WorkOrderId AND ISNULL([WorkOrderFormTypeId], 0) = 1)
		BEGIN
			SET @Message = 'Delete All Tasks is allowed only for a Dynamic Work Order.';
			SET @IsBlocked = 1;
		END
		ELSE IF NOT EXISTS (SELECT 1 FROM [dbo].[WorkOrderPartNumber] WITH(NOLOCK) WHERE [ID] = @WorkOrderPartNumberId AND [WorkOrderId] = @WorkOrderId)
		BEGIN
			SET @Message = 'Work Order part number not found on this Work Order.';
			SET @IsBlocked = 1;
		END
		ELSE IF EXISTS (SELECT 1 FROM [dbo].[WorkOrderPartNumber] WITH(NOLOCK) WHERE [ID] = @WorkOrderPartNumberId AND ISNULL([IsClosed], 0) = 1)
		BEGIN
			SET @Message = 'Tasks cannot be deleted because the Work Order part number is closed.';
			SET @IsBlocked = 1;
		END

		IF @IsBlocked = 0
		BEGIN
			/* Delete mode: U-lock the task rows (seek on IX_WorkOrderTask_WorkOrderId_PartNumber) so two users cannot both run it */
			IF @ValidateOnly = 0
				INSERT INTO @Tasks (WorkOrderTaskId, SequenceNumber, TaskName, MasterCompanyId)
				SELECT WOT.[WorkOrderTaskId], WOT.[SequenceNumber], WOT.[TaskName], WOT.[MasterCompanyId]
				FROM [dbo].[WorkOrderTask] WOT WITH (UPDLOCK)
				WHERE WOT.[WorkOrderId] = @WorkOrderId AND WOT.[WorkOrderPartNumberId] = @WorkOrderPartNumberId AND WOT.[IsDeleted] = 0;
			ELSE
				INSERT INTO @Tasks (WorkOrderTaskId, SequenceNumber, TaskName, MasterCompanyId)
				SELECT WOT.[WorkOrderTaskId], WOT.[SequenceNumber], WOT.[TaskName], WOT.[MasterCompanyId]
				FROM [dbo].[WorkOrderTask] WOT WITH (NOLOCK)
				WHERE WOT.[WorkOrderId] = @WorkOrderId AND WOT.[WorkOrderPartNumberId] = @WorkOrderPartNumberId AND WOT.[IsDeleted] = 0;

			SET @TaskCount = (SELECT COUNT(1) FROM @Tasks);

			IF @TaskCount = 0
			BEGIN
				SET @Message = 'There are no tasks to delete.';
				SET @IsBlocked = 1;
			END
		END

		IF @IsBlocked = 0
		BEGIN
			/* On a Dynamic WO the child TaskId columns hold WorkOrderTask.WorkOrderTaskId.
			   Always also filter on WorkOrderId: on Static WOs TaskId is the master Task id and could collide. */
			INSERT INTO @Materials (WorkOrderMaterialsId, TaskId, IsDeleted)
			SELECT WOM.[WorkOrderMaterialsId], WOM.[TaskId], ISNULL(WOM.[IsDeleted], 0)
			FROM [dbo].[WorkOrderMaterials] WOM WITH (NOLOCK)
			INNER JOIN @Tasks T ON T.WorkOrderTaskId = WOM.[TaskId]
			WHERE WOM.[WorkOrderId] = @WorkOrderId;

			INSERT INTO @KitMaterials (WorkOrderMaterialsKitId, TaskId, WorkOrderMaterialsKitMappingId, IsDeleted)
			SELECT WOMK.[WorkOrderMaterialsKitId], WOMK.[TaskId], WOMK.[WorkOrderMaterialsKitMappingId], ISNULL(WOMK.[IsDeleted], 0)
			FROM [dbo].[WorkOrderMaterialsKit] WOMK WITH (NOLOCK)
			INNER JOIN @Tasks T ON T.WorkOrderTaskId = WOMK.[TaskId]
			WHERE WOMK.[WorkOrderId] = @WorkOrderId;

			INSERT INTO @LaborHeaders (WorkOrderLaborHeaderId)
			SELECT WOLH.[WorkOrderLaborHeaderId] FROM [dbo].[WorkOrderLaborHeader] WOLH WITH (NOLOCK) WHERE WOLH.[WorkOrderId] = @WorkOrderId;

			INSERT INTO @Labor (WorkOrderLaborId, TaskId, IsDeleted)
			SELECT WOL.[WorkOrderLaborId], WOL.[TaskId], ISNULL(WOL.[IsDeleted], 0)
			FROM [dbo].[WorkOrderLabor] WOL WITH (NOLOCK)
			INNER JOIN @LaborHeaders H ON H.WorkOrderLaborHeaderId = WOL.[WorkOrderLaborHeaderId]
			INNER JOIN @Tasks T ON T.WorkOrderTaskId = WOL.[TaskId];

			INSERT INTO @Assets (WorkOrderAssetId, TaskId, IsDeleted)
			SELECT WOA.[WorkOrderAssetId], WOA.[TaskId], ISNULL(WOA.[IsDeleted], 0)
			FROM [dbo].[WorkOrderAssets] WOA WITH (NOLOCK)
			INNER JOIN @Tasks T ON T.WorkOrderTaskId = WOA.[TaskId]
			WHERE WOA.[WorkOrderId] = @WorkOrderId;

			/* ---------- 1. Materials ----------
			   Only what is reserved / issued RIGHT NOW blocks. Reserve/issue history of a material that was later
			   unreserved / returned does not block (it is cleaned up in the delete section, like USP_DeleteWorkOrderMaterials). */
			INSERT INTO @Blockers (WorkOrderTaskId, Reason)
			SELECT M.TaskId, 'Materials reserved/issued'
			FROM @Materials M
			INNER JOIN [dbo].[WorkOrderMaterials] WOM WITH (NOLOCK) ON WOM.[WorkOrderMaterialsId] = M.WorkOrderMaterialsId
			WHERE ISNULL(WOM.[QuantityReserved], 0) > 0 OR ISNULL(WOM.[QuantityIssued], 0) > 0
			   OR ISNULL(WOM.[TotalReserved], 0) > 0 OR ISNULL(WOM.[TotalIssued], 0) > 0
			   OR EXISTS (SELECT 1 FROM [dbo].[WorkOrderMaterialStockLine] WOMS WITH (NOLOCK)
						  WHERE WOMS.[WorkOrderMaterialsId] = M.WorkOrderMaterialsId
						    AND (ISNULL(WOMS.[QtyReserved], 0) > 0 OR ISNULL(WOMS.[QtyIssued], 0) > 0));

			INSERT INTO @Blockers (WorkOrderTaskId, Reason)
			SELECT M.TaskId, 'Materials linked to PO/RO/Sub WO/received stock'
			FROM @Materials M
			INNER JOIN [dbo].[WorkOrderMaterials] WOM WITH (NOLOCK) ON WOM.[WorkOrderMaterialsId] = M.WorkOrderMaterialsId
			WHERE ISNULL(WOM.[POId], 0) > 0 OR ISNULL(WOM.[QtyOnOrder], 0) > 0
			   OR EXISTS (SELECT 1 FROM [dbo].[WorkOrderMaterialStockLine] WOMS WITH (NOLOCK)
						  WHERE WOMS.[WorkOrderMaterialsId] = M.WorkOrderMaterialsId AND ISNULL(WOMS.[RepairOrderId], 0) > 0)
			   OR EXISTS (SELECT 1 FROM [dbo].[PurchaseOrderPart] X WITH (NOLOCK) WHERE X.[WorkOrderMaterialsId] = M.WorkOrderMaterialsId AND ISNULL(X.[IsKit], 0) = 0 AND ISNULL(X.[IsSubWO], 0) = 0)
			   OR EXISTS (SELECT 1 FROM [dbo].[RepairOrderPart] X WITH (NOLOCK) WHERE X.[WorkOrderMaterialsId] = M.WorkOrderMaterialsId AND ISNULL(X.[IsKitType], 0) = 0)
			   OR EXISTS (SELECT 1 FROM [dbo].[WorkOrederMaterialsROHistory] X WITH (NOLOCK) WHERE X.[WorkOrderMaterialsId] = M.WorkOrderMaterialsId)
			   OR EXISTS (SELECT 1 FROM [dbo].[SubWorkOrder] X WITH (NOLOCK) WHERE X.[WorkOrderMaterialsId] = M.WorkOrderMaterialsId)
			   OR EXISTS (SELECT 1 FROM [dbo].[SubWorkOrderMaterialMapping] X WITH (NOLOCK) WHERE X.[WorkOrderMaterialsId] = M.WorkOrderMaterialsId)
			   OR EXISTS (SELECT 1 FROM [dbo].[Stockline] X WITH (NOLOCK) WHERE X.[WorkOrderMaterialsId] = M.WorkOrderMaterialsId)
			   OR EXISTS (SELECT 1 FROM [dbo].[StocklineDraft] X WITH (NOLOCK) WHERE X.[WorkOrderMaterialsId] = M.WorkOrderMaterialsId AND ISNULL(X.[IsKitType], 0) = 0)
			   OR EXISTS (SELECT 1 FROM [dbo].[ChildStockline] X WITH (NOLOCK) WHERE X.[WorkOrderMaterialsId] = M.WorkOrderMaterialsId);

			INSERT INTO @Blockers (WorkOrderTaskId, Reason)
			SELECT K.TaskId, 'Kit materials reserved/issued'
			FROM @KitMaterials K
			INNER JOIN [dbo].[WorkOrderMaterialsKit] WOMK WITH (NOLOCK) ON WOMK.[WorkOrderMaterialsKitId] = K.WorkOrderMaterialsKitId
			WHERE ISNULL(WOMK.[QuantityReserved], 0) > 0 OR ISNULL(WOMK.[QuantityIssued], 0) > 0
			   OR ISNULL(WOMK.[TotalReserved], 0) > 0 OR ISNULL(WOMK.[TotalIssued], 0) > 0
			   OR EXISTS (SELECT 1 FROM [dbo].[WorkOrderMaterialStockLineKit] WOMSK WITH (NOLOCK)
						  WHERE WOMSK.[WorkOrderMaterialsKitId] = K.WorkOrderMaterialsKitId
						    AND (ISNULL(WOMSK.[QtyReserved], 0) > 0 OR ISNULL(WOMSK.[QtyIssued], 0) > 0));

			INSERT INTO @Blockers (WorkOrderTaskId, Reason)
			SELECT K.TaskId, 'Kit materials linked to PO/RO/received stock'
			FROM @KitMaterials K
			INNER JOIN [dbo].[WorkOrderMaterialsKit] WOMK WITH (NOLOCK) ON WOMK.[WorkOrderMaterialsKitId] = K.WorkOrderMaterialsKitId
			WHERE ISNULL(WOMK.[POId], 0) > 0 OR ISNULL(WOMK.[QtyOnOrder], 0) > 0
			   OR EXISTS (SELECT 1 FROM [dbo].[WorkOrderMaterialStockLineKit] WOMSK WITH (NOLOCK)
						  WHERE WOMSK.[WorkOrderMaterialsKitId] = K.WorkOrderMaterialsKitId AND ISNULL(WOMSK.[RepairOrderId], 0) > 0)
			   OR EXISTS (SELECT 1 FROM [dbo].[PurchaseOrderPart] X WITH (NOLOCK) WHERE X.[WorkOrderMaterialsId] = K.WorkOrderMaterialsKitId AND ISNULL(X.[IsKit], 0) = 1 AND ISNULL(X.[IsSubWO], 0) = 0)
			   OR EXISTS (SELECT 1 FROM [dbo].[RepairOrderPart] X WITH (NOLOCK) WHERE X.[WorkOrderMaterialsId] = K.WorkOrderMaterialsKitId AND ISNULL(X.[IsKitType], 0) = 1)
			   OR EXISTS (SELECT 1 FROM [dbo].[Stockline] X WITH (NOLOCK) WHERE X.[WorkOrderMaterialsKitId] = K.WorkOrderMaterialsKitId)
			   OR EXISTS (SELECT 1 FROM [dbo].[StocklineDraft] X WITH (NOLOCK) WHERE X.[WorkOrderMaterialsId] = K.WorkOrderMaterialsKitId AND ISNULL(X.[IsKitType], 0) = 1)
			   OR EXISTS (SELECT 1 FROM [dbo].[ChildStockline] X WITH (NOLOCK) WHERE X.[WorkOrderMaterialsKitId] = K.WorkOrderMaterialsKitId);

			/* ---------- 2. Labor ---------- */
			INSERT INTO @Blockers (WorkOrderTaskId, Reason)
			SELECT L.TaskId, 'Labor started/completed'
			FROM @Labor L
			INNER JOIN [dbo].[WorkOrderLabor] WOL WITH (NOLOCK) ON WOL.[WorkOrderLaborId] = L.WorkOrderLaborId
			LEFT JOIN  [dbo].[TaskStatus] TS WITH (NOLOCK) ON TS.[TaskStatusId] = WOL.[TaskStatusId]
			WHERE L.IsDeleted = 0
			  AND (ISNULL(WOL.[IsBegin], 0) = 1
			   OR WOL.[StartDate] IS NOT NULL
			   OR UPPER(ISNULL(TS.[StatusCode], '')) = 'COMPLETED'
			   OR UPPER(LTRIM(RTRIM(ISNULL(TS.[Description], '')))) IN ('COMPLETED', 'IN-PROCESS')
			   /* Workflow lines are created with estimated Hours, so only manual lines count Hours as time entered */
			   OR (ISNULL(WOL.[IsFromWorkFlow], 0) = 0 AND (ISNULL(WOL.[Hours], 0) <> 0 OR ISNULL(WOL.[AdjustedHours], 0) <> 0))
			   OR (WOL.[AdjustedHours] IS NOT NULL AND WOL.[AdjustedHours] <> ISNULL(WOL.[Hours], 0))
			   OR ISNULL(WOL.[Adjustments], 0) <> 0);

			/* Any clock-in / time entry, even on a deleted labor line or a deleted entry, is history */
			INSERT INTO @Blockers (WorkOrderTaskId, Reason)
			SELECT DISTINCT L.TaskId, 'Labor time entries/clock-ins'
			FROM @Labor L
			WHERE EXISTS (SELECT 1 FROM [dbo].[WorkOrderLaborTracking] WOLT WITH (NOLOCK) WHERE WOLT.[WorkOrderLaborId] = L.WorkOrderLaborId);

			/* ---------- 3. Freight ---------- */
			INSERT INTO @Blockers (WorkOrderTaskId, Reason)
			SELECT DISTINCT WOF.[TaskId], 'Freight'
			FROM [dbo].[WorkOrderFreight] WOF WITH (NOLOCK)
			INNER JOIN @Tasks T ON T.WorkOrderTaskId = WOF.[TaskId]
			WHERE WOF.[WorkOrderId] = @WorkOrderId AND WOF.[IsDeleted] = 0;

			/* ---------- 4. Charges ---------- */
			INSERT INTO @Blockers (WorkOrderTaskId, Reason)
			SELECT DISTINCT WOC.[TaskId], 'Charges'
			FROM [dbo].[WorkOrderCharges] WOC WITH (NOLOCK)
			INNER JOIN @Tasks T ON T.WorkOrderTaskId = WOC.[TaskId]
			WHERE WOC.[WorkOrderId] = @WorkOrderId AND WOC.[IsDeleted] = 0;

			/* ---------- 5. Tools ---------- (any check-out/check-in, even on a deleted tool line, is history) */
			INSERT INTO @Blockers (WorkOrderTaskId, Reason)
			SELECT DISTINCT A.TaskId, 'Tools checked out/in'
			FROM @Assets A
			WHERE EXISTS (SELECT 1 FROM [dbo].[CheckInCheckOutWorkOrderAsset] CICO WITH (NOLOCK) WHERE CICO.[WorkOrderAssetId] = A.WorkOrderAssetId);

			/* Tasks with transaction data are KEPT (listed back with their reasons); only the clean tasks are deleted */
			INSERT INTO @Result (WorkOrderTaskId, SequenceNumber, TaskName, Reasons)
			SELECT T.WorkOrderTaskId, T.SequenceNumber, T.TaskName,
				   STRING_AGG(B.Reason, ', ') WITHIN GROUP (ORDER BY B.Reason)
			FROM @Tasks T
			INNER JOIN (SELECT DISTINCT WorkOrderTaskId, Reason FROM @Blockers) B ON B.WorkOrderTaskId = T.WorkOrderTaskId
			GROUP BY T.WorkOrderTaskId, T.SequenceNumber, T.TaskName;

			SET @KeptCount = (SELECT COUNT(1) FROM @Result);
			SET @DeletableCount = @TaskCount - @KeptCount;

			IF @DeletableCount = 0
			BEGIN
				SET @IsBlocked = 1;
				SET @Message = 'Delete All Tasks is not allowed because transaction data exists on all '
							 + CAST(@TaskCount AS VARCHAR(10)) + ' task(s). No tasks were deleted.';
			END
			ELSE
			BEGIN
				/* Narrow every working set to the deletable tasks, so the delete section below never touches a kept task */
				DELETE FROM @Tasks        WHERE WorkOrderTaskId IN (SELECT WorkOrderTaskId FROM @Result);
				DELETE FROM @Materials    WHERE TaskId IN (SELECT WorkOrderTaskId FROM @Result);
				DELETE FROM @KitMaterials WHERE TaskId IN (SELECT WorkOrderTaskId FROM @Result);
				DELETE FROM @Labor        WHERE TaskId IN (SELECT WorkOrderTaskId FROM @Result);
				DELETE FROM @Assets       WHERE TaskId IN (SELECT WorkOrderTaskId FROM @Result);

				IF @ValidateOnly = 1
					SET @Message = CASE WHEN @KeptCount = 0
										THEN 'All ' + CAST(@TaskCount AS VARCHAR(10)) + ' task(s) can be deleted.'
										ELSE CAST(@DeletableCount AS VARCHAR(10)) + ' of ' + CAST(@TaskCount AS VARCHAR(10))
											 + ' task(s) can be deleted. ' + CAST(@KeptCount AS VARCHAR(10))
											 + ' task(s) with transaction data will be kept.' END;
			END
		END

		IF @IsBlocked = 0 AND @ValidateOnly = 0
		BEGIN
			/* ---------- Planned materials (nothing reserved/issued/linked - verified above) ---------- */

			/* Re-check the current qty under an update lock: a reserve/issue that committed after the checks above
			   must not be wiped together with its history below. The lock also holds off a reserve that starts now. */
			IF EXISTS (SELECT 1 FROM [dbo].[WorkOrderMaterials] WOM WITH (UPDLOCK)
					   INNER JOIN @Materials M ON M.WorkOrderMaterialsId = WOM.[WorkOrderMaterialsId]
					   WHERE M.IsDeleted = 0
						 AND (ISNULL(WOM.[QuantityReserved], 0) > 0 OR ISNULL(WOM.[QuantityIssued], 0) > 0
						   OR ISNULL(WOM.[TotalReserved], 0) > 0 OR ISNULL(WOM.[TotalIssued], 0) > 0))
			OR EXISTS (SELECT 1 FROM [dbo].[WorkOrderMaterialStockLine] WOMS WITH (UPDLOCK)
					   INNER JOIN @Materials M ON M.WorkOrderMaterialsId = WOMS.[WorkOrderMaterialsId]
					   WHERE M.IsDeleted = 0 AND (ISNULL(WOMS.[QtyReserved], 0) > 0 OR ISNULL(WOMS.[QtyIssued], 0) > 0))
			OR EXISTS (SELECT 1 FROM [dbo].[WorkOrderMaterialsKit] WOMK WITH (UPDLOCK)
					   INNER JOIN @KitMaterials K ON K.WorkOrderMaterialsKitId = WOMK.[WorkOrderMaterialsKitId]
					   WHERE K.IsDeleted = 0
						 AND (ISNULL(WOMK.[QuantityReserved], 0) > 0 OR ISNULL(WOMK.[QuantityIssued], 0) > 0
						   OR ISNULL(WOMK.[TotalReserved], 0) > 0 OR ISNULL(WOMK.[TotalIssued], 0) > 0))
			BEGIN
				ROLLBACK TRANSACTION;
				SET @OwnTran = 0;
				SET @IsBlocked = 1;
				SET @IsDeleted = 0;
				SET @Message = 'Task data was changed by another user while deleting. No tasks were deleted, please try again.';
				GOTO ReturnResult;
			END

			/* Old reserve/issue history of these planned materials (FK children of WorkOrderMaterials) -
			   removed the same way USP_DeleteWorkOrderMaterials does before deleting a material */
			DELETE X FROM [dbo].[WorkOrderIssuedStock]      X INNER JOIN @Materials M ON M.WorkOrderMaterialsId = X.[WorkOrderMaterialsId] WHERE M.IsDeleted = 0;
			DELETE X FROM [dbo].[WorkOrderUnIssuedStock]    X INNER JOIN @Materials M ON M.WorkOrderMaterialsId = X.[WorkOrderMaterialsId] WHERE M.IsDeleted = 0;
			DELETE X FROM [dbo].[WorkOrderReservedStock]    X INNER JOIN @Materials M ON M.WorkOrderMaterialsId = X.[WorkOrderMaterialsId] WHERE M.IsDeleted = 0;
			DELETE X FROM [dbo].[WorkOrderUnReservedStock]  X INNER JOIN @Materials M ON M.WorkOrderMaterialsId = X.[WorkOrderMaterialsId] WHERE M.IsDeleted = 0;
			DELETE X FROM [dbo].[WorkOrderStockLineReserve] X INNER JOIN @Materials M ON M.WorkOrderMaterialsId = X.[WorkOrderMaterialsId] WHERE M.IsDeleted = 0;

			DELETE WOMS FROM [dbo].[WorkOrderMaterialStockLine] WOMS INNER JOIN @Materials M ON M.WorkOrderMaterialsId = WOMS.[WorkOrderMaterialsId] WHERE M.IsDeleted = 0;
			DELETE WOM  FROM [dbo].[WorkOrderMaterials] WOM INNER JOIN @Materials M ON M.WorkOrderMaterialsId = WOM.[WorkOrderMaterialsId] WHERE M.IsDeleted = 0;

			DELETE WOMSK FROM [dbo].[WorkOrderMaterialStockLineKit] WOMSK INNER JOIN @KitMaterials K ON K.WorkOrderMaterialsKitId = WOMSK.[WorkOrderMaterialsKitId] WHERE K.IsDeleted = 0;
			DELETE WOMK  FROM [dbo].[WorkOrderMaterialsKit] WOMK INNER JOIN @KitMaterials K ON K.WorkOrderMaterialsKitId = WOMK.[WorkOrderMaterialsKitId] WHERE K.IsDeleted = 0;

			/* Drop kit mappings of this part number left without any kit item */
			DELETE KM FROM [dbo].[WorkOrderMaterialsKitMapping] KM
			WHERE KM.[WorkOrderMaterialsKitMappingId] IN (SELECT DISTINCT WorkOrderMaterialsKitMappingId FROM @KitMaterials WHERE IsDeleted = 0 AND WorkOrderMaterialsKitMappingId IS NOT NULL)
			  AND KM.[WOPartNoId] = @WorkOrderPartNumberId
			  AND NOT EXISTS (SELECT 1 FROM [dbo].[WorkOrderMaterialsKit] WOMK WHERE WOMK.[WorkOrderMaterialsKitMappingId] = KM.[WorkOrderMaterialsKitMappingId]);

			/* ---------- Planned labor / tools (soft delete, same as the single-row deletes) ---------- */
			UPDATE WOL SET WOL.[IsDeleted] = 1, WOL.[UpdatedBy] = @UpdatedBy, WOL.[UpdatedDate] = GETUTCDATE()
			FROM [dbo].[WorkOrderLabor] WOL INNER JOIN @Labor L ON L.WorkOrderLaborId = WOL.[WorkOrderLaborId] WHERE L.IsDeleted = 0;

			UPDATE WOA SET WOA.[IsDeleted] = 1, WOA.[UpdatedBy] = @UpdatedBy, WOA.[UpdatedDate] = GETUTCDATE()
			FROM [dbo].[WorkOrderAssets] WOA INNER JOIN @Assets A ON A.WorkOrderAssetId = WOA.[WorkOrderAssetId] WHERE A.IsDeleted = 0;

			/* ---------- Instructions / attributes ---------- */
			DELETE WOTII FROM [dbo].[WorkOrderTaskInstructionImage] WOTII
			INNER JOIN [dbo].[WorkOrderTaskInstruction] WOTI ON WOTI.[WorkOrderTaskInstructionId] = WOTII.[WorkOrderTaskInstructionId]
			INNER JOIN @Tasks T ON T.WorkOrderTaskId = WOTI.[WorkOrderTaskId];
			DELETE WOTI  FROM [dbo].[WorkOrderTaskInstruction] WOTI INNER JOIN @Tasks T ON T.WorkOrderTaskId = WOTI.[WorkOrderTaskId];
			DELETE WOTA  FROM [dbo].[WorkOrderTaskAttribute] WOTA INNER JOIN @Tasks T ON T.WorkOrderTaskId = WOTA.[WorkOrderTaskId];

			/* ---------- Tasks (same as DeleteWorkOrderTask) ---------- */
			DELETE WOTD FROM [dbo].[WorkOrderTaskDetails] WOTD INNER JOIN @Tasks T ON T.WorkOrderTaskId = WOTD.[WorkOrderTaskId];
			DELETE WOT  FROM [dbo].[WorkOrderTask] WOT INNER JOIN @Tasks T ON T.WorkOrderTaskId = WOT.[WorkOrderTaskId];

			/* ---------- Safety net: a row added to one of these tasks while we were validating would now be
			   orphaned (or is new transaction data). Roll everything back and let the user retry. ---------- */
			IF EXISTS (SELECT 1 FROM [dbo].[WorkOrderMaterials] X WITH (NOLOCK) INNER JOIN @Tasks T ON T.WorkOrderTaskId = X.[TaskId] WHERE X.[WorkOrderId] = @WorkOrderId AND X.[IsDeleted] = 0)
			OR EXISTS (SELECT 1 FROM [dbo].[WorkOrderMaterialsKit] X WITH (NOLOCK) INNER JOIN @Tasks T ON T.WorkOrderTaskId = X.[TaskId] WHERE X.[WorkOrderId] = @WorkOrderId AND X.[IsDeleted] = 0)
			OR EXISTS (SELECT 1 FROM [dbo].[WorkOrderLabor] X WITH (NOLOCK) INNER JOIN @LaborHeaders H ON H.WorkOrderLaborHeaderId = X.[WorkOrderLaborHeaderId] INNER JOIN @Tasks T ON T.WorkOrderTaskId = X.[TaskId] WHERE X.[IsDeleted] = 0)
			OR EXISTS (SELECT 1 FROM [dbo].[WorkOrderLaborTracking] X WITH (NOLOCK) INNER JOIN [dbo].[WorkOrderLabor] L WITH (NOLOCK) ON L.[WorkOrderLaborId] = X.[WorkOrderLaborId] INNER JOIN @LaborHeaders H ON H.WorkOrderLaborHeaderId = L.[WorkOrderLaborHeaderId] INNER JOIN @Tasks T ON T.WorkOrderTaskId = L.[TaskId])
			OR EXISTS (SELECT 1 FROM [dbo].[WorkOrderAssets] X WITH (NOLOCK) INNER JOIN @Tasks T ON T.WorkOrderTaskId = X.[TaskId] WHERE X.[WorkOrderId] = @WorkOrderId AND X.[IsDeleted] = 0)
			OR EXISTS (SELECT 1 FROM [dbo].[WorkOrderFreight] X WITH (NOLOCK) INNER JOIN @Tasks T ON T.WorkOrderTaskId = X.[TaskId] WHERE X.[WorkOrderId] = @WorkOrderId AND X.[IsDeleted] = 0)
			OR EXISTS (SELECT 1 FROM [dbo].[WorkOrderCharges] X WITH (NOLOCK) INNER JOIN @Tasks T ON T.WorkOrderTaskId = X.[TaskId] WHERE X.[WorkOrderId] = @WorkOrderId AND X.[IsDeleted] = 0)
			OR EXISTS (SELECT 1 FROM [dbo].[WorkOrderTaskInstruction] X WITH (NOLOCK) INNER JOIN @Tasks T ON T.WorkOrderTaskId = X.[WorkOrderTaskId])
			BEGIN
				ROLLBACK TRANSACTION;
				SET @OwnTran = 0;
				SET @IsBlocked = 1;
				SET @Message = 'Task data was changed by another user while deleting. No tasks were deleted, please try again.';
			END
			ELSE
			BEGIN
				/* ---------- History: one 'task removed' entry per task ---------- */
				DECLARE @ModuleId INT, @SubModuleId INT, @StatusCode VARCHAR(100) = 'DeleteWorkOrderTask', @TemplateBody VARCHAR(MAX), @HistoryText VARCHAR(MAX);
				DECLARE @TaskName VARCHAR(500), @MasterCompanyId INT;

				SELECT @ModuleId = [ModuleId] FROM [dbo].[Module] WITH(NOLOCK) WHERE [ModuleId] = 15;
				SELECT @SubModuleId = [ModuleId] FROM [dbo].[Module] WITH(NOLOCK) WHERE [ModuleName] = 'WorkOrderTask';
				SELECT @TemplateBody = [TemplateBody] FROM [dbo].[HistoryTemplate] WITH(NOLOCK) WHERE [TemplateCode] = @StatusCode;

				DECLARE curTask CURSOR LOCAL FAST_FORWARD FOR
					SELECT TaskName, MasterCompanyId FROM @Tasks ORDER BY TRY_CAST(SequenceNumber AS DECIMAL(10, 4));
				OPEN curTask;
				FETCH NEXT FROM curTask INTO @TaskName, @MasterCompanyId;
				WHILE @@FETCH_STATUS = 0
				BEGIN
					SET @HistoryText = REPLACE(ISNULL(@TemplateBody, ''), '##TaskName##', ISNULL(@TaskName, ''));
					EXEC [dbo].[USP_History] @ModuleId, @WorkOrderId, @SubModuleId, @WorkOrderPartNumberId, @TaskName, '', @HistoryText, @StatusCode, @MasterCompanyId, @UpdatedBy, NULL, @UpdatedBy, NULL;
					FETCH NEXT FROM curTask INTO @TaskName, @MasterCompanyId;
				END
				CLOSE curTask;
				DEALLOCATE curTask;

				/* ---------- Resequence the kept tasks of this part number (same as DeleteWorkOrderTask) ---------- */
				IF @KeptCount > 0
				BEGIN
					DECLARE @TempSequence TABLE (WorkOrderTaskId BIGINT, SequenceNumber INT);

					INSERT INTO @TempSequence (WorkOrderTaskId, SequenceNumber)
					SELECT WOT.[WorkOrderTaskId], ROW_NUMBER() OVER (ORDER BY TRY_CAST(WOT.[SequenceNumber] AS DECIMAL(10, 4)), WOT.[WorkOrderTaskId])
					FROM [dbo].[WorkOrderTask] WOT
					WHERE WOT.[WorkOrderId] = @WorkOrderId AND WOT.[WorkOrderPartNumberId] = @WorkOrderPartNumberId AND WOT.[IsDeleted] = 0;

					/* Only rows whose number actually changes */
					DELETE TS FROM @TempSequence TS
					INNER JOIN [dbo].[WorkOrderTask] WOT ON WOT.[WorkOrderTaskId] = TS.WorkOrderTaskId
					WHERE TRY_CAST(WOT.[SequenceNumber] AS DECIMAL(10, 4)) = TS.SequenceNumber;

					UPDATE WOT SET WOT.[SequenceNumber] = TS.SequenceNumber
					FROM [dbo].[WorkOrderTask] WOT
					INNER JOIN @TempSequence TS ON TS.WorkOrderTaskId = WOT.[WorkOrderTaskId];

					/* USP_AddWorkOrderTaskHistory SELECTs the new history id - swallow it so the client only gets our 2 result sets */
					DECLARE @HistorySink TABLE (WorkOrderTaskHistoryId NUMERIC(38, 0) NULL);
					DECLARE @WOTID BIGINT, @SeqNum INT;
					DECLARE curSeq CURSOR LOCAL FAST_FORWARD FOR SELECT WorkOrderTaskId, SequenceNumber FROM @TempSequence;
					OPEN curSeq;
					FETCH NEXT FROM curSeq INTO @WOTID, @SeqNum;
					WHILE @@FETCH_STATUS = 0
					BEGIN
						INSERT INTO @HistorySink (WorkOrderTaskHistoryId)
						EXEC [dbo].[USP_AddWorkOrderTaskHistory] @WOTID, @UpdatedBy, 0, @SeqNum;
						FETCH NEXT FROM curSeq INTO @WOTID, @SeqNum;
					END
					CLOSE curSeq;
					DEALLOCATE curSeq;
				END

				SET @IsDeleted = 1;
				SET @Message = CAST(@DeletableCount AS VARCHAR(10)) + ' task(s) deleted successfully.'
							 + CASE WHEN @KeptCount > 0 THEN ' ' + CAST(@KeptCount AS VARCHAR(10)) + ' task(s) with transaction data were kept.' ELSE '' END;
			END
		END

ReturnResult:
		IF @OwnTran = 1
			COMMIT TRANSACTION;

		/* Results are returned only after the commit, so the client never sees "deleted" for a rolled-back run */
		/* 1) Status */
		SELECT @IsDeleted AS IsDeleted, @TaskCount AS TaskCount, @DeletableCount AS DeletableCount, @KeptCount AS KeptCount, @IsBlocked AS IsBlocked, @Message AS [Message];

		/* 2) Blocked tasks with their reasons */
		SELECT WorkOrderTaskId, SequenceNumber, TaskName, Reasons
		FROM @Result
		ORDER BY TRY_CAST(SequenceNumber AS DECIMAL(10, 4));
	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT > 0
			ROLLBACK TRANSACTION;

		DECLARE @ErrorLogID INT, @DatabaseName VARCHAR(100) = db_name()
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
			  , @AdhocComments     VARCHAR(150)    = 'USP_DeleteAllWorkOrderTasks'
			  , @ProcedureParameters VARCHAR(3000)  = '@WorkOrderId = ' + ISNULL(CAST(@WorkOrderId AS VARCHAR(20)), '')
													 + ', @WorkOrderPartNumberId = ' + ISNULL(CAST(@WorkOrderPartNumberId AS VARCHAR(20)), '')
													 + ', @UpdatedBy = ' + ISNULL(@UpdatedBy, '')
													 + ', @ValidateOnly = ' + ISNULL(CAST(@ValidateOnly AS VARCHAR(1)), '')
													 + ', Error = ' + LEFT(ISNULL(ERROR_MESSAGE(), ''), 2000) + ' (line ' + CAST(ISNULL(ERROR_LINE(), 0) AS VARCHAR(10)) + ')'
			  , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
		EXEC spLogException
				 @DatabaseName           = @DatabaseName
			   , @AdhocComments          = @AdhocComments
			   , @ProcedureParameters    = @ProcedureParameters
			   , @ApplicationName        = @ApplicationName
			   , @ErrorLogID             = @ErrorLogID OUTPUT;
		RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)
		RETURN(1);
	END CATCH
END
