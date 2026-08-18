/*************************************************************             
 ** File:   [GetSalesOrderProformaInvoicingPdfData] 
 ** Author:  EKTA CHANDEGRA
 ** Description: This stored procedure is used GetSalesOrderProformaInvoicingPdfData
 ** Purpose:           
 ** Date:  01/02/2025        
            
 ** PARAMETERS: @sobillingInvoicingId bigint  
           
 ** RETURN VALUE:             
 **************************************************************             
 ** Change History             
 **************************************************************             
 ** PR   Date			 Author			Change Description              
 ** --   --------		-------			--------------------------------            
    1    01/02/2025		EKTA CHANDEGRA	 Created  
    2    07-07-2025     Moin Bloch       Changed Old To New Billing Table
    3    09/July/2026     RAJESH GAMI       [PN-17009] - Merge Non-Stock Inventory to Stockline : Get only Stock Inventory Data Where IsNonStock = 0
    4    22/July/2026     RAJESH GAMI       [PN-17350] - Removed leftover IsNonStock=0 exclusion filter from the PN-17008/17009 transitional phase so Non-Stock parts print/display correctly now that Non-Stock is fully merged
exec dbo.GetSalesOrderProformaInvoicingPdfData @sobillingInvoicingId=11201
************************************************************************/ 


