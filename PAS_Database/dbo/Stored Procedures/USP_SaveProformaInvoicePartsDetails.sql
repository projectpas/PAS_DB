/*************************************************************           
 ** File:   [USP_SaveProformaInvoicePartsDetails]           
 ** Author:   RAJESH GAMI
 ** Description: Save Proforma Invoice Parts Details
 ** Purpose:         
 ** Date:   19Dec2024
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date          Author					Change Description            
 ** --   -----------   -------				--------------------------------          
    1    19-Dec-2024   RAJESH GAMI			Created

**************************************************************/ 
CREATE     PROCEDURE [dbo].[USP_SaveProformaInvoicePartsDetails]
@tbl_VendorProformaInvoicePartDetailsType VendorProformaInvoicePartDetailsType READONLY
AS
BEGIN
	
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

		BEGIN TRY
				BEGIN TRANSACTION
				BEGIN
					DECLARE @VendorProformaInvoiceId BIGINT = 0,@UpdatedBy VARCHAR(150);
					SELECT TOP 1 @VendorProformaInvoiceId = [VendorProformaInvoiceId],@UpdatedBy = [UpdatedBy] FROM @tbl_VendorProformaInvoicePartDetailsType

					IF((SELECT COUNT(VendorProformaInvoicePartDetailsId) FROM @tbl_VendorProformaInvoicePartDetailsType) > 0 )
					BEGIN
						MERGE dbo.VendorProformaInvoicePartDetails AS TARGET
						USING @tbl_VendorProformaInvoicePartDetailsType AS SOURCE ON (TARGET.VendorProformaInvoiceId = SOURCE.VendorProformaInvoiceId AND TARGET.VendorProformaInvoicePartDetailsId = SOURCE.VendorProformaInvoicePartDetailsId) 
						WHEN MATCHED 				
							THEN UPDATE 						
							SET 							
								 TARGET.[GlAccountId] = SOURCE.GlAccountId
								,TARGET.[Amount] = SOURCE.[Amount]
								,TARGET.[FXRate] =SOURCE.[FXRate]
								,TARGET.[InvoiceNumber] =SOURCE.[InvoiceNumber]
								,TARGET.[Memo] =SOURCE.[Memo]
								,TARGET.[InvoiceDate] =SOURCE.[InvoiceDate]
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
										 [VendorProformaInvoiceId]
										,[EntryDate]
										,[Amount]
										,[CurrencyId]
										,[FXRate]
										,[GlAccountId]
										,[InvoiceNumber]
										,[InvoiceDate]
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
										 SOURCE.[VendorProformaInvoiceId]
										,SOURCE.[EntryDate]
										,SOURCE.[Amount]
										,SOURCE.[CurrencyId]
										,SOURCE.[FXRate]
										,SOURCE.[GlAccountId]
										,SOURCE.[InvoiceNumber]
										,SOURCE.[InvoiceDate]
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

					IF(@VendorProformaInvoiceId > 0)
					BEGIN
						DECLARE @IsEnforceApproval BIT = 0
						SELECT @IsEnforceApproval = [IsEnforcePoRoApproval] FROM [dbo].[VendorProformaInvoiceHeader] WITH(NOLOCK) WHERE [VendorProformaInvoiceId] = @VendorProformaInvoiceId;
						IF(@IsEnforceApproval = 0)
						BEGIN
							UPDATE [dbo].[VendorProformaInvoiceHeader]
							   SET [StatusId] = (SELECT [VendorProformaInvoiceHeaderStatusId] FROM [dbo].[VendorProformaInvoiceHeaderStatus] WITH(NOLOCK) WHERE [Description] = 'Approved')
							      ,[UpdatedDate] = GETUTCDATE()
								  ,[UpdatedBy] = @UpdatedBy								
						   WHERE [VendorProformaInvoiceId] = @VendorProformaInvoiceId;
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
              , @AdhocComments     VARCHAR(150)    = 'USP_SaveProformaInvoicePartsDetails' 
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