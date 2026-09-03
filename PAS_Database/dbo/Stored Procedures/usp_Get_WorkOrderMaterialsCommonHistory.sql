/*********************
 ** File:   [dbo].[usp_Get_WorkOrderMaterialsCommonHistory]
 ** Author:   Ayushi Patel
 ** Description: Combined, chronological, row-wise history for a work order's entire Material List -
 **              every WorkOrderMaterials / WorkOrderMaterialsKit line snapshot (Add PN / Edit),
 **              every WorkOrderMaterialStockLine / WorkOrderMaterialStockLineKit snapshot (stockline
 **              add/edit/delete), plus narrative action events (Add PN, Add Kit, Reserve, Unreserve,
 **              Issue, Unissue, Delete Material, Delete Stockline) sourced from the app's existing
 **              dbo.History log - reusing the same mechanisms that already back the per-row
 **              "Material List History" popup and the app-wide narrative history feature, instead of
 **              introducing a new capture mechanism.
 **
 **              Ordering notes:
 **              - Some business SPs fire the underlying *Audit tables' triggers twice for a single
 **                logical change (e.g. a MERGE followed by a separate UPDATE in the same reserve/issue
 **                call). Consecutive snapshots per record that are identical on every tracked display
 **                field are collapsed to one row.
 **              - Trg_WorkOrderMaterialsKitAudit / Trg_WorkOrderMaterialStockLineKitAudit insert BOTH
 **                the new (INSERTED) and old (DELETED) row on every UPDATE, in that order - so for an
 **                UPDATE the "old" snapshot always lands at a *later* AuditId than the "new" one it
 **                immediately follows, even though it is chronologically stale. Both artifacts share
 **                the exact same UpdatedDate as the row before them, so any row whose UpdatedDate is
 **                identical to its immediate predecessor (within the same record) is dropped, along
 **                with true exact-duplicate content.
 **              - Each source's own audit-table identity column is carried through as RowSeq and used
 **                as the final ORDER BY tiebreaker (after EventDate and a source priority), so rows
 **                sharing an identical displayed timestamp still sort in true insertion order instead
 **                of an undefined tie order.
 **              - Each row also carries a ChangedFields list (comma-separated field keys) identifying
 **                which tracked fields differ from that record's own previous snapshot, so the UI can
 **                highlight only genuinely changed cells instead of doing a naive "compare to the
 **                physically next row" comparison, which breaks once rows from different
 **                parts/stocklines/kits are interleaved by time.
 **
 **              Quantity display notes:
 **              - Quantity/QuantityReserved/QuantityIssued/QtyRemaining are converted the same way the
 **                Material List grid and the existing per-row history popup already do, via
 **                dbo.fn_ConvertUOM(value, fromUOM, toUOM, 0, MasterCompanyId), skipping the call when
 **                fromUOM = toUOM (matches PN-16911). Source of fromUOM/toUOM per row type mirrors the
 **                existing SPs exactly:
 **                  Material rows  - via the line's own stockline (WorkOrderMaterialStockLine ->
 **                                   Stockline.StockUnitOfMeasureId / ConsumeUnitOfMeasureId), same as
 **                                   USP_GetWorkOrderMaterialsAuditList.
 **                  Stockline rows - via that exact stockline (Stockline.StockUnitOfMeasureId /
 **                                   ConsumeUnitOfMeasureId).
 **                  Kit rows       - via the part's ItemMaster (ItemMaster.StockUnitOfMeasureId /
 **                                   ConsumeUnitOfMeasureId), same as the Kit branch in
 **                                   USP_GetWorkOrderMaterialsListNew.
 **                  KitStockline rows - via that exact stockline, same as Stockline rows.
 **
 ** Purpose: Backs the "Material List History" button shown above the Material List grid on Work Order
 **          Edit (before the "Export Parent" button). PN-14788.
 **
 ** PARAMETERS:
 **   @WorkOrderId  - the work order whose material-list history is requested
 **   @EmployeeId   - used to convert dates to the requesting employee's timezone
 **   @SortDir      - ASC | DESC (by EventDate), defaults to DESC (most recent first)
 **
 ** RETURN VALUE: one row per snapshot/action event - see column list in the final SELECT.
 **
 **********************
 ** Change History
 **********************
 ** S NO   Date          Author          Change Description
 ** --     --------      -------------   --------------------------------
    1      31-AUG-2026   Ayushi Patel    Created (PN-14788) - field-diff design over dbo.AuditLog
    2      01-SEP-2026   Ayushi Patel    Redesigned as a row-wise snapshot feed over the existing
                                         WorkOrderMaterialsAudit / WorkOrderMaterialStockLineAudit /
                                         dbo.History tables.
    3      01-SEP-2026   Ayushi Patel    Added WorkOrderMaterialsKit / WorkOrderMaterialStockLineKit
                                         coverage, de-duplication of consecutive identical snapshots,
                                         per-row ChangedFields tracking for correct highlight, moved
                                         Date/Changed By to the end of the row, added a stable
                                         secondary sort so same-timestamp rows group logically.
    4      01-SEP-2026   Ayushi Patel    Fixed non-deterministic ordering on timestamp ties by adding
                                         a per-source RowSeq tiebreaker; excluded the stale "old state"
                                         echo rows produced by the Kit audit triggers' double-insert on
                                         UPDATE; applied the same UOM conversion the Material List grid
                                         and existing history popup already use to Quantity/Reserved/
                                         Issued/Remaining so values match what's shown elsewhere.
    5      01-SEP-2026   Ayushi Patel    USP_UpdateWorkOrderMaterials's stockline/kit-stockline UPDATE
                                         statements never refresh UpdatedDate, so a same-timestamp
                                         requirement wrongly dropped genuine edits. Replaced it with a
                                         precise echo detector: a row is dropped only when it shares its
                                         predecessor's exact timestamp AND its content matches the state
                                         from *two* snapshots back (the true signature of the Kit
                                         triggers' new-then-old double-insert) - a real edit that merely
                                         inherits a stale timestamp no longer gets swallowed. Added
                                         DeleteKit / DeleteKitPart to the narrative action filter so
                                         deleting a kit line or a kit's stockline shows in the feed
                                         (deletion never changes field values, so it can only ever be
                                         surfaced narratively, not as a snapshot diff).
    6      01-SEP-2026   Ayushi Patel    Fixed a SQL three-valued-logic bug in the echo detector: when a
                                         record's *second-ever* snapshot shared its predecessor's exact
                                         timestamp, "RowHash = PrevPrevHash" against a NULL PrevPrevHash
                                         evaluated to UNKNOWN (not FALSE), so NOT(...) also stayed
                                         UNKNOWN and the row was wrongly dropped instead of kept - this
                                         was silently swallowing real edits (e.g. a stockline Provision
                                         edit via the "Edit" popup, whose UPDATE never refreshes
                                         UpdatedDate). Added an explicit PrevPrevHash IS NOT NULL guard.
                                         Also: added a 10-second EventBucket (based on the raw UTC
                                         timestamp) as the primary sort key ahead of the exact
                                         timestamp, so a parent (Material/Kit) row and its child
                                         (Stockline/KitStockline) row from the same save - which some
                                         underlying SPs stamp with slightly different UpdatedDate values
                                         - still land together instead of interleaving with unrelated
                                         rows. And: ChangedBy now reports CreatedBy for a record's first
                                         (creation) snapshot and UpdatedBy for every snapshot after that,
                                         instead of always showing UpdatedBy.
    7      02-SEP-2026   Ayushi Patel    Fixed the Source-priority tiebreaker (Action/Material.Kit/
                                         Stockline.KitStockline) always sorting ascending regardless of
                                         @SortDir - in DESC mode it was silently reversing itself for
                                         genuine same-EventDate ties. Now flips with @SortDir like every
                                         other sort key, so parent-before-child ordering reads the same
                                         direction the whole list is sorted in.
    8      02-SEP-2026   Ayushi Patel    Fixed stockline/kit-stockline rows displaying ~5.5 hours later
                                         than the kit/material row saved in the same action. Root cause:
                                         WorkOrderMaterialStockLine(Kit).UpdatedDate defaults to GETDATE()
                                         (this SQL instance's local time) and their audit triggers copy it
                                         as-is, while WorkOrderMaterials(Kit)'s audit triggers re-stamp
                                         with GETUTCDATE() - so stockline sources' raw timestamp was
                                         already local, not UTC, and got shifted again by the employee's
                                         timezone on top of that. Added @ServerUtcOffsetSec to undo the
                                         server's own UTC offset for stockline/kit-stockline rows only,
                                         before the shared UTC-to-employee-local conversion.
    9      02-SEP-2026   Ayushi Patel    Root-caused remaining "duplicate row at a stray older time"
                                         cases: Trg_WorkOrderMaterialsKitAudit / _StockLineAudit /
                                         _StockLineKitAudit each unconditionally do a second
                                         "INSERT ... SELECT * FROM DELETED" on every UPDATE, so one save
                                         always writes both the new state AND a stale echo of the pre-update
                                         state. The de-dup filter's echo detector assumed that echo always
                                         carries the exact same UpdatedDate as the row it follows, which
                                         only holds when the calling SP never refreshes UpdatedDate on
                                         UPDATE - not a safe assumption across every save path (confirmed by
                                         direct testing: a plain UPDATE that does set UpdatedDate produces
                                         an echo with its own older, genuine-looking timestamp, which then
                                         escaped the old filter entirely). Replaced the UpdatedDate-equality
                                         check with an AuditId-adjacency check (echo row's AuditId is always
                                         exactly the new row's AuditId + 1, since both come from the same
                                         trigger firing) - a structural signal that holds regardless of
                                         which SP touched the row, verified against a fresh live INSERT/
                                         UPDATE sequence covering every action type before and after.

exec usp_Get_WorkOrderMaterialsCommonHistory @WorkOrderId=10662, @EmployeeId=2
**********************/

