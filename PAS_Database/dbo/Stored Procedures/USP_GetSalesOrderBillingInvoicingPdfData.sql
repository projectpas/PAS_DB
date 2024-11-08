/*************************************************************           
 ** File:   [USP_GetSalesOrderBillingInvoicingPdfData]           
 ** Author:  Moin Bloch
 ** Description: This stored procedure is used to Get SalesOrder Billing Invoicing Pdf Data 
 ** Purpose:         
 ** Date:   20/02/2024   
          
 ** PARAMETERS: @SOBillingInvoicingId bigint
         
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    20/02/2024   Moin Bloch     Created
	2	 29/03/2024   Bhargav Saliya  Get CreditTermsName and NetDays From SO instead of CreditTerms
	3	 27/07/2024   Bhargav Saliya  Get/added ShippingTerms
	4	 19/09/2024   AMIT GHEDIYA    Get Cur from header for pdf.
	3    10/16/2024	  Abhishek Jirawla	Implemented the new tables for SalesOrder related tables
     
-- EXEC USP_GetSalesOrderBillingInvoicingPdfData 765
************************************************************************/
CREATE PROCEDURE [dbo].[USP_GetSalesOrderBillingInvoicingPdfData]  
@SOBillingInvoicingId BIGINT
AS  
BEGIN  
 SET NOCOUNT ON;  
 SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED  
  BEGIN TRY  
	DECLARE @SalesOrderId BIGINT = 0;
	DECLARE @Customer INT = 0
	DECLARE @Vendor INT = 0
	DECLARE @Company INT = 0

	SELECT @Customer = [ModuleId] FROM dbo.Module WITH(NOLOCK) WHERE [ModuleName] = 'Customer';
	SELECT @Vendor = [ModuleId] FROM dbo.Module WITH(NOLOCK) WHERE [ModuleName] = 'Vendor';
	SELECT @Company = [ModuleId] FROM dbo.Module WITH(NOLOCK) WHERE [ModuleName] = 'Company';
	SELECT @SalesOrderId = [SalesOrderId] FROM dbo.SalesOrderBillingInvoicing WITH(NOLOCK) WHERE [SOBillingInvoicingId] = @SObillingInvoicingId;
	DECLARE @moduleId BIGINT;
	SET @moduleId = (SELECT ModuleId FROM dbo.module WHERE CodePrefix = 'SO');

	SELECT TOP 1 
			1 AS ItemNo,
			bi.SalesOrderId,
			so.CustomerId,
			cust.Name AS ClientName,
			cust.Email AS CustEmail,
			bi.Notes AS SONotes,
			ISNULL(cont.countries_name, '') AS CustCountry,
			ISNULL(sp.FirstName + ' ' + sp.LastName, '') AS SalesPerson,
			ISNULL(po.PurchaseOrderNumber, '') + '/' + ISNULL(ro.RepairOrderNumber, '') AS PORONum,
			custAddress.Line1 AS AddressLine1,
			custAddress.Line2 AS AddressLine2,
			custAddress.City,
			custAddress.StateOrProvince AS [State],
			custAddress.PostalCode,
			cust.CustomerPhone AS PhoneFax,
			saos.ShipToSiteName AS SiteName,
			saos.ShipToAddress1 AS ShipToAddressLine1,
			saos.ShipToAddress2 AS ShipToAddressLine2,
			saos.ShipToCity AS ShipToCity,
			saos.ShipToState AS ShipToState,
			saos.ShipToZip AS ShipToPostalCode,
			shipToCountry.countries_name AS ShipToCountry,
			bi.ShipToCustomerId,
			bi.ShipToSiteId,
			CASE WHEN bi.ShipToUserType = @Customer THEN shipToSites.SiteName
				 WHEN bi.ShipToUserType = @Vendor THEN shipToSiteVendor.SiteName
				 WHEN bi.ShipToUserType = @Company THEN shipToSiteCompany.SiteName
				 ELSE ''
			END AS ShipToSiteName,

			CASE WHEN bi.BillToUserType = @Customer THEN billToSite.SiteName
				 WHEN bi.BillToUserType = @Vendor THEN billToSiteVendor.SiteName
				 WHEN bi.BillToUserType = @Company THEN billToSiteCompany.SiteName
				 ELSE ''
			END AS BillToSiteName,
			CASE WHEN bi.BillToUserType = @Customer THEN billToAddress.Line1
				 WHEN bi.BillToUserType = @Vendor THEN billToAddressVendor.Line1
				 WHEN bi.BillToUserType = @Company THEN billToAddressCompany.Line1
				 ELSE ''
			END AS BillToAddressLine1,
			CASE WHEN bi.BillToUserType = @Customer THEN billToAddress.Line2
				 WHEN bi.BillToUserType = @Vendor THEN billToAddressVendor.Line2
				 WHEN bi.BillToUserType = @Company THEN billToAddressCompany.Line2
				 ELSE ''
			END AS BillToAddressLine2,
			CASE WHEN bi.BillToUserType = @Customer THEN billToAddress.City
				 WHEN bi.BillToUserType = @Vendor THEN billToAddressVendor.City
				 WHEN bi.BillToUserType = @Company THEN billToAddressCompany.City
				 ELSE ''
			END AS BillToCity,
			CASE WHEN bi.BillToUserType = @Customer THEN billToAddress.StateOrProvince
				 WHEN bi.BillToUserType = @Vendor THEN billToAddressVendor.StateOrProvince
				 WHEN bi.BillToUserType = @Company THEN billToAddressCompany.StateOrProvince
				 ELSE ''
			END AS BillToState,
			CASE WHEN bi.BillToUserType = @Customer THEN billToAddress.PostalCode
				 WHEN bi.BillToUserType = @Vendor THEN billToAddressVendor.PostalCode
				 WHEN bi.BillToUserType = @Company THEN billToAddressCompany.PostalCode
				 ELSE ''
			END AS BillToPostalCode,
			CASE WHEN bi.BillToUserType = @Customer THEN billToCountry.countries_name
				 WHEN bi.BillToUserType = @Vendor THEN billToCountryVendor.countries_name
				 WHEN bi.BillToUserType = @Company THEN billToCountryCompany.countries_name
				 ELSE ''
			END AS BillToCountry,

			CASE WHEN bi.BillToUserType = @Customer THEN billToCustomer.[Name]
				 WHEN bi.BillToUserType = @Vendor THEN billToVendor.VendorName
				 WHEN bi.BillToUserType = @Company THEN billToCompany.CompanyName
				 ELSE ''
			END AS BillToNameOfCustomer,

			CASE WHEN bi.BillToUserType = @Customer THEN billToCustomer.Email
				 WHEN bi.BillToUserType = @Vendor THEN billToVendor.VendorEmail
				 WHEN bi.BillToUserType = @Company THEN ''
				 ELSE ''
			END AS BillToCustomerEmail,	   
			bi.InvoiceNo AS InvoiceNumber,
			ISNULL(CONVERT(VARCHAR(19), bi.InvoiceDate, 121),'') AS DateAndTime,
			ISNULL(CONVERT(VARCHAR,saos.NoOfContainer), '0') AS NoOfContainers,
			ISNULL(contact.FirstName + ' ' + contact.LastName, '') AS BuyersName,
			bi.CreatedBy AS PreparedBy,
			ISNULL(CONVERT(VARCHAR(10), bi.PrintDate, 121),'') AS DatePrinted,
			ISNULL(saos.[Weight], 0) AS 'Weight',
			so.[CreditTermName] AS CreditTerms,
			ISNULL(cur.Code, '') AS Currency,
			so.SalesOrderNumber AS SONum,
			ISNULL(CONVERT(VARCHAR(10), so.OpenDate, 121),'') AS OrderDate,
			ISNULL(CONVERT(VARCHAR(10), saos.ShipDate, 121),'') AS ShipDate,
			ISNULL(sipVia.[Name], '') AS ShipVia,
			'' AS ShipAccNumber,           --sipVia.ShippingAccountInfo AS ShipAccNumber,
			saos.SOShippingNum AS ShippingOrderNumber,
			ISNULL(saos.AirwayBill, '') AS Awb,
			bi.InvoiceStatus AS InvoiceStatus,
			so.ManagementStructureId AS ManagementStructureId,
			(bi.InvoiceNo) AS Barcode,  --dbo.PASCommon.BarCodeGenerator
			so.ChargesBilingMethodId AS HeaderMarkupIdCharge,
			so.FreightBilingMethodId AS HeaderMarkupIdFreight,
			so.CustomerReference AS CustomerReference,
			so.UpdatedDate AS UpdatedDate,
			ISNULL(cust.CustomerPhone, '') AS CustomerPhone,
			CASE WHEN bi.PostedDate IS NOT NULL THEN CONVERT(VARCHAR(10), DATEADD(DAY, so.NetDays, bi.InvoiceDate), 121)
				 ELSE ''
			END AS DueDate,
			bi.InvoiceDate AS NewDateAndTime,
			bi.InvoiceDate AS NewDueDate,
			bi.ShipToUserType,
			bi.BillToUserType,
			ShippingTerms = posv.ShippingTerms,
			FunctionalCurrency = scur.Code
		FROM [dbo].[SalesOrderBillingInvoicing] bi WITH(NOLOCK)
		INNER JOIN	[dbo].[SalesOrder] so WITH(NOLOCK) ON bi.SalesOrderId = so.SalesOrderId
		 LEFT JOIN  [dbo].[SalesOrderPartV1] sop WITH(NOLOCK) ON so.SalesOrderId = sop.SalesOrderId
		 LEFT JOIN  [dbo].[SalesOrderStocklineV1] sov WITH(NOLOCK) ON sop.SalesOrderPartId = sov.SalesOrderPartId
		 LEFT JOIN  [dbo].[Customer] cust WITH(NOLOCK) ON bi.CustomerId = cust.CustomerId
		 LEFT JOIN  [dbo].[Address] custAddress WITH(NOLOCK) ON cust.AddressId = custAddress.AddressId
		 LEFT JOIN  [dbo].[CustomerContact] cust_cont WITH(NOLOCK) ON so.CustomerContactId = cust_cont.CustomerContactId
		 LEFT JOIN  [dbo].[Contact] contact WITH(NOLOCK) ON cust_cont.ContactId = contact.ContactId
		 LEFT JOIN  [dbo].[CustomerFinancial] cf WITH(NOLOCK) ON cust.CustomerId = cf.CustomerId
		 LEFT JOIN  [dbo].[InvoiceType] it WITH(NOLOCK) ON bi.InvoiceTypeId = it.InvoiceTypeId
		 LEFT JOIN  [dbo].[Employee] emp WITH(NOLOCK) ON bi.EmployeeId = emp.EmployeeId
		 LEFT JOIN  [dbo].[Customer] soldToCustomer WITH(NOLOCK) ON bi.SoldToCustomerId = soldToCustomer.CustomerId
		 LEFT JOIN  [dbo].[CustomerDomensticShipping] shipToSites WITH(NOLOCK) ON bi.ShipToSiteId = shipToSites.CustomerDomensticShippingId AND bi.ShipToUserType = @Customer
		 LEFT JOIN  [dbo].[VendorShippingAddress] shipToSiteVendor WITH(NOLOCK) ON bi.ShipToSiteId = shipToSiteVendor.VendorShippingAddressId AND bi.ShipToUserType = @Vendor
		 LEFT JOIN  [dbo].[LegalEntityShippingAddress] shipToSiteCompany WITH(NOLOCK) ON bi.ShipToSiteId = shipToSiteCompany.LegalEntityShippingAddressId AND bi.ShipToUserType = @Company
		 LEFT JOIN  [dbo].[Customer] billToCustomer WITH(NOLOCK) ON bi.BillToCustomerId = billToCustomer.CustomerId
		 LEFT JOIN  [dbo].[Vendor] AS billToVendor WITH(NOLOCK) ON bi.BillToCustomerId = billToVendor.VendorId
		 LEFT JOIN  [dbo].[LegalEntity] AS billToCompany WITH(NOLOCK) ON bi.BillToCustomerId = billToCompany.LegalEntityId
		 LEFT JOIN  [dbo].[CustomerBillingAddress] AS billToSite WITH(NOLOCK) ON bi.BillToSiteId = billToSite.CustomerBillingAddressId
		 LEFT JOIN  [dbo].[VendorBillingAddress] AS billToSiteVendor WITH(NOLOCK) ON bi.BillToSiteId = billToSiteVendor.VendorBillingAddressId
		 LEFT JOIN  [dbo].[LegalEntityBillingAddress] AS billToSiteCompany WITH(NOLOCK) ON bi.BillToSiteId = billToSiteCompany.LegalEntityBillingAddressId
		 LEFT JOIN  [dbo].[Address] AS billToAddress WITH(NOLOCK) ON billToSite.AddressId = billToAddress.AddressId
		 LEFT JOIN  [dbo].[Address] AS billToAddressVendor WITH(NOLOCK) ON billToSiteVendor.AddressId = billToAddressVendor.AddressId
		 LEFT JOIN  [dbo].[Address] AS billToAddressCompany WITH(NOLOCK) ON billToSiteCompany.AddressId = billToAddressCompany.AddressId
		 LEFT JOIN  [dbo].[Countries] AS billToCountry WITH(NOLOCK) ON billToAddress.CountryId = billToCountry.countries_id
		 LEFT JOIN  [dbo].[Countries] AS billToCountryVendor WITH(NOLOCK) ON billToAddressVendor.CountryId = billToCountryVendor.countries_id
		 LEFT JOIN  [dbo].[Countries] AS billToCountryCompany WITH(NOLOCK) ON billToAddressCompany.CountryId = billToCountryCompany.countries_id
		 LEFT JOIN  [dbo].[Employee] AS sp WITH(NOLOCK) ON so.SalesPersonId = sp.EmployeeId
		 LEFT JOIN  [dbo].[Countries] AS cont WITH(NOLOCK) ON custAddress.CountryId = cont.countries_id
		 LEFT JOIN  [dbo].[Currency] AS cur WITH(NOLOCK) ON bi.CurrencyId = cur.CurrencyId
		 LEFT JOIN  [dbo].[Currency] AS scur WITH(NOLOCK) ON so.FunctionalCurrencyId = scur.CurrencyId
		 --LEFT JOIN  [dbo].[CreditTerms] AS ct WITH(NOLOCK) ON cf.CreditTermsId = ct.CreditTermsId
		 LEFT JOIN  [dbo].[StockLine] AS sl WITH(NOLOCK) ON sov.StockLineId = sl.StockLineId
		 LEFT JOIN  [dbo].[SalesOrderBillingInvoicingItem] AS sabi WITH(NOLOCK) ON bi.SOBillingInvoicingId = sabi.SOBillingInvoicingId
		 LEFT JOIN  [dbo].[SalesOrderShipping] AS saos WITH(NOLOCK) ON sabi.SalesOrderShippingId = saos.SalesOrderShippingId AND saos.SalesOrderId = @SalesOrderId
		 LEFT JOIN  [dbo].[ShippingVia] AS sipVia WITH(NOLOCK) ON saos.ShipviaId = sipVia.ShippingViaId
		 LEFT JOIN  [dbo].[Countries] AS shipToCountry WITH(NOLOCK) ON saos.ShipToCountryId = shipToCountry.countries_id
		 LEFT JOIN  [dbo].[PurchaseOrder] AS po WITH(NOLOCK) ON sl.PurchaseOrderId = po.PurchaseOrderId
		 LEFT JOIN  [dbo].[RepairOrder] AS ro WITH(NOLOCK) ON sl.RepairOrderId = ro.RepairOrderId
		 LEFT JOIN  [dbo].AllShipVia posv WITH(NOLOCK) ON so.SalesOrderId = posv.ReferenceId AND posv.ModuleId = @moduleId
		 WHERE bi.SOBillingInvoicingId = @SOBillingInvoicingId AND bi.IsActive = 1 AND bi.IsDeleted = 0;

 END TRY      
 BEGIN CATCH        
  IF @@trancount > 0  
   PRINT 'ROLLBACK'    
   DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()     
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------  
            , @AdhocComments     VARCHAR(150)    = 'GetLaborOHSettingsByManagementStructureId'              
			, @ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@SOBillingInvoicingId, '') AS VARCHAR(100))           
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