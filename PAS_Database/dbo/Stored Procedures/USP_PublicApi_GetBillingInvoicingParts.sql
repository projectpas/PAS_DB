/*************************************************************
 ** File:   [USP_PublicApi_GetBillingInvoicingParts]
 ** Author: Moin Bloch
 ** Description: 4.30 Invoice lines (MPN) of the invoices on one page. @BillingInvoicingIds: WO and SO invoices,
 **              @ExchangeInvoicingIds: exchange invoices (both comma separated).
 **              Revenue per line as on the PAS billing screen:
 **                WO: material / labor / charges / freight billed amounts (all 0 when the part is billed as one total);
 **                SO: part amount as material, misc charges, freight;
 **                Exchange: quantity x unit price, as charges / freight for those billing types, otherwise material.
 **              SubTotal is the line amount before tax. SO quantity and unit price are in the consume UOM.
 ** Purpose: PAS_PUBLIC_API - GET /api/v1/billinginvoicing (MPN)
 ** Date:   23/11/2026

 ** RETURN VALUE:
 **************************************************************
 ** Change History
 **************************************************************
 ** PR   Date         Author		Change Description
 ** --   --------     -------		--------------------------------
    1    23/11/2026   Moin Bloch    Created

  EXEC [dbo].[USP_PublicApi_GetBillingInvoicingParts] @MasterCompanyId = 1, @BillingInvoicingIds = '1', @ExchangeInvoicingIds = '1'
************************************************************************/
CREATE   PROCEDURE [dbo].[USP_PublicApi_GetBillingInvoicingParts]
    @MasterCompanyId      INT,
    @BillingInvoicingIds  VARCHAR(MAX) = NULL,
    @ExchangeInvoicingIds VARCHAR(MAX) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        DECLARE @WOModuleId INT = (SELECT TOP (1) [ModuleId] FROM [dbo].[Module] WITH (NOLOCK) WHERE [ModuleName] = 'WorkOrder');
        DECLARE @SOModuleId INT = (SELECT TOP (1) [ModuleId] FROM [dbo].[Module] WITH (NOLOCK) WHERE [ModuleName] = 'SalesOrder');
        DECLARE @ChargesBillingType INT = 2;   -- ExchangeBillingType: 1 EXCH FEE, 2 Charges, 3 FREIGHT, 4 Outright Price, 5 Overhaul Cost, 6 Core Price
        DECLARE @FreightBillingType INT = 3;

        -- Work order lines: the billed (revised) part, as on the printed invoice.
        SELECT
            -- Ids are used by the API to attach the line to its invoice; not returned to clients.
            CAST(0 AS BIT) AS [IsExchange],
            BI.[BillingInvoicingId] AS [InvoicingId],
            I.[BillingInvoicingItemId] AS [LineId],
            ISNULL(NULLIF(WOP.[RevisedPartNumber], ''), IM.[partnumber]) AS [PartNumber],
            ISNULL(NULLIF(WOP.[RevisedPartDescription], ''), IM.[PartDescription]) AS [PartDescription],
            ISNULL(RCD.[Description], CD.[Description]) AS [Condition],
            WOP.[WorkScope],
            ISNULL(NULLIF(WOP.[RevisedSerialNumber], ''), SL.[SerialNumber]) AS [SerialNumber],
            SL.[StockLineNumber],
            SL.[ControlNumber],
            PU.[ShortName] AS [UnitOfMeasure],
            ISNULL(I.[QtyBilled], 0) AS [QuantityShipped],
            I.[UnitPrice],
            CASE WHEN ISNULL(I.[IsTotalCheck], 0) = 1 THEN 0 ELSE ISNULL(I.[MaterialCostPlus], 0) END AS [MaterialRevenue],
            CASE WHEN ISNULL(I.[IsTotalCheck], 0) = 1 THEN 0 ELSE ISNULL(I.[LaborCostPlus], 0) END AS [LaborRevenue],
            CASE WHEN ISNULL(I.[IsTotalCheck], 0) = 1 THEN 0 ELSE ISNULL(I.[MiscChargesCostPlus], 0) END AS [ChargesRevenue],
            CASE WHEN ISNULL(I.[IsTotalCheck], 0) = 1 THEN 0 ELSE ISNULL(I.[FreightCostPlus], 0) END AS [FreightRevenue],
            ISNULL(I.[SubTotal], 0) AS [SubTotal]
        FROM [dbo].[BillingInvoicingItems] I WITH (NOLOCK)
        INNER JOIN [dbo].[BillingInvoicing] BI WITH (NOLOCK)
            ON BI.[BillingInvoicingId] = I.[BillingInvoicingId] AND BI.[MasterCompanyId] = @MasterCompanyId AND BI.[ModuleId] = @WOModuleId
        LEFT JOIN [dbo].[WorkOrderPartNumber] WOP WITH (NOLOCK) ON WOP.[ID] = I.[SubReferenceId]
        LEFT JOIN [dbo].[ItemMaster] IM WITH (NOLOCK) ON IM.[ItemMasterId] = ISNULL(WOP.[RevisedItemmasterid], I.[ItemMasterId])
        LEFT JOIN [dbo].[UnitOfMeasure] PU WITH (NOLOCK) ON PU.[UnitOfMeasureId] = IM.[PurchaseUnitOfMeasureId]
        LEFT JOIN [dbo].[Condition] RCD WITH (NOLOCK) ON RCD.[ConditionId] = WOP.[RevisedConditionId]
        LEFT JOIN [dbo].[Condition] CD WITH (NOLOCK) ON CD.[ConditionId] = I.[ConditionId]
        LEFT JOIN [dbo].[Stockline] SL WITH (NOLOCK) ON SL.[StockLineId] = I.[StocklineId]
        WHERE I.[BillingInvoicingId] IN (SELECT TRY_CAST([value] AS BIGINT) FROM STRING_SPLIT(@BillingInvoicingIds, ','))
          AND ISNULL(I.[IsDeleted], 0) = 0

        UNION ALL

        -- Sales order lines: quantity and unit price in the consume UOM (stored in the stock UOM), like the PAS Billing tab.
        SELECT
            CAST(0 AS BIT),
            BI.[BillingInvoicingId],
            I.[BillingInvoicingItemId],
            ISNULL(NULLIF(SOP.[PartNumber], ''), IM.[partnumber]),
            ISNULL(NULLIF(SOP.[PartDescription], ''), IM.[PartDescription]),
            ISNULL(NULLIF(SOP.[ConditionName], ''), CD.[Description]),
            NULL,
            ISNULL(NULLIF(I.[SerialNumber], ''), SL.[SerialNumber]),
            SL.[StockLineNumber],
            SL.[ControlNumber],
            CU.[ShortName],
            [dbo].[fn_PublicApi_ConvertUOM](ISNULL(I.[QtyBilled], 0), SU.[ShortName], CU.[ShortName], 0, BI.[MasterCompanyId]),
            [dbo].[fn_PublicApi_ConvertUOM](I.[UnitPrice], SU.[ShortName], CU.[ShortName], 1, BI.[MasterCompanyId]),
            ISNULL(I.[PartCost], 0),
            0,
            ISNULL(I.[MiscChargesCostPlus], 0),
            ISNULL(I.[FreightCostPlus], 0),
            ISNULL(I.[SubTotal], 0)
        FROM [dbo].[BillingInvoicingItems] I WITH (NOLOCK)
        INNER JOIN [dbo].[BillingInvoicing] BI WITH (NOLOCK)
            ON BI.[BillingInvoicingId] = I.[BillingInvoicingId] AND BI.[MasterCompanyId] = @MasterCompanyId AND BI.[ModuleId] = @SOModuleId
        LEFT JOIN [dbo].[SalesOrderPartV1] SOP WITH (NOLOCK) ON SOP.[SalesOrderId] = BI.[ReferenceId] AND SOP.[SalesOrderPartId] = I.[SubReferenceId]
        LEFT JOIN [dbo].[ItemMaster] IM WITH (NOLOCK) ON IM.[ItemMasterId] = ISNULL(SOP.[ItemMasterId], I.[ItemMasterId])
        LEFT JOIN [dbo].[UnitOfMeasure] SU WITH (NOLOCK) ON SU.[UnitOfMeasureId] = IM.[StockUnitOfMeasureId]
        LEFT JOIN [dbo].[UnitOfMeasure] CU WITH (NOLOCK) ON CU.[UnitOfMeasureId] = IM.[ConsumeUnitOfMeasureId]
        LEFT JOIN [dbo].[Condition] CD WITH (NOLOCK) ON CD.[ConditionId] = I.[ConditionId]
        LEFT JOIN [dbo].[Stockline] SL WITH (NOLOCK) ON SL.[StockLineId] = I.[StocklineId]
        WHERE I.[BillingInvoicingId] IN (SELECT TRY_CAST([value] AS BIGINT) FROM STRING_SPLIT(@BillingInvoicingIds, ','))
          AND ISNULL(I.[IsDeleted], 0) = 0

        UNION ALL

        -- Exchange lines: one line per billing (exchange fee, charges, freight, ...) of the exchange part.
        SELECT
            CAST(1 AS BIT),
            X.[SOBillingInvoicingId],
            I.[ExchangeSOBillingInvoicingItemId],
            IM.[partnumber],
            IM.[PartDescription],
            CD.[Description],
            NULL,
            SL.[SerialNumber],
            SL.[StockLineNumber],
            SL.[ControlNumber],
            CU.[ShortName],
            ISNULL(I.[NoofPieces], 0),
            I.[UnitPrice],
            CASE WHEN SB.[BillingTypeId] IN (@ChargesBillingType, @FreightBillingType) THEN 0 ELSE A.[Amount] END,
            0,
            CASE WHEN SB.[BillingTypeId] = @ChargesBillingType THEN A.[Amount] ELSE 0 END,
            CASE WHEN SB.[BillingTypeId] = @FreightBillingType THEN A.[Amount] ELSE 0 END,
            A.[Amount]
        FROM [dbo].[ExchangeSalesOrderBillingInvoicingItem] I WITH (NOLOCK)
        INNER JOIN [dbo].[ExchangeSalesOrderBillingInvoicing] X WITH (NOLOCK)
            ON X.[SOBillingInvoicingId] = I.[SOBillingInvoicingId] AND X.[MasterCompanyId] = @MasterCompanyId
        LEFT JOIN [dbo].[ExchangeSalesOrderPart] SOP WITH (NOLOCK) ON SOP.[ExchangeSalesOrderPartId] = I.[ExchangeSalesOrderPartId]
        LEFT JOIN [dbo].[ItemMaster] IM WITH (NOLOCK) ON IM.[ItemMasterId] = ISNULL(I.[ItemMasterId], SOP.[ItemMasterId])
        LEFT JOIN [dbo].[UnitOfMeasure] CU WITH (NOLOCK) ON CU.[UnitOfMeasureId] = IM.[ConsumeUnitOfMeasureId]
        LEFT JOIN [dbo].[Condition] CD WITH (NOLOCK) ON CD.[ConditionId] = SOP.[ConditionId]
        LEFT JOIN [dbo].[Stockline] SL WITH (NOLOCK) ON SL.[StockLineId] = SOP.[StockLineId]
        LEFT JOIN [dbo].[ExchangeSalesOrderScheduleBilling] SB WITH (NOLOCK)
            ON SB.[ExchangeSalesOrderScheduleBillingId] = I.[ExchangeSalesOrderScheduleBillingId]
        CROSS APPLY (SELECT ISNULL(I.[NoofPieces], 0) * ISNULL(I.[UnitPrice], 0) AS [Amount]) A
        WHERE I.[SOBillingInvoicingId] IN (SELECT TRY_CAST([value] AS BIGINT) FROM STRING_SPLIT(@ExchangeInvoicingIds, ','))
          AND I.[IsDeleted] = 0
        ORDER BY [IsExchange], [InvoicingId], [LineId];
    END TRY
    BEGIN CATCH
        IF @@trancount > 0
            PRINT 'ROLLBACK'
        DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_PublicApi_GetBillingInvoicingParts'
              , @ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@MasterCompanyId, '') AS VARCHAR(100))
                                                   + '@Parameter2 = ''' + CAST(ISNULL(@BillingInvoicingIds, '') AS VARCHAR(100))
                                                   + '@Parameter3 = ''' + CAST(ISNULL(@ExchangeInvoicingIds, '') AS VARCHAR(100))
              , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
              exec spLogException
                       @DatabaseName           = @DatabaseName
                     , @AdhocComments          = @AdhocComments
                     , @ProcedureParameters = @ProcedureParameters
                     , @ApplicationName        =  @ApplicationName
                     , @ErrorLogID                    = @ErrorLogID OUTPUT ;
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
              RETURN(1);
    END CATCH
END