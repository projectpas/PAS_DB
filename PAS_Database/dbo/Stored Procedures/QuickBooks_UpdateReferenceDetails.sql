/*************************************************************           
 ** File:   [QuickBooks_UpdateReferenceDetails]           
 ** Author:   Hemant Saliya
 ** Description: Update QuickBooks Customer Id In PAS    
 ** Purpose:         
 ** Date:   04-July-2024        
         
 ** RETURN VALUE: 
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date			Author			Change Description            
 ** --   --------		-------			--------------------------------          
    1    04-July-2024   Hemant Saliya	Created (Update QuickBooks Customer Id In PAS)
    2    12-Nov-2024   Devendra Shekh	Modified (Update AccountingIntegrationSettings LastRun, UpdatedDate)
    3    18-Nov-2024   Devendra Shekh	Modified (Update syncToken)
    4    27-Nov-2024   Devendra Shekh	Modified (added Change for Cash Receipt/CustomerPayment)
    5    28-Nov-2024   Devendra Shekh	Modified (added Change for CreditTerms)
    6    30-Jan-2025   Devendra Shekh	Modified (added Change for GLAccount)
    7    06-Feb-2025   Abhishek Jirawla	Modified (added Change for Non PO)
    8    07-Feb-2025   Abhishek Jirawla	Modified (added Change for Purchase Order)
    9    11-Feb-2025   Abhishek Jirawla	Modified (added Change for Item Master)
	10	 12-Feb-2024   Devendra Shekh	Modified (added Change for CreditMemo)
    11   07-07-2025    Moin Bloch       Modified Changed Old To New Billing Table
	12   21-04-2026    Moin Bloch       Modified Added Xero Accounting Changes PN-16008
	13   04-06-2026    Abhishek Jirawla Modified Added Xero Accounting Changes For Customer Payments(Cash Reciept)
	14   05-06-2026    Bhargav Saliya   Added Xero Case For Credit Memo
 EXECUTE [QuickBooks_UpdateCustomerReferenceDetails] 1, 10, '150'
**************************************************************/ 
CREATE PROCEDURE [dbo].[QuickBooks_UpdateReferenceDetails]
@IntegrationTypeId INT = NULL,
@ModuleId BIGINT = NULL,
@ReferenceId BIGINT = NULL,
@QuickBooksReferenceId VARCHAR(100),
@SyncToken VARCHAR(200) = NULL,
@ReferenceModuleId BIGINT = NULL
AS
BEGIN
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED	
	BEGIN TRY
		DECLARE @CustomerModuleId INT;
		DECLARE @VendorModuleId INT;
		DECLARE @InvModuleId INT = 0, @WOModuleId INT = 0, @SOModuleId INT = 0, @ExchModuleId INT = 0, @NonPOModuleId INT = 0, @PurchaseOrderModuleId INT = 0, @RepairOrderModuleId INT = 0;
		DECLARE @CustomerPaymentModuleId INT, @CreditTermModuleId INT, @GLAccountModuleId INT, @BillModuleId INT, @POModuleId INT, @ItemModuleId INT, @CreditMemoModuleId INT,@VendorCreditMemoModuleId INT;
		DECLARE @QBIntegrationTypeId INT = 1, @NSIntegrationTypeId INT = 2, @XeroIntegrationTypeId INT = 3;

		-- FIX 1: Consolidate all AccountingIntegrationSettings lookups into a single table scan
		SELECT
			@CustomerModuleId        = MAX(CASE WHEN UPPER([ModuleName]) = 'CUSTOMER'        THEN [ModuleId] END),
			@VendorModuleId          = MAX(CASE WHEN UPPER([ModuleName]) = 'VENDOR'          THEN [ModuleId] END),
			@InvModuleId             = ISNULL(MAX(CASE WHEN UPPER([ModuleName]) = 'INVOICE'          THEN [ModuleId] END), 0),
			@CustomerPaymentModuleId = MAX(CASE WHEN UPPER([ModuleName]) = 'CUSTOMERPAYMENT' THEN [ModuleId] END),
			@CreditTermModuleId      = MAX(CASE WHEN UPPER([ModuleName]) = 'CREDITTERM'      THEN [ModuleId] END),
			@GLAccountModuleId       = MAX(CASE WHEN UPPER([ModuleName]) = 'GLACCOUNT'       THEN [ModuleId] END),
			@BillModuleId            = MAX(CASE WHEN UPPER([ModuleName]) = 'BILL'            THEN [ModuleId] END),
			@POModuleId              = MAX(CASE WHEN UPPER([ModuleName]) = 'PURCHASEORDER'   THEN [ModuleId] END),
			@ItemModuleId            = MAX(CASE WHEN UPPER([ModuleName]) = 'ITEMMASTER'      THEN [ModuleId] END),
			@CreditMemoModuleId      = MAX(CASE WHEN UPPER([ModuleName]) = 'CREDITMEMO'      THEN [ModuleId] END),
			@VendorCreditMemoModuleId      = MAX(CASE WHEN UPPER([ModuleName]) = 'VENDORCREDITMEMO'      THEN [ModuleId] END)
		FROM [dbo].[AccountingIntegrationSettings] WITH(NOLOCK);

		-- FIX 1: Consolidate all Module lookups into a single table scan
		SELECT
			@WOModuleId             = ISNULL(MAX(CASE WHEN [ModuleName] = 'WorkOrder'         THEN [ModuleId] END), 0),
			@SOModuleId             = ISNULL(MAX(CASE WHEN [ModuleName] = 'SalesOrder'        THEN [ModuleId] END), 0),
			@ExchModuleId           = ISNULL(MAX(CASE WHEN [ModuleName] = 'ExchangeSalesOrder' THEN [ModuleId] END), 0),
			@NonPOModuleId          = ISNULL(MAX(CASE WHEN [ModuleName] = 'NonPOInvoice'      THEN [ModuleId] END), 0),
			@PurchaseOrderModuleId  = ISNULL(MAX(CASE WHEN [ModuleName] = 'PurchaseOrder'     THEN [ModuleId] END), 0),
			@RepairOrderModuleId    = ISNULL(MAX(CASE WHEN [ModuleName] = 'RepairOrder'       THEN [ModuleId] END), 0)
		FROM [dbo].[Module] WITH(NOLOCK);

		SET @ReferenceModuleId = ISNULL(@ReferenceModuleId, 0);

		-- FIX 1: Consolidate all AccountingIntegrationType lookups into a single table scan
		SELECT
			@QBIntegrationTypeId   = MAX(CASE WHEN [IntegrationType] = 'QuickBooks' THEN [IntegrationTypeId] END),
			@NSIntegrationTypeId   = MAX(CASE WHEN [IntegrationType] = 'NetSuite'   THEN [IntegrationTypeId] END),
			@XeroIntegrationTypeId = MAX(CASE WHEN [IntegrationType] = 'Xero'       THEN [IntegrationTypeId] END)
		FROM [dbo].[AccountingIntegrationType] WITH(NOLOCK);

		-- FIX 2: Use IF/ELSE IF chain so only ONE branch executes and only ONE UPDATE plan runs
		IF (ISNULL(@IntegrationTypeId, 0) = @QBIntegrationTypeId AND @ModuleId = @CustomerModuleId)
		BEGIN
			UPDATE [dbo].[Customer] SET [QuickBooksReferenceId] = @QuickBooksReferenceId, [IsUpdated] = 0, [LastSyncDate] = GETUTCDATE(), [SyncToken] = @SyncToken, [IntegrationTypeId] = @IntegrationTypeId WHERE [CustomerId] = @ReferenceId;
		END
		ELSE IF (ISNULL(@IntegrationTypeId, 0) = @QBIntegrationTypeId AND @ModuleId = @VendorModuleId)
		BEGIN
			UPDATE [dbo].[Vendor] SET [QuickBooksReferenceId] = @QuickBooksReferenceId, [IsUpdated] = 0, [LastSyncDate] = GETUTCDATE(), [SyncToken] = @SyncToken, [IntegrationTypeId] = @IntegrationTypeId WHERE [VendorId] = @ReferenceId;
		END
		ELSE IF (ISNULL(@IntegrationTypeId, 0) = @QBIntegrationTypeId AND @ModuleId = @InvModuleId AND @WOModuleId = @ReferenceModuleId)
		BEGIN
			UPDATE [dbo].[BillingInvoicing] SET [QuickBooksReferenceId] = @QuickBooksReferenceId, IsUpdated = 0, LastSyncDate = GETUTCDATE(), SyncToken = @SyncToken, [IntegrationTypeId] = @IntegrationTypeId WHERE BillingInvoicingId = @ReferenceId AND [ModuleId] = @WOModuleId;
		END
		ELSE IF (ISNULL(@IntegrationTypeId, 0) = @QBIntegrationTypeId AND @ModuleId = @InvModuleId AND @SOModuleId = @ReferenceModuleId)
		BEGIN
			UPDATE [dbo].[BillingInvoicing] SET [QuickBooksReferenceId] = @QuickBooksReferenceId, IsUpdated = 0, LastSyncDate = GETUTCDATE(), SyncToken = @SyncToken, [IntegrationTypeId] = @IntegrationTypeId WHERE BillingInvoicingId = @ReferenceId AND [ModuleId] = @SOModuleId;
		END
		ELSE IF (ISNULL(@IntegrationTypeId, 0) = @QBIntegrationTypeId AND @ModuleId = @InvModuleId AND @ExchModuleId = @ReferenceModuleId)
		BEGIN
			UPDATE [dbo].[ExchangeSalesOrderBillingInvoicing] SET [QuickBooksReferenceId] = @QuickBooksReferenceId, IsUpdated = 0, LastSyncDate = GETUTCDATE(), SyncToken = @SyncToken WHERE SOBillingInvoicingId = @ReferenceId;
		END
		ELSE IF (ISNULL(@IntegrationTypeId, 0) = @QBIntegrationTypeId AND @ModuleId = @BillModuleId AND @NonPOModuleId = @ReferenceModuleId)
		BEGIN
			UPDATE [dbo].[NonPOInvoiceHeader] SET [QuickBooksReferenceId] = @QuickBooksReferenceId, IsUpdated = 0, LastSyncDate = GETUTCDATE(), SyncToken = @SyncToken WHERE NonPOInvoiceId = @ReferenceId;
		END
		ELSE IF (ISNULL(@IntegrationTypeId, 0) = @QBIntegrationTypeId AND @ModuleId = @CustomerPaymentModuleId)
		BEGIN
			UPDATE [dbo].[CustomerPaymentDetails] SET [QuickBooksReferenceId] = @QuickBooksReferenceId, IsUpdated = 0, LastSyncDate = GETUTCDATE(), SyncToken = @SyncToken WHERE CustomerPaymentDetailsId = @ReferenceId;
		END
		ELSE IF (ISNULL(@IntegrationTypeId, 0) = @QBIntegrationTypeId AND @ModuleId = @CreditTermModuleId)
		BEGIN
			UPDATE [dbo].[CreditTerms] SET [QuickBooksReferenceId] = @QuickBooksReferenceId, IsUpdated = 0, LastSyncDate = GETUTCDATE(), SyncToken = @SyncToken WHERE CreditTermsId = @ReferenceId;
		END
		ELSE IF (ISNULL(@IntegrationTypeId, 0) = @QBIntegrationTypeId AND @ModuleId = @GLAccountModuleId)
		BEGIN
			UPDATE [dbo].[GLAccount] SET [QuickBooksReferenceId] = @QuickBooksReferenceId, IsUpdated = 0, LastSyncDate = GETUTCDATE(), SyncToken = @SyncToken WHERE GLAccountId = @ReferenceId;
		END
		ELSE IF (ISNULL(@IntegrationTypeId, 0) = @QBIntegrationTypeId AND @ModuleId = @POModuleId AND @PurchaseOrderModuleId = @ReferenceModuleId)
		BEGIN
			UPDATE PurchaseOrder SET [QuickBooksReferenceId] = @QuickBooksReferenceId, IsUpdated = 0, LastSyncDate = GETUTCDATE(), SyncToken = @SyncToken WHERE PurchaseOrderId = @ReferenceId;
		END
		ELSE IF (ISNULL(@IntegrationTypeId, 0) = @QBIntegrationTypeId AND @ModuleId = @POModuleId AND @RepairOrderModuleId = @ReferenceModuleId)
		BEGIN
			UPDATE RepairOrder SET [QuickBooksReferenceId] = @QuickBooksReferenceId, IsUpdated = 0, LastSyncDate = GETUTCDATE(), SyncToken = @SyncToken WHERE RepairOrderId = @ReferenceId;
		END
		ELSE IF (ISNULL(@IntegrationTypeId, 0) = @QBIntegrationTypeId AND @ModuleId = @ItemModuleId)
		BEGIN
			UPDATE [dbo].[ItemMaster] SET [QuickBooksReferenceId] = @QuickBooksReferenceId, IsUpdated = 0, LastSyncDate = GETUTCDATE(), SyncToken = @SyncToken WHERE ItemMasterId = @ReferenceId;
		END
		ELSE IF (ISNULL(@IntegrationTypeId, 0) = @QBIntegrationTypeId AND @ModuleId = @CreditMemoModuleId)
		BEGIN
			UPDATE [dbo].[CreditMemo] SET [QuickBooksReferenceId] = @QuickBooksReferenceId, IsUpdated = 0, LastSyncDate = GETUTCDATE(), SyncToken = @SyncToken WHERE CreditMemoHeaderId = @ReferenceId;
		END
		-- Xero
		ELSE IF (ISNULL(@IntegrationTypeId, 0) = @XeroIntegrationTypeId AND @ModuleId = @CustomerModuleId)
		BEGIN
			UPDATE [dbo].[Customer] SET [QuickBooksReferenceId] = @QuickBooksReferenceId, [IsUpdated] = 0, [LastSyncDate] = GETUTCDATE(), [SyncToken] = @SyncToken, [IntegrationTypeId] = @IntegrationTypeId WHERE [CustomerId] = @ReferenceId;
		END
		ELSE IF (ISNULL(@IntegrationTypeId, 0) = @XeroIntegrationTypeId AND @ModuleId = @VendorModuleId)
		BEGIN
			UPDATE [dbo].[Vendor] SET [QuickBooksReferenceId] = @QuickBooksReferenceId, [IsUpdated] = 0, [LastSyncDate] = GETUTCDATE(), [SyncToken] = @SyncToken, [IntegrationTypeId] = @IntegrationTypeId WHERE [VendorId] = @ReferenceId;
		END
		ELSE IF (ISNULL(@IntegrationTypeId, 0) = @XeroIntegrationTypeId AND @ModuleId = @GLAccountModuleId)
		BEGIN
			UPDATE [dbo].[GLAccount] SET [QuickBooksReferenceId] = @QuickBooksReferenceId, [IsUpdated] = 0, [LastSyncDate] = GETUTCDATE(), [SyncToken] = @SyncToken, [IntegrationTypeId] = @IntegrationTypeId WHERE [GLAccountId] = @ReferenceId;
		END
		ELSE IF (ISNULL(@IntegrationTypeId, 0) = @XeroIntegrationTypeId AND @ModuleId = @ItemModuleId)
		BEGIN
			UPDATE [dbo].[ItemMaster] SET [QuickBooksReferenceId] = @QuickBooksReferenceId, [IsUpdated] = 0, [LastSyncDate] = GETUTCDATE(), [SyncToken] = @SyncToken, [IntegrationTypeId] = @IntegrationTypeId WHERE [ItemMasterId] = @ReferenceId;
		END
		ELSE IF (ISNULL(@IntegrationTypeId, 0) = @XeroIntegrationTypeId AND @ModuleId = @POModuleId)
		BEGIN
			UPDATE [dbo].[PurchaseOrder] SET [QuickBooksReferenceId] = @QuickBooksReferenceId, [IsUpdated] = 0, [LastSyncDate] = GETUTCDATE(), [SyncToken] = @SyncToken, [IntegrationTypeId] = @IntegrationTypeId WHERE [PurchaseOrderId] = @ReferenceId;
		END
		ELSE IF (ISNULL(@IntegrationTypeId, 0) = @XeroIntegrationTypeId AND @ModuleId = @InvModuleId AND @WOModuleId = @ReferenceModuleId)
		BEGIN
			UPDATE [dbo].[BillingInvoicing] SET [QuickBooksReferenceId] = @QuickBooksReferenceId, [IsUpdated] = 0, [LastSyncDate] = GETUTCDATE(), [SyncToken] = @SyncToken, [IntegrationTypeId] = @IntegrationTypeId WHERE [BillingInvoicingId] = @ReferenceId AND [ModuleId] = @WOModuleId;
		END
		ELSE IF (ISNULL(@IntegrationTypeId, 0) = @XeroIntegrationTypeId AND @ModuleId = @InvModuleId AND @SOModuleId = @ReferenceModuleId)
		BEGIN
			UPDATE [dbo].[BillingInvoicing] SET [QuickBooksReferenceId] = @QuickBooksReferenceId, [IsUpdated] = 0, [LastSyncDate] = GETUTCDATE(), [SyncToken] = @SyncToken, [IntegrationTypeId] = @IntegrationTypeId WHERE [BillingInvoicingId] = @ReferenceId AND [ModuleId] = @SOModuleId;
		END
		ELSE IF (ISNULL(@IntegrationTypeId, 0) = @XeroIntegrationTypeId AND @ModuleId = @InvModuleId AND @ExchModuleId = @ReferenceModuleId)
		BEGIN
			UPDATE [dbo].[ExchangeSalesOrderBillingInvoicing] SET [QuickBooksReferenceId] = @QuickBooksReferenceId, [IsUpdated] = 0, [LastSyncDate] = GETUTCDATE(), [SyncToken] = @SyncToken, [IntegrationTypeId] = @IntegrationTypeId WHERE [SOBillingInvoicingId] = @ReferenceId;
		END
		ELSE IF (ISNULL(@IntegrationTypeId, 0) = @XeroIntegrationTypeId AND @ModuleId = @CustomerPaymentModuleId)
		BEGIN
			UPDATE [dbo].[CustomerPaymentDetails] SET [QuickBooksReferenceId] = @QuickBooksReferenceId, IsUpdated = 0, LastSyncDate = GETUTCDATE(), SyncToken = @SyncToken, [IntegrationTypeId] = @IntegrationTypeId WHERE CustomerPaymentDetailsId = @ReferenceId;
		END
		ELSE IF(ISNULL(@IntegrationTypeId, 0) = @XeroIntegrationTypeId AND @ModuleId = @CreditMemoModuleId) 
		BEGIN
			UPDATE [dbo].[CreditMemo] SET [QuickBooksReferenceId] = @QuickBooksReferenceId, [IsUpdated] = 0, [LastSyncDate] = GETUTCDATE(), [SyncToken] = @SyncToken, [IntegrationTypeId] = @IntegrationTypeId WHERE [CreditMemoHeaderId] = @ReferenceId
		END	
		ELSE IF(ISNULL(@IntegrationTypeId, 0) = @XeroIntegrationTypeId AND @ModuleId = @VendorCreditMemoModuleId) 
		BEGIN
			UPDATE [dbo].[VendorCreditMemo] SET [QuickBooksReferenceId] = @QuickBooksReferenceId, [IsUpdated] = 0, [LastSyncDate] = GETUTCDATE(), [SyncToken] = @SyncToken, [IntegrationTypeId] = @IntegrationTypeId WHERE [VendorCreditMemoId] = @ReferenceId
		END	

		-- FIX 3: Guard the settings update — only run it when the module/integration combo actually exists
		UPDATE [dbo].[AccountingIntegrationSettings]
		SET [LastRun] = GETUTCDATE(), [UpdatedDate] = GETUTCDATE()
		WHERE [ModuleId] = @ModuleId AND [IntegrationId] = @IntegrationTypeId
		  AND EXISTS (SELECT 1 FROM [dbo].[AccountingIntegrationSettings] WITH(NOLOCK) WHERE [ModuleId] = @ModuleId AND [IntegrationId] = @IntegrationTypeId);

	END TRY    
	BEGIN CATCH      
		DECLARE @ErrorLogID INT
			,@DatabaseName VARCHAR(100) = db_name()
			,@AdhocComments VARCHAR(150) = 'QuickBooks_UpdateReferenceDetails'
			,@ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@IntegrationTypeId, '') AS varchar(100))  			                                           
			,@ApplicationName VARCHAR(100) = 'PAS'
		EXEC spLogException @DatabaseName = @DatabaseName
			,@AdhocComments = @AdhocComments
			,@ProcedureParameters = @ProcedureParameters
			,@ApplicationName = @ApplicationName
			,@ErrorLogID = @ErrorLogID OUTPUT;

		RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)
		RETURN (1);           
	END CATCH
END