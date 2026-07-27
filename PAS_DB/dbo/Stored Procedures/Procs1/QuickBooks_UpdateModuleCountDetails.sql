
-- ---------------------------------------------------------------------------------------------------
-- Stored Procedure: dbo.QuickBooks_UpdateModuleCountDetails   (source: PAS_DB/dbo/Stored Procedures/Procs1/QuickBooks_UpdateModuleCountDetails.sql)
-- ---------------------------------------------------------------------------------------------------
/*************************************************************           
 ** File:   [QuickBooks_UpdateModuleCountDetails]           
 ** Author:   Abhishek Jirawla
 ** Description: Update Module Count Details
 ** Purpose:         
 ** Date:   05-Mar-2025  
         
 ** RETURN VALUE: 
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date			Author			Change Description            
 ** --   --------		-------			--------------------------------          
    1    05-Mar-2025   Abhishek Jirawla	Created
	2	 27-Mar-2025   Abhishek Jirawla Adding proper DB standards
	3	 19-Jun-2025   Moin Bloch       Replaced Old To New Table For Billing Invoicing
    4    21-Apr-2026   Moin Bloch       Modified Added Xero Accounting Changes PN-16008
	5    05-06-2026    Bhargav Saliya   Added Xero Case For Credit Memo
	6    01/July/2026			 RAJESH GAMI						[PN-17008] - Merge Non Stock Inventory to ItemMaster : Get only Stock Inventory Data Where IsNonStock = 0
	7    23/July/2026			 RAJESH GAMI						[PN-17350] - Removed 6 leftover IsNonStock=0 exclusion filters.
     
 EXECUTE [QuickBooks_UpdateModuleCountDetails] 1, 1
**************************************************************/ 
CREATE        PROCEDURE [dbo].[QuickBooks_UpdateModuleCountDetails]
	@MasterCompanyId INT = NULL,
	@ModuleId BIGINT = NULL
