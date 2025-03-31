/*************************************************************           
 ** File:   [QuickBooks_GetSyncPendingSOInvoiceList]           
 ** Author:   Devendra Shekh
 ** Description: Get SalesOrder Invoice List to Create Invoice in QuickBooks    
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
	4   20-Feb-2025		Devendra Shekh			Modified (reading Shipping Details)
	5   25-Feb-2025		Devendra Shekh			Modified (Added Missing Address Details for Bill/Ship)
	6   31-Mar-2025		Devendra Shekh			Modified (Added changes for Notes)
     
 EXECUTE [QuickBooks_GetSyncPendingSOInvoiceList] 1, 1, 700
**************************************************************/ 
CREATE   PROCEDURE [dbo].[QuickBooks_GetSyncPendingSOInvoiceList]
	@IntegrationTypeId INT = NULL,
	@MasterCompanyId INT = NULL,
	@ReferenceId BIGINT = NULL,
	@ReferencePartId BIGINT = NULL
AS
BEGIN
	
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED	
	BEGIN TRY

		DECLARE @InvModuleId INT = 0, @SOModuleId INT = 0;
		DECLARE @InvModuleName VARCHAR(200) = '';

		DECLARE @Customer INT = 0
		DECLARE @Vendor INT = 0
		DECLARE @Company INT = 0

		SELECT @Customer = [ModuleId] FROM dbo.Module WITH(NOLOCK) WHERE [ModuleName] = 'Customer';
		SELECT @Vendor = [ModuleId] FROM dbo.Module WITH(NOLOCK) WHERE [ModuleName] = 'Vendor';
		SELECT @Company = [ModuleId] FROM dbo.Module WITH(NOLOCK) WHERE [ModuleName] = 'Company';

		SELECT @InvModuleId = AccountingModuleId, @InvModuleName = AccountingModuleName FROM [dbo].[AccountingModule] WITH(NOLOCK) WHERE UPPER([AccountingModuleName]) = 'INVOICE';
		SELECT @SOModuleId = ModuleId FROM [dbo].[Module] WITH(NOLOCK) WHERE UPPER([ModuleName]) = 'SALESORDER';

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
			[MiscCharges] DECIMAL(13,2) NULL,
			[FreightCost] DECIMAL(13,2) NULL,
			[PercentValue] DECIMAL(13,2) NULL,
			[ItemQuickBooksReferenceId] VARCHAR(200) NULL,
			[SalesOrderPartId] BIGINT NULL, 
			[ShipViaName] VARCHAR(300) NULL,
			[ShipDate] DATETIME2 NULL,
			[TrackingNo] VARCHAR(100) NULL,
			[BillStateOrProvince] VARCHAR(50) NULL,
			[BillCountry] VARCHAR(50) NULL,
			[ShipStateOrProvince] VARCHAR(50) NULL,
			[ShipCountry] VARCHAR(50) NULL,
			[BillToUserType] INT NULL,
			[ShipToUserType] INT NULL,
			[InvoiceNotes] NVARCHAR(MAX) NULL,
		)

		-- FOR QuickBooks
		IF(ISNULL(@IntegrationTypeId, 0) = 1) 
		BEGIN
			--Inserting Sales Order Invoice Data
			IF(ISNULL(@ReferencePartId, 0) > 0)
			BEGIN
				INSERT INTO #InvoiceResults ([InvoiceId], [InvoiceNo], [BillingInvoicingItemId], [CustomerName], [CustomerEmail], [PaymentTerms], [InvoiceDate], [DueDate], [Tags], [Product],
				[PartNumber], [PartDescription], [Quantity], [SalesTax], [OtherTax], [SalesTaxPercent], [OtherTaxPercent], [TotalTax], [SubTotal], [GrandTotal], [Deposit], [UnitPrice], 
				[CustomerQuickBooksReferenceId], [QuickBooksReferenceId], [MasterCompanyId], [UpdatedBy], [ModuleName], [ModuleId], [ReferenceModuleId], [TermQuickBooksReferenceId], [TaxRateRef], [TxnTaxCodeRef],
				[MaterialCost], [MiscCharges], [FreightCost], [PercentValue], [ItemQuickBooksReferenceId], [SalesOrderPartId], [InvoiceNotes])
				SELECT	SOBI.SOBillingInvoicingId,
						SOBI.InvoiceNo,
						SOBII.SOBillingInvoicingItemId,
						C.[Name] AS Customer,
						C.Email AS CustomerEmail,						
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
						ISNULL(SOBI.ProformaDeposit, 0) AS Deposit,
						ISNULL(SOBII.UnitPrice, 0) AS UnitPrice,						
						C.QuickBooksReferenceId as CustomerQuickBooksReferenceId, 
						SOBI.QuickBooksReferenceId, 
						SOBI.MasterCompanyId,
						SOBI.UpdatedBy,
						@InvModuleName,
						@InvModuleId,
						@SOModuleId,
						CT.QuickBooksReferenceId,
						P.TaxRateRef,
						P.TxnTaxCodeRef,
						ISNULL(SPC.NetSaleAmountPerUnit, 0),
						CASE WHEN ISNULL(SOBII.MiscCharges, 0) = 0 THEN ISNULL(SOBI.MiscCharges, 0) ELSE  ISNULL(SOBII.MiscCharges, 0) END,
						CASE WHEN ISNULL(SOBII.Freight, 0) = 0 THEN ISNULL(SOBI.Freight, 0) ELSE  ISNULL(SOBII.Freight, 0) END,
						ISNULL(P.PercentValue, 0),
						IM.QuickBooksReferenceId,
						SOBII.SalesOrderPartId,
						SOBI.Notes
				FROM [dbo].[SalesOrderBillingInvoicingItem] SOBII WITH(NOLOCK) 
					JOIN [dbo].[SalesOrderBillingInvoicing] SOBI WITH(NOLOCK) ON SOBI.SOBillingInvoicingId = SOBII.SOBillingInvoicingId
					JOIN [dbo].[Customer] C WITH(NOLOCK) ON C.CustomerId = SOBI.CustomerId
					JOIN [dbo].[SalesOrder] SO WITH(NOLOCK) ON SO.SalesOrderId= SOBI.SalesOrderId
					LEFT JOIN [dbo].[SalesOrderPartCost] SPC (NOLOCK) ON SPC.SalesOrderPartId= SOBII.SalesOrderPartId
					LEFT JOIN [dbo].[ItemMaster] IM WITH(NOLOCK) ON IM.ItemMasterId= SOBII.ItemMasterId
					--LEFT JOIN [dbo].[CustomerBillingAddress] billToSite WITH(NOLOCK) ON SOBI.BillToSiteId = billToSite.CustomerBillingAddressId
					--LEFT JOIN [dbo].[Address] billToAddress WITH(NOLOCK) ON billToSite.AddressId = billToAddress.AddressId
					--LEFT JOIN [dbo].[CustomerDomensticShipping] shipToSite WITH(NOLOCK) ON SOBI.ShipToSiteId = shipToSite.CustomerDomensticShippingId
					--LEFT JOIN [dbo].[Address] shipToAddress WITH(NOLOCK) ON shipToSite.AddressId = shipToAddress.AddressId
					LEFT JOIN [dbo].[CreditTerms] CT WITH(NOLOCK) ON CT.CreditTermsId = SO.CreditTermId
					LEFT JOIN [dbo].[Percent] P with(nolock) ON P.MasterCompanyId = SOBI.MasterCompanyId AND P.PercentId = SOBII.SalesTaxPercent
					--LEFT JOIN [dbo].[Percent] P with(nolock) ON P.MasterCompanyId = SOBI.MasterCompanyId AND P.PercentValue = ((ISNULL(SOBI.SalesTax,0) + ISNULL(SOBI.OtherTax,0))*100 / ISNULL(SOBI.SubTotal,0))
				WHERE	ISNULL(SOBI.QuickBooksReferenceId, 0) = 0 AND ISNULL(SOBI.IsUpdated, 0) = 1 AND ISNULL(SOBI.IsProforma, 0) = 0 
						AND SOBII.SalesOrderPartId = @ReferencePartId AND SOBI.SalesOrderId = @ReferenceId AND ISNULL(SOBI.IsVersionIncrease, 0) = 0 AND ISNULL(SOBII.IsVersionIncrease, 0) = 0;
			END
			ELSE 
			BEGIN
				INSERT INTO #InvoiceResults ([InvoiceId], [InvoiceNo], [BillingInvoicingItemId], [CustomerName], [CustomerEmail], [PaymentTerms], [InvoiceDate], [DueDate], [Tags], [Product],
				[PartNumber], [PartDescription], [Quantity], [SalesTax], [OtherTax], [SalesTaxPercent], [OtherTaxPercent], [TotalTax], [SubTotal], [GrandTotal], [Deposit], [UnitPrice], 
				[CustomerQuickBooksReferenceId], [QuickBooksReferenceId], [MasterCompanyId], [UpdatedBy], [ModuleName], [ModuleId], [ReferenceModuleId], [TermQuickBooksReferenceId], [TaxRateRef], [TxnTaxCodeRef],
				[MaterialCost], [MiscCharges], [FreightCost], [PercentValue], [ItemQuickBooksReferenceId], [SalesOrderPartId], [InvoiceNotes])
				SELECT	SOBI.SOBillingInvoicingId,
						SOBI.InvoiceNo,
						SOBII.SOBillingInvoicingItemId,
						C.[Name] AS Customer,
						C.Email AS CustomerEmail,						
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
						ISNULL(SOBI.ProformaDeposit, 0) AS Deposit,
						ISNULL(SOBII.UnitPrice, 0) AS UnitPrice,						
						C.QuickBooksReferenceId as CustomerQuickBooksReferenceId, 
						SOBI.QuickBooksReferenceId, 
						SOBI.MasterCompanyId,
						SOBI.UpdatedBy,
						@InvModuleName,
						@InvModuleId,
						@SOModuleId,
						CT.QuickBooksReferenceId,
						P.TaxRateRef,
						P.TxnTaxCodeRef,
						ISNULL(SPC.NetSaleAmountPerUnit, 0),
						CASE WHEN ISNULL(SOBII.MiscCharges, 0) = 0 THEN ISNULL(SOBI.MiscCharges, 0) ELSE  ISNULL(SOBII.MiscCharges, 0) END,
						CASE WHEN ISNULL(SOBII.Freight, 0) = 0 THEN ISNULL(SOBI.Freight, 0) ELSE  ISNULL(SOBII.Freight, 0) END,
						ISNULL(P.PercentValue, 0),
						IM.QuickBooksReferenceId,
						SOBII.SalesOrderPartId,
						SOBI.Notes
				FROM [dbo].[SalesOrderBillingInvoicingItem] SOBII WITH(NOLOCK) 
					JOIN [dbo].[SalesOrderBillingInvoicing] SOBI WITH(NOLOCK) ON SOBI.SOBillingInvoicingId = SOBII.SOBillingInvoicingId
					JOIN [dbo].[Customer] C WITH(NOLOCK) ON C.CustomerId = SOBI.CustomerId
					JOIN [dbo].[SalesOrder] SO WITH(NOLOCK) ON SO.SalesOrderId= SOBI.SalesOrderId
					LEFT JOIN [dbo].[SalesOrderPartCost] SPC (NOLOCK) ON SPC.SalesOrderPartId= SOBII.SalesOrderPartId
					LEFT JOIN [dbo].[ItemMaster] IM WITH(NOLOCK) ON IM.ItemMasterId= SOBII.ItemMasterId
					--LEFT JOIN [dbo].[CustomerBillingAddress] billToSite WITH(NOLOCK) ON SOBI.BillToSiteId = billToSite.CustomerBillingAddressId
					--LEFT JOIN [dbo].[Address] billToAddress WITH(NOLOCK) ON billToSite.AddressId = billToAddress.AddressId
					--LEFT JOIN [dbo].[CustomerDomensticShipping] shipToSite WITH(NOLOCK) ON SOBI.ShipToSiteId = shipToSite.CustomerDomensticShippingId
					--LEFT JOIN [dbo].[Address] shipToAddress WITH(NOLOCK) ON shipToSite.AddressId = shipToAddress.AddressId
					LEFT JOIN [dbo].[CreditTerms] CT WITH(NOLOCK) ON CT.CreditTermsId = SO.CreditTermId
					LEFT JOIN [dbo].[Percent] P with(nolock) ON P.MasterCompanyId = SOBI.MasterCompanyId AND P.PercentId = SOBII.SalesTaxPercent
					--LEFT JOIN [dbo].[Percent] P with(nolock) ON P.MasterCompanyId = SOBI.MasterCompanyId AND P.PercentValue = ((ISNULL(SOBI.SalesTax,0) + ISNULL(SOBI.OtherTax,0))*100 / ISNULL(SOBI.SubTotal,0))
				WHERE	ISNULL(SOBI.QuickBooksReferenceId, 0) = 0 AND ISNULL(SOBI.IsUpdated, 0) = 1 AND ISNULL(SOBI.IsProforma, 0) = 0 
						AND SOBI.SalesOrderId = @ReferenceId AND ISNULL(SOBI.IsVersionIncrease, 0) = 0 AND ISNULL(SOBII.IsVersionIncrease, 0) = 0;
			END

			--Updating Shipping Details	: Start
			UPDATE TMP
			SET TMP.ShipViaName = shipResult.ShipVia, TMP.ShipDate = shipResult.ShipDate, TMP.TrackingNo = shipResult.AirwayBill
			FROM #InvoiceResults TMP
			OUTER APPLY(
					SELECT SS.ShipDate, SS.AirwayBill, sipVia.[Name] AS ShipVia
					FROM [dbo].[SalesOrderShippingItem] SSIM WITH(NOLOCK)
					LEFT JOIN [dbo].[SalesOrderShipping] SS WITH(NOLOCK) ON SS.SalesOrderShippingId= SSIM.SalesOrderShippingId
					LEFT JOIN [dbo].[ShippingVia] AS sipVia WITH(NOLOCK) ON SS.ShipviaId = sipVia.ShippingViaId
					WHERE TMP.SalesOrderPartId = SSIM.SalesOrderPartId
					GROUP BY SS.ShipDate, SS.AirwayBill, sipVia.[Name]
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
				SELECT 
				CASE WHEN BI.BillToUserType = @Customer THEN billToSite.SiteName
					 WHEN BI.BillToUserType = @Vendor THEN billToSiteVendor.SiteName
					 WHEN BI.BillToUserType = @Company THEN billToSiteCompany.SiteName
					 ELSE ''
				END AS BillToSiteName,
				CASE WHEN BI.BillToUserType = @Customer THEN billToAddress.Line1
					 WHEN BI.BillToUserType = @Vendor THEN billToAddressVendor.Line1
					 WHEN BI.BillToUserType = @Company THEN billToAddressCompany.Line1
					 ELSE ''
				END AS BillToAddressLine1,
				CASE WHEN BI.BillToUserType = @Customer THEN billToAddress.Line2
					 WHEN BI.BillToUserType = @Vendor THEN billToAddressVendor.Line2
					 WHEN BI.BillToUserType = @Company THEN billToAddressCompany.Line2
					 ELSE ''
				END AS BillToAddressLine2,
				CASE WHEN BI.BillToUserType = @Customer THEN billToAddress.City
					 WHEN BI.BillToUserType = @Vendor THEN billToAddressVendor.City
					 WHEN BI.BillToUserType = @Company THEN billToAddressCompany.City
					 ELSE ''
				END AS BillToCity,
				CASE WHEN BI.BillToUserType = @Customer THEN billToAddress.StateOrProvince
					 WHEN BI.BillToUserType = @Vendor THEN billToAddressVendor.StateOrProvince
					 WHEN BI.BillToUserType = @Company THEN billToAddressCompany.StateOrProvince
					 ELSE ''
				END AS BillToState,
				CASE WHEN BI.BillToUserType = @Customer THEN billToAddress.PostalCode
					 WHEN BI.BillToUserType = @Vendor THEN billToAddressVendor.PostalCode
					 WHEN BI.BillToUserType = @Company THEN billToAddressCompany.PostalCode
					 ELSE ''
				END AS BillToPostalCode,
				CASE WHEN BI.BillToUserType = @Customer THEN billToCountry.countries_name
					 WHEN BI.BillToUserType = @Vendor THEN billToCountryVendor.countries_name
					 WHEN BI.BillToUserType = @Company THEN billToCountryCompany.countries_name
					 ELSE ''
				END AS BillToCountry,

				CASE WHEN BI.BillToUserType = @Customer THEN billToCustomer.[Name]
					 WHEN BI.BillToUserType = @Vendor THEN billToVendor.VendorName
					 WHEN BI.BillToUserType = @Company THEN billToCompany.CompanyName
					 ELSE ''
				END AS BillToNameOfCustomer,

				CASE WHEN BI.BillToUserType = @Customer THEN billToCustomer.Email
					 WHEN BI.BillToUserType = @Vendor THEN billToVendor.VendorEmail
					 WHEN BI.BillToUserType = @Company THEN ''
					 ELSE ''
				END AS BillToCustomerEmail
				FROM [dbo].[SalesOrderBillingInvoicing] BI WITH(NOLOCK)
				LEFT JOIN  [dbo].[Customer] billToCustomer WITH(NOLOCK) ON BI.BillToCustomerId = billToCustomer.CustomerId
				LEFT JOIN  [dbo].[Vendor] AS billToVendor WITH(NOLOCK) ON BI.BillToCustomerId = billToVendor.VendorId
				LEFT JOIN  [dbo].[LegalEntity] AS billToCompany WITH(NOLOCK) ON BI.BillToCustomerId = billToCompany.LegalEntityId
				LEFT JOIN  [dbo].[CustomerBillingAddress] AS billToSite WITH(NOLOCK) ON BI.BillToSiteId = billToSite.CustomerBillingAddressId
				LEFT JOIN  [dbo].[VendorBillingAddress] AS billToSiteVendor WITH(NOLOCK) ON BI.BillToSiteId = billToSiteVendor.VendorBillingAddressId
				LEFT JOIN  [dbo].[LegalEntityBillingAddress] AS billToSiteCompany WITH(NOLOCK) ON BI.BillToSiteId = billToSiteCompany.LegalEntityBillingAddressId
				LEFT JOIN  [dbo].[Address] AS billToAddress WITH(NOLOCK) ON billToSite.AddressId = billToAddress.AddressId
				LEFT JOIN  [dbo].[Address] AS billToAddressVendor WITH(NOLOCK) ON billToSiteVendor.AddressId = billToAddressVendor.AddressId
				LEFT JOIN  [dbo].[Address] AS billToAddressCompany WITH(NOLOCK) ON billToSiteCompany.AddressId = billToAddressCompany.AddressId
				LEFT JOIN  [dbo].[Countries] AS billToCountry WITH(NOLOCK) ON billToAddress.CountryId = billToCountry.countries_id
				LEFT JOIN  [dbo].[Countries] AS billToCountryVendor WITH(NOLOCK) ON billToAddressVendor.CountryId = billToCountryVendor.countries_id
				LEFT JOIN  [dbo].[Countries] AS billToCountryCompany WITH(NOLOCK) ON billToAddressCompany.CountryId = billToCountryCompany.countries_id
				WHERE BI.SOBillingInvoicingId = TMPAddr.[InvoiceId]
			) InvBillAddr
			OUTER APPLY (
				SELECT 
				CASE WHEN BI.ShipToUserType = @Customer THEN shipToSite.SiteName
					 WHEN BI.ShipToUserType = @Vendor THEN shipToSiteVendor.SiteName
					 WHEN BI.ShipToUserType = @Company THEN shipToSiteCompany.SiteName
					 ELSE ''
				END AS ShipToSiteName,
				CASE WHEN BI.ShipToUserType = @Customer THEN shipToAddress.Line1
					 WHEN BI.ShipToUserType = @Vendor THEN shipToAddressVendor.Line1
					 WHEN BI.ShipToUserType = @Company THEN shipToAddressCompany.Line1
					 ELSE ''
				END AS ShipToAddressLine1,
				CASE WHEN BI.ShipToUserType = @Customer THEN shipToAddress.Line2
					 WHEN BI.ShipToUserType = @Vendor THEN shipToAddressVendor.Line2
					 WHEN BI.ShipToUserType = @Company THEN shipToAddressCompany.Line2
					 ELSE ''
				END AS ShipToAddressLine2,
				CASE WHEN BI.ShipToUserType = @Customer THEN shipToAddress.City
					 WHEN BI.ShipToUserType = @Vendor THEN shipToAddressVendor.City
					 WHEN BI.ShipToUserType = @Company THEN shipToAddressCompany.City
					 ELSE ''
				END AS ShipToCity,
				CASE WHEN BI.ShipToUserType = @Customer THEN shipToAddress.StateOrProvince
					 WHEN BI.ShipToUserType = @Vendor THEN shipToAddressVendor.StateOrProvince
					 WHEN BI.ShipToUserType = @Company THEN shipToAddressCompany.StateOrProvince
					 ELSE ''
				END AS ShipToState,
				CASE WHEN BI.ShipToUserType = @Customer THEN shipToAddress.PostalCode
					 WHEN BI.ShipToUserType = @Vendor THEN shipToAddressVendor.PostalCode
					 WHEN BI.ShipToUserType = @Company THEN shipToAddressCompany.PostalCode
					 ELSE ''
				END AS ShipToPostalCode,
				CASE WHEN BI.ShipToUserType = @Customer THEN shipToCountry.countries_name
					 WHEN BI.ShipToUserType = @Vendor THEN shipToCountryVendor.countries_name
					 WHEN BI.ShipToUserType = @Company THEN shipToCountryCompany.countries_name
					 ELSE ''
				END AS ShipToCountry,

				CASE WHEN BI.ShipToUserType = @Customer THEN shipToCustomer.[Name]
					 WHEN BI.ShipToUserType = @Vendor THEN shipToVendor.VendorName
					 WHEN BI.ShipToUserType = @Company THEN shipToCompany.CompanyName
					 ELSE ''
				END AS ShipToNameOfCustomer,

				CASE WHEN BI.ShipToUserType = @Customer THEN shipToCustomer.Email
					 WHEN BI.ShipToUserType = @Vendor THEN shipToVendor.VendorEmail
					 WHEN BI.ShipToUserType = @Company THEN ''
					 ELSE ''
				END AS ShipToCustomerEmail
				FROM [dbo].[SalesOrderBillingInvoicing] BI WITH(NOLOCK)
				LEFT JOIN  [dbo].[Customer] shipToCustomer WITH(NOLOCK) ON BI.ShipToCustomerId = shipToCustomer.CustomerId
				LEFT JOIN  [dbo].[Vendor] AS shipToVendor WITH(NOLOCK) ON BI.ShipToCustomerId = shipToVendor.VendorId
				LEFT JOIN  [dbo].[LegalEntity] AS shipToCompany WITH(NOLOCK) ON BI.ShipToCustomerId = shipToCompany.LegalEntityId
				LEFT JOIN  [dbo].[CustomerDomensticShipping] AS shipToSite WITH(NOLOCK) ON BI.shipToSiteId = shipToSite.CustomerDomensticShippingId
				LEFT JOIN  [dbo].[VendorShippingAddress] AS shipToSiteVendor WITH(NOLOCK) ON BI.shipToSiteId = shipToSiteVendor.VendorShippingAddressId
				LEFT JOIN  [dbo].[LegalEntityShippingAddress] AS shipToSiteCompany WITH(NOLOCK) ON BI.shipToSiteId = shipToSiteCompany.LegalEntityShippingAddressId
				LEFT JOIN  [dbo].[Address] AS shipToAddress WITH(NOLOCK) ON shipToSite.AddressId = shipToAddress.AddressId
				LEFT JOIN  [dbo].[Address] AS shipToAddressVendor WITH(NOLOCK) ON shipToSiteVendor.AddressId = shipToAddressVendor.AddressId
				LEFT JOIN  [dbo].[Address] AS shipToAddressCompany WITH(NOLOCK) ON shipToSiteCompany.AddressId = shipToAddressCompany.AddressId
				LEFT JOIN  [dbo].[Countries] AS shipToCountry WITH(NOLOCK) ON shipToAddress.CountryId = shipToCountry.countries_id
				LEFT JOIN  [dbo].[Countries] AS shipToCountryVendor WITH(NOLOCK) ON shipToAddressVendor.CountryId = shipToCountryVendor.countries_id
				LEFT JOIN  [dbo].[Countries] AS shipToCountryCompany WITH(NOLOCK) ON shipToAddressCompany.CountryId = shipToCountryCompany.countries_id
				WHERE BI.SOBillingInvoicingId = TMPAddr.[InvoiceId]
			) InvShipAddr
			--Updating Address Details	: End

			SELECT	[InvoiceId], [InvoiceNo], [BillingInvoicingItemId], [CustomerName], [CustomerEmail], [BillLine1], [BillLine2], [BillLine3], [BillCity], [BillPostalCode], [PaymentTerms], [InvoiceDate], [DueDate], [Tags], [Product],
					[PartNumber], [PartNumber] + ' - ' + 'Parts Cost' AS [PartDescription],
					[Quantity], [SalesTax], [OtherTax], [SalesTaxPercent], [OtherTaxPercent], [TotalTax], [SubTotal], [GrandTotal], [Deposit], [MaterialCost] AS [UnitPrice], 
					[ShipLine1], [ShipLine2], [ShipLine3], [ShipCity], [ShipPostalCode], [CustomerQuickBooksReferenceId], [QuickBooksReferenceId], [MasterCompanyId], [UpdatedBy], [ModuleName], [ModuleId], [ReferenceModuleId],
					[TermQuickBooksReferenceId], [TaxRateRef], [TxnTaxCodeRef], [MaterialCost], [MiscCharges], [FreightCost], [PercentValue], [ItemQuickBooksReferenceId], [ShipViaName], [ShipDate], [TrackingNo], [BillStateOrProvince], [BillCountry], [ShipStateOrProvince], [ShipCountry], [InvoiceNotes]
			FROM #InvoiceResults 
			WHERE MaterialCost > 0

			UNION

			SELECT	[InvoiceId], [InvoiceNo], [BillingInvoicingItemId], [CustomerName], [CustomerEmail], [BillLine1], [BillLine2], [BillLine3], [BillCity], [BillPostalCode], [PaymentTerms], [InvoiceDate], [DueDate], [Tags], [Product],
					[PartNumber], [PartNumber] + ' - ' + 'Misc Charges Cost' AS [PartDescription],
					[Quantity], [SalesTax], [OtherTax], [SalesTaxPercent], [OtherTaxPercent], [TotalTax], [SubTotal], [GrandTotal], [Deposit], [MiscCharges] AS [UnitPrice], 
					[ShipLine1], [ShipLine2], [ShipLine3], [ShipCity], [ShipPostalCode], [CustomerQuickBooksReferenceId], [QuickBooksReferenceId], [MasterCompanyId], [UpdatedBy], [ModuleName], [ModuleId], [ReferenceModuleId],
					[TermQuickBooksReferenceId], [TaxRateRef], [TxnTaxCodeRef], [MaterialCost], [MiscCharges], [FreightCost], [PercentValue], [ItemQuickBooksReferenceId], [ShipViaName], [ShipDate], [TrackingNo], [BillStateOrProvince], [BillCountry], [ShipStateOrProvince], [ShipCountry], [InvoiceNotes]
			FROM #InvoiceResults
			WHERE MiscCharges > 0

			UNION

			SELECT	[InvoiceId], [InvoiceNo], [BillingInvoicingItemId], [CustomerName], [CustomerEmail], [BillLine1], [BillLine2], [BillLine3], [BillCity], [BillPostalCode], [PaymentTerms], [InvoiceDate], [DueDate], [Tags], [Product],
					[PartNumber], [PartNumber] + ' - ' + 'Freight Cost' AS [PartDescription],
					[Quantity], [SalesTax], [OtherTax], [SalesTaxPercent], [OtherTaxPercent], [TotalTax], [SubTotal], [GrandTotal], [Deposit], [FreightCost] AS [UnitPrice], 
					[ShipLine1], [ShipLine2], [ShipLine3], [ShipCity], [ShipPostalCode], [CustomerQuickBooksReferenceId], [QuickBooksReferenceId], [MasterCompanyId], [UpdatedBy], [ModuleName], [ModuleId], [ReferenceModuleId],
					[TermQuickBooksReferenceId], [TaxRateRef], [TxnTaxCodeRef], [MaterialCost], [MiscCharges], [FreightCost], [PercentValue], [ItemQuickBooksReferenceId], [ShipViaName], [ShipDate], [TrackingNo], [BillStateOrProvince], [BillCountry], [ShipStateOrProvince], [ShipCountry], [InvoiceNotes]
			FROM #InvoiceResults
			WHERE FreightCost > 0
		END
	END TRY    
	BEGIN CATCH      

	         DECLARE @ErrorLogID INT
			,@DatabaseName VARCHAR(100) = db_name()
			-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
			,@AdhocComments VARCHAR(150) = 'QuickBooks_GetSyncPendingSOInvoiceList'
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