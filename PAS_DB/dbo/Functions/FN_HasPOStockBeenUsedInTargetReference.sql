-- =============================================
-- Author:		Abhishek Jirawala
-- Create date: 27 Aug 2026
-- Description:	Unlink PO - returns 1 if any stockline that was received
--              against (@PurchaseOrderId, @PurchaseOrderPartId) has actually
--              been reserved or issued against the SPECIFIC target reference
--              (@ModuleId, @ReferenceId) - e.g. Work Order 123 - as opposed to
--              FN_PurchaseOrderHasAnyReceipt, which only checks whether the PO
--              has been received AT ALL, anywhere. Receiving quantity against
--              a PO must not by itself block unlinking; only stock that was
--              actually consumed against the WO being unlinked should.
--              Traces via the authoritative per-stockline junction tables
--              (WorkOrderMaterialStockLine / ...Kit, SubWorkOrderMaterialStockLine
--              / ...Kit) rather than Stockline.WorkOrderId/WorkOrderMaterialsId,
--              since those columns are denormalized "last touched" pointers
--              that get overwritten on every subsequent reserve/issue/
--              un-reserve/un-issue call and are never cleared back to NULL -
--              they cannot answer "was this ever used against WO X".
--              Only ModuleId 1 (WorkOrder) and 5 (SubWorkOrder) have a
--              verified per-stockline usage mechanism today; other modules
--              return 0 here and keep using the blanket
--              FN_PurchaseOrderHasAnyReceipt check at the call site.
-- =============================================
/*************************************************************
** Change History
**************************************************************
** PR   Date         Author				Change Description
** --   --------     -------				--------------------------------
    1    27/Aug/2026   Abhishek Jirawala	Created for Unlink PO feature

SELECT dbo.FN_HasPOStockBeenUsedInTargetReference(1863, 100, 1, 500)
**************************************************************/
CREATE FUNCTION [dbo].[FN_HasPOStockBeenUsedInTargetReference]
(
    @PurchaseOrderId BIGINT,
    @PurchaseOrderPartId BIGINT,
    @ModuleId INT,
    @ReferenceId BIGINT
)
RETURNS BIT
AS
BEGIN
    DECLARE @Used BIT = 0

    IF @ModuleId = 1 -- WorkOrder
    BEGIN
        IF EXISTS (
            SELECT 1
            FROM [dbo].[Stockline] SL WITH (NOLOCK)
            INNER JOIN [dbo].[WorkOrderMaterialStockLine] WOMS WITH (NOLOCK) ON WOMS.StockLineId = SL.StockLineId
            INNER JOIN [dbo].[WorkOrderMaterials] WOM WITH (NOLOCK) ON WOM.WorkOrderMaterialsId = WOMS.WorkOrderMaterialsId
            WHERE SL.PurchaseOrderId = @PurchaseOrderId AND SL.PurchaseOrderPartRecordId = @PurchaseOrderPartId
                  AND WOM.WorkOrderId = @ReferenceId AND ISNULL(WOMS.IsDeleted,0) = 0
                  AND (ISNULL(WOMS.QtyReserved,0) > 0 OR ISNULL(WOMS.QtyIssued,0) > 0)
        )
            SET @Used = 1

        IF @Used = 0 AND EXISTS (
            SELECT 1
            FROM [dbo].[Stockline] SL WITH (NOLOCK)
            INNER JOIN [dbo].[WorkOrderMaterialStockLineKit] WOMSK WITH (NOLOCK) ON WOMSK.StockLineId = SL.StockLineId
            INNER JOIN [dbo].[WorkOrderMaterialsKit] WOMK WITH (NOLOCK) ON WOMK.WorkOrderMaterialsKitId = WOMSK.WorkOrderMaterialsKitId
            WHERE SL.PurchaseOrderId = @PurchaseOrderId AND SL.PurchaseOrderPartRecordId = @PurchaseOrderPartId
                  AND WOMK.WorkOrderId = @ReferenceId AND ISNULL(WOMSK.IsDeleted,0) = 0
                  AND (ISNULL(WOMSK.QtyReserved,0) > 0 OR ISNULL(WOMSK.QtyIssued,0) > 0)
        )
            SET @Used = 1
    END
    ELSE IF @ModuleId = 5 -- SubWorkOrder
    BEGIN
        IF EXISTS (
            SELECT 1
            FROM [dbo].[Stockline] SL WITH (NOLOCK)
            INNER JOIN [dbo].[SubWorkOrderMaterialStockLine] SWOMS WITH (NOLOCK) ON SWOMS.StockLIneId = SL.StockLineId
            INNER JOIN [dbo].[SubWorkOrderMaterials] SWOM WITH (NOLOCK) ON SWOM.SubWorkOrderMaterialsId = SWOMS.SubWorkOrderMaterialsId
            WHERE SL.PurchaseOrderId = @PurchaseOrderId AND SL.PurchaseOrderPartRecordId = @PurchaseOrderPartId
                  AND SWOM.SubWorkOrderId = @ReferenceId AND ISNULL(SWOMS.IsDeleted,0) = 0
                  AND (ISNULL(SWOMS.QtyReserved,0) > 0 OR ISNULL(SWOMS.QtyIssued,0) > 0)
        )
            SET @Used = 1

        IF @Used = 0 AND EXISTS (
            SELECT 1
            FROM [dbo].[Stockline] SL WITH (NOLOCK)
            INNER JOIN [dbo].[SubWorkOrderMaterialStockLineKit] SWOMSK WITH (NOLOCK) ON SWOMSK.StockLIneId = SL.StockLineId
            INNER JOIN [dbo].[SubWorkOrderMaterialsKit] SWOMK WITH (NOLOCK) ON SWOMK.SubWorkOrderMaterialsKitId = SWOMSK.SubWorkOrderMaterialsKitId
            WHERE SL.PurchaseOrderId = @PurchaseOrderId AND SL.PurchaseOrderPartRecordId = @PurchaseOrderPartId
                  AND SWOMK.SubWorkOrderId = @ReferenceId AND ISNULL(SWOMSK.IsDeleted,0) = 0
                  AND (ISNULL(SWOMSK.QtyReserved,0) > 0 OR ISNULL(SWOMSK.QtyIssued,0) > 0)
        )
            SET @Used = 1
    END
    -- other modules: no verified per-stockline mechanism yet, caller falls back to FN_PurchaseOrderHasAnyReceipt

    RETURN @Used
END
