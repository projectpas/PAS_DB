-- EXEC GetCustomerOverDuePaymentDetailsByReceiptId 90,0,2
CREATE PROCEDURE [dbo].[GetCustomerOverDuePaymentDetailsByReceiptId]
@ReceiptId BIGINT = 29
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON
	BEGIN TRY
			SELECT [CustomerOverDuePaymentId]
			  ,codp.[ReceiptId]
			  ,[OverDueDate]
			  ,codp.[Reference]
			  ,[CheckNumber]
			  ,codp.[CustomerId]
			  ,[BankId]
			  ,le.[BankName]
			  ,le.[BankAccountNumber]
			  ,[GLAccountNumber]
			  ,codp.[CurrencyId]
			  ,[InvoiceAmount]
			  ,codp.[Amount]
			  ,codp.[Memo]
			  ,codp.[MasterCompanyId]
			  ,codp.[CreatedBy]
			  ,codp.[UpdatedBy]
			  ,codp.[CreatedDate]
			  ,codp.[UpdatedDate]
			  ,codp.[IsActive]
			  ,codp.[IsDeleted]
			  ,[PageIndex]
			  ,c.[Name] AS CustomerName
			  ,c.[CustomerCode]
			  ,r.[ReceiptNo]
			  ,lee.[Name] as 'GlAccountName'
			  ,cr.Code as 'CurrencyName'
			  ,codp.Ismiscellaneous
	      FROM [dbo].[CustomerOverDuePayment] codp WITH (NOLOCK) 
		  INNER JOIN Customer c on c.CustomerId = codp.CustomerId
		  INNER JOIN CustomerPayments r on r.ReceiptId = codp.ReceiptId
		  LEFT JOIN LegalEntityBankingLockBox le on le.LegalEntityBankingLockBoxId = codp.BankId
		  LEFT JOIN LegalEntity lee on lee.LegalEntityId = codp.GLAccountNumber
		  LEFT JOIN Currency cr on cr.CurrencyId = codp.CurrencyId
		  ORDER BY PageIndex
	END TRY    
		BEGIN CATCH
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'GetCustomerOverDuePaymentDetailsByReceiptId' 
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