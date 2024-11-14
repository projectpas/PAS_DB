
-- EXEC [DBO].[GetSalesOrderQuotePrintData] 766
CREATE   PROCEDURE [dbo].[GetSalesOrderQuotePrintData]
    @SalesQuoteId INT
AS
BEGIN
    SELECT 
        0 AS ItemNo,
        so.CustomerId,
        ISNULL(cust.Name, '') AS ClientName,
        ISNULL(cust.Email, '') AS CustEmail,
        so.Notes AS SONotes,
        ISNULL(po.PurchaseOrderNumber, '') + ISNULL('/' + ro.RepairOrderNumber, '') AS PORONum,
        ISNULL(cont.countries_name, '') AS CustCountry,
        ISNULL(sp.FirstName + ' ' + sp.LastName, '') AS SalesPerson,
        custAddress.Line1 AS AddressLine1,
        custAddress.Line2 AS AddressLine2,
        custAddress.City,
        custAddress.StateOrProvince AS State,
        custAddress.PostalCode,
        ISNULL(cust.CustomerPhone, '') AS PhoneFax,
        'BuyersName' AS BuyersName, -- Static Value
        ISNULL(ct.Name, '') AS CreditTerms,
        ISNULL(cur.DisplayName, '') AS Currency,
        so.SalesOrderQuoteNumber AS SOQNum,
        FORMAT(so.OpenDate, 'MM/dd/yyyy') AS OrderDate,
        CASE 
            WHEN sop.EstimatedShipDate IS NOT NULL 
            THEN FORMAT(sop.EstimatedShipDate, 'MM/dd/yyyy') 
            ELSE NULL 
        END AS ShipDate,
        CASE 
            WHEN so.FreightBilingMethodId = 3 
            THEN ISNULL(so.TotalFreight, 0)
            ELSE ISNULL(soFreight.BillingAmount, 0)
        END AS Freight,
        CASE 
            WHEN so.ChargesBilingMethodId = 3 
            THEN ISNULL(so.TotalCharges, 0)
            ELSE ISNULL(soCharges.BillingAmount, 0)
        END AS MiscCharges,
        ISNULL(sopc.TaxPercentage, 0) AS TaxRate,
        ISNULL((sopc.TaxPercentage * sop.QtyRequested * sopc.UnitSalesPrice) / 100, 0) AS Tax,
        0 AS ShippingAndHandling, -- Static Value
        0 AS OtherTax, -- Static Value
        so.ManagementStructureId,
        -- Barcode Generation Logic (if needed can be implemented in SQL or outside of the SP)
        '' AS Barcode -- Placeholder for the barcode, should be handled in application code
    FROM SalesOrderQuote so WITH (NOLOCK)
    LEFT JOIN SalesOrderQuotePartV1 sop WITH (NOLOCK) ON so.SalesOrderQuoteId = sop.SalesOrderQuoteId
    LEFT JOIN SalesOrderQuoteStocklineV1 stk WITH (NOLOCK) ON stk.SalesOrderQuotePartId = sop.SalesOrderQuotePartId
    LEFT JOIN SalesOrderQuotePartCost sopc WITH (NOLOCK) ON sopc.SalesOrderQuotePartId = sop.SalesOrderQuotePartId
    LEFT JOIN ItemMaster itemMaster WITH (NOLOCK) ON sop.ItemMasterId = itemMaster.ItemMasterId
    LEFT JOIN UnitOfMeasure iu WITH (NOLOCK) ON itemMaster.ConsumeUnitOfMeasureId = iu.UnitOfMeasureId
    LEFT JOIN Condition cp WITH (NOLOCK) ON sop.ConditionId = cp.ConditionId
    LEFT JOIN Customer cust WITH (NOLOCK) ON so.CustomerId = cust.CustomerId
    LEFT JOIN Address custAddress WITH (NOLOCK) ON cust.AddressId = custAddress.AddressId
    LEFT JOIN CustomerFinancial cf WITH (NOLOCK) ON cust.CustomerId = cf.CustomerId
    LEFT JOIN Employee emp WITH (NOLOCK) ON so.EmployeeId = emp.EmployeeId
    LEFT JOIN Employee sp WITH (NOLOCK) ON so.SalesPersonId = sp.EmployeeId
    LEFT JOIN Countries cont WITH (NOLOCK) ON custAddress.CountryId = cont.countries_id
    LEFT JOIN Currency cur WITH (NOLOCK) ON so.CurrencyId = cur.CurrencyId
    LEFT JOIN CreditTerms ct WITH (NOLOCK) ON cf.CreditTermsId = ct.CreditTermsId
    LEFT JOIN StockLine sl WITH (NOLOCK) ON stk.StockLineId = sl.StockLineId
    LEFT JOIN SalesOrderQuoteFreight soFreight WITH (NOLOCK) ON so.SalesOrderQuoteId = soFreight.SalesOrderQuoteId AND soFreight.IsActive = 1 AND soFreight.IsDeleted = 0
    LEFT JOIN SalesOrderQuoteCharges soCharges WITH (NOLOCK) ON so.SalesOrderQuoteId = soCharges.SalesOrderQuoteId AND soCharges.IsActive = 1 AND soCharges.IsDeleted = 0
    LEFT JOIN StockLine qs WITH (NOLOCK) ON stk.StockLineId = qs.StockLineId
    LEFT JOIN PurchaseOrder po WITH (NOLOCK) ON qs.PurchaseOrderId = po.PurchaseOrderId
    LEFT JOIN RepairOrder ro WITH (NOLOCK) ON qs.RepairOrderId = ro.RepairOrderId
    WHERE so.SalesOrderQuoteId = @SalesQuoteId 
      AND so.IsActive = 1 
      AND so.IsDeleted = 0;
END