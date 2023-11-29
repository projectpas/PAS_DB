/*************************************************************           
EXEC [dbo].[USP_CreateReceivingReconciliationPostReadyToPay] 'RPO',10023,0
************************************************************************/
CREATE PROCEDURE [dbo].[USP_CreateReceivingReconciliationPostReadyToPay]
--@JtypeCode varchar(50),
@ReceivingReconciliationId bigint,
@BatchId BIGINT OUTPUT
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;
	BEGIN TRY
	BEGIN TRANSACTION
	BEGIN
			--Select @MasterCompanyId=MasterCompanyId,@UpdateBy=CreatedBy from ReceivingReconciliationHeader where ReceivingReconciliationId = @ReceivingReconciliationId;

			INSERT INTO VendorPaymentDetails(ReadyToPayId,DueDate,VendorId,VendorName,PaymentMethodId,PaymentMethodName,ReceivingReconciliationId,InvoiceNum,CurrencyId,CurrencyName,FXRate,
				OriginalAmount,PaymentMade,AmountDue,DaysPastDue,DiscountDate,DiscountAvailable,DiscountToken,OriginalTotal,RRTotal,InvoiceTotal,DIfferenceAmount,TotalAdjustAmount,StatusId,[Status],MasterCompanyId,CreatedBy,UpdatedBy,CreatedDate,UpdatedDate,IsActive,IsDeleted,RemainingAmount)
			SELECT 0,OpenDate,VendorId,VendorName,0,NULL,@ReceivingReconciliationId,InvoiceNum,CurrencyId,CurrencyName,0,InvoiceTotal,0,0,0,NULL,0,0,OriginalTotal,RRTotal,InvoiceTotal,DIfferenceAmount,TotalAdjustAmount,
			StatusId,[Status],MasterCompanyId,CreatedBy,UpdatedBy,CreatedDate,UpdatedDate,IsActive,IsDeleted,InvoiceTotal FROM ReceivingReconciliationHeader WHERE ReceivingReconciliationId = @ReceivingReconciliationId;
			
			SET @BatchId = @ReceivingReconciliationId;
			print @BatchId

END
  COMMIT  TRANSACTION
    END TRY    
	BEGIN CATCH      
		IF @@trancount > 0
			PRINT 'ROLLBACK'
			ROLLBACK TRAN;
			DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            , @AdhocComments     VARCHAR(150)    = 'USP_CreateReceivingReconciliationPostReadyToPay' 
            , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@ReceivingReconciliationId, '') + ''
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