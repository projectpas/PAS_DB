
---------------------------------------------------------------------------------------------
-- 4.3 GET /api/v1/purchaseorders (part lines). Part lines of the POs on one page (@PurchaseOrderIds = comma separated ids, max one page).
-- Main lines have isParent = 1; split shipment lines have ParentId set.
-- POs of another company are ignored.
---------------------------------------------------------------------------------------------
CREATE   PROCEDURE [dbo].[USP_PublicApi_GetPurchaseOrderParts]
    @MasterCompanyId  INT,
    @PurchaseOrderIds VARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        -- Ids are used by the API to group lines per PO and nest split lines; not returned to clients.
        P.[PurchaseOrderId],
        P.[PurchaseOrderPartRecordId] AS [PurchaseOrderPartId],
        CASE WHEN ISNULL(P.[isParent], 0) = 1 THEN NULL ELSE NULLIF(P.[ParentId], 0) END AS [ParentPurchaseOrderPartId],
        P.[PartNumber],
        P.[PartDescription],
        P.[ManufacturerPN] AS [ManufacturerPartNumber],
        P.[Manufacturer],
        P.[AltEquiPartNumber],
        P.[ItemType],
        P.[StockType],
        P.[Condition],
        P.[UnitOfMeasure],
        P.[Priority],
        P.[NeedByDate],
        P.[EstDeliveryDate],
        ISNULL(P.[QuantityOrdered], 0) AS [QuantityOrdered],
        ISNULL(P.[QuantityReceived], 0) AS [QuantityReceived],
        ISNULL(P.[QuantityBackOrdered], 0) AS [QuantityBackOrdered],
        ISNULL(P.[QuantityRejected], 0) AS [QuantityRejected],
        P.[VendorListPrice],
        P.[DiscountPercentValue] AS [DiscountPercent],
        P.[DiscountPerUnit],
        P.[DiscountAmount],
        P.[UnitCost],
        P.[ExtendedCost],
        P.[FunctionalCurrency],
        P.[WorkOrderNo],
        P.[SubWorkOrderNo],
        P.[ReapairOrderNo] AS [RepairOrderNo],
        P.[SalesOrderNo]
    FROM [dbo].[PurchaseOrderPart] P WITH (NOLOCK)
    INNER JOIN [dbo].[PurchaseOrder] PO WITH (NOLOCK)
        ON PO.[PurchaseOrderId] = P.[PurchaseOrderId] AND PO.[MasterCompanyId] = @MasterCompanyId AND PO.[IsDeleted] = 0
    WHERE P.[PurchaseOrderId] IN (SELECT TRY_CAST([value] AS BIGINT) FROM STRING_SPLIT(@PurchaseOrderIds, ','))
      AND ISNULL(P.[IsDeleted], 0) = 0
    ORDER BY P.[PurchaseOrderId], ISNULL(NULLIF(P.[ParentId], 0), P.[PurchaseOrderPartRecordId]), P.[PurchaseOrderPartRecordId];
END