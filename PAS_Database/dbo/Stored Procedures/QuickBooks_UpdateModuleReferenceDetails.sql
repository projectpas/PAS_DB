/*************************************************************           
 ** File:   [QuickBooks_UpdateModuleReferenceDetails]           
 ** Author:   Hemant Saliya
 ** Description: Update Module Detail for Sync
 ** Purpose:         
 ** Date:   20-Jan-2025        
         
 ** RETURN VALUE: 
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date			Author			Change Description            
 ** --   --------		-------			--------------------------------          
    1    20-Jan-2025   Devendra Shekh	Created
	2    23-Jan-2025   Devendra Shekh	Modified (added Change for JOURNALENTRY)
	3    07-Feb-2025   Abhishek Jirawla	Modified (added Change for Bill)
	4    07-Feb-2025   Abhishek Jirawla	Modified (added Change for Purchase Order)
	5    11-Feb-2025   Abhishek Jirawla	Modified (added Change for Item Master)
	6    12-Feb-2025   Devendra Shekh	Modified (added Change for CreditMemo)
	7    12-Feb-2025   Rajesh Gami   	Modified as per new SO Billing structure (So)
	8    12-Feb-2025   Moin Bloch   	Modified as per new WO Billing structure (WO)

 EXECUTE [QuickBooks_UpdateModuleReferenceDetails] 1, 10, '150'
**************************************************************/ 
CREATE   PROCEDURE [dbo].[QuickBooks_UpdateModuleReferenceDetails]
@IntegrationTypeId INT = NULL,
@MasterCompanyId INT = NULL,
@ModuleId BIGINT = NULL,
@ReferenceId BIGINT = NULL,
@ReferenceModuleId BIGINT = NULL
AS
BEGIN
	
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED	
	BEGIN TRY
		DECLARE @CustomerModuleId INT;
		DECLARE @VendorModuleId INT;
		DECLARE @InvModuleId INT = 0, @WOModuleId INT = 0, @SOModuleId INT = 0, @ExchModuleId INT = 0, @NonPOModuleId INT = 0, @PurchaseOrderModuleId INT = 0, @RepairOrderModuleId INT = 0;
		DECLARE @CustomerPaymentModuleId INT, @CreditTermModuleId INT, @JournalEntryModuleId INT, @BillModuleId INT, @POModuleId INT, @ItemModuleId INT, @CreditMemoModuleId INT;

		SELECT @CustomerModuleId = ModuleId FROM dbo.AccountingIntegrationSettings WITH(NOLOCK) WHERE UPPER(ModuleName) = 'CUSTOMER';
		SELECT @VendorModuleId = ModuleId FROM dbo.AccountingIntegrationSettings WITH(NOLOCK) WHERE UPPER(ModuleName) = 'VENDOR';
		SELECT @InvModuleId = ModuleId FROM dbo.AccountingIntegrationSettings WITH(NOLOCK) WHERE UPPER(ModuleName) = 'INVOICE';
		SELECT @CustomerPaymentModuleId = ModuleId FROM dbo.AccountingIntegrationSettings WITH(NOLOCK) WHERE UPPER(ModuleName) = 'CUSTOMERPAYMENT';
		SELECT @CreditTermModuleId = ModuleId FROM dbo.AccountingIntegrationSettings WITH(NOLOCK) WHERE UPPER(ModuleName) = 'CREDITTERM';
		SELECT @JournalEntryModuleId = ModuleId FROM dbo.AccountingIntegrationSettings WITH(NOLOCK) WHERE UPPER(ModuleName) = 'JOURNALENTRY';
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
			UPDATE Customer SET IsUpdated = 1 WHERE CustomerId = @ReferenceId AND MasterCompanyId = @MasterCompanyId;		
		END

		IF(ISNULL(@IntegrationTypeId, 0) = 1 AND @ModuleId = @VendorModuleId) 
		BEGIN
			UPDATE Vendor SET IsUpdated = 1 WHERE VendorId = @ReferenceId AND MasterCompanyId = @MasterCompanyId;		
		END

		IF(ISNULL(@IntegrationTypeId, 0) = 1 AND @ModuleId = @VendorModuleId) 
		BEGIN
			UPDATE Vendor SET IsUpdated = 1 WHERE VendorId = @ReferenceId AND MasterCompanyId = @MasterCompanyId;
		END

		IF(ISNULL(@IntegrationTypeId, 0) = 1 AND @ModuleId = @InvModuleId AND @WOModuleId = @ReferenceModuleId) 
		BEGIN
			--UPDATE [dbo].[WorkOrderBillingInvoicing] SET IsUpdated = 1 WHERE BillingInvoicingId = @ReferenceId AND MasterCompanyId = @MasterCompanyId;
			  UPDATE [dbo].[BillingInvoicing] SET [IsUpdated] = 1 WHERE [BillingInvoicingId] = @ReferenceId AND [MasterCompanyId] = @MasterCompanyId;
		END

		IF(ISNULL(@IntegrationTypeId, 0) = 1 AND @ModuleId = @InvModuleId AND @SOModuleId = @ReferenceModuleId) 
		BEGIN
			--UPDATE [dbo].[SalesOrderBillingInvoicing] SET IsUpdated = 1 WHERE SOBillingInvoicingId = @ReferenceId AND MasterCompanyId = @MasterCompanyId;		
			UPDATE [dbo].[BillingInvoicing] SET IsUpdated = 1 WHERE BillingInvoicingId = @ReferenceId AND MasterCompanyId = @MasterCompanyId;
		END

		IF(ISNULL(@IntegrationTypeId, 0) = 1 AND @ModuleId = @InvModuleId AND @ExchModuleId = @ReferenceModuleId) 
		BEGIN
			UPDATE [dbo].[ExchangeSalesOrderBillingInvoicing] SET IsUpdated = 1 WHERE SOBillingInvoicingId = @ReferenceId AND MasterCompanyId = @MasterCompanyId;		
		END

		IF(ISNULL(@IntegrationTypeId, 0) = 1 AND @ModuleId = @BillModuleId AND @NonPOModuleId = @ReferenceModuleId) 
		BEGIN
			UPDATE [dbo].[NonPOInvoiceHeader] SET IsUpdated = 1 WHERE NonPOInvoiceId = @ReferenceId AND MasterCompanyId = @MasterCompanyId;				
		END

		IF(ISNULL(@IntegrationTypeId, 0) = 1 AND @ModuleId = @CustomerPaymentModuleId) 
		BEGIN
			UPDATE [dbo].[CustomerPaymentDetails] SET IsUpdated = 1 WHERE ReceiptId = @ReferenceId AND MasterCompanyId = @MasterCompanyId;
		END

		IF(ISNULL(@IntegrationTypeId, 0) = 1 AND @ModuleId = @CreditTermModuleId) 
		BEGIN
			UPDATE [dbo].[CreditTerms] SET IsUpdated = 1 WHERE CreditTermsId = @ReferenceId AND MasterCompanyId = @MasterCompanyId;
		END

		IF(ISNULL(@IntegrationTypeId, 0) = 1 AND @ModuleId = @POModuleId AND @PurchaseOrderModuleId = @ReferenceModuleId) 
		BEGIN
			UPDATE [dbo].[PurchaseOrder] SET IsUpdated = 1 WHERE PurchaseOrderId = @ReferenceId AND MasterCompanyId = @MasterCompanyId;
		END

		IF(ISNULL(@IntegrationTypeId, 0) = 1 AND @ModuleId = @POModuleId AND @RepairOrderModuleId = @ReferenceModuleId) 
		BEGIN
			UPDATE [dbo].[RepairOrder] SET IsUpdated = 1 WHERE RepairOrderId = @ReferenceId AND MasterCompanyId = @MasterCompanyId;
		END

		IF(ISNULL(@IntegrationTypeId, 0) = 1 AND @ModuleId = @ItemModuleId) 
		BEGIN
			UPDATE [dbo].[ItemMaster] SET IsUpdated = 1 WHERE ItemMasterId = @ReferenceId AND MasterCompanyId = @MasterCompanyId;
		END

		--IF(ISNULL(@IntegrationTypeId, 0) = 1 AND @ModuleId = @CreditTermModuleId) 
		--BEGIN
		--	UPDATE [dbo].[CommonBatchDetails] SET IsUpdated = 1 WHERE CommonJournalBatchDetailId = @ReferenceId AND MasterCompanyId = @MasterCompanyId;
		--END

		IF(ISNULL(@IntegrationTypeId, 0) = 1 AND @ModuleId = @CreditMemoModuleId) 
		BEGIN
			UPDATE [dbo].[CreditMemo] SET IsUpdated = 1 WHERE CreditMemoHeaderId = @ReferenceId AND MasterCompanyId = @MasterCompanyId;
		END

	END TRY    
	BEGIN CATCH      

	         DECLARE @ErrorLogID INT
			,@DatabaseName VARCHAR(100) = db_name()
			-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
			,@AdhocComments VARCHAR(150) = 'QuickBooks_UpdateModuleReferenceDetails'
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