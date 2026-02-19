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
	2    07/05/2025   Amit Ghediya		add LegalEntityId
	3    26/01/2026   Rajesh Gami		Fixed [DueDate] issue. 
	4    19/02/2026   Amit Ghediya		add invoice num instance of nponum (PN-15520)
EXEC [dbo].[USP_AddVendorPaymentDetailsForNonPOById] 5
************************************************************************/
CREATE    PROCEDURE [dbo].[USP_AddVendorPaymentDetailsForNonPOById]
@NonPOInvoiceId BIGINT
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;
	BEGIN TRY
	BEGIN TRANSACTION
	BEGIN
			DECLARE @moduleId BIGINT = 0,
			@LEId BIGINT = 0;

			SELECT @moduleId = [ManagementStructureModuleId] FROM [dbo].[ManagementStructureModule] WITH(NOLOCK) WHERE ModuleName='NonPOInvoiceHeader'

			SELECT 
				@LEId = MSL.[LegalEntityId]
			FROM [dbo].[NonPOInvoiceManagementStructureDetails] NONS WITH(NOLOCK)
			INNER JOIN [dbo].[ManagementStructureLevel] MSL WITH(NOLOCK) ON NONS.Level1Id = MSL.ID
			WHERE ReferenceID = @NonPOInvoiceId AND ModuleID = @moduleId;

			INSERT INTO [dbo].[VendorPaymentDetails]
				       ([ReadyToPayId], [DueDate], [VendorId], [VendorName], [PaymentMethodId], [PaymentMethodName], [ReceivingReconciliationId], [InvoiceNum], [CurrencyId], [CurrencyName],
						[FXRate], [OriginalAmount], [PaymentMade], [AmountDue], [DaysPastDue], [DiscountDate], [DiscountAvailable], [DiscountToken], [OriginalTotal], [RRTotal], [InvoiceTotal],
						[DIfferenceAmount], [TotalAdjustAmount], [StatusId], [Status], [MasterCompanyId], [CreatedBy], [UpdatedBy], [CreatedDate],[UpdatedDate],[IsActive],[IsDeleted],[RemainingAmount],
						[NonPOInvoiceId],[LegalEntityId])
			     SELECT 0, NPH.DueDate, [VendorId], [VendorName], 0, NULL, 0, NPH.[InvoiceNumber], NPH.[CurrencyId], CU.[Code],
						0, part.ExtendedPrice, 0, 0, 0, NULL, 0, 0, part.ExtendedPrice, 0, part.ExtendedPrice,
						0, 0,  [StatusId], NPHS.[Description], NPH.[MasterCompanyId], NPH.[CreatedBy], NPH.[UpdatedBy], GETUTCDATE(), GETUTCDATE(), NPH.[IsActive], NPH.[IsDeleted], part.ExtendedPrice,
						@NonPOInvoiceId,@LEId
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