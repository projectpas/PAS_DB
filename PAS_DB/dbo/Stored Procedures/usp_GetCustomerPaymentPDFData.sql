/************************************
EXEC usp_GetCustomerPaymentPDFData 83
*************************************/ 
CREATE PROCEDURE [dbo].[usp_GetCustomerPaymentPDFData]
@ReceiptId BIGINT
AS
BEGIN
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
		BEGIN TRY
			BEGIN TRANSACTION
				BEGIN
					select DISTINCT cp.ReceiptId,ipy.SOBillingInvoicingId, icp.CheckPaymentId AS Id,ipy.CreatedDate AS 'CashApplyDate', ipy.DocNum AS 'InvoiceNumber',ipy.RemainingAmount AS 'RemainingAmount',
					ipy.PaymentAmount AS 'AmountPaid','Check' AS 'PaidMethod',ipy.CurrencyCode AS 'Currency', ipy.NewRemainingBal AS 'NewRemainingAmount',ct.[Name] AS 'CustomerName' from CustomerPayments cp WITH(NOLOCK)
					INNER JOIN InvoiceCheckPayment icp WITH(NOLOCK) on icp.ReceiptId = cp.ReceiptId
					INNER JOIN InvoicePayments ipy WITH(NOLOCK) on ipy.ReceiptId = cp.ReceiptId AND icp.CustomerId = ipy.CustomerId
					--LEFT JOIN Currency cr WITH(NOLOCK) ON cr.CurrencyId = icp.CurrencyId
					LEFT JOIN Customer ct WITH(NOLOCK) ON ct.CustomerId = icp.CustomerId
					where cp.ReceiptId=@ReceiptId 
					--group by cp.ReceiptId,ipy.SOBillingInvoicingId,icp.CheckPaymentId,ipy.CreatedDate,ipy.DocNum,ipy.RemainingAmount,ipy.PaymentAmount,ipy.CurrencyCode, ipy.NewRemainingBal,ct.[Name]
					UNION
					select DISTINCT cp.ReceiptId,ipy.SOBillingInvoicingId, iwp.WireTransferId AS Id,ipy.CreatedDate AS 'CashApplyDate',ipy.DocNum AS 'InvoiceNumber',ipy.RemainingAmount AS 'RemainingAmount',
					ipy.PaymentAmount AS 'AmountPaid','Wire Transfer' AS 'PaidMethod',ipy.CurrencyCode AS 'Currency',ipy.NewRemainingBal AS 'NewRemainingAmount',ct.[Name] AS 'CustomerName' from CustomerPayments cp WITH(NOLOCK)
					INNER JOIN InvoiceWireTransferPayment iwp WITH(NOLOCK) on iwp.ReceiptId = cp.ReceiptId
					INNER JOIN InvoicePayments ipy WITH(NOLOCK) on ipy.ReceiptId = cp.ReceiptId AND iwp.CustomerId = ipy.CustomerId
					--LEFT JOIN Currency cr WITH(NOLOCK) ON cr.CurrencyId = iwp.CurrencyId
					LEFT JOIN Customer ct WITH(NOLOCK) ON ct.CustomerId = iwp.CustomerId
					where cp.ReceiptId=@ReceiptId
					UNION
					select DISTINCT cp.ReceiptId,ipy.SOBillingInvoicingId, icdpp.CreditDebitPaymentId AS Id,ipy.CreatedDate AS 'CashApplyDate',ipy.DocNum AS 'InvoiceNumber',ipy.RemainingAmount AS 'RemainingAmount',
					ipy.PaymentAmount AS 'AmountPaid','Credit Card/Debit Card' AS 'PaidMethod',ipy.CurrencyCode AS 'Currency',ipy.NewRemainingBal AS 'NewRemainingAmount',ct.[Name] AS 'CustomerName' from CustomerPayments cp WITH(NOLOCK)
					INNER JOIN InvoiceCreditDebitCardPayment icdpp WITH(NOLOCK) on icdpp.ReceiptId = cp.ReceiptId
					INNER JOIN InvoicePayments ipy WITH(NOLOCK) on ipy.ReceiptId = cp.ReceiptId AND icdpp.CustomerId = ipy.CustomerId
					--LEFT JOIN Currency cr WITH(NOLOCK) ON cr.CurrencyId = icdpp.CurrencyId
					LEFT JOIN Customer ct WITH(NOLOCK) ON ct.CustomerId = icdpp.CustomerId
					where cp.ReceiptId=@ReceiptId;
				END
			COMMIT  TRANSACTION

		END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
				PRINT 'ROLLBACK'
                    ROLLBACK TRAN;
              DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'usp_GetCustomerPaymentPDFData' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''
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