CREATE PROCEDURE [dbo].[usp_Get_WorkOrderMaterialsCommonHistory]
    @WorkOrderId BIGINT,
    @EmployeeId  BIGINT      = NULL,
    @SortDir     NVARCHAR(4) = N'DESC'
AS
BEGIN
    SET NOCOUNT ON;
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
    BEGIN TRY

        IF @SortDir NOT IN (N'ASC', N'DESC') SET @SortDir = N'DESC';

        DECLARE @CurrntEmpTimeZoneDesc VARCHAR(100) = '';
        SELECT @CurrntEmpTimeZoneDesc = COALESCE(ETZ.[Description], LTZ.[Description])
        FROM dbo.Employee E WITH (NOLOCK)
        LEFT JOIN dbo.TimeZone ETZ WITH (NOLOCK) ON E.TimeZoneId = ETZ.TimeZoneId
        LEFT JOIN dbo.LegalEntity LE WITH (NOLOCK) ON E.LegalEntityId = LE.LegalEntityId
        LEFT JOIN dbo.TimeZone LTZ WITH (NOLOCK) ON LE.TimeZoneId = LTZ.TimeZoneId
        WHERE E.EmployeeId = @EmployeeId;

        DECLARE @WorkOrderModuleId BIGINT;
        SELECT @WorkOrderModuleId = ModuleId FROM dbo.Module WITH (NOLOCK) WHERE ModuleName = 'WorkOrder';

        -- Trg_WorkOrderMaterialsAudit / Trg_WorkOrderMaterialsKitAudit re-stamp UpdatedDate with
        -- GETUTCDATE() at audit-insert time, so those two sources' raw UpdatedDate is true UTC. But
        -- Trg_WorkOrderMaterialStockLineAudit / Trg_WorkOrderMaterialStockLineKitAudit do a plain
        -- "SELECT * FROM INSERTED", copying the source table's own UpdatedDate column as-is - and both
        -- WorkOrderMaterialStockLine.UpdatedDate and WorkOrderMaterialStockLineKit.UpdatedDate default to
        -- GETDATE() (this SQL instance's own local time), not GETUTCDATE(). Converting an already-local
        -- value through ConvertUTCtoLocal() a second time shifts stockline-sourced rows by the server's
        -- own UTC offset (e.g. +5:30 here), so they land hours away from the true moment they happened -
        -- this is what made stockline/kit-stockline edits appear to be at a completely different time than
        -- the kit/material edits saved in the very same action. Undo that server offset up front so every
        -- source's raw date is true UTC before the shared EventBucket/EventDate conversion below.
        DECLARE @ServerUtcOffsetSec INT = DATEDIFF(SECOND, GETUTCDATE(), GETDATE());

        ;WITH
        -- ===================== MATERIAL (WorkOrderMaterials) =====================
        MaterialRaw AS
        (
            SELECT
                WOM.WorkOrderMaterialsAuditId,
                WOM.WorkOrderMaterialsId,
                WOM.UpdatedDate AS RawDate,
                DATEADD(SECOND, (DATEDIFF(SECOND, '2000-01-01', WOM.UpdatedDate) / 10) * 10, CAST('2000-01-01' AS DATETIME2(3))) AS EventBucket,
                CASE WHEN @CurrntEmpTimeZoneDesc IS NULL OR LEN(@CurrntEmpTimeZoneDesc) = 0 THEN WOM.UpdatedDate
                     ELSE CAST(dbo.ConvertUTCtoLocal(WOM.UpdatedDate, @CurrntEmpTimeZoneDesc) AS DATETIME2(3)) END AS EventDate,
                WOM.UpdatedBy AS ChangedBy,
                WOM.CreatedBy AS CreatedByRaw,
                WOM.PartNum AS PartNumber,
                WOM.TaskName AS Task,
                WOM.Condition AS Condition,
                WOM.RequestType AS RequestType,
                WOM.Provision AS Provision,
                CASE WHEN ISNULL(uomStock.ShortName, '') = ISNULL(uomConsume.ShortName, '') THEN ISNULL(WOM.Quantity, 0)
                     ELSE dbo.fn_ConvertUOM(ISNULL(WOM.Quantity, 0), uomStock.ShortName, uomConsume.ShortName, 0, WOM.MasterCompanyId) END AS QtyRequested,
                CASE WHEN ISNULL(uomStock.ShortName, '') = ISNULL(uomConsume.ShortName, '') THEN ISNULL(WOM.QuantityReserved, 0)
                     ELSE dbo.fn_ConvertUOM(ISNULL(WOM.QuantityReserved, 0), uomStock.ShortName, uomConsume.ShortName, 0, WOM.MasterCompanyId) END AS QtyReserved,
                CASE WHEN ISNULL(uomStock.ShortName, '') = ISNULL(uomConsume.ShortName, '') THEN ISNULL(WOM.QuantityIssued, 0)
                     ELSE dbo.fn_ConvertUOM(ISNULL(WOM.QuantityIssued, 0), uomStock.ShortName, uomConsume.ShortName, 0, WOM.MasterCompanyId) END AS QtyIssued,
                CASE WHEN ISNULL(uomStock.ShortName, '') = ISNULL(uomConsume.ShortName, '') THEN ISNULL(WOM.Quantity, 0) - ISNULL(WOM.QuantityIssued, 0)
                     ELSE dbo.fn_ConvertUOM(ISNULL(WOM.Quantity, 0) - ISNULL(WOM.QuantityIssued, 0), uomStock.ShortName, uomConsume.ShortName, 0, WOM.MasterCompanyId) END AS QtyRemaining,
                WOM.UOM AS UOM,
                SLF.Name AS Shelf,
                B.Name AS Bin,
                WOM.IsActive AS IsActive,
                WOM.IsDeleted AS IsDeleted,
                WOM.Memo AS Memo,
                WOM.Notes AS Notes
            FROM [dbo].[WorkOrderMaterialsAudit] WOM WITH (NOLOCK)
            LEFT JOIN [dbo].[ItemMaster] IM WITH (NOLOCK) ON IM.ItemMasterId = WOM.ItemMasterId
            LEFT JOIN [dbo].[Shelf] SLF WITH (NOLOCK) ON SLF.ShelfId = IM.ShelfId
            LEFT JOIN [dbo].[Bin] B WITH (NOLOCK) ON B.BinId = IM.BinId
            OUTER APPLY (
                SELECT TOP (1) SL.StockUnitOfMeasureId, SL.ConsumeUnitOfMeasureId
                FROM [dbo].[WorkOrderMaterialStockLine] MSTL WITH (NOLOCK)
                JOIN [dbo].[Stockline] SL WITH (NOLOCK) ON SL.StockLineId = MSTL.StockLineId
                WHERE MSTL.WorkOrderMaterialsId = WOM.WorkOrderMaterialsId AND MSTL.IsDeleted = 0
                ORDER BY MSTL.WOMStockLineId
            ) MatUOM
            LEFT JOIN [dbo].[UnitOfMeasure] uomStock WITH (NOLOCK) ON uomStock.UnitOfMeasureId = MatUOM.StockUnitOfMeasureId
            LEFT JOIN [dbo].[UnitOfMeasure] uomConsume WITH (NOLOCK) ON uomConsume.UnitOfMeasureId = MatUOM.ConsumeUnitOfMeasureId
            WHERE WOM.WorkOrderId = @WorkOrderId
        ),
        MaterialLagged AS
        (
            SELECT
                *,
                CHECKSUM(Task, Condition, RequestType, Provision, QtyRequested, QtyReserved, QtyIssued, IsActive, IsDeleted, Memo, Notes) AS RowHash,
                LAG(CHECKSUM(Task, Condition, RequestType, Provision, QtyRequested, QtyReserved, QtyIssued, IsActive, IsDeleted, Memo, Notes))
                    OVER (PARTITION BY WorkOrderMaterialsId ORDER BY WorkOrderMaterialsAuditId) AS PrevHash,
                LAG(CHECKSUM(Task, Condition, RequestType, Provision, QtyRequested, QtyReserved, QtyIssued, IsActive, IsDeleted, Memo, Notes), 2)
                    OVER (PARTITION BY WorkOrderMaterialsId ORDER BY WorkOrderMaterialsAuditId) AS PrevPrevHash,
                LAG(RawDate) OVER (PARTITION BY WorkOrderMaterialsId ORDER BY WorkOrderMaterialsAuditId) AS PrevRawDate,
                LAG(Task) OVER (PARTITION BY WorkOrderMaterialsId ORDER BY WorkOrderMaterialsAuditId) AS PrevTask,
                LAG(Condition) OVER (PARTITION BY WorkOrderMaterialsId ORDER BY WorkOrderMaterialsAuditId) AS PrevCondition,
                LAG(RequestType) OVER (PARTITION BY WorkOrderMaterialsId ORDER BY WorkOrderMaterialsAuditId) AS PrevRequestType,
                LAG(Provision) OVER (PARTITION BY WorkOrderMaterialsId ORDER BY WorkOrderMaterialsAuditId) AS PrevProvision,
                LAG(QtyRequested) OVER (PARTITION BY WorkOrderMaterialsId ORDER BY WorkOrderMaterialsAuditId) AS PrevQtyRequested,
                LAG(QtyReserved) OVER (PARTITION BY WorkOrderMaterialsId ORDER BY WorkOrderMaterialsAuditId) AS PrevQtyReserved,
                LAG(QtyIssued) OVER (PARTITION BY WorkOrderMaterialsId ORDER BY WorkOrderMaterialsAuditId) AS PrevQtyIssued,
                LAG(IsActive) OVER (PARTITION BY WorkOrderMaterialsId ORDER BY WorkOrderMaterialsAuditId) AS PrevIsActive,
                LAG(IsDeleted) OVER (PARTITION BY WorkOrderMaterialsId ORDER BY WorkOrderMaterialsAuditId) AS PrevIsDeleted
            FROM MaterialRaw
        ),
        MaterialRows AS
        (
            SELECT
                N'Material' AS Source,
                PartNumber,
                CAST(NULL AS VARCHAR(50)) AS StockLineNumber,
                Task, Condition, RequestType, Provision, QtyRequested, QtyReserved, QtyIssued, QtyRemaining, UOM, Shelf, Bin, IsActive, IsDeleted, Memo, Notes,
                CAST(NULL AS VARCHAR(MAX)) AS Description,
                STUFF(
                    CASE WHEN PrevHash IS NOT NULL AND ISNULL(Task, '') <> ISNULL(PrevTask, '') THEN ',task' ELSE '' END +
                    CASE WHEN PrevHash IS NOT NULL AND ISNULL(Condition, '') <> ISNULL(PrevCondition, '') THEN ',condition' ELSE '' END +
                    CASE WHEN PrevHash IS NOT NULL AND ISNULL(RequestType, '') <> ISNULL(PrevRequestType, '') THEN ',requestType' ELSE '' END +
                    CASE WHEN PrevHash IS NOT NULL AND ISNULL(Provision, '') <> ISNULL(PrevProvision, '') THEN ',provision' ELSE '' END +
                    CASE WHEN PrevHash IS NOT NULL AND ISNULL(QtyRequested, -1) <> ISNULL(PrevQtyRequested, -1) THEN ',qtyRequested' ELSE '' END +
                    CASE WHEN PrevHash IS NOT NULL AND ISNULL(QtyReserved, -1) <> ISNULL(PrevQtyReserved, -1) THEN ',qtyReserved' ELSE '' END +
                    CASE WHEN PrevHash IS NOT NULL AND ISNULL(QtyIssued, -1) <> ISNULL(PrevQtyIssued, -1) THEN ',qtyIssued' ELSE '' END +
                    CASE WHEN PrevHash IS NOT NULL AND ISNULL(CAST(IsActive AS INT), -1) <> ISNULL(CAST(PrevIsActive AS INT), -1) THEN ',isActive' ELSE '' END +
                    CASE WHEN PrevHash IS NOT NULL AND ISNULL(CAST(IsDeleted AS INT), -1) <> ISNULL(CAST(PrevIsDeleted AS INT), -1) THEN ',isDeleted' ELSE '' END
                , 1, 1, '') AS ChangedFields,
                EventBucket,
                EventDate,
                CASE WHEN PrevHash IS NULL THEN CreatedByRaw ELSE ChangedBy END AS ChangedBy,
                WorkOrderMaterialsAuditId AS RowSeq
            FROM MaterialLagged
            WHERE PrevHash IS NULL OR (RowHash <> PrevHash AND NOT (PrevPrevHash IS NOT NULL AND RowHash = PrevPrevHash AND RawDate = PrevRawDate))
        ),
        -- ===================== STOCKLINE (WorkOrderMaterialStockLine) =====================
        StockLineRaw AS
        (
            SELECT
                WSL.WOMStockLineAuditId,
                WSL.WOMStockLineId,
                DATEADD(SECOND, -@ServerUtcOffsetSec, WSL.UpdatedDate) AS RawDate,
                DATEADD(SECOND, (DATEDIFF(SECOND, '2000-01-01', DATEADD(SECOND, -@ServerUtcOffsetSec, WSL.UpdatedDate)) / 10) * 10, CAST('2000-01-01' AS DATETIME2(3))) AS EventBucket,
                CASE WHEN @CurrntEmpTimeZoneDesc IS NULL OR LEN(@CurrntEmpTimeZoneDesc) = 0 THEN DATEADD(SECOND, -@ServerUtcOffsetSec, WSL.UpdatedDate)
                     ELSE CAST(dbo.ConvertUTCtoLocal(DATEADD(SECOND, -@ServerUtcOffsetSec, WSL.UpdatedDate), @CurrntEmpTimeZoneDesc) AS DATETIME2(3)) END AS EventDate,
                WSL.UpdatedBy AS ChangedBy,
                WSL.CreatedBy AS CreatedByRaw,
                IM2.PartNumber AS PartNumber,
                STK.StockLineNumber AS StockLineNumber,
                COND.[Description] AS Condition,
                PROV.[Description] AS Provision,
                CASE WHEN ISNULL(uomStock2.ShortName, '') = ISNULL(uomConsume2.ShortName, '') THEN ISNULL(WSL.Quantity, 0)
                     ELSE dbo.fn_ConvertUOM(ISNULL(WSL.Quantity, 0), uomStock2.ShortName, uomConsume2.ShortName, 0, WSL.MasterCompanyId) END AS QtyRequested,
                CASE WHEN ISNULL(uomStock2.ShortName, '') = ISNULL(uomConsume2.ShortName, '') THEN ISNULL(WSL.QtyReserved, 0)
                     ELSE dbo.fn_ConvertUOM(ISNULL(WSL.QtyReserved, 0), uomStock2.ShortName, uomConsume2.ShortName, 0, WSL.MasterCompanyId) END AS QtyReserved,
                CASE WHEN ISNULL(uomStock2.ShortName, '') = ISNULL(uomConsume2.ShortName, '') THEN ISNULL(WSL.QtyIssued, 0)
                     ELSE dbo.fn_ConvertUOM(ISNULL(WSL.QtyIssued, 0), uomStock2.ShortName, uomConsume2.ShortName, 0, WSL.MasterCompanyId) END AS QtyIssued,
                CASE WHEN ISNULL(uomStock2.ShortName, '') = ISNULL(uomConsume2.ShortName, '') THEN ISNULL(WSL.Quantity, 0) - ISNULL(WSL.QtyIssued, 0)
                     ELSE dbo.fn_ConvertUOM(ISNULL(WSL.Quantity, 0) - ISNULL(WSL.QtyIssued, 0), uomStock2.ShortName, uomConsume2.ShortName, 0, WSL.MasterCompanyId) END AS QtyRemaining,
                WSL.IsActive AS IsActive,
                WSL.IsDeleted AS IsDeleted,
                WSL.Notes AS Notes
            FROM [dbo].[WorkOrderMaterialStockLineAudit] WSL WITH (NOLOCK)
            LEFT JOIN [dbo].[ItemMaster] IM2 WITH (NOLOCK) ON IM2.ItemMasterId = WSL.ItemMasterId
            LEFT JOIN [dbo].[Stockline] STK WITH (NOLOCK) ON STK.StockLineId = WSL.StockLineId
            LEFT JOIN [dbo].[Condition] COND WITH (NOLOCK) ON COND.ConditionId = WSL.ConditionId
            LEFT JOIN [dbo].[Provision] PROV WITH (NOLOCK) ON PROV.ProvisionId = WSL.ProvisionId
            LEFT JOIN [dbo].[UnitOfMeasure] uomStock2 WITH (NOLOCK) ON uomStock2.UnitOfMeasureId = STK.StockUnitOfMeasureId
            LEFT JOIN [dbo].[UnitOfMeasure] uomConsume2 WITH (NOLOCK) ON uomConsume2.UnitOfMeasureId = STK.ConsumeUnitOfMeasureId
            WHERE WSL.WorkOrderMaterialsId IN (
                SELECT WorkOrderMaterialsId FROM [dbo].[WorkOrderMaterialsAudit] WHERE WorkOrderId = @WorkOrderId
                UNION
                SELECT WorkOrderMaterialsId FROM [dbo].[WorkOrderMaterials] WITH (NOLOCK) WHERE WorkOrderId = @WorkOrderId
            )
        ),
        StockLineLagged AS
        (
            SELECT
                *,
                CHECKSUM(Condition, Provision, QtyRequested, QtyReserved, QtyIssued, IsActive, IsDeleted, Notes) AS RowHash,
                LAG(CHECKSUM(Condition, Provision, QtyRequested, QtyReserved, QtyIssued, IsActive, IsDeleted, Notes))
                    OVER (PARTITION BY WOMStockLineId ORDER BY WOMStockLineAuditId) AS PrevHash,
                LAG(CHECKSUM(Condition, Provision, QtyRequested, QtyReserved, QtyIssued, IsActive, IsDeleted, Notes), 2)
                    OVER (PARTITION BY WOMStockLineId ORDER BY WOMStockLineAuditId) AS PrevPrevHash,
                LAG(RawDate) OVER (PARTITION BY WOMStockLineId ORDER BY WOMStockLineAuditId) AS PrevRawDate,
                LAG(WOMStockLineAuditId) OVER (PARTITION BY WOMStockLineId ORDER BY WOMStockLineAuditId) AS PrevAuditId,
                LAG(Condition) OVER (PARTITION BY WOMStockLineId ORDER BY WOMStockLineAuditId) AS PrevCondition,
                LAG(Provision) OVER (PARTITION BY WOMStockLineId ORDER BY WOMStockLineAuditId) AS PrevProvision,
                LAG(QtyRequested) OVER (PARTITION BY WOMStockLineId ORDER BY WOMStockLineAuditId) AS PrevQtyRequested,
                LAG(QtyReserved) OVER (PARTITION BY WOMStockLineId ORDER BY WOMStockLineAuditId) AS PrevQtyReserved,
                LAG(QtyIssued) OVER (PARTITION BY WOMStockLineId ORDER BY WOMStockLineAuditId) AS PrevQtyIssued,
                LAG(IsActive) OVER (PARTITION BY WOMStockLineId ORDER BY WOMStockLineAuditId) AS PrevIsActive,
                LAG(IsDeleted) OVER (PARTITION BY WOMStockLineId ORDER BY WOMStockLineAuditId) AS PrevIsDeleted
            FROM StockLineRaw
        ),
        StockLineRows AS
        (
            SELECT
                N'Stockline' AS Source,
                PartNumber, StockLineNumber,
                CAST(NULL AS VARCHAR(256)) AS Task,
                Condition,
                CAST(NULL AS VARCHAR(256)) AS RequestType,
                Provision, QtyRequested, QtyReserved, QtyIssued, QtyRemaining,
                CAST(NULL AS VARCHAR(256)) AS UOM,
                CAST(NULL AS VARCHAR(256)) AS Shelf,
                CAST(NULL AS VARCHAR(256)) AS Bin,
                IsActive, IsDeleted,
                CAST(NULL AS NVARCHAR(MAX)) AS Memo,
                Notes,
                CAST(NULL AS VARCHAR(MAX)) AS Description,
                STUFF(
                    CASE WHEN PrevHash IS NOT NULL AND ISNULL(Condition, '') <> ISNULL(PrevCondition, '') THEN ',condition' ELSE '' END +
                    CASE WHEN PrevHash IS NOT NULL AND ISNULL(Provision, '') <> ISNULL(PrevProvision, '') THEN ',provision' ELSE '' END +
                    CASE WHEN PrevHash IS NOT NULL AND ISNULL(QtyRequested, -1) <> ISNULL(PrevQtyRequested, -1) THEN ',qtyRequested' ELSE '' END +
                    CASE WHEN PrevHash IS NOT NULL AND ISNULL(QtyReserved, -1) <> ISNULL(PrevQtyReserved, -1) THEN ',qtyReserved' ELSE '' END +
                    CASE WHEN PrevHash IS NOT NULL AND ISNULL(QtyIssued, -1) <> ISNULL(PrevQtyIssued, -1) THEN ',qtyIssued' ELSE '' END +
                    CASE WHEN PrevHash IS NOT NULL AND ISNULL(CAST(IsActive AS INT), -1) <> ISNULL(CAST(PrevIsActive AS INT), -1) THEN ',isActive' ELSE '' END +
                    CASE WHEN PrevHash IS NOT NULL AND ISNULL(CAST(IsDeleted AS INT), -1) <> ISNULL(CAST(PrevIsDeleted AS INT), -1) THEN ',isDeleted' ELSE '' END
                , 1, 1, '') AS ChangedFields,
                EventBucket,
                EventDate,
                CASE WHEN PrevHash IS NULL THEN CreatedByRaw ELSE ChangedBy END AS ChangedBy,
                WOMStockLineAuditId AS RowSeq
            FROM StockLineLagged
            WHERE PrevHash IS NULL OR (RowHash <> PrevHash AND NOT (PrevPrevHash IS NOT NULL AND RowHash = PrevPrevHash AND WOMStockLineAuditId = PrevAuditId + 1))
        ),
        -- ===================== KIT (WorkOrderMaterialsKit) =====================
        KitRaw AS
        (
            SELECT
                WMK.WorkOrderMaterialsKitAuditId,
                WMK.WorkOrderMaterialsKitId,
                WMK.UpdatedDate AS RawDate,
                DATEADD(SECOND, (DATEDIFF(SECOND, '2000-01-01', WMK.UpdatedDate) / 10) * 10, CAST('2000-01-01' AS DATETIME2(3))) AS EventBucket,
                CASE WHEN @CurrntEmpTimeZoneDesc IS NULL OR LEN(@CurrntEmpTimeZoneDesc) = 0 THEN WMK.UpdatedDate
                     ELSE CAST(dbo.ConvertUTCtoLocal(WMK.UpdatedDate, @CurrntEmpTimeZoneDesc) AS DATETIME2(3)) END AS EventDate,
                WMK.UpdatedBy AS ChangedBy,
                WMK.CreatedBy AS CreatedByRaw,
                IM3.PartNumber AS PartNumber,
                TASK.[Description] AS Task,
                COND2.[Description] AS Condition,
                MM.Name AS RequestType,
                PROV2.[Description] AS Provision,
                CASE WHEN ISNULL(uomStock3.ShortName, '') = ISNULL(uomConsume3.ShortName, '') THEN ISNULL(WMK.Quantity, 0)
                     ELSE dbo.fn_ConvertUOM(ISNULL(WMK.Quantity, 0), uomStock3.ShortName, uomConsume3.ShortName, 0, WMK.MasterCompanyId) END AS QtyRequested,
                CASE WHEN ISNULL(uomStock3.ShortName, '') = ISNULL(uomConsume3.ShortName, '') THEN ISNULL(WMK.QuantityReserved, 0)
                     ELSE dbo.fn_ConvertUOM(ISNULL(WMK.QuantityReserved, 0), uomStock3.ShortName, uomConsume3.ShortName, 0, WMK.MasterCompanyId) END AS QtyReserved,
                CASE WHEN ISNULL(uomStock3.ShortName, '') = ISNULL(uomConsume3.ShortName, '') THEN ISNULL(WMK.QuantityIssued, 0)
                     ELSE dbo.fn_ConvertUOM(ISNULL(WMK.QuantityIssued, 0), uomStock3.ShortName, uomConsume3.ShortName, 0, WMK.MasterCompanyId) END AS QtyIssued,
                CASE WHEN ISNULL(uomStock3.ShortName, '') = ISNULL(uomConsume3.ShortName, '') THEN ISNULL(WMK.Quantity, 0) - ISNULL(WMK.QuantityIssued, 0)
                     ELSE dbo.fn_ConvertUOM(ISNULL(WMK.Quantity, 0) - ISNULL(WMK.QuantityIssued, 0), uomStock3.ShortName, uomConsume3.ShortName, 0, WMK.MasterCompanyId) END AS QtyRemaining,
                WMK.IsActive AS IsActive,
                WMK.IsDeleted AS IsDeleted,
                WMK.Memo AS Memo
            FROM [dbo].[WorkOrderMaterialsKitAudit] WMK WITH (NOLOCK)
            LEFT JOIN [dbo].[ItemMaster] IM3 WITH (NOLOCK) ON IM3.ItemMasterId = WMK.ItemMasterId
            LEFT JOIN [dbo].[Task] TASK WITH (NOLOCK) ON TASK.TaskId = WMK.TaskId
            LEFT JOIN [dbo].[Condition] COND2 WITH (NOLOCK) ON COND2.ConditionId = WMK.ConditionCodeId
            LEFT JOIN [dbo].[MaterialMandatories] MM WITH (NOLOCK) ON MM.Id = WMK.MaterialMandatoriesId
            LEFT JOIN [dbo].[Provision] PROV2 WITH (NOLOCK) ON PROV2.ProvisionId = WMK.ProvisionId
            LEFT JOIN [dbo].[UnitOfMeasure] uomStock3 WITH (NOLOCK) ON uomStock3.UnitOfMeasureId = IM3.StockUnitOfMeasureId
            LEFT JOIN [dbo].[UnitOfMeasure] uomConsume3 WITH (NOLOCK) ON uomConsume3.UnitOfMeasureId = IM3.ConsumeUnitOfMeasureId
            WHERE WMK.WorkOrderId = @WorkOrderId
        ),
        KitLagged AS
        (
            SELECT
                *,
                CHECKSUM(Task, Condition, RequestType, Provision, QtyRequested, QtyReserved, QtyIssued, IsActive, IsDeleted, Memo) AS RowHash,
                LAG(CHECKSUM(Task, Condition, RequestType, Provision, QtyRequested, QtyReserved, QtyIssued, IsActive, IsDeleted, Memo))
                    OVER (PARTITION BY WorkOrderMaterialsKitId ORDER BY WorkOrderMaterialsKitAuditId) AS PrevHash,
                LAG(CHECKSUM(Task, Condition, RequestType, Provision, QtyRequested, QtyReserved, QtyIssued, IsActive, IsDeleted, Memo), 2)
                    OVER (PARTITION BY WorkOrderMaterialsKitId ORDER BY WorkOrderMaterialsKitAuditId) AS PrevPrevHash,
                LAG(RawDate) OVER (PARTITION BY WorkOrderMaterialsKitId ORDER BY WorkOrderMaterialsKitAuditId) AS PrevRawDate,
                LAG(WorkOrderMaterialsKitAuditId) OVER (PARTITION BY WorkOrderMaterialsKitId ORDER BY WorkOrderMaterialsKitAuditId) AS PrevAuditId,
                LAG(Task) OVER (PARTITION BY WorkOrderMaterialsKitId ORDER BY WorkOrderMaterialsKitAuditId) AS PrevTask,
                LAG(Condition) OVER (PARTITION BY WorkOrderMaterialsKitId ORDER BY WorkOrderMaterialsKitAuditId) AS PrevCondition,
                LAG(RequestType) OVER (PARTITION BY WorkOrderMaterialsKitId ORDER BY WorkOrderMaterialsKitAuditId) AS PrevRequestType,
                LAG(Provision) OVER (PARTITION BY WorkOrderMaterialsKitId ORDER BY WorkOrderMaterialsKitAuditId) AS PrevProvision,
                LAG(QtyRequested) OVER (PARTITION BY WorkOrderMaterialsKitId ORDER BY WorkOrderMaterialsKitAuditId) AS PrevQtyRequested,
                LAG(QtyReserved) OVER (PARTITION BY WorkOrderMaterialsKitId ORDER BY WorkOrderMaterialsKitAuditId) AS PrevQtyReserved,
                LAG(QtyIssued) OVER (PARTITION BY WorkOrderMaterialsKitId ORDER BY WorkOrderMaterialsKitAuditId) AS PrevQtyIssued,
                LAG(IsActive) OVER (PARTITION BY WorkOrderMaterialsKitId ORDER BY WorkOrderMaterialsKitAuditId) AS PrevIsActive,
                LAG(IsDeleted) OVER (PARTITION BY WorkOrderMaterialsKitId ORDER BY WorkOrderMaterialsKitAuditId) AS PrevIsDeleted
            FROM KitRaw
        ),
        KitRows AS
        (
            SELECT
                N'Kit' AS Source,
                PartNumber,
                CAST(NULL AS VARCHAR(50)) AS StockLineNumber,
                Task, Condition, RequestType, Provision, QtyRequested, QtyReserved, QtyIssued, QtyRemaining,
                CAST(NULL AS VARCHAR(256)) AS UOM,
                CAST(NULL AS VARCHAR(256)) AS Shelf,
                CAST(NULL AS VARCHAR(256)) AS Bin,
                IsActive, IsDeleted, Memo,
                CAST(NULL AS NVARCHAR(MAX)) AS Notes,
                CAST(NULL AS VARCHAR(MAX)) AS Description,
                STUFF(
                    CASE WHEN PrevHash IS NOT NULL AND ISNULL(Task, '') <> ISNULL(PrevTask, '') THEN ',task' ELSE '' END +
                    CASE WHEN PrevHash IS NOT NULL AND ISNULL(Condition, '') <> ISNULL(PrevCondition, '') THEN ',condition' ELSE '' END +
                    CASE WHEN PrevHash IS NOT NULL AND ISNULL(RequestType, '') <> ISNULL(PrevRequestType, '') THEN ',requestType' ELSE '' END +
                    CASE WHEN PrevHash IS NOT NULL AND ISNULL(Provision, '') <> ISNULL(PrevProvision, '') THEN ',provision' ELSE '' END +
                    CASE WHEN PrevHash IS NOT NULL AND ISNULL(QtyRequested, -1) <> ISNULL(PrevQtyRequested, -1) THEN ',qtyRequested' ELSE '' END +
                    CASE WHEN PrevHash IS NOT NULL AND ISNULL(QtyReserved, -1) <> ISNULL(PrevQtyReserved, -1) THEN ',qtyReserved' ELSE '' END +
                    CASE WHEN PrevHash IS NOT NULL AND ISNULL(QtyIssued, -1) <> ISNULL(PrevQtyIssued, -1) THEN ',qtyIssued' ELSE '' END +
                    CASE WHEN PrevHash IS NOT NULL AND ISNULL(CAST(IsActive AS INT), -1) <> ISNULL(CAST(PrevIsActive AS INT), -1) THEN ',isActive' ELSE '' END +
                    CASE WHEN PrevHash IS NOT NULL AND ISNULL(CAST(IsDeleted AS INT), -1) <> ISNULL(CAST(PrevIsDeleted AS INT), -1) THEN ',isDeleted' ELSE '' END
                , 1, 1, '') AS ChangedFields,
                EventBucket,
                EventDate,
                CASE WHEN PrevHash IS NULL THEN CreatedByRaw ELSE ChangedBy END AS ChangedBy,
                WorkOrderMaterialsKitAuditId AS RowSeq
            FROM KitLagged
            WHERE PrevHash IS NULL OR (RowHash <> PrevHash AND NOT (PrevPrevHash IS NOT NULL AND RowHash = PrevPrevHash AND WorkOrderMaterialsKitAuditId = PrevAuditId + 1))
        ),
        -- ===================== KIT STOCKLINE (WorkOrderMaterialStockLineKit) =====================
        KitStockLineRaw AS
        (
            SELECT
                WSLK.WorkOrderMaterialStockLineKitAuditId,
                WSLK.WorkOrderMaterialStockLineKitId,
                DATEADD(SECOND, -@ServerUtcOffsetSec, WSLK.UpdatedDate) AS RawDate,
                DATEADD(SECOND, (DATEDIFF(SECOND, '2000-01-01', DATEADD(SECOND, -@ServerUtcOffsetSec, WSLK.UpdatedDate)) / 10) * 10, CAST('2000-01-01' AS DATETIME2(3))) AS EventBucket,
                CASE WHEN @CurrntEmpTimeZoneDesc IS NULL OR LEN(@CurrntEmpTimeZoneDesc) = 0 THEN DATEADD(SECOND, -@ServerUtcOffsetSec, WSLK.UpdatedDate)
                     ELSE CAST(dbo.ConvertUTCtoLocal(DATEADD(SECOND, -@ServerUtcOffsetSec, WSLK.UpdatedDate), @CurrntEmpTimeZoneDesc) AS DATETIME2(3)) END AS EventDate,
                WSLK.UpdatedBy AS ChangedBy,
                WSLK.CreatedBy AS CreatedByRaw,
                IM4.PartNumber AS PartNumber,
                STK2.StockLineNumber AS StockLineNumber,
                COND3.[Description] AS Condition,
                PROV3.[Description] AS Provision,
                CASE WHEN ISNULL(uomStock4.ShortName, '') = ISNULL(uomConsume4.ShortName, '') THEN ISNULL(WSLK.Quantity, 0)
                     ELSE dbo.fn_ConvertUOM(ISNULL(WSLK.Quantity, 0), uomStock4.ShortName, uomConsume4.ShortName, 0, WSLK.MasterCompanyId) END AS QtyRequested,
                CASE WHEN ISNULL(uomStock4.ShortName, '') = ISNULL(uomConsume4.ShortName, '') THEN ISNULL(WSLK.QtyReserved, 0)
                     ELSE dbo.fn_ConvertUOM(ISNULL(WSLK.QtyReserved, 0), uomStock4.ShortName, uomConsume4.ShortName, 0, WSLK.MasterCompanyId) END AS QtyReserved,
                CASE WHEN ISNULL(uomStock4.ShortName, '') = ISNULL(uomConsume4.ShortName, '') THEN ISNULL(WSLK.QtyIssued, 0)
                     ELSE dbo.fn_ConvertUOM(ISNULL(WSLK.QtyIssued, 0), uomStock4.ShortName, uomConsume4.ShortName, 0, WSLK.MasterCompanyId) END AS QtyIssued,
                CASE WHEN ISNULL(uomStock4.ShortName, '') = ISNULL(uomConsume4.ShortName, '') THEN ISNULL(WSLK.Quantity, 0) - ISNULL(WSLK.QtyIssued, 0)
                     ELSE dbo.fn_ConvertUOM(ISNULL(WSLK.Quantity, 0) - ISNULL(WSLK.QtyIssued, 0), uomStock4.ShortName, uomConsume4.ShortName, 0, WSLK.MasterCompanyId) END AS QtyRemaining,
                WSLK.IsActive AS IsActive,
                WSLK.IsDeleted AS IsDeleted
            FROM [dbo].[WorkOrderMaterialStockLineKitAudit] WSLK WITH (NOLOCK)
            LEFT JOIN [dbo].[ItemMaster] IM4 WITH (NOLOCK) ON IM4.ItemMasterId = WSLK.ItemMasterId
            LEFT JOIN [dbo].[Stockline] STK2 WITH (NOLOCK) ON STK2.StockLineId = WSLK.StockLineId
            LEFT JOIN [dbo].[Condition] COND3 WITH (NOLOCK) ON COND3.ConditionId = WSLK.ConditionId
            LEFT JOIN [dbo].[Provision] PROV3 WITH (NOLOCK) ON PROV3.ProvisionId = WSLK.ProvisionId
            LEFT JOIN [dbo].[UnitOfMeasure] uomStock4 WITH (NOLOCK) ON uomStock4.UnitOfMeasureId = STK2.StockUnitOfMeasureId
            LEFT JOIN [dbo].[UnitOfMeasure] uomConsume4 WITH (NOLOCK) ON uomConsume4.UnitOfMeasureId = STK2.ConsumeUnitOfMeasureId
            WHERE WSLK.WorkOrderMaterialsKitId IN (
                SELECT WorkOrderMaterialsKitId FROM [dbo].[WorkOrderMaterialsKitAudit] WHERE WorkOrderId = @WorkOrderId
                UNION
                SELECT WorkOrderMaterialsKitId FROM [dbo].[WorkOrderMaterialsKit] WITH (NOLOCK) WHERE WorkOrderId = @WorkOrderId
            )
        ),
        KitStockLineLagged AS
        (
            SELECT
                *,
                CHECKSUM(Condition, Provision, QtyRequested, QtyReserved, QtyIssued, IsActive, IsDeleted) AS RowHash,
                LAG(CHECKSUM(Condition, Provision, QtyRequested, QtyReserved, QtyIssued, IsActive, IsDeleted))
                    OVER (PARTITION BY WorkOrderMaterialStockLineKitId ORDER BY WorkOrderMaterialStockLineKitAuditId) AS PrevHash,
                LAG(CHECKSUM(Condition, Provision, QtyRequested, QtyReserved, QtyIssued, IsActive, IsDeleted), 2)
                    OVER (PARTITION BY WorkOrderMaterialStockLineKitId ORDER BY WorkOrderMaterialStockLineKitAuditId) AS PrevPrevHash,
                LAG(RawDate) OVER (PARTITION BY WorkOrderMaterialStockLineKitId ORDER BY WorkOrderMaterialStockLineKitAuditId) AS PrevRawDate,
                LAG(WorkOrderMaterialStockLineKitAuditId) OVER (PARTITION BY WorkOrderMaterialStockLineKitId ORDER BY WorkOrderMaterialStockLineKitAuditId) AS PrevAuditId,
                LAG(Condition) OVER (PARTITION BY WorkOrderMaterialStockLineKitId ORDER BY WorkOrderMaterialStockLineKitAuditId) AS PrevCondition,
                LAG(Provision) OVER (PARTITION BY WorkOrderMaterialStockLineKitId ORDER BY WorkOrderMaterialStockLineKitAuditId) AS PrevProvision,
                LAG(QtyRequested) OVER (PARTITION BY WorkOrderMaterialStockLineKitId ORDER BY WorkOrderMaterialStockLineKitAuditId) AS PrevQtyRequested,
                LAG(QtyReserved) OVER (PARTITION BY WorkOrderMaterialStockLineKitId ORDER BY WorkOrderMaterialStockLineKitAuditId) AS PrevQtyReserved,
                LAG(QtyIssued) OVER (PARTITION BY WorkOrderMaterialStockLineKitId ORDER BY WorkOrderMaterialStockLineKitAuditId) AS PrevQtyIssued,
                LAG(IsActive) OVER (PARTITION BY WorkOrderMaterialStockLineKitId ORDER BY WorkOrderMaterialStockLineKitAuditId) AS PrevIsActive,
                LAG(IsDeleted) OVER (PARTITION BY WorkOrderMaterialStockLineKitId ORDER BY WorkOrderMaterialStockLineKitAuditId) AS PrevIsDeleted
            FROM KitStockLineRaw
        ),
        KitStockLineRows AS
        (
            SELECT
                N'KitStockline' AS Source,
                PartNumber, StockLineNumber,
                CAST(NULL AS VARCHAR(256)) AS Task,
                Condition,
                CAST(NULL AS VARCHAR(256)) AS RequestType,
                Provision, QtyRequested, QtyReserved, QtyIssued, QtyRemaining,
                CAST(NULL AS VARCHAR(256)) AS UOM,
                CAST(NULL AS VARCHAR(256)) AS Shelf,
                CAST(NULL AS VARCHAR(256)) AS Bin,
                IsActive, IsDeleted,
                CAST(NULL AS NVARCHAR(MAX)) AS Memo,
                CAST(NULL AS NVARCHAR(MAX)) AS Notes,
                CAST(NULL AS VARCHAR(MAX)) AS Description,
                STUFF(
                    CASE WHEN PrevHash IS NOT NULL AND ISNULL(Condition, '') <> ISNULL(PrevCondition, '') THEN ',condition' ELSE '' END +
                    CASE WHEN PrevHash IS NOT NULL AND ISNULL(Provision, '') <> ISNULL(PrevProvision, '') THEN ',provision' ELSE '' END +
                    CASE WHEN PrevHash IS NOT NULL AND ISNULL(QtyRequested, -1) <> ISNULL(PrevQtyRequested, -1) THEN ',qtyRequested' ELSE '' END +
                    CASE WHEN PrevHash IS NOT NULL AND ISNULL(QtyReserved, -1) <> ISNULL(PrevQtyReserved, -1) THEN ',qtyReserved' ELSE '' END +
                    CASE WHEN PrevHash IS NOT NULL AND ISNULL(QtyIssued, -1) <> ISNULL(PrevQtyIssued, -1) THEN ',qtyIssued' ELSE '' END +
                    CASE WHEN PrevHash IS NOT NULL AND ISNULL(CAST(IsActive AS INT), -1) <> ISNULL(CAST(PrevIsActive AS INT), -1) THEN ',isActive' ELSE '' END +
                    CASE WHEN PrevHash IS NOT NULL AND ISNULL(CAST(IsDeleted AS INT), -1) <> ISNULL(CAST(PrevIsDeleted AS INT), -1) THEN ',isDeleted' ELSE '' END
                , 1, 1, '') AS ChangedFields,
                EventBucket,
                EventDate,
                CASE WHEN PrevHash IS NULL THEN CreatedByRaw ELSE ChangedBy END AS ChangedBy,
                WorkOrderMaterialStockLineKitAuditId AS RowSeq
            FROM KitStockLineLagged
            WHERE PrevHash IS NULL OR (RowHash <> PrevHash AND NOT (PrevPrevHash IS NOT NULL AND RowHash = PrevPrevHash AND WorkOrderMaterialStockLineKitAuditId = PrevAuditId + 1))
        ),
        -- ===================== ACTIONS (dbo.History narrative log) =====================
        ActionRows AS
        (
            SELECT
                N'Action' AS Source,
                CAST(NULL AS VARCHAR(256)) AS PartNumber,
                CAST(NULL AS VARCHAR(50)) AS StockLineNumber,
                CAST(NULL AS VARCHAR(256)) AS Task,
                CAST(NULL AS VARCHAR(256)) AS Condition,
                CAST(NULL AS VARCHAR(256)) AS RequestType,
                CAST(NULL AS VARCHAR(256)) AS Provision,
                CAST(NULL AS DECIMAL(18, 6)) AS QtyRequested,
                CAST(NULL AS DECIMAL(18, 6)) AS QtyReserved,
                CAST(NULL AS DECIMAL(18, 6)) AS QtyIssued,
                CAST(NULL AS DECIMAL(18, 6)) AS QtyRemaining,
                CAST(NULL AS VARCHAR(256)) AS UOM,
                CAST(NULL AS VARCHAR(256)) AS Shelf,
                CAST(NULL AS VARCHAR(256)) AS Bin,
                CAST(NULL AS BIT) AS IsActive,
                CAST(NULL AS BIT) AS IsDeleted,
                CAST(NULL AS NVARCHAR(MAX)) AS Memo,
                CAST(NULL AS NVARCHAR(MAX)) AS Notes,
                H.HistoryText AS Description,
                CAST(NULL AS VARCHAR(MAX)) AS ChangedFields,
                DATEADD(SECOND, (DATEDIFF(SECOND, '2000-01-01', H.CreatedDate) / 10) * 10, CAST('2000-01-01' AS DATETIME2(3))) AS EventBucket,
                CASE WHEN @CurrntEmpTimeZoneDesc IS NULL OR LEN(@CurrntEmpTimeZoneDesc) = 0 THEN H.CreatedDate
                     ELSE CAST(dbo.ConvertUTCtoLocal(H.CreatedDate, @CurrntEmpTimeZoneDesc) AS DATETIME2(3)) END AS EventDate,
                H.CreatedBy AS ChangedBy,
                H.HistoryId AS RowSeq
            FROM [dbo].[History] H WITH (NOLOCK)
            WHERE H.ModuleId = @WorkOrderModuleId
              AND H.RefferenceId = @WorkOrderId
              AND H.Activity IN (
                    SELECT TemplateText FROM [dbo].[HistoryTemplate] WITH (NOLOCK)
                    WHERE TemplateCode IN ('AddPN', 'AddKit', 'DeleteWorkOrderMaterials', 'DeleteWorkOrderMaterialStockline',
                                            'ReserveParts', 'UnReservedParts', 'IssuedParts', 'UnIssuedParts',
                                            'DeleteKit', 'DeleteKitPart')
              )
        ),
        Combined AS
        (
            SELECT * FROM MaterialRows
            UNION ALL
            SELECT * FROM StockLineRows
            UNION ALL
            SELECT * FROM KitRows
            UNION ALL
            SELECT * FROM KitStockLineRows
            UNION ALL
            SELECT * FROM ActionRows
        )
        SELECT
            Source, PartNumber, StockLineNumber, Task, Condition, RequestType, Provision,
            QtyRequested, QtyReserved, QtyIssued, QtyRemaining, UOM, Shelf, Bin, IsActive, IsDeleted,
            Memo, Notes, Description, ChangedFields, EventDate, ChangedBy
        FROM Combined
        ORDER BY
            -- Primary: a 10-second UTC bucket, so a single save that touches a parent (Material/Kit) and a
            -- child (Stockline/KitStockline) row with slightly different UpdatedDate values (some of the
            -- underlying SPs don't stamp every touched table with the same timestamp) still lands together
            -- instead of appearing "out of sequence".
            CASE WHEN @SortDir = N'ASC'  THEN EventBucket END ASC,
            CASE WHEN @SortDir = N'DESC' THEN EventBucket END DESC,
            -- Secondary: exact timestamp, for ordering distinct events within the same bucket.
            CASE WHEN @SortDir = N'ASC'  THEN EventDate END ASC,
            CASE WHEN @SortDir = N'DESC' THEN EventDate END DESC,
            -- Tertiary tiebreaker for genuine same-EventDate rows only (e.g. a parent Kit/Material row and
            -- its child Stockline/KitStockline row saved in the same instant): keep parent-before-child in
            -- both directions, so it reads the same whether the list is oldest-first or newest-first.
            CASE WHEN @SortDir = N'ASC'
                 THEN CASE Source WHEN N'Action' THEN 0 WHEN N'Material' THEN 1 WHEN N'Kit' THEN 1 WHEN N'Stockline' THEN 2 WHEN N'KitStockline' THEN 2 ELSE 3 END
            END ASC,
            CASE WHEN @SortDir = N'DESC'
                 THEN CASE Source WHEN N'Action' THEN 0 WHEN N'Material' THEN 1 WHEN N'Kit' THEN 1 WHEN N'Stockline' THEN 2 WHEN N'KitStockline' THEN 2 ELSE 3 END
            END DESC,
            CASE WHEN @SortDir = N'ASC'  THEN RowSeq END ASC,
            CASE WHEN @SortDir = N'DESC' THEN RowSeq END DESC;

    END TRY
    BEGIN CATCH

    DECLARE @ErrorLogID INT,
            @DatabaseName VARCHAR(100) = DB_NAME()
            -----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            ,
            @AdhocComments VARCHAR(150) = '[usp_Get_WorkOrderMaterialsCommonHistory]',
            @ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@WorkOrderId, 0) AS VARCHAR(100)) +
            '@Parameter2 = ''' + CAST(ISNULL(@EmployeeId, 0) AS VARCHAR(100)) +
            '@Parameter3 = ''' + CAST(ISNULL(@SortDir, '') AS VARCHAR(100)),
            @ApplicationName VARCHAR(100) = 'PAS'

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
