/*************************************************************           
 ** File:   [GetBillingInvoicingDetails]           
 ** Author:   Moin Bloch
 ** Description: Get Billing Invoicing Details
 ** Purpose:         
 ** Date:   28/04/2025
          
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    28/04/2025   Moin Bloch    Created
	2    30 Apr 2025   RAJESH GAMI  Implemented Sales Order Module and Fix invoice Date issue
	3    23 JUN 2025   RAJESH GAMI  FIXED CustomerDomensticShippingShipViaId related issue in SO
	4    03 JUL 2025   RAJESH GAMI  Change CustomerDomensticShippingShipViaId to ShipViaId 
	5    07 JUL 2025   RAJESH GAMI  added @DefaultInvoiceTypeId for if any STANDARD or COMMERCIAL invoice are there then it should be by default selected
	6    08 JUL 2025   RAJESH GAMI  Fixed: When we revise the proforma that time getting error 
   EXEC [dbo].[GetBillingInvoicingDetails] 8781,8523,2,15,0,0
   EXEC [dbo].[GetBillingInvoicingDetails] 802,972,2,10,292,0
**************************************************************/ 
CREATE      PROCEDURE [dbo].[GetBillingInvoicingDetails]
@ReferenceId BIGINT=NULL,
@SubReferenceId BIGINT=NULL,
@EmployeeId BIGINT=NULL,
@ModuleId INT=NULL,
@ShippingId BIGINT = NULL,
@BillingInvoicingId BIGINT =NULL,
@IsProformaInvoice BIT = NULL
AS
BEGIN	
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED	
	 BEGIN TRY  	
		
		DECLARE @WOModuleId INT,@SOModuleId INT,@EXModuleId INT,@Result INT,@ItemCount INT, @CostPlusType VARCHAR(20) ='Cost Plus', @DefaultInvoiceTypeId INT =0;;		
		DECLARE @AllowInvoiceBeforeShipping BIT
		SELECT @WOModuleId = [ModuleId] FROM [dbo].[Module] WITH(NOLOCK) WHERE [ModuleName] = 'WorkOrder';
		SELECT @SOModuleId = [ModuleId] FROM [dbo].[Module] WITH(NOLOCK) WHERE [ModuleName] = 'SalesOrder';
		SELECT @EXModuleId = [ModuleId] FROM [dbo].[Module] WITH(NOLOCK) WHERE [ModuleName] = 'ExchangeSalesOrder';
		
		IF(@ModuleId = @WOModuleId) /*********START: WORK ORDER ********/
		BEGIN	
			
			
		  
			SELECT @ItemCount = COUNT(DISTINCT [wosi].[WorkOrderPartNumId])
				FROM [dbo].[WorkOrderShipping] [wos] WITH(NOLOCK)
				LEFT JOIN [dbo].[WorkOrderShippingItem] [wosi] WITH(NOLOCK) ON [wos].[WorkOrderShippingId] = [wosi].[WorkOrderShippingId]
			WHERE [wos].[WorkOrderId] = @ReferenceId AND [wosi].[WorkOrderPartNumId] = @SubReferenceId;
			
			SELECT @AllowInvoiceBeforeShipping = ISNULL([AllowInvoiceBeforeShipping],0) FROM [dbo].[WorkOrderPartNumber] WITH(NOLOCK) WHERE [WorkOrderId] = @ReferenceId AND [ID] = @SubReferenceId;
			
			IF EXISTS (SELECT 1 FROM [dbo].[WorkOrder] wo WITH(NOLOCK)
			               INNER JOIN [dbo].[CustomerDomensticShipping] cust_ship WITH(NOLOCK) ON wo.[CustomerId] = cust_ship.[CustomerId]
                           INNER JOIN [dbo].[CustomerBillingAddress] cust_bill    WITH(NOLOCK) ON wo.[CustomerId] = cust_bill.[CustomerId]
                      WHERE wo.[WorkOrderId] = @ReferenceId)
			BEGIN
				SELECT @Result = 1;
			END
			ELSE
			BEGIN
				SELECT @Result = 0;
			END
			
			IF(@ItemCount > 0)
			BEGIN
				SELECT TOP 1
				[wosh].[WorkOrderId],
				[wosh].[WorkOrderPartNoId],
				[cust].[ContractReference],
				CASE WHEN [cust].[CustomerAffiliationId] = 1 THEN 1 ELSE 0 END AS [CustomerType],
				GETUTCDATE() AS [InvoiceDate],
				GETUTCDATE() AS [PrintDate],
				[wosh].[ShipDate],
				[wo].[EmployeeId],
				ISNULL([emp].[FirstName] + ' ' + [emp].[LastName], '') AS [EmployeeName],
				ISNULL([wos].[Code] + '-' + [wos].[Stage], '') AS [gateStatus],
				[wo].[WorkOrderTypeId],
				CASE 
					WHEN [wo].[WorkOrderTypeId] = 1 THEN 'Customer'
					WHEN [wo].[WorkOrderTypeId] = 2 THEN 'Internal'
					WHEN [wo].[WorkOrderTypeId] = 3 THEN 'Tear Down'
					ELSE 'Shop Services'
				END AS [WorkOrderType],
				[wop].[WorkScope],
				[wop].[WorkOrderScopeId],
				[wop].[Quantity],
				[wopsettlement].[ConditionId],
				[wo].[OpenDate],
				[wo].[SalesPersonId],
				ISNULL([sp].[FirstName] + ' ' + [sp].[LastName], '') AS [SalesPerson],
				[wosh].[ShippingAccountInfo] AS [ShipAccountInfo],
				--CASE 
				--	WHEN [wosh].[IsCustomerShipping] = 1 THEN [wosh].[CustomerDomensticShippingShipViaId]
				--	ELSE [wosh].[ShipviaId]
				--END AS [CustomerDomensticShippingShipViaId],
				[wosh].[ShipviaId] ShipViaId,
				ISNULL([cf].[CreditLimit], 0) AS [CreditLimit],
				ISNULL([cf].[CreditTermsId], 0) AS [CreditTermsId],
				[wo].[CreditTerms] AS [CreditTerm],
				ISNULL([wo].[FunctionalCurrencyId], 0) AS [CurrencyId],
				ISNULL([fcu].[Code], '') AS [Currency],
				[wo].[CustomerId] AS [SoldToCustomerId],
				[wosh].[SoldToName] AS [SoldToCustomer],
				[wosh].[SoldToSiteId],
				[wosh].[ShipToCustomerId],
				[wosh].[ShipToName] AS [ShipToCustomer],
				[wosh].[ShipToSiteId],
				[wop].[ManagementStructureId],
				@CostPlusType AS [CostPlusType],
				1 AS [TotalWorkOrder],
				[wosh].[ShipViaId],
				[wosh].[TrackingNum] AS [Tracking],
				ISNULL([csr].[FirstName] + ' ' + [csr].[LastName], '') AS [CSR],
				[wop].[CustomerReference],
				[cust].[Name] AS [CustomerName],
				[wo].[CustomerId],
				[cust].[Email],
				[cust].[CustomerPhone],
				[wosh].[AirwayBill] AS [wayBillRef],
				@ItemCount AS [NoofPieces],
				[wosh].[IsCustomerShipping],
				@Result [BillShipInfoExist],
				0 as InvoiceTypeId
			FROM [dbo].[WorkOrderShipping] [wosh] WITH(NOLOCK)
			INNER JOIN [dbo].[WorkOrder] [wo] WITH(NOLOCK) ON [wosh].[WorkOrderId] = [wo].[WorkOrderId]
			INNER JOIN [dbo].[WorkOrderPartNumber] [wop] WITH(NOLOCK) ON [wosh].[WorkOrderId] = [wop].[WorkOrderId]
			 LEFT JOIN [dbo].[WorkOrderShippingItem] [wosi] WITH(NOLOCK) ON [wop].[ID] = [wosi].[WorkOrderPartNumId]
			INNER JOIN [dbo].[Customer] [cust] WITH(NOLOCK) ON [wosh].[CustomerId] = [cust].[CustomerId]
			INNER JOIN [dbo].[WorkOrderStage] [wos] WITH(NOLOCK) ON [wop].[WorkOrderStageId] = [wos].[WorkOrderStageId]
			 LEFT JOIN [dbo].[CustomerFinancial] [cf] WITH(NOLOCK) ON [cust].[CustomerId] = [cf].[CustomerId]
			 LEFT JOIN [dbo].[Currency] [cr] WITH(NOLOCK) ON [cf].[CurrencyId] = [cr].[CurrencyId]
			 LEFT JOIN [dbo].[WorkOrderSettlementDetails] [wopsettlement] WITH(NOLOCK) ON [wop].[WorkOrderId] = [wopsettlement].[WorkOrderId] AND [wop].[ID] = [wopsettlement].[workOrderPartNoId] AND [wopsettlement].[WorkOrderSettlementId] = 9
			 LEFT JOIN [dbo].[Employee] [emp] WITH(NOLOCK) ON [wo].[EmployeeId] = [emp].[EmployeeId]
			 LEFT JOIN [dbo].[Employee] [sp] WITH(NOLOCK) ON [wo].[SalesPersonId] = [sp].[EmployeeId]
			INNER JOIN [dbo].[CreditTerms] [ct] WITH(NOLOCK) ON [cf].[CreditTermsId] = [ct].[CreditTermsId]
			 LEFT JOIN [dbo].[Employee] [csr] WITH(NOLOCK) ON [wo].[CSRId] = [csr].[EmployeeId]
			 LEFT JOIN [dbo].[StockLine] [sl] WITH(NOLOCK) ON [wop].[StockLineId] = [sl].[StockLineId]
			 LEFT JOIN [dbo].[Currency] [fcu] WITH(NOLOCK) ON [wo].[FunctionalCurrencyId] = [fcu].[CurrencyId] AND [fcu].[IsActive] = 1 AND [fcu].[IsDeleted] = 0
			WHERE [wosh].[WorkOrderId] = @ReferenceId AND [wosi].[WorkOrderPartNumId] = @SubReferenceId;
			END
			ELSE
			BEGIN
				IF(@AllowInvoiceBeforeShipping = 1)
				BEGIN
					SELECT TOP 1
					[wo].[WorkOrderId],
					[wop].[ID] AS [WorkOrderPartNoId],
					[cust].[ContractReference],
					[cust].[CustomerCode],
					CASE WHEN [cust].[CustomerAffiliationId] = 1 THEN 1 ELSE 0 END AS [CustomerType],
					GETUTCDATE() AS [InvoiceDate],
					GETUTCDATE() AS [PrintDate],
					NULL AS [ShipDate],
					[wo].[EmployeeId],
					ISNULL([emp].[FirstName] + ' ' + [emp].[LastName], '') AS [EmployeeName],
					ISNULL([wos].[Code] + '-' + [wos].[Stage], '') AS [gateStatus],
					[wo].[WorkOrderTypeId],
					CASE 
						WHEN [wo].[WorkOrderTypeId] = 1 THEN 'Customer'
						WHEN [wo].[WorkOrderTypeId] = 2 THEN 'Internal'
						WHEN [wo].[WorkOrderTypeId] = 3 THEN 'Tear Down'
						ELSE 'Shop Services'
					END AS [WorkOrderType],
					[wop].[WorkScope],
					[wop].[WorkOrderScopeId],
					[wop].[Quantity],
					[wopsettlement].[ConditionId],
					[wo].[OpenDate],
					[wo].[SalesPersonId],
					ISNULL([sp].[FirstName] + ' ' + [sp].[LastName], '') AS [SalesPerson],
					ISNULL([cust_shipVia].[ShippingAccountinfo], '') AS [ShipAccountInfo],
					ISNULL([cust_shipVia].[ShipViaId], 0) AS ShipViaId,
					ISNULL([cf].[CreditLimit], 0) AS [CreditLimit],
					ISNULL([cf].[CreditTermsId], 0) AS [CreditTermsId],
					[ct].[Name] AS [CreditTerm],
					ISNULL([wo].[FunctionalCurrencyId], 0) AS [CurrencyId],
					ISNULL([fcu].[Code], '') AS [Currency],
					[wo].[CustomerId] AS [SoldToCustomerId],
					[cust].[Name] AS [SoldToCustomer],
					[cust_bill].[CustomerBillingAddressId] AS [SoldToSiteId],
					[wo].[CustomerId] AS [ShipToCustomerId],
					[cust].[Name] AS [ShipToCustomer],
					[cust_ship].[CustomerDomensticShippingId] AS [ShipToSiteId],
					[wop].[ManagementStructureId],
					@CostPlusType AS [CostPlusType],
					1 AS [TotalWorkOrder],
					[cust_shipVia].[ShipViaId],
					'' AS [Tracking],
					ISNULL([csr].[FirstName] + ' ' + [csr].[LastName], '') AS [CSR],
					[wop].[CustomerReference],
					[cust].[Name] AS [CustomerName],
					[wo].[CustomerId],
					[cust].[Email],
					[cust].[CustomerPhone],
					'' AS [wayBillRef],
					@ItemCount AS [NoofPieces],
					0 AS [IsCustomerShipping],
					@Result [BillShipInfoExist],
						0 as InvoiceTypeId
				FROM [dbo].[WorkOrder] [wo] WITH(NOLOCK)
				INNER JOIN [dbo].[WorkOrderPartNumber] [wop] WITH(NOLOCK) ON [wo].[WorkOrderId] = [wop].[WorkOrderId]
				 LEFT JOIN [dbo].[WOPickTicket] [wopick] WITH(NOLOCK) ON [wop].[ID] = [wopick].[OrderPartId]
				INNER JOIN [dbo].[Customer] [cust] WITH(NOLOCK) ON [wo].[CustomerId] = [cust].[CustomerId]
				INNER JOIN [dbo].[WorkOrderStage] [wos] WITH(NOLOCK) ON [wop].[WorkOrderStageId] = [wos].[WorkOrderStageId]
				 LEFT JOIN [dbo].[CustomerFinancial] [cf] WITH(NOLOCK) ON [cust].[CustomerId] = [cf].[CustomerId]
				 LEFT JOIN [dbo].[Currency] [cr] WITH(NOLOCK) ON [cf].[CurrencyId] = [cr].[CurrencyId]
				 LEFT JOIN [dbo].[CustomerDomensticShipping] [cust_ship] WITH(NOLOCK) ON [wo].[CustomerId] = [cust_ship].[CustomerId]
				 LEFT JOIN [dbo].[CustomerBillingAddress] [cust_bill] WITH(NOLOCK) ON [wo].[CustomerId] = [cust_bill].[CustomerId]
				 LEFT JOIN [dbo].[WorkOrderSettlementDetails] [wopsettlement] WITH(NOLOCK) ON [wop].[WorkOrderId] = [wopsettlement].[WorkOrderId] AND [wop].[ID] = [wopsettlement].[workOrderPartNoId] AND [wopsettlement].[WorkOrderSettlementId] = 9
				INNER JOIN [dbo].[Address] [ship_addr] WITH(NOLOCK) ON [cust_ship].[AddressId] = [ship_addr].[AddressId]
				 LEFT JOIN [dbo].[CustomerDomensticShippingShipVia] [cust_shipVia] WITH(NOLOCK) ON [wo].[CustomerId] = [cust_shipVia].[CustomerId] AND [cust_shipVia].[IsPrimary] = 1
				 LEFT JOIN [dbo].[Employee] [emp] WITH(NOLOCK) ON [wo].[EmployeeId] = [emp].[EmployeeId]
				 LEFT JOIN [dbo].[Employee] [sp] WITH(NOLOCK) ON [wo].[SalesPersonId] = [sp].[EmployeeId]
				INNER JOIN [dbo].[CreditTerms] [ct]  WITH(NOLOCK) ON [cf].[CreditTermsId] = [ct].[CreditTermsId]
				 LEFT JOIN [dbo].[Employee] [csr] WITH(NOLOCK) ON [wo].[CSRId] = [csr].[EmployeeId]
				 LEFT JOIN [dbo].[StockLine] [sl] WITH(NOLOCK) ON [wop].[StockLineId] = [sl].[StockLineId]
				 LEFT JOIN [dbo].[Currency] [fcu] WITH(NOLOCK) ON [wo].[FunctionalCurrencyId] = [fcu].[CurrencyId] AND [fcu].[IsActive] = 1 AND [fcu].[IsDeleted] = 0
				WHERE [wo].[WorkOrderId] = @ReferenceId AND [wop].[ID] = @SubReferenceId;				
			END
			ELSE IF(@AllowInvoiceBeforeShipping = 0 AND @IsProformaInvoice = 1)
			BEGIN
				SELECT TOP 1
					[wo].[WorkOrderId],
					[wop].[ID] AS [WorkOrderPartNoId],
					[cust].[ContractReference],
					[cust].[CustomerCode],
					CASE WHEN [cust].[CustomerAffiliationId] = 1 THEN 1 ELSE 0 END AS [CustomerType],
					GETUTCDATE() AS [InvoiceDate],
					GETUTCDATE() AS [PrintDate],
					NULL AS [ShipDate],
					[wo].[EmployeeId],
					ISNULL([emp].[FirstName] + ' ' + [emp].[LastName], '') AS [EmployeeName],
					ISNULL([wos].[Code] + '-' + [wos].[Stage], '') AS [gateStatus],
					[wo].[WorkOrderTypeId],
					CASE 
						WHEN [wo].[WorkOrderTypeId] = 1 THEN 'Customer'
						WHEN [wo].[WorkOrderTypeId] = 2 THEN 'Internal'
						WHEN [wo].[WorkOrderTypeId] = 3 THEN 'Tear Down'
						ELSE 'Shop Services'
					END AS [WorkOrderType],
					[wop].[WorkScope],
					[wop].[WorkOrderScopeId],
					[wop].[Quantity],
					[wopsettlement].[ConditionId],
					[wo].[OpenDate],
					[wo].[SalesPersonId],
					ISNULL([sp].[FirstName] + ' ' + [sp].[LastName], '') AS [SalesPerson],
					ISNULL([cust_shipVia].[ShippingAccountinfo], '') AS [ShipAccountInfo],
					ISNULL([cust_shipVia].[ShipViaId], 0) AS ShipViaId,
					ISNULL([cf].[CreditLimit], 0) AS [CreditLimit],
					ISNULL([cf].[CreditTermsId], 0) AS [CreditTermsId],
					[ct].[Name] AS [CreditTerm],
					ISNULL([wo].[FunctionalCurrencyId], 0) AS [CurrencyId],
					ISNULL([fcu].[Code], '') AS [Currency],
					[wo].[CustomerId] AS [SoldToCustomerId],
					[cust].[Name] AS [SoldToCustomer],
					[cust_bill].[CustomerBillingAddressId] AS [SoldToSiteId],
					[wo].[CustomerId] AS [ShipToCustomerId],
					[cust].[Name] AS [ShipToCustomer],
					[cust_ship].[CustomerDomensticShippingId] AS [ShipToSiteId],
					[wop].[ManagementStructureId],
					@CostPlusType AS [CostPlusType],
					1 AS [TotalWorkOrder],
					[cust_shipVia].[ShipViaId],
					'' AS [Tracking],
					ISNULL([csr].[FirstName] + ' ' + [csr].[LastName], '') AS [CSR],
					[wop].[CustomerReference],
					[cust].[Name] AS [CustomerName],
					[wo].[CustomerId],
					[cust].[Email],
					[cust].[CustomerPhone],
					'' AS [wayBillRef],
					@ItemCount AS [NoofPieces],
					0 AS [IsCustomerShipping],
					@Result [BillShipInfoExist],
						0 as InvoiceTypeId
				FROM [dbo].[WorkOrder] [wo] WITH(NOLOCK)
				INNER JOIN [dbo].[WorkOrderPartNumber] [wop] WITH(NOLOCK) ON [wo].[WorkOrderId] = [wop].[WorkOrderId]
				 LEFT JOIN [dbo].[WOPickTicket] [wopick] WITH(NOLOCK) ON [wop].[ID] = [wopick].[OrderPartId]
				INNER JOIN [dbo].[Customer] [cust] WITH(NOLOCK) ON [wo].[CustomerId] = [cust].[CustomerId]
				INNER JOIN [dbo].[WorkOrderStage] [wos] WITH(NOLOCK) ON [wop].[WorkOrderStageId] = [wos].[WorkOrderStageId]
				 LEFT JOIN [dbo].[CustomerFinancial] [cf] WITH(NOLOCK) ON [cust].[CustomerId] = [cf].[CustomerId]
				 LEFT JOIN [dbo].[Currency] [cr] WITH(NOLOCK) ON [cf].[CurrencyId] = [cr].[CurrencyId]
				 LEFT JOIN [dbo].[CustomerDomensticShipping] [cust_ship] WITH(NOLOCK) ON [wo].[CustomerId] = [cust_ship].[CustomerId]
				 LEFT JOIN [dbo].[CustomerBillingAddress] [cust_bill] WITH(NOLOCK) ON [wo].[CustomerId] = [cust_bill].[CustomerId]
				 LEFT JOIN [dbo].[WorkOrderSettlementDetails] [wopsettlement] WITH(NOLOCK) ON [wop].[WorkOrderId] = [wopsettlement].[WorkOrderId] AND [wop].[ID] = [wopsettlement].[workOrderPartNoId] AND [wopsettlement].[WorkOrderSettlementId] = 9
				INNER JOIN [dbo].[Address] [ship_addr] WITH(NOLOCK) ON [cust_ship].[AddressId] = [ship_addr].[AddressId]
				 LEFT JOIN [dbo].[CustomerDomensticShippingShipVia] [cust_shipVia] WITH(NOLOCK) ON [wo].[CustomerId] = [cust_shipVia].[CustomerId] AND [cust_shipVia].[IsPrimary] = 1
				 LEFT JOIN [dbo].[Employee] [emp] WITH(NOLOCK) ON [wo].[EmployeeId] = [emp].[EmployeeId]
				 LEFT JOIN [dbo].[Employee] [sp] WITH(NOLOCK) ON [wo].[SalesPersonId] = [sp].[EmployeeId]
				INNER JOIN [dbo].[CreditTerms] [ct]  WITH(NOLOCK) ON [cf].[CreditTermsId] = [ct].[CreditTermsId]
				 LEFT JOIN [dbo].[Employee] [csr] WITH(NOLOCK) ON [wo].[CSRId] = [csr].[EmployeeId]
				 LEFT JOIN [dbo].[StockLine] [sl] WITH(NOLOCK) ON [wop].[StockLineId] = [sl].[StockLineId]
				 LEFT JOIN [dbo].[Currency] [fcu] WITH(NOLOCK) ON [wo].[FunctionalCurrencyId] = [fcu].[CurrencyId] AND [fcu].[IsActive] = 1 AND [fcu].[IsDeleted] = 0
				WHERE [wo].[WorkOrderId] = @ReferenceId AND [wop].[ID] = @SubReferenceId;				
			END
			ELSE
			BEGIN
				SELECT TOP 1
					[wosh].[WorkOrderId],
					[wosh].[WorkOrderPartNoId],
					[cust].[ContractReference],
					[cust].[CustomerCode],
					CASE WHEN [cust].[CustomerAffiliationId] = 1 THEN 1 ELSE 0 END AS [CustomerType],
					GETUTCDATE() AS [InvoiceDate],
					GETUTCDATE() AS [PrintDate],
					[wosh].[ShipDate],
					[wo].[EmployeeId],
					ISNULL([emp].[FirstName] + ' ' + [emp].[LastName], '') AS [EmployeeName],
					ISNULL([wos].[Code] + '-' + [wos].[Stage], '') AS [gateStatus],
					[wo].[WorkOrderTypeId],
					CASE 
						WHEN [wo].[WorkOrderTypeId] = 1 THEN 'Customer'
						WHEN [wo].[WorkOrderTypeId] = 2 THEN 'Internal'
						WHEN [wo].[WorkOrderTypeId] = 3 THEN 'Tear Down'
						ELSE 'Shop Services'
					END AS [WorkOrderType],
					[wop].[WorkScope],
					[wop].[WorkOrderScopeId],
					[wop].[Quantity],
					[wopsettlement].[ConditionId],
					[wo].[OpenDate],
					[wo].[SalesPersonId],
					ISNULL([sp].[FirstName] + ' ' + [sp].[LastName], '') AS [SalesPerson],
					[wosh].[ShippingAccountInfo] AS [ShipAccountInfo],
					--CASE 
					--	WHEN [wosh].[IsCustomerShipping] = 1 THEN [wosh].[CustomerDomensticShippingShipViaId]
					--	ELSE [wosh].[ShipviaId]
					--END AS [CustomerDomensticShippingShipViaId],
					wosh.ShipviaId ShipViaId,
					ISNULL([cf].[CreditLimit], 0) AS [CreditLimit],
					ISNULL([cf].[CreditTermsId], 0) AS [CreditTermsId],
					[ct].[Name] AS [CreditTerm],
					ISNULL([cf].[CurrencyId], 0) AS [CurrencyId],
					ISNULL([cr].[Code], '') AS [Currency],
					[wo].[CustomerId] AS [SoldToCustomerId],
					[wosh].[SoldToName] AS [SoldToCustomer],
					[wosh].[SoldToSiteId],
					[wosh].[ShipToCustomerId],
					[wosh].[ShipToName] AS [ShipToCustomer],
					[wosh].[ShipToSiteId],
					[wop].[ManagementStructureId],
					@CostPlusType AS [CostPlusType],
					1 AS [TotalWorkOrder],
					[wosh].[ShipViaId],
					[wosh].[TrackingNum] AS [Tracking],
					ISNULL([csr].[FirstName] + ' ' + [csr].[LastName], '') AS [CSR],
					[wop].[CustomerReference],
					[cust].[Name] AS [CustomerName],
					[wo].[CustomerId],
					[cust].[Email],
					[cust].[CustomerPhone],
					[wosh].[AirwayBill] AS [wayBillRef],
					@ItemCount AS [NoofPieces],
					[wosh].[IsCustomerShipping],
					@Result [BillShipInfoExist],
						0 as InvoiceTypeId
				FROM [dbo].[WorkOrderShipping] [wosh] WITH(NOLOCK)
				INNER JOIN [dbo].[WorkOrder] [wo] WITH(NOLOCK) ON [wosh].[WorkOrderId] = [wo].[WorkOrderId]
				INNER JOIN [dbo].[WorkOrderPartNumber] [wop] WITH(NOLOCK) ON [wosh].[WorkOrderId] = [wop].[WorkOrderId]
				LEFT JOIN [dbo].[WorkOrderShippingItem] [wosi] WITH(NOLOCK) ON [wop].[ID] = [wosi].[WorkOrderPartNumId]
				INNER JOIN [dbo].[Customer] [cust] WITH(NOLOCK) ON [wosh].[CustomerId] = [cust].[CustomerId]
				INNER JOIN [dbo].[WorkOrderStage] [wos] WITH(NOLOCK) ON [wop].[WorkOrderStageId] = [wos].[WorkOrderStageId]
				LEFT JOIN [dbo].[CustomerFinancial] [cf] WITH(NOLOCK) ON [cust].[CustomerId] = [cf].[CustomerId]
				LEFT JOIN [dbo].[Currency] [cr] WITH(NOLOCK) ON [cf].[CurrencyId] = [cr].[CurrencyId]
				LEFT JOIN [dbo].[WorkOrderSettlementDetails] [wopsettlement] WITH(NOLOCK) ON [wop].[WorkOrderId] = [wopsettlement].[WorkOrderId] AND [wop].[ID] = [wopsettlement].[workOrderPartNoId] AND [wopsettlement].[WorkOrderSettlementId] = 9
				LEFT JOIN [dbo].[Employee] [emp] WITH(NOLOCK) ON [wo].[EmployeeId] = [emp].[EmployeeId]
				LEFT JOIN [dbo].[Employee] [sp] WITH(NOLOCK) ON [wo].[SalesPersonId] = [sp].[EmployeeId]
				LEFT JOIN [dbo].[CreditTerms] [ct] WITH(NOLOCK) ON [cf].[CreditTermsId] = [ct].[CreditTermsId]
				LEFT JOIN [dbo].[Employee] [csr] WITH(NOLOCK) ON [wo].[CSRId] = [csr].[EmployeeId]
				LEFT JOIN [dbo].[StockLine] [sl] WITH(NOLOCK) ON [wop].[StockLineId] = [sl].[StockLineId]
				WHERE [wosh].[WorkOrderId] = @ReferenceId AND [wosi].[WorkOrderPartNumId] = @SubReferenceId;
			
			END
			END
		END /*********END: WORK ORDER ********/
		ELSE IF(@ModuleId = @SOModuleId) /*********START: SALES ORDER ********/
		BEGIN
			SET @ShippingId = (SELECT TOP 1 SalesOrderShippingId FROM dbo.SalesOrderShipping sos WITH(NOLOCK) WHERE sos.SalesOrderId = @ReferenceId AND IsActive = 1 AND ISNULL(IsDeleted,0) = 0 ORDER BY SalesOrderShippingId DESC)
			SELECT @AllowInvoiceBeforeShipping = ISNULL([AllowInvoiceBeforeShipping],0) FROM [dbo].[SalesOrder] WITH(NOLOCK) WHERE [SalesOrderId] = @ReferenceId;
			IF EXISTS (SELECT 1 FROM [dbo].[SalesOrder] so WITH(NOLOCK)
			               INNER JOIN [dbo].[CustomerDomensticShipping] cust_ship WITH(NOLOCK) ON so.[CustomerId] = cust_ship.[CustomerId]
                           INNER JOIN [dbo].[CustomerBillingAddress] cust_bill    WITH(NOLOCK) ON so.[CustomerId] = cust_bill.[CustomerId]
                      WHERE so.[SalesOrderId] = @ReferenceId)
			BEGIN
				SELECT @Result = 1;
			END
			ELSE
			BEGIN
				SELECT @Result = 0;
			END
			SET @DefaultInvoiceTypeId = ISNULL((SELECT InvoiceTypeId FROM DBO.BillingInvoicing WITH (NOLOCK) WHERE ReferenceId = @ReferenceId AND ModuleId = @SOModuleId AND ISNULL(IsVersionIncrease,0) = 0 AND ISNULL(IsPerformaInvoice,0) = 0),0)
			IF(@BillingInvoicingId > 0)
			BEGIN
				  SELECT TOP 1 sop.SalesOrderId, sop.SalesOrderPartId, 0 AS SalesOrderShippingId, NULL AS ShipDate, so.SalesOrderNumber, CONCAT(emp.FirstName, ' ', emp.LastName) as EmployeeName,
				  		so.EmployeeId, so.OpenDate, so.CustomerReference as CustomerReference, so.CustomerId, CONCAT(empsp.FirstName, ' ', empsp.LastName) as SalesPerson,
				  		so.SalesPersonId, cf.CreditLimit, cf.CreditTermsId, so.[CreditTermName] as CreditTerm, so.FunctionalCurrencyId CurrencyId,
				  		so.TypeId, sotype.[Name] as RevType,ISNULL(sobii.QtyBilled, 0) NoofPieces,--(ISNULL(SOR.QtyToReserve, 0) - ISNULL(sobii.QtyBilled, 0)) as NoofPieces,
				  		sobi.OriginCountryId AS OriginCountryId, 
				  		sobi.ShipToCountryId AS ShipToCountryId, 
				  		ime.ExportECCN AS ECCN,
				  		ime.HSCODE AS HSCODE,
				  		ime.ExportWeight AS [Weight], 
				  		ime.ExportSizeLength AS BillSizeLength,
				  		ime.ExportSizeWidth AS BillSizeWidth,
				  		ime.ExportSizeWidth AS BillSizeHeight,
				  		sobi.SignEmpId AS SignEmpId,
				  		sobi.SignEmpDate AS SignEmpDate,
				  		sobi.InvoiceNo,
				  		ISNULL(sobii.PartCost,0) AS SalesTotal,
				  		ISNULL(sobii.Freight,0) AS Freight,
				  		ISNULL(sobii.MiscCharges,0) AS MiscCharges,
				  		ISNULL(sobi.SubTotal,0) AS SubTotal,
				  		ISNULL(sobi.SalesTax,0) AS SalesTax,
				  		ISNULL(sobi.OtherTax,0) AS OtherTax,
				  		ISNULL(sobi.GrandTotal,0) AS GrandTotal,
				  		@Result [BillShipInfoExist],
						@CostPlusType AS [CostPlusType],
						[so].[CustomerId] AS [SoldToCustomerId],
						[co].[Name] AS [SoldToCustomer],
						[cust_bill].[CustomerBillingAddressId] AS [SoldToSiteId],
						[co].[CustomerId] AS [ShipToCustomerId],
						[co].[Name] AS [ShipToCustomer],
						[cust_ship].[CustomerDomensticShippingId] AS [ShipToSiteId],
						ISNULL([cr].[Code], '') AS [Currency],
						[so].[ManagementStructureId],
						GETUTCDATE() AS [InvoiceDate],
						null AS [PrintDate],
						null AS ShipDate,
						BID.ShipviaId,
							sobi.InvoiceTypeId as InvoiceTypeId,@DefaultInvoiceTypeId DefaultInvoiceTypeId
				  	FROM DBO.SalesOrderPartV1 sop WITH (NOLOCK)
				  	INNER JOIN DBO.SalesOrder so WITH (NOLOCK) ON so.SalesOrderId = sop.SalesOrderId
				  	INNER JOIN DBO.Customer co WITH (NOLOCK) ON co.CustomerId = so.CustomerId
				  	INNER JOIN DBO.MasterSalesOrderQuoteTypes sotype WITH (NOLOCK) ON sotype.Id = so.TypeId
					LEFT JOIN [dbo].[CustomerDomensticShipping] [cust_ship] WITH(NOLOCK) ON [so].[CustomerId] = [cust_ship].[CustomerId]
					LEFT JOIN [dbo].[CustomerBillingAddress] [cust_bill] WITH(NOLOCK) ON [so].[CustomerId] = [cust_bill].[CustomerId]
				  	LEFT JOIN DBO.CustomerFinancial cf WITH (NOLOCK) ON cf.CustomerId = co.CustomerId
				  	LEFT JOIN DBO.Employee emp WITH (NOLOCK) ON emp.EmployeeId = so.EmployeeId
				  	LEFT JOIN DBO.Employee empsp WITH (NOLOCK) ON empsp.EmployeeId = so.SalesPersonId
				  	LEFT JOIN DBO.SalesOrderReserveParts SOR WITH (NOLOCK) on SOR.SalesOrderPartId = sop.SalesOrderPartId
					INNER JOIN DBO.BillingInvoicing sobi WITH (NOLOCK) on SO.SalesOrderId = sobi.ReferenceId AND sobi.ModuleId = @SOModuleId
				  	INNER JOIN DBO.BillingInvoicingItems sobii WITH (NOLOCK) on sobii.SubReferenceId = sop.SalesOrderPartId AND sobi.BillingInvoicingId = sobii.BillingInvoicingId  AND sobii.ModuleId = @SOModuleId
					INNER JOIN [dbo].[BillingInvoicingDetails] BID WITH(NOLOCK) ON sobi.[BillingInvoicingId] = BID.[BillingInvoicingId]
					LEFT JOIN [dbo].[Currency] [cr] WITH(NOLOCK) ON SO.FunctionalCurrencyId = [cr].[CurrencyId]
					LEFT JOIN DBO.ItemMaster im WITH (NOLOCK) ON sop.ItemMasterId = im.ItemMasterId
					LEFT JOIN DBO.ItemMasterExportInfo ime WITH (NOLOCK) ON im.ItemMasterId = ime.ItemMasterId

				  	WHERE  sobi.BillingInvoicingId = @BillingInvoicingId and ISNULL(sobi.IsVersionIncrease,0) = 0;
			END
			ELSE
			BEGIN
				 IF (@ShippingId != 0)
				 BEGIN
				 	SELECT TOP 1 sop.SalesOrderId, sop.SalesOrderPartId, sos.SalesOrderShippingId, sos.ShipDate, so.SalesOrderNumber, CONCAT(emp.FirstName, ' ', emp.LastName) as EmployeeName,
				 		so.EmployeeId, so.OpenDate, so.CustomerReference as CustomerReference, so.CustomerId, CONCAT(empsp.FirstName, ' ', empsp.LastName) as SalesPerson,
				 		so.SalesPersonId, cf.CreditLimit, cf.CreditTermsId, so.[CreditTermName] as CreditTerm, so.FunctionalCurrencyId as CurrencyId,
				 		so.TypeId, sotype.[Name] as RevType, sosi.QtyShipped as NoofPieces,
				 		sos.OriginCountryId, 
				 		sos.ShipToCountryId, 
				 		sop.ECCN AS ECCN,
				 		sop.HSCODE AS HSCODE,
				 		sop.[Weight], 
				 		sop.SizeLength AS BillSizeLength,
				 		sop.SizeWidth AS BillSizeWidth,
				 		sop.SizeHeight AS BillSizeHeight,
				 		emp.EmployeeId,
				 		0 as SignEmpId,
				 		0 AS InvoiceNo,
				 		NULL as SignEmpDate,
				 		0 AS SalesTotal,
				 		0 AS Freight,
				 		0 AS MiscCharges,
				 		0 AS SubTotal,
				 		0 AS SalesTax,
				 		0 AS OtherTax,
				 		0 AS GrandTotal,
				 		@Result [BillShipInfoExist],
						@CostPlusType AS [CostPlusType],
						[so].[CustomerId] AS [SoldToCustomerId],
						[sos].[SoldToName] AS [SoldToCustomer],
						[sos].[SoldToSiteId],
						[sos].[ShipToCustomerId],
						[sos].[ShipToName] AS [ShipToCustomer],
						[sos].[ShipToSiteId],
						ISNULL([cr].[Code], '') AS [Currency],
						[so].[ManagementStructureId],
						GETUTCDATE() AS [InvoiceDate],
						null AS [PrintDate],
						null AS ShipDate,
						--CASE 
						--	WHEN sos.[IsCustomerShipping] = 1 THEN sos.[CustomerDomensticShippingShipViaId]
						--	ELSE sos.[ShipviaId]
						--END AS [CustomerDomensticShippingShipViaId],
						sos.ShipviaId ShipViaId,
							0 as InvoiceTypeId,@DefaultInvoiceTypeId DefaultInvoiceTypeId
				 	FROM DBO.SalesOrderShipping sos WITH (NOLOCK) 
				 	INNER JOIN DBO.SalesOrderPartV1 sop WITH (NOLOCK) ON sop.SalesOrderId = sos.SalesOrderId
				 	INNER JOIN DBO.SalesOrderShippingItem sosi WITH (NOLOCK) ON sosi.SalesOrderShippingId = sos.SalesOrderShippingId AND sosi.SalesOrderPartId = sop.SalesOrderPartId
				 	INNER JOIN DBO.SalesOrder so WITH (NOLOCK) ON so.SalesOrderId = sop.SalesOrderId
				 	INNER JOIN DBO.Customer co WITH (NOLOCK) ON co.CustomerId = so.CustomerId
				 	INNER JOIN DBO.ItemMaster im WITH (NOLOCK) ON im.ItemMasterId = sop.ItemMasterId
				 	INNER JOIN DBO.MasterSalesOrderQuoteTypes sotype WITH (NOLOCK) ON sotype.Id = so.TypeId
				 	LEFT JOIN DBO.ItemMasterExportInfo imei WITH (NOLOCK) ON imei.ItemMasterId = im.ItemMasterId
				 	LEFT JOIN DBO.CustomerFinancial cf WITH (NOLOCK) ON cf.CustomerId = co.CustomerId
				 	LEFT JOIN DBO.Employee emp WITH (NOLOCK) ON emp.EmployeeId = so.EmployeeId
				 	LEFT JOIN DBO.Employee empsp WITH (NOLOCK) ON empsp.EmployeeId = so.SalesPersonId
					LEFT JOIN [dbo].[Currency] [cr] WITH(NOLOCK) ON so.FunctionalCurrencyId = [cr].[CurrencyId]
				 	WHERE sos.SalesOrderShippingId = @ShippingId;
				 END
				 ELSE
				 BEGIN
				 	SELECT TOP 1 sop.SalesOrderId, sop.SalesOrderPartId, 0 AS SalesOrderShippingId, NULL AS ShipDate, so.SalesOrderNumber, CONCAT(emp.FirstName, ' ', emp.LastName) as EmployeeName,
				 		so.EmployeeId, so.OpenDate, so.CustomerReference as CustomerReference, so.CustomerId, CONCAT(empsp.FirstName, ' ', empsp.LastName) as SalesPerson,
				 		so.SalesPersonId, cf.CreditLimit, cf.CreditTermsId, so.[CreditTermName] as CreditTerm, so.FunctionalCurrencyId CurrencyId,
				 		so.TypeId, sotype.[Name] as RevType, (ISNULL(SOR.QtyToReserve, 0) - ISNULL(sobii.QtyBilled, 0)) as NoofPieces, 
						sobi.OriginCountryId AS OriginCountryId, 
				  		sobi.ShipToCountryId AS ShipToCountryId, 
				 		sop.ECCN AS ECCN,
				 		sop.HSCODE AS HSCODE,
				 		sop.[Weight] AS [Weight], 
				 		sop.SizeLength AS BillSizeLength,
				 		sop.SizeWidth AS BillSizeWidth,
				 		sop.SizeHeight AS BillSizeHeight,
				 		sobi.SignEmpId AS SignEmpId,
				 		sobi.SignEmpDate AS SignEmpDate,
				 		sobi.InvoiceNo,
				 		0 AS SalesTotal,
				 		0 AS Freight,
				 		0 AS MiscCharges,
				 		0 AS SubTotal,
				 		0 AS SalesTax,
				 		0 AS OtherTax,
				 		0 AS GrandTotal,
				 		@Result [BillShipInfoExist],
						@CostPlusType AS [CostPlusType],
						[so].[CustomerId] AS [SoldToCustomerId],
						[co].[Name] AS [SoldToCustomer],
						[cust_bill].[CustomerBillingAddressId] AS [SoldToSiteId],
						[co].[CustomerId] AS [ShipToCustomerId],
						[co].[Name] AS [ShipToCustomer],
						[cust_ship].[CustomerDomensticShippingId] AS [ShipToSiteId],
						ISNULL([cr].[Code], '') AS [Currency],
						[so].[ManagementStructureId],
						GETUTCDATE() AS [InvoiceDate],
						null AS [PrintDate],
					    ISNULL([cust_shipVia].[ShipViaId], 0) AS ShipviaId,
						sobi.InvoiceTypeId as InvoiceTypeId,@DefaultInvoiceTypeId DefaultInvoiceTypeId
				 	FROM DBO.SalesOrderPartV1 sop WITH (NOLOCK)
				 	INNER JOIN DBO.SalesOrder so WITH (NOLOCK) ON so.SalesOrderId = sop.SalesOrderId
				 	INNER JOIN DBO.Customer co WITH (NOLOCK) ON co.CustomerId = so.CustomerId
				 	INNER JOIN DBO.MasterSalesOrderQuoteTypes sotype WITH (NOLOCK) ON sotype.Id = so.TypeId
				 	INNER JOIN DBO.ItemMaster im WITH (NOLOCK) ON im.ItemMasterId = sop.ItemMasterId
					LEFT JOIN [dbo].[CustomerDomensticShipping] [cust_ship] WITH(NOLOCK) ON [so].[CustomerId] = [cust_ship].[CustomerId]
					LEFT JOIN [dbo].[CustomerBillingAddress] [cust_bill] WITH(NOLOCK) ON [so].[CustomerId] = [cust_bill].[CustomerId]				 	
					LEFT JOIN DBO.CustomerFinancial cf WITH (NOLOCK) ON cf.CustomerId = co.CustomerId
				 	LEFT JOIN DBO.Employee emp WITH (NOLOCK) ON emp.EmployeeId = so.EmployeeId
				 	LEFT JOIN DBO.Employee empsp WITH (NOLOCK) ON empsp.EmployeeId = so.SalesPersonId
				 	LEFT JOIN DBO.SalesOrderReserveParts SOR WITH (NOLOCK) on SOR.SalesOrderPartId = sop.SalesOrderPartId
					LEFT JOIN DBO.BillingInvoicing sobi WITH (NOLOCK) on SO.SalesOrderId = sobi.ReferenceId AND ISNULL(sobi.IsPerformaInvoice,0) = 0 AND sobi.ModuleId = @SOModuleId
				 	LEFT JOIN DBO.BillingInvoicingItems sobii WITH (NOLOCK) on sobii.SubReferenceId = sop.SalesOrderPartId  AND sobi.BillingInvoicingId = sobii.BillingInvoicingId AND ISNULL(sobii.IsPerformaInvoice,0) = 0 AND sobii.ModuleId = @SOModuleId				 	
				 	LEFT JOIN DBO.ItemMasterExportInfo imei WITH (NOLOCK) ON imei.ItemMasterId = im.ItemMasterId
					LEFT JOIN [dbo].[Currency] [cr] WITH(NOLOCK) ON SO.FunctionalCurrencyId = [cr].[CurrencyId]
					LEFT JOIN [dbo].[BillingInvoicingDetails] BID WITH(NOLOCK) ON sobi.[BillingInvoicingId] = BID.[BillingInvoicingId]					
					LEFT JOIN [dbo].[CustomerDomensticShippingShipVia] [cust_shipVia] WITH(NOLOCK) ON [so].[CustomerId] = [cust_shipVia].[CustomerId] AND [cust_shipVia].[IsPrimary] = 1

				 	WHERE so.SalesOrderId = @ReferenceId;
				 END
			END			
					
		END /*********END: SALES ORDER ********/
		

	END TRY    
	BEGIN CATCH      
		IF @@trancount > 0
			PRINT 'ROLLBACK'            
			DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'GetBillingInvoicingDetails'             
			   ,@ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@ReferenceId, '') AS VARCHAR(100))
			                                       + '@Parameter2 = ''' + CAST(ISNULL(@SubReferenceId, '') AS VARCHAR(100)) 
												   + '@Parameter3 = ''' + CAST(ISNULL(@EmployeeId, '') AS VARCHAR(100)) 
												   + '@Parameter4 = ''' + CAST(ISNULL(@ModuleId, '') AS VARCHAR(100)) 
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