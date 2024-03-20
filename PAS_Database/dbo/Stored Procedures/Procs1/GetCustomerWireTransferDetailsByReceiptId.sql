﻿/*****************************************************************************     
** Author:  <Unknown>    
** Create date: <>    
** Description: <Get Customer WireTransferDetails ByReceiptId>    
    
EXEC [GetCustomerWireTransferDetailsByReceiptId]   
**********************   
** Change History   
**********************     

	  (mm/dd/yyyy)
** PR   Date			Author				Change Description    
** --   --------		-------				--------------------------------  
** 1					Unknown				created
** 2   03/20/2024		Devendra Shekh		added CustomerPaymentDetailsId

-- EXEC GetCustomerWireTransferDetailsByReceiptId 90,0,2
*****************************************************************************/  

CREATE   PROCEDURE [dbo].[GetCustomerWireTransferDetailsByReceiptId]
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
			SELECT [WireTransferId]
			  ,[ReceiptId]
			  ,[CustomerId]
			  ,[WireDate]
			  ,[Amount]
			  ,[CurrencyId]
			  ,[BankName]
			  ,[ReferenceNo]
			  ,[IMAD_OMADNo]
			  ,[BankAccount]
			  ,[GLAccountNumber]
			  ,[Memo]
			  ,[MasterCompanyId]
			  ,[CreatedBy]
			  ,[UpdatedBy]
			  ,[CreatedDate]
			  ,[UpdatedDate]
			  ,[IsActive]
			  ,[IsDeleted]
			  ,[PageIndex]
			  ,ISNULL(CustomerPaymentDetailsId, 0) AS CustomerPaymentDetailsId
	      FROM [dbo].[InvoiceWireTransferPayment] WITH (NOLOCK) WHERE ReceiptId = @ReceiptId ORDER BY PageIndex
		END
		IF(@Opr=2)
		BEGIN
			SELECT [WireTransferId]
			  ,[ReceiptId]
			  ,[CustomerId]
			  ,[WireDate]
			  ,[Amount]
			  ,[CurrencyId]
			  ,[BankName]
			  ,[ReferenceNo]
			  ,[IMAD_OMADNo]
			  ,[BankAccount]
			  ,[GLAccountNumber]
			  ,[Memo]
			  ,[MasterCompanyId]
			  ,[CreatedBy]
			  ,[UpdatedBy]
			  ,[CreatedDate]
			  ,[UpdatedDate]
			  ,[IsActive]
			  ,[IsDeleted]
			  ,[PageIndex]
			  ,ISNULL(CustomerPaymentDetailsId, 0) AS CustomerPaymentDetailsId
	      FROM [dbo].[InvoiceWireTransferPayment] WITH (NOLOCK) WHERE ReceiptId = @ReceiptId AND PageIndex=@PageIndex;
		END
	END TRY    
		BEGIN CATCH
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'GetCustomerWireTransferDetailsByReceiptId' 
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