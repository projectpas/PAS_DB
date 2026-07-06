/*************************************************************           
 ** File:   [GetSalesQuoteResponse]           
 ** Author: Vishal Suthar
 ** Description: 
 ** Purpose:         
 ** Date:   11/04/2024

 ** PARAMETERS:           
         
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    11/04/2024   Vishal Suthar Updated to make use of new SOQ Part tables
	2    01/July/2026			 RAJESH GAMI						[PN-17008] - Merge Non Stock Inventory to ItemMaster : Get only Stock Inventory Data Where IsNonStock = 0
     
**************************************************************/
CREATE    PROCEDURE [dbo].[GetSalesQuoteResponse]
    @SalesOrderId INT
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
    FROM DBO.SalesOrderQuote so WITH(NOLOCK)
    LEFT JOIN DBO.SalesOrderQuotePartV1 sop WITH(NOLOCK) ON so.SalesOrderQuoteId = sop.SalesOrderQuoteId
    LEFT JOIN DBO.SalesOrderQuoteStocklineV1 stk WITH(NOLOCK) ON stk.SalesOrderQuotePartId = sop.SalesOrderQuotePartId
    LEFT JOIN DBO.SalesOrderQuotePartCost sopc WITH(NOLOCK) ON sopc.SalesOrderQuotePartId = sop.SalesOrderQuotePartId
    LEFT JOIN DBO.ItemMaster itemMaster WITH(NOLOCK) ON sop.ItemMasterId = itemMaster.ItemMasterId
     AND ISNULL(itemMaster.IsNonStock,0) = 0 LEFT JOIN DBO.UnitOfMeasure iu WITH(NOLOCK) ON itemMaster.ConsumeUnitOfMeasureId = iu.UnitOfMeasureId
    LEFT JOIN DBO.Condition cp WITH(NOLOCK) ON sop.ConditionId = cp.ConditionId
    LEFT JOIN DBO.Customer cust WITH(NOLOCK) ON so.CustomerId = cust.CustomerId
    LEFT JOIN DBO.Address custAddress WITH(NOLOCK) ON cust.AddressId = custAddress.AddressId
    LEFT JOIN DBO.CustomerFinancial cf WITH(NOLOCK) ON cust.CustomerId = cf.CustomerId
    LEFT JOIN DBO.Employee emp WITH(NOLOCK) ON so.EmployeeId = emp.EmployeeId
    LEFT JOIN DBO.Employee sp WITH(NOLOCK) ON so.SalesPersonId = sp.EmployeeId
    LEFT JOIN DBO.Countries cont WITH(NOLOCK) ON custAddress.CountryId = cont.countries_id
    LEFT JOIN DBO.Currency cur WITH(NOLOCK) ON so.CurrencyId = cur.CurrencyId
    LEFT JOIN DBO.CreditTerms ct WITH(NOLOCK) ON cf.CreditTermsId = ct.CreditTermsId
    LEFT JOIN DBO.StockLine sl WITH(NOLOCK) ON stk.StockLineId = sl.StockLineId
    LEFT JOIN DBO.SalesOrderQuoteFreight soFreight WITH(NOLOCK) ON so.SalesOrderQuoteId = soFreight.SalesOrderQuoteId AND soFreight.IsActive = 1 AND soFreight.IsDeleted = 0
    LEFT JOIN DBO.SalesOrderQuoteCharges soCharges WITH(NOLOCK) ON so.SalesOrderQuoteId = soCharges.SalesOrderQuoteId AND soCharges.IsActive = 1 AND soCharges.IsDeleted = 0
    LEFT JOIN DBO.StockLine qs WITH(NOLOCK) ON stk.StockLineId = qs.StockLineId
    LEFT JOIN DBO.PurchaseOrder po WITH(NOLOCK) ON qs.PurchaseOrderId = po.PurchaseOrderId
    LEFT JOIN DBO.RepairOrder ro WITH(NOLOCK) ON qs.RepairOrderId = ro.RepairOrderId
    WHERE so.SalesOrderQuoteId = @SalesOrderId 
      AND so.IsActive = 1 
      AND so.IsDeleted = 0;
END