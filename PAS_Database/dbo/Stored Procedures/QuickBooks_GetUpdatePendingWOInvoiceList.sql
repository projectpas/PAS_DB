/*************************************************************           
 ** File:   [QuickBooks_GetUpdatePendingWOInvoiceList]           
 ** Author:   Devendra Shekh
 ** Description: Get WorkOrder Invoice List to Update Invoice in QuickBooks    
 ** Purpose:         
 ** Date:   09-Jan-2025        
         
 ** RETURN VALUE: 
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date			Author					Change Description            
 ** --   --------		-------					--------------------------------          
    1   09-Jan-2025		Devendra Shekh			Created
	2   03-Feb-2025		Devendra Shekh			Modified (Using [AccountingModule] table for Accounting Modules)
	3   12-Feb-2025		Devendra Shekh			Modified (Added New Field [ItemQuickBooksReferenceId])
	4   31-Mar-2025		Devendra Shekh			Modified (Added changes for Notes and bill/ship)
	5   03-Jul-2025     Moin Bloch              Changed Old To New Billing Table
     
 EXECUTE [QuickBooks_GetUpdatePendingWOInvoiceList] 1, 1, 4771, 4336
 EXECUTE [QuickBooks_GetUpdatePendingWOInvoiceList] 1, 1, 4772, 0
**************************************************************/ 
CREATE   PROCEDURE [dbo].[QuickBooks_GetUpdatePendingWOInvoiceList]
	@IntegrationTypeId INT = NULL,
	@MasterCompanyId INT = NULL,
	@ReferenceId BIGINT = NULL,
	@ReferencePartId BIGINT = NULL
