/*************************************************************           
 ** File:   [USP_GetCommonBillingInvoicingPdfData]           
 ** Author:   Moin Bloch 
 ** Description: This stored procedure is used to GET Common Billing Invoicing Pdf Data
 ** Purpose:         
 ** Date:   16/05/2025
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    16/05/2025   Moin Bloch		Created
    2    21/05/2025   RAJESH GAMI       Implemented SO3    
	3	 03 JUL 2025  RAJESH GAMI		Change CustomerDomensticShippingShipViaId to ShipViaId 
    4    04/07/2025   Abhishek Jirawla  Get Billing view
--   EXEC [USP_GetCommonBillingInvoicingPdfData] 41,15
**************************************************************/
CREATE   PROCEDURE [dbo].[USP_GetCommonBillingInvoicingPdfData]
@BillingInvoicingId BIGINT = NULL,
@ModuleId INT = NULL,
@IsFromView BIT = NULL
AS
BEGIN
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	BEGIN TRY

	DECLARE @WOModuleId INT,@SOModuleId INT,@EXModuleId INT
	
	SELECT @WOModuleId = [ModuleId] FROM [dbo].[Module] WITH(NOLOCK) WHERE [ModuleName] = 'WorkOrder';
	SELECT @SOModuleId = [ModuleId] FROM [dbo].[Module] WITH(NOLOCK) WHERE [ModuleName] = 'SalesOrder';
	SELECT @EXModuleId = [ModuleId] FROM [dbo].[Module] WITH(NOLOCK) WHERE [ModuleName] = 'ExchangeSalesOrder';
	
	IF ISNULL(@IsFromView, 0) = 0
	BEGIN
		IF(@ModuleId = @WOModuleId) /*********START: WORK ORDER ********/
		BEGIN	
				SELECT TOP 1 
					1 AS [ItemNo],
					WO.[IsSinglePN],
					BI.[ReferenceId],   -- BI.[WorkOrderId],
					WO.[CustomerId],
					CUST.[Name]  [ClientName],
					CUST.[Email] [CustEmail],
					ISNULL(CONT.[countries_name], '') [CustCountry],
					ISNULL(SP.[FirstName] + ' ' + SP.[LastName], '') [SalesPerson],
					-- CLIENT ADDRESS START
					CUSTADDRESS.[Line1]  [ClientAddressLine1],
					CUSTADDRESS.[Line2]  [ClientAddressLine2],
					CUSTADDRESS.[City]   [ClientCity],
					CUSTADDRESS.[StateOrProvince] [ClientState],
					CUSTADDRESS.[PostalCode] [ClientPostalCode],
					-- CLIENT ADDRESS END
					CUST.[CustomerPhone]  [PhoneFax],
					-- SHIP TO ADDRESS START
					SHIPTOSITE.[SiteName] [ShipToSiteName],
					SHIPTOADDRESS.[Line1] [ShipToAddressLine1],
					SHIPTOADDRESS.[Line2] [ShipToAddressLine2],
					SHIPTOADDRESS.[City]  [ShipToCity],
					SHIPTOADDRESS.[StateOrProvince] [ShipToState],
					SHIPTOADDRESS.[PostalCode] [ShipToPostalCode],
					ISNULL(SHIPTOCOUNTRY.[countries_name], '') [ShipToCountry],
					SHIPTOSITE.[Attention] [ShipToAttention],
					-- SHIP TO ADDRESS END
					-- BILL TO ADDRESS START 
					BILLTOSITE.[SiteName] [BillToSiteName],
					BILLTOADDRESS.[Line1] [BillToAddressLine1],
					BILLTOADDRESS.[Line2] [BillToAddressLine2],
					BILLTOADDRESS.[City] [BillToCity],
					BILLTOADDRESS.[StateOrProvince] [BillToState],
					BILLTOADDRESS.[PostalCode] [BillToPostalCode],
					ISNULL(BILLTOCOUNTRY.[countries_name], '') [BillToCountry],
					'' AS [BillToAttention],
					-- BILL TO ADDRESS END 
					BILLTOCUSTOMER.[Name] [BillToNameOfCustomer],
					BILLTOCUSTOMER.Email BillToCustomerEmail,
					BI.[InvoiceNo] [InvoiceNumber],
					CASE WHEN BI.[InvoiceDate] IS NOT NULL THEN FORMAT(BI.[InvoiceDate], 'MM/dd/yyyy h:mm tt') ELSE '' END [DateAndTime],
					ISNULL(CAST(SHIPPINGINFO.[NoOfContainer] AS NVARCHAR), '0') [NoOfContainers],
					ISNULL(CONTACT.[FirstName] + ' ' + CONTACT.[LastName], '') [BuyersName],
					BI.[CreatedBy] [PreparedBy],
					FORMAT(BI.[PrintDate], 'MM/dd/yyyy h:mm tt') [DatePrinted],
					ISNULL(CAST(SHIPPINGINFO.[Weight] AS NVARCHAR), '0') [Weight],
					WO.[CreditTerms],
					ISNULL(cur.[Code], '') [Currency],
					FORMAT(WO.[OpenDate], 'MM/dd/yyyy') [OrderDate],
					FORMAT(SHIPPINGINFO.[ShipDate], 'MM/dd/yyyy') [ShipDate],
					--(CASE WHEN ISNULL(BI.IsCustomerShipping,0) = 1 THEN ISNULL(SHIPVIACust.[Name], '') ELSE  ISNULL(SHIPINFOVIA.[Name], '') END) AS [ShipVia],
					ISNULL(SHIPINFOVIA.[Name], '')  AS [ShipVia],
					BID.[ShipAccountInfo] [ShipAccNumber],
					SHIPPINGINFO.[WOShippingNum] [ShippingOrderNumber],
					ISNULL(SHIPPINGINFO.[AirwayBill], '') [Awb],
					BI.[InvoiceStatus],
					BI.[ManagementStructureId],
					BI.[InvoiceNo] [Barcode],
					WO.[UpdatedDate],
					SHIPPINGINFO.[Shipment],
					CUST.[CustomerCode],
					ISNULL(CUSTREF.[CustomerReference], '') [CustomerReference],
					CUST.[CustomerPhone] [CustToPhone],
					CASE WHEN BI.[PostedDate] IS NOT NULL THEN FORMAT(DATEADD(DAY, ISNULL(WO.[NetDays],0), BI.[InvoiceDate]), 'MM/dd/yyyy') ELSE '' END [DueDate],
					BI.[InvoiceDate] [NewDateAndTime],
					SHIPPINGINFO.[ShipDate] [NewShipDate],
					DATEADD(DAY, ISNULL(WO.[NetDays],0), BI.[InvoiceDate]) [NewDueDate],
					ISNULL(BI.[IsPerformaInvoice], 0) [IsProformaInvoice],
					0 [WorkFlowWorkOrderId],  
					WO.[MasterCompanyId],
					ISNULL(BI.[SalesTax], 0) [Tax],
					ISNULL(BI.[OtherTax], 0) [OtherTax],
					BI.InvoiceTypeId,
					'' AS InvoiceType,
					BI.[Notes] [Notes],
					WO.WorkOrderNum AS ReferenceNo,
					'' AS WorkScope,
					SignEmpName = '',
					SignEmpTitle = '',
					SignEmpDate = bi.CreatedDate,
					'' AS 'WOType',
					BI.RevType,
					BI.InvoiceDate,
					emp.FirstName+' '+emp.LastName AS Employee,
					'' AS Stage
				FROM [dbo].[BillingInvoicing] BI WITH(NOLOCK)		
				INNER JOIN [dbo].[BillingInvoicingDetails] BID WITH(NOLOCK) ON BI.[BillingInvoicingId] = BID.[BillingInvoicingId]
				INNER JOIN [dbo].[WorkOrder] WO WITH(NOLOCK) ON BI.[ReferenceId] = WO.[WorkOrderId]
				INNER JOIN [dbo].[Customer] CUST WITH(NOLOCK) ON WO.[CustomerId] = CUST.[CustomerId]
				INNER JOIN [dbo].[Address] CUSTADDRESS WITH(NOLOCK) ON CUST.[AddressId] = CUSTADDRESS.[AddressId]
				 LEFT JOIN [dbo].[CustomerContact] CUSTCONT WITH(NOLOCK) ON WO.[CustomerContactId] = CUSTCONT.[CustomerContactId]
				 LEFT JOIN [dbo].[Contact] CONTACT WITH(NOLOCK) ON CUSTCONT.[ContactId] = CONTACT.[ContactId]
				INNER JOIN [dbo].[Customer] BILLTOCUSTOMER WITH(NOLOCK) ON BID.[SoldToCustomerId] = BILLTOCUSTOMER.[CustomerId]		
				INNER JOIN [dbo].[CustomerBillingAddress] BILLTOSITE WITH(NOLOCK) ON BID.[SoldToSiteId] = BILLTOSITE.[CustomerBillingAddressId]
				INNER JOIN [dbo].[Address] BILLTOADDRESS WITH(NOLOCK) ON BILLTOSITE.[AddressId] = BILLTOADDRESS.[AddressId]
				 LEFT JOIN [dbo].[Countries] BILLTOCOUNTRY WITH(NOLOCK) ON BILLTOADDRESS.[CountryId] = BILLTOCOUNTRY.[countries_id]
				INNER JOIN [dbo].[CustomerDomensticShipping] SHIPTOSITE WITH(NOLOCK) ON BID.[ShipToSiteId] = SHIPTOSITE.[CustomerDomensticShippingId]
				INNER JOIN [dbo].[Address] SHIPTOADDRESS WITH(NOLOCK) ON SHIPTOSITE.[AddressId] = SHIPTOADDRESS.[AddressId]
				 LEFT JOIN [dbo].[Employee] SP WITH(NOLOCK) ON WO.[SalesPersonId] = SP.[EmployeeId]
				 LEFT JOIN [dbo].[Countries] CONT WITH(NOLOCK) ON CUSTADDRESS.[CountryId] = CONT.[countries_id]
				 LEFT JOIN [dbo].[Currency] CUR WITH(NOLOCK) ON BI.[CurrencyId] = CUR.[CurrencyId]
				 LEFT JOIN [dbo].[WorkOrderShipping] SHIPPINGINFO WITH(NOLOCK) ON BI.[WorkOrderShippingId] = SHIPPINGINFO.[WorkOrderShippingId]
				 LEFT JOIN [dbo].[ShippingVia] SHIPINFOVIA WITH(NOLOCK) ON BID.[ShipviaId] = SHIPINFOVIA.[ShippingViaId]
				 LEFT JOIN [dbo].[Countries] SHIPTOCOUNTRY WITH(NOLOCK) ON SHIPPINGINFO.[ShipToCountryId] = SHIPTOCOUNTRY.[countries_id]
				 LEFT JOIN DBO.Employee emp WITH(NOLOCK) ON bi.EmployeeId = emp.EmployeeId
				 LEFT JOIN (
					SELECT TOP 1 WOP.[CustomerReference],T.[ReferenceId]  --WFWO.WorkFlowWorkOrderId
					FROM [dbo].[BillingInvoicing] T WITH(NOLOCK)
					INNER JOIN [dbo].[BillingInvoicingItems] BII ON T.[BillingInvoicingId] = BII.[BillingInvoicingId]
					INNER JOIN [dbo].[WorkOrderPartNumber] WOP WITH(NOLOCK) ON BII.[SubReferenceId] = WOP.[ID]
					--INNER JOIN [dbo].[WorkOrderWorkFlow] WFWO WITH(NOLOCK) ON WOP.ID = WFWO.WorkOrderPartNoId
					WHERE T.[BillingInvoicingId] = @BillingInvoicingId
				) AS CUSTREF ON BI.[ReferenceId] = CUSTREF.[ReferenceId]
				WHERE BI.[BillingInvoicingId] = @BillingInvoicingId AND BI.[IsActive] = 1 AND BI.[IsDeleted] = 0 AND ISNULL(BI.[IsVersionIncrease],0) = 0
		END  /*********END: WORK ORDER ********/
		ELSE IF(@ModuleId = @SOModuleId) /*********START: SALES ORDER ********/
		BEGIN
				SELECT TOP 1
				
					1 AS [ItemNo],
					1 as [IsSinglePN],
					BI.[ReferenceId],  
					SO.[CustomerId],
					CUST.[Name]  [ClientName],
					CUST.[Email] [CustEmail],
					ISNULL(CONT.[countries_name], '') [CustCountry],
					ISNULL(SP.[FirstName] + ' ' + SP.[LastName], '') [SalesPerson],
		
					CUSTADDRESS.[Line1]  [ClientAddressLine1],
					CUSTADDRESS.[Line2]  [ClientAddressLine2],
					CUSTADDRESS.[City]   [ClientCity],
					CUSTADDRESS.[StateOrProvince] [ClientState],
					CUSTADDRESS.[PostalCode] [ClientPostalCode],
					
					CUST.[CustomerPhone]  [PhoneFax],
				
					SHIPTOSITE.[SiteName] [ShipToSiteName],
					SHIPTOADDRESS.[Line1] [ShipToAddressLine1],
					SHIPTOADDRESS.[Line2] [ShipToAddressLine2],
					SHIPTOADDRESS.[City]  [ShipToCity],
					SHIPTOADDRESS.[StateOrProvince] [ShipToState],
					SHIPTOADDRESS.[PostalCode] [ShipToPostalCode],
					ISNULL(SHIPTOCOUNTRY.[countries_name], '') [ShipToCountry],
					SHIPTOSITE.[Attention] [ShipToAttention],
			
				
					BILLTOSITE.[SiteName] [BillToSiteName],
					BILLTOADDRESS.[Line1] [BillToAddressLine1],
					BILLTOADDRESS.[Line2] [BillToAddressLine2],
					BILLTOADDRESS.[City] [BillToCity],
					BILLTOADDRESS.[StateOrProvince] [BillToState],
					BILLTOADDRESS.[PostalCode] [BillToPostalCode],
					ISNULL(BILLTOCOUNTRY.[countries_name], '') [BillToCountry],
					'' AS [BillToAttention],
					BILLTOCUSTOMER.[Name] [BillToNameOfCustomer],
					BILLTOCUSTOMER.Email BillToCustomerEmail,
					BI.[InvoiceNo] [InvoiceNumber],
					CASE WHEN BI.[InvoiceDate] IS NOT NULL THEN FORMAT(BI.[InvoiceDate], 'MM/dd/yyyy h:mm tt') ELSE '' END [DateAndTime],
					ISNULL(CAST(SHIPPINGINFO.[NoOfContainer] AS NVARCHAR), '0') [NoOfContainers],
					ISNULL(CONTACT.[FirstName] + ' ' + CONTACT.[LastName], '') [BuyersName],
					BI.[CreatedBy] [PreparedBy],
					FORMAT(BI.[PrintDate], 'MM/dd/yyyy h:mm tt') [DatePrinted],
					ISNULL(CAST(SHIPPINGINFO.[Weight] AS NVARCHAR), '0') [Weight],
					SO.CreditTermName AS [CreditTerms],
					ISNULL(cur.[Code], '') [Currency],
					FORMAT(SO.[OpenDate], 'MM/dd/yyyy') [OrderDate],
					FORMAT(SHIPPINGINFO.[ShipDate], 'MM/dd/yyyy') [ShipDate],
					ISNULL(SHIPINFOVIA.[Name], '')  AS [ShipVia],
					BID.[ShipAccountInfo] [ShipAccNumber],
					SHIPPINGINFO.[WOShippingNum] [ShippingOrderNumber],
					ISNULL(SHIPPINGINFO.[AirwayBill], '') [Awb],
					BI.[InvoiceStatus],
					BI.[ManagementStructureId],
					BI.[InvoiceNo] [Barcode],
					SO.[UpdatedDate],
					SHIPPINGINFO.[Shipment],
					CUST.[CustomerCode],
					ISNULL(SO.[CustomerReference], '') [CustomerReference],
					CUST.[CustomerPhone] [CustToPhone],
					CASE WHEN BI.[PostedDate] IS NOT NULL THEN FORMAT(DATEADD(DAY, ISNULL(SO.[NetDays],0), BI.[InvoiceDate]), 'MM/dd/yyyy') ELSE '' END [DueDate],
					BI.[InvoiceDate] [NewDateAndTime],
					SHIPPINGINFO.[ShipDate] [NewShipDate],
					DATEADD(DAY, ISNULL(SO.[NetDays],0), BI.[InvoiceDate]) [NewDueDate],
					ISNULL(BI.[IsPerformaInvoice], 0) [IsProformaInvoice],
					0 [WorkFlowWorkOrderId],  
					SO.[MasterCompanyId],
					ISNULL(BI.[SalesTax], 0) [Tax],
					ISNULL(BI.[OtherTax], 0) [OtherTax],
					BI.InvoiceTypeId,
					'' AS InvoiceType,
					BI.[Notes] [Notes],
					SO.SalesOrderNumber AS ReferenceNo,
					'' AS WorkScope,
					SignEmpName = ISNULL(emp.FirstName,'') + ' ' + ISNULL(emp.LastName,''),
					SignEmpTitle = ISNULL(jt.Description,''),
					SignEmpDate = bi.CreatedDate,
					'' AS 'WOType',
					BI.RevType,
					BI.InvoiceDate,
					emp.FirstName+' '+emp.LastName AS Employee,
					'' AS Stage
				FROM [dbo].[BillingInvoicing] BI WITH(NOLOCK)		
				INNER JOIN [dbo].[BillingInvoicingDetails] BID WITH(NOLOCK) ON BI.[BillingInvoicingId] = BID.[BillingInvoicingId]
				INNER JOIN [dbo].[SalesOrder] SO WITH(NOLOCK) ON BI.[ReferenceId] = SO.[SalesOrderId]
				INNER JOIN [dbo].[Customer] CUST WITH(NOLOCK) ON SO.[CustomerId] = CUST.[CustomerId]
				INNER JOIN [dbo].[Address] CUSTADDRESS WITH(NOLOCK) ON CUST.[AddressId] = CUSTADDRESS.[AddressId]
				 LEFT JOIN [dbo].[CustomerContact] CUSTCONT WITH(NOLOCK) ON SO.[CustomerContactId] = CUSTCONT.[CustomerContactId]
				 LEFT JOIN [dbo].[Contact] CONTACT WITH(NOLOCK) ON CUSTCONT.[ContactId] = CONTACT.[ContactId]
				INNER JOIN [dbo].[Customer] BILLTOCUSTOMER WITH(NOLOCK) ON BID.[SoldToCustomerId] = BILLTOCUSTOMER.[CustomerId]		
				INNER JOIN [dbo].[CustomerBillingAddress] BILLTOSITE WITH(NOLOCK) ON BID.[SoldToSiteId] = BILLTOSITE.[CustomerBillingAddressId]
				INNER JOIN [dbo].[Address] BILLTOADDRESS WITH(NOLOCK) ON BILLTOSITE.[AddressId] = BILLTOADDRESS.[AddressId]
				 LEFT JOIN [dbo].[Countries] BILLTOCOUNTRY WITH(NOLOCK) ON BILLTOADDRESS.[CountryId] = BILLTOCOUNTRY.[countries_id]
				INNER JOIN [dbo].[CustomerDomensticShipping] SHIPTOSITE WITH(NOLOCK) ON BID.[ShipToSiteId] = SHIPTOSITE.[CustomerDomensticShippingId]
				INNER JOIN [dbo].[Address] SHIPTOADDRESS WITH(NOLOCK) ON SHIPTOSITE.[AddressId] = SHIPTOADDRESS.[AddressId]
				 LEFT JOIN [dbo].[Employee] SP WITH(NOLOCK) ON SO.[SalesPersonId] = SP.[EmployeeId]
				 LEFT JOIN [dbo].[Countries] CONT WITH(NOLOCK) ON CUSTADDRESS.[CountryId] = CONT.[countries_id]
				 LEFT JOIN [dbo].[Currency] CUR WITH(NOLOCK) ON BI.[CurrencyId] = CUR.[CurrencyId]
				 LEFT JOIN [dbo].[WorkOrderShipping] SHIPPINGINFO WITH(NOLOCK) ON BI.[WorkOrderShippingId] = SHIPPINGINFO.[WorkOrderShippingId]
				 LEFT JOIN [dbo].[ShippingVia] SHIPINFOVIA WITH(NOLOCK) ON BID.[ShipviaId] = SHIPINFOVIA.[ShippingViaId]
				 LEFT JOIN [dbo].[Countries] SHIPTOCOUNTRY WITH(NOLOCK) ON SHIPPINGINFO.[ShipToCountryId] = SHIPTOCOUNTRY.[countries_id]
				LEFT JOIN  [dbo].[Employee] emp WITH(NOLOCK) ON bi.EmployeeId = emp.EmployeeId
				LEFT JOIN	[dbo].[JobTitle] jt WITH(NOLOCK) ON emp.JobTitleId = jt.JobTitleId
				WHERE BI.[BillingInvoicingId] = @BillingInvoicingId AND BI.[IsActive] = 1 AND BI.[IsDeleted] = 0 AND ISNULL(BI.[IsVersionIncrease],0) = 0
		END
	END
	ELSE
	BEGIN
		IF(@ModuleId = @WOModuleId) /*********START: WORK ORDER ********/
		BEGIN	
				SELECT TOP 1 
					1 AS [ItemNo],
					WO.[IsSinglePN],
					BI.[ReferenceId],   -- BI.[WorkOrderId],
					WO.[CustomerId],
					CUST.[Name]  [ClientName],
					CUST.[Email] [CustEmail],
					ISNULL(CONT.[countries_name], '') [CustCountry],
					ISNULL(SP.[FirstName] + ' ' + SP.[LastName], '') [SalesPerson],
					-- CLIENT ADDRESS START
					CUSTADDRESS.[Line1]  [ClientAddressLine1],
					CUSTADDRESS.[Line2]  [ClientAddressLine2],
					CUSTADDRESS.[City]   [ClientCity],
					CUSTADDRESS.[StateOrProvince] [ClientState],
					CUSTADDRESS.[PostalCode] [ClientPostalCode],
					-- CLIENT ADDRESS END
					CUST.[CustomerPhone]  [PhoneFax],
					-- SHIP TO ADDRESS START
					SHIPTOSITE.[SiteName] [ShipToSiteName],
					SHIPTOADDRESS.[Line1] [ShipToAddressLine1],
					SHIPTOADDRESS.[Line2] [ShipToAddressLine2],
					SHIPTOADDRESS.[City]  [ShipToCity],
					SHIPTOADDRESS.[StateOrProvince] [ShipToState],
					SHIPTOADDRESS.[PostalCode] [ShipToPostalCode],
					ISNULL(SHIPTOCOUNTRY.[countries_name], '') [ShipToCountry],
					SHIPTOSITE.[Attention] [ShipToAttention],
					-- SHIP TO ADDRESS END
					-- BILL TO ADDRESS START 
					BILLTOSITE.[SiteName] [BillToSiteName],
					BILLTOADDRESS.[Line1] [BillToAddressLine1],
					BILLTOADDRESS.[Line2] [BillToAddressLine2],
					BILLTOADDRESS.[City] [BillToCity],
					BILLTOADDRESS.[StateOrProvince] [BillToState],
					BILLTOADDRESS.[PostalCode] [BillToPostalCode],
					ISNULL(BILLTOCOUNTRY.[countries_name], '') [BillToCountry],
					BILLTOSITE.[Attention] AS [BillToAttention],
					-- BILL TO ADDRESS END 
					BILLTOCUSTOMER.[Name] [BillToNameOfCustomer],
					BILLTOCUSTOMER.Email BillToCustomerEmail,
					BI.[InvoiceNo] [InvoiceNumber],
					CASE WHEN BI.[InvoiceDate] IS NOT NULL THEN FORMAT(BI.[InvoiceDate], 'MM/dd/yyyy h:mm tt') ELSE '' END [DateAndTime],
					ISNULL(CAST(SHIPPINGINFO.[NoOfContainer] AS NVARCHAR), '0') [NoOfContainers],
					ISNULL(CONTACT.[FirstName] + ' ' + CONTACT.[LastName], '') [BuyersName],
					BI.[CreatedBy] [PreparedBy],
					FORMAT(BI.[PrintDate], 'MM/dd/yyyy h:mm tt') [DatePrinted],
					ISNULL(CAST(SHIPPINGINFO.[Weight] AS NVARCHAR), '0') [Weight],
					WO.[CreditTerms],
					ISNULL(cur.[Code], '') [Currency],
					FORMAT(WO.[OpenDate], 'MM/dd/yyyy') [OrderDate],
					FORMAT(SHIPPINGINFO.[ShipDate], 'MM/dd/yyyy') [ShipDate],
					--(CASE WHEN ISNULL(BI.IsCustomerShipping,0) = 1 THEN ISNULL(SHIPVIACust.[Name], '') ELSE  ISNULL(SHIPINFOVIA.[Name], '') END) AS [ShipVia],
					ISNULL(SHIPINFOVIA.[Name], '')  AS [ShipVia],
					BID.[ShipAccountInfo] [ShipAccNumber],
					SHIPPINGINFO.[WOShippingNum] [ShippingOrderNumber],
					ISNULL(SHIPPINGINFO.[AirwayBill], '') [Awb],
					BI.[InvoiceStatus],
					BI.[ManagementStructureId],
					BI.[InvoiceNo] [Barcode],
					WO.[UpdatedDate],
					SHIPPINGINFO.[Shipment],
					CUST.[CustomerCode],
					ISNULL(CUSTREF.[CustomerReference], '') [CustomerReference],
					CUST.[CustomerPhone] [CustToPhone],
					CASE WHEN BI.[PostedDate] IS NOT NULL THEN FORMAT(DATEADD(DAY, ISNULL(WO.[NetDays],0), BI.[InvoiceDate]), 'MM/dd/yyyy') ELSE '' END [DueDate],
					BI.[InvoiceDate] [NewDateAndTime],
					SHIPPINGINFO.[ShipDate] [NewShipDate],
					DATEADD(DAY, ISNULL(WO.[NetDays],0), BI.[InvoiceDate]) [NewDueDate],
					ISNULL(BI.[IsPerformaInvoice], 0) [IsProformaInvoice],
					0 [WorkFlowWorkOrderId],  
					WO.[MasterCompanyId],
					ISNULL(BI.[SalesTax], 0) [Tax],
					ISNULL(BI.[OtherTax], 0) [OtherTax],
					BI.InvoiceTypeId,
					InvoiceType.Description AS InvoiceType,
					BI.[Notes] [Notes],
					WO.WorkOrderNum AS ReferenceNo,
					[wop].[WorkScope],
					SignEmpName = '',
					SignEmpTitle = '',
					SignEmpDate = bi.CreatedDate,
					WOT.Description AS 'WOType',
					BI.RevType,
					BI.InvoiceDate,
					emp.FirstName+' '+emp.LastName AS Employee,
					WOS.Code +'-'+WOS.Stage AS Stage
				FROM [dbo].[BillingInvoicing] BI WITH(NOLOCK)		
				INNER JOIN [dbo].[BillingInvoicingDetails] BID WITH(NOLOCK) ON BI.[BillingInvoicingId] = BID.[BillingInvoicingId]
				INNER JOIN [dbo].[WorkOrder] WO WITH(NOLOCK) ON BI.[ReferenceId] = WO.[WorkOrderId]
				INNER JOIN [dbo].[Customer] CUST WITH(NOLOCK) ON WO.[CustomerId] = CUST.[CustomerId]
				INNER JOIN [dbo].[Address] CUSTADDRESS WITH(NOLOCK) ON CUST.[AddressId] = CUSTADDRESS.[AddressId]
				 LEFT JOIN [dbo].[CustomerContact] CUSTCONT WITH(NOLOCK) ON WO.[CustomerContactId] = CUSTCONT.[CustomerContactId]
				 LEFT JOIN [dbo].[Contact] CONTACT WITH(NOLOCK) ON CUSTCONT.[ContactId] = CONTACT.[ContactId]
				INNER JOIN [dbo].[Customer] BILLTOCUSTOMER WITH(NOLOCK) ON BID.[SoldToCustomerId] = BILLTOCUSTOMER.[CustomerId]		
				INNER JOIN [dbo].[CustomerBillingAddress] BILLTOSITE WITH(NOLOCK) ON BID.[SoldToSiteId] = BILLTOSITE.[CustomerBillingAddressId]
				INNER JOIN [dbo].[Address] BILLTOADDRESS WITH(NOLOCK) ON BILLTOSITE.[AddressId] = BILLTOADDRESS.[AddressId]
				 LEFT JOIN [dbo].[Countries] BILLTOCOUNTRY WITH(NOLOCK) ON BILLTOADDRESS.[CountryId] = BILLTOCOUNTRY.[countries_id]
				INNER JOIN [dbo].[CustomerDomensticShipping] SHIPTOSITE WITH(NOLOCK) ON BID.[ShipToSiteId] = SHIPTOSITE.[CustomerDomensticShippingId]
				INNER JOIN [dbo].[Address] SHIPTOADDRESS WITH(NOLOCK) ON SHIPTOSITE.[AddressId] = SHIPTOADDRESS.[AddressId]
				 LEFT JOIN [dbo].[Employee] SP WITH(NOLOCK) ON WO.[SalesPersonId] = SP.[EmployeeId]
				 LEFT JOIN [dbo].[Countries] CONT WITH(NOLOCK) ON CUSTADDRESS.[CountryId] = CONT.[countries_id]
				 LEFT JOIN DBO.WorkOrderType WOT WITH(NOLOCK) on WOT.Id = WO.WorkOrderTypeId
				 LEFT JOIN [dbo].[Currency] CUR WITH(NOLOCK) ON BI.[CurrencyId] = CUR.[CurrencyId]
				 LEFT JOIN [dbo].[WorkOrderShipping] SHIPPINGINFO WITH(NOLOCK) ON BI.[WorkOrderShippingId] = SHIPPINGINFO.[WorkOrderShippingId] 
				 LEFT JOIN [dbo].[WorkOrderPartNumber] [wop] WITH(NOLOCK) ON SHIPPINGINFO.[WorkOrderId] = [wop].[WorkOrderId]
				 LEFT JOIN [dbo].[ShippingVia] SHIPINFOVIA WITH(NOLOCK) ON BID.[ShipviaId] = SHIPINFOVIA.[ShippingViaId]
				 LEFT JOIN [dbo].[Countries] SHIPTOCOUNTRY WITH(NOLOCK) ON SHIPPINGINFO.[ShipToCountryId] = SHIPTOCOUNTRY.[countries_id]
				 LEFT JOIN [dbo].[InvoiceType] InvoiceType WITH(NOLOCK) ON InvoiceType.[InvoiceTypeId] = BI.[InvoiceTypeId]
				 LEFT JOIN DBO.Employee emp WITH(NOLOCK) ON bi.EmployeeId = emp.EmployeeId
				 LEFT JOIN DBO.WorkOrderStage WOS WITH(NOLOCK) on WOP.WorkOrderStageId = WOS.WorkOrderStageId
				 LEFT JOIN (
					SELECT TOP 1 WOP.[CustomerReference],T.[ReferenceId]  --WFWO.WorkFlowWorkOrderId
					FROM [dbo].[BillingInvoicing] T WITH(NOLOCK)
					INNER JOIN [dbo].[BillingInvoicingItems] BII ON T.[BillingInvoicingId] = BII.[BillingInvoicingId]
					INNER JOIN [dbo].[WorkOrderPartNumber] WOP WITH(NOLOCK) ON BII.[SubReferenceId] = WOP.[ID]
					--INNER JOIN [dbo].[WorkOrderWorkFlow] WFWO WITH(NOLOCK) ON WOP.ID = WFWO.WorkOrderPartNoId
					WHERE T.[BillingInvoicingId] = @BillingInvoicingId
				) AS CUSTREF ON BI.[ReferenceId] = CUSTREF.[ReferenceId]
				WHERE BI.[BillingInvoicingId] = @BillingInvoicingId AND BI.[IsActive] = 1 AND BI.[IsDeleted] = 0
		END  /*********END: WORK ORDER ********/
		ELSE IF(@ModuleId = @SOModuleId) /*********START: SALES ORDER ********/
		BEGIN
				SELECT TOP 1
				
					1 AS [ItemNo],
					1 as [IsSinglePN],
					BI.[ReferenceId],  
					SO.[CustomerId],
					CUST.[Name]  [ClientName],
					CUST.[Email] [CustEmail],
					ISNULL(CONT.[countries_name], '') [CustCountry],
					ISNULL(SP.[FirstName] + ' ' + SP.[LastName], '') [SalesPerson],
		
					CUSTADDRESS.[Line1]  [ClientAddressLine1],
					CUSTADDRESS.[Line2]  [ClientAddressLine2],
					CUSTADDRESS.[City]   [ClientCity],
					CUSTADDRESS.[StateOrProvince] [ClientState],
					CUSTADDRESS.[PostalCode] [ClientPostalCode],
					
					CUST.[CustomerPhone]  [PhoneFax],
				
					SHIPTOSITE.[SiteName] [ShipToSiteName],
					SHIPTOADDRESS.[Line1] [ShipToAddressLine1],
					SHIPTOADDRESS.[Line2] [ShipToAddressLine2],
					SHIPTOADDRESS.[City]  [ShipToCity],
					SHIPTOADDRESS.[StateOrProvince] [ShipToState],
					SHIPTOADDRESS.[PostalCode] [ShipToPostalCode],
					ISNULL(SHIPTOCOUNTRY.[countries_name], '') [ShipToCountry],
					SHIPTOSITE.[Attention] [ShipToAttention],
			
				
					BILLTOSITE.[SiteName] [BillToSiteName],
					BILLTOADDRESS.[Line1] [BillToAddressLine1],
					BILLTOADDRESS.[Line2] [BillToAddressLine2],
					BILLTOADDRESS.[City] [BillToCity],
					BILLTOADDRESS.[StateOrProvince] [BillToState],
					BILLTOADDRESS.[PostalCode] [BillToPostalCode],
					ISNULL(BILLTOCOUNTRY.[countries_name], '') [BillToCountry],
					BILLTOSITE.[Attention] AS [BillToAttention],
			
					BILLTOCUSTOMER.[Name] [BillToNameOfCustomer],
					BILLTOCUSTOMER.Email BillToCustomerEmail,
					BI.[InvoiceNo] [InvoiceNumber],
					CASE WHEN BI.[InvoiceDate] IS NOT NULL THEN FORMAT(BI.[InvoiceDate], 'MM/dd/yyyy h:mm tt') ELSE '' END [DateAndTime],
					ISNULL(CAST(SHIPPINGINFO.[NoOfContainer] AS NVARCHAR), '0') [NoOfContainers],
					ISNULL(CONTACT.[FirstName] + ' ' + CONTACT.[LastName], '') [BuyersName],
					BI.[CreatedBy] [PreparedBy],
					FORMAT(BI.[PrintDate], 'MM/dd/yyyy h:mm tt') [DatePrinted],
					ISNULL(CAST(SHIPPINGINFO.[Weight] AS NVARCHAR), '0') [Weight],
					SO.CreditTermName AS [CreditTerms],
					ISNULL(cur.[Code], '') [Currency],
					FORMAT(SO.[OpenDate], 'MM/dd/yyyy') [OrderDate],
					FORMAT(SHIPPINGINFO.[ShipDate], 'MM/dd/yyyy') [ShipDate],
					ISNULL(SHIPINFOVIA.[Name], '')  AS [ShipVia],
					BID.[ShipAccountInfo] [ShipAccNumber],
					SHIPPINGINFO.[WOShippingNum] [ShippingOrderNumber],
					ISNULL(SHIPPINGINFO.[AirwayBill], '') [Awb],
					BI.[InvoiceStatus],
					BI.[ManagementStructureId],
					BI.[InvoiceNo] [Barcode],
					SO.[UpdatedDate],
					SHIPPINGINFO.[Shipment],
					CUST.[CustomerCode],
					ISNULL(SO.[CustomerReference], '') [CustomerReference],
					CUST.[CustomerPhone] [CustToPhone],
					CASE WHEN BI.[PostedDate] IS NOT NULL THEN FORMAT(DATEADD(DAY, ISNULL(SO.[NetDays],0), BI.[InvoiceDate]), 'MM/dd/yyyy') ELSE '' END [DueDate],
					BI.[InvoiceDate] [NewDateAndTime],
					SHIPPINGINFO.[ShipDate] [NewShipDate],
					DATEADD(DAY, ISNULL(SO.[NetDays],0), BI.[InvoiceDate]) [NewDueDate],
					ISNULL(BI.[IsPerformaInvoice], 0) [IsProformaInvoice],
					0 [WorkFlowWorkOrderId],  
					SO.[MasterCompanyId],
					ISNULL(BI.[SalesTax], 0) [Tax],
					ISNULL(BI.[OtherTax], 0) [OtherTax],
					BI.InvoiceTypeId,
					InvoiceType.Description AS InvoiceType,
					BI.[Notes] [Notes],
					SO.SalesOrderNumber AS ReferenceNo,
					'' AS WorkScope,
					SignEmpName = ISNULL(emp.FirstName,'') + ' ' + ISNULL(emp.LastName,''),
					SignEmpTitle = ISNULL(jt.Description,''),
					SignEmpDate = bi.CreatedDate,
					'' AS 'WOType',
					BI.RevType,
					BI.InvoiceDate,
					emp.FirstName+' '+emp.LastName AS Employee,
					'' AS Stage
				FROM [dbo].[BillingInvoicing] BI WITH(NOLOCK)		
				INNER JOIN [dbo].[BillingInvoicingDetails] BID WITH(NOLOCK) ON BI.[BillingInvoicingId] = BID.[BillingInvoicingId]
				INNER JOIN [dbo].[SalesOrder] SO WITH(NOLOCK) ON BI.[ReferenceId] = SO.[SalesOrderId]
				INNER JOIN [dbo].[Customer] CUST WITH(NOLOCK) ON SO.[CustomerId] = CUST.[CustomerId]
				INNER JOIN [dbo].[Address] CUSTADDRESS WITH(NOLOCK) ON CUST.[AddressId] = CUSTADDRESS.[AddressId]
				 LEFT JOIN [dbo].[CustomerContact] CUSTCONT WITH(NOLOCK) ON SO.[CustomerContactId] = CUSTCONT.[CustomerContactId]
				 LEFT JOIN [dbo].[Contact] CONTACT WITH(NOLOCK) ON CUSTCONT.[ContactId] = CONTACT.[ContactId]
				INNER JOIN [dbo].[Customer] BILLTOCUSTOMER WITH(NOLOCK) ON BID.[SoldToCustomerId] = BILLTOCUSTOMER.[CustomerId]		
				INNER JOIN [dbo].[CustomerBillingAddress] BILLTOSITE WITH(NOLOCK) ON BID.[SoldToSiteId] = BILLTOSITE.[CustomerBillingAddressId]
				INNER JOIN [dbo].[Address] BILLTOADDRESS WITH(NOLOCK) ON BILLTOSITE.[AddressId] = BILLTOADDRESS.[AddressId]
				 LEFT JOIN [dbo].[Countries] BILLTOCOUNTRY WITH(NOLOCK) ON BILLTOADDRESS.[CountryId] = BILLTOCOUNTRY.[countries_id]
				INNER JOIN [dbo].[CustomerDomensticShipping] SHIPTOSITE WITH(NOLOCK) ON BID.[ShipToSiteId] = SHIPTOSITE.[CustomerDomensticShippingId]
				INNER JOIN [dbo].[Address] SHIPTOADDRESS WITH(NOLOCK) ON SHIPTOSITE.[AddressId] = SHIPTOADDRESS.[AddressId]
				 LEFT JOIN [dbo].[Employee] SP WITH(NOLOCK) ON SO.[SalesPersonId] = SP.[EmployeeId]
				 LEFT JOIN [dbo].[Countries] CONT WITH(NOLOCK) ON CUSTADDRESS.[CountryId] = CONT.[countries_id]
				 LEFT JOIN [dbo].[Currency] CUR WITH(NOLOCK) ON BI.[CurrencyId] = CUR.[CurrencyId]
				 LEFT JOIN [dbo].[WorkOrderShipping] SHIPPINGINFO WITH(NOLOCK) ON BI.[WorkOrderShippingId] = SHIPPINGINFO.[WorkOrderShippingId]
				 LEFT JOIN [dbo].[ShippingVia] SHIPINFOVIA WITH(NOLOCK) ON BID.[ShipviaId] = SHIPINFOVIA.[ShippingViaId]
				 LEFT JOIN [dbo].[Countries] SHIPTOCOUNTRY WITH(NOLOCK) ON SHIPPINGINFO.[ShipToCountryId] = SHIPTOCOUNTRY.[countries_id]
				 LEFT JOIN [dbo].[InvoiceType] InvoiceType WITH(NOLOCK) ON InvoiceType.[InvoiceTypeId] = BI.[InvoiceTypeId]
				LEFT JOIN  [dbo].[Employee] emp WITH(NOLOCK) ON bi.EmployeeId = emp.EmployeeId
				LEFT JOIN	[dbo].[JobTitle] jt WITH(NOLOCK) ON emp.JobTitleId = jt.JobTitleId
				WHERE BI.[BillingInvoicingId] = @BillingInvoicingId AND BI.[IsActive] = 1 AND BI.[IsDeleted] = 0
		END
	END
	END TRY    
	BEGIN CATCH      
		IF @@trancount > 0
              DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_GetCommonBillingInvoicingPdfData' 
			  , @ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@BillingInvoicingId, '') AS VARCHAR(100)) 
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