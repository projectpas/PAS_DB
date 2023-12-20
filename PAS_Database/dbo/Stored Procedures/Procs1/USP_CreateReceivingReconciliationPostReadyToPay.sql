/*************************************************************             
 ** File:   [USP_CreateReceivingReconciliationPostReadyToPays]             
 ** Author:   
 ** Description: This stored procedure is used to Add  Vendor Payment Details
 ** Date:   
         
 **************************************************************             
  ** Change History             
 **************************************************************             
 ** PR   Date         Author		Change Description              
 ** --   --------     -------		------------------------------- 
    1    unknown                    Created 
	2    09/10/2023   Moin Bloch    Formetted SP 

EXEC [dbo].[USP_CreateReceivingReconciliationPostReadyToPay] 10023,0
************************************************************************/
CREATE   PROCEDURE [dbo].[USP_CreateReceivingReconciliationPostReadyToPay]
@ReceivingReconciliationId bigint,
@BatchId BIGINT OUTPUT
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;
	BEGIN TRY
	BEGIN TRANSACTION
	BEGIN
			INSERT INTO [dbo].[VendorPaymentDetails]
				       ([ReadyToPayId],
					    [DueDate],
						[VendorId],
						[VendorName],
						[PaymentMethodId],
						[PaymentMethodName],
						[ReceivingReconciliationId],
						[InvoiceNum],
						[CurrencyId],
						[CurrencyName],
						[FXRate],
				        [OriginalAmount],
						[PaymentMade],
						[AmountDue],
						[DaysPastDue],
						[DiscountDate],
						[DiscountAvailable],
						[DiscountToken],
						[OriginalTotal],
						[RRTotal],
						[InvoiceTotal],
						[DIfferenceAmount],
						[TotalAdjustAmount],
						[StatusId],
						[Status],
						[MasterCompanyId],
						[CreatedBy],
						[UpdatedBy],
						[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted],[RemainingAmount])
			     SELECT 0,
				        [OpenDate],
				        [VendorId],
						[VendorName],
						0,
						NULL,
						@ReceivingReconciliationId,
						[InvoiceNum],
						[CurrencyId],
						[CurrencyName],
						0,
						[InvoiceTotal],
						0,
						0,
						0,
						NULL,
						0,
						0,
						[OriginalTotal],
						[RRTotal],
						[InvoiceTotal],
						[DIfferenceAmount],
						[TotalAdjustAmount],
			            [StatusId],
						[Status],
						[MasterCompanyId],
						[CreatedBy],
						[UpdatedBy],
						[CreatedDate],
						[UpdatedDate],
						[IsActive],
						[IsDeleted],
						[InvoiceTotal] 
				   FROM [dbo].[ReceivingReconciliationHeader] WITH(NOLOCK) 
				  WHERE [ReceivingReconciliationId] = @ReceivingReconciliationId;
			
			SET @BatchId = @ReceivingReconciliationId;			
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