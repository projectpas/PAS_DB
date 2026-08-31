/*************************************************************
 ** File:   [USP_GetLinkedPOUnlinkEligibility]
 ** Author:   Abhishek Jirawala
 ** Description: This SP is used to get the linked Purchase Order(s) for a
 **              given PO line (@Opr=1), for a given module grid part/line
 **              (@Opr=2), or for every part on a source WO/SO/PO (@Opr=3),
 **              annotated with receipt/reservation eligibility so the
 **              Unlink PO popup can gray out ineligible rows.
 ** Purpose: Feeds the Unlink PO / Unlink All PO popups (line-level and bulk)
 **          on the Work Order Material Grid, Sales Order, and Purchase Order screens.
 ** Date:   26/08/2026

 ** PARAMETERS:
 @Opr INT

 ** RETURN VALUE:
 Flat rowset of linked PO(s) with CanUnlink/CannotUnlinkReasonCode
 (0 none, 1 received, 2 reserved/issued on grid, 3 issued on reference) -
 CanUnlink/CannotUnlinkReason text are computed in C# from the reason code
 to keep the wording in one place (PASMessages).

 **************************************************************
  ** Change History
 **************************************************************
 ** PR   Date         Author				Change Description
 ** --   --------     -------				--------------------------------
    1    26/08/2026   Abhishek Jirawala	Created for Unlink PO feature
    2    26/08/2026   Abhishek Jirawala	Fixed row duplication: the Nha_Tla_Alt_Equ_ItemMapping lookup was an
	                                        unconditional LEFT JOIN on POP.ItemMasterId in both the @Opr=2 branch
	                                        and the final resolve query, so any item with multiple alt/equivalent
	                                        mapping rows multiplied the result set even when WorkOrderMaterialsId
	                                        matched directly and no fallback lookup was needed. Converted the
	                                        @Opr=2 usage to EXISTS and scoped the resolve-query join to only fire
	                                        when WorkOrderMaterialsId IS NULL (matching the wom/womk/swom joins).
    3    27/08/2026   Abhishek Jirawala	Fixed duplicate rows on Sales Order Unlink All: the resolve query's
	                                        wom/womk/swom/sop/esop (and MainNha) fallback lookups were plain LEFT
	                                        JOINs keyed on (ReferenceId, ConditionId, ItemMasterId) with no
	                                        uniqueness guarantee - e.g. a Sales Order with the same part/condition
	                                        on more than one line produced one duplicate row per matching
	                                        SalesOrderPartV1 row. Converted all five to OUTER APPLY ... TOP 1
	                                        ... ORDER BY <PK> so each #Rel row resolves to at most one match.
	                                        Also scoped MainNha to ModuleId = 1 (it's only consumed by wom/womk).
    4    27/08/2026   Abhishek Jirawala	Receiving quantity against a PO must not by itself block Unlink PO -
	                                        only stock actually used against the SPECIFIC target Work Order /
	                                        Sub Work Order should. For ModuleId 1/5, CannotUnlinkReasonCode now
	                                        comes from FN_HasPOStockBeenUsedInTargetReference (reason 6) instead
	                                        of the blanket FN_PurchaseOrderHasAnyReceipt (reason 1). Other modules
	                                        (SO/Exchange/RepairOrder/Lot) keep the blanket check unchanged - no
	                                        verified per-stockline usage mechanism for them yet.
    5    28/08/2026   Abhishek Jirawala	Explicitly CAST QtyReceivedOnLine/GridQtyReserved/GridQtyIssued to
	                                        DECIMAL(18,6) - the UOM branch's quantity standard - instead of relying
	                                        on implicit type inheritance from the source columns, so the Unlink PO
	                                        popup consistently shows the same decimal precision as the rest of the app.

 EXEC USP_GetLinkedPOUnlinkEligibility @Opr = 1, @PurchaseOrderId = 1863, @PurchaseOrderPartRecordId = 100
 EXEC USP_GetLinkedPOUnlinkEligibility @Opr = 2, @SourceModuleId = 1, @ReferenceId = 500, @ReferencePartId = 900, @IsKit = 0
 EXEC USP_GetLinkedPOUnlinkEligibility @Opr = 3, @SourceModuleId = 1, @ReferenceId = 500
 EXEC USP_GetLinkedPOUnlinkEligibility @Opr = 3, @SourceModuleId = 0, @PurchaseOrderId = 1863
**************************************************************/
CREATE PROCEDURE [dbo].[USP_GetLinkedPOUnlinkEligibility]
    @Opr INT,
    @PurchaseOrderId BIGINT = 0,
    @PurchaseOrderPartRecordId BIGINT = 0,
    @SourceModuleId INT = 0,
    @ReferenceId BIGINT = 0,
    @ReferencePartId BIGINT = 0,
    @IsKit BIT = 0,
    @ItemMasterId BIGINT = 0,
    @ConditionId BIGINT = 0
