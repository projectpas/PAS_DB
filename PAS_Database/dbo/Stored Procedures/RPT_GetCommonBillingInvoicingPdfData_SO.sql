/*************************************************************           
 ** File:   [RPT_GetCommonBillingInvoicingPdfData_SO]           
 ** Author:  RAJESH GAMI 
 ** Description: This stored procedure is used to GET Common Billing Invoicing Pdf Data (SO)
 ** Purpose:         
 ** Date:   05/JUN/2025
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    05/JUN/2025   RAJESH GAMI		CREATED
	2    18/JUN/2025   RAJESH GAMI		Proforma Amount Related Fixed  
	3    03 JUL 2025   RAJESH GAMI		Change CustomerDomensticShippingShipViaId to ShipViaId 	
	4    07 JUL 2025   Devendra Shekh	Deposite Amount Calculation Issue Resolved
	5    17 JUL 2025   Moin Bloch       Notes Replace <p> Tag
	6    05 Aug 2025   Bhargav Saliya   Get Shipping Terms Name from BillingInvoiceDatails
--  EXEC [dbo].[RPT_GetCommonBillingInvoicingPdfData_SO] 4352,10,245
**************************************************************/
CREATE       PROCEDURE [dbo].[RPT_GetCommonBillingInvoicingPdfData_SO]
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
	DECLARE @ReferenceId BIGINT = NULL, @ProformaDepositAmount DECIMAL(18, 2) = 0;
	
	DECLARE @CurrntEmpTimeZoneDesc VARCHAR(100) = '';
		
	SELECT @CurrntEmpTimeZoneDesc = COALESCE(ETZ.[Description], LTZ.[Description]) 
	  FROM [dbo].[Employee] E WITH (NOLOCK) 
	       LEFT JOIN [dbo].[TimeZone] ETZ WITH (NOLOCK) ON E.TimeZoneId = ETZ.TimeZoneId
		   LEFT JOIN [dbo].[LegalEntity] LE WITH (NOLOCK) ON E.LegalEntityId = LE.LegalEntityId
		   LEFT JOIN [dbo].[TimeZone] LTZ WITH (NOLOCK) ON LE.TimeZoneId = LTZ.TimeZoneId
		WHERE E.EmployeeId = @EmployeeId; 

		SELECT @ReferenceId = ReferenceId FROM [dbo].[BillingInvoicing] WITH(NOLOCK) WHERE [BillingInvoicingId] = @BillingInvoicingId

		SELECT @ProformaDepositAmount = SUM(ISNULL(BI.DepositAmount, 0)) - SUM(ISNULL(BI.UsedDeposit, 0))  
		FROM [dbo].[BillingInvoicing] BI WITH(NOLOCK)			
		WHERE BI.[ReferenceId] = @ReferenceId AND BI.ModuleId  =  @ModuleId AND ISNULL(BI.IsPerformaInvoice, 0) = 1 
	   		
		IF(@ModuleId = @SOModuleId) /********* START: SALES ORDER ********/
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
					UPPER(ISNULL(cur.[Code], '')) [Currency],
					FORMAT(SO.[OpenDate], 'MM/dd/yyyy') [OrderDate],
					FORMAT(SHIPPINGINFO.[ShipDate], 'MM/dd/yyyy') [ShipDate],
					ISNULL(SHIPINFOVIA.[Name], '')  AS [ShipVia],
					BID.[ShipAccountInfo] [ShipAccNumber],
					SHIPPINGINFO.[SOShippingNum] [ShippingOrderNumber],
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
					REPLACE(REPLACE(ISNULL(BI.[Notes],''), '<p>', ''),'</p>','<br />') AS [Notes],
					SO.SalesOrderNumber AS ReferenceNo,
					SignEmpName = ISNULL(emp.FirstName,'') + ' ' + ISNULL(emp.LastName,''),
					SignEmpTitle = ISNULL(jt.Description,''),
					SignEmpDate = bi.CreatedDate,
					ShippingTerms = BID.ShippingTermsName,
					CASE 
							WHEN BI.IsPerformaInvoice = 1 THEN 
								(SELECT SUM(ISNULL(BII.PartCost, 0)) FROM dbo.BillingInvoicingItems BII WITH (NOLOCK) WHERE BII.BillingInvoicingId = BI.BillingInvoicingId)
								+
								(SELECT SUM(ISNULL(FreightCostPlus, 0))
									FROM (
										SELECT 
											ItemMasterId,
											MAX(ISNULL(FreightCostPlus, 0)) AS FreightCostPlus
										FROM dbo.BillingInvoicingItems WITH (NOLOCK)
										WHERE ISNULL(IsActive, 0) = 1
										  AND ISNULL(IsDeleted, 0) = 0
										  AND ISNULL(IsVersionIncrease, 0) = 0
										  AND BillingInvoicingId = BI.BillingInvoicingId
										  AND ModuleId = @SOModuleId
										  AND ReferenceId = BI.ReferenceId
										GROUP BY ItemMasterId
									) AS DistinctFreight 
								)
								+
								(SELECT SUM(ISNULL(Charges, 0))
									FROM (
										SELECT 
											ItemMasterId,
											MAX(ISNULL(MiscChargesCostPlus, 0)) AS Charges
										FROM dbo.BillingInvoicingItems WITH (NOLOCK)
										WHERE ISNULL(IsActive, 0) = 1
										  AND ISNULL(IsDeleted, 0) = 0
										  AND ISNULL(IsVersionIncrease, 0) = 0
										  AND BillingInvoicingId = BI.BillingInvoicingId
										  AND ModuleId = @SOModuleId
										  AND ReferenceId = BI.ReferenceId
										GROUP BY ItemMasterId
									) AS DistinctCharges 
								)
							ELSE ISNULL(BI.[SubTotal], 0)
						END AS [SubTotal],
					--ISNULL(BI.[DepositAmount],0) [DepositAmount],
					CASE WHEN ISNULL(BI.[DepositAmount],0) >= @ProformaDepositAmount AND ISNULL(IsPerformaInvoice, 0) = 0 THEN @ProformaDepositAmount ELSE ISNULL(BI.[DepositAmount],0) END [DepositAmount],
					CASE WHEN BI.IsPerformaInvoice = 1 THEN 
													(SELECT SUM(ISNULL(BII.PartCost,0)) FROM dbo.BillingInvoicingItems BII WITH(NOLOCK) WHERE BII.BillingInvoicingId = BI.BillingInvoicingId) + ISNULL(BI.[SalesTax], 0)  + ISNULL(BI.[OtherTax], 0) 
													+
								(SELECT SUM(ISNULL(FreightCostPlus, 0))
									FROM (SELECT ItemMasterId,MAX(ISNULL(FreightCostPlus, 0)) AS FreightCostPlus FROM dbo.BillingInvoicingItems WITH (NOLOCK)
										WHERE ISNULL(IsActive, 0) = 1 AND ISNULL(IsDeleted, 0) = 0  AND ISNULL(IsVersionIncrease, 0) = 0  AND BillingInvoicingId = BI.BillingInvoicingId
										  AND ModuleId = @SOModuleId AND ReferenceId = BI.ReferenceId GROUP BY ItemMasterId
									) AS DistinctFreight 
								)
								+
								(SELECT SUM(ISNULL(Charges, 0))
									FROM (
										SELECT ItemMasterId,MAX(ISNULL(MiscChargesCostPlus, 0)) AS Charges
										FROM dbo.BillingInvoicingItems WITH (NOLOCK)
										WHERE ISNULL(IsActive, 0) = 1
										  AND ISNULL(IsDeleted, 0) = 0
										  AND ISNULL(IsVersionIncrease, 0) = 0
										  AND BillingInvoicingId = BI.BillingInvoicingId
										  AND ModuleId = @SOModuleId
										  AND ReferenceId = BI.ReferenceId
										GROUP BY ItemMasterId
									) AS DistinctCharges 
								)
								ELSE  ISNULL(BI.[GrandTotal],0) END [GrandTotal],
					--ISNULL(BI.[RemainingAmount],0) [RemainingAmount],
					CASE WHEN ISNULL(BI.[DepositAmount],0) >= @ProformaDepositAmount AND ISNULL(IsPerformaInvoice, 0) = 0 THEN ISNULL(BI.[GrandTotal],0) - @ProformaDepositAmount ELSE ISNULL(BI.[GrandTotal],0) - ISNULL(BI.[DepositAmount],0) END [RemainingAmount],
					SHIPTOFULLADDRESS = (SELECT dbo.FN_ValidatePDFAddress(SHIPTOADDRESS.[Line1],SHIPTOADDRESS.[Line2],NULL,SHIPTOADDRESS.[City],SHIPTOADDRESS.[StateOrProvince],SHIPTOADDRESS.[PostalCode],SHIPTOCOUNTRY.[countries_name],NULL,NULL,NULL)),
  				    BILLTOFULLADDRESS = (SELECT dbo.FN_ValidatePDFAddress(BILLTOADDRESS.[Line1],BILLTOADDRESS.[Line2],NULL,BILLTOADDRESS.[City],BILLTOADDRESS.[StateOrProvince],BILLTOADDRESS.[PostalCode],BILLTOCOUNTRY.[countries_name],CUST.[CustomerPhone],NULL,CUST.[Email])),
					 GETDATE() [PrintDate],
					UPPER(inv.[Description]) InvoiceType,
					oriCountry.countries_name OriginCountry,
					destCountry.countries_name DestinationCountry
				FROM [dbo].[BillingInvoicing] BI WITH(NOLOCK)		
				INNER JOIN [dbo].[BillingInvoicingDetails] BID WITH(NOLOCK) ON BI.[BillingInvoicingId] = BID.[BillingInvoicingId]
				INNER JOIN [dbo].[SalesOrder] SO WITH(NOLOCK) ON BI.[ReferenceId] = SO.[SalesOrderId]
				INNER JOIN [dbo].[Customer] CUST WITH(NOLOCK) ON SO.[CustomerId] = CUST.[CustomerId]
				INNER JOIN [dbo].[Address] CUSTADDRESS WITH(NOLOCK) ON CUST.[AddressId] = CUSTADDRESS.[AddressId]
				INNER JOIN [dbo].InvoiceType inv WITH(NOLOCK) ON inv.InvoiceTypeId = BI.InvoiceTypeId
				 LEFT JOIN [dbo].[CustomerContact] CUSTCONT WITH(NOLOCK) ON SO.[CustomerContactId] = CUSTCONT.[CustomerContactId]
				 LEFT JOIN [dbo].[Contact] CONTACT WITH(NOLOCK) ON CUSTCONT.[ContactId] = CONTACT.[ContactId]
				INNER JOIN [dbo].[Customer] BILLTOCUSTOMER WITH(NOLOCK) ON BID.[SoldToCustomerId] = BILLTOCUSTOMER.[CustomerId]		
				INNER JOIN [dbo].[CustomerBillingAddress] BILLTOSITE WITH(NOLOCK) ON BID.[SoldToSiteId] = BILLTOSITE.[CustomerBillingAddressId]
				INNER JOIN [dbo].[Address] BILLTOADDRESS WITH(NOLOCK) ON BILLTOSITE.[AddressId] = BILLTOADDRESS.[AddressId]
				 LEFT JOIN [dbo].[Countries] BILLTOCOUNTRY WITH(NOLOCK) ON BILLTOADDRESS.[CountryId] = BILLTOCOUNTRY.[countries_id]
				INNER JOIN [dbo].[CustomerDomensticShipping] SHIPTOSITE WITH(NOLOCK) ON BID.[ShipToSiteId] = SHIPTOSITE.[CustomerDomensticShippingId]
				INNER JOIN [dbo].[Address] SHIPTOADDRESS WITH(NOLOCK) ON SHIPTOSITE.[AddressId] = SHIPTOADDRESS.[AddressId]
				LEFT JOIN [dbo].[Countries] SHIPTOCOUNTRY WITH(NOLOCK) ON SHIPTOADDRESS.[CountryId] = SHIPTOCOUNTRY.[countries_id]
				 LEFT JOIN [dbo].[Employee] SP WITH(NOLOCK) ON SO.[SalesPersonId] = SP.[EmployeeId]
				 LEFT JOIN [dbo].[Countries] CONT WITH(NOLOCK) ON CUSTADDRESS.[CountryId] = CONT.[countries_id]
				 LEFT JOIN [dbo].[Currency] CUR WITH(NOLOCK) ON SO.[FunctionalCurrencyId] = CUR.[CurrencyId]
				 OUTER APPLY (SELECT TOP 1 * FROM [dbo].[SalesOrderShipping] s WITH(NOLOCK)	WHERE s.SalesOrderId = SO.SalesOrderId ORDER BY ISNULL(s.UpdatedDate, s.ShipDate) DESC ) SHIPPINGINFO
				 --LEFT JOIN [dbo].[SalesOrderShipping] SHIPPINGINFO WITH(NOLOCK) ON SO.[SalesOrderId] = SHIPPINGINFO.[SalesOrderId]
				 LEFT JOIN [dbo].[ShippingVia] SHIPINFOVIA WITH(NOLOCK) ON BID.[ShipViaId] = SHIPINFOVIA.[ShippingViaId]
				 --LEFT JOIN [dbo].[Countries] SHIPTOCOUNTRY WITH(NOLOCK) ON SHIPPINGINFO.[ShipToCountryId] = SHIPTOCOUNTRY.[countries_id]
				LEFT JOIN  [dbo].[Employee] emp WITH(NOLOCK) ON bi.EmployeeId = emp.EmployeeId
				LEFT JOIN	[dbo].[JobTitle] jt WITH(NOLOCK) ON emp.JobTitleId = jt.JobTitleId
				LEFT JOIN  [dbo].AllShipVia posv WITH(NOLOCK) ON so.SalesOrderId = posv.ReferenceId AND posv.ModuleId = @ModuleId
				LEFT JOIN [dbo].[Countries] oriCountry WITH(NOLOCK) ON Bi.OriginCountryId = oriCountry.[countries_id]
				LEFT JOIN [dbo].[Countries] destCountry WITH(NOLOCK) ON Bi.ShipToCountryId = destCountry.[countries_id]
				WHERE BI.[BillingInvoicingId] = @BillingInvoicingId AND BI.[IsActive] = 1 AND BI.[IsDeleted] = 0 AND ISNULL(BI.[IsVersionIncrease],0) = 0

		END  /*********END: SALES ORDER ********/		
	END TRY    
	BEGIN CATCH      
		IF @@trancount > 0
              DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'RPT_GetCommonBillingInvoicingPdfData_SO' 
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