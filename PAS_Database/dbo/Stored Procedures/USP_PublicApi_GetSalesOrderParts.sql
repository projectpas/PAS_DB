
---------------------------------------------------------------------------------------------
-- 4.9 Part lines of the SOs on one page (@SalesOrderIds = comma separated ids, max one page).
-- QuantityShipped = shipped items; QuantityInvoiced = billed qty on standard (not proforma) invoices.
-- UOM: quantities and unit price / cost are converted from the stock UOM (as stored) to the consume
-- (sell) UOM with fn_PublicApi_ConvertUOM (4.4), like the PAS screens (also in 4.10 - 4.12). Totals are not converted.
---------------------------------------------------------------------------------------------
CREATE   PROCEDURE [dbo].[USP_PublicApi_GetSalesOrderParts]
    @MasterCompanyId INT,
    @SalesOrderIds   VARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @SOModuleId INT = (SELECT TOP (1) [ModuleId] FROM [dbo].[Module] WITH (NOLOCK) WHERE [ModuleName] = 'SalesOrder');

    SELECT
        -- Ids are used by the API to group lines per SO and attach stocklines; not returned to clients.
        SOP.[SalesOrderId],
        SOP.[SalesOrderPartId],
        ISNULL(NULLIF(SOP.[PartNumber], ''), IM.[partnumber]) AS [PartNumber],
        ISNULL(NULLIF(SOP.[PartDescription], ''), IM.[PartDescription]) AS [PartDescription],
        IM.[ManufacturerName] AS [Manufacturer],
        SOP.[AltOrEqType] AS [AlternateType],
        SOP.[ConditionName] AS [Condition],
        SOP.[PriorityName] AS [Priority],
        SOP.[StatusName] AS [Status],
        SOP.[CustomerRequestDate],
        SOP.[PromisedDate],
        SOP.[EstimatedShipDate],
        SOP.[PONumber] AS [PurchaseOrderNumber],
        -- Quantities and unit price / cost in the consume UOM (stored in the stock UOM), like the PAS parts list.
        CU.[ShortName] AS [UnitOfMeasure],
        [dbo].[fn_PublicApi_ConvertUOM](ISNULL(SOP.[QtyRequested], 0), SU.[ShortName], CU.[ShortName], 0, SO.[MasterCompanyId]) AS [QuantityRequested],
        [dbo].[fn_PublicApi_ConvertUOM](ISNULL(SOP.[QtyOrder], 0), SU.[ShortName], CU.[ShortName], 0, SO.[MasterCompanyId]) AS [QuantityOrdered],
        [dbo].[fn_PublicApi_ConvertUOM](ISNULL(SOP.[QtyReserved], 0), SU.[ShortName], CU.[ShortName], 0, SO.[MasterCompanyId]) AS [QuantityReserved],
        [dbo].[fn_PublicApi_ConvertUOM](ISNULL(SH.[QuantityShipped], 0), SU.[ShortName], CU.[ShortName], 0, SO.[MasterCompanyId]) AS [QuantityShipped],
        [dbo].[fn_PublicApi_ConvertUOM](ISNULL(BI.[QuantityInvoiced], 0), SU.[ShortName], CU.[ShortName], 0, SO.[MasterCompanyId]) AS [QuantityInvoiced],
        CUR.[Code] AS [Currency],
        [dbo].[fn_PublicApi_ConvertUOM](PC.[UnitSalesPrice], SU.[ShortName], CU.[ShortName], 1, SO.[MasterCompanyId]) AS [UnitSalesPrice],
        PC.[UnitSalesPriceExtended],
        [dbo].[fn_PublicApi_ConvertUOM](PC.[UnitCost], SU.[ShortName], CU.[ShortName], 1, SO.[MasterCompanyId]) AS [UnitCost],
        PC.[UnitCostExtended],
        PC.[MarkUpPercentage],
        PC.[MarkUpAmount],
        PC.[DiscountPercentage],
        PC.[DiscountAmount],
        PC.[MarginPercentage],
        PC.[MarginAmount],
        PC.[TaxPercentage],
        PC.[TaxAmount],
        PC.[GrossSaleAmount],
        PC.[NetSaleAmount],
        PC.[MiscCharges],
        PC.[Freight],
        PC.[TotalRevenue],
        SOP.[ECCN],
        SOP.[HSCODE] AS [HsCode],
        SOP.[Weight]
    FROM [dbo].[SalesOrderPartV1] SOP WITH (NOLOCK)
    INNER JOIN [dbo].[SalesOrder] SO WITH (NOLOCK)
        ON SO.[SalesOrderId] = SOP.[SalesOrderId] AND SO.[MasterCompanyId] = @MasterCompanyId AND SO.[IsDeleted] = 0
    LEFT JOIN [dbo].[ItemMaster] IM WITH (NOLOCK) ON IM.[ItemMasterId] = SOP.[ItemMasterId]
    LEFT JOIN [dbo].[UnitOfMeasure] SU WITH (NOLOCK) ON SU.[UnitOfMeasureId] = IM.[StockUnitOfMeasureId]
    LEFT JOIN [dbo].[UnitOfMeasure] CU WITH (NOLOCK) ON CU.[UnitOfMeasureId] = IM.[ConsumeUnitOfMeasureId]
    LEFT JOIN [dbo].[Currency] CUR WITH (NOLOCK) ON CUR.[CurrencyId] = SOP.[CurrencyId]
    OUTER APPLY (SELECT TOP (1) C.* FROM [dbo].[SalesOrderPartCost] C WITH (NOLOCK)
                 WHERE C.[SalesOrderPartId] = SOP.[SalesOrderPartId] AND C.[IsDeleted] = 0
                 ORDER BY C.[SalesOrderPartCostId] DESC) PC
    OUTER APPLY (SELECT SUM(I.[QtyShipped]) AS [QuantityShipped]
                 FROM [dbo].[SalesOrderShippingItem] I WITH (NOLOCK)
                 INNER JOIN [dbo].[SalesOrderShipping] S WITH (NOLOCK) ON S.[SalesOrderShippingId] = I.[SalesOrderShippingId] AND S.[IsDeleted] = 0
                 WHERE S.[SalesOrderId] = SOP.[SalesOrderId] AND I.[SalesOrderPartId] = SOP.[SalesOrderPartId] AND I.[IsDeleted] = 0) SH
    OUTER APPLY (SELECT SUM(I.[QtyBilled]) AS [QuantityInvoiced]
                 FROM [dbo].[BillingInvoicingItems] I WITH (NOLOCK)
                 INNER JOIN [dbo].[BillingInvoicing] B WITH (NOLOCK) ON B.[BillingInvoicingId] = I.[BillingInvoicingId]
                 WHERE B.[ModuleId] = @SOModuleId AND B.[ReferenceId] = SOP.[SalesOrderId] AND B.[IsDeleted] = 0
                   AND ISNULL(B.[IsPerformaInvoice], 0) = 0 AND ISNULL(B.[IsVersionIncrease], 0) = 0
                   AND I.[SubReferenceId] = SOP.[SalesOrderPartId] AND I.[IsDeleted] = 0
                   AND ISNULL(I.[IsPerformaInvoice], 0) = 0 AND ISNULL(I.[IsVersionIncrease], 0) = 0) BI
    WHERE SOP.[SalesOrderId] IN (SELECT TRY_CAST([value] AS BIGINT) FROM STRING_SPLIT(@SalesOrderIds, ','))
      AND SOP.[IsDeleted] = 0
    ORDER BY SOP.[SalesOrderId], ISNULL(SOP.[SequenceNumber], SOP.[SalesOrderPartId]), SOP.[SalesOrderPartId];
END