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
    2    02-Jan-2024   RAJESH GAMI			Auto Approved the part if part has sales tax. And Resolved issue regarding auto approve, And Commented unwanted code now
	3    02-Jan-2024   RAJESH GAMI			Sales Tax timout issue resolved
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
						IF(@IsEnforceApproval = 0 AND  (SELECT COUNT(VendorProformaInvoiceId) FROM @tbl_VendorProformaInvoicePartDetailsType WHERE ISNULL(VendorProformaInvoicePartDetailsId,0) = 0) >0)
						BEGIN
							UPDATE [dbo].[VendorProformaInvoiceHeader]
							   SET [StatusId] = (SELECT [VendorProformaInvoiceHeaderStatusId] FROM [dbo].[VendorProformaInvoiceHeaderStatus] WITH(NOLOCK) WHERE [Description] = 'Open')
							      ,[UpdatedDate] = GETUTCDATE()
								  ,[UpdatedBy] = @UpdatedBy								
						   WHERE [VendorProformaInvoiceId] = @VendorProformaInvoiceId;
						END
						--ELSE IF(@IsEnforceApproval = 1)
						--BEGIN
						--		DECLARE @ApprovalProcessId INT = (Select TOP 1 ApprovalProcessId from dbo.ApprovalProcess WITH(NOLOCK) Where Name = 'Approved')
						--		DECLARE @ApprovedStatusId INT = (Select TOP 1 ApprovalStatusId from dbo.ApprovalStatus WITH(NOLOCK) Where Name = 'Approved'),@totalTaxApprovalPartCount INT = 0;
						--		MERGE INTO DBO.VendorProformaInvoiceApproval AS Target
						--			USING (
						--				SELECT
						--					VendorProformaInvoicePartDetailsId,
						--					VendorProformaInvoiceId,
						--					TaxTypeId,
						--					GETUTCDATE() AS CurrentDate, 
						--					MasterCompanyId
						--				FROM VendorProformaInvoicePartDetails
						--				WHERE TaxTypeId > 0 AND [VendorProformaInvoiceId] = @VendorProformaInvoiceId
						--			) AS Source
						--			ON Target.VendorProformaInvoicePartDetailsId = Source.VendorProformaInvoicePartDetailsId 
						--			WHEN NOT MATCHED BY TARGET THEN
						--			INSERT (
						--				VendorProformaInvoiceId,
						--				VendorProformaInvoicePartDetailsId,
						--				ActionId,
						--				StatusId,
						--				SentDate,
						--				CreatedDate,
						--				UpdatedDate,
						--				CreatedBy,
						--				UpdatedBy,
						--				MasterCompanyId,
						--				IsActive,
						--				IsDeleted,
						--				ApprovedDate,
						--				ApprovedByName
						--			)
						--			VALUES (
						--				Source.VendorProformaInvoiceId,
						--				Source.VendorProformaInvoicePartDetailsId,
						--				@ApprovalProcessId, -- ActionId 
						--				@ApprovedStatusId, -- StatusId 
						--				Source.CurrentDate, -- SentDate
						--				Source.CurrentDate, -- CreatedDate
						--				Source.CurrentDate, -- UpdatedDate
						--				@UpdatedBy,   -- CreatedBy
						--				@UpdatedBy,   -- UpdatedBy
						--				Source.MasterCompanyId,
						--				1, -- IsActive (true)
						--				0,  -- IsDeleted (false)
						--				Source.CurrentDate,
						--				'Auto Approved'
						--			);
						--			--SET @totalTaxApprovalPartCount = isnull((SELECT count(1) FROM DBO.VendorProformaInvoiceApproval AP WITH(NOLOCK) WHERE AP.VendorProformaInvoiceId = @VendorProformaInvoiceId and AP.VendorProformaInvoicePartDetailsId IN(SELECT VendorProformaInvoicePartDetailsId FROM dbo.VendorProformaInvoicePartDetails AP WITH(NOLOCK) WHERE [VendorProformaInvoiceId] = @VendorProformaInvoiceId and isnull(TaxTypeId,0) = 0) AND ISNULL(Ap.ApprovedById,0) > 0 ),0)
						--			--If(((SELECT COUNT(VendorProformaInvoiceApprovalId) FROM VendorProformaInvoiceApproval AP WITH (NOLOCK) WHERE AP.VendorProformaInvoiceId = @VendorProformaInvoiceId AND ISNULL(ApprovedDate,'') != '' ) - @totalTaxApprovalPartCount) = ISNULL((SELECT COUNT(VendorProformaInvoicePartDetailsId) FROM VendorProformaInvoicePartDetails P WITH (NOLOCK) WHERE P.VendorProformaInvoiceId = @VendorProformaInvoiceId AND ISNULL(P.TaxTypeId,0) = 0),0))
						--			--BEGIN
						--			--	UPDATE [dbo].[VendorProformaInvoiceHeader]
						--			--	   SET [StatusId] = (SELECT [VendorProformaInvoiceHeaderStatusId] FROM [dbo].[VendorProformaInvoiceHeaderStatus] WITH(NOLOCK) WHERE [Description] = 'Approved')
						--			--		  ,[UpdatedDate] = GETUTCDATE()
						--			--		  ,[UpdatedBy] = @UpdatedBy								
						--			--   WHERE [VendorProformaInvoiceId] = @VendorProformaInvoiceId;
						--			--END
						--			--ELSE
						--			--BEGIN
						--			--	UPDATE [dbo].[VendorProformaInvoiceHeader]
						--			--	   SET [StatusId] = (SELECT [VendorProformaInvoiceHeaderStatusId] FROM [dbo].[VendorProformaInvoiceHeaderStatus] WITH(NOLOCK) WHERE [Description] = 'Open')
						--			--		  ,[UpdatedDate] = GETUTCDATE()
						--			--		  ,[UpdatedBy] = @UpdatedBy								
						--			--   WHERE [VendorProformaInvoiceId] = @VendorProformaInvoiceId;
						--			--END

						--END
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