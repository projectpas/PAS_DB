-- =============================================
-- Author:		<Subhash Saliya>
-- Create date: <21/04/2023>
-- Description:	<Delete Case Reciept data>
-- 1   27/06/2025   Moin Bloch	Format SP
-- =============================================
CREATE   PROCEDURE [dbo].[USP_RemoveCustomerPaymentDetails]
    @CustomerPaymentDetailsId varchar(200) = null,
	@PaymentId varchar(200) = null,
	@CheckPaymentId varchar(200) = null,
	@WireTransferId varchar(200) = null,
	@CreditDebitPaymentId varchar(200)= null ,
	@ReceiptId BIGINT = NULL
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;

	BEGIN TRY
	BEGIN TRANSACTION
	BEGIN
		DECLARE @paymentAmt DECIMAL(20, 2) = 0
		DECLARE @remPaymentAmt DECIMAL(20, 2) = 0

		UPDATE [dbo].[CustomerPaymentDetails] SET [IsDeleted]=1 WHERE [ReceiptId]= @ReceiptId AND [CustomerPaymentDetailsId] NOT IN (SELECT value FROM STRING_SPLIT(ISNULL(@CustomerPaymentDetailsId,0), ','))

		UPDATE [dbo].[InvoicePayments] SET [IsDeleted]=1 WHERE  [ReceiptId]= @ReceiptId AND [PaymentId] NOT IN (SELECT value FROM STRING_SPLIT(ISNULL(@PaymentId,0), ','))
		
		UPDATE [dbo].[InvoiceCheckPayment] SET [IsDeleted]=1 WHERE  [ReceiptId]= @ReceiptId AND [CheckPaymentId] NOT IN (SELECT value FROM STRING_SPLIT(ISNULL(@CheckPaymentId,0), ','))

		UPDATE [dbo].[InvoiceWireTransferPayment] SET [IsDeleted]=1 WHERE  [ReceiptId]= @ReceiptId AND [WireTransferId] NOT IN (SELECT value FROM STRING_SPLIT(ISNULL(@WireTransferId,0), ','))

		UPDATE [dbo].[InvoiceCreditDebitCardPayment] SET [IsDeleted]=1 WHERE  [ReceiptId]= @ReceiptId AND [CreditDebitPaymentId] NOT IN (SELECT value FROM STRING_SPLIT(ISNULL(@CreditDebitPaymentId,0), ','))
		
		SELECT ReceiptNo AS 'value' FROM [dbo].[CustomerPayments] WITH(NOLOCK) WHERE [ReceiptId] = @ReceiptId
	END
	COMMIT  TRANSACTION

	END TRY    
	BEGIN CATCH      
		IF @@trancount > 0
			PRINT 'ROLLBACK'
			ROLLBACK TRAN;
			DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            , @AdhocComments     VARCHAR(150)    = 'USP_RemoveCustomerPaymentDetails'            
			, @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(CAST(@ReceiptId AS VARCHAR(10)), '') + ''      
            , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
            exec spLogException 
                    @DatabaseName           = @DatabaseName
                    , @AdhocComments          = @AdhocComments
                    , @ProcedureParameters = @ProcedureParameters
                    , @ApplicationName        =  @ApplicationName
                    , @ErrorLogID                    = @ErrorLogID OUTPUT ;
            RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
            RETURN(1);
	END CATCH
END