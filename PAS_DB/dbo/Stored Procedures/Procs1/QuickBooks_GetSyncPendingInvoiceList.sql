/*************************************************************           
 ** File:   [QuickBooks_GetSyncPendingInvoiceList]           
 ** Author:   Devendra Shekh
 ** Description: Get Invoice List to Create Invoice in QuickBooks    
 ** Purpose:         
 ** Date:   19-Nov-2024        
         
 ** RETURN VALUE: 
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date			Author					Change Description            
 ** --   --------		-------					--------------------------------          
    1   19-Nov-2024		Devendra Shekh			Created
	2   28-Nov-2024		Devendra Shekh			Modified(Added [CreditTerms] to get TermQuickBooksReferenceId)
	3   03-DEC-2024		Devendra Shekh			Modified(excluding Profoma Invoices)
	4   17-DEC-2024		Devendra Shekh			Modified(added Changes to read TaxRateRef values from Percent table)
	5   03-07-2025      Moin Bloch              Changed Old To New Billing Table
	6    01/July/2026			 RAJESH GAMI						[PN-17008] - Merge Non Stock Inventory to ItemMaster : Get only Stock Inventory Data Where IsNonStock = 0
     
 EXECUTE [QuickBooks_GetSyncPendingInvoiceList] 1
**************************************************************/ 
CREATE   PROCEDURE [dbo].[QuickBooks_GetSyncPendingInvoiceList]
	@IntegrationTypeId INT = NULL
