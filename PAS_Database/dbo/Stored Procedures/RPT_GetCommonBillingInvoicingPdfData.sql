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
    2    21/05/2025   RAJESH GAMI       Implemented SO
	
--   EXEC [dbo].[RPT_GetCommonBillingInvoicingPdfData] 38,15,2
**************************************************************/
CREATE    PROCEDURE [dbo].[RPT_GetCommonBillingInvoicingPdfData]
@BillingInvoicingId BIGINT = NULL,
@ModuleId INT = NULL,
@EmployeeId BIGINT = NULL
AS
BEGIN
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	BEGIN TRY

	DECLARE @WOModuleId INT,@SOModuleId INT,@EXModuleId INT
	
	SELECT @WOModuleId = [ModuleId] FROM [dbo].[Module] WITH(NOLOCK) WHERE [ModuleName] = 'WorkOrder';
	SELECT @SOModuleId = [ModuleId] FROM [dbo].[Module] WITH(NOLOCK) WHERE [ModuleName] = 'SalesOrder';
	SELECT @EXModuleId = [ModuleId] FROM [dbo].[Module] WITH(NOLOCK) WHERE [ModuleName] = 'ExchangeSalesOrder';
	
	DECLARE @CurrntEmpTimeZoneDesc VARCHAR(100) = '';
		
	SELECT @CurrntEmpTimeZoneDesc = COALESCE(ETZ.[Description], LTZ.[Description]) 
	  FROM [dbo].[Employee] E WITH (NOLOCK) 
	       LEFT JOIN [dbo].[TimeZone] ETZ WITH (NOLOCK) ON E.TimeZoneId = ETZ.TimeZoneId
		   LEFT JOIN [dbo].[LegalEntity] LE WITH (NOLOCK) ON E.LegalEntityId = LE.LegalEntityId
		   LEFT JOIN [dbo].[TimeZone] LTZ WITH (NOLOCK) ON LE.TimeZoneId = LTZ.TimeZoneId
		WHERE E.EmployeeId = @EmployeeId; 
	   		
		IF(@ModuleId = @WOModuleId) /*********START: WORK ORDER ********/
		BEGIN	
			SELECT TOP 1 WOP.CustomerReference, T.ReferenceId
			INTO #TempCustomerRef
			FROM [dbo].[BillingInvoicing] T WITH(NOLOCK)
			INNER JOIN [dbo].[BillingInvoicingItems] BII WITH(NOLOCK) ON T.BillingInvoicingId = BII.BillingInvoicingId
			INNER JOIN [dbo].[WorkOrderPartNumber] WOP WITH(NOLOCK) ON BII.SubReferenceId = WOP.ID
			WHERE T.[BillingInvoicingId] = @BillingInvoicingId;

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
					SHIPTOFULLADDRESS = (SELECT dbo.FN_ValidatePDFAddress(SHIPTOADDRESS.[Line1],SHIPTOADDRESS.[Line2],NULL,SHIPTOADDRESS.[City],SHIPTOADDRESS.[StateOrProvince],SHIPTOADDRESS.[PostalCode],SHIPTOCOUNTRY.[countries_name],NULL,NULL,NULL)),
					-- SHIP TO ADDRESS END
					-- BILL TO ADDRESS START 
					BILLTOSITE.[SiteName] [BillToSiteName],
					BILLTOADDRESS.[Line1] [BillToAddressLine1],
					BILLTOADDRESS.[Line2] [BillToAddressLine2],
					BILLTOADDRESS.[City] [BillToCity],
					BILLTOADDRESS.[StateOrProvince] [BillToState],
					BILLTOADDRESS.[PostalCode] [BillToPostalCode],
					ISNULL(BILLTOCOUNTRY.[countries_name], '') [BillToCountry],						
  				    BILLTOFULLADDRESS = (SELECT dbo.FN_ValidatePDFAddress(BILLTOADDRESS.[Line1],BILLTOADDRESS.[Line2],NULL,BILLTOADDRESS.[City],BILLTOADDRESS.[StateOrProvince],BILLTOADDRESS.[PostalCode],BILLTOCOUNTRY.[countries_name],CUST.[CustomerPhone],NULL,CUST.[Email])),					
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
					CASE WHEN BI.[InvoiceDate] IS NOT NULL THEN (CAST(dbo.ConvertUTCtoLocal(BI.[InvoiceDate], @CurrntEmpTimeZoneDesc) AS DATETIME)) ELSE NULL END [NewDateAndTime],
					SHIPPINGINFO.[ShipDate] [NewShipDate],					
					CASE WHEN BI.[InvoiceDate] IS NOT NULL THEN (CAST(dbo.ConvertUTCtoLocal(DATEADD(DAY, ISNULL(WO.[NetDays],0), BI.[InvoiceDate]), @CurrntEmpTimeZoneDesc) AS DATETIME)) ELSE NULL END [NewDueDate],
					CAST(dbo.ConvertUTCtoLocal(GETUTCDATE(), @CurrntEmpTimeZoneDesc) AS DATETIME) [PrintDate],					
					ISNULL(BI.[IsPerformaInvoice], 0) [IsProformaInvoice],
					0 [WorkFlowWorkOrderId],  
					WO.[MasterCompanyId],
					ISNULL(BI.[SalesTax], 0) [Tax],
					ISNULL(BI.[OtherTax], 0) [OtherTax],
					BI.InvoiceTypeId,
					BI.[Notes] [Notes],
					WO.[WorkOrderNum] AS [ReferenceNo],
					ISNULL(BI.[SubTotal],0) [SubTotal],
					ISNULL(BI.[DepositAmount],0) [DepositAmount],
					ISNULL(BI.[GrandTotal],0) [GrandTotal],
					ISNULL(BI.[RemainingAmount],0) [RemainingAmount]	 				
				FROM [dbo].[BillingInvoicing] BI WITH(NOLOCK)		
				INNER JOIN [dbo].[BillingInvoicingDetails] BID WITH(NOLOCK) ON BI.[BillingInvoicingId] = BID.[BillingInvoicingId]
				INNER JOIN [dbo].[WorkOrder] WO WITH(NOLOCK) ON BI.[ReferenceId] = WO.[WorkOrderId]
				INNER JOIN [dbo].[Customer] CUST WITH(NOLOCK) ON WO.[CustomerId] = CUST.[CustomerId]
				INNER JOIN [dbo].[Address] CUSTADDRESS WITH(NOLOCK) ON CUST.[AddressId] = CUSTADDRESS.[AddressId]
				 LEFT JOIN [dbo].[CustomerContact] CUSTCONT WITH(NOLOCK) ON WO.[CustomerContactId] = CUSTCONT.[CustomerContactId]
				 LEFT JOIN [dbo].[Contact] CONTACT WITH(NOLOCK) ON CUSTCONT.[ContactId] = CONTACT.[ContactId]
				 LEFT JOIN [dbo].[Customer] BILLTOCUSTOMER WITH(NOLOCK) ON BID.[SoldToCustomerId] = BILLTOCUSTOMER.[CustomerId]		
				INNER JOIN [dbo].[CustomerBillingAddress] BILLTOSITE WITH(NOLOCK) ON BID.[SoldToSiteId] = BILLTOSITE.[CustomerBillingAddressId]
				INNER JOIN [dbo].[Address] BILLTOADDRESS WITH(NOLOCK) ON BILLTOSITE.[AddressId] = BILLTOADDRESS.[AddressId]
				 LEFT JOIN [dbo].[Countries] BILLTOCOUNTRY WITH(NOLOCK) ON BILLTOADDRESS.[CountryId] = BILLTOCOUNTRY.[countries_id]
				INNER JOIN [dbo].[CustomerDomensticShipping] SHIPTOSITE WITH(NOLOCK) ON BID.[ShipToSiteId] = SHIPTOSITE.[CustomerDomensticShippingId]
				INNER JOIN [dbo].[Address] SHIPTOADDRESS WITH(NOLOCK) ON SHIPTOSITE.[AddressId] = SHIPTOADDRESS.[AddressId]
				 LEFT JOIN [dbo].[Employee] SP WITH(NOLOCK) ON WO.[SalesPersonId] = SP.[EmployeeId]
				 LEFT JOIN [dbo].[Countries] CONT WITH(NOLOCK) ON CUSTADDRESS.[CountryId] = CONT.[countries_id]
				 LEFT JOIN [dbo].[Currency] CUR WITH(NOLOCK) ON BI.[CurrencyId] = CUR.[CurrencyId]
				 LEFT JOIN [dbo].[WorkOrderShipping] SHIPPINGINFO WITH(NOLOCK) ON BI.[WorkOrderShippingId] = SHIPPINGINFO.[WorkOrderShippingId]
				 LEFT JOIN [dbo].[ShippingVia] SHIPINFOVIA WITH(NOLOCK) ON BID.[CustomerDomensticShippingShipViaId] = SHIPINFOVIA.[ShippingViaId]
				 LEFT JOIN [dbo].[Countries] SHIPTOCOUNTRY WITH(NOLOCK) ON SHIPPINGINFO.[ShipToCountryId] = SHIPTOCOUNTRY.[countries_id]				
				 LEFT JOIN #TempCustomerRef CUSTREF ON BI.ReferenceId = CUSTREF.ReferenceId
				WHERE BI.[BillingInvoicingId] = @BillingInvoicingId AND BI.[IsActive] = 1 AND BI.[IsDeleted] = 0 
		END  /*********END: WORK ORDER ********/		
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