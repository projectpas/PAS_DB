/*************************************************************           
 ** File:   [USP_GetWorkOrderBillingInvoicingPdfData]           
 ** Author:   Moin Bloch 
 ** Description: This stored procedure is used to GET Work Order Billing Invoicing Pdf Data
 ** Purpose:         
 ** Date:   26/03/2025      
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    26/03/2025   Moin Bloch    Created
	2    07/04/2025   Moin Bloch    Added [IsVersionIncrease] Condition
 	3    06/05/2025   RAJESH GAMI   Customer Domenstic Shipping Via ID Changes 
--   EXEC [USP_GetWorkOrderBillingInvoicingPdfData] 3296
**************************************************************/
CREATE   PROCEDURE [dbo].[USP_GetWorkOrderBillingInvoicingPdfData]
@BillingInvoicingId BIGINT = NULL
AS
BEGIN
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	BEGIN TRY
	
		SELECT TOP 1 
			1 AS [ItemNo],
			WO.[IsSinglePN],
			BI.[WorkOrderId],
			WO.[CustomerId],
			CUST.[Name]  [ClientName],
			CUST.[Email] [CustEmail],
			BI.[Notes] [WONotes],
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
			-- BILL TO ADDRESS END 
			BILLTOCUSTOMER.[Name] [BillToNameOfCustomer],
			BI.[InvoiceNo] [InvoiceNumber],
			CASE WHEN BI.[InvoiceDate] IS NOT NULL THEN FORMAT(BI.[InvoiceDate], 'MM/dd/yyyy h:mm tt') ELSE '' END [DateAndTime],
			ISNULL(CAST(SHIPPINGINFO.[NoOfContainer] AS NVARCHAR), '0') [NoOfContainers],
			ISNULL(CONTACT.[FirstName] + ' ' + CONTACT.[LastName], '') [BuyersName],
			BI.[CreatedBy] [PreparedBy],
			FORMAT(BI.[PrintDate], 'MM/dd/yyyy h:mm tt') [DatePrinted],
			ISNULL(CAST(SHIPPINGINFO.[Weight] AS NVARCHAR), '0') [Weight],
			WO.[CreditTerms],
			ISNULL(cur.[Code], '') [Currency],
			WO.[WorkOrderNum] [WONum],
			FORMAT(WO.[OpenDate], 'MM/dd/yyyy') [OrderDate],
			FORMAT(SHIPPINGINFO.[ShipDate], 'MM/dd/yyyy') [ShipDate],
			(CASE WHEN ISNULL(BI.IsCustomerShipping,0) = 1 THEN ISNULL(SHIPVIACust.[Name], '') ELSE  ISNULL(SHIPINFOVIA.[Name], '') END) AS [ShipVia],
			BI.[ShippingAccountInfo] [ShipAccNumber],
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
			BI.[WorkFlowWorkOrderId],
			WO.[MasterCompanyId],
			ISNULL(BI.[SalesTax], 0) [Tax],
			ISNULL(BI.[OtherTax], 0) [OtherTax]
		FROM [dbo].[WorkOrderBillingInvoicing] BI WITH(NOLOCK)
		INNER JOIN [dbo].[WorkOrder] WO WITH(NOLOCK) ON BI.[WorkOrderId] = WO.[WorkOrderId]
		INNER JOIN [dbo].[Customer] CUST WITH(NOLOCK) ON BI.[CustomerId] = CUST.[CustomerId]
		INNER JOIN [dbo].[Address] CUSTADDRESS WITH(NOLOCK) ON CUST.[AddressId] = CUSTADDRESS.[AddressId]
		 LEFT JOIN [dbo].[CustomerContact] CUSTCONT WITH(NOLOCK) ON WO.[CustomerContactId] = CUSTCONT.[CustomerContactId]
		 LEFT JOIN [dbo].[Contact] CONTACT WITH(NOLOCK) ON CUSTCONT.[ContactId] = CONTACT.[ContactId]
		INNER JOIN [dbo].[Customer] BILLTOCUSTOMER WITH(NOLOCK) ON BI.[SoldToCustomerId] = BILLTOCUSTOMER.[CustomerId]		
		INNER JOIN [dbo].[CustomerBillingAddress] BILLTOSITE WITH(NOLOCK) ON BI.[SoldToSiteId] = BILLTOSITE.[CustomerBillingAddressId]
		INNER JOIN [dbo].[Address] BILLTOADDRESS WITH(NOLOCK) ON BILLTOSITE.[AddressId] = BILLTOADDRESS.[AddressId]
		 LEFT JOIN [dbo].[Countries] BILLTOCOUNTRY WITH(NOLOCK) ON BILLTOADDRESS.[CountryId] = BILLTOCOUNTRY.[countries_id]
		INNER JOIN [dbo].[CustomerDomensticShipping] SHIPTOSITE WITH(NOLOCK) ON BI.[ShipToSiteId] = SHIPTOSITE.[CustomerDomensticShippingId]
		INNER JOIN [dbo].[Address] SHIPTOADDRESS WITH(NOLOCK) ON SHIPTOSITE.[AddressId] = SHIPTOADDRESS.[AddressId]
		 LEFT JOIN [dbo].[Employee] SP WITH(NOLOCK) ON WO.[SalesPersonId] = SP.[EmployeeId]
		 LEFT JOIN [dbo].[Countries] CONT WITH(NOLOCK) ON CUSTADDRESS.[CountryId] = CONT.[countries_id]
		 LEFT JOIN [dbo].[Currency] CUR WITH(NOLOCK) ON BI.[CurrencyId] = CUR.[CurrencyId]
		 LEFT JOIN [dbo].[WorkOrderShipping] SHIPPINGINFO WITH(NOLOCK) ON BI.[WorkOrderShippingId] = SHIPPINGINFO.[WorkOrderShippingId]
		 LEFT JOIN [dbo].[ShippingVia] SHIPINFOVIA WITH(NOLOCK) ON BI.[ShipViaId] = SHIPINFOVIA.[ShippingViaId]
		 LEFT JOIN [dbo].[ShippingVia] SHIPVIACust WITH(NOLOCK) ON BI.[CustomerDomensticShippingShipViaId] = SHIPVIACust.[ShippingViaId]
		 LEFT JOIN [dbo].[Countries] SHIPTOCOUNTRY WITH(NOLOCK) ON SHIPPINGINFO.[ShipToCountryId] = SHIPTOCOUNTRY.[countries_id]
		 LEFT JOIN (
			SELECT WOP.[CustomerReference], WFWO.[WorkFlowWorkOrderId]
			FROM [dbo].[WorkOrderBillingInvoicing] T WITH(NOLOCK)
			INNER JOIN [dbo].[WorkOrderWorkFlow] WFWO WITH(NOLOCK) ON T.[WorkFlowWorkOrderId] = WFWO.[WorkFlowWorkOrderId]
			INNER JOIN [dbo].[WorkOrderPartNumber] WOP WITH(NOLOCK) ON WFWO.[WorkOrderPartNoId] = WOP.[ID]
			WHERE T.[BillingInvoicingId] = @BillingInvoicingId
		) AS CUSTREF ON BI.WorkFlowWorkOrderId = CUSTREF.WorkFlowWorkOrderId
		WHERE BI.[BillingInvoicingId] = @BillingInvoicingId AND BI.[IsActive] = 1 AND BI.[IsDeleted] = 0 AND ISNULL(BI.[IsVersionIncrease],0) = 0

	END TRY    
	BEGIN CATCH      
		IF @@trancount > 0
              DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_GetWorkOrderBillingInvoicingPdfData' 
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