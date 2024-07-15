
/*************************************************************           
 ** File:   [USP_DuplicateSalesOrderQuote]           
 ** Author:   Abhishek Jirawla  
 ** Description: Get Data for SalesOrderQuote Conversion Report 
 ** Purpose:         
 ** Date:   07/04/2024
          
 ** PARAMETERS:           
   
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** S NO   Date         Author  		Change Description            
 ** --   --------     -------			--------------------------------          
    1	07/04/2024	Abhishek Jirawla	Created
   
**************************************************************/
CREATE   PROCEDURE [dbo].[USP_DuplicateSalesOrderQuote]
	@SalesOrderQuoteId BIGINT,
	@MasterCompanyId INT,
	@CodeTypeId INT,
	@Username VARCHAR(250),
	@Result INT OUTPUT
AS
BEGIN
  SET NOCOUNT ON;
  SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

  BEGIN TRY
    BEGIN TRANSACTION
		DECLARE @OpenStatus INT, @PartOpenStatus BIGINT, @CustomerId BIGINT
		DECLARE @CurrentNummber BIGINT,
				 @CodePrefix VARCHAR(50),
				 @CodeSufix VARCHAR(50),
				 @ValidForDays INT,
				 @IsApprovalRule BIT,
				 @QuoteExpireDate DATETIME2,
				 @CreditTermsId INT, 
				 @CreditLimit DECIMAL(18,2), 
				 @ARBalance DECIMAL(18,2),
				 @CommonDocumentDetailId BIGINT,
				 @ReferenceId BIGINT,
				 @AttachmentId BIGINT,
				 @NewAttachmentId BIGINT,
				 @ManagementStructureHeaderModuleId BIGINT,
				 @ManagementStructurePartModuleId BIGINT,
				 @AddressModuleId BIGINT,
				 @AttachmentModuleId BIGINT,
				 @Id INT,
				 @DocId INT,
				 @NewID BIGINT,
				 @SalesOrderQuoteNumber VARCHAR(250),
				 @SalesOrderQuotePartId BIGINT,
				 @NewPartID BIGINT; 
		
		SELECT @CustomerId = CustomerId FROM [dbo].[SalesOrderQuote] WITH(NOLOCK)  WHERE SalesOrderQuoteId = @SalesOrderQuoteId
		
		SELECT @OpenStatus = [Id] FROM [dbo].[MasterSalesOrderQuoteStatus] WITH(NOLOCK)  WHERE [Name] = 'Open'

		SELECT @PartOpenStatus = SOPartStatusId FROM [dbo].[SOPartStatus] WITH(NOLOCK)  WHERE PartStatus = 'Open'

		SELECT @CreditTermsId = CreditTermsId FROM [dbo].[CustomerFinancial] WITH(NOLOCK)  WHERE CustomerId = @CustomerId
		SELECT @CreditLimit = CreditLimit FROM [dbo].[CustomerFinancial] WITH(NOLOCK)  WHERE CustomerId = @CustomerId
		SELECT @ARBalance = ARBalance FROM [dbo].[CustomerCreditTermsHistory] WITH(NOLOCK)  WHERE CustomerId = @CustomerId

		SELECT @ManagementStructureHeaderModuleId = [ManagementStructureModuleId] FROM [dbo].[ManagementStructureModule] WITH(NOLOCK) WHERE [ModuleName] = 'SalesOrderQuote';

		SELECT @ManagementStructurePartModuleId = [ManagementStructureModuleId] FROM [dbo].[ManagementStructureModule] WITH(NOLOCK) WHERE [ModuleName] = 'SalesOrderQuote';

		SELECT @AddressModuleId = ModuleId FROM [dbo].[Module] WITH(NOLOCK) WHERE [ModuleName] = 'SalesQuote';

		SELECT @AttachmentModuleId = AttachmentModuleId FROM [dbo].[AttachmentModule] WITH(NOLOCK)  WHERE [Name] = 'SalesQuote';

		SELECT @ValidForDays = ValidDays, @IsApprovalRule = IsApprovalRule FROM SalesOrderQuoteSettings

		SELECT @QuoteExpireDate = DATEADD(day, @ValidForDays, GETUTCDATE());

		SELECT @CurrentNummber = [CurrentNummber],@CodePrefix = [CodePrefix],@CodeSufix = [CodeSufix] FROM [dbo].[CodePrefixes] WITH(NOLOCK)    
        WHERE [CodeTypeId] = @CodeTypeId AND [MasterCompanyId] = @MasterCompanyId;

		SET @SalesOrderQuoteNumber = (SELECT * FROM dbo.udfGenerateCodeNumberWithOutDash(CAST(@CurrentNummber AS BIGINT) + 1, @CodePrefix, @CodeSufix)); 

		INSERT INTO [dbo].[SalesOrderQuote]
			([QuoteTypeId],[OpenDate],[ValidForDays],[QuoteExpireDate],[AccountTypeId],[CustomerId],[CustomerContactId],[CustomerReference],
			[ContractReference],[SalesPersonId],[AgentName],[CustomerSeviceRepId],[ProbabilityId],[LeadSourceId],[CreditLimit],[CreditTermId],
			[EmployeeId],[RestrictPMA],[RestrictDER],[ApprovedDate],[CurrencyId],[CustomerWarningId],[Memo],[Notes],[MasterCompanyId],[CreatedBy],
			[CreatedDate],[UpdatedBy],[UpdatedDate],[IsDeleted],[StatusId],[StatusChangeDate],[ManagementStructureId],[Version],[AgentId],
			[QtyRequested],[QtyToBeQuoted],[SalesOrderQuoteNumber],[QuoteSentDate],[IsNewVersionCreated],[IsActive],[QuoteParentId],[QuoteTypeName],
			[AccountTypeName],[CustomerName],[SalesPersonName],[CustomerServiceRepName],[ProbabilityName],[LeadSourceName],[CreditTermName],
			[EmployeeName],[CurrencyName],[CustomerWarningName],[ManagementStructureName],[CustomerContactName],[VersionNumber],[CustomerCode],
			[CustomerContactEmail],[CreditLimitName],[StatusName],[ManagementStructureName1],[ManagementStructureName2],[ManagementStructureName3],
			[ManagementStructureName4],[EnforceEffectiveDate],[IsEnforceApproval],[TotalFreight],[TotalCharges],[FreightBilingMethodId],
			[ChargesBilingMethodId])
		(SELECT [QuoteTypeId],GETUTCDATE(),@ValidForDays,@QuoteExpireDate,[AccountTypeId],[CustomerId],[CustomerContactId],[CustomerReference],
			[ContractReference],[SalesPersonId],[AgentName],[CustomerSeviceRepId],[ProbabilityId],[LeadSourceId],@CreditLimit,@CreditTermsId,
			[EmployeeId],[RestrictPMA],[RestrictDER],NULL,[CurrencyId],[CustomerWarningId],[Memo],[Notes],[MasterCompanyId],@Username,
			GETUTCDATE(),@Username,GETUTCDATE(),0,@OpenStatus,GETUTCDATE(),[ManagementStructureId],[Version],[AgentId],
			[QtyRequested],[QtyToBeQuoted],@SalesOrderQuoteNumber,[QuoteSentDate],[IsNewVersionCreated],1,[QuoteParentId],[QuoteTypeName],
			[AccountTypeName],[CustomerName],[SalesPersonName],[CustomerServiceRepName],[ProbabilityName],[LeadSourceName],[CreditTermName],
			[EmployeeName],[CurrencyName],[CustomerWarningName],[ManagementStructureName],[CustomerContactName],[VersionNumber],[CustomerCode],
			[CustomerContactEmail],[CreditLimitName],[StatusName],[ManagementStructureName1],[ManagementStructureName2],[ManagementStructureName3],
			[ManagementStructureName4],[EnforceEffectiveDate],[IsEnforceApproval],[TotalFreight],[TotalCharges],[FreightBilingMethodId],
			[ChargesBilingMethodId]
		FROM [dbo].[SalesOrderQuote]
		WHERE SalesOrderQuoteId = @SalesOrderQuoteId)

		SET @NewID = IDENT_CURRENT('SalesOrderQuote');

		 ------Start Update CodePrifix No ------
		 UPDATE dbo.CodePrefixes SET CurrentNummber = CAST(@CurrentNummber AS BIGINT) + 1 WHERE CodeTypeId = @CodeTypeId AND MasterCompanyId = @MasterCompanyId;  
		 ------End CodePrifix Update ---------

		  ----- Start Add ManagementStructureDetails Header Data----
		 INSERT INTO [dbo].[SalesOrderManagementStructureDetails]([ModuleID],[ReferenceID],[EntityMSID],
		 			[Level1Id],[Level1Name],[Level2Id],[Level2Name],[Level3Id],[Level3Name],[Level4Id],[Level4Name],[Level5Id],[Level5Name],
		 			[Level6Id],[Level6Name],[Level7Id],[Level7Name],[Level8Id],[Level8Name],[Level9Id],[Level9Name],[Level10Id],[Level10Name],
		 			[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted],[LastMSLevel],[AllMSlevels])
		 SELECT [ModuleID],@NewID,[EntityMSID],
		 			[Level1Id],[Level1Name],[Level2Id],[Level2Name],[Level3Id],[Level3Name],[Level4Id],[Level4Name],[Level5Id],[Level5Name],
		 			[Level6Id],[Level6Name],[Level7Id],[Level7Name],[Level8Id],[Level8Name],[Level9Id],[Level9Name],[Level10Id],[Level10Name],
		 			[MasterCompanyId],@Username,@Username,GETUTCDATE(),GETUTCDATE(),[IsActive],[IsDeleted],[LastMSLevel],[AllMSlevels]
		 FROM [dbo].[SalesOrderManagementStructureDetails] WITH(NOLOCK) 
		 WHERE [ReferenceID] = @SalesOrderQuoteId 
		 AND [ModuleID] = @ManagementStructureHeaderModuleId;
		 -----End ManagementStructureDetails Header---------

		 IF OBJECT_ID(N'tempdb.#tblSalesOrderQuotePartSingle') IS NOT NULL    
		 BEGIN    
			 DROP TABLE #tblSalesOrderQuotePartSingle     
		 END    
		 CREATE TABLE #tblSalesOrderQuotePartSingle    
		 (    
			ID BIGINT NOT NULL IDENTITY,     
			SalesOrderQuotePartId BIGINT NULL,    
			SalesOrderQuoteId BIGINT NULL, 
			MasterCompanyId INT NULL
		 ) 
		 ------- Start Part Data ------------
		 IF EXISTS(SELECT 1 FROM [dbo].[SalesOrderQuotePart] WITH(NOLOCK) WHERE SalesOrderQuoteId = @SalesOrderQuoteId)
		 BEGIN
				INSERT INTO #tblSalesOrderQuotePartSingle(SalesOrderQuotePartId,SalesOrderQuoteId,MasterCompanyId)
				SELECT SalesOrderQuotePartId,SalesOrderQuoteId,MasterCompanyId
				FROM [dbo].[SalesOrderQuotePart] WITH(NOLOCK) 
				WHERE [SalesOrderQuoteId] = @SalesOrderQuoteId
				AND [MasterCompanyId] = @MasterCompanyId;

				SELECT @ID = 1;    
				WHILE @ID <= (SELECT MAX(ID) FROM #tblSalesOrderQuotePartSingle)
				BEGIN
					SELECT @SalesOrderQuotePartId = [SalesOrderQuotePartId]
					FROM #tblSalesOrderQuotePartSingle WITH(NOLOCK) WHERE [ID] = @ID;

					----Insert record in Part table --------
					INSERT INTO SalesOrderQuotePart(
						[SalesOrderQuoteId],[ItemMasterId],[StockLineId],[FxRate],[QtyQuoted],[UnitSalePrice],
					   [MarkUpPercentage],[SalesBeforeDiscount],[Discount],[DiscountAmount],[NetSales],[MasterCompanyId],
					   [CreatedBy],[CreatedDate],[UpdatedBy],[UpdatedDate],[IsDeleted],[UnitCost],[MethodType],[SalesPriceExtended],
					   [MarkupExtended],[SalesDiscountExtended],[NetSalePriceExtended],[UnitCostExtended],[MarginAmount],[MarginAmountExtended],
					   [MarginPercentage],[ConditionId],[IsConvertedToSalesOrder],[IsActive],[CustomerRequestDate],[PromisedDate],
					   [EstimatedShipDate],[PriorityId],[StatusId],[CustomerReference],[QtyRequested],[Notes],[CurrencyId],[MarkupPerUnit],
					   [GrossSalePricePerUnit],[GrossSalePrice],[TaxType],[TaxPercentage],[TaxAmount],[AltOrEqType],[QtyPrevQuoted],
					   [ControlNumber],[IdNumber],[QtyAvailable],[StockLineName],[PartNumber],[PartDescription],[ConditionName],[PriorityName],
					   [StatusName],[CurrencyName],[ItemNo],[UnitSalesPricePerUnit],[IsLotAssigned],[LotId],[SalesPriceExpiryDate])
					SELECT @NewID,[ItemMasterId],[StockLineId],[FxRate],[QtyQuoted],[UnitSalePrice],
						   [MarkUpPercentage],[SalesBeforeDiscount],[Discount],[DiscountAmount],[NetSales],[MasterCompanyId],
						   @Username,GETUTCDATE(),@Username,GETUTCDATE(),[IsDeleted],[UnitCost],[MethodType],[SalesPriceExtended],
						   [MarkupExtended],[SalesDiscountExtended],[NetSalePriceExtended],[UnitCostExtended],[MarginAmount],[MarginAmountExtended],
						   [MarginPercentage],[ConditionId],[IsConvertedToSalesOrder],[IsActive],[CustomerRequestDate],[PromisedDate],
						   [EstimatedShipDate],[PriorityId],@PartOpenStatus,[CustomerReference],[QtyRequested],[Notes],[CurrencyId],[MarkupPerUnit],
						   [GrossSalePricePerUnit],[GrossSalePrice],[TaxType],[TaxPercentage],[TaxAmount],[AltOrEqType],[QtyPrevQuoted],
						   [ControlNumber],[IdNumber],[QtyAvailable],[StockLineName],[PartNumber],[PartDescription],[ConditionName],[PriorityName],
						   [StatusName],[CurrencyName],[ItemNo],[UnitSalesPricePerUnit],[IsLotAssigned],[LotId],[SalesPriceExpiryDate]
					FROM [dbo].[SalesOrderQuotePart] WITH(NOLOCK) 
					WHERE SalesOrderQuoteId = @SalesOrderQuoteId
						  AND [SalesOrderQuotePartId] = @SalesOrderQuotePartId
						  AND [MasterCompanyId] = @MasterCompanyId;
					------End Part table -----------

					SET @NewPartID = IDENT_CURRENT('SalesOrderQuotePart');  

					----- Start Add ManagementStructureDetails Header Data----
					INSERT INTO [dbo].[SalesOrderManagementStructureDetails]([ModuleID],[ReferenceID],[EntityMSID],
		 	   				[Level1Id],[Level1Name],[Level2Id],[Level2Name],[Level3Id],[Level3Name],[Level4Id],[Level4Name],[Level5Id],[Level5Name],
		 	   				[Level6Id],[Level6Name],[Level7Id],[Level7Name],[Level8Id],[Level8Name],[Level9Id],[Level9Name],[Level10Id],[Level10Name],
		 	   				[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted],[LastMSLevel],[AllMSlevels])
					SELECT [ModuleID],@NewPartID,[EntityMSID],
		 	   				[Level1Id],[Level1Name],[Level2Id],[Level2Name],[Level3Id],[Level3Name],[Level4Id],[Level4Name],[Level5Id],[Level5Name],
		 	   				[Level6Id],[Level6Name],[Level7Id],[Level7Name],[Level8Id],[Level8Name],[Level9Id],[Level9Name],[Level10Id],[Level10Name],
		 	   				[MasterCompanyId],@Username,@Username,GETUTCDATE(),GETUTCDATE(),[IsActive],[IsDeleted],[LastMSLevel],[AllMSlevels]
					FROM [dbo].[SalesOrderManagementStructureDetails] WITH(NOLOCK) 
					WHERE [ReferenceID] = @SalesOrderQuotePartId 
					AND [ModuleID] = @ManagementStructurePartModuleId;
					-----End ManagementStructureDetails Header---------

					--------Start Charges Tab ---------------
					 IF EXISTS (SELECT 1 FROM [dbo].[SalesOrderQuoteCharges] WITH(NOLOCK) WHERE [SalesOrderQuoteId] = @SalesOrderQuoteId AND [SalesOrderQuotePartId] = @SalesOrderQuotePartId)    
					 BEGIN 
							INSERT INTO [dbo].[SalesOrderQuoteCharges](
							[SalesOrderQuoteId],[SalesOrderQuotePartId],[ChargesTypeId],[VendorId],[Quantity],[MarkupPercentageId],[Description],
							[UnitCost],[ExtendedCost],[MasterCompanyId],[MarkupFixedPrice],[BillingMethodId],[BillingAmount],[BillingRate],[HeaderMarkupId],
							[RefNum],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted],[HeaderMarkupPercentageId],[VendorName],
							[ChargeName],[MarkupName],[ItemMasterId],[ConditionId],[UnitOfMeasureId])    
							SELECT @NewID,@NewPartID,[ChargesTypeId],[VendorId],[Quantity],[MarkupPercentageId],[Description],
							[UnitCost],[ExtendedCost],[MasterCompanyId],[MarkupFixedPrice],[BillingMethodId],[BillingAmount],[BillingRate],[HeaderMarkupId],
							[RefNum],@Username,@Username,GETUTCDATE(),GETUTCDATE(),[IsActive],[IsDeleted],[HeaderMarkupPercentageId],[VendorName],
							[ChargeName],[MarkupName],[ItemMasterId],[ConditionId],[UnitOfMeasureId]    
							FROM [dbo].[SalesOrderQuoteCharges] WITH(NOLOCK) WHERE [SalesOrderQuoteId] = @SalesOrderQuoteId AND [SalesOrderQuotePartId] = @SalesOrderQuotePartId;    
					 END
					 --------End Charges Tab  ---------------

					 --------Start Freight Tab ---------------
					 IF EXISTS (SELECT 1 FROM [dbo].[SalesOrderQuoteFreight] WITH(NOLOCK) WHERE [SalesOrderQuoteId] = @SalesOrderQuoteId AND [SalesOrderQuotePartId] = @SalesOrderQuotePartId)    
					 BEGIN 
							INSERT INTO [dbo].[SalesOrderQuoteFreight](
							[SalesOrderQuoteId],[SalesOrderQuotePartId],[ShipViaId],[Weight],[Memo],[Amount],[MarkupPercentageId],[MarkupFixedPrice],
							[HeaderMarkupId],[BillingMethodId],[BillingRate],[BillingAmount],[Length],[Width],[Height],[UOMId],[DimensionUOMId],[CurrencyId],
							[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted],[HeaderMarkupPercentageId],
							[ShipViaName],[UOMName],[DimensionUOMName],[CurrencyName],[ItemMasterId],[ConditionId])    
							SELECT @NewID,@NewPartID,[ShipViaId],[Weight],[Memo],[Amount],[MarkupPercentageId],[MarkupFixedPrice],
							[HeaderMarkupId],[BillingMethodId],[BillingRate],[BillingAmount],[Length],[Width],[Height],[UOMId],[DimensionUOMId],[CurrencyId],
							[MasterCompanyId],@Username,@Username,GETUTCDATE(),GETUTCDATE(),[IsActive],[IsDeleted],[HeaderMarkupPercentageId],
							[ShipViaName],[UOMName],[DimensionUOMName],[CurrencyName],[ItemMasterId],[ConditionId]    
							FROM [dbo].[SalesOrderQuoteFreight] WITH(NOLOCK) WHERE [SalesOrderQuoteId] = @SalesOrderQuoteId AND [SalesOrderQuotePartId] = @SalesOrderQuotePartId;    
					 END
					 --------End Freight Tab  ---------------


					SET @ID = @ID + 1;
				END
		 END
		 --------End Parts Tab  ---------------

		 --------Start Address Tab ---------------
		 IF EXISTS (SELECT 1 FROM [dbo].[AllAddress] WITH(NOLOCK) WHERE [ReffranceId] = @SalesOrderQuoteId AND ModuleId = @AddressModuleId)    
		 BEGIN 
				INSERT INTO [dbo].[AllAddress]([ReffranceId],[ModuleId],[UserType],[UserTypeName],[UserId],[UserName],[SiteId],[SiteName],    
				   [AddressId],[IsModuleOnly],[IsShippingAdd],[ShippingAccountNo],[Memo],[ContactId],[ContactName],[ContactPhoneNo],    
				   [Line1],[Line2],[Line3],[City],[StateOrProvince],[PostalCode],[CountryId],[Country],[MasterCompanyId],[CreatedBy],    
				   [UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted],[IsPrimary])    
				SELECT @NewID,@AddressModuleId,[UserType],[UserTypeName],[UserId],[UserName],[SiteId],[SiteName],    
				   [AddressId],[IsModuleOnly],[IsShippingAdd],[ShippingAccountNo],[Memo],[ContactId],[ContactName],[ContactPhoneNo],    
				   [Line1],[Line2],[Line3],[City],[StateOrProvince],[PostalCode],[CountryId],[Country],[MasterCompanyId],@Username,    
				   @Username,GETUTCDATE(),GETUTCDATE(),1,0,[IsPrimary]    
			    FROM [dbo].[AllAddress] WITH(NOLOCK) WHERE [ReffranceId] = @SalesOrderQuoteId AND [ModuleId] = @AddressModuleId;    
    
				INSERT INTO [dbo].[AllShipVia]([ReferenceId],[ModuleId],[UserType],[ShipViaId],[ShippingCost],[HandlingCost],[IsModuleShipVia],    
					[ShippingAccountNo],[ShipVia],[ShippingViaId],[MasterCompanyId],[CreatedBy],[UpdatedBy] ,[CreatedDate] ,[UpdatedDate] ,    
					[IsActive] ,[IsDeleted])    
				SELECT @NewID,@AddressModuleId,[UserType],[ShipViaId],[ShippingCost],[HandlingCost],[IsModuleShipVia],    
					[ShippingAccountNo],[ShipVia],[ShippingViaId],[MasterCompanyId],@Username,@Username ,GETUTCDATE(),GETUTCDATE(),    
					1,0     
				FROM [dbo].[AllShipVia] WITH(NOLOCK) 
				WHERE [ReferenceId] = @SalesOrderQuoteId AND [ModuleId] = @AddressModuleId;  
		 END
		 --------End Address Tab  ---------------

		 -------Start Document Tab --------------
		 IF OBJECT_ID(N'tempdb..#tblSalesOrderQuoteDocuments') IS NOT NULL    
		 BEGIN    
			 DROP TABLE #tblSalesOrderQuoteDocuments
		 END    
		 CREATE TABLE #tblSalesOrderQuoteDocuments    
		 (    
			ID BIGINT NOT NULL IDENTITY,  
			CommonDocumentDetailId BIGINT NULL,
			ReferenceId BIGINT NULL, 
			AttachmentId BIGINT NULL,    
			MasterCompanyId INT NULL  
		 ) 

		 IF EXISTS (SELECT 1 FROM [dbo].[CommonDocumentDetails] WITH(NOLOCK) WHERE [ReferenceId] = @SalesOrderQuoteId)    
		 BEGIN
				INSERT INTO #tblSalesOrderQuoteDocuments(CommonDocumentDetailId,ReferenceId,AttachmentId)
				SELECT [CommonDocumentDetailId],[ReferenceId],[AttachmentId]
				FROM [dbo].[CommonDocumentDetails] WITH(NOLOCK) 
				WHERE [ReferenceId] = @SalesOrderQuoteId 
				AND [ModuleId] = @AttachmentModuleId 
				AND [MasterCompanyId] = @MasterCompanyId;

				SELECT @DocId = 1;    
				WHILE @DocId <= (SELECT MAX(ID) FROM #tblSalesOrderQuoteDocuments)         
				BEGIN
					 SELECT @CommonDocumentDetailId = [CommonDocumentDetailId],
							@ReferenceId = [ReferenceId], 
							@AttachmentId = [AttachmentId]
					 FROM #tblSalesOrderQuoteDocuments WITH(NOLOCK) WHERE [ID] = @DocId;

					 IF(@AttachmentId > 0)
					 BEGIN
						  ------------ Attachment --------
						  INSERT [dbo].[Attachment]([ModuleId],[ReferenceId],[MasterCompanyId],[CreatedBy],
								 [CreatedDate],[UpdatedBy],[UpdatedDate],[IsActive],[IsDeleted])
						  SELECT @AttachmentModuleId,@NewID,[MasterCompanyId],@Username,
								 GETUTCDATE(),@Username,GETUTCDATE(),[IsActive],[IsDeleted]
						  FROM [dbo].[Attachment] WITH(NOLOCK)
						  WHERE [AttachmentId] = @AttachmentId
						  AND [ReferenceId] = @ReferenceId;
						  
						  SET @NewAttachmentId = IDENT_CURRENT('Attachment');
					 END

					 ------- CommonDocumentDetails ---------
					 INSERT INTO [dbo].[CommonDocumentDetails]([ModuleId],[ReferenceId],[AttachmentId],[DocName],[DocMemo],[DocDescription],[MasterCompanyId],
								 [CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted],
							     [DocumentTypeId],[ExpirationDate],[ReferenceIndex],[ModuleType])
					 SELECT [ModuleId],@NewID,@NewAttachmentId,[DocName],[DocMemo],[DocDescription],[MasterCompanyId],
								 @Username,@Username,GETUTCDATE(),GETUTCDATE(),[IsActive],[IsDeleted],
								 [DocumentTypeId],[ExpirationDate],[ReferenceIndex],[ModuleType]
					 FROM [dbo].[CommonDocumentDetails] WITH(NOLOCK) 
					 WHERE [CommonDocumentDetailId] = @CommonDocumentDetailId
					 AND [ReferenceId] = @ReferenceId 
					 AND [ModuleId] = @AttachmentModuleId 
					 AND [MasterCompanyId] = @MasterCompanyId;

					 ----AttachmentDetails-------
					 INSERT INTO [dbo].[AttachmentDetails]
							([AttachmentId],[FileName],[Description],[Link],[FileFormat],[FileSize],[FileType],
							[CreatedDate],[UpdatedDate],[CreatedBy],[UpdatedBy],[IsActive],[IsDeleted],[Name],
							[Memo],[TypeId])
					 SELECT @NewAttachmentId,[FileName],[Description],[Link],[FileFormat],[FileSize],[FileType],
							GETUTCDATE(),GETUTCDATE(),@Username,@Username,[IsActive],[IsDeleted],[Name],
							[Memo],[TypeId]
					 FROM [dbo].[AttachmentDetails] WITH(NOLOCK) WHERE [AttachmentId] = @AttachmentId;

					 SET @CommonDocumentDetailId = 0;
					 SET @NewAttachmentId = 0;
					 SET @ReferenceId = 0;
					 SET @AttachmentId = 0;
					 SET @DocId = @DocId + 1;
				END
		 END
		 -------End Document Tab ---------------

		SELECT @Result = @NewID;
  
 COMMIT TRANSACTION  
 END TRY
 BEGIN CATCH        
  IF @@trancount > 0  
  PRINT 'ROLLBACK'  
    ROLLBACK TRANSACTION;  
    DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()   
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------  
              , @AdhocComments     VARCHAR(150)    = 'USP_DuplicateSalesOrderQuote'   
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ CAST(ISNULL(@SalesOrderQuoteId, '') AS varchar(100))  
             + '@Parameter2 = ''' + CAST(ISNULL(@MasterCompanyId, '') AS varchar(100))   
              , @ApplicationName VARCHAR(100) = 'PAS'  
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------  
              exec spLogException   
                       @DatabaseName           = @DatabaseName  
                     , @AdhocComments          = @AdhocComments  
                     , @ProcedureParameters    = @ProcedureParameters  
                     , @ApplicationName        =  @ApplicationName  
                     , @ErrorLogID                    = @ErrorLogID OUTPUT ;  
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)  
              RETURN(1);  
  END CATCH  
END