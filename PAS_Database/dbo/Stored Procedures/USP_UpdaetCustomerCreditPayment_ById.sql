/*****************************************************************************     
** Author:  <Devendra Shekh>    
** Create date: <03/04/2024>    
** Description: <used to update Customer CreditPayment ById>    
    
EXEC [USP_UpdateCustomerCreditPayment_ById]   
**********************   
** Change History   
**********************     

	  (mm/dd/yyyy)
** PR   Date			Author				Change Description    
** --   --------		-------				--------------------------------  
** 1    03/08/2024		Devendra Shekh		created

*****************************************************************************/  
CREATE   PROCEDURE [dbo].[USP_UpdateCustomerCreditPayment_ById]
@CreditMemoHeaderId BIGINT,
@CustomerCreditPaymentDetailId BIGINT
AS
BEGIN	
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED	
	BEGIN TRY

		DECLARE @MEMO VARCHAR(500) = '',
		@CreditMemoNumber VARCHAR(50) = '';

		SELECT @CreditMemoNumber = CreditMemoNumber FROM [dbo].[CreditMemo] WITH(NOLOCK) WHERE [CreditMemoHeaderId] = @CreditMemoHeaderId;

		SET @MEMO = 'Created Stand Alone Credit Memo. CreditMemoNumber: ' + CAST(@CreditMemoNumber AS VARCHAR);

		UPDATE CCPD
		SET CCPD.[Memo] = @MEMO , CCPD.[StatusId] = 2
		FROM [dbo].[CustomerCreditPaymentDetail] CCPD WITH(NOLOCK)
		WHERE CCPD.[CustomerCreditPaymentDetailId] = @CustomerCreditPaymentDetailId;

	END TRY    
	BEGIN CATCH      
	         DECLARE @ErrorLogID INT
			,@DatabaseName VARCHAR(100) = db_name()
			-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
			,@AdhocComments VARCHAR(150) = 'USP_UpdateCustomerCreditPayment_ById'
			,@ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@CreditMemoHeaderId, '') AS varchar(100))
			   + '@Parameter2 = ''' + CAST(ISNULL(@CustomerCreditPaymentDetailId, '') AS varchar(100)) 
			   		                                           
			,@ApplicationName VARCHAR(100) = 'PAS'

		-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
		EXEC spLogException @DatabaseName = @DatabaseName
			,@AdhocComments = @AdhocComments
			,@ProcedureParameters = @ProcedureParameters
			,@ApplicationName = @ApplicationName
			,@ErrorLogID = @ErrorLogID OUTPUT;

		RAISERROR (
				'Unexpected Error Occured in the database. Please let the support team know of the error number : %d'
				,16
				,1
				,@ErrorLogID
				)

		RETURN (1);           
	END CATCH
END