/*************************************************************
 ** File:   [USP_ReconcilePiecePart]
 ** Author:   Abhishek Jirawla
 ** Description: Reconcile Piece Part
 ** Purpose:
 ** Date:   22/06/2026

 ** PARAMETERS:

 ** RETURN VALUE:

 **************************************************************
  ** Change History
 **************************************************************
  ** S NO   Date            Author				Change Description
  ** --   --------			-------				--------------------------------
     1    22/06/2026		Abhishek Jirawla	Created
 **************************************************************/
CREATE     PROCEDURE [dbo].[USP_ReconcilePiecePart]
    @RepairOrderPartRecordId    BIGINT,
    @SourceRepairOrderId        BIGINT,
    @ConsumedRepairOrderId      BIGINT          = NULL,   -- may differ from source RO
    @StockLineId                BIGINT,
    @QtyConsumed                INT             = 0,
    @QtyReturned                INT             = 0,
    @QtyDamagedLost             INT             = 0,
    @Memo                       NVARCHAR(500)   = NULL,
    @UpdatedBy                  NVARCHAR(256),
    @MasterCompanyId            INT,
    @ChargesTypeId              BIGINT          = NULL,   -- when provided + QtyConsumed > 0, adds cost to consumed RO
    @ParentRepairOrderPartId    BIGINT          = NULL    -- optional parent piece part link (child-split scenario)
