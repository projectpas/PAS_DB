
/*************************************************************
 ** File:   [USP_PublicApi_GetSalesOrderStocklines]
 ** Author: Moin Bloch
 ** Description: 4.10 Stocklines selected for the part lines of the SOs on one page, with their sale price.
 ** Purpose: PAS_PUBLIC_API - GET /api/v1/salesorders (parts[].stocklines)
 ** Date:   09/11/2026

 ** RETURN VALUE:
 **************************************************************
 ** Change History
 **************************************************************
 ** PR   Date         Author		Change Description
 ** --   --------     -------		--------------------------------
    1    09/11/2026   Moin Bloch    Created

  EXEC [dbo].[USP_PublicApi_GetSalesOrderStocklines] @MasterCompanyId = 1, @SalesOrderIds = '679'
************************************************************************/
CREATE   PROCEDURE [dbo].[USP_PublicApi_GetSalesOrderStocklines]
    @MasterCompanyId INT,
    @SalesOrderIds   VARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        -- Id is used by the API to attach the stockline to its part line; not returned to clients.
        STK.[SalesOrderPartId],
        SL.[StockLineNumber],
        SL.[ControlNumber],
        SL.[IdNumber],
        SL.[SerialNumber],
        ISNULL(NULLIF(STK.[ConditionName], ''), SL.[Condition]) AS [Condition],
        STK.[StatusName] AS [Status],
        -- Quantities and unit price / cost in the stockline's consume UOM (stored in its stock UOM), like the PAS parts list.
        CU.[ShortName] AS [UnitOfMeasure],
        [dbo].[fn_PublicApi_ConvertUOM](ISNULL(STK.[QtyOrder], 0), SU.[ShortName], CU.[ShortName], 0, SO.[MasterCompanyId]) AS [QuantityOrdered],
        [dbo].[fn_PublicApi_ConvertUOM](ISNULL(STK.[QtyReserved], 0), SU.[ShortName], CU.[ShortName], 0, SO.[MasterCompanyId]) AS [QuantityReserved],
        [dbo].[fn_PublicApi_ConvertUOM](ISNULL(SL.[QuantityOnHand], 0), SU.[ShortName], CU.[ShortName], 0, SO.[MasterCompanyId]) AS [QuantityOnHand],
        [dbo].[fn_PublicApi_ConvertUOM](ISNULL(SL.[QuantityAvailable], 0), SU.[ShortName], CU.[ShortName], 0, SO.[MasterCompanyId]) AS [QuantityAvailable],
        [dbo].[fn_PublicApi_ConvertUOM](SC.[UnitSalesPrice], SU.[ShortName], CU.[ShortName], 1, SO.[MasterCompanyId]) AS [UnitSalesPrice],
        SC.[UnitSalesPriceExtended],
        [dbo].[fn_PublicApi_ConvertUOM](SC.[UnitCost], SU.[ShortName], CU.[ShortName], 1, SO.[MasterCompanyId]) AS [UnitCost],
        SC.[UnitCostExtended],
        SC.[MarkUpPercentage],
        SC.[DiscountPercentage],
        SC.[DiscountAmount],
        SC.[MarginPercentage],
        SC.[MarginAmount],
        SC.[NetSaleAmount],
        STK.[CustomerRequestDate],
        STK.[PromisedDate],
        STK.[EstimatedShipDate],
        SL.[Site],
        SL.[Warehouse],
        SL.[Location],
        SL.[Shelf],
        SL.[Bin]
    FROM [dbo].[SalesOrderStocklineV1] STK WITH (NOLOCK)
    INNER JOIN [dbo].[SalesOrderPartV1] SOP WITH (NOLOCK) ON SOP.[SalesOrderPartId] = STK.[SalesOrderPartId] AND SOP.[IsDeleted] = 0
    INNER JOIN [dbo].[SalesOrder] SO WITH (NOLOCK)
        ON SO.[SalesOrderId] = SOP.[SalesOrderId] AND SO.[MasterCompanyId] = @MasterCompanyId AND SO.[IsDeleted] = 0
    LEFT JOIN [dbo].[Stockline] SL WITH (NOLOCK) ON SL.[StockLineId] = STK.[StockLineId]
    LEFT JOIN [dbo].[UnitOfMeasure] SU WITH (NOLOCK) ON SU.[UnitOfMeasureId] = SL.[StockUnitOfMeasureId]
    LEFT JOIN [dbo].[UnitOfMeasure] CU WITH (NOLOCK) ON CU.[UnitOfMeasureId] = SL.[ConsumeUnitOfMeasureId]
    OUTER APPLY (SELECT TOP (1) C.* FROM [dbo].[SalesOrderStockLineCost] C WITH (NOLOCK)
                 WHERE C.[SalesOrderStocklineId] = STK.[SalesOrderStocklineId] AND C.[IsDeleted] = 0
                 ORDER BY C.[SalesOrderStockLineCostId] DESC) SC
    WHERE SOP.[SalesOrderId] IN (SELECT TRY_CAST([value] AS BIGINT) FROM STRING_SPLIT(@SalesOrderIds, ','))
      AND STK.[IsDeleted] = 0
    ORDER BY SOP.[SalesOrderId], STK.[SalesOrderPartId], STK.[SalesOrderStocklineId];
END