AS
BEGIN
	
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED	
	BEGIN TRY

		DECLARE @InvModuleId INT = 0, @WOModuleId INT = 0, @SOModuleId INT = 0, @ExchModuleId INT = 0;
		DECLARE @InvModuleName VARCHAR(200) = '';

		SELECT @InvModuleId = ModuleId, @InvModuleName = ModuleName FROM [dbo].[Module] WITH(NOLOCK) WHERE [ModuleName] = 'Invoice';
		SELECT @WOModuleId = ModuleId FROM [dbo].[Module] WITH(NOLOCK) WHERE [ModuleName] = 'WorkOrder';
		SELECT @SOModuleId = ModuleId FROM [dbo].[Module] WITH(NOLOCK) WHERE [ModuleName] = 'SalesOrder';
		SELECT @ExchModuleId = ModuleId FROM [dbo].[Module] WITH(NOLOCK) WHERE [ModuleName] = 'ExchangeSalesOrder';

		IF OBJECT_ID('tempdb..#InvoiceResults') IS NOT NULL
			DROP TABLE #InvoiceResults

		CREATE TABLE #InvoiceResults
		(
			[Id] BIGINT IDENTITY(1,1) NOT NULL,
			[InvoiceId] BIGINT NULL,
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
		)

		-- FOR QuickBooks
		IF(ISNULL(@IntegrationTypeId, 0) = 1) 
		BEGIN
			--Inserting Work Order Invoice Data
			INSERT INTO #InvoiceResults ([InvoiceId], [BillingInvoicingItemId], [CustomerName], [CustomerEmail], [BillLine1], [BillLine2], [BillLine3], [BillCity], [BillPostalCode], [PaymentTerms], [InvoiceDate], 
			[DueDate], [Tags], [Product], [PartNumber], [PartDescription], [Quantity], [SalesTax], [OtherTax], [SalesTaxPercent], [OtherTaxPercent], [TotalTax], [SubTotal], [GrandTotal], [Deposit], [UnitPrice], 
			[ShipLine1], [ShipLine2], [ShipLine3], [ShipCity], [ShipPostalCode], [CustomerQuickBooksReferenceId], [QuickBooksReferenceId], [MasterCompanyId], [UpdatedBy], [ModuleName], [ModuleId], [ReferenceModuleId],
			[TermQuickBooksReferenceId], [TaxRateRef], [TxnTaxCodeRef])
			SELECT	WOBI.BillingInvoicingId,
					WOBII.BillingInvoicingItemId,
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
					P.TxnTaxCodeRef
			FROM [dbo].[BillingInvoicingItems] WOBII WITH(NOLOCK) 
				JOIN [dbo].[BillingInvoicing] WOBI WITH(NOLOCK) ON WOBI.BillingInvoicingId = WOBII.BillingInvoicingId
				JOIN [dbo].[BillingInvoicingDetails] SOBD WITH(NOLOCK) ON WOBI.BillingInvoicingId = SOBD.BillingInvoicingId
				JOIN [dbo].[Customer] C WITH(NOLOCK) ON C.CustomerId = WOBI.CustomerId
				JOIN [dbo].[WorkOrder] WO WITH(NOLOCK) ON WO.WorkOrderId= WOBI.ReferenceId
				LEFT JOIN [dbo].[ItemMaster] IM WITH(NOLOCK) ON IM.ItemMasterId= WOBII.ItemMasterId
				 AND ISNULL(IM.IsNonStock,0) = 0 LEFT JOIN [dbo].[CustomerBillingAddress] billToSite WITH(NOLOCK) ON SOBD.SoldToSiteId = billToSite.CustomerBillingAddressId
				LEFT JOIN [dbo].[Address] billToAddress WITH(NOLOCK) ON billToSite.AddressId = billToAddress.AddressId
				LEFT JOIN [dbo].[CustomerDomensticShipping] shipToSite WITH(NOLOCK) ON SOBD.ShipToSiteId = shipToSite.CustomerDomensticShippingId
				LEFT JOIN [dbo].[Address] shipToAddress WITH(NOLOCK) ON shipToSite.AddressId = shipToAddress.AddressId
				LEFT JOIN [dbo].[CreditTerms] CT WITH(NOLOCK) ON CT.CreditTermsId = WO.CreditTermId
				LEFT JOIN [dbo].[Percent] P with(nolock) ON P.MasterCompanyId = WOBI.MasterCompanyId AND P.PercentId = WOBII.SalesTaxPercent
				--LEFT JOIN [dbo].[Percent] P with(nolock) ON P.MasterCompanyId = WOBI.MasterCompanyId AND P.PercentValue = ((ISNULL(WOBI.SalesTax,0) + ISNULL(WOBI.OtherTax,0))*100 / ISNULL(WOBI.SubTotal,0))
			WHERE ISNULL(WOBI.QuickBooksReferenceId, 0) = 0 AND WOBI.[ModuleId] = @WOModuleId AND ISNULL(WOBI.IsUpdated, 0) = 1 AND ISNULL(WOBI.IsPerformaInvoice, 0) = 0 
			--)

			--Inserting Sales Order Invoice Data
			INSERT INTO #InvoiceResults ([InvoiceId], [BillingInvoicingItemId], [CustomerName], [CustomerEmail], [BillLine1], [BillLine2], [BillLine3], [BillCity], [BillPostalCode], [PaymentTerms], [InvoiceDate], 
			[DueDate], [Tags], [Product], [PartNumber], [PartDescription], [Quantity], [SalesTax], [OtherTax], [SalesTaxPercent], [OtherTaxPercent], [TotalTax], [SubTotal], [GrandTotal], [Deposit], [UnitPrice], 
			[ShipLine1], [ShipLine2], [ShipLine3], [ShipCity], [ShipPostalCode], [CustomerQuickBooksReferenceId], [QuickBooksReferenceId], [MasterCompanyId], [UpdatedBy], [ModuleName], [ModuleId], [ReferenceModuleId],
			[TermQuickBooksReferenceId], [TaxRateRef], [TxnTaxCodeRef])
			SELECT	SOBI.BillingInvoicingId,
					SOBII.BillingInvoicingItemId,
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
					SOBII.QtyBilled AS Quantity,
					ISNULL(SOBI.SalesTax, 0) AS SalesTax,
					ISNULL(SOBI.OtherTax, 0) AS OtherTax,
					CASE WHEN ISNULL(SOBI.SalesTax, 0) = 0 OR ISNULL(SOBI.SubTotal, 0) = 0 THEN 0 ELSE (ISNULL(SOBI.SalesTax, 0) * 100 / ISNULL(SOBI.SubTotal, 0)) END AS SalesTaxPercent,
					CASE WHEN ISNULL(SOBI.OtherTax, 0) = 0 OR ISNULL(SOBI.SubTotal, 0) = 0 THEN 0 ELSE (ISNULL(SOBI.OtherTax, 0) * 100 / ISNULL(SOBI.SubTotal, 0)) END AS OtherTaxPercent,
					(ISNULL(SOBI.OtherTax, 0) + ISNULL(SOBI.SalesTax, 0)) AS TotalTax,
					ISNULL(SOBI.SubTotal, 0) AS SubTotal,
					ISNULL(SOBI.GrandTotal, 0) AS GrandTotal,
					ISNULL(SOBI.ProformaDeposit, 0) AS Deposit,
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
					@SOModuleId,
					CT.QuickBooksReferenceId,
					P.TaxRateRef,
					P.TxnTaxCodeRef
			FROM [dbo].[BillingInvoicingItems] SOBII WITH(NOLOCK) 
				JOIN [dbo].[BillingInvoicing] SOBI WITH(NOLOCK) ON SOBI.BillingInvoicingId = SOBII.BillingInvoicingId
				JOIN [dbo].[BillingInvoicingDetails] SOBD WITH(NOLOCK) ON SOBI.BillingInvoicingId = SOBD.BillingInvoicingId
				JOIN [dbo].[Customer] C WITH(NOLOCK) ON C.CustomerId = SOBI.CustomerId
				JOIN [dbo].[SalesOrder] SO WITH(NOLOCK) ON SO.SalesOrderId= SOBI.ReferenceId
				LEFT JOIN [dbo].[ItemMaster] IM WITH(NOLOCK) ON IM.ItemMasterId= SOBII.ItemMasterId
				 AND ISNULL(IM.IsNonStock,0) = 0 LEFT JOIN [dbo].[CustomerBillingAddress] billToSite WITH(NOLOCK) ON SOBD.SoldToSiteId = billToSite.CustomerBillingAddressId
				LEFT JOIN [dbo].[Address] billToAddress WITH(NOLOCK) ON billToSite.AddressId = billToAddress.AddressId
				LEFT JOIN [dbo].[CustomerDomensticShipping] shipToSite WITH(NOLOCK) ON SOBD.ShipToSiteId = shipToSite.CustomerDomensticShippingId
				LEFT JOIN [dbo].[Address] shipToAddress WITH(NOLOCK) ON shipToSite.AddressId = shipToAddress.AddressId
				LEFT JOIN [dbo].[CreditTerms] CT WITH(NOLOCK) ON CT.CreditTermsId = SO.CreditTermId
				LEFT JOIN [dbo].[Percent] P with(nolock) ON P.MasterCompanyId = SOBI.MasterCompanyId AND P.PercentId = SOBII.SalesTaxPercent
				--LEFT JOIN [dbo].[Percent] P with(nolock) ON P.MasterCompanyId = SOBI.MasterCompanyId AND P.PercentValue = ((ISNULL(SOBI.SalesTax,0) + ISNULL(SOBI.OtherTax,0))*100 / ISNULL(SOBI.SubTotal,0))
			WHERE ISNULL(SOBI.QuickBooksReferenceId, 0) = 0 AND SOBI.[ModuleId] = @SOModuleId AND ISNULL(SOBI.IsUpdated, 0) = 1 AND ISNULL(SOBI.IsPerformaInvoice, 0) = 0 

			--Inserting Exchange Sales Order Invoice Data
			INSERT INTO #InvoiceResults ([InvoiceId], [BillingInvoicingItemId], [CustomerName], [CustomerEmail], [BillLine1], [BillLine2], [BillLine3], [BillCity], [BillPostalCode], [PaymentTerms], [InvoiceDate], 
			[DueDate], [Tags], [Product], [PartNumber], [PartDescription], [Quantity], [SalesTax], [OtherTax], [SalesTaxPercent], [OtherTaxPercent], [TotalTax], [SubTotal], [GrandTotal], [Deposit], [UnitPrice], 
			[ShipLine1], [ShipLine2], [ShipLine3], [ShipCity], [ShipPostalCode], [CustomerQuickBooksReferenceId], [QuickBooksReferenceId], [MasterCompanyId], [UpdatedBy], [ModuleName], [ModuleId], [ReferenceModuleId],
			[TermQuickBooksReferenceId], [TaxRateRef], [TxnTaxCodeRef])
			SELECT	SOBI.SOBillingInvoicingId,
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
					CT.QuickBooksReferenceId,
					P.TaxRateRef,
					P.TxnTaxCodeRef
			FROM [dbo].[ExchangeSalesOrderBillingInvoicingItem] SOBII WITH(NOLOCK) 
				JOIN [dbo].[ExchangeSalesOrderBillingInvoicing] SOBI WITH(NOLOCK) ON SOBI.SOBillingInvoicingId = SOBII.SOBillingInvoicingId
				JOIN [dbo].[Customer] C WITH(NOLOCK) ON C.CustomerId = SOBI.CustomerId
				JOIN [dbo].[ExchangeSalesOrder] SO WITH(NOLOCK) ON SO.ExchangeSalesOrderId= SOBI.ExchangeSalesOrderId AND ISNULL(SO.IsVendor, 0) = 0
				LEFT JOIN [dbo].[ItemMaster] IM WITH(NOLOCK) ON IM.ItemMasterId= SOBII.ItemMasterId
				 AND ISNULL(IM.IsNonStock,0) = 0 LEFT JOIN [dbo].[CustomerBillingAddress] billToSite WITH(NOLOCK) ON SOBI.BillToSiteId = billToSite.CustomerBillingAddressId
				LEFT JOIN [dbo].[Address] billToAddress WITH(NOLOCK) ON billToSite.AddressId = billToAddress.AddressId
				LEFT JOIN [dbo].[CustomerDomensticShipping] shipToSite WITH(NOLOCK) ON SOBI.ShipToSiteId = shipToSite.CustomerDomensticShippingId
				LEFT JOIN [dbo].[Address] shipToAddress WITH(NOLOCK) ON shipToSite.AddressId = shipToAddress.AddressId
				LEFT JOIN [dbo].[CreditTerms] CT WITH(NOLOCK) ON CT.CreditTermsId = SO.CreditTermId
				LEFT JOIN [dbo].[Percent] P with(nolock) ON P.MasterCompanyId = SOBI.MasterCompanyId AND P.PercentId = SOBI.TaxRate
				--LEFT JOIN [dbo].[Percent] P with(nolock) ON P.MasterCompanyId = SOBI.MasterCompanyId AND P.PercentValue = ((ISNULL(SOBI.SalesTax,0) + ISNULL(SOBI.OtherTax,0))*100 / ISNULL(SOBI.SubTotal,0))
			WHERE ISNULL(SOBI.QuickBooksReferenceId, 0) = 0 AND ISNULL(SOBI.IsUpdated, 0) = 1 

			SELECT * FROM #InvoiceResults
		END
	END TRY    
	BEGIN CATCH      

	         DECLARE @ErrorLogID INT
			,@DatabaseName VARCHAR(100) = db_name()
			-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
			,@AdhocComments VARCHAR(150) = 'QuickBooks_GetSyncPendingInvoiceList'
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