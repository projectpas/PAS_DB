
/*************************************************************             
 ** File:   [USP_DuplicateRFQRO]             
 ** Author:  Amit Ghediya 
 ** Description: This stored procedure is used to Make Duplicate vendor RFQ RO to New vendor RFQ RO  
 ** Purpose:           
 ** Date:   05/07/2024  
 ** PARAMETERS: 
 ** RETURN VALUE:             
 **************************************************************             
 ** Change History             
 **************************************************************             
 ** PR		Date			Author				Change Description              
 ** --		--------		-------				--------------------------------            
   1		05/07/2024		Amit Ghediya		Created

-- EXEC [USP_DuplicateRFQRO] 78,1,61
************************************************************************/  
CREATE     PROCEDURE [dbo].[USP_DuplicateRFQRO]  
	@VendorRFQRepairOrderId BIGINT,  
	@MasterCompanyId INT, 
	@CodeTypeId INT,
	@Result INT OUTPUT  
AS  
BEGIN  
 SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED  
 SET NOCOUNT ON;  
		 DECLARE @CurrentNummber BIGINT,
				 @CodePrefix VARCHAR(50),
				 @CodeSufix VARCHAR(50),
				 @RepairOrderNumber VARCHAR(250),
				 @IsEnforceApproval BIT,
				 @RONumber VARCHAR(250),
				 @NewStatusId INT = 1,
				 @NewStatus VARCHAR(50) = 'Open',
				 @VendorRFQRepairOrderNumber VARCHAR(250),
				 @NewID BIGINT,
				 @NewPartID BIGINT,
				 @ManagementStructureHeaderModuleId BIGINT,
				 @ManagementStructurePartModuleId BIGINT,
				 @AddressModuleId BIGINT,
				 @AttachmentModuleId BIGINT,
				 @Id INT,
				 @DocId INT,
				 @VendorId BIGINT,
				 @CreditLimit DECIMAL(18,2),
				 @CreditTermsId INT,
				 @Terms VARCHAR(250),
				 @CommonDocumentDetailId BIGINT,
				 @ReferenceId BIGINT, 
				 @AttachmentId BIGINT,
				 @NewAttachmentId BIGINT,
				 @VendorRFQROPartRecordId BIGINT;  

		SELECT @ManagementStructureHeaderModuleId = [ManagementStructureModuleId] FROM [dbo].[ManagementStructureModule] WITH(NOLOCK) WHERE [ModuleName] = 'VendorRFQROHeader';

		SELECT @ManagementStructurePartModuleId = [ManagementStructureModuleId] FROM [dbo].[ManagementStructureModule] WITH(NOLOCK) WHERE [ModuleName] = 'VendorRFQROPart';

		SELECT @AddressModuleId = [ModuleId] FROM [dbo].[Module] WITH(NOLOCK) WHERE [ModuleName] = 'VendorRFQRepairOrder';

		SELECT @AttachmentModuleId = [AttachmentModuleId] FROM [dbo].[AttachmentModule] WHERE [Name] = 'VendorRFQRepairOrder';

		SELECT @VendorId = [VendorId] FROM [dbo].[VendorRFQRepairOrder] WITH(NOLOCK) WHERE [VendorRFQRepairOrderId] = @VendorRFQRepairOrderId;

		SELECT @CreditLimit = V.[CreditLimit],@CreditTermsId = V.[CreditTermsId],@Terms = CT.[Name] 
		FROM [dbo].[Vendor] V WITH(NOLOCK)
		JOIN [dbo].[CreditTerms] CT WITH(NOLOCK) ON V.CreditTermsId = CT.CreditTermsId WHERE V.VendorId = @VendorId;

 BEGIN TRY  
 BEGIN TRANSACTION  

		SELECT @CurrentNummber = [CurrentNummber],@CodePrefix = [CodePrefix],@CodeSufix = [CodeSufix] FROM [dbo].[CodePrefixes] WITH(NOLOCK)    
        WHERE [CodeTypeId] = @CodeTypeId AND [MasterCompanyId] = @MasterCompanyId;  

		SET @VendorRFQRepairOrderNumber = (SELECT * FROM dbo.udfGenerateCodeNumber(CAST(@CurrentNummber AS BIGINT) + 1, @CodePrefix, @CodeSufix));  
		
		------ Add Header exiting data into new RFQPO -------

		---Check CreditLimit ----
		IF(ISNULL(@CreditLimit,0) = 0)
		BEGIN
			SELECT @CreditLimit = [CreditLimit], @CreditTermsId = [CreditTermsId] FROM [dbo].[VendorRFQRepairOrder] WITH(NOLOCK) 
			WHERE [VendorRFQRepairOrderId] = @VendorRFQRepairOrderId;
		END
		
		INSERT INTO [dbo].[VendorRFQRepairOrder]([VendorRFQRepairOrderNumber],[OpenDate],[ClosedDate],[NeedByDate],[PriorityId],[Priority],[VendorId],[VendorName],    
					[VendorCode],[VendorContactId],[VendorContact],[VendorContactPhone],[CreditTermsId],[Terms],[CreditLimit],[RequisitionerId],    
					[Requisitioner],[StatusId],[Status],[StatusChangeDate],[Resale],[DeferredReceiver],[Memo],[Notes],    
					[ManagementStructureId],[Level1],[Level2],[Level3],[Level4],[MasterCompanyId],    
					[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted],[PDFPath])    
         SELECT @VendorRFQRepairOrderNumber,[OpenDate],[ClosedDate],[NeedByDate],[PriorityId],[Priority],[VendorId],[VendorName],    
					[VendorCode],[VendorContactId],[VendorContact],[VendorContactPhone],@CreditTermsId,@Terms,@CreditLimit,[RequisitionerId],    
					[Requisitioner],@NewStatusId,@NewStatus,[StatusChangeDate],[Resale],[DeferredReceiver],[Memo],[Notes],    
					[ManagementStructureId],[Level1],[Level2],[Level3],[Level4],[MasterCompanyId],    
					[CreatedBy],[UpdatedBy],GETDATE(),GETDATE(),1,0,PDFPath   
         FROM [dbo].[VendorRFQRepairOrder] WITH(NOLOCK) 
		 WHERE [VendorRFQRepairOrderId] = @VendorRFQRepairOrderId;

		 SET @NewID = IDENT_CURRENT('VendorRFQRepairOrder');    
		 ------ End Header add new RFQPO-------

		 ------Start Update CodePrifix No ------
		 UPDATE [dbo].[CodePrefixes] SET CurrentNummber = CAST(@CurrentNummber AS BIGINT) + 1 WHERE [CodeTypeId] = @CodeTypeId AND [MasterCompanyId] = @MasterCompanyId;  
		 ------End CodePrifix Update ---------

		 ----- Start Add ManagementStructureDetails Header Data----
		 INSERT INTO [dbo].[RepairOrderManagementStructureDetails]([ModuleID],[ReferenceID],[EntityMSID],
		 			[Level1Id],[Level1Name],[Level2Id],[Level2Name],[Level3Id],[Level3Name],[Level4Id],[Level4Name],[Level5Id],[Level5Name],
		 			[Level6Id],[Level6Name],[Level7Id],[Level7Name],[Level8Id],[Level8Name],[Level9Id],[Level9Name],[Level10Id],[Level10Name],
		 			[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted],[LastMSLevel],[AllMSlevels])
		 SELECT [ModuleID],@NewID,[EntityMSID],
		 			[Level1Id],[Level1Name],[Level2Id],[Level2Name],[Level3Id],[Level3Name],[Level4Id],[Level4Name],[Level5Id],[Level5Name],
		 			[Level6Id],[Level6Name],[Level7Id],[Level7Name],[Level8Id],[Level8Name],[Level9Id],[Level9Name],[Level10Id],[Level10Name],
		 			[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted],[LastMSLevel],[AllMSlevels]
		 FROM [dbo].[RepairOrderManagementStructureDetails] WITH(NOLOCK) 
		 WHERE [ReferenceID] = @VendorRFQRepairOrderId 
		 AND [ModuleID] = @ManagementStructureHeaderModuleId;
		 -----End ManagementStructureDetails Header---------

		 IF OBJECT_ID(N'tempdb..#tblRepairOrderPartSingle') IS NOT NULL    
		 BEGIN    
			 DROP TABLE #tblRepairOrderPartSingle     
		 END    
		 CREATE TABLE #tblRepairOrderPartSingle    
		 (    
			ID BIGINT NOT NULL IDENTITY,     
			VendorRFQROPartRecordId BIGINT NULL,    
			VendorRFQRepairOrderId BIGINT NULL, 
			MasterCompanyId INT NULL  
		 ) 
		 ------- Start Part Data ------------
		 IF EXISTS(SELECT 1 FROM [dbo].[VendorRFQRepairOrderPart] WITH(NOLOCK) WHERE [VendorRFQRepairOrderId] = @VendorRFQRepairOrderId)
		 BEGIN
				INSERT INTO #tblRepairOrderPartSingle(VendorRFQROPartRecordId,VendorRFQRepairOrderId,MasterCompanyId)
				SELECT VendorRFQROPartRecordId,VendorRFQRepairOrderId,MasterCompanyId
				FROM [dbo].[VendorRFQRepairOrderPart] WITH(NOLOCK) 
				WHERE [VendorRFQRepairOrderId] = @VendorRFQRepairOrderId
				AND [MasterCompanyId] = @MasterCompanyId;

				SELECT @ID = 1;    
				WHILE @ID <= (SELECT MAX(ID) FROM #tblRepairOrderPartSingle)         
				BEGIN
					SELECT @VendorRFQROPartRecordId = [VendorRFQROPartRecordId]
					FROM #tblRepairOrderPartSingle WITH(NOLOCK) WHERE [ID] = @ID;

					----Insert record in Part table --------
					INSERT INTO VendorRFQRepairOrderPart(
					   [VendorRFQRepairOrderId],[ItemMasterId],[PartNumber],[PartDescription],
					   [StockType],[ManufacturerId],[Manufacturer],[PriorityId],[Priority],[NeedByDate],[PromisedDate],[ConditionId],[Condition],
					   [QuantityOrdered],[UnitCost],[ExtendedCost],[WorkOrderId],[WorkOrderNo],[SubWorkOrderId],[SubWorkOrderNo],[SalesOrderId],
					   [SalesOrderNo],[ManagementStructureId],[Level1],[Level2],[Level3],[Level4],[Memo],[MasterCompanyId],[CreatedBy],[UpdatedBy],
					   [CreatedDate],[UpdatedDate],[IsActive],[IsDeleted],[RepairOrderId],[RepairOrderNumber],[UOMId],[UnitOfMeasure],[TraceableTo],
					   [TraceableToName],[TraceableToType],[TagTypeId],[TaggedBy],[TaggedByType],[TaggedByName],[TaggedByTypeName],[TagDate],[IsNoQuote])
					SELECT @NewID,[ItemMasterId],[PartNumber],[PartDescription],
						   [StockType],[ManufacturerId],[Manufacturer],[PriorityId],[Priority],[NeedByDate],[PromisedDate],[ConditionId],[Condition],
						   [QuantityOrdered],[UnitCost],[ExtendedCost],[WorkOrderId],[WorkOrderNo],[SubWorkOrderId],[SubWorkOrderNo],[SalesOrderId],
						   [SalesOrderNo],[ManagementStructureId],[Level1],[Level2],[Level3],[Level4],[Memo],[MasterCompanyId],[CreatedBy],[UpdatedBy],
						   [CreatedDate],[UpdatedDate],[IsActive],[IsDeleted],[RepairOrderId],[RepairOrderNumber],[UOMId],[UnitOfMeasure],[TraceableTo],
						   [TraceableToName],[TraceableToType],[TagTypeId],[TaggedBy],[TaggedByType],[TaggedByName],[TaggedByTypeName],[TagDate],[IsNoQuote]
					FROM [dbo].[VendorRFQRepairOrderPart] WITH(NOLOCK) 
					WHERE [VendorRFQRepairOrderId] = @VendorRFQRepairOrderId
						  AND [VendorRFQROPartRecordId] = @VendorRFQROPartRecordId
						  AND [MasterCompanyId] = @MasterCompanyId;
					------End Part table -----------

					SET @NewPartID = IDENT_CURRENT('VendorRFQRepairOrderPart');  

					----- Start Add ManagementStructureDetails Header Data----
					INSERT INTO [dbo].[RepairOrderManagementStructureDetails]([ModuleID],[ReferenceID],[EntityMSID],
		 	   				[Level1Id],[Level1Name],[Level2Id],[Level2Name],[Level3Id],[Level3Name],[Level4Id],[Level4Name],[Level5Id],[Level5Name],
		 	   				[Level6Id],[Level6Name],[Level7Id],[Level7Name],[Level8Id],[Level8Name],[Level9Id],[Level9Name],[Level10Id],[Level10Name],
		 	   				[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted],[LastMSLevel],[AllMSlevels])
					SELECT [ModuleID],@NewPartID,[EntityMSID],
		 	   				[Level1Id],[Level1Name],[Level2Id],[Level2Name],[Level3Id],[Level3Name],[Level4Id],[Level4Name],[Level5Id],[Level5Name],
		 	   				[Level6Id],[Level6Name],[Level7Id],[Level7Name],[Level8Id],[Level8Name],[Level9Id],[Level9Name],[Level10Id],[Level10Name],
		 	   				[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted],[LastMSLevel],[AllMSlevels]
					FROM [dbo].[RepairOrderManagementStructureDetails] WITH(NOLOCK) 
					WHERE [ReferenceID] = @VendorRFQROPartRecordId 
					AND [ModuleID] = @ManagementStructurePartModuleId;
					-----End ManagementStructureDetails Header---------

					--------Start Charges Tab ---------------
					 IF EXISTS (SELECT 1 FROM [dbo].[VendorRFQROCharges] WITH(NOLOCK) WHERE [VendorRFQRepairOrderId] = @VendorRFQRepairOrderId AND [VendorRFQROPartRecordId] = @VendorRFQROPartRecordId)    
					 BEGIN 
							INSERT INTO [dbo].[VendorRFQROCharges]
							([VendorRFQRepairOrderId],[VendorRFQROPartRecordId],[ChargesTypeId],[VendorId],[Quantity],[MarkupPercentageId],[Description]
							,[UnitCost],[ExtendedCost],[MasterCompanyId],[MarkupFixedPrice],[BillingMethodId],[BillingAmount],[BillingRate],[HeaderMarkupId]
							,[RefNum],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted],[HeaderMarkupPercentageId],[ItemMasterId]
							,[ConditionId],[LineNum],[PartNumber],[ManufacturerId],[Manufacturer],[UOMId])
							SELECT @NewID,[VendorRFQROPartRecordId],[ChargesTypeId],[VendorId],[Quantity],[MarkupPercentageId],[Description]
							,[UnitCost],[ExtendedCost],[MasterCompanyId],[MarkupFixedPrice],[BillingMethodId],[BillingAmount],[BillingRate],[HeaderMarkupId]
							,[RefNum],[CreatedBy],[UpdatedBy],GETUTCDATE(),GETUTCDATE(),[IsActive],[IsDeleted],[HeaderMarkupPercentageId],[ItemMasterId]
							,[ConditionId],[LineNum],[PartNumber],[ManufacturerId],[Manufacturer],[UOMId]
							FROM [dbo].[VendorRFQROCharges] WITH(NOLOCK) 
							WHERE [VendorRFQRepairOrderId] = @VendorRFQRepairOrderId AND [VendorRFQROPartRecordId] = @VendorRFQROPartRecordId;    
					 END
					 --------End Charges Tab  ---------------

					 --------Start Freight Tab ---------------
					 IF EXISTS (SELECT 1 FROM [dbo].[VendorRFQROFreight] WITH(NOLOCK) WHERE [VendorRFQRepairOrderId] = @VendorRFQRepairOrderId AND [VendorRFQROPartRecordId] = @VendorRFQROPartRecordId)    
					 BEGIN 
							INSERT INTO [dbo].[VendorRFQROFreight]
							([VendorRFQRepairOrderId],[VendorRFQROPartRecordId],[ItemMasterId],[PartNumber],[ShipViaId],
							[ShipViaName],[MarkupPercentageId],[MarkupFixedPrice],[HeaderMarkupId],[BillingMethodId],
							[BillingRate],[BillingAmount],[HeaderMarkupPercentageId],[Weight],[UOMId],[UOMName],[Length],
							[Width],[Height],[DimensionUOMId],[DimensionUOMName],[CurrencyId],[CurrencyName],[Amount],[Memo],
							[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted],[LineNum],
							[ManufacturerId],[Manufacturer])
							SELECT @NewID,[VendorRFQROPartRecordId],[ItemMasterId],[PartNumber],[ShipViaId],
							[ShipViaName],[MarkupPercentageId],[MarkupFixedPrice],[HeaderMarkupId],[BillingMethodId],
							[BillingRate],[BillingAmount],[HeaderMarkupPercentageId],[Weight],[UOMId],[UOMName],[Length],
							[Width],[Height],[DimensionUOMId],[DimensionUOMName],[CurrencyId],[CurrencyName],[Amount],[Memo],
							[MasterCompanyId],[CreatedBy],[UpdatedBy],GETUTCDATE(),GETUTCDATE(),[IsActive],[IsDeleted],[LineNum],
							[ManufacturerId],[Manufacturer]
							FROM [dbo].[VendorRFQROFreight] WITH(NOLOCK) 
							WHERE [VendorRFQRepairOrderId] = @VendorRFQRepairOrderId AND [VendorRFQROPartRecordId] = @VendorRFQROPartRecordId;    
					 END
					 --------End Freight Tab  ---------------

					SET @ID = @ID + 1;
				END
		 END
		 ---------End Part Data ------------------

		 --------Start Address Tab ---------------
		 IF EXISTS (SELECT 1 FROM [dbo].[AllAddress] WITH(NOLOCK) WHERE [ReffranceId] = @VendorRFQRepairOrderId AND ModuleId = @AddressModuleId)    
		 BEGIN 
				INSERT INTO [dbo].[AllAddress]([ReffranceId],[ModuleId],[UserType],[UserTypeName],[UserId],[UserName],[SiteId],[SiteName],    
				   [AddressId],[IsModuleOnly],[IsShippingAdd],[ShippingAccountNo],[Memo],[ContactId],[ContactName],[ContactPhoneNo],    
				   [Line1],[Line2],[Line3],[City],[StateOrProvince],[PostalCode],[CountryId],[Country],[MasterCompanyId],[CreatedBy],    
				   [UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted],[IsPrimary])    
				SELECT @NewID,@AddressModuleId,[UserType],[UserTypeName],[UserId],[UserName],[SiteId],[SiteName],    
				   [AddressId],[IsModuleOnly],[IsShippingAdd],[ShippingAccountNo],[Memo],[ContactId],[ContactName],[ContactPhoneNo],    
				   [Line1],[Line2],[Line3],[City],[StateOrProvince],[PostalCode],[CountryId],[Country],[MasterCompanyId],[CreatedBy],    
				   [UpdatedBy],GETDATE(),GETDATE(),1,0,[IsPrimary]    
			    FROM [dbo].[AllAddress] WITH(NOLOCK) WHERE [ReffranceId] = @VendorRFQRepairOrderId AND [ModuleId] = @AddressModuleId;    
    
				INSERT INTO [dbo].[AllShipVia]([ReferenceId],[ModuleId],[UserType],[ShipViaId],[ShippingCost],[HandlingCost],[IsModuleShipVia],    
					[ShippingAccountNo],[ShipVia],[ShippingViaId],[MasterCompanyId],[CreatedBy],[UpdatedBy] ,[CreatedDate] ,[UpdatedDate] ,    
					[IsActive] ,[IsDeleted])    
				SELECT @NewID,@AddressModuleId,[UserType],[ShipViaId],[ShippingCost],[HandlingCost],[IsModuleShipVia],    
					[ShippingAccountNo],[ShipVia],[ShippingViaId],[MasterCompanyId],[CreatedBy],[UpdatedBy] ,GETDATE() ,GETDATE(),    
					1,0     
				FROM [dbo].[AllShipVia] WITH(NOLOCK) 
				WHERE [ReferenceId] = @VendorRFQRepairOrderId AND [ModuleId] = @AddressModuleId;  
		 END
		 --------End Address Tab  ---------------

		 IF OBJECT_ID(N'tempdb..#tblRepairOrderDocuments') IS NOT NULL    
		 BEGIN    
			 DROP TABLE #tblRepairOrderDocuments     
		 END    
		 CREATE TABLE #tblRepairOrderDocuments    
		 (    
			ID BIGINT NOT NULL IDENTITY,  
			CommonDocumentDetailId BIGINT NULL,
			ReferenceId BIGINT NULL, 
			AttachmentId BIGINT NULL,    
			MasterCompanyId INT NULL  
		 ) 
		 -------Start Documnet Tab --------------
		 IF EXISTS (SELECT 1 FROM [dbo].[CommonDocumentDetails] WITH(NOLOCK) WHERE [ReferenceId] = @VendorRFQRepairOrderId)    
		 BEGIN
				INSERT INTO #tblRepairOrderDocuments(CommonDocumentDetailId,ReferenceId,AttachmentId)
				SELECT [CommonDocumentDetailId],[ReferenceId],[AttachmentId]
				FROM [dbo].[CommonDocumentDetails] WITH(NOLOCK) 
				WHERE [ReferenceId] = @VendorRFQRepairOrderId 
				AND [ModuleId] = @AttachmentModuleId 
				AND [MasterCompanyId] = @MasterCompanyId;

				SELECT @DocId = 1;    
				WHILE @DocId <= (SELECT MAX(ID) FROM #tblRepairOrderDocuments)         
				BEGIN
					 SELECT @CommonDocumentDetailId = [CommonDocumentDetailId],
							@ReferenceId = [ReferenceId], 
							@AttachmentId = [AttachmentId]
					 FROM #tblRepairOrderDocuments WITH(NOLOCK) WHERE [ID] = @DocId;

					 IF(@AttachmentId > 0)
					 BEGIN
						  ------------ Attachment --------
						  INSERT [dbo].[Attachment]([ModuleId],[ReferenceId],[MasterCompanyId],[CreatedBy],
								 [CreatedDate],[UpdatedBy],[UpdatedDate],[IsActive],[IsDeleted])
						  SELECT @AttachmentModuleId,@NewID,[MasterCompanyId],[CreatedBy],
								 [CreatedDate],[UpdatedBy],[UpdatedDate],[IsActive],[IsDeleted]
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
							[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted],
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
							[CreatedDate],[UpdatedDate],[CreatedBy],[UpdatedBy],[IsActive],[IsDeleted],[Name],
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
  
 COMMIT  TRANSACTION  
 END TRY   
 BEGIN CATCH        
  IF @@trancount > 0  
  PRINT 'ROLLBACK'  
    ROLLBACK TRANSACTION;  
    DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()   
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------  
              , @AdhocComments     VARCHAR(150)    = 'USP_DuplicateRFQRO'   
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ CAST(ISNULL(@VendorRFQRepairOrderId, '') AS varchar(100))  
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