-- ===== PROCEDURE: [USP_GetSalesOrderQuotePrintData]   (file: _PAS_DB/PAS_DB/dbo/Stored Procedures/Procs2/USP_GetSalesOrderQuotePrintData.sql) =====
/*************************************************************           
 ** File:   [dbo].[USP_GetSalesOrderQuotePrintData]          
 ** Author:   BHARGAV SALIA
 ** Description: Get Sales Order Quote Print Data
 ** Date:   12/16/2024   
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author			Change Description            
 ** --   --------     -------		--------------------------------          
	1    12/16/2024   BHARGAV SALIA	     Created
	2    01/July/2026			 RAJESH GAMI						[PN-17008] - Merge Non Stock Inventory to ItemMaster : Get only Stock Inventory Data Where IsNonStock = 0
	3    09/July/2026			 RAJESH GAMI						[PN-17009] - Merge Non-Stock Inventory to Stockline : Get only Stock Inventory Data Where IsNonStock = 0
**************************************************************/ 
CREATE   PROCEDURE [USP_GetSalesOrderQuotePrintData]
    @SalesOrderId INT
AS
BEGIN
    SET NOCOUNT ON;	
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	BEGIN TRY
		SELECT TOP 1
			0 AS ItemNo,
			so.CustomerId,
			ISNULL(cust.Name, '') AS ClientName,
			ISNULL(cust.Email, '') AS CustEmail,
			so.Notes AS SONotes,
			ISNULL(po.PurchaseOrderNumber, '') + 
			CASE WHEN ro.RepairOrderNumber IS NOT NULL THEN '/' + ro.RepairOrderNumber 
				 ELSE '' 
			END AS PORONum,
			ISNULL(cont.countries_name, '') AS CustCountry,
			ISNULL(sp.FirstName + ' ' + sp.LastName, '') AS SalesPerson,
			(custAddress.Line1) AS AddressLine1,
			(custAddress.Line2) AS AddressLine2,
			(custAddress.City) AS City,
			(custAddress.StateOrProvince) AS State,
			(custAddress.PostalCode) AS PostalCode,
			ISNULL(cust.CustomerPhone, '') AS PhoneFax,
			'BuyersName' AS BuyersName,
			ISNULL(ct.Name, '') AS CreditTerms,
			ISNULL(cur.DisplayName, '') AS Currency,
			so.SalesOrderQuoteNumber AS SOQNum,
			FORMAT(so.OpenDate, 'MM/dd/yyyy') AS OrderDate,
			FORMAT(sop.EstimatedShipDate, 'MM/dd/yyyy') AS ShipDate,
			CASE 
				WHEN ((SELECT FreightBilingMethodId FROM [dbo].SalesOrder WITH (NOLOCK) WHERE SalesOrderId = @SalesOrderId AND IsActive = 1 AND IsDeleted = 0) = 3) THEN
					CAST(ISNULL((SELECT TotalFreight FROM [dbo].SalesOrder WITH (NOLOCK) WHERE SalesOrderId = @SalesOrderId AND IsActive = 1 AND IsDeleted = 0), 0) AS DECIMAL(18, 2))

				WHEN (select BillingAmount FROM [dbo].SalesOrderFreight WITH (NOLOCK) WHERE SalesOrderId = @SalesOrderId AND ItemMasterId = sop.ItemMasterId AND IsActive = 1 AND IsDeleted = 0) = NULL THEN 0
				ELSE
					CAST(ISNULL((select BillingAmount FROM [dbo].SalesOrderFreight WITH (NOLOCK) WHERE SalesOrderId = @SalesOrderId AND ItemMasterId = sop.ItemMasterId AND IsActive = 1 AND IsDeleted = 0), 0) AS DECIMAL(18, 2))
			END AS Freight,

			CASE 
				WHEN ((SELECT ChargesBilingMethodId FROM [dbo].SalesOrder WITH (NOLOCK) WHERE SalesOrderId = @SalesOrderId AND IsActive = 1 AND IsDeleted = 0) = 3) THEN
					CAST(ISNULL((SELECT TotalCharges FROM [dbo].SalesOrder WITH (NOLOCK) WHERE SalesOrderId = @SalesOrderId AND IsActive = 1 AND IsDeleted = 0), 0) AS DECIMAL(18, 2))

				WHEN (select BillingAmount from [dbo].SalesOrderCharges WITH (NOLOCK) where SalesOrderId = @SalesOrderId AND ItemMasterId = sop.ItemMasterId AND IsActive = 1 AND IsDeleted = 0) = NULL THEN 0
				ELSE
					CAST(ISNULL((select BillingAmount FROM [dbo].SalesOrderCharges WITH (NOLOCK) WHERE SalesOrderId = @SalesOrderId AND ItemMasterId = sop.ItemMasterId AND IsActive = 1 AND IsDeleted = 0), 0) AS DECIMAL(18, 2))
			END AS MiscCharges,	
			ISNULL(partc.TaxPercentage, 0) AS TaxRate,
			ISNULL((partc.TaxPercentage * sop.QtyRequested * partc.UnitSalesPrice) / 100, 0) AS Tax,
			0 AS ShippingAndHandling,
			0 AS OtherTax,
			so.ManagementStructureId,
			so.SalesOrderQuoteNumber AS Barcode
		FROM [dbo].SalesOrderQuote so WITH (NOLOCK)
		LEFT JOIN [dbo].SalesOrderQuotePartV1 sop WITH (NOLOCK) ON so.SalesOrderQuoteId = sop.SalesOrderQuoteId
		LEFT JOIN [dbo].SalesOrderQuoteStocklineV1 stk WITH (NOLOCK) ON sop.SalesOrderQuotePartId = stk.SalesOrderQuotePartId
		LEFT JOIN [dbo].SalesOrderQuotePartCost partc WITH (NOLOCK) ON sop.SalesOrderQuotePartId = partc.SalesOrderQuotePartId
		LEFT JOIN [dbo].ItemMaster itemMaster WITH (NOLOCK) ON sop.ItemMasterId = itemMaster.ItemMasterId
		 AND ISNULL(itemMaster.IsNonStock,0) = 0
		 LEFT JOIN [dbo].UnitOfMeasure iu WITH (NOLOCK) ON itemMaster.ConsumeUnitOfMeasureId = iu.UnitOfMeasureId
		LEFT JOIN [dbo].Condition cp WITH (NOLOCK) ON sop.ConditionId = cp.ConditionId
		LEFT JOIN [dbo].Customer cust WITH (NOLOCK) ON so.CustomerId = cust.CustomerId
		LEFT JOIN [dbo].Address custAddress WITH (NOLOCK) ON cust.AddressId = custAddress.AddressId
		LEFT JOIN [dbo].CustomerFinancial cf WITH (NOLOCK) ON cust.CustomerId = cf.CustomerId
		LEFT JOIN [dbo].Employee emp WITH (NOLOCK) ON so.EmployeeId = emp.EmployeeId
		LEFT JOIN [dbo].Employee sp WITH (NOLOCK) ON so.SalesPersonId = sp.EmployeeId
		LEFT JOIN [dbo].Countries cont WITH (NOLOCK) ON custAddress.CountryId = cont.countries_id
		LEFT JOIN [dbo].Currency cur WITH (NOLOCK) ON so.CurrencyId = cur.CurrencyId
		LEFT JOIN [dbo].CreditTerms ct WITH (NOLOCK) ON cf.CreditTermsId = ct.CreditTermsId
		LEFT JOIN [dbo].StockLine sl WITH (NOLOCK) ON stk.StockLineId = sl.StockLineId AND ISNULL(sl.IsNonStock,0) = 0
		LEFT JOIN [dbo].SalesOrderQuoteFreight soFreight WITH (NOLOCK) ON so.SalesOrderQuoteId = soFreight.SalesOrderQuoteId AND soFreight.IsDeleted = 0 AND soFreight.IsActive = 1
		LEFT JOIN [dbo].SalesOrderQuoteCharges soCharges WITH (NOLOCK) ON so.SalesOrderQuoteId = soCharges.SalesOrderQuoteId AND soCharges.IsDeleted = 0 AND soCharges.IsActive = 1
		LEFT JOIN [dbo].StockLine qs WITH (NOLOCK) ON stk.StockLineId = qs.StockLineId AND ISNULL(qs.IsNonStock,0) = 0
		LEFT JOIN [dbo].PurchaseOrder po WITH (NOLOCK) ON qs.PurchaseOrderId = po.PurchaseOrderId
		LEFT JOIN [dbo].RepairOrder ro WITH (NOLOCK) ON qs.RepairOrderId = ro.RepairOrderId
		WHERE so.SalesOrderQuoteId = @SalesOrderId
		  AND so.IsActive = 1
		  AND so.IsDeleted = 0;
	END TRY 
		BEGIN CATCH      
			IF @@trancount > 0			
            DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_GetSalesOrderQuotePrintData' 
			  , @ProcedureParameters VARCHAR(3000) = '@SalesOrderId = ''' + CAST(ISNULL(@SalesOrderId, '') AS VARCHAR(100))  
              , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
              exec spLogException 
                       @DatabaseName           = @DatabaseName
                     , @AdhocComments          = @AdhocComments
                     , @ProcedureParameters    = @ProcedureParameters
                     , @ApplicationName        =  @ApplicationName
                     , @ErrorLogID                    = @ErrorLogID OUTPUT ;
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
              RETURN(1);
        END CATCH    

END