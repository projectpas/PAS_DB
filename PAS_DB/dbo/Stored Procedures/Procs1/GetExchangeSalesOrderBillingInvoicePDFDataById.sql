/*************************************************************           
 ** File:   [GetExchangeSalesOrderBillingInvoicePDFDataById]           
 ** Author:  Ekta Chandegra
 ** Description: This stored procedure is used to GetExchangeSalesOrderBillingInvoicePDFDataById
 ** Purpose:         
 ** Date:   06/11/2025      
          
 ** PARAMETERS: @ExchangeSOBillingInvoicingId bigint
         
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date         Author			Change Description            
 ** --   --------     -------			--------------------------------          
    1    06/11/2025   Ekta Chandegra     Created
     
 EXEC GetExchangeSalesOrderBillingInvoicePDFDataById @ExchangeSOBillingInvoicingId=144
************************************************************************/
CREATE   PROCEDURE [dbo].[GetExchangeSalesOrderBillingInvoicePDFDataById]
    @ExchangeSOBillingInvoicingId BIGINT
AS
BEGIN
    SET NOCOUNT ON;
	BEGIN TRY
		SELECT TOP 1
			1 AS ItemNo,
			bi.ExchangeSalesOrderId,
			so.CustomerId,
			cust.Name AS ClientName,
			cust.Email AS CustEmail,
			so.Notes AS SONotes,
			ISNULL(cont.countries_name, '') AS CustCountry,
			ISNULL(sp.FirstName + ' ' + sp.LastName, '') AS SalesPerson,

			custAddress.Line1 AS ClientAddressLine1,
			custAddress.Line2 AS ClientAddressLine2,
			custAddress.City AS ClientCity,
			custAddress.StateOrProvince AS ClientState,
			custAddress.PostalCode AS ClientPostalCode,

			cust.CustomerPhone AS PhoneFax,

			shippingInfo.ShipToSiteName AS SiteName,
			shippingInfo.ShipToAddress1 AS ShipToAddressLine1,
			shippingInfo.ShipToAddress2 AS ShipToAddressLine2,
			shippingInfo.ShipToCity AS ShipToCity,
			shippingInfo.ShipToState AS ShipToState,
			shippingInfo.ShipToZip AS ShipToPostalCode,
			shipToCountry.countries_name AS ShipToCountry,

			ISNULL(shipToSite.SiteName, '') AS ShipToSiteName,

			billToAddress.Line1 AS BillToAddressLine1,
			billToAddress.Line2 AS BillToAddressLine2,
			billToAddress.City AS BillToCity,
			billToAddress.StateOrProvince AS BillToState,
			billToAddress.PostalCode AS BillToPostalCode,

			billToCustomer.Name AS BillToNameOfCustomer,
			bi.InvoiceNo AS InvoiceNumber,
			CONVERT(VARCHAR,bi.InvoiceDate, 100) AS DateAndTime,
			ISNULL(CAST(shippingInfo.NoOfContainer AS VARCHAR), '0') AS NoOfContainers,
			ISNULL(contact.FirstName + ' ' + contact.LastName, '') AS BuyersName,
			bi.CreatedBy AS PreparedBy,
			FORMAT(bi.PrintDate, 'MM/dd/yyyy') AS DatePrinted,
			ISNULL(CAST(shippingInfo.Weight AS VARCHAR), '0') AS Weight,
			ct.Name AS CreditTerms,
			ISNULL(cur.DisplayName, '') AS Currency,
			so.ExchangeSalesOrderNumber AS SONum,
			FORMAT(so.OpenDate, 'MM/dd/yyyy') AS OrderDate,
			FORMAT(shippingInfo.ShipDate, 'MM/dd/yyyy') AS ShipDate,
			ISNULL(shipInfoVia.Name, '') AS ShipVia,
			shippingInfo.ShippingAccountNo AS ShipAccNumber,
			shippingInfo.SOShippingNum AS ShippingOrderNumber,
			ISNULL(shippingInfo.AirwayBill, '') AS Awb,
			bi.InvoiceStatus,
			so.ManagementStructureId
		FROM [dbo].[ExchangeSalesOrderBillingInvoicing] bi WITH(NOLOCK)
		INNER JOIN [dbo].[ExchangeSalesOrder] so WITH(NOLOCK) ON bi.ExchangeSalesOrderId = so.ExchangeSalesOrderId
		INNER JOIN [dbo].[Customer] cust WITH(NOLOCK) ON bi.CustomerId = cust.CustomerId
		INNER JOIN [dbo].[Address] custAddress WITH(NOLOCK) ON cust.AddressId = custAddress.AddressId
		INNER JOIN [dbo].[CustomerContact] cust_cont WITH(NOLOCK) ON so.CustomerContactId = cust_cont.CustomerContactId
		LEFT JOIN [dbo].[Contact] contact WITH(NOLOCK) ON cust_cont.ContactId = contact.ContactId
		LEFT JOIN [dbo].[CustomerFinancial] cf WITH(NOLOCK) ON cust.CustomerId = cf.CustomerId
		LEFT JOIN [dbo].[InvoiceType] it WITH(NOLOCK) ON bi.InvoiceTypeId = it.InvoiceTypeId
		LEFT JOIN [dbo].[Employee] emp WITH(NOLOCK) ON bi.EmployeeId = emp.EmployeeId
		LEFT JOIN [dbo].[Customer] soldToCustomer WITH(NOLOCK) ON bi.SoldToCustomerId = soldToCustomer.CustomerId
		LEFT JOIN [dbo].[Customer] billToCustomer WITH(NOLOCK) ON bi.BillToCustomerId = billToCustomer.CustomerId
		LEFT JOIN [dbo].[CustomerBillingAddress] billToSite WITH(NOLOCK) ON bi.BillToSiteId = billToSite.CustomerBillingAddressId
		LEFT JOIN [dbo].[Address] billToAddress WITH(NOLOCK) ON billToSite.AddressId = billToAddress.AddressId
		LEFT JOIN [dbo].[CustomerDomensticShipping] shipToSite WITH(NOLOCK) ON bi.ShipToSiteId = shipToSite.CustomerDomensticShippingId
		LEFT JOIN [dbo].[Employee] sp WITH(NOLOCK) ON so.SalesPersonId = sp.EmployeeId
		LEFT JOIN [dbo].[Countries] cont WITH(NOLOCK) ON custAddress.CountryId = cont.countries_id
		LEFT JOIN [dbo].[Currency] cur WITH(NOLOCK) ON bi.CurrencyId = cur.CurrencyId
		INNER JOIN [dbo].[CreditTerms] ct WITH(NOLOCK) ON cf.CreditTermsId = ct.CreditTermsId
		LEFT JOIN [dbo].[ExchangeSalesOrderShipping] shippingInfo WITH(NOLOCK) ON bi.ExchangeSalesOrderId = shippingInfo.ExchangeSalesOrderId
		LEFT JOIN [dbo].[ShippingVia] shipInfoVia WITH(NOLOCK) ON shippingInfo.ShipviaId = shipInfoVia.ShippingViaId
		LEFT JOIN [dbo].[ExchangeSalesOrderFreight] soFreight WITH(NOLOCK) ON so.ExchangeSalesOrderId = soFreight.ExchangeSalesOrderId
		LEFT JOIN [dbo].[ExchangeSalesOrderCharges] soCharges WITH(NOLOCK) ON so.ExchangeSalesOrderId = soCharges.ExchangeSalesOrderId
		LEFT JOIN [dbo].[Countries] shipToCountry WITH(NOLOCK) ON shippingInfo.ShipToCountryId = shipToCountry.countries_id
		WHERE bi.SOBillingInvoicingId = @ExchangeSOBillingInvoicingId
		  AND ISNULL(bi.IsActive,0) = 1
		  AND ISNULL(bi.IsDeleted,0) = 0
	END TRY
	BEGIN CATCH
	DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()    
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------    
            , @AdhocComments     VARCHAR(150)    = 'GetExchangeSalesOrderBillingInvoicePDFDataById'     
			, @ProcedureParameters VARCHAR(3000) = '@ExchangeSOBillingInvoicingId = ''' + CAST(ISNULL(@ExchangeSOBillingInvoicingId, '') AS VARCHAR(100))
            , @ApplicationName VARCHAR(100) = 'PAS'    
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------    
            exec spLogException     
                    @DatabaseName           = @DatabaseName    
                    , @AdhocComments          = @AdhocComments    
                    , @ProcedureParameters = @ProcedureParameters    
                    , @ApplicationName        =  @ApplicationName    
                    , @ErrorLogID             = @ErrorLogID OUTPUT ;    
            RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)    
            RETURN(1);
	END CATCH
END