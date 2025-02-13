/*************************************************************           
 ** File:   [QuickBooks_GetSyncPendingWOInvoiceList]           
 ** Author:   Devendra Shekh
 ** Description: Get WorkOrder Invoice List to Create Invoice in QuickBooks    
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
     
 EXECUTE [QuickBooks_GetSyncPendingWOInvoiceList] 1, 1, 4771, 4336
 EXECUTE [QuickBooks_GetSyncPendingWOInvoiceList] 1, 1, 4772, 0
**************************************************************/ 
CREATE   PROCEDURE [dbo].[QuickBooks_GetSyncPendingWOInvoiceList]
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
		)

		-- FOR QuickBooks
		IF(ISNULL(@IntegrationTypeId, 0) = 1) 
		BEGIN
			--Inserting Work Order Invoice Data
			IF(ISNULL(@ReferencePartId, 0) > 0)
			BEGIN
				INSERT INTO #InvoiceResults ([InvoiceId], [InvoiceNo], [BillingInvoicingItemId], [CustomerName], [CustomerEmail], [BillLine1], [BillLine2], [BillLine3], [BillCity], [BillPostalCode], [PaymentTerms], [InvoiceDate], 
				[DueDate], [Tags], [Product], [PartNumber], [PartDescription], [Quantity], [SalesTax], [OtherTax], [SalesTaxPercent], [OtherTaxPercent], [TotalTax], [SubTotal], [GrandTotal], [Deposit], [UnitPrice], 
				[ShipLine1], [ShipLine2], [ShipLine3], [ShipCity], [ShipPostalCode], [CustomerQuickBooksReferenceId], [QuickBooksReferenceId], [MasterCompanyId], [UpdatedBy], [ModuleName], [ModuleId], [ReferenceModuleId],
				[TermQuickBooksReferenceId], [TaxRateRef], [TxnTaxCodeRef], [MaterialCost], [LaborCost], [MiscCharges], [FreightCost], [TotalWorkOrder], [PercentValue], [ItemQuickBooksReferenceId])
				SELECT	WOBI.BillingInvoicingId,
						WOBI.InvoiceNo,
						WOBII.WOBillingInvoicingItemId,
						C.[Name] AS Customer,
						C.Email AS CustomerEmail,
						COALESCE(billToAddress.Line1, '') AS BillLine1,
						COALESCE(billToAddress.Line2, '') AS BillLine2,
						COALESCE(billToAddress.Line3, '') AS BillLine3,
						COALESCE(billToAddress.City, '') AS BillCity,
						COALESCE(billToAddress.PostalCode, '') AS BillPostalCode,
						WO.CreditTerms AS PaymentTerms,
						WOBI.PostedDate AS InvoieDate,
						--CASE WHEN WOBI.PostedDate IS NULL THEN NULL ELSE DATEADD(DAY, 5, WOBI.PostedDate) END AS DueDate,
						NULL AS DueDate,
						'' AS Tags,
						'' AS Product,
						IM.partnumber AS PartNumber,
						IM.PartDescription,
						WOBII.NoofPieces AS Quantity,
						ISNULL(WOBI.SalesTax, 0) AS SalesTax,
						ISNULL(WOBI.OtherTax, 0) AS OtherTax,
						CASE WHEN ISNULL(WOBI.SalesTax, 0) = 0 OR ISNULL(WOBI.SubTotal, 0) = 0 THEN 0 ELSE (ISNULL(WOBI.SalesTax, 0) * 100 / ISNULL(WOBI.SubTotal, 0)) END AS SalesTaxPercent,
						CASE WHEN ISNULL(WOBI.OtherTax, 0) = 0 OR ISNULL(WOBI.SubTotal, 0) = 0 THEN 0 ELSE (ISNULL(WOBI.OtherTax, 0) * 100 / ISNULL(WOBI.SubTotal, 0)) END AS OtherTaxPercent,
						(ISNULL(WOBI.OtherTax, 0) + ISNULL(WOBI.SalesTax, 0)) AS TotalTax,
						ISNULL(WOBI.SubTotal, 0) AS SubTotal,
						ISNULL(WOBI.GrandTotal, 0) AS GrandTotal,
						ISNULL(WOBI.ProformaDeposit, 0) AS Deposit,
						ISNULL(WOBII.SubTotal, 0) AS UnitPrice,
						COALESCE(shipToAddress.Line1, '') AS ShipLine1,
						COALESCE(shipToAddress.Line2, '') AS ShipLine2,
						COALESCE(shipToAddress.Line3, '') AS ShipLine3,
						COALESCE(shipToAddress.City, '') AS ShipCity,
						COALESCE(shipToAddress.PostalCode, '') AS ShipPostalCode,
						C.QuickBooksReferenceId as CustomerQuickBooksReferenceId, 
						WOBI.QuickBooksReferenceId, 
						WOBI.MasterCompanyId,
						WOBI.UpdatedBy,
						@InvModuleName,
						@InvModuleId,
						@WOModuleId,
						CT.QuickBooksReferenceId,
						P.TaxRateRef,
						P.TxnTaxCodeRef,
						ISNULL(WOBII.MaterialCost, 0),
						ISNULL(WOBII.LaborCost, 0),
						ISNULL(WOBII.MiscCharges, 0),
						ISNULL(WOBII.Freight, 0),
						ISNULL(WOBI.TotalWorkOrder, 0),
						ISNULL(P.PercentValue, 0),
						IM.QuickBooksReferenceId
				FROM [dbo].[WorkOrderBillingInvoicingItem] WOBII WITH(NOLOCK) 
					JOIN [dbo].[WorkOrderBillingInvoicing] WOBI WITH(NOLOCK) ON WOBI.BillingInvoicingId = WOBII.BillingInvoicingId
					JOIN [dbo].[Customer] C WITH(NOLOCK) ON C.CustomerId = WOBI.CustomerId
					JOIN [dbo].[WorkOrder] WO WITH(NOLOCK) ON WO.WorkOrderId= WOBI.WorkOrderId
					LEFT JOIN [dbo].[ItemMaster] IM WITH(NOLOCK) ON IM.ItemMasterId= WOBII.ItemMasterId
					LEFT JOIN [dbo].[CustomerBillingAddress] billToSite WITH(NOLOCK) ON WOBI.SoldToSiteId = billToSite.CustomerBillingAddressId
					LEFT JOIN [dbo].[Address] billToAddress WITH(NOLOCK) ON billToSite.AddressId = billToAddress.AddressId
					LEFT JOIN [dbo].[CustomerDomensticShipping] shipToSite WITH(NOLOCK) ON WOBI.ShipToSiteId = shipToSite.CustomerDomensticShippingId
					LEFT JOIN [dbo].[Address] shipToAddress WITH(NOLOCK) ON shipToSite.AddressId = shipToAddress.AddressId
					LEFT JOIN [dbo].[CreditTerms] CT WITH(NOLOCK) ON CT.CreditTermsId = WO.CreditTermId
					LEFT JOIN [dbo].[Percent] P with(nolock) ON P.MasterCompanyId = WOBI.MasterCompanyId AND P.PercentId = WOBII.TaxRate
					--LEFT JOIN [dbo].[Percent] P with(nolock) ON P.MasterCompanyId = WOBI.MasterCompanyId AND P.PercentValue = ((ISNULL(WOBI.SalesTax,0) + ISNULL(WOBI.OtherTax,0))*100 / ISNULL(WOBI.SubTotal,0))
				WHERE	ISNULL(WOBI.QuickBooksReferenceId, 0) = 0 AND ISNULL(WOBI.IsUpdated, 0) = 1 AND ISNULL(WOBI.IsPerformaInvoice, 0) = 0 
						AND WOBII.WorkOrderPartId = @ReferencePartId AND WOBI.WorkOrderId = @ReferenceId AND ISNULL(WOBI.IsVersionIncrease, 0) = 0 AND ISNULL(WOBII.IsVersionIncrease, 0) = 0;
			END
			ELSE
			BEGIN
				INSERT INTO #InvoiceResults ([InvoiceId], [InvoiceNo], [BillingInvoicingItemId], [CustomerName], [CustomerEmail], [BillLine1], [BillLine2], [BillLine3], [BillCity], [BillPostalCode], [PaymentTerms], [InvoiceDate], 
				[DueDate], [Tags], [Product], [PartNumber], [PartDescription], [Quantity], [SalesTax], [OtherTax], [SalesTaxPercent], [OtherTaxPercent], [TotalTax], [SubTotal], [GrandTotal], [Deposit], [UnitPrice], 
				[ShipLine1], [ShipLine2], [ShipLine3], [ShipCity], [ShipPostalCode], [CustomerQuickBooksReferenceId], [QuickBooksReferenceId], [MasterCompanyId], [UpdatedBy], [ModuleName], [ModuleId], [ReferenceModuleId],
				[TermQuickBooksReferenceId], [TaxRateRef], [TxnTaxCodeRef], [MaterialCost], [LaborCost], [MiscCharges], [FreightCost], [TotalWorkOrder], [PercentValue], [ItemQuickBooksReferenceId])
				SELECT	WOBI.BillingInvoicingId,
						WOBI.InvoiceNo,
						WOBII.WOBillingInvoicingItemId,
						C.[Name] AS Customer,
						C.Email AS CustomerEmail,
						COALESCE(billToAddress.Line1, '') AS BillLine1,
						COALESCE(billToAddress.Line2, '') AS BillLine2,
						COALESCE(billToAddress.Line3, '') AS BillLine3,
						COALESCE(billToAddress.City, '') AS BillCity,
						COALESCE(billToAddress.PostalCode, '') AS BillPostalCode,
						WO.CreditTerms AS PaymentTerms,
						WOBI.PostedDate AS InvoieDate,
						--CASE WHEN WOBI.PostedDate IS NULL THEN NULL ELSE DATEADD(DAY, 5, WOBI.PostedDate) END AS DueDate,
						NULL AS DueDate,
						'' AS Tags,
						'' AS Product,
						IM.partnumber AS PartNumber,
						IM.PartDescription,
						WOBII.NoofPieces AS Quantity,
						ISNULL(WOBI.SalesTax, 0) AS SalesTax,
						ISNULL(WOBI.OtherTax, 0) AS OtherTax,
						CASE WHEN ISNULL(WOBI.SalesTax, 0) = 0 OR ISNULL(WOBI.SubTotal, 0) = 0 THEN 0 ELSE (ISNULL(WOBI.SalesTax, 0) * 100 / ISNULL(WOBI.SubTotal, 0)) END AS SalesTaxPercent,
						CASE WHEN ISNULL(WOBI.OtherTax, 0) = 0 OR ISNULL(WOBI.SubTotal, 0) = 0 THEN 0 ELSE (ISNULL(WOBI.OtherTax, 0) * 100 / ISNULL(WOBI.SubTotal, 0)) END AS OtherTaxPercent,
						(ISNULL(WOBI.OtherTax, 0) + ISNULL(WOBI.SalesTax, 0)) AS TotalTax,
						ISNULL(WOBI.SubTotal, 0) AS SubTotal,
						ISNULL(WOBI.GrandTotal, 0) AS GrandTotal,
						ISNULL(WOBI.ProformaDeposit, 0) AS Deposit,
						ISNULL(WOBII.SubTotal, 0) AS UnitPrice,
						COALESCE(shipToAddress.Line1, '') AS ShipLine1,
						COALESCE(shipToAddress.Line2, '') AS ShipLine2,
						COALESCE(shipToAddress.Line3, '') AS ShipLine3,
						COALESCE(shipToAddress.City, '') AS ShipCity,
						COALESCE(shipToAddress.PostalCode, '') AS ShipPostalCode,
						C.QuickBooksReferenceId as CustomerQuickBooksReferenceId, 
						WOBI.QuickBooksReferenceId, 
						WOBI.MasterCompanyId,
						WOBI.UpdatedBy,
						@InvModuleName,
						@InvModuleId,
						@WOModuleId,
						CT.QuickBooksReferenceId,
						P.TaxRateRef,
						P.TxnTaxCodeRef,
						ISNULL(WOBII.MaterialCost, 0),
						ISNULL(WOBII.LaborCost, 0),
						ISNULL(WOBII.MiscCharges, 0),
						ISNULL(WOBII.Freight, 0),
						ISNULL(WOBI.TotalWorkOrder, 0),
						ISNULL(P.PercentValue, 0),
						IM.QuickBooksReferenceId
				FROM [dbo].[WorkOrderBillingInvoicingItem] WOBII WITH(NOLOCK) 
					JOIN [dbo].[WorkOrderBillingInvoicing] WOBI WITH(NOLOCK) ON WOBI.BillingInvoicingId = WOBII.BillingInvoicingId
					JOIN [dbo].[Customer] C WITH(NOLOCK) ON C.CustomerId = WOBI.CustomerId
					JOIN [dbo].[WorkOrder] WO WITH(NOLOCK) ON WO.WorkOrderId= WOBI.WorkOrderId
					LEFT JOIN [dbo].[ItemMaster] IM WITH(NOLOCK) ON IM.ItemMasterId= WOBII.ItemMasterId
					LEFT JOIN [dbo].[CustomerBillingAddress] billToSite WITH(NOLOCK) ON WOBI.SoldToSiteId = billToSite.CustomerBillingAddressId
					LEFT JOIN [dbo].[Address] billToAddress WITH(NOLOCK) ON billToSite.AddressId = billToAddress.AddressId
					LEFT JOIN [dbo].[CustomerDomensticShipping] shipToSite WITH(NOLOCK) ON WOBI.ShipToSiteId = shipToSite.CustomerDomensticShippingId
					LEFT JOIN [dbo].[Address] shipToAddress WITH(NOLOCK) ON shipToSite.AddressId = shipToAddress.AddressId
					LEFT JOIN [dbo].[CreditTerms] CT WITH(NOLOCK) ON CT.CreditTermsId = WO.CreditTermId
					LEFT JOIN [dbo].[Percent] P with(nolock) ON P.MasterCompanyId = WOBI.MasterCompanyId AND P.PercentId = WOBII.TaxRate
					--LEFT JOIN [dbo].[Percent] P with(nolock) ON P.MasterCompanyId = WOBI.MasterCompanyId AND P.PercentValue = ((ISNULL(WOBI.SalesTax,0) + ISNULL(WOBI.OtherTax,0))*100 / ISNULL(WOBI.SubTotal,0))
				WHERE	ISNULL(WOBI.QuickBooksReferenceId, 0) = 0 AND ISNULL(WOBI.IsUpdated, 0) = 1 AND ISNULL(WOBI.IsPerformaInvoice, 0) = 0 
						AND WOBI.WorkOrderId = @ReferenceId AND ISNULL(WOBI.IsVersionIncrease, 0) = 0 AND ISNULL(WOBII.IsVersionIncrease, 0) = 0;
			END

			SELECT	[InvoiceId], [InvoiceNo], [BillingInvoicingItemId], [CustomerName], [CustomerEmail], [BillLine1], [BillLine2], [BillLine3], [BillCity], [BillPostalCode], [PaymentTerms], [InvoiceDate], 
					[DueDate], [Tags], [Product], [PartNumber], [PartNumber] + ' - ' + [PartDescription] AS [PartDescription], [Quantity], [SalesTax], [OtherTax], [SalesTaxPercent], [OtherTaxPercent], [TotalTax], [SubTotal], [GrandTotal], [Deposit], [UnitPrice], 
					[ShipLine1], [ShipLine2], [ShipLine3], [ShipCity], [ShipPostalCode], [CustomerQuickBooksReferenceId], [QuickBooksReferenceId], [MasterCompanyId], [UpdatedBy], [ModuleName], [ModuleId], [ReferenceModuleId],
					[TermQuickBooksReferenceId], [TaxRateRef], [TxnTaxCodeRef], [MaterialCost], [LaborCost], [MiscCharges], [FreightCost], [TotalWorkOrder], [PercentValue], [ItemQuickBooksReferenceId]
			FROM #InvoiceResults
			WHERE [TotalWorkOrder] = 1

			UNION

			SELECT	[InvoiceId], [InvoiceNo], [BillingInvoicingItemId], [CustomerName], [CustomerEmail], [BillLine1], [BillLine2], [BillLine3], [BillCity], [BillPostalCode], [PaymentTerms], [InvoiceDate], 
					[DueDate], [Tags], [Product],
					[PartNumber], [PartNumber] + ' - ' + 'Material Cost' AS [PartDescription],
					[Quantity], [SalesTax], [OtherTax], [SalesTaxPercent], [OtherTaxPercent], [TotalTax], [SubTotal], [GrandTotal], [Deposit], [MaterialCost] AS [UnitPrice], 
					[ShipLine1], [ShipLine2], [ShipLine3], [ShipCity], [ShipPostalCode], [CustomerQuickBooksReferenceId], [QuickBooksReferenceId], [MasterCompanyId], [UpdatedBy], [ModuleName], [ModuleId], [ReferenceModuleId],
					[TermQuickBooksReferenceId], [TaxRateRef], [TxnTaxCodeRef], [MaterialCost], [LaborCost], [MiscCharges], [FreightCost], [TotalWorkOrder], [PercentValue], [ItemQuickBooksReferenceId]
			FROM #InvoiceResults 
			WHERE MaterialCost > 0 AND [TotalWorkOrder] = 0

			UNION

			SELECT	[InvoiceId], [InvoiceNo], [BillingInvoicingItemId], [CustomerName], [CustomerEmail], [BillLine1], [BillLine2], [BillLine3], [BillCity], [BillPostalCode], [PaymentTerms], [InvoiceDate], 
					[DueDate], [Tags], [Product],
					[PartNumber], [PartNumber] + ' - ' + 'Labor Cost' AS [PartDescription],
					[Quantity], [SalesTax], [OtherTax], [SalesTaxPercent], [OtherTaxPercent], [TotalTax], [SubTotal], [GrandTotal], [Deposit], [LaborCost] AS [UnitPrice], 
					[ShipLine1], [ShipLine2], [ShipLine3], [ShipCity], [ShipPostalCode], [CustomerQuickBooksReferenceId], [QuickBooksReferenceId], [MasterCompanyId], [UpdatedBy], [ModuleName], [ModuleId], [ReferenceModuleId],
					[TermQuickBooksReferenceId], [TaxRateRef], [TxnTaxCodeRef], [MaterialCost], [LaborCost], [MiscCharges], [FreightCost], [TotalWorkOrder], [PercentValue], [ItemQuickBooksReferenceId]
			FROM #InvoiceResults
			WHERE LaborCost > 0 AND [TotalWorkOrder] = 0

			UNION

			SELECT	[InvoiceId], [InvoiceNo], [BillingInvoicingItemId], [CustomerName], [CustomerEmail], [BillLine1], [BillLine2], [BillLine3], [BillCity], [BillPostalCode], [PaymentTerms], [InvoiceDate], 
					[DueDate], [Tags], [Product],
					[PartNumber], [PartNumber] + ' - ' + 'Misc Charges Cost' AS [PartDescription],
					[Quantity], [SalesTax], [OtherTax], [SalesTaxPercent], [OtherTaxPercent], [TotalTax], [SubTotal], [GrandTotal], [Deposit], [MiscCharges] AS [UnitPrice], 
					[ShipLine1], [ShipLine2], [ShipLine3], [ShipCity], [ShipPostalCode], [CustomerQuickBooksReferenceId], [QuickBooksReferenceId], [MasterCompanyId], [UpdatedBy], [ModuleName], [ModuleId], [ReferenceModuleId],
					[TermQuickBooksReferenceId], [TaxRateRef], [TxnTaxCodeRef], [MaterialCost], [LaborCost], [MiscCharges], [FreightCost], [TotalWorkOrder], [PercentValue], [ItemQuickBooksReferenceId]
			FROM #InvoiceResults
			WHERE MiscCharges > 0 AND [TotalWorkOrder] = 0

			UNION

			SELECT	[InvoiceId], [InvoiceNo], [BillingInvoicingItemId], [CustomerName], [CustomerEmail], [BillLine1], [BillLine2], [BillLine3], [BillCity], [BillPostalCode], [PaymentTerms], [InvoiceDate], 
					[DueDate], [Tags], [Product],
					[PartNumber], [PartNumber] + ' - ' + 'Freight Cost' AS [PartDescription],
					[Quantity], [SalesTax], [OtherTax], [SalesTaxPercent], [OtherTaxPercent], [TotalTax], [SubTotal], [GrandTotal], [Deposit], [FreightCost] AS [UnitPrice], 
					[ShipLine1], [ShipLine2], [ShipLine3], [ShipCity], [ShipPostalCode], [CustomerQuickBooksReferenceId], [QuickBooksReferenceId], [MasterCompanyId], [UpdatedBy], [ModuleName], [ModuleId], [ReferenceModuleId],
					[TermQuickBooksReferenceId], [TaxRateRef], [TxnTaxCodeRef], [MaterialCost], [LaborCost], [MiscCharges], [FreightCost], [TotalWorkOrder], [PercentValue], [ItemQuickBooksReferenceId]
			FROM #InvoiceResults
			WHERE FreightCost > 0 AND [TotalWorkOrder] = 0

		END
	END TRY    
	BEGIN CATCH      

	         DECLARE @ErrorLogID INT
			,@DatabaseName VARCHAR(100) = db_name()
			-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
			,@AdhocComments VARCHAR(150) = 'QuickBooks_GetSyncPendingWOInvoiceList'
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