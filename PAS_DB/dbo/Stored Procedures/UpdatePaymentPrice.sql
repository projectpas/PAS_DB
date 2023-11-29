/*************************************************************             
 ** File:   [SearchCustomerInvoicesByCustId]             
 ** Author:   Subhash Saliya
 ** Description: This stored procedure is used to Update Payment Price
 ** Purpose:           
 ** Date:   21/04/2023
         
 **************************************************************             
  ** Change History             
 **************************************************************             
 ** PR   Date         Author		 Change Description              
 ** --   --------     -------		 -------------------------------            
    1    21/04/2023   Subhash Saliya  Created
	2    02/10/2023   Moin Bloch      Formetted SP
 **************************************************************/
CREATE   PROCEDURE [dbo].[UpdatePaymentPrice]
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

		--SELECT @paymentAmt = (SUM(ISNULL(IC.Amount, 0)) + SUM(ISNULL(IW.Amount, 0)) + SUM(ISNULL(ICC.Amount, 0)))
		--FROM DBO.CustomerPayments C  WITH(NOLOCK)
		--LEFT JOIN (SELECT ReceiptId, SUM(PaymentAmount) PaymentAmount FROM DBO.InvoicePayments WITH(NOLOCK) WHERE ReceiptId = @ReceiptId  and isnull(IsDeleted,0)=0 GROUP BY ReceiptId) AS IPS ON IPS.ReceiptId = C.ReceiptId 
		--LEFT JOIN DBO.InvoiceCheckPayment IC WITH(NOLOCK) ON C.ReceiptId = IC.ReceiptId and isnull(IC.IsDeleted,0)=0
		--LEFT JOIN DBO.InvoiceWireTransferPayment IW WITH(NOLOCK) ON C.ReceiptId = IW.ReceiptId and isnull(IW.IsDeleted,0)=0
		--LEFT JOIN DBO.InvoiceCreditDebitCardPayment ICC WITH(NOLOCK) ON C.ReceiptId = ICC.ReceiptId and isnull(ICC.IsDeleted,0)=0
		--LEFT JOIN (SELECT ReceiptId, SUM(Amount) Amount FROM DBO.CustomerOverDuePayment WITH(NOLOCK) WHERE ReceiptId = @ReceiptId and isnull(IsDeleted,0)=0 GROUP BY ReceiptId)
		--AS ICN ON ICN.ReceiptId = C.ReceiptId
		--Where C.ReceiptId = @ReceiptId
		--GROUP BY IPS.PaymentAmount,ICN.Amount

		SELECT @paymentAmt = SUM(ISNULL(Amount, 0)) 
		  FROM [dbo].[CustomerPaymentDetails] WITH(NOLOCK) 
		 WHERE [ReceiptId] = @ReceiptId AND ISNULL(IsDeleted,0) = 0;

		UPDATE [dbo].[CustomerPayments]
		   SET [AmtApplied] = (ABS(@paymentAmt)),
		       [UpdatedDate] = GETUTCDATE()
		 WHERE [ReceiptId] = @ReceiptId;

		UPDATE [dbo].[CustomerPayments]
		   SET [AmtRemaining] = [Amount] - [AmtApplied],
		       [UpdatedDate] = GETUTCDATE()
		 WHERE [ReceiptId] = @ReceiptId

		SELECT [ReceiptNo] AS 'value' 
		  FROM [dbo].[CustomerPayments] WITH(NOLOCK)
		 WHERE [ReceiptId] = @ReceiptId;
	END
	COMMIT  TRANSACTION

	END TRY    
	BEGIN CATCH      
		IF @@trancount > 0			
			ROLLBACK TRAN;
			DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            , @AdhocComments     VARCHAR(150)    = 'UpdatePaymentPrice' 
            , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ CAST(ISNULL(@ReceiptId, '') AS VARCHAR(100))  
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