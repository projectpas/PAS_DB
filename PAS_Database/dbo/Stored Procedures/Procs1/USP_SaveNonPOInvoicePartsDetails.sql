/*************************************************************           
 ** File:   [USP_SaveNonPOInvoicePartsDetails]           
 ** Author:   Devendra Shekh
 ** Description: Save NonPOInvoice Parts Details
 ** Purpose:         
 ** Date:   21st September 2023
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author					Change Description            
 ** --   --------     -------				--------------------------------          
    1    21-09-2023     Devendra Shekh			Created
	2	 26-10-2023		Devendra				added new columns  
	3	 11-01-2024		Moin Bloch		        Modified chaned Status Open To Approved
	4	 17-01-2024		Moin Bloch		        Modified Added [TaxTypeId]

**************************************************************/ 
CREATE   PROCEDURE [dbo].[USP_SaveNonPOInvoicePartsDetails]
@tbl_NonPOInvoicePartDetails NonPOInvoicePartDetailsType READONLY
AS
BEGIN
	
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

		BEGIN TRY
				BEGIN TRANSACTION
				BEGIN
					DECLARE @NonPOInvoiceId BIGINT = 0,@UpdatedBy VARCHAR(50);
					SELECT TOP 1 @NonPOInvoiceId = [NonPOInvoiceId],@UpdatedBy = [UpdatedBy] FROM @tbl_NonPOInvoicePartDetails

					IF((SELECT COUNT(NonPOInvoicePartDetailsId) FROM @tbl_NonPOInvoicePartDetails) > 0 )
					BEGIN
						MERGE dbo.NonPOInvoicePartDetails AS TARGET
						USING @tbl_NonPOInvoicePartDetails AS SOURCE ON (TARGET.NonPOInvoiceId = SOURCE.NonPOInvoiceId AND TARGET.NonPOInvoicePartDetailsId = SOURCE.NonPOInvoicePartDetailsId) 
						--WHEN RECORDS ARE MATCHED, UPDATE THE RECORDS IF THEREANY CHANGES
						WHEN MATCHED 				
							THEN UPDATE 						
							SET 							
								 TARGET.[GlAccountId] = SOURCE.GlAccountId
								,TARGET.[Amount] = SOURCE.[Amount]
								,TARGET.[FXRate] =SOURCE.[FXRate]
								,TARGET.[InvoiceNum] =SOURCE.[InvoiceNum]
								,TARGET.[Memo] =SOURCE.[Memo]
								,TARGET.[Invoicedate] =SOURCE.[Invoicedate]
								,TARGET.[JournalType] =SOURCE.[JournalType]
								,TARGET.[ManagementStructureId] = SOURCE.ManagementStructureId								
								,TARGET.[LastMSLevel] = SOURCE.LastMSLevel
								,TARGET.[AllMSlevels] = SOURCE.AllMSlevels
								,TARGET.[UpdatedBy] = SOURCE.UpdatedBy
								,TARGET.[UpdatedDate] = GETUTCDATE()
								,TARGET.[Item] =SOURCE.[Item]
								,TARGET.[Description] =SOURCE.[Description]
								,TARGET.[UnitOfMeasureId] =SOURCE.[UnitOfMeasureId]
								,TARGET.[Qty] =SOURCE.[Qty]
								,TARGET.[ExtendedPrice] =SOURCE.[ExtendedPrice]
								,TARGET.[TaxTypeId] = SOURCE.[TaxTypeId]
							
						WHEN NOT MATCHED BY TARGET 
							THEN INSERT (
										 [NonPOInvoiceId]
										,[EntryDate]
										,[Amount]
										,[CurrencyId]
										,[FXRate]
										,[GlAccountId]
										,[InvoiceNum]
										,[Invoicedate]
										,[ManagementStructureId]
										,[LastMSLevel]
										,[AllMSlevels]
										,[Memo]
										,[JournalType]
										,[MasterCompanyId]
										,[CreatedBy]
										,[UpdatedBy]
										,[CreatedDate]
										,[UpdatedDate]
										,[IsActive]
										,[IsDeleted]
										,[Item]
										,[Description]
										,[UnitOfMeasureId]
										,[Qty]
										,[ExtendedPrice]
										,[TaxTypeId]
								   )
							VALUES (
										 SOURCE.[NonPOInvoiceId]
										,SOURCE.[EntryDate]
										,SOURCE.[Amount]
										,SOURCE.[CurrencyId]
										,SOURCE.[FXRate]
										,SOURCE.[GlAccountId]
										,SOURCE.[InvoiceNum]
										,SOURCE.[Invoicedate]
										,SOURCE.[ManagementStructureId]
										,SOURCE.[LastMSLevel]
										,SOURCE.[AllMSlevels]
										,SOURCE.[Memo]
										,SOURCE.[JournalType]
										,SOURCE.[MasterCompanyId]
										,SOURCE.[UpdatedBy]
										,SOURCE.[UpdatedBy]
										,GETUTCDATE()
										,GETUTCDATE()
										,1
										,SOURCE.[IsDeleted]
										,SOURCE.[Item]
										,SOURCE.[Description]
										,SOURCE.[UnitOfMeasureId]
										,SOURCE.[Qty]
										,SOURCE.[ExtendedPrice]
										,SOURCE.[TaxTypeId]
										);
					 END

					IF(@NonPOInvoiceId > 0)
					BEGIN
						DECLARE @IsEnforceNonPoApproval BIT = 0
						SELECT @IsEnforceNonPoApproval = [IsEnforceNonPoApproval] FROM [dbo].[NonPOInvoiceHeader] WITH(NOLOCK) WHERE [NonPOInvoiceId] = @NonPOInvoiceId;
						IF(@IsEnforceNonPoApproval = 0)
						BEGIN
							UPDATE [dbo].[NonPOInvoiceHeader]
							   SET [StatusId] = (SELECT [NonPOInvoiceHeaderStatusId] FROM [dbo].[NonPOInvoiceHeaderStatus] WITH(NOLOCK) WHERE [Description] = 'Approved')
							      ,[UpdatedDate] = GETUTCDATE()
								  ,[UpdatedBy] = @UpdatedBy								
						   WHERE [NonPOInvoiceId] = @NonPOInvoiceId;
						END						
					END
				COMMIT  TRANSACTION
			END
		END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
				PRINT 'ROLLBACK'
                    ROLLBACK TRAN;
              DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_SaveNonPOInvoicePartsDetails' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''
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