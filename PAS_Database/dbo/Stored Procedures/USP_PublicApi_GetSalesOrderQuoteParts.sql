/*************************************************************
 ** File:   [USP_PublicApi_GetSalesOrderQuoteParts]
 ** Author: Moin Bloch
 ** Description: Quoted parts (SalesOrderQuotePartV1) of the quotes on one page (@SalesOrderQuoteIds: comma separated).
 **              Amounts as on the printed quote (USP_GetCustomerTax_Information_ProductSale_SOQ):
 **                MaterialRevenue = the part's net sale amount;
 **                FreightRevenue / ChargesRevenue = the part's freight / charge lines; a quote billed with one freight or
 **                charges amount (billing method 3) has it split equally over its parts (the last part takes the cents left);
 **                sales / other tax = the customer's product sale tax rates for the ship-to site and the part's origin site,
 **                on the part total, its freight and its charges, rounded as the print;
 **                QuoteAmount = the part total + one-amount charges + freight + taxes (the parts add up to the printed TOTAL).
 **              Quantity (quoted, else requested) and UnitCost in the consume UOM.
 **              ApprovedBy / CustomerApprovedBy: latest approval of the part (SalesOrderQuoteApproval), as the PAS approval tab.
 ** Purpose: PAS_PUBLIC_API - GET /api/v1/salesorderquotes (MPN)
 ** Date:   24/11/2026

 ** RETURN VALUE:
 **************************************************************
 ** Change History
 **************************************************************
 ** PR   Date         Author		Change Description
 ** --   --------     -------		--------------------------------
    1    24/11/2026   Moin Bloch    Created

  EXEC [dbo].[USP_PublicApi_GetSalesOrderQuoteParts] @MasterCompanyId = 1, @SalesOrderQuoteIds = '1'
************************************************************************/
CREATE   PROCEDURE [dbo].[USP_PublicApi_GetSalesOrderQuoteParts]
    @MasterCompanyId    INT,
    @SalesOrderQuoteIds VARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        -- FreightBilingMethodId / ChargesBilingMethodId Flat Rate (BillingMethod, stored as 'Flate Rate'): one amount for the whole quote.
        DECLARE @OneAmount INT = (SELECT TOP (1) [BillingMethodId] FROM [dbo].[BillingMethod] WITH (NOLOCK) WHERE [Description] = 'Flate Rate');
        DECLARE @SOQModuleId INT = (SELECT TOP (1) [ModuleId] FROM [dbo].[Module] WITH (NOLOCK) WHERE [ModuleName] = 'SalesQuote');

        IF OBJECT_ID(N'tempdb..#Quote') IS NOT NULL DROP TABLE #Quote;
        IF OBJECT_ID(N'tempdb..#Part') IS NOT NULL DROP TABLE #Part;
        IF OBJECT_ID(N'tempdb..#TaxRow') IS NOT NULL DROP TABLE #TaxRow;
        IF OBJECT_ID(N'tempdb..#PartTax') IS NOT NULL DROP TABLE #PartTax;

        -- Quotes of the page (of the token's company), with their one-amount freight / charges.
        SELECT Q.[SalesOrderQuoteId], Q.[CustomerId],
               CASE WHEN Q.[FreightBilingMethodId] = @OneAmount THEN CAST(ISNULL(Q.[TotalFreight], 0) AS DECIMAL(18, 2)) END AS [OneFreight],
               CASE WHEN Q.[ChargesBilingMethodId] = @OneAmount THEN CAST(ISNULL(Q.[TotalCharges], 0) AS DECIMAL(18, 2)) END AS [OneCharges]
        INTO #Quote
        FROM [dbo].[SalesOrderQuote] Q WITH (NOLOCK)
        WHERE Q.[SalesOrderQuoteId] IN (SELECT TRY_CAST([value] AS BIGINT) FROM STRING_SPLIT(@SalesOrderQuoteIds, ','))
          AND Q.[MasterCompanyId] = @MasterCompanyId
          AND Q.[IsDeleted] = 0;

        -- Parts with their total (part cost TotalRevenue), freight and charge lines, and their place in the quote.
        SELECT P.[SalesOrderQuoteId], P.[SalesOrderQuotePartId],
               CAST(ISNULL(PC.[TotalRevenue], 0) AS DECIMAL(18, 2)) AS [PartTotal],
               CAST(ISNULL(PC.[NetSaleAmount], 0) AS DECIMAL(18, 2)) AS [NetSaleAmount],
               PC.[UnitCost],
               CAST(ISNULL(FR.[Amount], 0) AS DECIMAL(18, 2)) AS [FreightLines],
               CAST(ISNULL(CH.[Amount], 0) AS DECIMAL(18, 2)) AS [ChargeLines],
               ROW_NUMBER() OVER (PARTITION BY P.[SalesOrderQuoteId] ORDER BY P.[SalesOrderQuotePartId]) AS [PartNo],
               COUNT(1) OVER (PARTITION BY P.[SalesOrderQuoteId]) AS [PartCount]
        INTO #Part
        FROM #Quote Q
        INNER JOIN [dbo].[SalesOrderQuotePartV1] P WITH (NOLOCK) ON P.[SalesOrderQuoteId] = Q.[SalesOrderQuoteId] AND P.[IsDeleted] = 0
        OUTER APPLY (SELECT TOP (1) C.[TotalRevenue], C.[NetSaleAmount], C.[UnitCost]
                     FROM [dbo].[SalesOrderQuotePartCost] C WITH (NOLOCK)
                     WHERE C.[SalesOrderQuoteId] = P.[SalesOrderQuoteId] AND C.[SalesOrderQuotePartId] = P.[SalesOrderQuotePartId]
                     ORDER BY C.[SalesOrderQuotePartCostId] DESC) PC
        OUTER APPLY (SELECT SUM(F.[BillingAmount]) AS [Amount] FROM [dbo].[SalesOrderQuoteFreight] F WITH (NOLOCK)
                     WHERE F.[SalesOrderQuoteId] = P.[SalesOrderQuoteId] AND F.[SalesOrderQuotePartId] = P.[SalesOrderQuotePartId]
                       AND F.[IsActive] = 1 AND F.[IsDeleted] = 0) FR
        OUTER APPLY (SELECT SUM(H.[BillingAmount]) AS [Amount] FROM [dbo].[SalesOrderQuoteCharges] H WITH (NOLOCK)
                     WHERE H.[SalesOrderQuoteId] = P.[SalesOrderQuoteId] AND H.[SalesOrderQuotePartId] = P.[SalesOrderQuotePartId]
                       AND H.[IsActive] = 1 AND H.[IsDeleted] = 0) CH;

        -- Tax rows as USP_GetCustomerTax_Information_ProductSale_SOQ: origin site = the quoted stockline's site, else the
        -- item's site; ship-to site = the quote's ship-to address, else the customer's primary domestic ship-to.
        SELECT DISTINCT
               CASE WHEN STK.[SiteId] IS NOT NULL THEN STK.[SiteId] ELSE IM.[SiteId] END AS [OriginSiteId],
               CASE WHEN AAD.[SiteId] IS NOT NULL THEN AAD.[SiteId] ELSE CDS.[CustomerDomensticShippingId] END AS [ShipToSiteId],
               Q.[CustomerId], P.[SalesOrderQuoteId], P.[SalesOrderQuotePartId]
        INTO #TaxRow
        FROM #Quote Q
        INNER JOIN [dbo].[SalesOrderQuotePartV1] P WITH (NOLOCK) ON P.[SalesOrderQuoteId] = Q.[SalesOrderQuoteId] AND P.[IsDeleted] = 0
        LEFT JOIN [dbo].[SalesOrderQuoteStocklineV1] QSL WITH (NOLOCK) ON QSL.[SalesOrderQuotePartId] = P.[SalesOrderQuotePartId]
        LEFT JOIN [dbo].[Stockline] STK WITH (NOLOCK) ON STK.[StockLineId] = QSL.[StockLineId]
        LEFT JOIN [dbo].[ItemMaster] IM WITH (NOLOCK) ON IM.[ItemMasterId] = P.[ItemMasterId]
        LEFT JOIN [dbo].[AllAddress] AAD WITH (NOLOCK) ON AAD.[ReffranceId] = P.[SalesOrderQuoteId] AND AAD.[IsShippingAdd] = 1
            AND AAD.[ModuleId] = @SOQModuleId AND AAD.[MasterCompanyId] = @MasterCompanyId AND AAD.[IsDeleted] = 0
        LEFT JOIN [dbo].[CustomerDomensticShipping] CDS WITH (NOLOCK) ON CDS.[CustomerId] = Q.[CustomerId] AND CDS.[IsPrimary] = 1;

        -- Taxes per part, as the print: each amount x rate / 100 rounded to cents; a one-amount freight / charges is taxed
        -- as amount / number of tax rows of the quote.
        SELECT T.[SalesOrderQuotePartId],
               SUM(P.[PartTotal]) AS [PrintedTotal],
               SUM(X.[SalesTax]) AS [SalesTax],
               SUM(X.[OtherTax]) AS [OtherTax]
        INTO #PartTax
        FROM #TaxRow T
        INNER JOIN #Part P ON P.[SalesOrderQuotePartId] = T.[SalesOrderQuotePartId]
        INNER JOIN #Quote Q ON Q.[SalesOrderQuoteId] = T.[SalesOrderQuoteId]
        CROSS APPLY (SELECT COUNT(1) AS [Rows] FROM #TaxRow N WHERE N.[SalesOrderQuoteId] = T.[SalesOrderQuoteId]) N
        -- Product sale tax rates, as USP_GetCustomerTax_Information_ProductSale.
        OUTER APPLY (SELECT CAST(ISNULL(SUM(CASE WHEN TT.[Code] = 'SALES TAX' THEN CAST(ISNULL(TR.[TaxRate], 0) AS DECIMAL(18, 2)) ELSE 0 END), 0) AS DECIMAL(18, 2)) AS [SalesRate],
                            CAST(ISNULL(SUM(CASE WHEN TT.[Code] = 'SALES TAX' THEN 0 ELSE CAST(ISNULL(TR.[TaxRate], 0) AS DECIMAL(18, 2)) END), 0) AS DECIMAL(18, 2)) AS [OtherRate]
                     FROM [dbo].[CustomerTaxTypeRateMapping] M WITH (NOLOCK)
                     INNER JOIN [dbo].[TaxType] TT WITH (NOLOCK) ON TT.[TaxTypeId] = M.[TaxTypeId]
                     INNER JOIN [dbo].[TaxRate] TR WITH (NOLOCK) ON TR.[TaxRateId] = M.[TaxRateId]
                     WHERE M.[CustomerId] = T.[CustomerId] AND M.[SiteId] = T.[ShipToSiteId] AND M.[ShipFromSiteId] = T.[OriginSiteId]
                       AND M.[IsProductSale] = 1 AND M.[IsTaxExempt] = 0 AND M.[IsDeleted] = 0 AND M.[IsActive] = 1) R
        CROSS APPLY (SELECT
            CAST(P.[PartTotal] * R.[SalesRate] / 100 AS DECIMAL(18, 2))
          + CASE WHEN Q.[OneFreight] IS NULL THEN CAST(P.[FreightLines] * R.[SalesRate] / 100 AS DECIMAL(18, 2))
                 WHEN Q.[OneFreight] > 0 THEN CAST(ISNULL(Q.[OneFreight] / N.[Rows], 0) * R.[SalesRate] / 100 AS DECIMAL(18, 2)) ELSE 0 END
          + CASE WHEN Q.[OneCharges] IS NULL THEN CAST(P.[ChargeLines] * R.[SalesRate] / 100 AS DECIMAL(18, 2))
                 WHEN Q.[OneCharges] > 0 THEN CAST(ISNULL(Q.[OneCharges] / N.[Rows], 0) * R.[SalesRate] / 100 AS DECIMAL(18, 2)) ELSE 0 END AS [SalesTax],
            CAST(P.[PartTotal] * R.[OtherRate] / 100 AS DECIMAL(18, 2))
          + CASE WHEN Q.[OneFreight] IS NULL THEN CAST(P.[FreightLines] * R.[OtherRate] / 100 AS DECIMAL(18, 2))
                 WHEN Q.[OneFreight] > 0 THEN CAST(ISNULL(Q.[OneFreight] / N.[Rows], 0) * R.[OtherRate] / 100 AS DECIMAL(18, 2)) ELSE 0 END
          + CASE WHEN Q.[OneCharges] IS NULL THEN CAST(P.[ChargeLines] * R.[OtherRate] / 100 AS DECIMAL(18, 2))
                 WHEN Q.[OneCharges] > 0 THEN CAST(ISNULL(Q.[OneCharges] / N.[Rows], 0) * R.[OtherRate] / 100 AS DECIMAL(18, 2)) ELSE 0 END AS [OtherTax]) X
        GROUP BY T.[SalesOrderQuotePartId];

        SELECT
            -- Ids are used by the API to group parts per quote; not returned to clients.
            P.[SalesOrderQuoteId],
            P.[SalesOrderQuotePartId],
            -- As the PAS quote parts list (GetSalesOrderQuoteParts): item master, condition and priority tables.
            ISNULL(IM.[partnumber], NULLIF(QP.[PartNumber], '')) AS [PartNumber],
            ISNULL(IM.[PartDescription], NULLIF(QP.[PartDescription], '')) AS [PartDescription],
            ISNULL(CD.[Description], NULLIF(QP.[ConditionName], '')) AS [Condition],
            ISNULL(PR.[Description], NULLIF(LTRIM(RTRIM(QP.[PriorityName])), '')) AS [Priority],
            CU.[ShortName] AS [UnitOfMeasure],
            [dbo].[fn_PublicApi_ConvertUOM](ISNULL(NULLIF(QP.[QtyQuoted], 0), ISNULL(QP.[QtyRequested], 0)), SU.[ShortName], CU.[ShortName], 0, QP.[MasterCompanyId]) AS [Quantity],
            [dbo].[fn_PublicApi_ConvertUOM](P.[UnitCost], SU.[ShortName], CU.[ShortName], 1, QP.[MasterCompanyId]) AS [UnitCost],
            P.[NetSaleAmount] AS [MaterialRevenue],
            A.[ChargesRevenue],
            A.[FreightRevenue],
            ISNULL(PT.[SalesTax], 0) AS [SalesTax],
            ISNULL(PT.[OtherTax], 0) AS [OtherTax],
            ISNULL(PT.[PrintedTotal], P.[PartTotal]) + CASE WHEN Q.[OneCharges] IS NULL THEN 0 ELSE A.[ChargesRevenue] END
                + A.[FreightRevenue] + ISNULL(PT.[SalesTax], 0) + ISNULL(PT.[OtherTax], 0) AS [QuoteAmount],
            NULLIF(LTRIM(RTRIM(AP.[InternalApprovedBy])), '') AS [ApprovedBy],
            NULLIF(LTRIM(RTRIM(AP.[CustomerApprovedBy])), '') AS [CustomerApprovedBy]
        FROM #Part P
        INNER JOIN #Quote Q ON Q.[SalesOrderQuoteId] = P.[SalesOrderQuoteId]
        INNER JOIN [dbo].[SalesOrderQuotePartV1] QP WITH (NOLOCK) ON QP.[SalesOrderQuotePartId] = P.[SalesOrderQuotePartId]
        LEFT JOIN #PartTax PT ON PT.[SalesOrderQuotePartId] = P.[SalesOrderQuotePartId]
        LEFT JOIN [dbo].[ItemMaster] IM WITH (NOLOCK) ON IM.[ItemMasterId] = QP.[ItemMasterId]
        LEFT JOIN [dbo].[UnitOfMeasure] SU WITH (NOLOCK) ON SU.[UnitOfMeasureId] = IM.[StockUnitOfMeasureId]
        LEFT JOIN [dbo].[UnitOfMeasure] CU WITH (NOLOCK) ON CU.[UnitOfMeasureId] = IM.[ConsumeUnitOfMeasureId]
        LEFT JOIN [dbo].[Condition] CD WITH (NOLOCK) ON CD.[ConditionId] = QP.[ConditionId]
        LEFT JOIN [dbo].[Priority] PR WITH (NOLOCK) ON PR.[PriorityId] = QP.[PriorityId]
        -- Freight / charges of the part; a one-amount freight / charges split equally, the last part takes the cents left.
        CROSS APPLY (SELECT
            CASE WHEN Q.[OneFreight] IS NULL THEN P.[FreightLines]
                 WHEN P.[PartNo] < P.[PartCount] THEN CAST(Q.[OneFreight] / P.[PartCount] AS DECIMAL(18, 2))
                 ELSE Q.[OneFreight] - CAST(Q.[OneFreight] / P.[PartCount] AS DECIMAL(18, 2)) * (P.[PartCount] - 1) END AS [FreightRevenue],
            CASE WHEN Q.[OneCharges] IS NULL THEN P.[ChargeLines]
                 WHEN P.[PartNo] < P.[PartCount] THEN CAST(Q.[OneCharges] / P.[PartCount] AS DECIMAL(18, 2))
                 ELSE Q.[OneCharges] - CAST(Q.[OneCharges] / P.[PartCount] AS DECIMAL(18, 2)) * (P.[PartCount] - 1) END AS [ChargesRevenue]) A
        -- Latest approval of the part on this quote.
        OUTER APPLY (SELECT TOP (1) QA.[InternalApprovedBy], QA.[CustomerApprovedBy]
                     FROM [dbo].[SalesOrderQuoteApproval] QA WITH (NOLOCK)
                     WHERE QA.[SalesOrderQuoteId] = P.[SalesOrderQuoteId] AND QA.[SalesOrderQuotePartId] = P.[SalesOrderQuotePartId] AND QA.[IsDeleted] = 0
                     ORDER BY QA.[SalesOrderQuoteApprovalId] DESC) AP
        ORDER BY P.[SalesOrderQuoteId], P.[SalesOrderQuotePartId];
    END TRY
    BEGIN CATCH
        IF @@trancount > 0
            PRINT 'ROLLBACK'
        DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_PublicApi_GetSalesOrderQuoteParts'
              , @ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@MasterCompanyId, '') AS VARCHAR(100))
                                                   + '@Parameter2 = ''' + CAST(ISNULL(@SalesOrderQuoteIds, '') AS VARCHAR(100))
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