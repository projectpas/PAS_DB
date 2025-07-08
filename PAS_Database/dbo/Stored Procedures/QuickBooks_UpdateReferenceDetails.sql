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
 EXECUTE [QuickBooks_UpdateCustomerReferenceDetails] 1, 10, '150'
**************************************************************/ 
CREATE   PROCEDURE [dbo].[QuickBooks_UpdateReferenceDetails]
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
		DECLARE @CustomerPaymentModuleId INT, @CreditTermModuleId INT, @GLAccountModuleId INT, @BillModuleId INT, @POModuleId INT, @ItemModuleId INT, @CreditMemoModuleId INT;

		SELECT @CustomerModuleId = ModuleId FROM dbo.AccountingIntegrationSettings WITH(NOLOCK) WHERE UPPER(ModuleName) = 'CUSTOMER';
		SELECT @VendorModuleId = ModuleId FROM dbo.AccountingIntegrationSettings WITH(NOLOCK) WHERE UPPER(ModuleName) = 'VENDOR';
		SELECT @InvModuleId = ModuleId FROM dbo.AccountingIntegrationSettings WITH(NOLOCK) WHERE UPPER(ModuleName) = 'INVOICE';
		SELECT @CustomerPaymentModuleId = ModuleId FROM dbo.AccountingIntegrationSettings WITH(NOLOCK) WHERE UPPER(ModuleName) = 'CUSTOMERPAYMENT';
		SELECT @CreditTermModuleId = ModuleId FROM dbo.AccountingIntegrationSettings WITH(NOLOCK) WHERE UPPER(ModuleName) = 'CREDITTERM';
		SELECT @GLAccountModuleId = ModuleId FROM dbo.AccountingIntegrationSettings WITH(NOLOCK) WHERE UPPER(ModuleName) = 'GLACCOUNT';
		SELECT @BillModuleId = ModuleId FROM dbo.AccountingIntegrationSettings WITH(NOLOCK) WHERE UPPER(ModuleName) = 'BILL';
		SELECT @POModuleId = ModuleId FROM dbo.AccountingIntegrationSettings WITH(NOLOCK) WHERE UPPER(ModuleName) = 'PURCHASEORDER';
		SELECT @ItemModuleId = ModuleId FROM dbo.AccountingIntegrationSettings WITH(NOLOCK) WHERE UPPER(ModuleName) = 'ITEMMASTER';
		SELECT @CreditMemoModuleId = ModuleId FROM dbo.AccountingIntegrationSettings WITH(NOLOCK) WHERE UPPER(ModuleName) = 'CREDITMEMO';

		SELECT @WOModuleId = ISNULL(ModuleId, 0) FROM [dbo].[Module] WITH(NOLOCK) WHERE [ModuleName] = 'WorkOrder';
		SELECT @SOModuleId = ISNULL(ModuleId, 0) FROM [dbo].[Module] WITH(NOLOCK) WHERE [ModuleName] = 'SalesOrder';
		SELECT @ExchModuleId = ISNULL(ModuleId, 0) FROM [dbo].[Module] WITH(NOLOCK) WHERE [ModuleName] = 'ExchangeSalesOrder';

		SELECT @NonPOModuleId = ISNULL(ModuleId, 0) FROM [dbo].[Module] WITH(NOLOCK) WHERE [ModuleName] = 'NonPOInvoice';
		SELECT @PurchaseOrderModuleId = ISNULL(ModuleId, 0) FROM [dbo].[Module] WITH(NOLOCK) WHERE [ModuleName] = 'PurchaseOrder';
		SELECT @RepairOrderModuleId = ISNULL(ModuleId, 0) FROM [dbo].[Module] WITH(NOLOCK) WHERE [ModuleName] = 'RepairOrder';
		SET @ReferenceModuleId =  ISNULL(@ReferenceModuleId, 0);

		-- FOR QuickBooks
		IF(ISNULL(@IntegrationTypeId, 0) = 1 AND @ModuleId = @CustomerModuleId) 
		BEGIN
			UPDATE [dbo].[Customer] SET QuickBooksReferenceId =  @QuickBooksReferenceId, IsUpdated = 0, LastSyncDate = GETUTCDATE(), SyncToken = @SyncToken WHERE CustomerId = @ReferenceId			
		END

		IF(ISNULL(@IntegrationTypeId, 0) = 1 AND @ModuleId = @VendorModuleId) 
		BEGIN
			UPDATE [dbo].[Vendor] SET QuickBooksReferenceId =  @QuickBooksReferenceId, IsUpdated = 0, LastSyncDate = GETUTCDATE(), SyncToken = @SyncToken WHERE VendorId = @ReferenceId			
		END		 

		IF(ISNULL(@IntegrationTypeId, 0) = 1 AND @ModuleId = @InvModuleId AND @WOModuleId = @ReferenceModuleId) 
		BEGIN
			UPDATE [dbo].[BillingInvoicing] SET QuickBooksReferenceId =  @QuickBooksReferenceId, IsUpdated = 0, LastSyncDate = GETUTCDATE(), SyncToken = @SyncToken WHERE BillingInvoicingId = @ReferenceId	AND [ModuleId] = @WOModuleId 		
		END

		IF(ISNULL(@IntegrationTypeId, 0) = 1 AND @ModuleId = @InvModuleId AND @SOModuleId = @ReferenceModuleId) 
		BEGIN
			UPDATE [dbo].[BillingInvoicing] SET QuickBooksReferenceId =  @QuickBooksReferenceId, IsUpdated = 0, LastSyncDate = GETUTCDATE(), SyncToken = @SyncToken WHERE BillingInvoicingId = @ReferenceId	AND [ModuleId] = @SOModuleId		
		END

		IF(ISNULL(@IntegrationTypeId, 0) = 1 AND @ModuleId = @InvModuleId AND @ExchModuleId = @ReferenceModuleId) 
		BEGIN
			UPDATE [dbo].[ExchangeSalesOrderBillingInvoicing] SET QuickBooksReferenceId =  @QuickBooksReferenceId, IsUpdated = 0, LastSyncDate = GETUTCDATE(), SyncToken = @SyncToken WHERE SOBillingInvoicingId = @ReferenceId			
		END

		IF(ISNULL(@IntegrationTypeId, 0) = 1 AND @ModuleId = @BillModuleId AND @NonPOModuleId = @ReferenceModuleId) 
		BEGIN
			UPDATE [dbo].[NonPOInvoiceHeader] SET QuickBooksReferenceId = @QuickBooksReferenceId, IsUpdated = 0, LastSyncDate = GETUTCDATE(), SyncToken = @SyncToken WHERE NonPOInvoiceId = @ReferenceId			
		END

		IF(ISNULL(@IntegrationTypeId, 0) = 1 AND @ModuleId = @CustomerPaymentModuleId) 
		BEGIN
			UPDATE [dbo].[CustomerPaymentDetails] SET QuickBooksReferenceId =  @QuickBooksReferenceId, IsUpdated = 0, LastSyncDate = GETUTCDATE(), SyncToken = @SyncToken WHERE CustomerPaymentDetailsId = @ReferenceId			
		END

		IF(ISNULL(@IntegrationTypeId, 0) = 1 AND @ModuleId = @CreditTermModuleId) 
		BEGIN
			UPDATE [dbo].[CreditTerms] SET QuickBooksReferenceId =  @QuickBooksReferenceId, IsUpdated = 0, LastSyncDate = GETUTCDATE(), SyncToken = @SyncToken WHERE CreditTermsId = @ReferenceId	
		END

		IF(ISNULL(@IntegrationTypeId, 0) = 1 AND @ModuleId = @GLAccountModuleId) 
		BEGIN
			UPDATE [dbo].[GLAccount] SET QuickBooksReferenceId =  @QuickBooksReferenceId, IsUpdated = 0, LastSyncDate = GETUTCDATE(), SyncToken = @SyncToken WHERE GLAccountId = @ReferenceId			
		END

		IF(ISNULL(@IntegrationTypeId, 0) = 1 AND @ModuleId = @POModuleId AND @PurchaseOrderModuleId = @ReferenceModuleId) 
		BEGIN
			UPDATE PurchaseOrder SET QuickBooksReferenceId =  @QuickBooksReferenceId, IsUpdated = 0, LastSyncDate = GETUTCDATE(), SyncToken = @SyncToken WHERE PurchaseOrderId = @ReferenceId			
		END

		IF(ISNULL(@IntegrationTypeId, 0) = 1 AND @ModuleId = @POModuleId AND @RepairOrderModuleId = @ReferenceModuleId) 
		BEGIN
			UPDATE RepairOrder SET QuickBooksReferenceId =  @QuickBooksReferenceId, IsUpdated = 0, LastSyncDate = GETUTCDATE(), SyncToken = @SyncToken WHERE RepairOrderId = @ReferenceId			
		END

		IF(ISNULL(@IntegrationTypeId, 0) = 1 AND @ModuleId = @ItemModuleId) 
		BEGIN
			UPDATE [dbo].[ItemMaster] SET QuickBooksReferenceId =  @QuickBooksReferenceId, IsUpdated = 0, LastSyncDate = GETUTCDATE(), SyncToken = @SyncToken WHERE ItemMasterId = @ReferenceId
		END

		IF(ISNULL(@IntegrationTypeId, 0) = 1 AND @ModuleId = @CreditMemoModuleId) 
		BEGIN
			UPDATE [dbo].[CreditMemo] SET QuickBooksReferenceId =  @QuickBooksReferenceId, IsUpdated = 0, LastSyncDate = GETUTCDATE(), SyncToken = @SyncToken WHERE CreditMemoHeaderId = @ReferenceId			
		END

		UPDATE dbo.AccountingIntegrationSettings SET [LastRun] = GETUTCDATE(), [UpdatedDate] = GETUTCDATE() WHERE [ModuleId] = @ModuleId AND [IntegrationId] = @IntegrationTypeId;

	END TRY    
	BEGIN CATCH      

	         DECLARE @ErrorLogID INT
			,@DatabaseName VARCHAR(100) = db_name()
			-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
			,@AdhocComments VARCHAR(150) = 'QuickBooks_UpdateCustomerReferenceDetails'
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