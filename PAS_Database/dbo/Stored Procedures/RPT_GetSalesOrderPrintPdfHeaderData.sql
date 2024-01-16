/*************************************************************  
** Author:  <AMIT GHEDIYA>  
** Create date: <01/09/2024>  
** Description: 
 
EXEC [RPT_GetSalesOrderPrintPdfHeaderData]
**************************************************************
** Change History
**************************************************************  
** PR   Date        Author          Change Description  
** --   --------    -------         --------------------------------
** 1    01/09/2024  AMIT GHEDIYA    Created

EXEC RPT_GetSalesOrderPrintPdfHeaderData 781

**************************************************************/
CREATE     PROCEDURE [dbo].[RPT_GetSalesOrderPrintPdfHeaderData]              
	@salesOrderId BIGINT            
AS              
BEGIN              
 SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED              
 SET NOCOUNT ON;              
             
  BEGIN TRY              
   BEGIN            
		SELECT TOP 1
			sop.ItemNo,
			so.CustomerId,
			UPPER(ISNULL(cust.Name, '')) AS ClientName,
			UPPER(ISNULL(cust.Email, '')) AS CustEmail,
			UPPER(ISNULL(cust.CustomerPhone, '')) AS CustomerPhone,
			so.Notes AS SONotes,
			UPPER(ISNULL(po.PurchaseOrderNumber, '') + ISNULL('/' + ro.RepairOrderNumber, '')) AS PORONum,
			UPPER(ISNULL(cont.countries_name, '')) AS CustCountry,
			UPPER(ISNULL(sp.FirstName + ' ' + sp.LastName, '')) AS SalesPerson,
			UPPER(custAddress.Line1) AS AddressLine1,
			UPPER(custAddress.Line2) AS AddressLine2,
			UPPER(custAddress.City) AS City,
			UPPER(custAddress.StateOrProvince) AS State,
			UPPER(custAddress.PostalCode) AS PostalCode,
			ISNULL(cust.CustomerPhone, '') AS PhoneFax,
			'' AS BuyersName,
			UPPER(ISNULL(ct.Name, '')) AS CreditTerms,
			UPPER(ISNULL(cur.DisplayName, '')) AS Currency,
			UPPER(so.SalesOrderNumber) AS SONum,
			so.OpenDate AS OrderDate,
			CONVERT(VARCHAR, sop.EstimatedShipDate, 101) AS ShipDate,
			Awb = (SELECT TOP 1 sos.AirwayBill
					FROM dbo.SalesOrder so WITH(NOLOCK)
				  LEFT JOIN dbo.SalesOrderShipping sos WITH(NOLOCK) ON so.SalesOrderId = sos.SalesOrderId
					WHERE sos.SalesOrderId = @salesOrderId),
			CASE
				WHEN so.FreightBilingMethodId = 3 THEN so.TotalFreight
				ELSE ISNULL(soFreight.BillingAmount, 0)
			END AS Freight,
			CASE
				WHEN so.ChargesBilingMethodId = 3 THEN so.TotalCharges
				ELSE ISNULL(soCharges.BillingAmount, 0)
			END AS MiscCharges,
			ISNULL(sop.TaxPercentage, 0) AS TaxRate,
			0 AS ShippingAndHandling,
			so.ManagementStructureId,
			UPPER(so.CustomerReference) AS CustomerReference
		FROM dbo.SalesOrder so WITH(NOLOCK)
			LEFT JOIN dbo.SalesOrderPart sop WITH(NOLOCK) ON so.SalesOrderId = sop.SalesOrderId
			LEFT JOIN dbo.ItemMaster itemMaster WITH(NOLOCK) ON sop.ItemMasterId = itemMaster.ItemMasterId
			LEFT JOIN dbo.UnitOfMeasure uom WITH(NOLOCK) ON itemMaster.ConsumeUnitOfMeasureId = uom.UnitOfMeasureId
			LEFT JOIN dbo.Condition cp WITH(NOLOCK) ON sop.ConditionId = cp.ConditionId
			INNER JOIN dbo.Customer cust WITH(NOLOCK) ON so.CustomerId = cust.CustomerId
			INNER JOIN dbo.Address custAddress WITH(NOLOCK) ON cust.AddressId = custAddress.AddressId
			LEFT JOIN dbo.CustomerFinancial cf WITH(NOLOCK) ON cust.CustomerId = cf.CustomerId
			LEFT JOIN dbo.Employee emp WITH(NOLOCK) ON so.EmployeeId = emp.EmployeeId
			LEFT JOIN dbo.Employee sp WITH(NOLOCK) ON so.SalesPersonId = sp.EmployeeId
			LEFT JOIN dbo.Countries cont WITH(NOLOCK) ON custAddress.CountryId = cont.countries_id
			LEFT JOIN dbo.Currency cur WITH(NOLOCK) ON so.CurrencyId = cur.CurrencyId
			INNER JOIN dbo.CreditTerms ct WITH(NOLOCK) ON cf.CreditTermsId = ct.CreditTermsId
			LEFT JOIN dbo.StockLine sl WITH(NOLOCK) ON sop.StockLineId = sl.StockLineId
			LEFT JOIN dbo.SalesOrderFreight soFreight WITH(NOLOCK) ON so.SalesOrderId = soFreight.SalesOrderId AND soFreight.IsDeleted = 0 AND soFreight.IsActive = 1
			LEFT JOIN dbo.SalesOrderCharges soCharges WITH(NOLOCK) ON so.SalesOrderId = soCharges.SalesOrderId AND soCharges.IsDeleted = 0 AND soCharges.IsActive = 1
			LEFT JOIN dbo.StockLine qs WITH(NOLOCK) ON sop.StockLineId = qs.StockLineId
			LEFT JOIN dbo.PurchaseOrder po WITH(NOLOCK) ON qs.PurchaseOrderId = po.PurchaseOrderId
			LEFT JOIN dbo.RepairOrder ro WITH(NOLOCK) ON qs.RepairOrderId = ro.RepairOrderId
		WHERE so.SalesOrderId = @salesOrderId AND so.IsActive = 1 AND so.IsDeleted = 0
         
   END              
  END TRY                  
  BEGIN CATCH                    
   IF @@trancount > 0              
    PRINT 'ROLLBACK'              
    ROLLBACK TRAN;              
    DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()              
             
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------              
              , @AdhocComments     VARCHAR(150)    = 'RPT_GetSalesOrderPrintPdfHeaderData'              
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@salesOrderId, '')              
              , @ApplicationName VARCHAR(100) = 'PAS'              
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------              
             
              exec spLogException              
                       @DatabaseName           = @DatabaseName              
                     , @AdhocComments          = @AdhocComments              
                     , @ProcedureParameters    = @ProcedureParameters              
                     , @ApplicationName        = @ApplicationName              
                     , @ErrorLogID                    = @ErrorLogID OUTPUT ;              
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)              
              RETURN(1);              
  END CATCH              
END