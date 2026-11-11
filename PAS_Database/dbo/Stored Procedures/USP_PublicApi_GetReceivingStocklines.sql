
/*************************************************************
 ** File:   [USP_PublicApi_GetReceivingStocklines]
 ** Author: Moin Bloch
 ** Description: 4.6 GET /api/v1/receivingpurchaseorders (stocklines). Stocklines received against the POs on one page. Same rows as the PAS receiving screen
 **              (GetStocklineIdsForReceivingPO): not deleted, not created from a work order (IsFinishGood);
 **              only the received stockline itself (IsParent = 1), not its per-unit child rows.
 **              Quantities and unit cost are in the stockline's stock UOM (StockUnitOfMeasureId; Stockline.UnitOfMeasure
 **              can still hold the PO UOM). PoQuantity / PoUnitCost are the received quantity and unit cost converted
 **              back to the PO line's UOM, as in PAS receiving reconciliation (GetReceivingReconciliationPoData).
 ** Purpose: PAS_PUBLIC_API - GET /api/v1/receivingpurchaseorders (stocklines)
 ** Date:   09/11/2026

 ** RETURN VALUE:
 **************************************************************
 ** Change History
 **************************************************************
 ** PR   Date         Author		Change Description
 ** --   --------     -------		--------------------------------
    1    09/11/2026   Moin Bloch    Created

  EXEC [dbo].[USP_PublicApi_GetReceivingStocklines] @MasterCompanyId = 1, @PurchaseOrderIds = '18885'
************************************************************************/
CREATE   PROCEDURE [dbo].[USP_PublicApi_GetReceivingStocklines]
    @MasterCompanyId  INT,
    @PurchaseOrderIds VARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        -- Ids are used by the API to attach stocklines to their PO line; not returned to clients.
        S.[PurchaseOrderId],
        S.[PurchaseOrderPartRecordId] AS [PurchaseOrderPartId],
        S.[StockLineNumber],
        S.[ControlNumber],
        S.[IdNumber],
        S.[SerialNumber],
        S.[Condition],
        S.[Quantity],
        S.[QuantityOnHand],
        S.[QuantityAvailable],
        U.[StockUOM] AS [UnitOfMeasure],
        S.[UnitCost],
        U.[POUOM] AS [PoUnitOfMeasure],
        [dbo].[fn_PublicApi_ConvertUOM](S.[Quantity], U.[StockUOM], U.[POUOM], 0, PO.[MasterCompanyId]) AS [PoQuantity],
        [dbo].[fn_PublicApi_ConvertUOM](S.[UnitCost], U.[StockUOM], U.[POUOM], 1, PO.[MasterCompanyId]) AS [PoUnitCost],
        S.[ReceiverNumber],
        S.[ReceivedDate],
        S.[Site],
        S.[Warehouse],
        S.[Location],
        S.[Shelf],
        S.[Bin],
        S.[TagDate],
        S.[TagType],
        S.[TraceableToName],
        S.[OwnerName],
        S.[ObtainFromName],
        S.[ManufacturerLotNumber],
        S.[ManufacturingDate],
        S.[ExpirationDate],
        S.[CertifiedBy],
        S.[CertifiedDate],
        S.[ShippingReference]
    FROM [dbo].[Stockline] S WITH (NOLOCK)
    INNER JOIN [dbo].[PurchaseOrder] PO WITH (NOLOCK)
        ON PO.[PurchaseOrderId] = S.[PurchaseOrderId] AND PO.[MasterCompanyId] = @MasterCompanyId AND PO.[IsDeleted] = 0
    LEFT JOIN [dbo].[PurchaseOrderPart] POP WITH (NOLOCK)
        ON POP.[PurchaseOrderPartRecordId] = S.[PurchaseOrderPartRecordId] AND POP.[PurchaseOrderId] = S.[PurchaseOrderId]
    LEFT JOIN [dbo].[UnitOfMeasure] SU WITH (NOLOCK) ON SU.[UnitOfMeasureId] = S.[StockUnitOfMeasureId]
    LEFT JOIN [dbo].[UnitOfMeasure] PU WITH (NOLOCK) ON PU.[UnitOfMeasureId] = POP.[UOMId]
    -- Older stocklines have no stock UOM yet; their quantity is in Stockline.UnitOfMeasure.
    CROSS APPLY (SELECT ISNULL(SU.[ShortName], NULLIF(S.[UnitOfMeasure], '')) AS [StockUOM],
                        ISNULL(PU.[ShortName], NULLIF(POP.[UnitOfMeasure], '')) AS [POUOM]) U
    WHERE S.[PurchaseOrderId] IN (SELECT TRY_CAST([value] AS BIGINT) FROM STRING_SPLIT(@PurchaseOrderIds, ','))
      AND S.[IsDeleted] = 0
      AND ISNULL(S.[IsFinishGood], 0) = 0
      AND S.[IsParent] = 1
    ORDER BY S.[PurchaseOrderId], S.[PurchaseOrderPartRecordId], S.[StockLineId];
END