AS
BEGIN

	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED	
	BEGIN TRY

		DECLARE @CustomerModuleId INT, @VendorModuleId INT, @StocklineModuleId INT, @InvModuleId INT, @CPModuleId INT, @CreditTermsModuleId INT, @GLAccountModuleId INT, @BillModuleId INT, @BillPaymentModuleId INT, @ItemMasterModuleId INT, @CreditMemoModuleId INT, @PurchaseOrderModuleId INT,@VendorCreditMemoModuleId INT;		
		DECLARE @QBIntegrationTypeId INT=1,@NSIntegrationTypeId INT=2,@XeroIntegrationTypeId INT=3
		DECLARE @WOModuleId BIGINT, @SOModuleId BIGINT, @ExchModuleId BIGINT;

		SELECT @CustomerModuleId = [AccountingModuleId] FROM dbo.[AccountingModule] WITH(NOLOCK) WHERE UPPER([AccountingModuleName]) = 'CUSTOMER';
		SELECT @VendorModuleId = [AccountingModuleId] FROM dbo.[AccountingModule] WITH(NOLOCK) WHERE UPPER([AccountingModuleName]) = 'VENDOR';
		SELECT @StocklineModuleId = [AccountingModuleId] FROM dbo.[AccountingModule] WITH(NOLOCK) WHERE [AccountingModuleName] = 'STOCKLINE';
		SELECT @InvModuleId = [AccountingModuleId] FROM dbo.[AccountingModule] WITH(NOLOCK) WHERE UPPER([AccountingModuleName]) = 'INVOICE';
		SELECT @CPModuleId = [AccountingModuleId] FROM dbo.[AccountingModule] WITH(NOLOCK) WHERE UPPER([AccountingModuleName]) = 'CUSTOMERPAYMENT';
		SELECT @CreditTermsModuleId = [AccountingModuleId] FROM dbo.[AccountingModule] WITH(NOLOCK) WHERE UPPER([AccountingModuleName]) = 'CREDITTERM';
		SELECT @GLAccountModuleId = [AccountingModuleId] FROM dbo.[AccountingModule] WITH(NOLOCK) WHERE UPPER([AccountingModuleName]) = 'GLACCOUNT';
		SELECT @BillModuleId = [AccountingModuleId] FROM dbo.[AccountingModule] WITH(NOLOCK) WHERE UPPER([AccountingModuleName]) = 'BILL';
		SELECT @BillPaymentModuleId = [AccountingModuleId] FROM dbo.[AccountingModule] WITH(NOLOCK) WHERE UPPER([AccountingModuleName]) = 'BILLPAYMENT';
		SELECT @ItemMasterModuleId = [AccountingModuleId] FROM dbo.[AccountingModule] WITH(NOLOCK) WHERE UPPER([AccountingModuleName]) = 'ITEMMASTER';
		SELECT @CreditMemoModuleId = [AccountingModuleId] FROM dbo.[AccountingModule] WITH(NOLOCK) WHERE UPPER([AccountingModuleName]) = 'CREDITMEMO';
		SELECT @PurchaseOrderModuleId = [AccountingModuleId] FROM dbo.[AccountingModule] WITH(NOLOCK) WHERE UPPER([AccountingModuleName]) = 'PURCHASEORDER';
		SELECT @VendorCreditMemoModuleId = [AccountingModuleId] FROM dbo.[AccountingModule] WITH(NOLOCK) WHERE UPPER([AccountingModuleName]) = 'VENDORCREDITMEMO'

		SELECT @WOModuleId = ModuleId FROM [dbo].[Module] WITH(NOLOCK) WHERE UPPER([ModuleName]) = 'WORKORDER';
		SELECT @SOModuleId = ModuleId FROM [dbo].[Module] WITH(NOLOCK) WHERE UPPER([ModuleName]) = 'SALESORDER';
		SELECT @ExchModuleId = ModuleId FROM [dbo].[Module] WITH(NOLOCK) WHERE UPPER([ModuleName]) = 'EXCHANGESALESORDER';

		SELECT @QBIntegrationTypeId = [IntegrationTypeId] FROM [dbo].[AccountingIntegrationType] WITH(NOLOCK) WHERE [IntegrationType] = 'QuickBooks';
		SELECT @NSIntegrationTypeId = [IntegrationTypeId] FROM [dbo].[AccountingIntegrationType] WITH(NOLOCK) WHERE [IntegrationType] = 'NetSuite';
		SELECT @XeroIntegrationTypeId = [IntegrationTypeId] FROM [dbo].[AccountingIntegrationType] WITH(NOLOCK) WHERE [IntegrationType] = 'Xero';

		IF @ModuleId = @CustomerModuleId
		BEGIN
			--------------------------------- QuickBooks ---------------------------------
			UPDATE ACI
			SET 
				SyncRecords = ISNULL(CustomerData.CustomerCount, 0),
				PendingSyncRecords = ISNULL(PendingCustomerData.CustomerCount, 0),
				TotalRecords = ISNULL(AllCustomerData.CustomerCount, 0)
			FROM dbo.AccountingIntegrationSettings ACI
			-- Customer Data
			LEFT JOIN (
				SELECT MasterCompanyId, COUNT(QuickBooksReferenceId) AS CustomerCount
				FROM dbo.Customer  WITH(NOLOCK)
				WHERE ISNULL(IsActive, 0) = 1 AND ISNULL(IsDeleted, 0) = 0 AND ISNULL(QuickBooksReferenceId, '') <> '' AND [IntegrationTypeId] = @QBIntegrationTypeId
				GROUP BY MasterCompanyId
			) AS CustomerData ON CustomerData.MasterCompanyId = ACI.MasterCompanyId AND ACI.ModuleId = @CustomerModuleId

			-- Pending Customer Data
			LEFT JOIN (
				SELECT MasterCompanyId, COUNT(IsUpdated) AS CustomerCount
				FROM dbo.Customer WITH(NOLOCK) 
				WHERE ISNULL(IsActive, 0) = 1 AND ISNULL(IsDeleted, 0) = 0 AND ISNULL(IsUpdated, 0) = 1 AND [IntegrationTypeId] = @QBIntegrationTypeId
				GROUP BY MasterCompanyId
			) AS PendingCustomerData ON PendingCustomerData.MasterCompanyId = ACI.MasterCompanyId AND ACI.ModuleId = @CustomerModuleId

			-- All Customer Data
			LEFT JOIN (
				SELECT MasterCompanyId, COUNT(CustomerId) AS CustomerCount
				FROM dbo.Customer  WITH(NOLOCK)
				WHERE ISNULL(IsActive, 0) = 1 AND ISNULL(IsDeleted, 0) = 0 AND [IntegrationTypeId] = @QBIntegrationTypeId
				GROUP BY MasterCompanyId
			) AS AllCustomerData ON AllCustomerData.MasterCompanyId = ACI.MasterCompanyId AND ACI.ModuleId = @CustomerModuleId
			WHERE ACI.ModuleId = @CustomerModuleId

			--------------------------------- Xero Accounting ---------------------------------

			UPDATE ACI
			SET 
				SyncRecords = ISNULL(CustomerData.CustomerCount, 0),
				PendingSyncRecords = ISNULL(PendingCustomerData.CustomerCount, 0),
				TotalRecords = ISNULL(AllCustomerData.CustomerCount, 0)
			FROM dbo.AccountingIntegrationSettings ACI
			-- Customer Data
			LEFT JOIN (
				SELECT MasterCompanyId, COUNT(QuickBooksReferenceId) AS CustomerCount
				FROM dbo.Customer  WITH(NOLOCK)
				WHERE ISNULL(IsActive, 0) = 1 AND ISNULL(IsDeleted, 0) = 0 AND ISNULL(QuickBooksReferenceId, '') <> '' AND [IntegrationTypeId] = @XeroIntegrationTypeId
				GROUP BY MasterCompanyId
			) AS CustomerData ON CustomerData.MasterCompanyId = ACI.MasterCompanyId AND ACI.ModuleId = @CustomerModuleId

			-- Pending Customer Data
			LEFT JOIN (
				SELECT MasterCompanyId, COUNT(IsUpdated) AS CustomerCount
				FROM dbo.Customer WITH(NOLOCK) 
				WHERE ISNULL(IsActive, 0) = 1 AND ISNULL(IsDeleted, 0) = 0 AND ISNULL(IsUpdated, 0) = 1 AND [IntegrationTypeId] = @XeroIntegrationTypeId
				GROUP BY MasterCompanyId
			) AS PendingCustomerData ON PendingCustomerData.MasterCompanyId = ACI.MasterCompanyId AND ACI.ModuleId = @CustomerModuleId

			-- All Customer Data
			LEFT JOIN (
				SELECT MasterCompanyId, COUNT(CustomerId) AS CustomerCount
				FROM dbo.Customer  WITH(NOLOCK)
				WHERE ISNULL(IsActive, 0) = 1 AND ISNULL(IsDeleted, 0) = 0 AND [IntegrationTypeId] = @XeroIntegrationTypeId
				GROUP BY MasterCompanyId
			) AS AllCustomerData ON AllCustomerData.MasterCompanyId = ACI.MasterCompanyId AND ACI.ModuleId = @CustomerModuleId
			WHERE ACI.ModuleId = @CustomerModuleId

		END

		---------------Vendor Insert

		IF @ModuleId = @VendorModuleId
		BEGIN
			--------------------------------- QuickBooks ---------------------------------

			UPDATE ACI
			SET 
				SyncRecords = ISNULL(VendorData.VendorCount, 0),
				PendingSyncRecords = ISNULL(PendingVendorData.VendorCount, 0),
				TotalRecords = ISNULL(AllVendorData.VendorCount, 0)
			FROM dbo.AccountingIntegrationSettings ACI

			-- Vendor Data
			LEFT JOIN (
				SELECT MasterCompanyId, COUNT(QuickBooksReferenceId) AS VendorCount
				FROM dbo.Vendor WITH(NOLOCK) 
				WHERE ISNULL(IsActive, 0) = 1 AND ISNULL(IsDeleted, 0) = 0 AND ISNULL([QuickBooksReferenceId], '') <> '' AND [IntegrationTypeId] = @QBIntegrationTypeId
				GROUP BY MasterCompanyId
			) AS VendorData ON VendorData.MasterCompanyId = ACI.MasterCompanyId AND ACI.ModuleId = @VendorModuleId

			-- Pending Vendor Data
			LEFT JOIN (
				SELECT MasterCompanyId, COUNT(IsUpdated) AS VendorCount
				FROM dbo.Vendor  WITH(NOLOCK)
				WHERE ISNULL(IsActive, 0) = 1 AND ISNULL(IsDeleted, 0) = 0 AND ISNULL(IsUpdated, 0) = 1 AND [IntegrationTypeId] = @QBIntegrationTypeId
				GROUP BY MasterCompanyId
			) AS PendingVendorData ON PendingVendorData.MasterCompanyId = ACI.MasterCompanyId AND ACI.ModuleId = @VendorModuleId

			-- All Vendor Data
			LEFT JOIN (
				SELECT MasterCompanyId, COUNT(VendorId) AS VendorCount
				FROM dbo.Vendor  WITH(NOLOCK)
				WHERE ISNULL(IsActive, 0) = 1 AND ISNULL(IsDeleted, 0) = 0 AND [IntegrationTypeId] = @QBIntegrationTypeId
				GROUP BY MasterCompanyId
			) AS AllVendorData ON AllVendorData.MasterCompanyId = ACI.MasterCompanyId AND ACI.ModuleId = @VendorModuleId
			WHERE ACI.ModuleId = @VendorModuleId

			--------------------------------- Xero Accounting ---------------------------------

			UPDATE ACI
			SET 
				SyncRecords = ISNULL(VendorData.VendorCount, 0),
				PendingSyncRecords = ISNULL(PendingVendorData.VendorCount, 0),
				TotalRecords = ISNULL(AllVendorData.VendorCount, 0)
			FROM dbo.AccountingIntegrationSettings ACI

			-- Vendor Data
			LEFT JOIN (
				SELECT MasterCompanyId, COUNT(QuickBooksReferenceId) AS VendorCount
				FROM dbo.Vendor WITH(NOLOCK) 
				WHERE ISNULL(IsActive, 0) = 1 AND ISNULL(IsDeleted, 0) = 0 AND ISNULL([QuickBooksReferenceId], '') <> '' AND [IntegrationTypeId] = @XeroIntegrationTypeId
				GROUP BY MasterCompanyId
			) AS VendorData ON VendorData.MasterCompanyId = ACI.MasterCompanyId AND ACI.ModuleId = @VendorModuleId

			-- Pending Vendor Data
			LEFT JOIN (
				SELECT MasterCompanyId, COUNT(IsUpdated) AS VendorCount
				FROM dbo.Vendor  WITH(NOLOCK)
				WHERE ISNULL(IsActive, 0) = 1 AND ISNULL(IsDeleted, 0) = 0 AND ISNULL(IsUpdated, 0) = 1 AND [IntegrationTypeId] = @XeroIntegrationTypeId
				GROUP BY MasterCompanyId
			) AS PendingVendorData ON PendingVendorData.MasterCompanyId = ACI.MasterCompanyId AND ACI.ModuleId = @VendorModuleId

			-- All Vendor Data
			LEFT JOIN (
				SELECT MasterCompanyId, COUNT(VendorId) AS VendorCount
				FROM dbo.Vendor  WITH(NOLOCK)
				WHERE ISNULL(IsActive, 0) = 1 AND ISNULL(IsDeleted, 0) = 0 AND [IntegrationTypeId] = @XeroIntegrationTypeId
				GROUP BY MasterCompanyId
			) AS AllVendorData ON AllVendorData.MasterCompanyId = ACI.MasterCompanyId AND ACI.ModuleId = @VendorModuleId
			WHERE ACI.ModuleId = @VendorModuleId

		END

		---------------Stockline Insert

		IF @ModuleId = @StocklineModuleId
		BEGIN
			UPDATE ACI
			SET 
				SyncRecords = ISNULL(StocklineData.StocklineCount, 0),
				PendingSyncRecords = ISNULL(PendingStocklineData.StocklineCount, 0),
				TotalRecords = ISNULL(AllStocklineData.StocklineCount, 0)
			FROM dbo.AccountingIntegrationSettings ACI

			-- Stockline Data
			LEFT JOIN (
				SELECT MasterCompanyId, COUNT(QuickBooksReferenceId) AS StocklineCount
				FROM dbo.Stockline  WITH(NOLOCK)
				WHERE ISNULL(IsActive, 0) = 1 AND ISNULL(IsDeleted, 0) = 0 AND ISNULL(QuickBooksReferenceId, 0) > 0
				GROUP BY MasterCompanyId
			) AS StocklineData ON StocklineData.MasterCompanyId = ACI.MasterCompanyId AND ACI.ModuleId = @StocklineModuleId

			-- Pending Stockline Data
			LEFT JOIN (
				SELECT MasterCompanyId, COUNT(IsUpdated) AS StocklineCount
				FROM dbo.Stockline  WITH(NOLOCK)
				WHERE ISNULL(IsActive, 0) = 1 AND ISNULL(IsDeleted, 0) = 0 AND ISNULL(IsUpdated, 0) = 1
				GROUP BY MasterCompanyId
			) AS PendingStocklineData ON PendingStocklineData.MasterCompanyId = ACI.MasterCompanyId AND ACI.ModuleId = @StocklineModuleId

			-- All Stockline Data
			LEFT JOIN (
				SELECT MasterCompanyId, COUNT(StocklineId) AS StocklineCount
				FROM dbo.Stockline  WITH(NOLOCK)
				WHERE ISNULL(IsActive, 0) = 1 AND ISNULL(IsDeleted, 0) = 0
				GROUP BY MasterCompanyId
			) AS AllStocklineData ON AllStocklineData.MasterCompanyId = ACI.MasterCompanyId AND ACI.ModuleId = @StocklineModuleId
			WHERE ACI.ModuleId = @StocklineModuleId
		END

		---------------NonPOInvoice Insert

		IF @ModuleId = @BillModuleId
		BEGIN
			--------------------------------- QuickBooks ---------------------------------
			UPDATE ACI
			SET 
				SyncRecords = ISNULL(NonPOInvoiceData.NonPOInvoiceCount, 0),
				PendingSyncRecords = ISNULL(PendingNonPOInvoiceData.NonPOInvoiceCount, 0),
				TotalRecords = ISNULL(AllNonPOInvoiceData.NonPOInvoiceCount, 0)
			FROM dbo.AccountingIntegrationSettings ACI

			-- NonPOInvoice Data
			LEFT JOIN (
				SELECT MasterCompanyId, COUNT(QuickBooksReferenceId) AS NonPOInvoiceCount
				FROM dbo.NonPOInvoiceHeader  WITH(NOLOCK)
				WHERE ISNULL(IsActive, 0) = 1 AND ISNULL(IsDeleted, 0) = 0 AND ISNULL(QuickBooksReferenceId, '') <> '' AND [IntegrationTypeId] = @QBIntegrationTypeId
				GROUP BY MasterCompanyId
			) AS NonPOInvoiceData ON NonPOInvoiceData.MasterCompanyId = ACI.MasterCompanyId AND ACI.ModuleId = @BillModuleId

			-- Pending NonPOInvoice Data
			LEFT JOIN (
				SELECT MasterCompanyId, COUNT(IsUpdated) AS NonPOInvoiceCount
				FROM dbo.NonPOInvoiceHeader  WITH(NOLOCK)
				WHERE ISNULL(IsActive, 0) = 1 AND ISNULL(IsDeleted, 0) = 0 AND ISNULL(IsUpdated, 0) = 1 AND [IntegrationTypeId] = @QBIntegrationTypeId
				GROUP BY MasterCompanyId
			) AS PendingNonPOInvoiceData ON PendingNonPOInvoiceData.MasterCompanyId = ACI.MasterCompanyId AND ACI.ModuleId = @BillModuleId

			-- All NonPOInvoice Data
			LEFT JOIN (
				SELECT MasterCompanyId, COUNT(NonPOInvoiceId) AS NonPOInvoiceCount
				FROM dbo.NonPOInvoiceHeader  WITH(NOLOCK)
				WHERE ISNULL(IsActive, 0) = 1 AND ISNULL(IsDeleted, 0) = 0 AND [IntegrationTypeId] = @QBIntegrationTypeId
				GROUP BY MasterCompanyId
			) AS AllNonPOInvoiceData ON AllNonPOInvoiceData.MasterCompanyId = ACI.MasterCompanyId AND ACI.ModuleId = @BillModuleId
			WHERE ACI.ModuleId = @BillModuleId
			
			--------------------------------- Xero Accounting ---------------------------------
			UPDATE ACI
			SET 
				SyncRecords = ISNULL(NonPOInvoiceData.NonPOInvoiceCount, 0),
				PendingSyncRecords = ISNULL(PendingNonPOInvoiceData.NonPOInvoiceCount, 0),
				TotalRecords = ISNULL(AllNonPOInvoiceData.NonPOInvoiceCount, 0)
			FROM dbo.AccountingIntegrationSettings ACI

			-- NonPOInvoice Data
			LEFT JOIN (
				SELECT MasterCompanyId, COUNT(QuickBooksReferenceId) AS NonPOInvoiceCount
				FROM dbo.NonPOInvoiceHeader  WITH(NOLOCK)
				WHERE ISNULL(IsActive, 0) = 1 AND ISNULL(IsDeleted, 0) = 0 AND ISNULL(QuickBooksReferenceId, '') <> '' AND [IntegrationTypeId] = @XeroIntegrationTypeId
				GROUP BY MasterCompanyId
			) AS NonPOInvoiceData ON NonPOInvoiceData.MasterCompanyId = ACI.MasterCompanyId AND ACI.ModuleId = @BillModuleId

			-- Pending NonPOInvoice Data
			LEFT JOIN (
				SELECT MasterCompanyId, COUNT(IsUpdated) AS NonPOInvoiceCount
				FROM dbo.NonPOInvoiceHeader  WITH(NOLOCK)
				WHERE ISNULL(IsActive, 0) = 1 AND ISNULL(IsDeleted, 0) = 0 AND ISNULL(IsUpdated, 0) = 1 AND [IntegrationTypeId] = @XeroIntegrationTypeId
				GROUP BY MasterCompanyId
			) AS PendingNonPOInvoiceData ON PendingNonPOInvoiceData.MasterCompanyId = ACI.MasterCompanyId AND ACI.ModuleId = @BillModuleId

			-- All NonPOInvoice Data
			LEFT JOIN (
				SELECT MasterCompanyId, COUNT(NonPOInvoiceId) AS NonPOInvoiceCount
				FROM dbo.NonPOInvoiceHeader  WITH(NOLOCK)
				WHERE ISNULL(IsActive, 0) = 1 AND ISNULL(IsDeleted, 0) = 0 AND [IntegrationTypeId] = @XeroIntegrationTypeId
				GROUP BY MasterCompanyId
			) AS AllNonPOInvoiceData ON AllNonPOInvoiceData.MasterCompanyId = ACI.MasterCompanyId AND ACI.ModuleId = @BillModuleId
			WHERE ACI.ModuleId = @BillModuleId

		END

		---------------CreditTerms Insert

		IF @ModuleId = @CreditTermsModuleId
		BEGIN
			UPDATE ACI
			SET 
				SyncRecords = ISNULL(CreditTermsData.CreditTermsCount, 0),
				PendingSyncRecords = ISNULL(PendingCreditTermsData.CreditTermsCount, 0),
				TotalRecords = ISNULL(AllCreditTermsData.CreditTermsCount, 0)
			FROM dbo.AccountingIntegrationSettings ACI

			-- CreditTerms Data
			LEFT JOIN (
				SELECT MasterCompanyId, COUNT(QuickBooksReferenceId) AS CreditTermsCount
				FROM dbo.CreditTerms  WITH(NOLOCK)
				WHERE ISNULL(IsActive, 0) = 1 AND ISNULL(IsDeleted, 0) = 0 AND ISNULL(QuickBooksReferenceId, 0) > 0
				GROUP BY MasterCompanyId
			) AS CreditTermsData ON CreditTermsData.MasterCompanyId = ACI.MasterCompanyId AND ACI.ModuleId = @CreditTermsModuleId

			-- Pending CreditTerms Data
			LEFT JOIN (
				SELECT MasterCompanyId, COUNT(IsUpdated) AS CreditTermsCount
				FROM dbo.CreditTerms  WITH(NOLOCK)
				WHERE ISNULL(IsActive, 0) = 1 AND ISNULL(IsDeleted, 0) = 0 AND ISNULL(IsUpdated, 0) = 1
				GROUP BY MasterCompanyId
			) AS PendingCreditTermsData ON PendingCreditTermsData.MasterCompanyId = ACI.MasterCompanyId AND ACI.ModuleId = @CreditTermsModuleId

			-- All CreditTerms Data
			LEFT JOIN (
				SELECT MasterCompanyId, COUNT(CreditTermsId) AS CreditTermsCount
				FROM dbo.CreditTerms  WITH(NOLOCK)
				WHERE ISNULL(IsActive, 0) = 1 AND ISNULL(IsDeleted, 0) = 0
				GROUP BY MasterCompanyId
			) AS AllCreditTermsData ON AllCreditTermsData.MasterCompanyId = ACI.MasterCompanyId AND ACI.ModuleId = @CreditTermsModuleId
			WHERE ACI.ModuleId = @CreditTermsModuleId
		END

		---------------GLAccount Insert

		IF @ModuleId = @GLAccountModuleId
		BEGIN
			--------------------------------- QuickBooks ---------------------------------
			UPDATE ACI
			SET 
				SyncRecords = ISNULL(GLAccountData.GLAccountCount, 0),
				PendingSyncRecords = ISNULL(PendingGLAccountData.GLAccountCount, 0),
				TotalRecords = ISNULL(AllGLAccountData.GLAccountCount, 0)
			FROM dbo.AccountingIntegrationSettings ACI

			-- GLAccount Data
			LEFT JOIN (
				SELECT MasterCompanyId, COUNT(QuickBooksReferenceId) AS GLAccountCount
				FROM dbo.GLAccount  WITH(NOLOCK)
				WHERE ISNULL(IsActive, 0) = 1 AND ISNULL(IsDeleted, 0) = 0 AND ISNULL(QuickBooksReferenceId, '') <> '' AND [IntegrationTypeId] = @QBIntegrationTypeId
				GROUP BY MasterCompanyId
			) AS GLAccountData ON GLAccountData.MasterCompanyId = ACI.MasterCompanyId AND ACI.ModuleId = @GLAccountModuleId

			-- Pending GLAccount Data
			LEFT JOIN (
				SELECT MasterCompanyId, COUNT(IsUpdated) AS GLAccountCount
				FROM dbo.GLAccount  WITH(NOLOCK)
				WHERE ISNULL(IsActive, 0) = 1 AND ISNULL(IsDeleted, 0) = 0 AND ISNULL(IsUpdated, 0) = 1 AND [IntegrationTypeId] = @QBIntegrationTypeId
				GROUP BY MasterCompanyId
			) AS PendingGLAccountData ON PendingGLAccountData.MasterCompanyId = ACI.MasterCompanyId AND ACI.ModuleId = @GLAccountModuleId

			-- All GLAccount Data
			LEFT JOIN (
				SELECT MasterCompanyId, COUNT(GLAccountId) AS GLAccountCount
				FROM dbo.GLAccount  WITH(NOLOCK)
				WHERE ISNULL(IsActive, 0) = 1 AND ISNULL(IsDeleted, 0) = 0 AND [IntegrationTypeId] = @QBIntegrationTypeId
				GROUP BY MasterCompanyId
			) AS AllGLAccountData ON AllGLAccountData.MasterCompanyId = ACI.MasterCompanyId AND ACI.ModuleId = @GLAccountModuleId
			WHERE ACI.ModuleId = @GLAccountModuleId

			--------------------------------- Xero Accounting ---------------------------------

			UPDATE ACI
			SET 
				SyncRecords = ISNULL(GLAccountData.GLAccountCount, 0),
				PendingSyncRecords = ISNULL(PendingGLAccountData.GLAccountCount, 0),
				TotalRecords = ISNULL(AllGLAccountData.GLAccountCount, 0)
			FROM dbo.AccountingIntegrationSettings ACI

			-- GLAccount Data
			LEFT JOIN (
				SELECT MasterCompanyId, COUNT(QuickBooksReferenceId) AS GLAccountCount
				FROM dbo.GLAccount  WITH(NOLOCK)
				WHERE ISNULL(IsActive, 0) = 1 AND ISNULL(IsDeleted, 0) = 0 AND ISNULL(QuickBooksReferenceId, '') <> '' AND [IntegrationTypeId] = @XeroIntegrationTypeId
				GROUP BY MasterCompanyId
			) AS GLAccountData ON GLAccountData.MasterCompanyId = ACI.MasterCompanyId AND ACI.ModuleId = @GLAccountModuleId

			-- Pending GLAccount Data
			LEFT JOIN (
				SELECT MasterCompanyId, COUNT(IsUpdated) AS GLAccountCount
				FROM dbo.GLAccount  WITH(NOLOCK)
				WHERE ISNULL(IsActive, 0) = 1 AND ISNULL(IsDeleted, 0) = 0 AND ISNULL(IsUpdated, 0) = 1 AND [IntegrationTypeId] = @XeroIntegrationTypeId
				GROUP BY MasterCompanyId
			) AS PendingGLAccountData ON PendingGLAccountData.MasterCompanyId = ACI.MasterCompanyId AND ACI.ModuleId = @GLAccountModuleId

			-- All GLAccount Data
			LEFT JOIN (
				SELECT MasterCompanyId, COUNT(GLAccountId) AS GLAccountCount
				FROM dbo.GLAccount  WITH(NOLOCK)
				WHERE ISNULL(IsActive, 0) = 1 AND ISNULL(IsDeleted, 0) = 0 AND [IntegrationTypeId] = @XeroIntegrationTypeId
				GROUP BY MasterCompanyId
			) AS AllGLAccountData ON AllGLAccountData.MasterCompanyId = ACI.MasterCompanyId AND ACI.ModuleId = @GLAccountModuleId
			WHERE ACI.ModuleId = @GLAccountModuleId

		END

		---------------CreditMemo Insert

		IF @ModuleId = @CreditMemoModuleId
		BEGIN
			UPDATE ACI
			SET 
				SyncRecords = ISNULL(CreditMemoData.CreditMemoCount, 0),
				PendingSyncRecords = ISNULL(PendingCreditMemoData.CreditMemoCount, 0),
				TotalRecords = ISNULL(AllCreditMemoData.CreditMemoCount, 0)
			FROM dbo.AccountingIntegrationSettings ACI

			-- CreditMemo Data
			LEFT JOIN (
				SELECT MasterCompanyId, COUNT(QuickBooksReferenceId) AS CreditMemoCount
				FROM dbo.CreditMemo  WITH(NOLOCK)
				WHERE ISNULL(IsActive, 0) = 1 AND ISNULL(IsDeleted, 0) = 0 AND ISNULL(QuickBooksReferenceId, '') <> '' AND [IntegrationTypeId] = @QBIntegrationTypeId
				GROUP BY MasterCompanyId
			) AS CreditMemoData ON CreditMemoData.MasterCompanyId = ACI.MasterCompanyId AND ACI.ModuleId = @CreditMemoModuleId

			-- Pending CreditMemo Data
			LEFT JOIN (
				SELECT MasterCompanyId, COUNT(IsUpdated) AS CreditMemoCount
				FROM dbo.CreditMemo  WITH(NOLOCK)
				WHERE ISNULL(IsActive, 0) = 1 AND ISNULL(IsDeleted, 0) = 0 AND ISNULL(IsUpdated, 0) = 1 AND [IntegrationTypeId] = @QBIntegrationTypeId
				GROUP BY MasterCompanyId
			) AS PendingCreditMemoData ON PendingCreditMemoData.MasterCompanyId = ACI.MasterCompanyId AND ACI.ModuleId = @CreditMemoModuleId

			-- All CreditMemo Data
			LEFT JOIN (
				SELECT MasterCompanyId, COUNT(CreditMemoHeaderId) AS CreditMemoCount
				FROM dbo.CreditMemo  WITH(NOLOCK)
				WHERE ISNULL(IsActive, 0) = 1 AND ISNULL(IsDeleted, 0) = 0 AND [IntegrationTypeId] = @QBIntegrationTypeId
				GROUP BY MasterCompanyId
			) AS AllCreditMemoData ON AllCreditMemoData.MasterCompanyId = ACI.MasterCompanyId AND ACI.ModuleId = @CreditMemoModuleId
			WHERE ACI.ModuleId = @CreditMemoModuleId

			--------------------------------- Xero Accounting ---------------------------------
			UPDATE ACI
			SET 
				SyncRecords        = ISNULL(CreditMemoData.CreditMemoCount, 0),
				PendingSyncRecords = ISNULL(PendingCreditMemoData.CreditMemoCount, 0),
				TotalRecords       = ISNULL(AllCreditMemoData.CreditMemoCount, 0)
			FROM dbo.AccountingIntegrationSettings ACI

			-- Synced CreditMemo Data
			LEFT JOIN (
				SELECT MasterCompanyId, COUNT(QuickBooksReferenceId) AS CreditMemoCount
				FROM dbo.CreditMemo WITH(NOLOCK)
				WHERE ISNULL(IsActive, 0) = 1 
				  AND ISNULL(IsDeleted, 0) = 0 
				  AND ISNULL(QuickBooksReferenceId, '') <> ''
				  AND [IntegrationTypeId] = @XeroIntegrationTypeId
				GROUP BY MasterCompanyId
			) AS CreditMemoData ON CreditMemoData.MasterCompanyId = ACI.MasterCompanyId 
				AND ACI.ModuleId = @CreditMemoModuleId

			-- Pending CreditMemo Data
			LEFT JOIN (
				SELECT MasterCompanyId, COUNT(IsUpdated) AS CreditMemoCount
				FROM dbo.CreditMemo WITH(NOLOCK)
				WHERE ISNULL(IsActive, 0) = 1 
				  AND ISNULL(IsDeleted, 0) = 0 
				  AND ISNULL(IsUpdated, 0) = 1
				  AND [IntegrationTypeId] = @XeroIntegrationTypeId
				GROUP BY MasterCompanyId
			) AS PendingCreditMemoData ON PendingCreditMemoData.MasterCompanyId = ACI.MasterCompanyId 
				AND ACI.ModuleId = @CreditMemoModuleId

			-- All CreditMemo Data
			LEFT JOIN (
				SELECT MasterCompanyId, COUNT(CreditMemoHeaderId) AS CreditMemoCount
				FROM dbo.CreditMemo WITH(NOLOCK)
				WHERE ISNULL(IsActive, 0) = 1 
				  AND ISNULL(IsDeleted, 0) = 0
				  AND [IntegrationTypeId] = @XeroIntegrationTypeId
				GROUP BY MasterCompanyId
			) AS AllCreditMemoData ON AllCreditMemoData.MasterCompanyId = ACI.MasterCompanyId 
				AND ACI.ModuleId = @CreditMemoModuleId

			WHERE ACI.ModuleId = @CreditMemoModuleId
		END

		---------------ItemMaster Insert

		IF @ModuleId = @ItemMasterModuleId
		BEGIN
			--------------------------------- QuickBooks ---------------------------------
			UPDATE ACI
			SET 
				SyncRecords = ISNULL(ItemMasterData.ItemMasterCount, 0),
				PendingSyncRecords = ISNULL(PendingItemMasterData.ItemMasterCount, 0),
				TotalRecords = ISNULL(AllItemMasterData.ItemMasterCount, 0)
			FROM dbo.AccountingIntegrationSettings ACI

			-- ItemMaster Data
			LEFT JOIN (
				SELECT MasterCompanyId, COUNT(QuickBooksReferenceId) AS ItemMasterCount
				FROM dbo.ItemMaster  WITH(NOLOCK)
				WHERE ISNULL(IsActive, 0) = 1 AND ISNULL(IsDeleted, 0) = 0 AND ISNULL(QuickBooksReferenceId, '') <> '' AND [IntegrationTypeId] = @QBIntegrationTypeId
				 GROUP BY MasterCompanyId
			) AS ItemMasterData ON ItemMasterData.MasterCompanyId = ACI.MasterCompanyId AND ACI.ModuleId = @ItemMasterModuleId

			-- Pending ItemMaster Data
			LEFT JOIN (
				SELECT MasterCompanyId, COUNT(IsUpdated) AS ItemMasterCount
				FROM dbo.ItemMaster  WITH(NOLOCK)
				WHERE ISNULL(IsActive, 0) = 1 AND ISNULL(IsDeleted, 0) = 0 AND ISNULL(IsUpdated, 0) = 1 AND [IntegrationTypeId] = @QBIntegrationTypeId
				 GROUP BY MasterCompanyId
			) AS PendingItemMasterData ON PendingItemMasterData.MasterCompanyId = ACI.MasterCompanyId AND ACI.ModuleId = @ItemMasterModuleId

			-- All ItemMaster Data
			LEFT JOIN (
				SELECT MasterCompanyId, COUNT(ItemMasterId) AS ItemMasterCount
				FROM dbo.ItemMaster  WITH(NOLOCK)
				WHERE ISNULL(IsActive, 0) = 1 AND ISNULL(IsDeleted, 0) = 0 AND [IntegrationTypeId] = @QBIntegrationTypeId
				 GROUP BY MasterCompanyId
			) AS AllItemMasterData ON AllItemMasterData.MasterCompanyId = ACI.MasterCompanyId AND ACI.ModuleId = @ItemMasterModuleId
			WHERE ACI.ModuleId = @ItemMasterModuleId

			--------------------------------- Xero Accounting ---------------------------------

			UPDATE ACI
			SET 
				SyncRecords = ISNULL(ItemMasterData.ItemMasterCount, 0),
				PendingSyncRecords = ISNULL(PendingItemMasterData.ItemMasterCount, 0),
				TotalRecords = ISNULL(AllItemMasterData.ItemMasterCount, 0)
			FROM dbo.AccountingIntegrationSettings ACI

			-- ItemMaster Data
			LEFT JOIN (
				SELECT MasterCompanyId, COUNT(QuickBooksReferenceId) AS ItemMasterCount
				FROM dbo.ItemMaster  WITH(NOLOCK)
				WHERE ISNULL(IsActive, 0) = 1 AND ISNULL(IsDeleted, 0) = 0 AND ISNULL(QuickBooksReferenceId, '') <> '' AND [IntegrationTypeId] = @XeroIntegrationTypeId
				 GROUP BY MasterCompanyId
			) AS ItemMasterData ON ItemMasterData.MasterCompanyId = ACI.MasterCompanyId AND ACI.ModuleId = @ItemMasterModuleId

			-- Pending ItemMaster Data
			LEFT JOIN (
				SELECT MasterCompanyId, COUNT(IsUpdated) AS ItemMasterCount
				FROM dbo.ItemMaster  WITH(NOLOCK)
				WHERE ISNULL(IsActive, 0) = 1 AND ISNULL(IsDeleted, 0) = 0 AND ISNULL(IsUpdated, 0) = 1 AND [IntegrationTypeId] = @XeroIntegrationTypeId
				 GROUP BY MasterCompanyId
			) AS PendingItemMasterData ON PendingItemMasterData.MasterCompanyId = ACI.MasterCompanyId AND ACI.ModuleId = @ItemMasterModuleId

			-- All ItemMaster Data
			LEFT JOIN (
				SELECT MasterCompanyId, COUNT(ItemMasterId) AS ItemMasterCount
				FROM dbo.ItemMaster  WITH(NOLOCK)
				WHERE ISNULL(IsActive, 0) = 1 AND ISNULL(IsDeleted, 0) = 0 AND [IntegrationTypeId] = @XeroIntegrationTypeId
				 GROUP BY MasterCompanyId
			) AS AllItemMasterData ON AllItemMasterData.MasterCompanyId = ACI.MasterCompanyId AND ACI.ModuleId = @ItemMasterModuleId
			WHERE ACI.ModuleId = @ItemMasterModuleId

		END

		---------------PurchaseOrder Insert

		IF @ModuleId = @PurchaseOrderModuleId
		BEGIN
			UPDATE ACI
			SET 
				SyncRecords = ISNULL(PurchaseOrderData.PurchaseOrderCount, 0) + ISNULL(RepairOrderData.RepairOrderCount, 0),
				PendingSyncRecords = ISNULL(PendingPurchaseOrderData.PurchaseOrderCount, 0) + ISNULL(PendingRepairOrderData.RepairOrderCount, 0),
				TotalRecords = ISNULL(AllPurchaseOrderData.PurchaseOrderCount, 0) + ISNULL(AllRepairOrderData.RepairOrderCount, 0)
			FROM dbo.AccountingIntegrationSettings ACI

			-- PurchaseOrder Data
			LEFT JOIN (
				SELECT MasterCompanyId, COUNT(QuickBooksReferenceId) AS PurchaseOrderCount
				FROM dbo.PurchaseOrder  WITH(NOLOCK)
				WHERE ISNULL(IsActive, 0) = 1 AND ISNULL(IsDeleted, 0) = 0 AND ISNULL(QuickBooksReferenceId, '') <> ''  AND [IntegrationTypeId] = @QBIntegrationTypeId
				GROUP BY MasterCompanyId
			) AS PurchaseOrderData ON PurchaseOrderData.MasterCompanyId = ACI.MasterCompanyId AND ACI.ModuleId = @PurchaseOrderModuleId

			-- Pending PurchaseOrder Data
			LEFT JOIN (
				SELECT MasterCompanyId, COUNT(IsUpdated) AS PurchaseOrderCount
				FROM dbo.PurchaseOrder  WITH(NOLOCK)
				WHERE ISNULL(IsActive, 0) = 1 AND ISNULL(IsDeleted, 0) = 0 AND ISNULL(IsUpdated, 0) = 1 AND [IntegrationTypeId] = @QBIntegrationTypeId
				GROUP BY MasterCompanyId
			) AS PendingPurchaseOrderData ON PendingPurchaseOrderData.MasterCompanyId = ACI.MasterCompanyId AND ACI.ModuleId = @PurchaseOrderModuleId

			-- All PurchaseOrder Data
			LEFT JOIN (
				SELECT MasterCompanyId, COUNT(PurchaseOrderId) AS PurchaseOrderCount
				FROM dbo.PurchaseOrder  WITH(NOLOCK)
				WHERE ISNULL(IsActive, 0) = 1 AND ISNULL(IsDeleted, 0) = 0 AND [IntegrationTypeId] = @QBIntegrationTypeId
				GROUP BY MasterCompanyId
			) AS AllPurchaseOrderData ON AllPurchaseOrderData.MasterCompanyId = ACI.MasterCompanyId AND ACI.ModuleId = @PurchaseOrderModuleId

			-- RepairOrder Data
			LEFT JOIN (
				SELECT MasterCompanyId, COUNT(QuickBooksReferenceId) AS RepairOrderCount
				FROM dbo.RepairOrder  WITH(NOLOCK)
				WHERE ISNULL(IsActive, 0) = 1 AND ISNULL(IsDeleted, 0) = 0 AND ISNULL(QuickBooksReferenceId, '') <> '' AND [IntegrationTypeId] = @QBIntegrationTypeId
				GROUP BY MasterCompanyId
			) AS RepairOrderData ON RepairOrderData.MasterCompanyId = ACI.MasterCompanyId AND ACI.ModuleId = @PurchaseOrderModuleId

			-- Pending RepairOrder Data
			LEFT JOIN (
				SELECT MasterCompanyId, COUNT(IsUpdated) AS RepairOrderCount
				FROM dbo.RepairOrder  WITH(NOLOCK) 
				WHERE ISNULL(IsActive, 0) = 1 AND ISNULL(IsDeleted, 0) = 0 AND ISNULL(IsUpdated, 0) = 1 AND [IntegrationTypeId] = @QBIntegrationTypeId
				GROUP BY MasterCompanyId
			) AS PendingRepairOrderData ON PendingRepairOrderData.MasterCompanyId = ACI.MasterCompanyId AND ACI.ModuleId = @PurchaseOrderModuleId

			-- All RepairOrder Data
			LEFT JOIN (
				SELECT MasterCompanyId, COUNT(RepairOrderId) AS RepairOrderCount
				FROM dbo.RepairOrder  WITH(NOLOCK)
				WHERE ISNULL(IsActive, 0) = 1 AND ISNULL(IsDeleted, 0) = 0 AND [IntegrationTypeId] = @QBIntegrationTypeId
				GROUP BY MasterCompanyId
			) AS AllRepairOrderData ON AllRepairOrderData.MasterCompanyId = ACI.MasterCompanyId AND ACI.ModuleId = @PurchaseOrderModuleId

			WHERE ACI.ModuleId = @PurchaseOrderModuleId

			--------------------------------- Xero Accounting Purchase Order---------------------------------
			UPDATE ACI
			SET 
				SyncRecords = ISNULL(PurchaseOrderData.PurchaseOrderCount, 0) + ISNULL(RepairOrderData.RepairOrderCount, 0),
				PendingSyncRecords = ISNULL(PendingPurchaseOrderData.PurchaseOrderCount, 0) + ISNULL(PendingRepairOrderData.RepairOrderCount, 0),
				TotalRecords = ISNULL(AllPurchaseOrderData.PurchaseOrderCount, 0) + ISNULL(AllRepairOrderData.RepairOrderCount, 0)
			FROM dbo.AccountingIntegrationSettings ACI

			-- PurchaseOrder Data
			LEFT JOIN (
				SELECT MasterCompanyId, COUNT(QuickBooksReferenceId) AS PurchaseOrderCount
				FROM dbo.PurchaseOrder  WITH(NOLOCK)
				WHERE ISNULL(IsActive, 0) = 1 AND ISNULL(IsDeleted, 0) = 0 AND ISNULL(QuickBooksReferenceId, '') <> ''  AND [IntegrationTypeId] = @XeroIntegrationTypeId
				GROUP BY MasterCompanyId
			) AS PurchaseOrderData ON PurchaseOrderData.MasterCompanyId = ACI.MasterCompanyId AND ACI.ModuleId = @PurchaseOrderModuleId

			-- Pending PurchaseOrder Data
			LEFT JOIN (
				SELECT MasterCompanyId, COUNT(IsUpdated) AS PurchaseOrderCount
				FROM dbo.PurchaseOrder  WITH(NOLOCK)
				WHERE ISNULL(IsActive, 0) = 1 AND ISNULL(IsDeleted, 0) = 0 AND ISNULL(IsUpdated, 0) = 1 AND [IntegrationTypeId] = @XeroIntegrationTypeId
				GROUP BY MasterCompanyId
			) AS PendingPurchaseOrderData ON PendingPurchaseOrderData.MasterCompanyId = ACI.MasterCompanyId AND ACI.ModuleId = @PurchaseOrderModuleId

			-- All PurchaseOrder Data
			LEFT JOIN (
				SELECT MasterCompanyId, COUNT(PurchaseOrderId) AS PurchaseOrderCount
				FROM dbo.PurchaseOrder  WITH(NOLOCK)
				WHERE ISNULL(IsActive, 0) = 1 AND ISNULL(IsDeleted, 0) = 0 AND [IntegrationTypeId] = @XeroIntegrationTypeId
				GROUP BY MasterCompanyId
			) AS AllPurchaseOrderData ON AllPurchaseOrderData.MasterCompanyId = ACI.MasterCompanyId AND ACI.ModuleId = @PurchaseOrderModuleId

			-- RepairOrder Data
			LEFT JOIN (
				SELECT MasterCompanyId, COUNT(QuickBooksReferenceId) AS RepairOrderCount
				FROM dbo.RepairOrder  WITH(NOLOCK)
				WHERE ISNULL(IsActive, 0) = 1 AND ISNULL(IsDeleted, 0) = 0 AND ISNULL(QuickBooksReferenceId, '') <> '' AND [IntegrationTypeId] = @XeroIntegrationTypeId
				GROUP BY MasterCompanyId
			) AS RepairOrderData ON RepairOrderData.MasterCompanyId = ACI.MasterCompanyId AND ACI.ModuleId = @PurchaseOrderModuleId

			-- Pending RepairOrder Data
			LEFT JOIN (
				SELECT MasterCompanyId, COUNT(IsUpdated) AS RepairOrderCount
				FROM dbo.RepairOrder  WITH(NOLOCK) 
				WHERE ISNULL(IsActive, 0) = 1 AND ISNULL(IsDeleted, 0) = 0 AND ISNULL(IsUpdated, 0) = 1 AND [IntegrationTypeId] = @XeroIntegrationTypeId
				GROUP BY MasterCompanyId
			) AS PendingRepairOrderData ON PendingRepairOrderData.MasterCompanyId = ACI.MasterCompanyId AND ACI.ModuleId = @PurchaseOrderModuleId

			-- All RepairOrder Data
			LEFT JOIN (
				SELECT MasterCompanyId, COUNT(RepairOrderId) AS RepairOrderCount
				FROM dbo.RepairOrder  WITH(NOLOCK)
				WHERE ISNULL(IsActive, 0) = 1 AND ISNULL(IsDeleted, 0) = 0 AND [IntegrationTypeId] = @XeroIntegrationTypeId
				GROUP BY MasterCompanyId
			) AS AllRepairOrderData ON AllRepairOrderData.MasterCompanyId = ACI.MasterCompanyId AND ACI.ModuleId = @PurchaseOrderModuleId

			WHERE ACI.ModuleId = @PurchaseOrderModuleId

		END

		---------------CustomerPaymentDetails Insert

		IF @ModuleId = @CPModuleId
		BEGIN
			UPDATE ACI
			SET 
				SyncRecords = ISNULL(CustomerPaymentDetailsData.CustomerPaymentDetailsCount, 0),
				PendingSyncRecords = ISNULL(PendingCustomerPaymentDetailsData.CustomerPaymentDetailsCount, 0),
				TotalRecords = ISNULL(AllCustomerPaymentDetailsData.CustomerPaymentDetailsCount, 0)
			FROM dbo.AccountingIntegrationSettings ACI

			-- CustomerPaymentDetails Data
			LEFT JOIN (
				SELECT MasterCompanyId, COUNT(QuickBooksReferenceId) AS CustomerPaymentDetailsCount
				FROM dbo.CustomerPaymentDetails  WITH(NOLOCK)
				WHERE ISNULL(IsActive, 0) = 1 AND ISNULL(IsDeleted, 0) = 0 AND ISNULL(QuickBooksReferenceId, '') <> '' AND [IntegrationTypeId] = @QBIntegrationTypeId
				GROUP BY MasterCompanyId
			) AS CustomerPaymentDetailsData ON CustomerPaymentDetailsData.MasterCompanyId = ACI.MasterCompanyId AND ACI.ModuleId = @CPModuleId

			-- Pending CustomerPaymentDetails Data
			LEFT JOIN (
				SELECT MasterCompanyId, COUNT(IsUpdated) AS CustomerPaymentDetailsCount
				FROM dbo.CustomerPaymentDetails  WITH(NOLOCK)
				WHERE ISNULL(IsActive, 0) = 1 AND ISNULL(IsDeleted, 0) = 0 AND ISNULL(IsUpdated, 0) = 1 AND [IntegrationTypeId] = @QBIntegrationTypeId
				GROUP BY MasterCompanyId
			) AS PendingCustomerPaymentDetailsData ON PendingCustomerPaymentDetailsData.MasterCompanyId = ACI.MasterCompanyId AND ACI.ModuleId = @CPModuleId

			-- All CustomerPaymentDetails Data
			LEFT JOIN (
				SELECT MasterCompanyId, COUNT(CustomerPaymentDetailsId) AS CustomerPaymentDetailsCount
				FROM dbo.CustomerPaymentDetails  WITH(NOLOCK)
				WHERE ISNULL(IsActive, 0) = 1 AND ISNULL(IsDeleted, 0) = 0 AND [IntegrationTypeId] = @QBIntegrationTypeId
				GROUP BY MasterCompanyId
			) AS AllCustomerPaymentDetailsData ON AllCustomerPaymentDetailsData.MasterCompanyId = ACI.MasterCompanyId AND ACI.ModuleId = @CPModuleId

			WHERE ACI.ModuleId = @CPModuleId


			UPDATE ACI
			SET 
				SyncRecords = ISNULL(CustomerPaymentDetailsData.CustomerPaymentDetailsCount, 0),
				PendingSyncRecords = ISNULL(PendingCustomerPaymentDetailsData.CustomerPaymentDetailsCount, 0),
				TotalRecords = ISNULL(AllCustomerPaymentDetailsData.CustomerPaymentDetailsCount, 0)
			FROM dbo.AccountingIntegrationSettings ACI

			-- CustomerPaymentDetails Data
			LEFT JOIN (
				SELECT MasterCompanyId, COUNT(QuickBooksReferenceId) AS CustomerPaymentDetailsCount
				FROM dbo.CustomerPaymentDetails  WITH(NOLOCK)
				WHERE ISNULL(IsActive, 0) = 1 AND ISNULL(IsDeleted, 0) = 0 AND ISNULL(QuickBooksReferenceId, '') <> '' AND [IntegrationTypeId] = @XeroIntegrationTypeId
				GROUP BY MasterCompanyId
			) AS CustomerPaymentDetailsData ON CustomerPaymentDetailsData.MasterCompanyId = ACI.MasterCompanyId AND ACI.ModuleId = @CPModuleId

			-- Pending CustomerPaymentDetails Data
			LEFT JOIN (
				SELECT MasterCompanyId, COUNT(IsUpdated) AS CustomerPaymentDetailsCount
				FROM dbo.CustomerPaymentDetails  WITH(NOLOCK)
				WHERE ISNULL(IsActive, 0) = 1 AND ISNULL(IsDeleted, 0) = 0 AND ISNULL(IsUpdated, 0) = 1 AND [IntegrationTypeId] = @XeroIntegrationTypeId
				GROUP BY MasterCompanyId
			) AS PendingCustomerPaymentDetailsData ON PendingCustomerPaymentDetailsData.MasterCompanyId = ACI.MasterCompanyId AND ACI.ModuleId = @CPModuleId

			-- All CustomerPaymentDetails Data
			LEFT JOIN (
				SELECT MasterCompanyId, COUNT(CustomerPaymentDetailsId) AS CustomerPaymentDetailsCount
				FROM dbo.CustomerPaymentDetails  WITH(NOLOCK)
				WHERE ISNULL(IsActive, 0) = 1 AND ISNULL(IsDeleted, 0) = 0 AND [IntegrationTypeId] = @XeroIntegrationTypeId
				GROUP BY MasterCompanyId
			) AS AllCustomerPaymentDetailsData ON AllCustomerPaymentDetailsData.MasterCompanyId = ACI.MasterCompanyId AND ACI.ModuleId = @CPModuleId

			WHERE ACI.ModuleId = @CPModuleId
		END

		---------------Invoice Insert

		IF @ModuleId = @InvModuleId
		BEGIN
			--------------------------------- QuickBooks ---------------------------------

			UPDATE ACI
			SET 
				SyncRecords = ISNULL(WorkOrderBillingInvoicingData.WorkOrderBillingInvoicingCount, 0) + ISNULL(SalesOrderBillingInvoicingData.SalesOrderBillingInvoicingCount, 0) + ISNULL(ExchangeSalesOrderBillingInvoicingData.ExchangeSalesOrderBillingInvoicingCount, 0),
				PendingSyncRecords = ISNULL(PendingWorkOrderBillingInvoicingData.WorkOrderBillingInvoicingCount, 0) + ISNULL(PendingSalesOrderBillingInvoicingData.SalesOrderBillingInvoicingCount, 0) + ISNULL(PendingExchangeSalesOrderBillingInvoicingData.ExchangeSalesOrderBillingInvoicingCount, 0),
				TotalRecords = ISNULL(AllWorkOrderBillingInvoicingData.WorkOrderBillingInvoicingCount, 0) + ISNULL(AllSalesOrderBillingInvoicingData.SalesOrderBillingInvoicingCount, 0) + 	ISNULL(AllExchangeSalesOrderBillingInvoicingData.ExchangeSalesOrderBillingInvoicingCount, 0)
			FROM dbo.AccountingIntegrationSettings ACI			

			-- New Table
			LEFT JOIN (
				SELECT MasterCompanyId, COUNT(QuickBooksReferenceId) AS WorkOrderBillingInvoicingCount
				FROM [dbo].[BillingInvoicing]  WITH(NOLOCK)
				WHERE [IsVersionIncrease] = 0 AND IsActive = 1 AND IsDeleted = 0 AND ISNULL(QuickBooksReferenceId, '') <> ''  AND [IntegrationTypeId] = @QBIntegrationTypeId AND ISNULL(IsPerformaInvoice, 0) = 0
				GROUP BY MasterCompanyId
			) AS WorkOrderBillingInvoicingData ON WorkOrderBillingInvoicingData.MasterCompanyId = ACI.MasterCompanyId AND ACI.ModuleId = @InvModuleId
						
			-- New Table
			LEFT JOIN (
				SELECT MasterCompanyId, COUNT(IsUpdated) AS WorkOrderBillingInvoicingCount
				FROM [dbo].[BillingInvoicing]  WITH(NOLOCK)
				WHERE [IsVersionIncrease] = 0 AND IsActive = 1 AND IsDeleted = 0 AND ISNULL(IsUpdated, 0) = 1 AND ISNULL(IsPerformaInvoice, 0) = 0 AND [IntegrationTypeId] = @QBIntegrationTypeId
				GROUP BY MasterCompanyId
			) AS PendingWorkOrderBillingInvoicingData ON PendingWorkOrderBillingInvoicingData.MasterCompanyId = ACI.MasterCompanyId AND ACI.ModuleId = @InvModuleId
						
			-- New Table
			LEFT JOIN (
				SELECT MasterCompanyId, COUNT(BillingInvoicingId) AS WorkOrderBillingInvoicingCount
				FROM [dbo].[BillingInvoicing] WITH(NOLOCK)
				WHERE [IsVersionIncrease] = 0 AND IsActive = 1 AND IsDeleted = 0 AND ISNULL(IsPerformaInvoice, 0) = 0 AND [IntegrationTypeId] = @QBIntegrationTypeId
				GROUP BY MasterCompanyId
			) AS AllWorkOrderBillingInvoicingData ON AllWorkOrderBillingInvoicingData.MasterCompanyId = ACI.MasterCompanyId AND ACI.ModuleId = @InvModuleId
						
			-- New Table
			LEFT JOIN (
				SELECT MasterCompanyId, COUNT(QuickBooksReferenceId) AS SalesOrderBillingInvoicingCount
				FROM [dbo].[BillingInvoicing]  WITH(NOLOCK)
				WHERE [IsVersionIncrease] = 0 AND IsActive = 1 AND IsDeleted = 0 AND ISNULL(QuickBooksReferenceId, '') <> '' AND [IntegrationTypeId] = @QBIntegrationTypeId AND ISNULL(IsPerformaInvoice, 0) = 0
				GROUP BY MasterCompanyId
			) AS SalesOrderBillingInvoicingData ON SalesOrderBillingInvoicingData.MasterCompanyId = ACI.MasterCompanyId AND ACI.ModuleId = @InvModuleId
			
			-- New Table
			LEFT JOIN (
				SELECT MasterCompanyId, COUNT(IsUpdated) AS SalesOrderBillingInvoicingCount
				FROM [dbo].[BillingInvoicing]  WITH(NOLOCK)
				WHERE [IsVersionIncrease] = 0 AND ISNULL(IsActive, 0) = 1 AND ISNULL(IsDeleted, 0) = 0 AND ISNULL(IsUpdated, 0) = 1 AND ISNULL([IsPerformaInvoice], 0) = 0 AND [IntegrationTypeId] = @QBIntegrationTypeId
				GROUP BY MasterCompanyId
			) AS PendingSalesOrderBillingInvoicingData ON PendingSalesOrderBillingInvoicingData.MasterCompanyId = ACI.MasterCompanyId AND ACI.ModuleId = @InvModuleId
						
			-- New Table
			LEFT JOIN (
				SELECT MasterCompanyId, COUNT(BillingInvoicingId) AS SalesOrderBillingInvoicingCount
				FROM [dbo].[BillingInvoicing]  WITH(NOLOCK)
				WHERE [IsVersionIncrease] = 0 AND ISNULL(IsActive, 0) = 1 AND ISNULL(IsDeleted, 0) = 0 AND ISNULL([IsPerformaInvoice], 0) = 0 AND [IntegrationTypeId] = @QBIntegrationTypeId
				GROUP BY MasterCompanyId
			) AS AllSalesOrderBillingInvoicingData ON AllSalesOrderBillingInvoicingData.MasterCompanyId = ACI.MasterCompanyId AND ACI.ModuleId = @InvModuleId
			
			-- ExchangeSalesOrderBillingInvoicing Data
			LEFT JOIN (
				SELECT MasterCompanyId, COUNT(QuickBooksReferenceId) AS ExchangeSalesOrderBillingInvoicingCount
				FROM dbo.ExchangeSalesOrderBillingInvoicing  WITH(NOLOCK)
				WHERE ISNULL(IsActive, 0) = 1 AND ISNULL(IsDeleted, 0) = 0 AND ISNULL(QuickBooksReferenceId, '') <> '' AND [IntegrationTypeId] = @QBIntegrationTypeId
				GROUP BY MasterCompanyId
			) AS ExchangeSalesOrderBillingInvoicingData ON ExchangeSalesOrderBillingInvoicingData.MasterCompanyId = ACI.MasterCompanyId AND ACI.ModuleId = @InvModuleId

			-- Pending ExchangeSalesOrderBillingInvoicing Data
			LEFT JOIN (
				SELECT MasterCompanyId, COUNT(IsUpdated) AS ExchangeSalesOrderBillingInvoicingCount
				FROM dbo.ExchangeSalesOrderBillingInvoicing  WITH(NOLOCK)
				WHERE ISNULL(IsActive, 0) = 1 AND ISNULL(IsDeleted, 0) = 0 AND ISNULL(IsUpdated, 0) = 1 AND [IntegrationTypeId] = @QBIntegrationTypeId
				GROUP BY MasterCompanyId
			) AS PendingExchangeSalesOrderBillingInvoicingData ON PendingExchangeSalesOrderBillingInvoicingData.MasterCompanyId = ACI.MasterCompanyId AND ACI.ModuleId = @InvModuleId

			-- All ExchangeSalesOrderBillingInvoicing Data
			LEFT JOIN (
				SELECT MasterCompanyId, COUNT(SOBillingInvoicingId) AS ExchangeSalesOrderBillingInvoicingCount
				FROM dbo.ExchangeSalesOrderBillingInvoicing  WITH(NOLOCK)
				WHERE ISNULL(IsActive, 0) = 1 AND ISNULL(IsDeleted, 0) = 0 AND [IntegrationTypeId] = @QBIntegrationTypeId
				GROUP BY MasterCompanyId
			) AS AllExchangeSalesOrderBillingInvoicingData ON AllExchangeSalesOrderBillingInvoicingData.MasterCompanyId = ACI.MasterCompanyId AND ACI.ModuleId = @InvModuleId

			WHERE ACI.ModuleId = @InvModuleId

			--------------------------------- Xero Accounting ---------------------------------

			UPDATE ACI
			SET 
				SyncRecords = ISNULL(WorkOrderBillingInvoicingData.WorkOrderBillingInvoicingCount, 0) + ISNULL(SalesOrderBillingInvoicingData.SalesOrderBillingInvoicingCount, 0) + ISNULL(ExchangeSalesOrderBillingInvoicingData.ExchangeSalesOrderBillingInvoicingCount, 0),
				PendingSyncRecords = ISNULL(PendingWorkOrderBillingInvoicingData.WorkOrderBillingInvoicingCount, 0) + ISNULL(PendingSalesOrderBillingInvoicingData.SalesOrderBillingInvoicingCount, 0) + ISNULL(PendingExchangeSalesOrderBillingInvoicingData.ExchangeSalesOrderBillingInvoicingCount, 0),
				TotalRecords = ISNULL(AllWorkOrderBillingInvoicingData.WorkOrderBillingInvoicingCount, 0) + ISNULL(AllSalesOrderBillingInvoicingData.SalesOrderBillingInvoicingCount, 0) + 	ISNULL(AllExchangeSalesOrderBillingInvoicingData.ExchangeSalesOrderBillingInvoicingCount, 0)
			FROM dbo.AccountingIntegrationSettings ACI			

			-- New Table
			LEFT JOIN (
				SELECT MasterCompanyId, COUNT(QuickBooksReferenceId) AS WorkOrderBillingInvoicingCount
				FROM [dbo].[BillingInvoicing]  WITH(NOLOCK)
				WHERE [IsVersionIncrease] = 0 AND IsActive = 1 AND IsDeleted = 0 AND ISNULL(QuickBooksReferenceId, '') <> ''  AND [IntegrationTypeId] = @XeroIntegrationTypeId AND ISNULL(IsPerformaInvoice, 0) = 0
				GROUP BY MasterCompanyId
			) AS WorkOrderBillingInvoicingData ON WorkOrderBillingInvoicingData.MasterCompanyId = ACI.MasterCompanyId AND ACI.ModuleId = @InvModuleId
						
			-- New Table
			LEFT JOIN (
				SELECT MasterCompanyId, COUNT(IsUpdated) AS WorkOrderBillingInvoicingCount
				FROM [dbo].[BillingInvoicing]  WITH(NOLOCK)
				WHERE [IsVersionIncrease] = 0 AND IsActive = 1 AND IsDeleted = 0 AND ISNULL(IsUpdated, 0) = 1 AND ISNULL(IsPerformaInvoice, 0) = 0 AND [IntegrationTypeId] = @XeroIntegrationTypeId 
				GROUP BY MasterCompanyId
			) AS PendingWorkOrderBillingInvoicingData ON PendingWorkOrderBillingInvoicingData.MasterCompanyId = ACI.MasterCompanyId AND ACI.ModuleId = @InvModuleId
						
			-- New Table
			LEFT JOIN (
				SELECT MasterCompanyId, COUNT(BillingInvoicingId) AS WorkOrderBillingInvoicingCount
				FROM [dbo].[BillingInvoicing] WITH(NOLOCK)
				WHERE [IsVersionIncrease] = 0 AND IsActive = 1 AND IsDeleted = 0 AND ISNULL(IsPerformaInvoice, 0) = 0 AND [IntegrationTypeId] = @XeroIntegrationTypeId
				GROUP BY MasterCompanyId
			) AS AllWorkOrderBillingInvoicingData ON AllWorkOrderBillingInvoicingData.MasterCompanyId = ACI.MasterCompanyId AND ACI.ModuleId = @InvModuleId
						
			-- New Table
			LEFT JOIN (
				SELECT MasterCompanyId, COUNT(QuickBooksReferenceId) AS SalesOrderBillingInvoicingCount
				FROM [dbo].[BillingInvoicing]  WITH(NOLOCK)
				WHERE [IsVersionIncrease] = 0 AND IsActive = 1 AND IsDeleted = 0 AND ISNULL(QuickBooksReferenceId, '') <> '' AND [IntegrationTypeId] = @XeroIntegrationTypeId AND ISNULL(IsPerformaInvoice, 0) = 0
				GROUP BY MasterCompanyId
			) AS SalesOrderBillingInvoicingData ON SalesOrderBillingInvoicingData.MasterCompanyId = ACI.MasterCompanyId AND ACI.ModuleId = @InvModuleId
			
			-- New Table
			LEFT JOIN (
				SELECT MasterCompanyId, COUNT(IsUpdated) AS SalesOrderBillingInvoicingCount
				FROM [dbo].[BillingInvoicing]  WITH(NOLOCK)
				WHERE [IsVersionIncrease] = 0 AND ISNULL(IsActive, 0) = 1 AND ISNULL(IsDeleted, 0) = 0 AND ISNULL(IsUpdated, 0) = 1 AND ISNULL([IsPerformaInvoice], 0) = 0 AND [IntegrationTypeId] = @XeroIntegrationTypeId
				GROUP BY MasterCompanyId
			) AS PendingSalesOrderBillingInvoicingData ON PendingSalesOrderBillingInvoicingData.MasterCompanyId = ACI.MasterCompanyId AND ACI.ModuleId = @InvModuleId
						
			-- New Table
			LEFT JOIN (
				SELECT MasterCompanyId, COUNT(BillingInvoicingId) AS SalesOrderBillingInvoicingCount
				FROM [dbo].[BillingInvoicing]  WITH(NOLOCK)
				WHERE [IsVersionIncrease] = 0 AND ISNULL(IsActive, 0) = 1 AND ISNULL(IsDeleted, 0) = 0 AND ISNULL([IsPerformaInvoice], 0) = 0 AND [IntegrationTypeId] = @XeroIntegrationTypeId
				GROUP BY MasterCompanyId
			) AS AllSalesOrderBillingInvoicingData ON AllSalesOrderBillingInvoicingData.MasterCompanyId = ACI.MasterCompanyId AND ACI.ModuleId = @InvModuleId
			
			-- ExchangeSalesOrderBillingInvoicing Data
			LEFT JOIN (
				SELECT MasterCompanyId, COUNT(QuickBooksReferenceId) AS ExchangeSalesOrderBillingInvoicingCount
				FROM dbo.ExchangeSalesOrderBillingInvoicing  WITH(NOLOCK)
				WHERE ISNULL(IsActive, 0) = 1 AND ISNULL(IsDeleted, 0) = 0 AND ISNULL(QuickBooksReferenceId, '') <> '' AND [IntegrationTypeId] = @XeroIntegrationTypeId
				GROUP BY MasterCompanyId
			) AS ExchangeSalesOrderBillingInvoicingData ON ExchangeSalesOrderBillingInvoicingData.MasterCompanyId = ACI.MasterCompanyId AND ACI.ModuleId = @InvModuleId

			-- Pending ExchangeSalesOrderBillingInvoicing Data
			LEFT JOIN (
				SELECT MasterCompanyId, COUNT(IsUpdated) AS ExchangeSalesOrderBillingInvoicingCount
				FROM dbo.ExchangeSalesOrderBillingInvoicing  WITH(NOLOCK)
				WHERE ISNULL(IsActive, 0) = 1 AND ISNULL(IsDeleted, 0) = 0 AND ISNULL(IsUpdated, 0) = 1 AND [IntegrationTypeId] = @XeroIntegrationTypeId
				GROUP BY MasterCompanyId
			) AS PendingExchangeSalesOrderBillingInvoicingData ON PendingExchangeSalesOrderBillingInvoicingData.MasterCompanyId = ACI.MasterCompanyId AND ACI.ModuleId = @InvModuleId

			-- All ExchangeSalesOrderBillingInvoicing Data
			LEFT JOIN (
				SELECT MasterCompanyId, COUNT(SOBillingInvoicingId) AS ExchangeSalesOrderBillingInvoicingCount
				FROM dbo.ExchangeSalesOrderBillingInvoicing  WITH(NOLOCK)
				WHERE ISNULL(IsActive, 0) = 1 AND ISNULL(IsDeleted, 0) = 0 AND [IntegrationTypeId] = @XeroIntegrationTypeId
				GROUP BY MasterCompanyId
			) AS AllExchangeSalesOrderBillingInvoicingData ON AllExchangeSalesOrderBillingInvoicingData.MasterCompanyId = ACI.MasterCompanyId AND ACI.ModuleId = @InvModuleId

			WHERE ACI.ModuleId = @InvModuleId
		END

		---------------VendorReadyToPayDetails Insert

		IF @ModuleId = @BillPaymentModuleId
		BEGIN
			--------------------------------- QuickBooks ---------------------------------

			UPDATE ACI
			SET 
				SyncRecords = ISNULL(VendorReadyToPayDetailsData.VendorReadyToPayDetailsCount, 0),
				PendingSyncRecords = ISNULL(PendingVendorReadyToPayDetailsData.VendorReadyToPayDetailsCount, 0),
				TotalRecords = ISNULL(AllVendorReadyToPayDetailsData.VendorReadyToPayDetailsCount, 0)
			FROM dbo.AccountingIntegrationSettings ACI

			-- VendorReadyToPayDetails Data
			LEFT JOIN (
				SELECT MasterCompanyId, COUNT(QuickBooksReferenceId) AS VendorReadyToPayDetailsCount
				FROM dbo.VendorReadyToPayDetails  WITH(NOLOCK)
				WHERE ISNULL(IsActive, 0) = 1 AND ISNULL(IsDeleted, 0) = 0 AND ISNULL(QuickBooksReferenceId, '') <> '' AND [IntegrationTypeId] = @QBIntegrationTypeId
				GROUP BY MasterCompanyId
			) AS VendorReadyToPayDetailsData ON VendorReadyToPayDetailsData.MasterCompanyId = ACI.MasterCompanyId AND ACI.ModuleId = @BillPaymentModuleId

			-- Pending VendorReadyToPayDetails Data
			LEFT JOIN (
				SELECT MasterCompanyId, COUNT(IsUpdated) AS VendorReadyToPayDetailsCount
				FROM dbo.VendorReadyToPayDetails  WITH(NOLOCK)
				WHERE ISNULL(IsActive, 0) = 1 AND ISNULL(IsDeleted, 0) = 0 AND ISNULL(IsUpdated, 0) = 1 AND [IntegrationTypeId] = @QBIntegrationTypeId
				GROUP BY MasterCompanyId
			) AS PendingVendorReadyToPayDetailsData ON PendingVendorReadyToPayDetailsData.MasterCompanyId = ACI.MasterCompanyId AND ACI.ModuleId = @BillPaymentModuleId

			-- All VendorReadyToPayDetails Data
			LEFT JOIN (
				SELECT MasterCompanyId, COUNT(ReadyToPayDetailsId) AS VendorReadyToPayDetailsCount
				FROM dbo.VendorReadyToPayDetails  WITH(NOLOCK)
				WHERE ISNULL(IsActive, 0) = 1 AND ISNULL(IsDeleted, 0) = 0 AND [IntegrationTypeId] = @QBIntegrationTypeId
				GROUP BY MasterCompanyId
			) AS AllVendorReadyToPayDetailsData ON AllVendorReadyToPayDetailsData.MasterCompanyId = ACI.MasterCompanyId AND ACI.ModuleId = @BillPaymentModuleId
			WHERE ACI.ModuleId = @BillPaymentModuleId

			--------------------------------- Xero Accounting ---------------------------------

			UPDATE ACI
			SET 
				SyncRecords = ISNULL(VendorReadyToPayDetailsData.VendorReadyToPayDetailsCount, 0),
				PendingSyncRecords = ISNULL(PendingVendorReadyToPayDetailsData.VendorReadyToPayDetailsCount, 0),
				TotalRecords = ISNULL(AllVendorReadyToPayDetailsData.VendorReadyToPayDetailsCount, 0)
			FROM dbo.AccountingIntegrationSettings ACI

			-- VendorReadyToPayDetails Data
			LEFT JOIN (
				SELECT MasterCompanyId, COUNT(QuickBooksReferenceId) AS VendorReadyToPayDetailsCount
				FROM dbo.VendorReadyToPayDetails  WITH(NOLOCK)
				WHERE ISNULL(IsActive, 0) = 1 AND ISNULL(IsDeleted, 0) = 0 AND ISNULL(QuickBooksReferenceId, '') <> '' AND [IntegrationTypeId] = @XeroIntegrationTypeId
				GROUP BY MasterCompanyId
			) AS VendorReadyToPayDetailsData ON VendorReadyToPayDetailsData.MasterCompanyId = ACI.MasterCompanyId AND ACI.ModuleId = @BillPaymentModuleId

			-- Pending VendorReadyToPayDetails Data
			LEFT JOIN (
				SELECT MasterCompanyId, COUNT(IsUpdated) AS VendorReadyToPayDetailsCount
				FROM dbo.VendorReadyToPayDetails  WITH(NOLOCK)
				WHERE ISNULL(IsActive, 0) = 1 AND ISNULL(IsDeleted, 0) = 0 AND ISNULL(IsUpdated, 0) = 1 AND [IntegrationTypeId] = @XeroIntegrationTypeId
				GROUP BY MasterCompanyId
			) AS PendingVendorReadyToPayDetailsData ON PendingVendorReadyToPayDetailsData.MasterCompanyId = ACI.MasterCompanyId AND ACI.ModuleId = @BillPaymentModuleId

			-- All VendorReadyToPayDetails Data
			LEFT JOIN (
				SELECT MasterCompanyId, COUNT(ReadyToPayDetailsId) AS VendorReadyToPayDetailsCount
				FROM dbo.VendorReadyToPayDetails  WITH(NOLOCK)
				WHERE ISNULL(IsActive, 0) = 1 AND ISNULL(IsDeleted, 0) = 0 AND [IntegrationTypeId] = @XeroIntegrationTypeId
				GROUP BY MasterCompanyId
			) AS AllVendorReadyToPayDetailsData ON AllVendorReadyToPayDetailsData.MasterCompanyId = ACI.MasterCompanyId AND ACI.ModuleId = @BillPaymentModuleId
			WHERE ACI.ModuleId = @BillPaymentModuleId

		END

		--------------- VendorCreditMemo Insert

		IF @ModuleId = @VendorCreditMemoModuleId
		BEGIN
			--------------------------------- Xero Accounting ---------------------------------
			UPDATE ACI
			SET 
				SyncRecords        = ISNULL(VendorCreditMemoData.VendorCreditMemoCount, 0),
				PendingSyncRecords = ISNULL(PendingVendorCreditMemoData.VendorCreditMemoCount, 0),
				TotalRecords       = ISNULL(AllVendorCreditMemoData.VendorCreditMemoCount, 0)
			FROM dbo.AccountingIntegrationSettings ACI

			-- Synced VendorCreditMemo Data
			LEFT JOIN (
				SELECT MasterCompanyId, COUNT(QuickBooksReferenceId) AS VendorCreditMemoCount
				FROM dbo.VendorCreditMemo WITH(NOLOCK)
				WHERE ISNULL(IsActive, 0) = 1 
				  AND ISNULL(IsDeleted, 0) = 0 
				  AND ISNULL(QuickBooksReferenceId, '') <> ''
				  AND [IntegrationTypeId] = @XeroIntegrationTypeId
				GROUP BY MasterCompanyId
			) AS VendorCreditMemoData ON VendorCreditMemoData.MasterCompanyId = ACI.MasterCompanyId 
				AND ACI.ModuleId = @VendorCreditMemoModuleId

			-- Pending VendorCreditMemo Data
			LEFT JOIN (
				SELECT MasterCompanyId, COUNT(IsUpdated) AS VendorCreditMemoCount
				FROM dbo.VendorCreditMemo WITH(NOLOCK)
				WHERE ISNULL(IsActive, 0) = 1 
				  AND ISNULL(IsDeleted, 0) = 0 
				  AND ISNULL(IsUpdated, 0) = 1
				  AND [IntegrationTypeId] = @XeroIntegrationTypeId
				GROUP BY MasterCompanyId
			) AS PendingVendorCreditMemoData ON PendingVendorCreditMemoData.MasterCompanyId = ACI.MasterCompanyId 
				AND ACI.ModuleId = @VendorCreditMemoModuleId

			-- All VendorCreditMemo Data
			LEFT JOIN (
				SELECT MasterCompanyId, COUNT(VendorCreditMemoId) AS VendorCreditMemoCount
				FROM dbo.VendorCreditMemo WITH(NOLOCK)
				WHERE ISNULL(IsActive, 0) = 1 
				  AND ISNULL(IsDeleted, 0) = 0
				  AND [IntegrationTypeId] = @XeroIntegrationTypeId
				GROUP BY MasterCompanyId
			) AS AllVendorCreditMemoData ON AllVendorCreditMemoData.MasterCompanyId = ACI.MasterCompanyId 
				AND ACI.ModuleId = @VendorCreditMemoModuleId

			WHERE ACI.ModuleId = @VendorCreditMemoModuleId
		END

	END TRY    
	BEGIN CATCH      

				DECLARE @ErrorLogID INT
			,@DatabaseName VARCHAR(100) = db_name()
			-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
			,@AdhocComments VARCHAR(150) = 'QuickBooks_UpdateModuleCountDetails'
			,@ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@MasterCompanyId, '') AS varchar(100))  			                                           
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