
---------------------------------------------------------------------------------------------
-- 4.11 Shipments of the SOs on one page: one row per shipped item (a shipment without items gives
-- one row with empty item columns). The API groups the rows per shipment.
---------------------------------------------------------------------------------------------
CREATE   PROCEDURE [dbo].[USP_PublicApi_GetSalesOrderShipping]
    @MasterCompanyId INT,
    @SalesOrderIds   VARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        -- Ids are used by the API to group items per shipment and shipment per SO; not returned to clients.
        S.[SalesOrderId],
        S.[SalesOrderShippingId],
        S.[SOShippingNum] AS [ShippingNumber],
        SS.[Status] AS [Status],
        S.[OpenDate],
        S.[ShipDate],
        SV.[Name] AS [ShipVia],
        S.[ServiceClass],
        S.[ShippingAccountNo],
        S.[AirwayBill],
        S.[HouseAirwayBill],
        S.[TrackingNum] AS [TrackingNumber],
        S.[NoOfContainer] AS [NumberOfContainers],
        S.[Weight],
        S.[ShipSizeLength],
        S.[ShipSizeWidth],
        S.[ShipSizeHeight],
        I.[SalesOrderShippingItemId],
        PT.[SOPickTicketNumber] AS [PickTicketNumber],
        ISNULL(NULLIF(SOP.[PartNumber], ''), IM.[partnumber]) AS [PartNumber],
        ISNULL(NULLIF(SOP.[PartDescription], ''), IM.[PartDescription]) AS [PartDescription],
        SOP.[ConditionName] AS [Condition],
        SL.[StockLineNumber],
        SL.[SerialNumber],
        -- Quantity in the item's consume UOM (stored in its stock UOM), like the PAS Shipping tab.
        CU.[ShortName] AS [UnitOfMeasure],
        [dbo].[fn_PublicApi_ConvertUOM](I.[QtyShipped], SU.[ShortName], CU.[ShortName], 0, SO.[MasterCompanyId]) AS [QuantityShipped]
    FROM [dbo].[SalesOrderShipping] S WITH (NOLOCK)
    INNER JOIN [dbo].[SalesOrder] SO WITH (NOLOCK)
        ON SO.[SalesOrderId] = S.[SalesOrderId] AND SO.[MasterCompanyId] = @MasterCompanyId AND SO.[IsDeleted] = 0
    LEFT JOIN [dbo].[ShippingStatus] SS WITH (NOLOCK) ON SS.[ShippingStatusId] = S.[SOShippingStatusId]
    LEFT JOIN [dbo].[ShippingVia] SV WITH (NOLOCK) ON SV.[ShippingViaId] = S.[ShipViaId]
    LEFT JOIN [dbo].[SalesOrderShippingItem] I WITH (NOLOCK) ON I.[SalesOrderShippingId] = S.[SalesOrderShippingId] AND I.[IsDeleted] = 0
    LEFT JOIN [dbo].[SOPickTicket] PT WITH (NOLOCK) ON PT.[SOPickTicketId] = I.[SOPickTicketId]
    LEFT JOIN [dbo].[SalesOrderPartV1] SOP WITH (NOLOCK) ON SOP.[SalesOrderId] = S.[SalesOrderId] AND SOP.[SalesOrderPartId] = I.[SalesOrderPartId]
    LEFT JOIN [dbo].[ItemMaster] IM WITH (NOLOCK) ON IM.[ItemMasterId] = SOP.[ItemMasterId]
    LEFT JOIN [dbo].[UnitOfMeasure] SU WITH (NOLOCK) ON SU.[UnitOfMeasureId] = IM.[StockUnitOfMeasureId]
    LEFT JOIN [dbo].[UnitOfMeasure] CU WITH (NOLOCK) ON CU.[UnitOfMeasureId] = IM.[ConsumeUnitOfMeasureId]
    LEFT JOIN [dbo].[SalesOrderStocklineV1] STK WITH (NOLOCK) ON STK.[SalesOrderStocklineId] = PT.[SalesOrderPartStocklineId]
    LEFT JOIN [dbo].[Stockline] SL WITH (NOLOCK) ON SL.[StockLineId] = STK.[StockLineId]
    WHERE S.[SalesOrderId] IN (SELECT TRY_CAST([value] AS BIGINT) FROM STRING_SPLIT(@SalesOrderIds, ','))
      AND S.[IsDeleted] = 0
    ORDER BY S.[SalesOrderId], S.[SalesOrderShippingId], I.[SalesOrderShippingItemId];
END