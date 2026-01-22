/*************************************************************             
 ** File:   [USP_UpdateInvoicePayment]             
 ** Author:   Devendra Shekh
 ** Description: This stored procedure is used to Update [InvoicePayments]
 ** Purpose:           
 ** Date:   24/10/2024	[mm/dd/yyyy]
         
 **************************************************************             
  ** Change History             
 **************************************************************             
 ** PR   Date         Author			Change Description              
 ** --   --------     -------			-------------------------------            
    1    24/10/2023   Devendra Shekh	Created
 **************************************************************/
CREATE   PROCEDURE [dbo].[USP_UpdateInvoicePayment]
@PaymentId BIGINT = NULL,
@CustomerPaymentDetailsId BIGINT = NULL
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;

	BEGIN TRY
	BEGIN TRANSACTION
	BEGIN
		IF(ISNULL(@PaymentId, 0) > 0 AND ISNULL(@CustomerPaymentDetailsId, 0) > 0)
		BEGIN
			UPDATE INV SET INV.CustomerPaymentDetailsId = @CustomerPaymentDetailsId	FROM [dbo].[InvoicePayments] INV WHERE INV.PaymentId = @PaymentId AND ISNULL(INV.CustomerPaymentDetailsId, 0) = 0
		END
	END
	COMMIT  TRANSACTION
	END TRY    
	BEGIN CATCH      
		IF @@trancount > 0			
			ROLLBACK TRAN;
			DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            , @AdhocComments     VARCHAR(150)    = 'USP_UpdateInvoicePayment' 
            , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ CAST(ISNULL(@PaymentId, '') AS VARCHAR(100))  
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