CREATE PROCEDURE [dbo].[GetSalesOrderProformaInvoicingPdfData]
    @sobillingInvoicingId BIGINT
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;
	BEGIN TRY
	BEGIN TRANSACTION
			BEGIN	
				DECLARE @SalesOrderId BIGINT = (SELECT ReferenceId FROM [dbo].[BillingInvoicing] WITH(NOLOCK) WHERE [BillingInvoicingId] = @sobillingInvoicingId);
				DECLARE @SalesOrderModuleId INT = (SELECT ModuleId FROM [dbo].[Module] WITH(NOLOCK) WHERE [ModuleName] = 'SalesOrder');
				PRINT @SalesOrderModuleId
				PRINT @SalesOrderId
				SELECT TOP 1
					1 AS ItemNo,
					bi.ReferenceId SalesOrderId,
					so.CustomerId,
					cust.Name AS ClientName,
					cust.Email AS CustEmail,
					bi.Notes AS SONotes,
					ISNULL(cont.countries_name, '') AS CustCountry,
					ISNULL(sp.FirstName + ' ' + sp.LastName, '') AS SalesPerson,
					ISNULL(po.PurchaseOrderNumber, '') + ISNULL('/' + ro.RepairOrderNumber, '') AS PORONum,
					custAddress.Line1 AS ClientAddressLine1,
					custAddress.Line2 AS ClientAddressLine2,
					custAddress.City AS ClientAddressCity,
					custAddress.StateOrProvince AS ClientAddressState,
					custAddress.PostalCode AS ClientAddressPostalCode,
					cust.CustomerPhone AS PhoneFax,
					shippingInfo.ShipToSiteName AS ShipToAddressSiteName,
					shippingInfo.ShipToAddress1 AS ShipToAddressLine1,
					shippingInfo.ShipToAddress2 AS ShipToAddressLine2,
					shippingInfo.ShipToCity AS ShipToAddressCity,
					shippingInfo.ShipToState AS ShipToAddressState,
					shippingInfo.ShipToZip AS ShipToAddressPostalCode,
					shipToCountry.countries_name AS ShipToAddressCountry,
					bid.ShipToCustomerId AS ShipToCustomerId,
					bid.ShipToSiteId AS ShipToSiteId,
					shipToSite.SiteName AS ShipToSiteName,
					billToSite.SiteName AS BillToAddressSiteName,
					billToAddress.Line1 AS BillToAddressLine1,
					billToAddress.Line2 AS BillToAddressLine2,
					billToAddress.City AS BillToAddressCity,
					billToAddress.StateOrProvince AS BillToAddressState,
					billToAddress.PostalCode AS BillToAddressPostalCode,
					billToCountry.countries_name AS BillToAddressCountry,
					billToCustomer.Name AS BillToNameOfCustomer,
					billToCustomer.Email AS BillToCustomerEmail,
					bi.InvoiceNo AS InvoiceNumber,
					CASE 
						WHEN bi.InvoiceDate IS NOT NULL THEN FORMAT(bi.InvoiceDate, 'MM/dd/yyyy h:mm tt')
						ELSE ''
					END AS DateAndTime,
					ISNULL(shippingInfo.NoOfContainer, 0) AS NoOfContainers,
					ISNULL(contact.FirstName + ' ' + contact.LastName,'') AS BuyersName,
					bi.CreatedBy AS PreparedBy,
					CASE 
						WHEN bi.PrintDate IS NOT NULL THEN FORMAT(bi.PrintDate, 'MM/dd/yyyy')
						ELSE ''
					END AS DatePrinted,
					ISNULL(CAST(shippingInfo.Weight AS VARCHAR(10)), '0') AS Weight,
					so.CreditTermName AS CreditTerms,
					ISNULL(cur.Code, '') AS Currency,
					so.SalesOrderNumber AS SONum,
					FORMAT(so.OpenDate, 'MM/dd/yyyy') AS OrderDate,
					CASE 
						WHEN shippingInfo.ShipDate IS NOT NULL THEN FORMAT(shippingInfo.ShipDate, 'MM/dd/yyyy')
						ELSE ''
					END AS ShipDate,
					ISNULL(shipInfoVia.Name, '') AS ShipVia,
					--shipInfoVia.ShippingAccountInfo AS ShipAccNumber,
					shippingInfo.SOShippingNum AS ShippingOrderNumber,
					ISNULL(shippingInfo.AirwayBill, '') AS Awb,
					bi.InvoiceStatus,
					so.ManagementStructureId,
					so.ChargesBilingMethodId AS HeaderMarkupIdCharge,
					so.FreightBilingMethodId AS HeaderMarkupIdFreight,
					so.CustomerReference,
					so.UpdatedDate,
					ISNULL(cust.CustomerPhone, '') AS CustomerPhone,
					CASE 
						WHEN bi.PostedDate IS NOT NULL THEN FORMAT(DATEADD(day, so.NetDays, bi.InvoiceDate), 'MM/dd/yyyy')
						ELSE ''
					END AS DueDate,
					bi.InvoiceDate AS NewDateAndTime,
					bi.InvoiceDate AS NewDueDate,
					ISNULL(allShipVia.ShippingTerms, '') AS ShippingTerms,
					ISNULL(fcu.Code, '') AS FunctionalCurrency
				FROM [dbo].[BillingInvoicing]  bi WITH(NOLOCK)
				LEFT JOIN [dbo].[BillingInvoicingDetails] bid WITH(NOLOCK) ON bi.BillingInvoicingId = bid.BillingInvoicingId
				LEFT JOIN [dbo].[SalesOrder] so WITH(NOLOCK) ON bi.ReferenceId = so.SalesOrderId
				LEFT JOIN [dbo].[SalesOrderPartV1] sop WITH(NOLOCK) ON so.SalesOrderId = sop.SalesOrderId
				LEFT JOIN [dbo].[SalesOrderStockLineV1] sov WITH(NOLOCK) ON sop.SalesOrderPartId = sov.SalesOrderPartId
				LEFT JOIN [dbo].[Customer] cust WITH(NOLOCK) ON bi.CustomerId = cust.CustomerId
				LEFT JOIN [dbo].[Address] custAddress WITH(NOLOCK) ON cust.AddressId = custAddress.AddressId
				LEFT JOIN [dbo].[CustomerContact] cust_cont WITH(NOLOCK) ON so.CustomerContactId = cust_cont.CustomerContactId
				LEFT JOIN [dbo].[Contact] contact  WITH(NOLOCK) ON cust_cont.ContactId = contact.ContactId
				LEFT JOIN [dbo].[CustomerFinancial] cf WITH(NOLOCK) ON cust.CustomerId = cf.CustomerId
				LEFT JOIN [dbo].[InvoiceType] it WITH(NOLOCK) ON bi.InvoiceTypeId = it.InvoiceTypeId
				LEFT JOIN [dbo].[Employee] emp WITH(NOLOCK) ON bi.EmployeeId = emp.EmployeeId
				LEFT JOIN [dbo].[Customer] soldToCustomer WITH(NOLOCK) ON bid.SoldToCustomerId = soldToCustomer.CustomerId
				LEFT JOIN [dbo].[Customer] billToCustomer WITH(NOLOCK) ON bid.SoldToCustomerId = billToCustomer.CustomerId
				LEFT JOIN [dbo].[CustomerBillingAddress] billToSite WITH(NOLOCK) ON bid.SoldToSiteId = billToSite.CustomerBillingAddressId
				LEFT JOIN [dbo].[Address] billToAddress WITH(NOLOCK) ON billToSite.AddressId = billToAddress.AddressId
				LEFT JOIN [dbo].[CustomerDomensticShipping] shipToSite WITH(NOLOCK) ON bid.ShipToSiteId = shipToSite.CustomerDomensticShippingId
				LEFT JOIN [dbo].[Countries] billToCountry WITH(NOLOCK) ON billToAddress.CountryId = billToCountry.countries_id
				LEFT JOIN [dbo].[Employee] sp WITH(NOLOCK) ON so.SalesPersonId = sp.EmployeeId
				LEFT JOIN [dbo].[Countries] cont WITH(NOLOCK) ON custAddress.CountryId = cont.countries_id
				LEFT JOIN [dbo].[Currency] cur WITH(NOLOCK) ON bi.CurrencyId = cur.CurrencyId
				LEFT JOIN [dbo].[CreditTerms] ct WITH(NOLOCK) ON cf.CreditTermsId = ct.CreditTermsId
				LEFT JOIN [dbo].[StockLine] sl WITH(NOLOCK) ON sov.StockLineId = sl.StockLineId
				LEFT JOIN [dbo].[BillingInvoicingItems] bii WITH(NOLOCK) ON bi.BillingInvoicingId = bii.BillingInvoicingId
				LEFT JOIN [dbo].[SalesOrderShipping] shippingInfo WITH(NOLOCK) ON bii.ShippingId = shippingInfo.SalesOrderShippingId AND shippingInfo.SalesOrderId = @SalesOrderId
				LEFT JOIN [dbo].[ShippingVia] shipInfoVia WITH(NOLOCK) ON shippingInfo.ShipviaId = shipInfoVia.ShippingViaId
				LEFT JOIN [dbo].[Countries] shipToCountry WITH(NOLOCK) ON shippingInfo.ShipToCountryId = shipToCountry.countries_id
				LEFT JOIN [dbo].[PurchaseOrder] po WITH(NOLOCK) ON sl.PurchaseOrderId = po.PurchaseOrderId
				LEFT JOIN [dbo].[RepairOrder] ro WITH(NOLOCK) ON sl.RepairOrderId = ro.RepairOrderId
				LEFT JOIN [dbo].[AllShipVia] allShipVia WITH(NOLOCK) ON so.SalesOrderId = allShipVia.ReferenceId AND allShipVia.ModuleId = @SalesOrderModuleId
				LEFT JOIN [dbo].[Currency] fcu WITH(NOLOCK) ON so.FunctionalCurrencyId = fcu.CurrencyId AND ISNULL(fcu.IsActive,0) = 1 AND ISNULL(fcu.IsDeleted,0) = 0
				WHERE bi.BillingInvoicingId = @sobillingInvoicingId
				AND ISNULL(bi.IsActive,0) = 1
				AND ISNULL(bi.IsDeleted,0) = 0;
			END
		COMMIT TRANSACTION
	END TRY
	BEGIN CATCH
		DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------    
            , @AdhocComments     VARCHAR(150)    = 'GetSalesOrderProformaInvoicingPdfData'     
            , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ CAST(ISNULL(@sobillingInvoicingId, '') AS varchar(100) ) + ''
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