AS
BEGIN
	
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED	
	BEGIN TRY

		DECLARE @InvModuleId INT = 0, @WOModuleId INT = 0;
		DECLARE @InvModuleName VARCHAR(200) = '';

		SELECT @InvModuleId = AccountingModuleId, @InvModuleName = AccountingModuleName FROM [dbo].[AccountingModule] WITH(NOLOCK) WHERE UPPER([AccountingModuleName]) = 'INVOICE';
		SELECT @WOModuleId = ModuleId FROM [dbo].[Module] WITH(NOLOCK) WHERE UPPER([ModuleName]) = 'WORKORDER';

		IF OBJECT_ID('tempdb..#InvoiceResults') IS NOT NULL
			DROP TABLE #InvoiceResults

		IF OBJECT_ID('tempdb..#InvoiceSyncData') IS NOT NULL
			DROP TABLE #InvoiceSyncData

		CREATE TABLE #InvoiceResults
		(
			[Id] BIGINT IDENTITY(1,1) NOT NULL,
			[InvoiceId] BIGINT NULL,
			[InvoiceNo] VARCHAR(256) NULL,
			[BillingInvoicingItemId] BIGINT NULL,
			[CustomerName] VARCHAR(100) NULL,
			[CustomerEmail] VARCHAR(200) NULL,
			[BillLine1] VARCHAR(50) NULL,
			[BillLine2] VARCHAR(50) NULL,
			[BillLine3] VARCHAR(50) NULL,
			[BillCity] VARCHAR(50) NULL,
			[BillPostalCode] VARCHAR(50) NULL,
			[PaymentTerms] VARCHAR(200) NULL,
			[InvoiceDate] DATETIME2 NULL,
			[DueDate] DATETIME2 NULL,
			[Tags] VARCHAR(100) NULL,
			[Product] VARCHAR(100) NULL,
			[PartNumber] VARCHAR(50) NULL,
			[PartDescription] VARCHAR(MAX) NULL,
			[Quantity] INT NULL,
			[SalesTax] DECIMAL(9,2) NULL,
			[OtherTax] DECIMAL(9,2) NULL,
			[SalesTaxPercent] DECIMAL(9,2) NULL,
			[OtherTaxPercent] DECIMAL(9,2) NULL,
			[TotalTax] DECIMAL(9,2) NULL,
			[SubTotal] DECIMAL(13,2) NULL,
			[GrandTotal] DECIMAL(13,2) NULL,
			[Deposit] DECIMAL(13,2) NULL,
			[UnitPrice] DECIMAL(13,2) NULL,
			[ShipLine1] VARCHAR(50) NULL,
			[ShipLine2] VARCHAR(50) NULL,
			[ShipLine3] VARCHAR(50) NULL,
			[ShipCity] VARCHAR(50) NULL,
			[ShipPostalCode] VARCHAR(50) NULL,
			[CustomerQuickBooksReferenceId] VARCHAR(200) NULL,
			[QuickBooksReferenceId] VARCHAR(200) NULL,
			[MasterCompanyId] INT NULL,
			[UpdatedBy] VARCHAR(256) NULL,
			[ModuleName] VARCHAR(256) NULL,
			[ModuleId] INT NULL,
			[ReferenceModuleId] INT NULL,
			[SyncToken] VARCHAR(200) NULL,
			[TermQuickBooksReferenceId] VARCHAR(200) NULL,
			[TaxRateRef] VARCHAR(50) NULL,
			[TxnTaxCodeRef] VARCHAR(50) NULL,
			[MaterialCost] DECIMAL(13,2) NULL,
			[LaborCost] DECIMAL(13,2) NULL,
			[MiscCharges] DECIMAL(13,2) NULL,
			[FreightCost] DECIMAL(13,2) NULL,
			[TotalWorkOrder] BIT NULL,
			[PercentValue] DECIMAL(13,2) NULL,
			[ItemQuickBooksReferenceId] VARCHAR(200) NULL,
			[WorkOrderId] BIGINT NULL,
			[CostPlusType] VARCHAR(20) NULL,
			[WorkOrderPartId] BIGINT NULL, 
			[ShipViaName] VARCHAR(300) NULL,
			[ShipDate] DATETIME2 NULL,
			[TrackingNo] VARCHAR(100) NULL,
			[ReferenceNumber] VARCHAR(50) NULL,
			[BillStateOrProvince] VARCHAR(50) NULL,
			[BillCountry] VARCHAR(50) NULL,
			[ShipStateOrProvince] VARCHAR(50) NULL,
			[ShipCountry] VARCHAR(50) NULL,
			[InvoiceNotes] NVARCHAR(MAX) NULL,
		)

		-- FOR QuickBooks
		IF(ISNULL(@IntegrationTypeId, 0) = 1) 
		BEGIN
			--Inserting Work Order Invoice Data
			IF(ISNULL(@ReferencePartId, 0) > 0)
			BEGIN
				INSERT INTO #InvoiceResults ([InvoiceId], [InvoiceNo], [BillingInvoicingItemId], [CustomerName], [CustomerEmail], [PaymentTerms], [InvoiceDate], [DueDate], [Tags], [Product],
				[PartNumber], [PartDescription], [Quantity], [SalesTax], [OtherTax], [SalesTaxPercent], [OtherTaxPercent], [TotalTax], [SubTotal], [GrandTotal], [Deposit], [UnitPrice], 
				[CustomerQuickBooksReferenceId], [QuickBooksReferenceId], [MasterCompanyId], [UpdatedBy], [ModuleName], [ModuleId], [ReferenceModuleId], [SyncToken], [TermQuickBooksReferenceId], [TaxRateRef], [TxnTaxCodeRef],
				[MaterialCost], [LaborCost], [MiscCharges], [FreightCost], [TotalWorkOrder], [PercentValue], [ItemQuickBooksReferenceId], [WorkOrderId], [CostPlusType],
				[WorkOrderPartId], [ShipViaName], [ReferenceNumber], [InvoiceNotes])
				SELECT	WOBI.BillingInvoicingId,
						WOBI.InvoiceNo,
						WOBII.BillingInvoicingItemId,
						C.[Name] AS Customer,
						C.Email AS CustomerEmail,
						WO.CreditTerms AS PaymentTerms,
						WOBI.PostedDate AS InvoieDate,
						NULL AS DueDate,
						'' AS Tags,
						'' AS Product,
						IM.partnumber AS PartNumber,
						IM.PartDescription,
						WOBII.QtyBilled AS Quantity,
						ISNULL(WOBI.SalesTax, 0) AS SalesTax,
						ISNULL(WOBI.OtherTax, 0) AS OtherTax,
						CASE WHEN ISNULL(WOBI.SalesTax, 0) = 0 OR ISNULL(WOBI.SubTotal, 0) = 0 THEN 0 ELSE (ISNULL(WOBI.SalesTax, 0) * 100 / ISNULL(WOBI.SubTotal, 0)) END AS SalesTaxPercent,
						CASE WHEN ISNULL(WOBI.OtherTax, 0) = 0 OR ISNULL(WOBI.SubTotal, 0) = 0 THEN 0 ELSE (ISNULL(WOBI.OtherTax, 0) * 100 / ISNULL(WOBI.SubTotal, 0)) END AS OtherTaxPercent,
						(ISNULL(WOBI.OtherTax, 0) + ISNULL(WOBI.SalesTax, 0)) AS TotalTax,
						ISNULL(WOBI.SubTotal, 0) AS SubTotal,
						ISNULL(WOBI.GrandTotal, 0) AS GrandTotal,
						ISNULL(WOBI.ProformaDeposit, 0) AS Deposit,
						ISNULL(WOBII.SubTotal, 0) AS UnitPrice,
						C.QuickBooksReferenceId as CustomerQuickBooksReferenceId, 
						WOBI.QuickBooksReferenceId, 
						WOBI.MasterCompanyId,
						WOBI.UpdatedBy,
						@InvModuleName,
						@InvModuleId,
						@WOModuleId,
						ISNULL(WOBI.SyncToken, '0') AS SyncToken,
						CT.QuickBooksReferenceId,
						P.TaxRateRef,
						P.TxnTaxCodeRef,
						ISNULL(WOBII.MaterialCost, 0),
						ISNULL(WOBII.LaborCost, 0),
						ISNULL(WOBII.MiscCharges, 0),
						ISNULL(WOBII.Freight, 0),
						ISNULL(WOBII.IsTotalCheck, 0),
						ISNULL(P.PercentValue, 0),
						IM.QuickBooksReferenceId,
						WOBI.ReferenceId,
						ISNULL(WOBI.CostPlusType, ''),
						WOBII.SubReferenceId,
						sipVia.[Name],
						WO.WorkOrderNum,
						WOBI.Notes
				FROM [dbo].[BillingInvoicingItems] WOBII WITH(NOLOCK) 
					JOIN [dbo].[BillingInvoicing] WOBI WITH(NOLOCK) ON WOBI.BillingInvoicingId = WOBII.BillingInvoicingId AND WOBI.[ModuleId] = @WOModuleId
					JOIN [dbo].[BillingInvoicingDetails] WOBID WITH(NOLOCK) ON WOBID.BillingInvoicingId = WOBI.BillingInvoicingId AND WOBI.[ModuleId] = @WOModuleId
					JOIN [dbo].[Customer] C WITH(NOLOCK) ON C.CustomerId = WOBI.CustomerId
					JOIN [dbo].[WorkOrder] WO WITH(NOLOCK) ON WO.WorkOrderId = WOBI.ReferenceId AND WOBI.[ModuleId] = @WOModuleId
					LEFT JOIN [dbo].[ItemMaster] IM WITH(NOLOCK) ON IM.ItemMasterId= WOBII.ItemMasterId					
					LEFT JOIN [dbo].[CreditTerms] CT WITH(NOLOCK) ON CT.CreditTermsId = WO.CreditTermId
					LEFT JOIN [dbo].[Percent] P with(nolock) ON P.MasterCompanyId = WOBI.MasterCompanyId AND P.PercentId = WOBII.SalesTaxPercent
					LEFT JOIN [dbo].[ShippingVia] AS sipVia WITH(NOLOCK) ON WOBID.CustomerDomensticShippingShipViaId = sipVia.ShippingViaId
				WHERE	ISNULL(WOBI.QuickBooksReferenceId, 0) != 0 AND ISNULL(WOBI.IsUpdated, 0) = 1 AND ISNULL(WOBI.IsPerformaInvoice, 0) = 0
						AND WOBII.SubReferenceId = @ReferencePartId AND WOBI.ReferenceId = @ReferenceId AND ISNULL(WOBI.IsVersionIncrease, 0) = 0 AND ISNULL(WOBII.IsVersionIncrease, 0) = 0;
			END
			ELSE
			BEGIN
				INSERT INTO #InvoiceResults ([InvoiceId], [InvoiceNo], [BillingInvoicingItemId], [CustomerName], [CustomerEmail], [PaymentTerms], [InvoiceDate], [DueDate], [Tags], [Product],
				[PartNumber], [PartDescription], [Quantity], [SalesTax], [OtherTax], [SalesTaxPercent], [OtherTaxPercent], [TotalTax], [SubTotal], [GrandTotal], [Deposit], [UnitPrice], 
				[CustomerQuickBooksReferenceId], [QuickBooksReferenceId], [MasterCompanyId], [UpdatedBy], [ModuleName], [ModuleId], [ReferenceModuleId], [SyncToken],
				[TermQuickBooksReferenceId], [TaxRateRef], [TxnTaxCodeRef], [MaterialCost], [LaborCost], [MiscCharges], [FreightCost], [TotalWorkOrder], [PercentValue], [ItemQuickBooksReferenceId], [WorkOrderId], [CostPlusType],
				[WorkOrderPartId], [ShipViaName], [ReferenceNumber], [InvoiceNotes])
				SELECT	WOBI.BillingInvoicingId,
						WOBI.InvoiceNo,
						WOBII.BillingInvoicingItemId,
						C.[Name] AS Customer,
						C.Email AS CustomerEmail,
						WO.CreditTerms AS PaymentTerms,
						WOBI.PostedDate AS InvoieDate,
						NULL AS DueDate,
						'' AS Tags,
						'' AS Product,
						IM.partnumber AS PartNumber,
						IM.PartDescription,
						WOBII.QtyBilled AS Quantity,
						ISNULL(WOBI.SalesTax, 0) AS SalesTax,
						ISNULL(WOBI.OtherTax, 0) AS OtherTax,
						CASE WHEN ISNULL(WOBI.SalesTax, 0) = 0 OR ISNULL(WOBI.SubTotal, 0) = 0 THEN 0 ELSE (ISNULL(WOBI.SalesTax, 0) * 100 / ISNULL(WOBI.SubTotal, 0)) END AS SalesTaxPercent,
						CASE WHEN ISNULL(WOBI.OtherTax, 0) = 0 OR ISNULL(WOBI.SubTotal, 0) = 0 THEN 0 ELSE (ISNULL(WOBI.OtherTax, 0) * 100 / ISNULL(WOBI.SubTotal, 0)) END AS OtherTaxPercent,
						(ISNULL(WOBI.OtherTax, 0) + ISNULL(WOBI.SalesTax, 0)) AS TotalTax,
						ISNULL(WOBI.SubTotal, 0) AS SubTotal,
						ISNULL(WOBI.GrandTotal, 0) AS GrandTotal,
						ISNULL(WOBI.ProformaDeposit, 0) AS Deposit,
						CASE	WHEN ISNULL(WOBII.IsTotalCheck, 0) = 0	THEN ISNULL(WOBII.SubTotal, 0)
								WHEN ISNULL(WOBII.IsTotalCheck, 0) = 1 THEN 
										CASE WHEN ISNULL(WOBII.SubTotal, 0) = 0 THEN ISNULL(WOBI.SubTotal, 0) ELSE ISNULL(WOBII.SubTotal, 0) END END AS UnitPrice,
						C.QuickBooksReferenceId as CustomerQuickBooksReferenceId, 
						WOBI.QuickBooksReferenceId, 
						WOBI.MasterCompanyId,
						WOBI.UpdatedBy,
						@InvModuleName,
						@InvModuleId,
						@WOModuleId,
						ISNULL(WOBI.SyncToken, '0') AS SyncToken,
						CT.QuickBooksReferenceId,
						P.TaxRateRef,
						P.TxnTaxCodeRef,
						ISNULL(WOBII.MaterialCost, 0),
						ISNULL(WOBII.LaborCost, 0),
						ISNULL(WOBII.MiscCharges, 0),
						ISNULL(WOBII.Freight, 0),
						ISNULL(WOBII.IsTotalCheck, 0),
						ISNULL(P.PercentValue, 0),
						IM.QuickBooksReferenceId,
						WOBI.ReferenceId,
						ISNULL(WOBI.CostPlusType, ''),
						WOBII.SubReferenceId,
						sipVia.[Name],
						WO.WorkOrderNum,
						WOBI.Notes
				FROM [dbo].[BillingInvoicingItems] WOBII WITH(NOLOCK) 
					JOIN [dbo].[BillingInvoicing] WOBI WITH(NOLOCK) ON WOBI.BillingInvoicingId = WOBII.BillingInvoicingId AND WOBI.[ModuleId] = @WOModuleId
					JOIN [dbo].[BillingInvoicingDetails] WOBID WITH(NOLOCK) ON WOBID.BillingInvoicingId = WOBI.BillingInvoicingId AND WOBI.[ModuleId] = @WOModuleId
					JOIN [dbo].[Customer] C WITH(NOLOCK) ON C.CustomerId = WOBI.CustomerId
					JOIN [dbo].[WorkOrder] WO WITH(NOLOCK) ON WO.WorkOrderId= WOBI.ReferenceId AND WOBI.[ModuleId] = @WOModuleId
					LEFT JOIN [dbo].[ItemMaster] IM WITH(NOLOCK) ON IM.ItemMasterId= WOBII.ItemMasterId					
					LEFT JOIN [dbo].[CreditTerms] CT WITH(NOLOCK) ON CT.CreditTermsId = WO.CreditTermId
					LEFT JOIN [dbo].[Percent] P with(nolock) ON P.MasterCompanyId = WOBI.MasterCompanyId AND P.PercentId = WOBII.SalesTaxPercent
					LEFT JOIN [dbo].[ShippingVia] AS sipVia WITH(NOLOCK) ON WOBID.CustomerDomensticShippingShipViaId = sipVia.ShippingViaId
				WHERE	ISNULL(WOBI.QuickBooksReferenceId, 0) != 0 AND ISNULL(WOBI.IsUpdated, 0) = 1 AND ISNULL(WOBI.IsPerformaInvoice, 0) = 0
						AND WOBI.ReferenceId = @ReferenceId AND ISNULL(WOBI.IsVersionIncrease, 0) = 0 AND ISNULL(WOBII.IsVersionIncrease, 0) = 0;
			END

			--Updating Shipping Details	: Start
			UPDATE TMP
			SET TMP.ShipDate = shipResult.ShipDate, TMP.TrackingNo = shipResult.AirwayBill
			FROM #InvoiceResults TMP
			OUTER APPLY(
					SELECT WS.ShipDate, WS.AirwayBill
					FROM [dbo].[WorkOrderShippingItem] WSIM WITH(NOLOCK)
					LEFT JOIN [dbo].[WorkOrderShipping] WS WITH(NOLOCK) ON WS.WorkOrderShippingId= WSIM.WorkOrderShippingId
					WHERE TMP.WorkOrderPartId = WSIM.WorkOrderPartNumId
					GROUP BY WS.ShipDate, WS.AirwayBill
			) shipResult
			--Updating Shipping Details	: End

			--Updating Address Details	: Start
			UPDATE TMPAddr
			SET	TMPAddr.BillLine1 = InvBillAddr.BillToAddressLine1,
				TMPAddr.BillLine2 = InvBillAddr.BillToAddressLine2,
				TMPAddr.BillCity = InvBillAddr.BillToCity,
				TMPAddr.BillStateOrProvince = InvBillAddr.BillToState,
				TMPAddr.BillPostalCode = InvBillAddr.BillToPostalCode,
				TMPAddr.BillCountry = InvBillAddr.BillToCountry,

				TMPAddr.ShipLine1 = InvShipAddr.ShipToAddressLine1,
				TMPAddr.ShipLine2 = InvShipAddr.ShipToAddressLine2,
				TMPAddr.ShipCity = InvShipAddr.ShipToCity,
				TMPAddr.ShipStateOrProvince = InvShipAddr.ShipToState,
				TMPAddr.ShipPostalCode = InvShipAddr.ShipToPostalCode,
				TMPAddr.ShipCountry = InvShipAddr.ShipToCountry
			FROM #InvoiceResults TMPAddr
			OUTER APPLY (
				SELECT	billToSite.SiteName AS BillToSiteName,
						billToAddress.Line1 AS BillToAddressLine1,
						billToAddress.Line2 AS BillToAddressLine2,
						billToAddress.City AS BillToCity,
						billToAddress.StateOrProvince AS BillToState,
						billToAddress.PostalCode AS BillToPostalCode,
						billToCountry.countries_name AS BillToCountry,
						billToCustomer.[Name] AS BillToNameOfCustomer,
						billToCustomer.Email AS BillToCustomerEmail
				FROM [dbo].[BillingInvoicing] BI WITH(NOLOCK)
				JOIN [dbo].[BillingInvoicingDetails] WOBID WITH(NOLOCK) ON WOBID.BillingInvoicingId = BI.BillingInvoicingId AND BI.[ModuleId] = @WOModuleId
				LEFT JOIN  [dbo].[Customer] billToCustomer WITH(NOLOCK) ON WOBID.SoldToCustomerId = billToCustomer.CustomerId
				LEFT JOIN  [dbo].[CustomerBillingAddress] AS billToSite WITH(NOLOCK) ON WOBID.SoldToSiteId = billToSite.CustomerBillingAddressId
				LEFT JOIN  [dbo].[Address] AS billToAddress WITH(NOLOCK) ON billToSite.AddressId = billToAddress.AddressId
				LEFT JOIN  [dbo].[Countries] AS billToCountry WITH(NOLOCK) ON billToAddress.CountryId = billToCountry.countries_id
				WHERE BI.BillingInvoicingId = TMPAddr.[InvoiceId]
			) InvBillAddr
			OUTER APPLY (
				SELECT 
					shipToSite.SiteName AS ShipToSiteName,
					shipToAddress.Line1 AS ShipToAddressLine1,
					shipToAddress.Line2 AS ShipToAddressLine2,
					shipToAddress.City AS ShipToCity,
					shipToAddress.StateOrProvince AS ShipToState,
					shipToAddress.PostalCode AS ShipToPostalCode,
					shipToCountry.countries_name AS ShipToCountry,
					shipToCustomer.[Name] AS ShipToNameOfCustomer,
					shipToCustomer.Email AS ShipToCustomerEmail
				FROM [dbo].[BillingInvoicing] BI WITH(NOLOCK)
				JOIN [dbo].[BillingInvoicingDetails] WOBID WITH(NOLOCK) ON WOBID.BillingInvoicingId = BI.BillingInvoicingId AND BI.[ModuleId] = @WOModuleId
				LEFT JOIN  [dbo].[Customer] shipToCustomer WITH(NOLOCK) ON WOBID.ShipToCustomerId = shipToCustomer.CustomerId
				LEFT JOIN  [dbo].[CustomerDomensticShipping] AS shipToSite WITH(NOLOCK) ON WOBID.shipToSiteId = shipToSite.CustomerDomensticShippingId
				LEFT JOIN  [dbo].[Address] AS shipToAddress WITH(NOLOCK) ON shipToSite.AddressId = shipToAddress.AddressId
				LEFT JOIN  [dbo].[Countries] AS shipToCountry WITH(NOLOCK) ON shipToAddress.CountryId = shipToCountry.countries_id
				WHERE BI.BillingInvoicingId = TMPAddr.[InvoiceId]
			) InvShipAddr
			--Updating Address Details	: End

			;With Result As(
			SELECT	[InvoiceId], [InvoiceNo], [CustomerName], [CustomerEmail], [BillLine1], [BillLine2], [BillLine3], [BillCity], [BillPostalCode], [PaymentTerms], [InvoiceDate], [DueDate], [Tags], [Product],
					CASE	WHEN UPPER([CostPlusType]) = 'FLAT RATE' THEN 1 ELSE [BillingInvoicingItemId] END AS [BillingInvoicingItemId],
					CASE	WHEN UPPER([CostPlusType]) = 'FLAT RATE' THEN [InvoiceNo] ELSE [PartNumber] END AS [PartNumber],
					CASE	WHEN UPPER([CostPlusType]) = 'FLAT RATE' THEN [ReferenceNumber] + ' - ' + [InvoiceNo] + ' Flat Rate' ELSE [PartDescription] END AS [PartDescription],
					CASE	WHEN UPPER([CostPlusType]) = 'FLAT RATE' THEN 1 ELSE [Quantity] END AS [Quantity],
					CASE	WHEN UPPER([CostPlusType]) = 'FLAT RATE' THEN '1' ELSE [ItemQuickBooksReferenceId] END AS [ItemQuickBooksReferenceId], 
					CASE	WHEN UPPER([CostPlusType]) = 'FLAT RATE' THEN [SubTotal] ELSE [UnitPrice] END AS [UnitPrice],
					CASE	WHEN UPPER([CostPlusType]) = 'FLAT RATE' THEN 0 ELSE [MaterialCost] END AS [MaterialCost], 
					CASE	WHEN UPPER([CostPlusType]) = 'FLAT RATE' THEN 0 ELSE [LaborCost] END AS [LaborCost],
					CASE	WHEN UPPER([CostPlusType]) = 'FLAT RATE' THEN 0 ELSE [MiscCharges] END AS [MiscCharges],
					CASE	WHEN UPPER([CostPlusType]) = 'FLAT RATE' THEN 0 ELSE [FreightCost] END AS [FreightCost],
					[SalesTax], [OtherTax], [SalesTaxPercent], [OtherTaxPercent], [TotalTax], [SubTotal], [GrandTotal], [Deposit],
					[ShipLine1], [ShipLine2], [ShipLine3], [ShipCity], [ShipPostalCode], [CustomerQuickBooksReferenceId], [QuickBooksReferenceId], [MasterCompanyId], [UpdatedBy], [ModuleName], [ModuleId], [ReferenceModuleId], [SyncToken]
					[TermQuickBooksReferenceId], [TaxRateRef], [TxnTaxCodeRef], [TotalWorkOrder], [PercentValue], [ShipViaName], [ShipDate], [TrackingNo], [BillStateOrProvince], [BillCountry], [ShipStateOrProvince], [ShipCountry], [InvoiceNotes]
			FROM #InvoiceResults TMP 
			)

			SELECT	[InvoiceId], [InvoiceNo], [BillingInvoicingItemId], [CustomerName], [CustomerEmail], [BillLine1], [BillLine2], [BillLine3], [BillCity], [BillPostalCode], [PaymentTerms], [InvoiceDate], [DueDate], [Tags], [Product],
					[PartNumber], [PartDescription], [Quantity], [ItemQuickBooksReferenceId], [UnitPrice], [MaterialCost], [LaborCost], [MiscCharges], [FreightCost],					
					[SalesTax], [OtherTax], [SalesTaxPercent], [OtherTaxPercent], [TotalTax], [SubTotal], [GrandTotal], [Deposit],
					[ShipLine1], [ShipLine2], [ShipLine3], [ShipCity], [ShipPostalCode], [CustomerQuickBooksReferenceId], [QuickBooksReferenceId], [MasterCompanyId], [UpdatedBy], [ModuleName], [ModuleId], [ReferenceModuleId], [SyncToken],
					[TermQuickBooksReferenceId], [TaxRateRef], [TxnTaxCodeRef], [TotalWorkOrder], [PercentValue], [ShipViaName], [ShipDate], [TrackingNo], [BillStateOrProvince], [BillCountry], [ShipStateOrProvince], [ShipCountry], [InvoiceNotes]
			INTO #InvoiceSyncData
			FROM Result
			GROUP BY	[InvoiceId], [InvoiceNo], [BillingInvoicingItemId], [CustomerName], [CustomerEmail], [BillLine1], [BillLine2], [BillLine3], [BillCity], [BillPostalCode], [PaymentTerms], [InvoiceDate], [DueDate], [Tags], [Product],
						[PartNumber], [PartDescription], [Quantity], [ItemQuickBooksReferenceId], [UnitPrice], [MaterialCost], [LaborCost], [MiscCharges], [FreightCost],				
						[SalesTax], [OtherTax], [SalesTaxPercent], [OtherTaxPercent], [TotalTax], [SubTotal], [GrandTotal], [Deposit],
						[ShipLine1], [ShipLine2], [ShipLine3], [ShipCity], [ShipPostalCode], [CustomerQuickBooksReferenceId], [QuickBooksReferenceId], [MasterCompanyId], [UpdatedBy], [ModuleName], [ModuleId], [ReferenceModuleId], [SyncToken],
						[TermQuickBooksReferenceId], [TaxRateRef], [TxnTaxCodeRef], [TotalWorkOrder], [PercentValue], [ShipViaName], [ShipDate], [TrackingNo], [BillStateOrProvince], [BillCountry], [ShipStateOrProvince], [ShipCountry], [InvoiceNotes]

			SELECT	[InvoiceId], [InvoiceNo], [BillingInvoicingItemId], [CustomerName], [CustomerEmail], [BillLine1], [BillLine2], [BillLine3], [BillCity], [BillPostalCode], [PaymentTerms], [InvoiceDate], [DueDate], [Tags], [Product],
					[PartNumber], [PartDescription], [Quantity], [ItemQuickBooksReferenceId], [UnitPrice], [MaterialCost], [LaborCost], [MiscCharges], [FreightCost],
					[SalesTax], [OtherTax], [SalesTaxPercent], [OtherTaxPercent], [TotalTax], [SubTotal], [GrandTotal], [Deposit], 
					[ShipLine1], [ShipLine2], [ShipLine3], [ShipCity], [ShipPostalCode], [CustomerQuickBooksReferenceId], [QuickBooksReferenceId], [MasterCompanyId], [UpdatedBy], [ModuleName], [ModuleId], [ReferenceModuleId], [SyncToken],
					[TermQuickBooksReferenceId], [TaxRateRef], [TxnTaxCodeRef], [TotalWorkOrder], [PercentValue], [ShipViaName], [ShipDate], [TrackingNo], [BillStateOrProvince], [BillCountry], [ShipStateOrProvince], [ShipCountry], [InvoiceNotes]
			FROM #InvoiceSyncData
			WHERE [TotalWorkOrder] = 1

			UNION

			SELECT	[InvoiceId], [InvoiceNo], [BillingInvoicingItemId], [CustomerName], [CustomerEmail], [BillLine1], [BillLine2], [BillLine3], [BillCity], [BillPostalCode], [PaymentTerms], [InvoiceDate], [DueDate], [Tags], [Product],
					[PartNumber], [PartNumber] + ' - ' + 'Material Cost' AS [PartDescription], [Quantity], [ItemQuickBooksReferenceId], [MaterialCost] AS [UnitPrice], [MaterialCost], [LaborCost], [MiscCharges], [FreightCost],
					[SalesTax], [OtherTax], [SalesTaxPercent], [OtherTaxPercent], [TotalTax], [SubTotal], [GrandTotal], [Deposit],
					[ShipLine1], [ShipLine2], [ShipLine3], [ShipCity], [ShipPostalCode], [CustomerQuickBooksReferenceId], [QuickBooksReferenceId], [MasterCompanyId], [UpdatedBy], [ModuleName], [ModuleId], [ReferenceModuleId], [SyncToken],
					[TermQuickBooksReferenceId], [TaxRateRef], [TxnTaxCodeRef], [TotalWorkOrder], [PercentValue], [ShipViaName], [ShipDate], [TrackingNo], [BillStateOrProvince], [BillCountry], [ShipStateOrProvince], [ShipCountry], [InvoiceNotes]
			FROM #InvoiceSyncData 
			WHERE MaterialCost > 0 AND [TotalWorkOrder] = 0

			UNION

			SELECT	[InvoiceId], [InvoiceNo], [BillingInvoicingItemId], [CustomerName], [CustomerEmail], [BillLine1], [BillLine2], [BillLine3], [BillCity], [BillPostalCode], [PaymentTerms], [InvoiceDate], [DueDate], [Tags], [Product],
					[PartNumber], [PartNumber] + ' - ' + 'Labor Cost' AS [PartDescription], [Quantity], [ItemQuickBooksReferenceId], [LaborCost] AS [UnitPrice], [MaterialCost], [LaborCost], [MiscCharges], [FreightCost],
					[SalesTax], [OtherTax], [SalesTaxPercent], [OtherTaxPercent], [TotalTax], [SubTotal], [GrandTotal], [Deposit], 
					[ShipLine1], [ShipLine2], [ShipLine3], [ShipCity], [ShipPostalCode], [CustomerQuickBooksReferenceId], [QuickBooksReferenceId], [MasterCompanyId], [UpdatedBy], [ModuleName], [ModuleId], [ReferenceModuleId], [SyncToken],
					[TermQuickBooksReferenceId], [TaxRateRef], [TxnTaxCodeRef], [TotalWorkOrder], [PercentValue], [ShipViaName], [ShipDate], [TrackingNo], [BillStateOrProvince], [BillCountry], [ShipStateOrProvince], [ShipCountry], [InvoiceNotes]
			FROM #InvoiceSyncData
			WHERE LaborCost > 0 AND [TotalWorkOrder] = 0

			UNION

			SELECT	[InvoiceId], [InvoiceNo], [BillingInvoicingItemId], [CustomerName], [CustomerEmail], [BillLine1], [BillLine2], [BillLine3], [BillCity], [BillPostalCode], [PaymentTerms], [InvoiceDate], [DueDate], [Tags], [Product],
					[PartNumber], [PartNumber] + ' - ' + 'Misc Charges Cost' AS [PartDescription], [Quantity], [ItemQuickBooksReferenceId], [MiscCharges] AS [UnitPrice], [MaterialCost], [LaborCost], [MiscCharges], [FreightCost],					
					[SalesTax], [OtherTax], [SalesTaxPercent], [OtherTaxPercent], [TotalTax], [SubTotal], [GrandTotal], [Deposit],
					[ShipLine1], [ShipLine2], [ShipLine3], [ShipCity], [ShipPostalCode], [CustomerQuickBooksReferenceId], [QuickBooksReferenceId], [MasterCompanyId], [UpdatedBy], [ModuleName], [ModuleId], [ReferenceModuleId], [SyncToken],
					[TermQuickBooksReferenceId], [TaxRateRef], [TxnTaxCodeRef], [TotalWorkOrder], [PercentValue], [ShipViaName], [ShipDate], [TrackingNo], [BillStateOrProvince], [BillCountry], [ShipStateOrProvince], [ShipCountry], [InvoiceNotes]
			FROM #InvoiceSyncData
			WHERE MiscCharges > 0 AND [TotalWorkOrder] = 0

			UNION

			SELECT	[InvoiceId], [InvoiceNo], [BillingInvoicingItemId], [CustomerName], [CustomerEmail], [BillLine1], [BillLine2], [BillLine3], [BillCity], [BillPostalCode], [PaymentTerms], [InvoiceDate], [DueDate], [Tags], [Product],
					[PartNumber], [PartNumber] + ' - ' + 'Freight Cost' AS [PartDescription], [Quantity], [ItemQuickBooksReferenceId], [FreightCost] AS [UnitPrice], [MaterialCost], [LaborCost], [MiscCharges], [FreightCost],				
					[SalesTax], [OtherTax], [SalesTaxPercent], [OtherTaxPercent], [TotalTax], [SubTotal], [GrandTotal], [Deposit],
					[ShipLine1], [ShipLine2], [ShipLine3], [ShipCity], [ShipPostalCode], [CustomerQuickBooksReferenceId], [QuickBooksReferenceId], [MasterCompanyId], [UpdatedBy], [ModuleName], [ModuleId], [ReferenceModuleId], [SyncToken],
					[TermQuickBooksReferenceId], [TaxRateRef], [TxnTaxCodeRef], [TotalWorkOrder], [PercentValue], [ShipViaName], [ShipDate], [TrackingNo], [BillStateOrProvince], [BillCountry], [ShipStateOrProvince], [ShipCountry], [InvoiceNotes]
			FROM #InvoiceSyncData
			WHERE FreightCost > 0 AND [TotalWorkOrder] = 0

		END
	END TRY    
	BEGIN CATCH      

	         DECLARE @ErrorLogID INT
			,@DatabaseName VARCHAR(100) = db_name()
			-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
			,@AdhocComments VARCHAR(150) = 'QuickBooks_GetUpdatePendingWOInvoiceList'
			,@ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@IntegrationTypeId, '') AS varchar(100))  			                                           
			,@ApplicationName VARCHAR(100) = 'PAS'
		-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
		EXEC spLogException @DatabaseName = @DatabaseName
			,@AdhocComments = @AdhocComments
			,@ProcedureParameters = @ProcedureParameters
			,@ApplicationName = @ApplicationName
			,@ErrorLogID = @ErrorLogID OUTPUT;

		RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)

		RETURN (1);           
	END CATCH
END