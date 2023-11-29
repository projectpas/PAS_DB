/*************************************************************             
 ** File:   [USP_AddVendorPaymentDetailsForNonPOById]             
 ** Author:   Devendra Shekh
 ** Description: This stored procedure is used to Add  Vendor Payment Details for nonPO
 ** Date:   
         
 **************************************************************             
  ** Change History             
 **************************************************************             
 ** PR   Date         Author			Change Description              
 ** --   --------     -------			------------------------------ 
	1    02/11/2023   Devendra Shekh		created

EXEC [dbo].[USP_AddVendorPaymentDetailsForNonPOById] 5
************************************************************************/
CREATE   PROCEDURE [dbo].[USP_AddVendorPaymentDetailsForNonPOById]
@NonPOInvoiceId BIGINT
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;
	BEGIN TRY
	BEGIN TRANSACTION
	BEGIN
			INSERT INTO [dbo].[VendorPaymentDetails]
				       ([ReadyToPayId], [DueDate], [VendorId], [VendorName], [PaymentMethodId], [PaymentMethodName], [ReceivingReconciliationId], [InvoiceNum], [CurrencyId], [CurrencyName],
						[FXRate], [OriginalAmount], [PaymentMade], [AmountDue], [DaysPastDue], [DiscountDate], [DiscountAvailable], [DiscountToken], [OriginalTotal], [RRTotal], [InvoiceTotal],
						[DIfferenceAmount], [TotalAdjustAmount], [StatusId], [Status], [MasterCompanyId], [CreatedBy], [UpdatedBy], [CreatedDate],[UpdatedDate],[IsActive],[IsDeleted],[RemainingAmount],
						[NonPOInvoiceId])
			     SELECT 0, GETUTCDATE(),  [VendorId], [VendorName], 0, NULL, 0, NPH.[NPONumber], NPH.[CurrencyId], CU.[Code],
						0, part.ExtendedPrice, 0, 0, 0, NULL, 0, 0, part.ExtendedPrice, 0, part.ExtendedPrice,
						0, 0,  [StatusId], NPHS.[Description], NPH.[MasterCompanyId], NPH.[CreatedBy], NPH.[UpdatedBy], GETUTCDATE(), GETUTCDATE(), NPH.[IsActive], NPH.[IsDeleted], part.ExtendedPrice,
						@NonPOInvoiceId
				   FROM [dbo].[NonPOInvoiceHeader] NPH WITH(NOLOCK) 
				   INNER JOIN [dbo].[NonPOInvoiceHeaderStatus] NPHS WITH(NOLOCK) ON NPHS.[NonPOInvoiceHeaderStatusId] = NPH.[StatusId]
				   INNER JOIN [dbo].[Currency] CU WITH(NOLOCK) ON CU.[CurrencyId] = NPH.[CurrencyId]
				   OUTER APPLY (SELECT VD.NonPOInvoiceId,
									   SUM(ISNULL(VD.ExtendedPrice,0)) ExtendedPrice
								FROM [dbo].[NonPOInvoicePartDetails] VD WITH(NOLOCK) 
								WHERE VD.NonPOInvoiceId = NPH.NonPOInvoiceId
					GROUP BY VD.NonPOInvoiceId) AS part
				  WHERE NPH.[NonPOInvoiceId] = @NonPOInvoiceId;
    END
    COMMIT  TRANSACTION
    END TRY    
	BEGIN CATCH      
		IF @@trancount > 0
			PRINT 'ROLLBACK'
			ROLLBACK TRAN;
			DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            , @AdhocComments     VARCHAR(150)    = 'USP_AddVendorPaymentDetailsForNonPOById' 
            , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@NonPOInvoiceId, '') + ''
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