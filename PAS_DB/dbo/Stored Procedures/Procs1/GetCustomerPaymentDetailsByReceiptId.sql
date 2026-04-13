/*************************************************************           
 ** File:   [GetCustomerPaymentDetailsByReceiptId]           
 ** Author:   Moin Bloch
 ** Description: This SP is used retrieve Customer Payment Details
 ** Purpose:         
 ** Date:   06/24/2022     
          
 ** PARAMETERS:     

 ** RETURN VALUE:   
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    09/04/2026   Moin Bloch    Added New Field [IsNonInvoicePayment] PN-15989

-- EXEC GetCustomerPaymentDetailsByReceiptId 146,0,1
**************************************************************/
CREATE   PROCEDURE [dbo].[GetCustomerPaymentDetailsByReceiptId]
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
			  ,ISNULL([IsNonInvoicePayment],0) [IsNonInvoicePayment]
	      FROM [dbo].[CustomerPaymentDetails] WITH (NOLOCK) WHERE ReceiptId = @ReceiptId AND IsDeleted=0 ORDER BY PageIndex
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
			  ,ISNULL([IsNonInvoicePayment],0) [IsNonInvoicePayment]
	      FROM [dbo].[CustomerPaymentDetails] WITH (NOLOCK) WHERE ReceiptId = @ReceiptId AND IsDeleted = 0 AND PageIndex=@PageIndex;
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