AS
BEGIN
    SET NOCOUNT ON;

    IF ISNULL(@QtyConsumed, 0) = 0 AND ISNULL(@QtyReturned, 0) = 0 AND ISNULL(@QtyDamagedLost, 0) = 0
    BEGIN
        RAISERROR('At least one of QtyConsumed, QtyReturned, or QtyDamagedLost must be greater than zero.', 16, 1);
        RETURN;
    END

    IF ISNULL(@QtyConsumed, 0) > 0 AND @ConsumedRepairOrderId IS NULL
    BEGIN
        RAISERROR('ConsumedRepairOrderId is required when QtyConsumed > 0.', 16, 1);
        RETURN;
    END

    DECLARE @Now                    DATETIME        = GETUTCDATE();
    DECLARE @NewReconciliationId    BIGINT;

    -- Piece part details (populated in step 4 whenever QtyConsumed > 0)
    DECLARE @PartUnitCost           DECIMAL(18,4)   = 0;
    DECLARE @PartNumber             NVARCHAR(50);
    DECLARE @PartDesc               NVARCHAR(500);

    -- WO cost rollup (populated in step 4b, consumed in step 7)
    DECLARE @PiecePartCostPerUnit   DECIMAL(18,4)   = 0;
    DECLARE @StocklineCostDelta     DECIMAL(18,4)   = 0;   -- proportional delta applied to main stockline UnitCost
    DECLARE @MainStockLineId        BIGINT;
    DECLARE @MainPartQty            INT;
    DECLARE @WOId                   BIGINT;
    DECLARE @WFWOId                 BIGINT;
    DECLARE @WOMId                  BIGINT;

    -- SO cost rollup (populated in step 4b, consumed in step 8)
    DECLARE @SOId                   BIGINT;
    DECLARE @SOPartId               BIGINT;
    DECLARE @SOStocklineId          BIGINT;

    -- Stockline history
    DECLARE @HistoryModuleId          INT;
    DECLARE @HistoryActionId          INT;
    DECLARE @HistoryDamagedActionId   INT;
    DECLARE @HistoryUnreserveActionId INT;

    DECLARE @SourceRONumber         NVARCHAR(100);

    BEGIN TRANSACTION;
    BEGIN TRY

        SELECT @HistoryModuleId           = ModuleId FROM dbo.Module WITH (NOLOCK) WHERE ModuleId = 14; -- RepairOrder
        SELECT @HistoryActionId           = ActionId FROM dbo.StklineHistory_Action WITH (NOLOCK) WHERE [Type] = 'Issue';
        SELECT @HistoryDamagedActionId    = ActionId FROM dbo.StklineHistory_Action WITH (NOLOCK) WHERE [Type] = 'DamagedLost';
        SELECT @HistoryUnreserveActionId  = ActionId FROM dbo.StklineHistory_Action WITH (NOLOCK) WHERE [Type] = 'Unreserve';
        SELECT @SourceRONumber          = RepairOrderNumber FROM dbo.RepairOrder WITH (NOLOCK) WHERE RepairOrderId = @SourceRepairOrderId;

        /* ────────────────────────────────────────────────────────────────
           1. QTY CONSUMED
              - Reduce physical inventory (QuantityOnHand)
              - Track consumption (QuantityIssued)
              - Remove from available / release reservation
        ──────────────────────────────────────────────────────────────── */
        IF ISNULL(@QtyConsumed, 0) > 0
        BEGIN
            UPDATE dbo.StockLine
            SET
                QuantityOnHand    = CASE WHEN QuantityOnHand   - @QtyConsumed < 0 THEN 0
                                         ELSE QuantityOnHand   - @QtyConsumed END,
                QuantityReserved  = CASE WHEN QuantityReserved - @QtyConsumed < 0 THEN 0
                                         ELSE QuantityReserved - @QtyConsumed END,
                QuantityIssued    = ISNULL(QuantityIssued, 0) + @QtyConsumed,
                UpdatedBy         = @UpdatedBy,
                UpdatedDate       = @Now
            WHERE StockLineId     = @StockLineId;

            EXEC [dbo].[USP_AddUpdateStocklineHistory]
                @StocklineId     = @StockLineId,
                @ModuleId        = @HistoryModuleId,
                @ReferenceId     = @SourceRepairOrderId,
                @SubModuleId     = NULL,
                @SubRefferenceId = @RepairOrderPartRecordId,
                @ActionId        = @HistoryActionId,
                @Qty             = @QtyConsumed,
                @UpdatedBy       = @UpdatedBy;

            UPDATE dbo.RepairOrderPart
            SET
                QuantityBackOrdered = CASE WHEN QuantityBackOrdered - @QtyConsumed < 0 THEN 0
                                           ELSE QuantityBackOrdered - @QtyConsumed END,
                QuantityReserved    = CASE WHEN QuantityReserved    - @QtyConsumed < 0 THEN 0
                                           ELSE QuantityReserved    - @QtyConsumed END,
                UpdatedBy           = @UpdatedBy,
                UpdatedDate         = @Now
            WHERE RepairOrderPartRecordId = @RepairOrderPartRecordId;
        END

        /* ────────────────────────────────────────────────────────────────
           2. QTY RETURNED
              Stock was reserved for a consuming RO but never physically used.
              - QuantityOnHand unchanged (stock never left inventory)
              - Release reservation (QuantityReserved)
              - Add back to available (QuantityAvailable)
              - QuantityReceived unchanged (not a new vendor receipt)
        ──────────────────────────────────────────────────────────────── */
        IF ISNULL(@QtyReturned, 0) > 0
        BEGIN
            -- Stock was only reserved, never physically removed, so QuantityOnHand is unchanged.
            -- QuantityAvailable can only increase by what was actually reserved; adding more than
            -- QuantityReserved would push Available above OnHand, which is physically impossible.
            UPDATE dbo.StockLine
            SET
                QuantityAvailable = ISNULL(QuantityAvailable, 0) +
                                    CASE WHEN ISNULL(QuantityReserved, 0) >= @QtyReturned
                                         THEN @QtyReturned
                                         ELSE ISNULL(QuantityReserved, 0) END,
                QuantityReserved  = CASE WHEN QuantityReserved - @QtyReturned < 0 THEN 0
                                         ELSE QuantityReserved - @QtyReturned END,
                UpdatedBy         = @UpdatedBy,
                UpdatedDate       = @Now
            WHERE StockLineId     = @StockLineId;

            EXEC [dbo].[USP_AddUpdateStocklineHistory]
                @StocklineId     = @StockLineId,
                @ModuleId        = @HistoryModuleId,
                @ReferenceId     = @SourceRepairOrderId,
                @SubModuleId     = NULL,
                @SubRefferenceId = @RepairOrderPartRecordId,
                @ActionId        = @HistoryUnreserveActionId,
                @Qty             = @QtyReturned,
                @UpdatedBy       = @UpdatedBy;

            -- QuantityReceived is unchanged: this is not a new vendor receipt,
            -- it is previously received inventory being released from reservation.
            UPDATE dbo.RepairOrderPart
            SET
                QuantityBackOrdered = CASE WHEN QuantityBackOrdered - @QtyReturned < 0 THEN 0
                                           ELSE QuantityBackOrdered - @QtyReturned END,
                QuantityReserved    = CASE WHEN QuantityReserved    - @QtyReturned < 0 THEN 0
                                           ELSE QuantityReserved    - @QtyReturned END,
                UpdatedBy           = @UpdatedBy,
                UpdatedDate         = @Now
            WHERE RepairOrderPartRecordId = @RepairOrderPartRecordId;
        END

        /* ────────────────────────────────────────────────────────────────
           2b. QTY DAMAGED / LOST
               Parts are physically gone (write-off) — reduce OnHand and Reserved only.
               QuantityAvailable and QuantityIssued are NOT changed.
        ──────────────────────────────────────────────────────────────── */
        IF ISNULL(@QtyDamagedLost, 0) > 0
        BEGIN
            UPDATE dbo.StockLine
            SET
                QuantityOnHand    = CASE WHEN QuantityOnHand   - @QtyDamagedLost < 0 THEN 0
                                         ELSE QuantityOnHand   - @QtyDamagedLost END,
                QuantityReserved  = CASE WHEN QuantityReserved - @QtyDamagedLost < 0 THEN 0
                                         ELSE QuantityReserved - @QtyDamagedLost END,
                UpdatedBy         = @UpdatedBy,
                UpdatedDate       = @Now
            WHERE StockLineId     = @StockLineId;

            EXEC [dbo].[USP_AddUpdateStocklineHistory]
                @StocklineId     = @StockLineId,
                @ModuleId        = @HistoryModuleId,
                @ReferenceId     = @SourceRepairOrderId,
                @SubModuleId     = NULL,
                @SubRefferenceId = @RepairOrderPartRecordId,
                @ActionId        = @HistoryDamagedActionId,
                @Qty             = @QtyDamagedLost,
                @UpdatedBy       = @UpdatedBy;

            UPDATE dbo.RepairOrderPart
            SET
                QuantityBackOrdered = CASE WHEN QuantityBackOrdered - @QtyDamagedLost < 0 THEN 0
                                           ELSE QuantityBackOrdered - @QtyDamagedLost END,
                QuantityReserved    = CASE WHEN QuantityReserved    - @QtyDamagedLost < 0 THEN 0
                                           ELSE QuantityReserved    - @QtyDamagedLost END,
                UpdatedBy           = @UpdatedBy,
                UpdatedDate         = @Now
            WHERE RepairOrderPartRecordId = @RepairOrderPartRecordId;
        END

        /* ────────────────────────────────────────────────────────────────
           3. INSERT reconciliation record with full qty snapshot
        ──────────────────────────────────────────────────────────────── */
        DECLARE @QtyShipped      INT;
        DECLARE @QtyRemainingNow INT;

        SELECT
            @QtyShipped      = QuantityOrdered,
            @QtyRemainingNow = ISNULL(QuantityBackOrdered, 0)
        FROM dbo.RepairOrderPart WITH (NOLOCK)
        WHERE RepairOrderPartRecordId = @RepairOrderPartRecordId;

        DECLARE @Status NVARCHAR(50) =
            CASE
                WHEN @QtyShipped = 0                THEN 'No Qty'
                WHEN @QtyRemainingNow = 0           THEN 'Fully Consumed'
                WHEN @QtyRemainingNow < @QtyShipped THEN 'Partially Consumed'
                ELSE 'Pending'
            END;

        INSERT INTO dbo.PiecePartReconciliation
        (
            RepairOrderPartRecordId,
            SourceRepairOrderId,
            ConsumedRepairOrderId,
            StockLineId,
            QtyShipped,
            QtyConsumed,
            QtyReturned,
            QtyDamagedLost,
            QtyRemaining,
            ReconciliationStatus,
            Memo,
            ParentRepairOrderPartId,
            MasterCompanyId,
            CreatedBy,
            CreatedDate,
            UpdatedBy,
            UpdatedDate,
            IsActive,
            IsDeleted
        )
        VALUES
        (
            @RepairOrderPartRecordId,
            @SourceRepairOrderId,
            @ConsumedRepairOrderId,
            @StockLineId,
            @QtyShipped,
            ISNULL(@QtyConsumed, 0),
            ISNULL(@QtyReturned, 0),
            ISNULL(@QtyDamagedLost, 0),
            @QtyRemainingNow,
            @Status,
            @Memo,
            @ParentRepairOrderPartId,
            @MasterCompanyId,
            @UpdatedBy,
            @Now,
            @UpdatedBy,
            @Now,
            1,
            0
        );

        SET @NewReconciliationId = SCOPE_IDENTITY();

        /* ────────────────────────────────────────────────────────────────
           4. PIECE PART COST — lookup always runs when QtyConsumed > 0.
              4a: insert a RepairOrderCharges line on the consumed RO
                  (only when caller provides a ChargesTypeId).
              4b: absorb cost into the repaired main-part stockline and
                  propagate to WorkOrder / SubWorkOrder material stocklines
                  and Sales Order stockline cost, mirroring what
                  USP_CreateWOStocklineFromRO / USP_CreateSOStocklineFromRO
                  do for regular RO parts.
        ──────────────────────────────────────────────────────────────── */
        IF ISNULL(@QtyConsumed, 0) > 0 OR ISNULL(@QtyDamagedLost, 0) > 0
        BEGIN
            -- Cost lookup runs for both consumed and damaged/lost so @PiecePartCostPerUnit
            -- is always populated and returned to C# for GL batch posting.
            SELECT
                @PartUnitCost = ISNULL(UnitCost, 0),
                @PartNumber   = PartNumber,
                @PartDesc     = PartDescription
            FROM dbo.RepairOrderPart WITH (NOLOCK)
            WHERE RepairOrderPartRecordId = @RepairOrderPartRecordId;

            SET @PiecePartCostPerUnit = @PartUnitCost;

            -- Steps 4a and 4b (charges line + main stockline cost absorption) only apply when
            -- qty was consumed, not for damaged/lost.
            IF ISNULL(@QtyConsumed, 0) > 0
            BEGIN

            /* 4a. RepairOrderCharges line on the consuming RO */
            IF @ChargesTypeId IS NOT NULL
            BEGIN
                DECLARE @NextLineNum INT;

                SELECT @NextLineNum = ISNULL(MAX(LineNum), 0) + 1
                FROM dbo.RepairOrderCharges WITH (NOLOCK)
                WHERE RepairOrderId = @ConsumedRepairOrderId
                  AND IsDeleted     = 0;

                INSERT INTO dbo.RepairOrderCharges
                (
                    RepairOrderId,
                    RepairOrderPartRecordId,
                    ChargesTypeId,
                    Quantity,
                    UnitCost,
                    ExtendedCost,
                    Description,
                    PartNumber,
                    LineNum,
                    MasterCompanyId,
                    CreatedBy,
                    CreatedDate,
                    UpdatedBy,
                    UpdatedDate,
                    IsActive,
                    IsDeleted
                )
                VALUES
                (
                    @ConsumedRepairOrderId,
                    @RepairOrderPartRecordId,
                    @ChargesTypeId,
                    @QtyConsumed,
                    @PartUnitCost,
                    @QtyConsumed * @PartUnitCost,
                    ISNULL(@PartDesc, 'Piece Part Consumption'),
                    @PartNumber,
                    @NextLineNum,
                    @MasterCompanyId,
                    @UpdatedBy,
                    @Now,
                    @UpdatedBy,
                    @Now,
                    1,
                    0
                );
            END

            /* 4b. Absorb piece part cost into the repaired main-part stockline.
                   The total piece part cost (QtyConsumed × UnitCost) is divided
                   by the main part's quantity to get a per-unit cost delta,
                   matching how UnitCost is maintained on StockLine. */
            SELECT TOP 1
                @MainStockLineId = sl.StockLineId,
                @MainPartQty     = ISNULL(NULLIF(sl.Quantity, 0), 1)
            FROM dbo.RepairOrderPart rop WITH (NOLOCK)
            JOIN dbo.StockLine sl WITH (NOLOCK) ON sl.RepairOrderPartRecordId = rop.RepairOrderPartRecordId
            WHERE rop.RepairOrderId          = @ConsumedRepairOrderId
              AND ISNULL(rop.IsPiecePart, 0) = 0
              AND sl.IsParent                = 1
              AND sl.IsDeleted               = 0;

            IF @MainStockLineId IS NOT NULL
            BEGIN
                -- Proportional cost delta: total piece part cost spread across the main part's qty.
                SET @StocklineCostDelta = @QtyConsumed * @PartUnitCost / @MainPartQty;

                -- Add to RepairOrderUnitCost (the repair-spend component) and recompute UnitCost.
                -- UnitCost = PurchaseOrderUnitCost + RepairOrderUnitCost + Adjustment, so adding
                -- the same delta to both RepairOrderUnitCost and UnitCost keeps the formula intact.
                UPDATE dbo.StockLine
                SET
                    RepairOrderUnitCost = ISNULL(RepairOrderUnitCost, 0) + @StocklineCostDelta,
                    UnitCost            = ISNULL(UnitCost, 0)            + @StocklineCostDelta,
                    UpdatedBy           = @UpdatedBy,
                    UpdatedDate         = @Now
                WHERE StockLineId = @MainStockLineId;

                -- Propagate to WorkOrderMaterialStockLine (main WO case).
                -- IsPiecePart = 1:    piece part cost has been consumed and absorbed into this stockline.
                -- IsNewPartAdded = 1: a new piece part has been added to the repair order for this stockline.
                UPDATE dbo.WorkOrderMaterialStockLine
                SET
                    UnitCost     = ISNULL(UnitCost, 0) + @StocklineCostDelta,
                    ExtendedCost = (ISNULL(UnitCost, 0) + @StocklineCostDelta) * ISNULL(Quantity, 0),
                    IsPiecePart  = 1,
                    UpdatedBy    = @UpdatedBy,
                    UpdatedDate  = @Now
                WHERE StockLineId = @MainStockLineId
                  AND IsActive    = 1
                  AND IsDeleted   = 0;

                -- Propagate to SubWorkOrderMaterialStockLine (sub WO case)
                UPDATE dbo.SubWorkOrderMaterialStockLine
                SET
                    UnitCost     = ISNULL(UnitCost, 0) + @StocklineCostDelta,
                    ExtendedCost = (ISNULL(UnitCost, 0) + @StocklineCostDelta) * ISNULL(Quantity, 0),
                    UpdatedBy    = @UpdatedBy,
                    UpdatedDate  = @Now
                WHERE StockLineId = @MainStockLineId
                  AND IsActive    = 1
                  AND IsDeleted   = 0;

                -- Capture WO identifiers for the cost rollup SPs (step 7).
                -- Try main WO first; fall back to sub WO.
                SELECT TOP 1
                    @WOMId  = wom.WorkOrderMaterialsId,
                    @WOId   = wom.WorkOrderId,
                    @WFWOId = wom.WorkFlowWorkOrderId
                FROM dbo.WorkOrderMaterialStockLine womsl WITH (NOLOCK)
                JOIN dbo.WorkOrderMaterials wom WITH (NOLOCK)
                    ON wom.WorkOrderMaterialsId = womsl.WorkOrderMaterialsId
                WHERE womsl.StockLineId = @MainStockLineId
                  AND womsl.IsDeleted   = 0;

                IF @WOId IS NULL
                BEGIN
                    SELECT TOP 1
                        @WOMId  = swom.SubWorkOrderMaterialsId,
                        @WOId   = swom.WorkOrderId,
                        @WFWOId = wm.WorkFlowWorkOrderId
                    FROM dbo.SubWorkOrderMaterialStockLine swomsl WITH (NOLOCK)
                    JOIN dbo.SubWorkOrderMaterials swom WITH (NOLOCK)
                        ON swom.SubWorkOrderMaterialsId = swomsl.SubWorkOrderMaterialsId
                    JOIN dbo.SubWorkOrder swo WITH (NOLOCK)
                        ON swo.SubWorkOrderId = swom.SubWorkOrderId
                    JOIN dbo.WorkOrderMaterials wm WITH (NOLOCK)
                        ON wm.WorkOrderMaterialsId = swo.WorkOrderMaterialsId
                    WHERE swomsl.StockLineId = @MainStockLineId
                      AND swomsl.IsDeleted   = 0;
                END

                -- Find the SO stockline linked to the main repaired stockline.
                -- Join chain mirrors USP_CreateSOStocklineFromRO:
                --   SalesOrderStocklineV1.StocklineId → SalesOrderPartV1.SalesOrderPartId → SalesOrderId
                SELECT TOP 1
                    @SOStocklineId = sosv1.SalesOrderStocklineId,
                    @SOPartId      = sosv1.SalesOrderPartId,
                    @SOId          = sop.SalesOrderId
                FROM dbo.SalesOrderStocklineV1 sosv1 WITH (NOLOCK)
                JOIN dbo.SalesOrderPartV1 sop WITH (NOLOCK) ON sop.SalesOrderPartId = sosv1.SalesOrderPartId
                WHERE sosv1.StocklineId          = @MainStockLineId
                  AND ISNULL(sosv1.IsDeleted, 0) = 0;

                IF @SOStocklineId IS NOT NULL
                BEGIN
                    -- Absorb the piece part cost delta into the SO stockline cost row.
                    -- USP_UpdateSOPartCostDetails (step 8) will then roll the updated
                    -- UnitCost up to the SO part level.
                    UPDATE dbo.SalesOrderStockLineCost
                    SET
                        UnitCost    = ISNULL(UnitCost, 0) + @StocklineCostDelta,
                        UpdatedBy   = @UpdatedBy,
                        UpdatedDate = @Now
                    WHERE SalesOrderStocklineId = @SOStocklineId;
                END
            END
            END -- end consumed-only section (4a + 4b)
        END

        /* ────────────────────────────────────────────────────────────────
           5. Return the new reconciliation record + updated stock state
        ──────────────────────────────────────────────────────────────── */
        SELECT
            ppr.PiecePartReconciliationId,
            ppr.RepairOrderPartRecordId,
            ppr.SourceRepairOrderId,
            srcRO.RepairOrderNumber     AS SourceRONumber,
            ppr.ConsumedRepairOrderId,
            conRO.RepairOrderNumber     AS ConsumedRONumber,
            ppr.QtyShipped,
            -- Cumulative totals across all reconciliation records for this piece part
            (SELECT ISNULL(SUM(QtyConsumed),    0) FROM dbo.PiecePartReconciliation WITH (NOLOCK) WHERE RepairOrderPartRecordId = @RepairOrderPartRecordId AND IsDeleted = 0) AS QtyConsumed,
            (SELECT ISNULL(SUM(QtyReturned),    0) FROM dbo.PiecePartReconciliation WITH (NOLOCK) WHERE RepairOrderPartRecordId = @RepairOrderPartRecordId AND IsDeleted = 0) AS QtyReturned,
            (SELECT ISNULL(SUM(QtyDamagedLost), 0) FROM dbo.PiecePartReconciliation WITH (NOLOCK) WHERE RepairOrderPartRecordId = @RepairOrderPartRecordId AND IsDeleted = 0) AS QtyDamagedLost,
            @QtyRemainingNow            AS QtyRemaining,
            ppr.ReconciliationStatus,
            ppr.Memo,
            sl.QuantityOnHand           AS StockQtyOnHand,
            sl.QuantityAvailable        AS StockQtyAvailable,
            sl.QuantityReserved         AS StockQtyReserved,
            sl.QuantityIssued           AS StockQtyIssued,
            -- Returned so C# can post the GL batch entry for the cost addition
            @MainStockLineId            AS MainStockLineId,
            @PiecePartCostPerUnit       AS PiecePartCostPerUnit,
            @MainPartQty                AS MainPartQty
        FROM  dbo.PiecePartReconciliation  ppr  WITH (NOLOCK)
        JOIN  dbo.RepairOrder  srcRO WITH (NOLOCK) ON srcRO.RepairOrderId = ppr.SourceRepairOrderId
        LEFT JOIN dbo.RepairOrder conRO WITH (NOLOCK) ON conRO.RepairOrderId = ppr.ConsumedRepairOrderId
        JOIN  dbo.StockLine    sl    WITH (NOLOCK) ON sl.StockLineId      = ppr.StockLineId
        WHERE ppr.PiecePartReconciliationId = @NewReconciliationId;

        COMMIT TRANSACTION;

    /* ────────────────────────────────────────────────────────────────
       6. Recalculate consumed RO totals (outside transaction so
          UpdateRepairOrderDetail's own transaction doesn't conflict)
    ──────────────────────────────────────────────────────────────── */
    IF ISNULL(@QtyConsumed, 0) > 0 AND @ChargesTypeId IS NOT NULL AND @ConsumedRepairOrderId IS NOT NULL
    BEGIN
        EXEC dbo.UpdateRepairOrderDetail @ConsumedRepairOrderId;
    END

    /* ────────────────────────────────────────────────────────────────
       7. Recalculate WO cost totals (outside transaction for same
          reason — inner SP transactions must not nest here).
          Mirrors the cost rollup calls in USP_CreateWOStocklineFromRO.
    ──────────────────────────────────────────────────────────────── */
    IF @WOId IS NOT NULL
    BEGIN
        EXEC dbo.USP_UpdateWOMaterialsCost
            @WorkOrderMaterialsId = @WOMId;

        EXEC dbo.USP_UpdateWOTotalCostDetails
            @WorkOrderId         = @WOId,
            @WorkOrderWorkflowId = @WFWOId,
            @UpdatedBy           = @UpdatedBy;

        EXEC dbo.USP_UpdateWOCostDetails
            @WorkOrderId         = @WOId,
            @WorkOrderWorkflowId = @WFWOId,
            @UpdatedBy           = @UpdatedBy;
    END

    /* ────────────────────────────────────────────────────────────────
       8. Recalculate SO cost totals (outside transaction, mirrors
          the USP_UpdateSOPartCostDetails call in USP_CreateSOStocklineFromRO).
    ──────────────────────────────────────────────────────────────── */
    IF @SOId IS NOT NULL AND @SOPartId IS NOT NULL
    BEGIN
        EXEC dbo.USP_UpdateSOPartCostDetails
            @SOId,
            @SOPartId,
            @UpdatedBy,
            @MasterCompanyId;
    END

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;


        DECLARE @ErrorLogID int,
            @DatabaseName varchar(100) = DB_NAME()
            -----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            ,
            @AdhocComments varchar(150) = '[USP_ReconcilePiecePart]',
            @ProcedureParameters varchar(3000) = '@Parameter1 = ''' + CAST(ISNULL(@RepairOrderPartRecordId, '') AS varchar(100)),
            @ApplicationName varchar(100) = 'PAS'
        -----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
        EXEC Splogexception @DatabaseName = @DatabaseName,
                            @AdhocComments = @AdhocComments,
                            @ProcedureParameters = @ProcedureParameters,
                            @ApplicationName = @ApplicationName,
                            @ErrorLogID = @ErrorLogID OUTPUT;

        RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)

        RETURN (1);
    END CATCH

END