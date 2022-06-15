-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[UpdatePaymentPrice]
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

		SELECT @paymentAmt = (SUM(ISNULL(IC.Amount, 0)) + SUM(ISNULL(IW.Amount, 0)) + SUM(ISNULL(ICC.Amount, 0)))
		, @remPaymentAmt = ((SUM(ISNULL(IC.Amount, 0)) + SUM(ISNULL(IW.Amount, 0)) + SUM(ISNULL(ICC.Amount, 0))) - (ISNULL(IPS.PaymentAmount, 0)))
		FROM DBO.CustomerPayments C  WITH(NOLOCK)
		LEFT JOIN (SELECT ReceiptId, SUM(PaymentAmount) PaymentAmount FROM DBO.InvoicePayments WITH(NOLOCK) WHERE ReceiptId = @ReceiptId GROUP BY ReceiptId) AS IPS ON IPS.ReceiptId = C.ReceiptId 
		LEFT JOIN DBO.InvoiceCheckPayment IC WITH(NOLOCK) ON C.ReceiptId = IC.ReceiptId
		LEFT JOIN DBO.InvoiceWireTransferPayment IW WITH(NOLOCK) ON C.ReceiptId = IW.ReceiptId
		LEFT JOIN DBO.InvoiceCreditDebitCardPayment ICC WITH(NOLOCK) ON C.ReceiptId = ICC.ReceiptId
		Where C.ReceiptId = @ReceiptId
		GROUP BY IPS.PaymentAmount

		Update DBO.CustomerPayments
		SET AmtApplied = (@paymentAmt - @remPaymentAmt),UpdatedDate=GETDATE()
		Where ReceiptId = @ReceiptId

		Update DBO.CustomerPayments
		SET AmtRemaining = Amount - AmtApplied,UpdatedDate=GETDATE()
		Where ReceiptId = @ReceiptId

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