/*************************************************************           
 ** File:   [QuickBooks_GetSyncPendingCashReceiptList_ById]           
 ** Author:   Devendra Shekh
 ** Description: Get Cash Receipt List to Create Payment in QuickBooks By Id   
 ** Purpose:         
 ** Date:   20-Jan-2025        
         
 ** RETURN VALUE: 
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date			Author					Change Description            
 ** --   --------		-------					--------------------------------          
    1   2-Jan-2025		Devendra Shekh			Created
     
 EXECUTE [QuickBooks_GetSyncPendingCashReceiptList_ById] 1, 1, 510
**************************************************************/ 
CREATE   PROCEDURE [dbo].[QuickBooks_GetSyncPendingCashReceiptList_ById]
	@IntegrationTypeId INT = NULL,
	@MasterCompanyId INT = NULL,
	@ReferenceId BIGINT = NULL
AS
BEGIN
	
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED	
	BEGIN TRY

		DECLARE @WOInvoiceType INT = 2, @SOInvoiceType INT = 1, @ExchInvoiceType INT = 6;
		DECLARE @InvPaymentType VARCHAR(20) = 'Invoice';
		DECLARE @CMPaymentType VARCHAR(20) = 'CreditMemo';
		DECLARE @CheckPMId VARCHAR(200), @CreditCardPMId VARCHAR(200), @WirePMId VARCHAR(200); 

		SELECT @CheckPMId = [QuickBooksReferenceId] FROM [dbo].[PaymentMethod] WITH(NOLOCK) WHERE UPPER([Description]) = 'CHECK';
		SELECT @WirePMId = [QuickBooksReferenceId] FROM [dbo].[PaymentMethod] WITH(NOLOCK) WHERE UPPER([Description]) = 'DOMESTIC WIRE';
		SELECT @CreditCardPMId = [QuickBooksReferenceId] FROM [dbo].[PaymentMethod] WITH(NOLOCK) WHERE UPPER([Description]) = 'CREDIT CARD';

		IF OBJECT_ID('tempdb..#CashReceiptDetails') IS NOT NULL
			DROP TABLE #CashReceiptDetails

		CREATE TABLE #CashReceiptDetails
		(
			[Id] BIGINT IDENTITY(1,1) NOT NULL,
			[ReceiptId] BIGINT NULL,
			[CustomerPaymentDetailsId] BIGINT NULL,
			[BillingInvoicingId] BIGINT NULL,
			[InvoiceType] INT NULL,
			[CntrlNum] VARCHAR(100) NULL,
			[Amount] DECIMAL(9,2) NULL,
			[AmountRem] DECIMAL(9,2) NULL,
			[PaymentAmount] DECIMAL(9,2) NULL,
			[CustomerQuickBooksReferenceId] VARCHAR(200) NULL,
			[InvoiceQuickBooksReferenceId] VARCHAR(200) NULL,
			[PaymentType] VARCHAR(200) NULL,
			[QuickBooksReferenceId] VARCHAR(200) NULL,
			[SyncToken] VARCHAR(200) NULL,
			[MasterCompanyId] INT NULL,
			[UpdatedBy] VARCHAR(256) NULL,
			[IsMultiplePaymentMethod] BIT NULL,
			[IsCheckPayment] BIT NULL,
			[IsWireTransfer] BIT NULL,
			[IsCCDCPayment] BIT NULL,
			[PaymentMethodRef] VARCHAR(200) NULL,
		)

		-- FOR QuickBooks
		IF(ISNULL(@IntegrationTypeId, 0) = 1) 
		BEGIN
			--Inserting Cash Receipt Data
			INSERT INTO #CashReceiptDetails ([ReceiptId], [CustomerPaymentDetailsId], [BillingInvoicingId], [InvoiceType], [CntrlNum], [Amount], [AmountRem], [PaymentAmount], [CustomerQuickBooksReferenceId], 
			[PaymentType], [QuickBooksReferenceId], [SyncToken], [MasterCompanyId], [UpdatedBy], [IsMultiplePaymentMethod], [IsCheckPayment], [IsWireTransfer], [IsCCDCPayment])
			SELECT	CP.ReceiptId,
					CPD.CustomerPaymentDetailsId,
					INV.SOBillingInvoicingId,
					INV.InvoiceType,
					CP.CntrlNum,
					ISNULL(CPD.Amount, 0),
					ISNULL(CPD.AmountRem, 0),
					ISNULL(INV.PaymentAmount, 0),
					ISNULL(C.QuickBooksReferenceId, 0),
					@CMPaymentType,
					ISNULL(CPD.QuickBooksReferenceId, 0),
					ISNULL(CPD.SyncToken, 0),
					CPD.MasterCompanyId,
					CPD.UpdatedBy,
					ISNULL(CPD.[IsMultiplePaymentMethod], 0),
					ISNULL(CPD.[IsCheckPayment], 0),
					ISNULL(CPD.[IsWireTransfer], 0),
					ISNULL(CPD.[IsCCDCPayment], 0)
			FROM [dbo].[CustomerPayments] CP WITH(NOLOCK) 
				LEFT JOIN [dbo].[CustomerPaymentDetails] CPD WITH(NOLOCK) ON CPD.ReceiptId = CP.ReceiptId
				LEFT JOIN [dbo].[Customer] C WITH(NOLOCK) ON C.CustomerId = CPD.CustomerId
				LEFT JOIN [dbo].[InvoicePayments] INV WITH(NOLOCK) ON INV.CustomerPaymentDetailsId = CPD.CustomerPaymentDetailsId
			WHERE ISNULL(CPD.QuickBooksReferenceId, 0) = 0 AND ISNULL(CPD.IsUpdated, 0) = 1 AND CP.MasterCompanyId = @MasterCompanyId AND CP.ReceiptId = @ReferenceId;

			UPDATE CRD
			SET	CRD.InvoiceQuickBooksReferenceId = WOBI.QuickBooksReferenceId, [PaymentType] = @InvPaymentType
			FROM #CashReceiptDetails CRD 
			LEFT JOIN [dbo].[WorkOrderBillingInvoicing] WOBI WITH(NOLOCK) ON WOBI.BillingInvoicingId = CRD.BillingInvoicingId AND CRD.InvoiceType = @WOInvoiceType
			WHERE CRD.InvoiceType = @WOInvoiceType;

			UPDATE CRD
			SET	CRD.InvoiceQuickBooksReferenceId = SOBI.QuickBooksReferenceId, [PaymentType] = @InvPaymentType
			FROM #CashReceiptDetails CRD 
			LEFT JOIN [dbo].[SalesOrderBillingInvoicing] SOBI WITH(NOLOCK) ON SOBI.SOBillingInvoicingId = CRD.BillingInvoicingId AND CRD.InvoiceType = @SOInvoiceType
			WHERE CRD.InvoiceType = @SOInvoiceType;

			UPDATE CRD
			SET	CRD.InvoiceQuickBooksReferenceId = SOBI.QuickBooksReferenceId, [PaymentType] = @InvPaymentType
			FROM #CashReceiptDetails CRD 
			LEFT JOIN [dbo].[ExchangeSalesOrderBillingInvoicing] SOBI WITH(NOLOCK) ON SOBI.SOBillingInvoicingId = CRD.BillingInvoicingId AND CRD.InvoiceType = @ExchInvoiceType
			WHERE CRD.InvoiceType = @ExchInvoiceType;

			UPDATE CRD
			SET	CRD.[PaymentMethodRef] =  CASE	WHEN CRD.IsMultiplePaymentMethod = 1 THEN	CASE WHEN CRD.IsCheckPayment = 1 THEN @CheckPMId WHEN CRD.IsWireTransfer = 1 THEN @WirePMId WHEN CRD.IsCCDCPayment = 1 THEN @CreditCardPMId END
																	WHEN CRD.IsCheckPayment = 1 THEN @CheckPMId
																	WHEN CRD.IsWireTransfer = 1 THEN @WirePMId
																	WHEN CRD.IsCCDCPayment = 1 THEN @CreditCardPMId END
			FROM #CashReceiptDetails CRD

			SELECT * FROM #CashReceiptDetails;
		END
	END TRY    
	BEGIN CATCH      

	         DECLARE @ErrorLogID INT
			,@DatabaseName VARCHAR(100) = db_name()
			-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
			,@AdhocComments VARCHAR(150) = 'QuickBooks_GetSyncPendingCashReceiptList_ById'
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