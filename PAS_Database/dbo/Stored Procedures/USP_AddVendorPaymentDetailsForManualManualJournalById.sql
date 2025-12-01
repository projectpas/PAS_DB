/*************************************************************             
 ** File:   [USP_AddVendorPaymentDetailsForManualManualJournalById]             
 ** Author:   Moin Bloch
 ** Description: This stored procedure is used to Add  Vendor Payment Details for Manual Manual
 ** Date:   
         
 **************************************************************             
  ** Change History             
 **************************************************************             
 ** PR   Date         Author			Change Description              
 ** --   --------     -------			------------------------------ 
	1    26/11/2025   Moin Bloch		CREATED

EXEC [dbo].[USP_AddVendorPaymentDetailsForManualManualJournalById] 18
************************************************************************/
CREATE   PROCEDURE [dbo].[USP_AddVendorPaymentDetailsForManualManualJournalById]
@ManualJournalHeaderId BIGINT
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;
	BEGIN TRY
	BEGIN TRANSACTION
	BEGIN
			DECLARE @MSModuleId BIGINT = 0,@LegalEntityId BIGINT = 0;

			SELECT @MSModuleId = [ManagementStructureModuleId] FROM [dbo].[ManagementStructureModule] WITH(NOLOCK) WHERE [ModuleName]='ManualJournal'
			
			SELECT @LegalEntityId = MSL.[LegalEntityId]
			FROM [dbo].[AccountingManagementStructureDetails] AMD WITH(NOLOCK)
			INNER JOIN [dbo].[ManagementStructureLevel] MSL WITH(NOLOCK) ON AMD.[Level1Id] = MSL.[ID]
			WHERE [ReferenceID] = @ManualJournalHeaderId AND [ModuleID] = @MSModuleId;

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
						[CreatedDate],
						[UpdatedDate],
						[IsActive],
						[IsDeleted],
						[RemainingAmount],						
						[LegalEntityId],
						[ManualJournalHeaderId],
						[ManualJournalDetailsId]
						)
			     SELECT 0,
				        GETUTCDATE(),  
						MGD.[ReferenceId], 
						VE.[VendorName], 
						0, 
						NULL, 
						0, 
						UPPER(MG.[JournalNumber]), 
						MG.[FunctionalCurrencyId], 
						CU.[Code],
						0, 
						CASE WHEN MGD.[Credit] > 0 then MGD.[Credit] ELSE MGD.[Debit] END,
						0,  
						0, 
						0, 
						NULL, 
						0, 
						0, 
						CASE WHEN MGD.[Credit] > 0 then MGD.[Credit] ELSE MGD.[Debit] END,
						0, 
						CASE WHEN MGD.[Credit] > 0 then MGD.[Credit] ELSE MGD.[Debit] END,
						0, 
						0, 
						MG.[ManualJournalStatusId],
						MGS.[Name],
						MG.[MasterCompanyId], 
						MG.[CreatedBy], 
						MG.[UpdatedBy], 
						GETUTCDATE(), 
						GETUTCDATE(), 
						1, 
						0, 
						CASE WHEN MGD.[Credit] > 0 then MGD.[Credit] ELSE MGD.[Debit] END,
						@LegalEntityId,
						@ManualJournalHeaderId,
						MGD.[ManualJournalDetailsId]
				   FROM [dbo].[ManualJournalHeader] MG WITH(NOLOCK) 
				  INNER JOIN [dbo].[ManualJournalDetails] MGD WITH(NOLOCK) ON MG.[ManualJournalHeaderId] = MGD.[ManualJournalHeaderId]
				  INNER JOIN [dbo].[Currency] CU WITH(NOLOCK) ON CU.[CurrencyId] = MG.[FunctionalCurrencyId]
				  INNER JOIN [dbo].[Vendor] VE WITH(NOLOCK) ON MGD.[ReferenceId] = VE.[VendorId]	
				  INNER JOIN [dbo].[ManualJournalStatus] MGS WITH(NOLOCK) ON MG.[ManualJournalStatusId] = MGS.[ManualJournalStatusId]				   
				  WHERE MG.[ManualJournalHeaderId] = @ManualJournalHeaderId AND MGD.[ReferenceTypeId] = 2
    END
    COMMIT  TRANSACTION
    END TRY    
	BEGIN CATCH      
		IF @@trancount > 0
			PRINT 'ROLLBACK'
			ROLLBACK TRAN;
			DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            , @AdhocComments     VARCHAR(150)    = 'USP_AddVendorPaymentDetailsForManualManualJournalById'             
			, @ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@ManualJournalHeaderId, '') AS VARCHAR(100))  
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