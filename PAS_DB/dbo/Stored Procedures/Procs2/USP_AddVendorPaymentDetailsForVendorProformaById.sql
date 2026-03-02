/*************************************************************             
 ** File:   [USP_AddVendorPaymentDetailsForVendorProformaById]             
 ** Author:   Rajesh Gami
 ** Description: This stored procedure is used to Add  Vendor Payment Details for Vendor Proforma
 ** Date: 23-Dec-2024  
         
 **************************************************************             
  ** Change History             
 **************************************************************             
 ** PR   Date          Author			Change Description              
 ** --   --------      -------			------------------------------ 
	1    23-Dec-2024   Rajesh Gami		CREATED
	2    24-Dec-2024   Rajesh Gami		Added VendorProformaInvoiceId into the VendorPaymentDetails
	3    28/05/2025    Amit Ghediya		add LegalEntityId
	4    02/03/2026    Amit Ghediya		Updated Due date (PN-15622)

EXEC [dbo].[USP_AddVendorPaymentDetailsForVendorProformaById] 5
************************************************************************/
CREATE     PROCEDURE [dbo].[USP_AddVendorPaymentDetailsForVendorProformaById]
@VendorProformaInvoiceId BIGINT
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;
	BEGIN TRY
	BEGIN TRANSACTION
	BEGIN

			DECLARE @moduleId BIGINT = 0,
			@LEId BIGINT = 0;

			SELECT @moduleId = [ManagementStructureModuleId] FROM [dbo].[ManagementStructureModule] WITH(NOLOCK) WHERE ModuleName='VendorProformaInvoice'

			SELECT 
				@LEId = MSL.[LegalEntityId]
			FROM [dbo].[NonPOInvoiceManagementStructureDetails] NONS WITH(NOLOCK)
			INNER JOIN [dbo].[ManagementStructureLevel] MSL WITH(NOLOCK) ON NONS.Level1Id = MSL.ID
			WHERE ReferenceID = @VendorProformaInvoiceId AND ModuleID = @moduleId;


			INSERT INTO [dbo].[VendorPaymentDetails]
				       ([ReadyToPayId], [DueDate], [VendorId], [VendorName], [PaymentMethodId], [PaymentMethodName], [ReceivingReconciliationId], [InvoiceNum], [CurrencyId], [CurrencyName],
						[FXRate], [OriginalAmount], [PaymentMade], [AmountDue], [DaysPastDue], [DiscountDate], [DiscountAvailable], [DiscountToken], [OriginalTotal], [RRTotal], [InvoiceTotal],
						[DIfferenceAmount], [TotalAdjustAmount], [StatusId], [Status], [MasterCompanyId], [CreatedBy], [UpdatedBy], [CreatedDate],[UpdatedDate],[IsActive],[IsDeleted],[RemainingAmount],
						[VendorProformaInvoiceId],[LegalEntityId])
			     SELECT 0, DATEADD(DAY,ISNULL(CTM.NetDays,0),CAST([InvoiceDate] AS DATE)), VE.[VendorId] , VE.[VendorName], 0, NULL, 0, VPH.VendorProformaInvoiceNo, VPH.[CurrencyId], CU.[Code],
						0, part.ExtendedPrice, 0, 0, 0, NULL, 0, 0, part.ExtendedPrice, 0, part.ExtendedPrice,
						0, 0,  [StatusId], NPHS.[Description], VPH.[MasterCompanyId], VPH.[CreatedBy], VPH.[UpdatedBy], GETUTCDATE(), GETUTCDATE(), VPH.[IsActive], VPH.[IsDeleted], part.ExtendedPrice,
						@VendorProformaInvoiceId,@LEId
				   FROM [dbo].[VendorProformaInvoiceHeader] VPH WITH(NOLOCK) 
				   INNER JOIN [dbo].[VendorProformaInvoiceHeaderStatus] NPHS WITH(NOLOCK) ON NPHS.[VendorProformaInvoiceHeaderStatusId] = VPH.[StatusId]
				   INNER JOIN [dbo].[Currency] CU WITH(NOLOCK) ON CU.[CurrencyId] = VPH.[CurrencyId]
				   INNER JOIN [dbo].[Vendor] VE WITH(NOLOCK) ON VPH.[VendorId] = VE.[VendorId] 	
				   LEFT JOIN [dbo].[CreditTerms] CTM WITH(NOLOCK) ON CTM.[CreditTermsId] = VE.[CreditTermsId]
				   OUTER APPLY (SELECT VD.VendorProformaInvoiceId,
									   SUM(ISNULL(VD.ExtendedPrice,0)) ExtendedPrice
								FROM [dbo].VendorProformaInvoicePartDetails VD WITH(NOLOCK) 
								WHERE VD.VendorProformaInvoiceId = VPH.VendorProformaInvoiceId
					GROUP BY VD.VendorProformaInvoiceId) AS part
				  WHERE VPH.VendorProformaInvoiceId = @VendorProformaInvoiceId;
    END
    COMMIT  TRANSACTION
    END TRY    
	BEGIN CATCH      
		IF @@trancount > 0
			PRINT 'ROLLBACK'
			ROLLBACK TRAN;
			DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            , @AdhocComments     VARCHAR(150)    = 'USP_AddVendorPaymentDetailsForVendorProformaById' 
            , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@VendorProformaInvoiceId, '') + ''
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