/*************************************************************           
 ** File:   [QuickBooks_GetUpdatePendingExChangeInvoiceList]           
 ** Author:   Devendra Shekh
 ** Description: Get ExChange Invoice List to Update Invoice in QuickBooks    
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
	5    01/July/2026			 RAJESH GAMI						[PN-17008] - Merge Non Stock Inventory to ItemMaster : Get only Stock Inventory Data Where IsNonStock = 0
     
 EXECUTE [QuickBooks_GetUpdatePendingExChangeInvoiceList] 1, 1, 523, 0
**************************************************************/ 
CREATE   PROCEDURE [dbo].[QuickBooks_GetUpdatePendingExChangeInvoiceList]
	@IntegrationTypeId INT = NULL,
	@MasterCompanyId INT = NULL,
	@ReferenceId BIGINT = NULL,
	@ReferencePartId BIGINT = NULL
AS
BEGIN
	
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED	
	BEGIN TRY

		DECLARE @InvModuleId INT = 0, @ExchModuleId INT = 0;
		DECLARE @InvModuleName VARCHAR(200) = '';

		SELECT @InvModuleId = AccountingModuleId, @InvModuleName = AccountingModuleName FROM [dbo].[AccountingModule] WITH(NOLOCK) WHERE UPPER([AccountingModuleName]) = 'INVOICE';
		SELECT @ExchModuleId = ModuleId FROM [dbo].[Module] WITH(NOLOCK) WHERE UPPER([ModuleName]) = 'EXCHANGESALESORDER';

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
			[SyncToken] VARCHAR(200) NULL,
			[TermQuickBooksReferenceId] VARCHAR(200) NULL,
			[TaxRateRef] VARCHAR(50) NULL,
			[TxnTaxCodeRef] VARCHAR(50) NULL,
			[MaterialCost] DECIMAL(13,2) NULL,
			[MiscCharges] DECIMAL(13,2) NULL,
			[FreightCost] DECIMAL(13,2) NULL,
			[PercentValue] DECIMAL(13,2) NULL,
			[BillingType] VARCHAR(100) NULL,
			[ItemQuickBooksReferenceId] VARCHAR(200) NULL,
			[ExchangeSalesOrderPartId] BIGINT NULL, 
			[ShipViaName] VARCHAR(300) NULL,
			[ShipDate] DATETIME2 NULL,
			[TrackingNo] VARCHAR(100) NULL,
			[BillStateOrProvince] VARCHAR(50) NULL,
			[BillCountry] VARCHAR(50) NULL,
			[ShipStateOrProvince] VARCHAR(50) NULL,
			[ShipCountry] VARCHAR(50) NULL,
			[InvoiceNotes] NVARCHAR(MAX) NULL,
		)

		-- FOR QuickBooks
		IF(ISNULL(@IntegrationTypeId, 0) = 1) 
		BEGIN
			--Inserting Exchange Sales Order Invoice Data
			IF(ISNULL(@ReferencePartId, 0) > 0)
			BEGIN
				INSERT INTO #InvoiceResults ([InvoiceId], [InvoiceNo], [BillingInvoicingItemId], [CustomerName], [CustomerEmail], [BillLine1], [BillLine2], [BillLine3], [BillCity], [BillPostalCode], [PaymentTerms], [InvoiceDate], 
				[DueDate], [Tags], [Product], [PartNumber], [PartDescription], [Quantity], [SalesTax], [OtherTax], [SalesTaxPercent], [OtherTaxPercent], [TotalTax], [SubTotal], [GrandTotal], [Deposit], [UnitPrice],
				[ShipLine1], [ShipLine2], [ShipLine3], [ShipCity], [ShipPostalCode], [CustomerQuickBooksReferenceId], [QuickBooksReferenceId], [MasterCompanyId], [UpdatedBy], [ModuleName], [ModuleId], [ReferenceModuleId], [SyncToken],
				[TermQuickBooksReferenceId], [TaxRateRef], [TxnTaxCodeRef], [MaterialCost], [MiscCharges], [FreightCost], [PercentValue], [BillingType], [ItemQuickBooksReferenceId], [ExchangeSalesOrderPartId],
				[BillStateOrProvince], [BillCountry], [ShipStateOrProvince], [ShipCountry], [InvoiceNotes])
				SELECT	SOBI.SOBillingInvoicingId,
						SOBI.InvoiceNo,
						SOBII.ExchangeSOBillingInvoicingItemId,
						C.[Name] AS Customer,
						C.Email AS CustomerEmail,
						COALESCE(billToAddress.Line1, '') AS BillLine1,
						COALESCE(billToAddress.Line2, '') AS BillLine2,
						COALESCE(billToAddress.Line3, '') AS BillLine3,
						COALESCE(billToAddress.City, '') AS BillCity,
						COALESCE(billToAddress.PostalCode, '') AS BillPostalCode,
						SO.CreditTermName AS PaymentTerms,
						SOBI.PostedDate AS InvoieDate,
						NULL AS DueDate,
						'' AS Tags,
						'' AS Product,
						IM.partnumber AS PartNumber,
						IM.PartDescription,
						SOBII.NoofPieces AS Quantity,
						ISNULL(SOBI.SalesTax, 0) AS SalesTax,
						ISNULL(SOBI.OtherTax, 0) AS OtherTax,
						CASE WHEN ISNULL(SOBI.SalesTax, 0) = 0 OR ISNULL(SOBI.SubTotal, 0) = 0 THEN 0 ELSE (ISNULL(SOBI.SalesTax, 0) * 100 / ISNULL(SOBI.SubTotal, 0)) END AS SalesTaxPercent,
						CASE WHEN ISNULL(SOBI.OtherTax, 0) = 0 OR ISNULL(SOBI.SubTotal, 0) = 0 THEN 0 ELSE (ISNULL(SOBI.OtherTax, 0) * 100 / ISNULL(SOBI.SubTotal, 0)) END AS OtherTaxPercent,
						(ISNULL(SOBI.OtherTax, 0) + ISNULL(SOBI.SalesTax, 0)) AS TotalTax,
						ISNULL(SOBI.SubTotal, 0) AS SubTotal,
						ISNULL(SOBI.GrandTotal, 0) AS GrandTotal,
						0 AS Deposit,
						ISNULL(SOBII.UnitPrice, 0) AS UnitPrice,
						COALESCE(shipToAddress.Line1, '') AS ShipLine1,
						COALESCE(shipToAddress.Line2, '') AS ShipLine2,
						COALESCE(shipToAddress.Line3, '') AS ShipLine3,
						COALESCE(shipToAddress.City, '') AS ShipCity,
						COALESCE(shipToAddress.PostalCode, '') AS ShipPostalCode,
						C.QuickBooksReferenceId as CustomerQuickBooksReferenceId, 
						SOBI.QuickBooksReferenceId, 
						SOBI.MasterCompanyId,
						SOBI.UpdatedBy,
						@InvModuleName,
						@InvModuleId,
						@ExchModuleId,
						ISNULL(SOBI.SyncToken, '0') AS SyncToken,
						CT.QuickBooksReferenceId,
						P.TaxRateRef,
						P.TxnTaxCodeRef,
						ISNULL(SOBII.UnitPrice, 0),
						ISNULL(SOBII.MiscCharges, 0),
						ISNULL(SOBII.Freight, 0),
						ISNULL(P.PercentValue, 0),
						ISNULL(EBT.Description, ''),
						IM.QuickBooksReferenceId,
						SOBII.ExchangeSalesOrderPartId,
						COALESCE(billToAddress.StateOrProvince, '') AS BillStateOrProvince,
						COALESCE(billToAddress.Country, '') AS BillCountry,
						COALESCE(shipToAddress.StateOrProvince, '') AS ShipStateOrProvince,
						COALESCE(shipToAddress.Country, '') AS ShipCountry,
						'' as [InvoiceNotes]
				FROM [dbo].[ExchangeSalesOrderBillingInvoicingItem] SOBII WITH(NOLOCK) 
					JOIN [dbo].[ExchangeSalesOrderBillingInvoicing] SOBI WITH(NOLOCK) ON SOBI.SOBillingInvoicingId = SOBII.SOBillingInvoicingId
					JOIN [dbo].[Customer] C WITH(NOLOCK) ON C.CustomerId = SOBI.CustomerId
					JOIN [dbo].[ExchangeSalesOrder] SO WITH(NOLOCK) ON SO.ExchangeSalesOrderId= SOBI.ExchangeSalesOrderId AND ISNULL(SO.IsVendor, 0) = 0
					LEFT JOIN [dbo].[ExchangeSalesOrderScheduleBilling] SSBI WITH(NOLOCK) ON SSBI.ExchangeSalesOrderScheduleBillingId = SOBII.ExchangeSalesOrderScheduleBillingId
					LEFT JOIN [dbo].[ExchangeBillingType] EBT WITH(NOLOCK) ON EBT.ExchangeBillingTypeId = SSBI.BillingTypeId
					LEFT JOIN [dbo].[ItemMaster] IM WITH(NOLOCK) ON IM.ItemMasterId= SOBII.ItemMasterId
					--LEFT JOIN [dbo].[CustomerBillingAddress] billToSite WITH(NOLOCK) ON SOBI.BillToSiteId = billToSite.CustomerBillingAddressId
					--LEFT JOIN [dbo].[Address] billToAddress WITH(NOLOCK) ON billToSite.AddressId = billToAddress.AddressId
					--LEFT JOIN [dbo].[CustomerDomensticShipping] shipToSite WITH(NOLOCK) ON SOBI.ShipToSiteId = shipToSite.CustomerDomensticShippingId
					--LEFT JOIN [dbo].[Address] shipToAddress WITH(NOLOCK) ON shipToSite.AddressId = shipToAddress.AddressId
					 AND ISNULL(IM.IsNonStock,0) = 0
					 LEFT JOIN  [dbo].[AllAddress] billToAddress WITH(NOLOCK) ON SOBI.ExchangeSalesOrderId = billToAddress.ReffranceId AND billToAddress.IsShippingAdd = 0 AND billToAddress.[ModuleId] = @ExchModuleId
					LEFT JOIN  [dbo].[AllAddress] shipToAddress WITH(NOLOCK) ON SOBI.ExchangeSalesOrderId = shipToAddress.ReffranceId AND shipToAddress.IsShippingAdd = 1 AND shipToAddress.[ModuleId] = @ExchModuleId
					LEFT JOIN [dbo].[CreditTerms] CT WITH(NOLOCK) ON CT.CreditTermsId = SO.CreditTermId
					LEFT JOIN [dbo].[Percent] P with(nolock) ON P.MasterCompanyId = SOBI.MasterCompanyId AND P.PercentId = SOBI.TaxRate
					--LEFT JOIN [dbo].[Percent] P with(nolock) ON P.MasterCompanyId = SOBI.MasterCompanyId AND P.PercentValue = ((ISNULL(SOBI.SalesTax,0) + ISNULL(SOBI.OtherTax,0))*100 / ISNULL(SOBI.SubTotal,0))
				WHERE	ISNULL(SOBI.QuickBooksReferenceId, 0) != 0 AND ISNULL(SOBI.IsUpdated, 0) = 1 
						AND SOBII.ExchangeSalesOrderPartId = @ReferencePartId AND SOBI.ExchangeSalesOrderId = @ReferenceId;
			END
			ELSE
			BEGIN
				INSERT INTO #InvoiceResults ([InvoiceId], [InvoiceNo], [BillingInvoicingItemId], [CustomerName], [CustomerEmail], [BillLine1], [BillLine2], [BillLine3], [BillCity], [BillPostalCode], [PaymentTerms], [InvoiceDate], 
				[DueDate], [Tags], [Product], [PartNumber], [PartDescription], [Quantity], [SalesTax], [OtherTax], [SalesTaxPercent], [OtherTaxPercent], [TotalTax], [SubTotal], [GrandTotal], [Deposit], [UnitPrice],
				[ShipLine1], [ShipLine2], [ShipLine3], [ShipCity], [ShipPostalCode], [CustomerQuickBooksReferenceId], [QuickBooksReferenceId], [MasterCompanyId], [UpdatedBy], [ModuleName], [ModuleId], [ReferenceModuleId], [SyncToken],
				[TermQuickBooksReferenceId], [TaxRateRef], [TxnTaxCodeRef], [MaterialCost], [MiscCharges], [FreightCost], [PercentValue], [BillingType], [ItemQuickBooksReferenceId], [ExchangeSalesOrderPartId],
				[BillStateOrProvince], [BillCountry], [ShipStateOrProvince], [ShipCountry], [InvoiceNotes])
				SELECT	SOBI.SOBillingInvoicingId,
						SOBI.InvoiceNo,
						SOBII.ExchangeSOBillingInvoicingItemId,
						C.[Name] AS Customer,
						C.Email AS CustomerEmail,
						COALESCE(billToAddress.Line1, '') AS BillLine1,
						COALESCE(billToAddress.Line2, '') AS BillLine2,
						COALESCE(billToAddress.Line3, '') AS BillLine3,
						COALESCE(billToAddress.City, '') AS BillCity,
						COALESCE(billToAddress.PostalCode, '') AS BillPostalCode,
						SO.CreditTermName AS PaymentTerms,
						SOBI.PostedDate AS InvoieDate,
						NULL AS DueDate,
						'' AS Tags,
						'' AS Product,
						IM.partnumber AS PartNumber,
						IM.PartDescription,
						SOBII.NoofPieces AS Quantity,
						ISNULL(SOBI.SalesTax, 0) AS SalesTax,
						ISNULL(SOBI.OtherTax, 0) AS OtherTax,
						CASE WHEN ISNULL(SOBI.SalesTax, 0) = 0 OR ISNULL(SOBI.SubTotal, 0) = 0 THEN 0 ELSE (ISNULL(SOBI.SalesTax, 0) * 100 / ISNULL(SOBI.SubTotal, 0)) END AS SalesTaxPercent,
						CASE WHEN ISNULL(SOBI.OtherTax, 0) = 0 OR ISNULL(SOBI.SubTotal, 0) = 0 THEN 0 ELSE (ISNULL(SOBI.OtherTax, 0) * 100 / ISNULL(SOBI.SubTotal, 0)) END AS OtherTaxPercent,
						(ISNULL(SOBI.OtherTax, 0) + ISNULL(SOBI.SalesTax, 0)) AS TotalTax,
						ISNULL(SOBI.SubTotal, 0) AS SubTotal,
						ISNULL(SOBI.GrandTotal, 0) AS GrandTotal,
						0 AS Deposit,
						ISNULL(SOBII.UnitPrice, 0) AS UnitPrice,
						COALESCE(shipToAddress.Line1, '') AS ShipLine1,
						COALESCE(shipToAddress.Line2, '') AS ShipLine2,
						COALESCE(shipToAddress.Line3, '') AS ShipLine3,
						COALESCE(shipToAddress.City, '') AS ShipCity,
						COALESCE(shipToAddress.PostalCode, '') AS ShipPostalCode,
						C.QuickBooksReferenceId as CustomerQuickBooksReferenceId, 
						SOBI.QuickBooksReferenceId, 
						SOBI.MasterCompanyId,
						SOBI.UpdatedBy,
						@InvModuleName,
						@InvModuleId,
						@ExchModuleId,
						ISNULL(SOBI.SyncToken, '0') AS SyncToken,
						CT.QuickBooksReferenceId,
						P.TaxRateRef,
						P.TxnTaxCodeRef,
						ISNULL(SOBII.UnitPrice, 0),
						ISNULL(SOBII.MiscCharges, 0),
						ISNULL(SOBII.Freight, 0),
						ISNULL(P.PercentValue, 0),
						ISNULL(EBT.Description, ''),
						IM.QuickBooksReferenceId,
						SOBII.ExchangeSalesOrderPartId,
						COALESCE(billToAddress.StateOrProvince, '') AS BillStateOrProvince,
						COALESCE(billToAddress.Country, '') AS BillCountry,
						COALESCE(shipToAddress.StateOrProvince, '') AS ShipStateOrProvince,
						COALESCE(shipToAddress.Country, '') AS ShipCountry,
						'' as [InvoiceNotes]
				FROM [dbo].[ExchangeSalesOrderBillingInvoicingItem] SOBII WITH(NOLOCK) 
					JOIN [dbo].[ExchangeSalesOrderBillingInvoicing] SOBI WITH(NOLOCK) ON SOBI.SOBillingInvoicingId = SOBII.SOBillingInvoicingId
					JOIN [dbo].[Customer] C WITH(NOLOCK) ON C.CustomerId = SOBI.CustomerId
					JOIN [dbo].[ExchangeSalesOrder] SO WITH(NOLOCK) ON SO.ExchangeSalesOrderId= SOBI.ExchangeSalesOrderId AND ISNULL(SO.IsVendor, 0) = 0
					LEFT JOIN [dbo].[ExchangeSalesOrderScheduleBilling] SSBI WITH(NOLOCK) ON SSBI.ExchangeSalesOrderScheduleBillingId = SOBII.ExchangeSalesOrderScheduleBillingId
					LEFT JOIN [dbo].[ExchangeBillingType] EBT WITH(NOLOCK) ON EBT.ExchangeBillingTypeId = SSBI.BillingTypeId
					LEFT JOIN [dbo].[ItemMaster] IM WITH(NOLOCK) ON IM.ItemMasterId= SOBII.ItemMasterId
					--LEFT JOIN [dbo].[CustomerBillingAddress] billToSite WITH(NOLOCK) ON SOBI.BillToSiteId = billToSite.CustomerBillingAddressId
					--LEFT JOIN [dbo].[Address] billToAddress WITH(NOLOCK) ON billToSite.AddressId = billToAddress.AddressId
					--LEFT JOIN [dbo].[CustomerDomensticShipping] shipToSite WITH(NOLOCK) ON SOBI.ShipToSiteId = shipToSite.CustomerDomensticShippingId
					--LEFT JOIN [dbo].[Address] shipToAddress WITH(NOLOCK) ON shipToSite.AddressId = shipToAddress.AddressId
					 AND ISNULL(IM.IsNonStock,0) = 0
					 LEFT JOIN  [dbo].[AllAddress] billToAddress WITH(NOLOCK) ON SOBI.ExchangeSalesOrderId = billToAddress.ReffranceId AND billToAddress.IsShippingAdd = 0 AND billToAddress.[ModuleId] = @ExchModuleId
					LEFT JOIN  [dbo].[AllAddress] shipToAddress WITH(NOLOCK) ON SOBI.ExchangeSalesOrderId = shipToAddress.ReffranceId AND shipToAddress.IsShippingAdd = 1 AND shipToAddress.[ModuleId] = @ExchModuleId
					LEFT JOIN [dbo].[CreditTerms] CT WITH(NOLOCK) ON CT.CreditTermsId = SO.CreditTermId
					LEFT JOIN [dbo].[Percent] P with(nolock) ON P.MasterCompanyId = SOBI.MasterCompanyId AND P.PercentId = SOBI.TaxRate
					--LEFT JOIN [dbo].[Percent] P with(nolock) ON P.MasterCompanyId = SOBI.MasterCompanyId AND P.PercentValue = ((ISNULL(SOBI.SalesTax,0) + ISNULL(SOBI.OtherTax,0))*100 / ISNULL(SOBI.SubTotal,0))
				WHERE	ISNULL(SOBI.QuickBooksReferenceId, 0) != 0 AND ISNULL(SOBI.IsUpdated, 0) = 1 
						AND SOBI.ExchangeSalesOrderId = @ReferenceId;
			END

			--Updating Shipping Details	: Start
			UPDATE TMP
			SET TMP.ShipViaName = shipResult.ShipVia, TMP.ShipDate = shipResult.ShipDate, TMP.TrackingNo = shipResult.AirwayBill
			FROM #InvoiceResults TMP
			OUTER APPLY(
					SELECT SS.ShipDate, SS.AirwayBill, sipVia.[Name] AS ShipVia
					FROM [dbo].[ExchangeSalesOrderShippingItem] SSIM WITH(NOLOCK)
					LEFT JOIN [dbo].[ExchangeSalesOrderShipping] SS WITH(NOLOCK) ON SS.ExchangeSalesOrderShippingId= SSIM.ExchangeSalesOrderShippingId
					LEFT JOIN [dbo].[ShippingVia] AS sipVia WITH(NOLOCK) ON SS.ShipviaId = sipVia.ShippingViaId
					WHERE TMP.ExchangeSalesOrderPartId = SSIM.ExchangeSalesOrderPartId
					GROUP BY SS.ShipDate, SS.AirwayBill, sipVia.[Name]
			) shipResult
			--Updating Shipping Details	: End

			SELECT	[InvoiceId], [InvoiceNo], [BillingInvoicingItemId], [CustomerName], [CustomerEmail], [BillLine1], [BillLine2], [BillLine3], [BillCity], [BillPostalCode], [PaymentTerms], [InvoiceDate], [DueDate], [Tags], [Product],
					--[PartNumber], [PartNumber] + ' - ' + 'Parts Cost' AS [PartDescription],
					[PartNumber], [PartNumber] + ' - ' + [BillingType] AS [PartDescription],
					[Quantity], [SalesTax], [OtherTax], [SalesTaxPercent], [OtherTaxPercent], [TotalTax], [SubTotal], [GrandTotal], [Deposit], [MaterialCost] AS [UnitPrice], 
					[ShipLine1], [ShipLine2], [ShipLine3], [ShipCity], [ShipPostalCode], [CustomerQuickBooksReferenceId], [QuickBooksReferenceId], [MasterCompanyId], [UpdatedBy], [ModuleName], [ModuleId], [ReferenceModuleId],
					[TermQuickBooksReferenceId], [TaxRateRef], [TxnTaxCodeRef], [MaterialCost], [MiscCharges], [FreightCost], [PercentValue], [BillingType], [ItemQuickBooksReferenceId], [ShipViaName], [ShipDate], [TrackingNo],
					[BillStateOrProvince], [BillCountry], [ShipStateOrProvince], [ShipCountry], [InvoiceNotes]
			FROM #InvoiceResults 
			--WHERE MaterialCost > 0 AND (MiscCharges = 0 AND FreightCost = 0)

			--UNION

			--SELECT	[InvoiceId], [InvoiceNo], [BillingInvoicingItemId], [CustomerName], [CustomerEmail], [BillLine1], [BillLine2], [BillLine3], [BillCity], [BillPostalCode], [PaymentTerms], [InvoiceDate], [DueDate], [Tags], [Product],
			--		--[PartNumber], [PartNumber] + ' - ' + 'Misc Charges Cost' AS [PartDescription],
			--		[PartNumber], [PartNumber] + ' - ' + [BillingType] AS [PartDescription],
			--		[Quantity], [SalesTax], [OtherTax], [SalesTaxPercent], [OtherTaxPercent], [TotalTax], [SubTotal], [GrandTotal], [Deposit], [MiscCharges] AS [UnitPrice], 
			--		[ShipLine1], [ShipLine2], [ShipLine3], [ShipCity], [ShipPostalCode], [CustomerQuickBooksReferenceId], [QuickBooksReferenceId], [MasterCompanyId], [UpdatedBy], [ModuleName], [ModuleId], [ReferenceModuleId],
			--		[TermQuickBooksReferenceId], [TaxRateRef], [TxnTaxCodeRef], [MaterialCost], [MiscCharges], [FreightCost], [PercentValue], [BillingType], [ItemQuickBooksReferenceId]
			--FROM #InvoiceResults
			--WHERE MiscCharges > 0

			--UNION

			--SELECT	[InvoiceId], [InvoiceNo], [BillingInvoicingItemId], [CustomerName], [CustomerEmail], [BillLine1], [BillLine2], [BillLine3], [BillCity], [BillPostalCode], [PaymentTerms], [InvoiceDate], [DueDate], [Tags], [Product],
			--		--[PartNumber], [PartNumber] + ' - ' + 'Freight Cost' AS [PartDescription],
			--		[PartNumber], [PartNumber] + ' - ' + [BillingType] AS [PartDescription],
			--		[Quantity], [SalesTax], [OtherTax], [SalesTaxPercent], [OtherTaxPercent], [TotalTax], [SubTotal], [GrandTotal], [Deposit], [FreightCost] AS [UnitPrice], 
			--		[ShipLine1], [ShipLine2], [ShipLine3], [ShipCity], [ShipPostalCode], [CustomerQuickBooksReferenceId], [QuickBooksReferenceId], [MasterCompanyId], [UpdatedBy], [ModuleName], [ModuleId], [ReferenceModuleId],
			--		[TermQuickBooksReferenceId], [TaxRateRef], [TxnTaxCodeRef], [MaterialCost], [MiscCharges], [FreightCost], [PercentValue], [BillingType], [ItemQuickBooksReferenceId]
			--FROM #InvoiceResults
			--WHERE FreightCost > 0
		END
	END TRY    
	BEGIN CATCH      

	         DECLARE @ErrorLogID INT
			,@DatabaseName VARCHAR(100) = db_name()
			-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
			,@AdhocComments VARCHAR(150) = 'QuickBooks_GetUpdatePendingExChangeInvoiceList'
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