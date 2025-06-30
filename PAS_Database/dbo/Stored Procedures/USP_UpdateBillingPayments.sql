/*************************************************************           
 ** File:   [UpdateBillingPayments]           
 ** Author:  Moin Bloch
 ** Description: This stored procedure is used to save asset depericiation data
 ** Purpose:         
 ** Date:   30/06/2025
 ** PARAMETERS: @BillingInvoicingId bigint
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date         Author		 Change Description            
 ** --   --------     -------		 --------------------------------          
    1    30/06/2025   Moin Bloch     Created
************************************************************************/
CREATE    PROCEDURE [dbo].[USP_UpdateBillingPayments] 
@BillingInvoicingId BIGINT = NULL,
@PaymentAmount DECIMAL(18,2) = NULL,
@DiscAmount DECIMAL(18,2) = NULL,
@BankFeeAmount DECIMAL(18,2) = NULL,
@OtherAdjustAmt DECIMAL(18,2) = NULL,
@OriginalAmount DECIMAL(18,2) = NULL,
@ModuleId INT = NULL,
@Opr INT = NULL
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;
	BEGIN TRY
	BEGIN TRANSACTION
	BEGIN	
		
		SET @PaymentAmount = ISNULL(@PaymentAmount, 0)
		SET @DiscAmount = ISNULL(@DiscAmount, 0)
		SET @BankFeeAmount = ISNULL(@BankFeeAmount, 0)
		SET @OtherAdjustAmt = ISNULL(@OtherAdjustAmt, 0)
		SET @OriginalAmount = ISNULL(@OriginalAmount, 0)		

		DECLARE @RemainingAmount DECIMAL = 0,@GrandTotal DECIMAL = 0,@CreditMemoUsed DECIMAL = 0

		IF(@Opr = 1)
		BEGIN		
			SELECT @RemainingAmount = ISNULL([RemainingAmount],0),
				   @GrandTotal = ISNULL([GrandTotal],0)		
			  FROM [dbo].[BillingInvoicing] WITH(NOLOCK) 
			 WHERE [BillingInvoicingId] = @BillingInvoicingId
			   
			UPDATE [dbo].[BillingInvoicing]
			   SET [RemainingAmount] = ISNULL(@RemainingAmount, 0) - (@PaymentAmount + @DiscAmount + @BankFeeAmount + @OtherAdjustAmt)		
			 WHERE [BillingInvoicingId] = @BillingInvoicingId

			 SELECT @RemainingAmount = ISNULL([RemainingAmount],0)		     
			  FROM [dbo].[BillingInvoicing] WITH(NOLOCK) 
			 WHERE [BillingInvoicingId] = @BillingInvoicingId


			UPDATE [dbo].[BillingInvoicing]
			   SET [DepositAmount] = CASE WHEN (ISNULL(@GrandTotal, 0) - ISNULL(@RemainingAmount,0)) < 0 THEN 0 ELSE ISNULL(@GrandTotal, 0) - ISNULL(@RemainingAmount,0) END
			 WHERE [BillingInvoicingId] = @BillingInvoicingId		
		END
		IF(@Opr = 2)
		BEGIN
			SELECT @CreditMemoUsed = ISNULL([CreditMemoUsed],0)				 
			  FROM [dbo].[BillingInvoicing] WITH(NOLOCK) 
			 WHERE [BillingInvoicingId] = @BillingInvoicingId

			UPDATE [dbo].[BillingInvoicing]
			   SET [CreditMemoUsed] = ISNULL(@CreditMemoUsed, 0) + ISNULL(@OriginalAmount,0)
			 WHERE [BillingInvoicingId] = @BillingInvoicingId
		END		
	END
	COMMIT  TRANSACTION
	END TRY    
	BEGIN CATCH      
		IF @@trancount > 0
			PRINT 'ROLLBACK'
                ROLLBACK TRAN;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            , @AdhocComments     VARCHAR(150)    = 'SaveAssetDeprciationData' 
            , @ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@BillingInvoicingId, '') AS VARCHAR(100))
            , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------

            exec spLogException 
                    @DatabaseName			= @DatabaseName
                    , @AdhocComments			= @AdhocComments
                    , @ProcedureParameters		= @ProcedureParameters
                    , @ApplicationName			=  @ApplicationName
                    , @ErrorLogID              = @ErrorLogID OUTPUT ;
            RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
            RETURN(1);
    END CATCH 
END