-- =============================================
-- Author:		<Subhash Saliya>
-- Create date: <21/04/2023>
-- Description:	<Delete Case Reciept data>
-- =============================================
Create   PROCEDURE [dbo].[USP_RemoveCustomerPaymentDetails]
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
		DECLARE @paymentAmt DECIMAL(20, 2)
		DECLARE @remPaymentAmt DECIMAL(20, 2)

		update CustomerPaymentDetails set IsDeleted=1 where ReceiptId= @ReceiptId and  CustomerPaymentDetailsId  not IN (SELECT value FROM String_split(ISNULL(@CustomerPaymentDetailsId,0), ','))

		update InvoicePayments set IsDeleted=1 where  ReceiptId= @ReceiptId and PaymentId  not IN (SELECT value FROM String_split(ISNULL(@PaymentId,0), ','))
		
		update InvoiceCheckPayment set IsDeleted=1 where  ReceiptId= @ReceiptId and CheckPaymentId  not IN (SELECT value FROM String_split(ISNULL(@CheckPaymentId,0), ','))

		update InvoiceWireTransferPayment set IsDeleted=1 where  ReceiptId= @ReceiptId and WireTransferId  not IN (SELECT value FROM String_split(ISNULL(@WireTransferId,0), ','))

		update InvoiceCreditDebitCardPayment set IsDeleted=1 where  ReceiptId= @ReceiptId and CreditDebitPaymentId  not IN (SELECT value FROM String_split(ISNULL(@CreditDebitPaymentId,0), ','))
		
		SELECT ReceiptNo as 'value' FROM DBO.CustomerPayments WITH(NOLOCK) Where ReceiptId = @ReceiptId
	END
	COMMIT  TRANSACTION

	END TRY    
	BEGIN CATCH      
		IF @@trancount > 0
			PRINT 'ROLLBACK'
			ROLLBACK TRAN;
			DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            , @AdhocComments     VARCHAR(150)    = 'UpdatePaymentPrice' 
            , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@ReceiptId, '') + ''
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