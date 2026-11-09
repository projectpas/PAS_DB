
/*************************************************************
 ** File:   [USP_PublicApi_GetSalesOrderInvoices]
 ** Author: Moin Bloch
 ** Description: 4.12 Invoices of the SOs on one page (standard and proforma; current versions only): one row per
 **              invoice item (an invoice without items gives one row with empty item columns).
 **              The API groups the rows per invoice.
 ** Purpose: PAS_PUBLIC_API - GET /api/v1/salesorders (billing)
 ** Date:   09/11/2026

 ** RETURN VALUE:
 **************************************************************
 ** Change History
 **************************************************************
 ** PR   Date         Author		Change Description
 ** --   --------     -------		--------------------------------
    1    09/11/2026   Moin Bloch    Created

  EXEC [dbo].[USP_PublicApi_GetSalesOrderInvoices] @MasterCompanyId = 1, @SalesOrderIds = '679'
************************************************************************/
CREATE   PROCEDURE [dbo].[USP_PublicApi_GetSalesOrderInvoices]
    @MasterCompanyId INT,
    @SalesOrderIds   VARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @SOModuleId INT = (SELECT TOP (1) [ModuleId] FROM [dbo].[Module] WITH (NOLOCK) WHERE [ModuleName] = 'SalesOrder');

    SELECT
        -- Ids are used by the API to group items per invoice and invoice per SO; not returned to clients.
        B.[ReferenceId] AS [SalesOrderId],
        B.[BillingInvoicingId],
        B.[InvoiceNo] AS [InvoiceNumber],
        B.[InvoiceDate],
        B.[InvoiceStatus] AS [Status],
        CAST(ISNULL(B.[IsPerformaInvoice], 0) AS BIT) AS [IsProforma],
        B.[VersionNo] AS [Version],
        B.[PostedDate],
        CUR.[Code] AS [Currency],
        ISNULL(B.[SubTotal], 0) AS [SubTotal],
        ISNULL(B.[SalesTax], 0) AS [SalesTax],
        ISNULL(B.[OtherTax], 0) AS [OtherTax],
        ISNULL(B.[GrandTotal], 0) AS [GrandTotal],
        ISNULL(B.[DepositAmount], 0) AS [DepositAmount],
        ISNULL(B.[UsedDeposit], 0) AS [UsedDeposit],
        ISNULL(B.[CreditMemoUsed], 0) AS [CreditMemoUsed],
        ISNULL(B.[RemainingAmount], 0) AS [RemainingAmount],
        I.[BillingInvoicingItemId],
        ISNULL(NULLIF(SOP.[PartNumber], ''), IM.[partnumber]) AS [PartNumber],
        ISNULL(NULLIF(SOP.[PartDescription], ''), IM.[PartDescription]) AS [PartDescription],
        SOP.[ConditionName] AS [Condition],
        SL.[StockLineNumber],
        ISNULL(NULLIF(I.[SerialNumber], ''), SL.[SerialNumber]) AS [SerialNumber],
        SHP.[SOShippingNum] AS [ShippingNumber],
        -- Quantity and unit price in the item's consume UOM (stored in its stock UOM), like the PAS Billing tab.
        CU.[ShortName] AS [UnitOfMeasure],
        [dbo].[fn_PublicApi_ConvertUOM](I.[QtyBilled], SU.[ShortName], CU.[ShortName], 0, SO.[MasterCompanyId]) AS [QuantityBilled],
        [dbo].[fn_PublicApi_ConvertUOM](I.[UnitPrice], SU.[ShortName], CU.[ShortName], 1, SO.[MasterCompanyId]) AS [UnitPrice],
        I.[MiscCharges] AS [ItemMiscCharges],
        I.[Freight] AS [ItemFreight],
        I.[SubTotal] AS [ItemSubTotal],
        I.[SalesTax] AS [ItemSalesTax],
        I.[OtherTax] AS [ItemOtherTax],
        I.[GrandTotal] AS [ItemGrandTotal]
    FROM [dbo].[BillingInvoicing] B WITH (NOLOCK)
    INNER JOIN [dbo].[SalesOrder] SO WITH (NOLOCK)
        ON SO.[SalesOrderId] = B.[ReferenceId] AND SO.[MasterCompanyId] = @MasterCompanyId AND SO.[IsDeleted] = 0
    LEFT JOIN [dbo].[Currency] CUR WITH (NOLOCK) ON CUR.[CurrencyId] = B.[CurrencyId]
    LEFT JOIN [dbo].[BillingInvoicingItems] I WITH (NOLOCK)
        ON I.[BillingInvoicingId] = B.[BillingInvoicingId] AND I.[IsDeleted] = 0 AND ISNULL(I.[IsVersionIncrease], 0) = 0
    LEFT JOIN [dbo].[SalesOrderPartV1] SOP WITH (NOLOCK) ON SOP.[SalesOrderId] = B.[ReferenceId] AND SOP.[SalesOrderPartId] = I.[SubReferenceId]
    LEFT JOIN [dbo].[ItemMaster] IM WITH (NOLOCK) ON IM.[ItemMasterId] = ISNULL(SOP.[ItemMasterId], I.[ItemMasterId])
    LEFT JOIN [dbo].[UnitOfMeasure] SU WITH (NOLOCK) ON SU.[UnitOfMeasureId] = IM.[StockUnitOfMeasureId]
    LEFT JOIN [dbo].[UnitOfMeasure] CU WITH (NOLOCK) ON CU.[UnitOfMeasureId] = IM.[ConsumeUnitOfMeasureId]
    LEFT JOIN [dbo].[Stockline] SL WITH (NOLOCK) ON SL.[StockLineId] = I.[StocklineId]
    LEFT JOIN [dbo].[SalesOrderShipping] SHP WITH (NOLOCK) ON SHP.[SalesOrderShippingId] = I.[ShippingId]
    WHERE B.[ModuleId] = @SOModuleId
      AND B.[ReferenceId] IN (SELECT TRY_CAST([value] AS BIGINT) FROM STRING_SPLIT(@SalesOrderIds, ','))
      AND B.[IsDeleted] = 0
      AND ISNULL(B.[IsVersionIncrease], 0) = 0
    ORDER BY B.[ReferenceId], B.[BillingInvoicingId], I.[BillingInvoicingItemId];
END