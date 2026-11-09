
---------------------------------------------------------------------------------------------
-- 4.5 GET /api/v1/receivingpurchaseorders (lines). Receivable lines of the POs on one page (@PurchaseOrderIds = comma separated ids, max one page).
-- Like the PAS receiving screen: a line split into separate deliveries is received per delivery,
-- so the split lines are returned and their main line is not.
-- QuantityReceived follows PAS: stock / non-stock = PurchaseOrderPart.QuantityReceived,
-- asset = created asset inventory drafts, other types = created stockline drafts.
---------------------------------------------------------------------------------------------
CREATE   PROCEDURE [dbo].[USP_PublicApi_GetReceivingPurchaseOrderParts]
    @MasterCompanyId  INT,
    @PurchaseOrderIds VARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        -- Ids are used by the API to group lines per PO and attach stocklines; not returned to clients.
        P.[PurchaseOrderId],
        P.[PurchaseOrderPartRecordId] AS [PurchaseOrderPartId],
        CASE WHEN ISNULL(P.[isParent], 0) = 1 THEN NULL ELSE NULLIF(P.[ParentId], 0) END AS [ParentPurchaseOrderPartId],
        CAST(CASE WHEN ISNULL(P.[isParent], 0) = 0 AND ISNULL(P.[ParentId], 0) > 0 THEN 1 ELSE 0 END AS BIT) AS [IsSplitShipment],
        P.[PartNumber],
        P.[PartDescription],
        P.[ManufacturerPN] AS [ManufacturerPartNumber],
        P.[Manufacturer],
        P.[AltEquiPartNumber],
        CASE WHEN P.[ItemTypeId] = 1 AND ISNULL(ITM.[IsAsset], 0) = 1 THEN 'Asset' ELSE P.[ItemType] END AS [ItemType],
        P.[StockType],
        P.[Condition],
        P.[UnitOfMeasure],
        CAST(ISNULL(CASE WHEN P.[ItemTypeId] = 1 THEN ITM.[isSerialized] WHEN P.[ItemTypeId] = 2 THEN NSI.[IsSerialized] ELSE ASI.[IsSerialized] END, 0) AS BIT) AS [IsSerialized],
        P.[NeedByDate],
        P.[EstDeliveryDate],
        ISNULL(P.[QuantityOrdered], 0) AS [QuantityOrdered],
        R.[QuantityReceived],
        CASE WHEN ISNULL(P.[QuantityOrdered], 0) > R.[QuantityReceived] THEN ISNULL(P.[QuantityOrdered], 0) - R.[QuantityReceived] ELSE 0 END AS [QuantityPending],
        ISNULL(P.[QuantityRejected], 0) AS [QuantityRejected],
        P.[UnitCost],
        P.[ExtendedCost],
        P.[FunctionalCurrency]
    FROM [dbo].[PurchaseOrderPart] P WITH (NOLOCK)
    INNER JOIN [dbo].[PurchaseOrder] PO WITH (NOLOCK)
        ON PO.[PurchaseOrderId] = P.[PurchaseOrderId] AND PO.[MasterCompanyId] = @MasterCompanyId AND PO.[IsDeleted] = 0
    LEFT JOIN [dbo].[ItemMaster] ITM WITH (NOLOCK) ON ITM.[ItemMasterId] = P.[ItemMasterId] AND ISNULL(ITM.[IsNonStock], 0) = 0
    LEFT JOIN [dbo].[ItemMaster] NSI WITH (NOLOCK) ON NSI.[ItemMasterId] = P.[ItemMasterId] AND ISNULL(NSI.[IsNonStock], 0) = 1
    LEFT JOIN [dbo].[Asset] ASI WITH (NOLOCK) ON ASI.[AssetRecordId] = P.[ItemMasterId]
    CROSS APPLY (
        SELECT CASE
            WHEN P.[ItemTypeId] IN (1, 2) THEN ISNULL(P.[QuantityReceived], 0)
            WHEN P.[ItemTypeId] = 11 THEN (
                SELECT ISNULL(SUM(D.[Qty]), 0) FROM [dbo].[AssetInventoryDraft] D WITH (NOLOCK)
                WHERE D.[AssetInventoryId] > 0 AND ISNULL(D.[IsParent], 0) = 0 AND D.[isDeleted] = 0
                  AND D.[PurchaseOrderPartRecordId] = P.[PurchaseOrderPartRecordId] AND D.[PurchaseOrderId] = P.[PurchaseOrderId])
            ELSE (
                SELECT ISNULL(SUM(D.[Quantity]), 0) FROM [dbo].[StocklineDraft] D WITH (NOLOCK)
                WHERE D.[StockLineId] > 0 AND ISNULL(D.[IsNonStock], 0) = 0 AND D.[isDeleted] = 0
                  AND D.[PurchaseOrderPartRecordId] = P.[PurchaseOrderPartRecordId] AND D.[PurchaseOrderId] = P.[PurchaseOrderId])
        END AS [QuantityReceived]
    ) R
    WHERE P.[PurchaseOrderId] IN (SELECT TRY_CAST([value] AS BIGINT) FROM STRING_SPLIT(@PurchaseOrderIds, ','))
      AND ISNULL(P.[IsDeleted], 0) = 0
      AND NOT EXISTS (SELECT 1 FROM [dbo].[PurchaseOrderPart] C WITH (NOLOCK)
                      WHERE C.[PurchaseOrderId] = P.[PurchaseOrderId] AND C.[ParentId] = P.[PurchaseOrderPartRecordId])
    ORDER BY P.[PurchaseOrderId], ISNULL(NULLIF(P.[ParentId], 0), P.[PurchaseOrderPartRecordId]), P.[PurchaseOrderPartRecordId];
END