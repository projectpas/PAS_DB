/*************************************************************             
 ** File:   [USP_AddVendorPaymentDetails_ForCustomerCreditPaymentDetailById]             
 ** Author:   Devendra Shekh
 ** Description: This stored procedure is used to Add  Vendor Payment Details for Customer Credit PaymentDetail
 ** Date:   
         
 **************************************************************             
  ** Change History             
 **************************************************************             
 ** PR   Date         Author			Change Description              
 ** --   --------     -------			------------------------------ 
	1    03/26/2024   Devendra Shekh		created

EXEC [dbo].[USP_AddVendorPaymentDetails_ForCustomerCreditPaymentDetailById] 5
************************************************************************/
CREATE   PROCEDURE [dbo].[USP_AddVendorPaymentDetails_ForCustomerCreditPaymentDetailById]
@CustomerCreditPaymentDetailId BIGINT,
@VendorId BIGINT,
@MasterCompanyId INT,
@UserName VARCHAR(50)
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;
	BEGIN TRY
	BEGIN TRANSACTION
	BEGIN
			
			DECLARE @DefaultMethodId INT = 0,
			@DefaultMethodName VARCHAR(250) = '';

			SELECT TOP 1  @DefaultMethodId = DefaultPaymentMethod FROM [dbo].[VendorPayment] WHERE VendorId = @VendorId ORDER BY VendorId DESC;
			SELECT @DefaultMethodName = [Description] FROM [dbo].[VendorPaymentMethod] WHERE VendorPaymentMethodId = @DefaultMethodId;

			INSERT INTO [dbo].[VendorPaymentDetails]
				       ([ReadyToPayId], [DueDate], [VendorId], [VendorName], [PaymentMethodId], [PaymentMethodName], [ReceivingReconciliationId], [InvoiceNum], [CurrencyId], [CurrencyName],
						[FXRate], [OriginalAmount], [PaymentMade], [AmountDue], [DaysPastDue], [DiscountDate], [DiscountAvailable], [DiscountToken], [OriginalTotal], [RRTotal], [InvoiceTotal],
						[DIfferenceAmount], [TotalAdjustAmount], [StatusId], [Status], [MasterCompanyId], [CreatedBy], [UpdatedBy], [CreatedDate],[UpdatedDate],[IsActive],[IsDeleted],[RemainingAmount],
						[NonPOInvoiceId], [CustomerCreditPaymentDetailId])
			     SELECT 0, GETUTCDATE(),  CCPD.[VendorId], V.[VendorName], @DefaultMethodId, @DefaultMethodName, 0, CCPD.SuspenseUnappliedNumber, V.[CurrencyId], CU.[Code],
						0, CCPD.RemainingAmount, 0, 0, 0, NULL, 0, 0, CCPD.RemainingAmount, 0, CCPD.RemainingAmount,
						0, 0,  CCPD.[StatusId], 'Processed', @MasterCompanyId, @UserName, @UserName, GETUTCDATE(), GETUTCDATE(), CCPD.[IsActive], CCPD.[IsDeleted], CCPD.RemainingAmount,
						0, @CustomerCreditPaymentDetailId
				   FROM [dbo].[CustomerCreditPaymentDetail] CCPD WITH(NOLOCK) 
					INNER JOIN [dbo].[Vendor] V WITH(NOLOCK) ON CCPD.VendorId = V.VendorId  
					LEFT JOIN [dbo].[Currency] CU WITH(NOLOCK) ON V.CurrencyId = CU.CurrencyId  
					WHERE CCPD.CustomerCreditPaymentDetailId = @CustomerCreditPaymentDetailId;
    END
    COMMIT  TRANSACTION
    END TRY    
	BEGIN CATCH      
		IF @@trancount > 0
			PRINT 'ROLLBACK'
			ROLLBACK TRAN;
			DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            , @AdhocComments     VARCHAR(150)    = 'USP_AddVendorPaymentDetails_ForCustomerCreditPaymentDetailById' 
            , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@CustomerCreditPaymentDetailId, '') + ''
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