AS
BEGIN
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
    SET NOCOUNT ON
    BEGIN TRY
    BEGIN TRANSACTION

    IF OBJECT_ID('tempdb..#Rel') IS NOT NULL DROP TABLE #Rel
    CREATE TABLE #Rel (
        PurchaseOrderPartReferenceId BIGINT, PurchaseOrderId BIGINT, PurchaseOrderPartId BIGINT,
        ModuleId INT, ReferenceId BIGINT,
        Qty DECIMAL(18,6), RequestedQty DECIMAL(18,6), ReservedQty DECIMAL(18,6), IssuedQty DECIMAL(18,6));

    IF @Opr = 1
    BEGIN
        INSERT INTO #Rel
        SELECT POR.PurchaseOrderPartReferenceId, POR.PurchaseOrderId, POR.PurchaseOrderPartId, POR.ModuleId, POR.ReferenceId,
               ISNULL(POR.Qty,0), ISNULL(POR.RequestedQty,0), ISNULL(POR.ReservedQty,0), ISNULL(POR.IssuedQty,0)
        FROM dbo.PurchaseOrderPartReference POR WITH (NOLOCK)
        WHERE POR.PurchaseOrderId = @PurchaseOrderId AND POR.PurchaseOrderPartId = @PurchaseOrderPartRecordId
              AND ISNULL(POR.IsDeleted,0) = 0 AND ISNULL(POR.IsActive,1) = 1
    END
    ELSE IF @Opr = 2
    BEGIN
        INSERT INTO #Rel
        SELECT POR.PurchaseOrderPartReferenceId, POR.PurchaseOrderId, POR.PurchaseOrderPartId, POR.ModuleId, POR.ReferenceId,
               ISNULL(POR.Qty,0), ISNULL(POR.RequestedQty,0), ISNULL(POR.ReservedQty,0), ISNULL(POR.IssuedQty,0)
        FROM dbo.PurchaseOrderPartReference POR WITH (NOLOCK)
        INNER JOIN dbo.PurchaseOrderPart POP WITH (NOLOCK) ON POP.PurchaseOrderPartRecordId = POR.PurchaseOrderPartId
        WHERE POR.ModuleId = @SourceModuleId AND POR.ReferenceId = @ReferenceId
              AND ISNULL(POR.IsDeleted,0) = 0 AND ISNULL(POR.IsActive,1) = 1 AND ISNULL(POP.IsDeleted,0) = 0
              AND (
                   (POP.WorkOrderMaterialsId = @ReferencePartId AND ISNULL(POP.IsKit,0) = ISNULL(@IsKit,0))
                   OR (POP.WorkOrderMaterialsId IS NULL AND POP.ConditionId = @ConditionId
                       AND (POP.ItemMasterId = @ItemMasterId
                            OR EXISTS (SELECT 1 FROM dbo.Nha_Tla_Alt_Equ_ItemMapping MainNha WITH (NOLOCK)
                                       WHERE MainNha.MappingItemMasterId = @ItemMasterId AND MainNha.ItemMasterId = POP.ItemMasterId)))
                  )
    END
    ELSE -- @Opr = 3
    BEGIN
        INSERT INTO #Rel
        SELECT POR.PurchaseOrderPartReferenceId, POR.PurchaseOrderId, POR.PurchaseOrderPartId, POR.ModuleId, POR.ReferenceId,
               ISNULL(POR.Qty,0), ISNULL(POR.RequestedQty,0), ISNULL(POR.ReservedQty,0), ISNULL(POR.IssuedQty,0)
        FROM dbo.PurchaseOrderPartReference POR WITH (NOLOCK)
        WHERE ISNULL(POR.IsDeleted,0) = 0 AND ISNULL(POR.IsActive,1) = 1
              AND (
                   (@SourceModuleId > 0 AND POR.ModuleId = @SourceModuleId AND POR.ReferenceId = @ReferenceId)
                   OR (@SourceModuleId = 0 AND POR.PurchaseOrderId = @PurchaseOrderId)
                  )
    END

    IF OBJECT_ID('tempdb..#POReceipt') IS NOT NULL DROP TABLE #POReceipt
    SELECT DISTINCT PurchaseOrderId, dbo.FN_PurchaseOrderHasAnyReceipt(PurchaseOrderId) AS HasAnyReceipt
    INTO #POReceipt FROM #Rel

    IF OBJECT_ID('tempdb..#Resolved') IS NOT NULL DROP TABLE #Resolved
    SELECT
        R.PurchaseOrderPartReferenceId, R.PurchaseOrderId, R.PurchaseOrderPartId, R.ModuleId, R.ReferenceId,
        R.Qty, R.RequestedQty, R.ReservedQty AS QtyReserved, R.IssuedQty AS QtyIssued,
        POP.ItemMasterId, POP.PartNumber, POP.PartDescription, POP.ConditionId, POP.Condition,
        ISNULL(POP.IsKit,0) AS IsKit, ISNULL(POP.IsSubWO,0) AS IsSubWO, POP.EstDeliveryDate,
        PO.PurchaseOrderNumber, PO.VendorId, PO.VendorName, PO.StatusId, PO.Status,
        COALESCE(POP.WorkOrderMaterialsId, wom.WorkOrderMaterialsId, womk.WorkOrderMaterialsKitId,
                 swom.SubWorkOrderMaterialsId, sop.SalesOrderPartId, esop.ExchangeSalesOrderPartId) AS ReferencePartId,
        CASE WHEN R.ModuleId = 1 THEN wo.WorkOrderNum
             WHEN R.ModuleId = 2 THEN ro.RepairOrderNumber
             WHEN R.ModuleId = 3 THEN so.SalesOrderNumber
             WHEN R.ModuleId = 4 THEN eso.ExchangeSalesOrderNumber
             WHEN R.ModuleId = 5 THEN sw.SubWorkOrderNo
             WHEN R.ModuleId = 6 THEN l.LotNumber ELSE NULL END AS ReferenceNumber,
        CASE WHEN R.ModuleId = 1 THEN 'Work Order'
             WHEN R.ModuleId = 2 THEN 'Repair Order'
             WHEN R.ModuleId = 3 THEN 'Sales Order'
             WHEN R.ModuleId = 4 THEN 'Exchange'
             WHEN R.ModuleId = 5 THEN 'Sub Work Order'
             WHEN R.ModuleId = 6 THEN 'Lot' ELSE NULL END AS ModuleName,
        CAST(ISNULL((SELECT SUM(Quantity) FROM dbo.Stockline WITH (NOLOCK)
                WHERE PurchaseOrderId = R.PurchaseOrderId
                      AND (PurchaseOrderPartRecordId = POP.PurchaseOrderPartRecordId
                           OR PurchaseOrderPartRecordId IN (SELECT PurchaseOrderPartRecordId FROM dbo.PurchaseOrderPart WITH (NOLOCK) WHERE ParentId = POP.PurchaseOrderPartRecordId))), 0) AS DECIMAL(18,6)) AS QtyReceivedOnLine,
        CAST(ISNULL(wom.QuantityReserved, ISNULL(womk.QuantityReserved, ISNULL(swom.QuantityReserved, ISNULL(sop.QtyReserved,0)))) AS DECIMAL(18,6)) AS GridQtyReserved,
        CAST(ISNULL(wom.QuantityIssued, ISNULL(womk.QuantityIssued, ISNULL(swom.QuantityIssued,0))) AS DECIMAL(18,6)) AS GridQtyIssued,
        PORc.HasAnyReceipt,
        dbo.FN_IsModulePartReservedOrIssued(
            R.ModuleId, R.ReferenceId,
            COALESCE(POP.WorkOrderMaterialsId, wom.WorkOrderMaterialsId, womk.WorkOrderMaterialsKitId,
                     swom.SubWorkOrderMaterialsId, sop.SalesOrderPartId, esop.ExchangeSalesOrderPartId),
            ISNULL(POP.IsKit,0), POP.ItemMasterId, POP.ConditionId) AS IsReserved
    INTO #Resolved
    FROM #Rel R
    INNER JOIN dbo.PurchaseOrderPart POP WITH (NOLOCK) ON POP.PurchaseOrderPartRecordId = R.PurchaseOrderPartId
    INNER JOIN dbo.PurchaseOrder PO WITH (NOLOCK) ON PO.PurchaseOrderId = R.PurchaseOrderId
    INNER JOIN #POReceipt PORc ON PORc.PurchaseOrderId = R.PurchaseOrderId
    OUTER APPLY (
        SELECT TOP 1 * FROM dbo.Nha_Tla_Alt_Equ_ItemMapping WITH (NOLOCK)
        WHERE R.ModuleId = 1 AND POP.WorkOrderMaterialsId IS NULL AND MappingItemMasterId = POP.ItemMasterId
        ORDER BY ItemMappingId
    ) MainNha
    LEFT JOIN dbo.WorkOrder wo WITH (NOLOCK) ON wo.WorkOrderId = R.ReferenceId
    LEFT JOIN dbo.RepairOrder ro WITH (NOLOCK) ON ro.RepairOrderId = R.ReferenceId
    LEFT JOIN dbo.SalesOrder so WITH (NOLOCK) ON so.SalesOrderId = R.ReferenceId
    LEFT JOIN dbo.ExchangeSalesOrder eso WITH (NOLOCK) ON eso.ExchangeSalesOrderId = R.ReferenceId
    LEFT JOIN dbo.SubWorkOrder sw WITH (NOLOCK) ON sw.SubWorkOrderId = R.ReferenceId
    LEFT JOIN dbo.Lot l WITH (NOLOCK) ON l.LotId = R.ReferenceId
    OUTER APPLY (
        SELECT TOP 1 * FROM dbo.WorkOrderMaterials WITH (NOLOCK)
        WHERE R.ModuleId = 1 AND ISNULL(POP.IsKit,0) = 0 AND POP.WorkOrderMaterialsId IS NULL
              AND WorkOrderId = R.ReferenceId AND ConditionCodeId = POP.ConditionId AND (ItemMasterId = POP.ItemMasterId OR ItemMasterId = MainNha.ItemMasterId)
        ORDER BY WorkOrderMaterialsId
    ) wom
    OUTER APPLY (
        SELECT TOP 1 * FROM dbo.WorkOrderMaterialsKit WITH (NOLOCK)
        WHERE R.ModuleId = 1 AND ISNULL(POP.IsKit,0) = 1 AND POP.WorkOrderMaterialsId IS NULL
              AND WorkOrderId = R.ReferenceId AND ConditionCodeId = POP.ConditionId AND (ItemMasterId = POP.ItemMasterId OR ItemMasterId = MainNha.ItemMasterId)
        ORDER BY WorkOrderMaterialsKitId
    ) womk
    OUTER APPLY (
        SELECT TOP 1 * FROM dbo.SubWorkOrderMaterials WITH (NOLOCK)
        WHERE R.ModuleId = 5 AND POP.WorkOrderMaterialsId IS NULL
              AND SubWorkOrderId = R.ReferenceId AND ConditionCodeId = POP.ConditionId AND ItemMasterId = POP.ItemMasterId
        ORDER BY SubWorkOrderMaterialsId
    ) swom
    OUTER APPLY (
        SELECT TOP 1 * FROM dbo.SalesOrderPartV1 WITH (NOLOCK)
        WHERE R.ModuleId = 3
              AND SalesOrderId = R.ReferenceId AND ConditionId = POP.ConditionId AND ItemMasterId = POP.ItemMasterId
        ORDER BY SalesOrderPartId
    ) sop
    OUTER APPLY (
        SELECT TOP 1 * FROM dbo.ExchangeSalesOrderPart WITH (NOLOCK)
        WHERE R.ModuleId = 4
              AND ExchangeSalesOrderId = R.ReferenceId AND ConditionId = POP.ConditionId AND ItemMasterId = POP.ItemMasterId
        ORDER BY ExchangeSalesOrderPartId
    ) esop

    SELECT *,
        CASE
            WHEN ModuleId IN (1,5) AND dbo.FN_HasPOStockBeenUsedInTargetReference(PurchaseOrderId, PurchaseOrderPartId, ModuleId, ReferenceId) = 1 THEN 6
            WHEN ModuleId NOT IN (1,5) AND HasAnyReceipt = 1 THEN 1
            WHEN ISNULL(QtyIssued,0) > 0 THEN 3
            WHEN @SourceModuleId <> 0 AND IsReserved = 1 THEN 2
            ELSE 0
        END AS CannotUnlinkReasonCode
    FROM #Resolved
    ORDER BY PartNumber, PurchaseOrderNumber

    COMMIT TRANSACTION
    END TRY
    BEGIN CATCH
        IF @@trancount > 0
            ROLLBACK TRAN;
        DECLARE @ErrorLogID INT, @DatabaseName VARCHAR(100) = db_name()
            , @AdhocComments VARCHAR(150) = 'USP_GetLinkedPOUnlinkEligibility'
            , @ProcedureParameters VARCHAR(3000) = '@Opr = ' + ISNULL(CAST(@Opr AS VARCHAR(20)), '')
            , @ApplicationName VARCHAR(100) = 'PAS'
        EXEC dbo.spLogException
            @DatabaseName = @DatabaseName
            , @AdhocComments = @AdhocComments
            , @ProcedureParameters = @ProcedureParameters
            , @ApplicationName = @ApplicationName
            , @ErrorLogID = @ErrorLogID OUTPUT;
        RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)
        RETURN(1);
    END CATCH
END
