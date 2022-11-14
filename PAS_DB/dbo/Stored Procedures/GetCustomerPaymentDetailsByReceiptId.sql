-- EXEC GetCustomerPaymentDetailsByReceiptId 90,0,2
CREATE PROCEDURE [dbo].[GetCustomerPaymentDetailsByReceiptId]
@ReceiptId BIGINT = NULL,
@PageIndex int = NULL,
@Opr int = NULL
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON
	BEGIN TRY
		IF(@Opr=1)
		BEGIN
			SELECT [CustomerPaymentDetailsId]
			  ,[ReceiptId]
			  ,[IsMultiplePaymentMethod]
			  ,[IsCheckPayment]
			  ,[IsWireTransfer]
			  ,[IsCCDCPayment]
			  ,[IsTradeReceivable]
			  ,[TradeReceivableORMiscReceiptGLAccnt]
			  ,[IsDeposite]
			  ,[PaymentMode]
			  ,[CustomerId]
			  ,[MasterCompanyId]
			  ,[CreatedBy]
			  ,[UpdatedBy]
			  ,[CreatedDate]
			  ,[UpdatedDate]
			  ,[IsActive]
			  ,[IsDeleted]
			  ,[PageIndex]
			  ,[CustomerCode]
			  ,[PaymentRef]
			  ,[Amount]
			  ,[AmountRem]
			  ,[Ismiscellaneous]
			  ,[AppliedAmount]
			  ,[InvoiceAmount]
			  ,[LegalEntityId]
			  ,[BankAcctNum]
			  ,[BankingId]
			  ,[Type]
	      FROM [dbo].[CustomerPaymentDetails] WITH (NOLOCK) WHERE ReceiptId = @ReceiptId ORDER BY PageIndex
		END
		IF(@Opr=2)
		BEGIN
			SELECT [CustomerPaymentDetailsId]
			  ,[ReceiptId]
			  ,[IsMultiplePaymentMethod]
			  ,[IsCheckPayment]
			  ,[IsWireTransfer]
			  ,[IsCCDCPayment]
			  ,[IsTradeReceivable]
			  ,[TradeReceivableORMiscReceiptGLAccnt]
			  ,[IsDeposite]
			  ,[PaymentMode]
			  ,[CustomerId]
			  ,[MasterCompanyId]
			  ,[CreatedBy]
			  ,[UpdatedBy]
			  ,[CreatedDate]
			  ,[UpdatedDate]
			  ,[IsActive]
			  ,[IsDeleted]
			  ,[PageIndex]
			  ,[CustomerCode]
			  ,[PaymentRef]
			  ,[Amount]
			  ,[AmountRem]
			  ,[Ismiscellaneous]
			  ,[AppliedAmount]
			  ,[InvoiceAmount]
			  ,[LegalEntityId]
			  ,[BankAcctNum]
			  ,[BankingId]
			  ,[Type]
	      FROM [dbo].[CustomerPaymentDetails] WITH (NOLOCK) WHERE ReceiptId = @ReceiptId AND PageIndex=@PageIndex;
		END
	END TRY    
		BEGIN CATCH
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'GetCustomerPaymentDetailsByReceiptId' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@ReceiptId, '') + ''
              , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
              exec spLogException 
                       @DatabaseName           = @DatabaseName
                     , @AdhocComments          = @AdhocComments
                     , @ProcedureParameters = @ProcedureParameters
                     , @ApplicationName        =  @ApplicationName
                     , @ErrorLogID             = @ErrorLogID OUTPUT;
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
              RETURN(1);
	END CATCH
END