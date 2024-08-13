/*************************************************************             
 ** File:   [USP_DuplicateRFQPO]             
 ** Author:  Amit Ghediya 
 ** Description: This stored procedure is used to Make Duplicate vendor RFQ PO to New vendor RFQ PO  
 ** Purpose:           
 ** Date:   02/07/2024  
 ** PARAMETERS: 
 ** RETURN VALUE:             
 **************************************************************             
 ** Change History             
 **************************************************************             
 ** PR		Date			Author				Change Description              
 ** --		--------		-------				--------------------------------            
   1		02/07/2024		Amit Ghediya		Created
   2        29/07/2024		Rajesh Gami			Added Freight and Charges table logic
   3        31-07-2024      Shrey Chandegara    Modify due to can't insert data in VendorRFQPOPartReference.
   4	    07 Aug 2024	    Rajesh Gami     	Implemented 'CustomerReference','IsCopyUnitPrice','IsCopyQty','IsCopyNote' for the make duplicate & also added login UserName

-- EXEC [USP_DuplicateRFQPO] 78,0,1,61
************************************************************************/  
CREATE PROCEDURE [dbo].[USP_DuplicateRFQPO]  
	@VendorRFQPurchaseOrderId BIGINT,  
	@MasterCompanyId INT, 
	@CodeTypeId INT,
	@Username VARCHAR(250),
	@VendorReference VARCHAR(100),
	@IsCopyUnitPrice BIT,
	@IsCopyQty BIT,
	@IsCopyNote BIT,
	@Result INT OUTPUT  
AS  
BEGIN  
 SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED  
 SET NOCOUNT ON;  
		 DECLARE @CurrentNummber BIGINT,@ItemMasterId BIGINT = 0,
				 @CodePrefix VARCHAR(50),
				 @CodeSufix VARCHAR(50),
				 @RepairOrderNumber VARCHAR(250),
				 @IsEnforceApproval BIT,
				 @RONumber VARCHAR(250),
				 @NewStatusId INT = 1,
				 @NewStatus VARCHAR(50) = 'Open',
				 @VendorRFQPurchaseOrderNumber VARCHAR(250),
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
				 @VendorRFQPOPartRecordId BIGINT;  

		SELECT @ManagementStructureHeaderModuleId = [ManagementStructureModuleId] FROM [dbo].[ManagementStructureModule] WITH(NOLOCK) WHERE [ModuleName] = 'VendorRFQPOHeader';

		SELECT @ManagementStructurePartModuleId = [ManagementStructureModuleId] FROM [dbo].[ManagementStructureModule] WITH(NOLOCK) WHERE [ModuleName] = 'VendorRFQPOPart';

		SELECT @AddressModuleId = ModuleId FROM [dbo].[Module] WITH(NOLOCK) WHERE [ModuleName] = 'VendorRFQPurchaseOrder';

		SELECT @AttachmentModuleId = AttachmentModuleId FROM [dbo].[AttachmentModule] WHERE [Name] = 'VendorRFQPurchaseOrder';

		SELECT @VendorId = VendorId FROM [dbo].[VendorRFQPurchaseOrder] WITH(NOLOCK) WHERE [VendorRFQPurchaseOrderId] = @VendorRFQPurchaseOrderId;

		SELECT @CreditLimit = V.[CreditLimit],@CreditTermsId = V.[CreditTermsId],@Terms = CT.[Name] 
		FROM [dbo].[Vendor] V WITH(NOLOCK)
		JOIN [dbo].[CreditTerms] CT WITH(NOLOCK) ON V.CreditTermsId = CT.CreditTermsId WHERE V.VendorId = @VendorId;

 BEGIN TRY  
 BEGIN TRANSACTION  

		SELECT @CurrentNummber = [CurrentNummber],@CodePrefix = [CodePrefix],@CodeSufix = [CodeSufix] FROM [dbo].[CodePrefixes] WITH(NOLOCK)    
        WHERE [CodeTypeId] = @CodeTypeId AND [MasterCompanyId] = @MasterCompanyId;  

		SET @VendorRFQPurchaseOrderNumber = (SELECT * FROM dbo.udfGenerateCodeNumber(CAST(@CurrentNummber AS BIGINT) + 1, @CodePrefix, @CodeSufix));  
		
		------ Add Header exiting data into new RFQPO -------

		---Check CreditLimit ----
		IF(ISNULL(@CreditLimit,0) = 0)
		BEGIN
			SELECT @CreditLimit = [CreditLimit], @CreditTermsId = [CreditTermsId] FROM [dbo].[VendorRFQPurchaseOrder] WITH(NOLOCK) 
		    WHERE [VendorRFQPurchaseOrderId] = @VendorRFQPurchaseOrderId;
		END

		INSERT INTO [dbo].[VendorRFQPurchaseOrder]([VendorRFQPurchaseOrderNumber],[OpenDate],[ClosedDate],[NeedByDate],[PriorityId],[Priority],[VendorId],[VendorName],    
					[VendorCode],[VendorContactId],[VendorContact],[VendorContactPhone],[CreditTermsId],[Terms],[CreditLimit],[RequestedBy],    
					[Requisitioner],[StatusId],[Status],[StatusChangeDate],[Resale],[DeferredReceiver],Memo,Notes,    
					[ManagementStructureId],[Level1],[Level2],[Level3],[Level4],[MasterCompanyId],    
					[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted],[PDFPath],[IsFromBulkPO],FreightBilingMethodId,TotalFreight,
					ChargesBilingMethodId,TotalCharges,VendorReference)    
         SELECT @VendorRFQPurchaseOrderNumber,[OpenDate],[ClosedDate],[NeedByDate],[PriorityId],[Priority],[VendorId],[VendorName],    
					[VendorCode],[VendorContactId],[VendorContact],[VendorContactPhone],@CreditTermsId,@Terms,@CreditLimit,[RequestedBy],    
					[Requisitioner],@NewStatusId,@NewStatus,[StatusChangeDate],[Resale],[DeferredReceiver],[Memo],[Notes],    
					[ManagementStructureId],[Level1],[Level2],[Level3],[Level4],@MasterCompanyId,    
					@Username,@Username,GETUTCDATE(),GETUTCDATE(),1,0,PDFPath,IsFromBulkPO,FreightBilingMethodId,TotalFreight,
					ChargesBilingMethodId,TotalCharges,@VendorReference  
         FROM [dbo].[VendorRFQPurchaseOrder] WITH(NOLOCK) 
		 WHERE [VendorRFQPurchaseOrderId] = @VendorRFQPurchaseOrderId;

		 SET @NewID = IDENT_CURRENT('VendorRFQPurchaseOrder');    
		 ------ End Header add new RFQPO-------

		 ------Start Update CodePrifix No ------
		 UPDATE dbo.CodePrefixes SET CurrentNummber = CAST(@CurrentNummber AS BIGINT) + 1 WHERE CodeTypeId = @CodeTypeId AND MasterCompanyId = @MasterCompanyId;  
		 ------End CodePrifix Update ---------

		 ----- Start Add ManagementStructureDetails Header Data----
		 INSERT INTO [dbo].[PurchaseOrderManagementStructureDetails]([ModuleID],[ReferenceID],[EntityMSID],
		 			[Level1Id],[Level1Name],[Level2Id],[Level2Name],[Level3Id],[Level3Name],[Level4Id],[Level4Name],[Level5Id],[Level5Name],
		 			[Level6Id],[Level6Name],[Level7Id],[Level7Name],[Level8Id],[Level8Name],[Level9Id],[Level9Name],[Level10Id],[Level10Name],
		 			[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted],[LastMSLevel],[AllMSlevels])
		 SELECT [ModuleID],@NewID,[EntityMSID],
		 			[Level1Id],[Level1Name],[Level2Id],[Level2Name],[Level3Id],[Level3Name],[Level4Id],[Level4Name],[Level5Id],[Level5Name],
		 			[Level6Id],[Level6Name],[Level7Id],[Level7Name],[Level8Id],[Level8Name],[Level9Id],[Level9Name],[Level10Id],[Level10Name],
		 			@MasterCompanyId,@Username,@Username,[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted],[LastMSLevel],[AllMSlevels]
		 FROM [dbo].[PurchaseOrderManagementStructureDetails] WITH(NOLOCK) 
		 WHERE [ReferenceID] = @VendorRFQPurchaseOrderId 
		 AND [ModuleID] = @ManagementStructureHeaderModuleId;
		 -----End ManagementStructureDetails Header---------

		 IF OBJECT_ID(N'tempdb..#tblPurchaseOrderPartSingle') IS NOT NULL    
		 BEGIN    
			 DROP TABLE #tblPurchaseOrderPartSingle     
		 END    
		 CREATE TABLE #tblPurchaseOrderPartSingle    
		 (    
			ID BIGINT NOT NULL IDENTITY,     
			VendorRFQPOPartRecordId BIGINT NULL,    
			VendorRFQPurchaseOrderId BIGINT NULL, 
			MasterCompanyId INT NULL  
		 ) 
		 ------- Start Part Data ------------
		 IF EXISTS(SELECT 1 FROM [dbo].[VendorRFQPurchaseOrderPart] WITH(NOLOCK) WHERE VendorRFQPurchaseOrderId = @VendorRFQPurchaseOrderId)
		 BEGIN
				INSERT INTO #tblPurchaseOrderPartSingle(VendorRFQPOPartRecordId,VendorRFQPurchaseOrderId,MasterCompanyId)
				SELECT VendorRFQPOPartRecordId,VendorRFQPurchaseOrderId,MasterCompanyId
				FROM [dbo].[VendorRFQPurchaseOrderPart] WITH(NOLOCK) 
				WHERE [VendorRFQPurchaseOrderId] = @VendorRFQPurchaseOrderId
				

				SELECT @ID = 1;    
				WHILE @ID <= (SELECT MAX(ID) FROM #tblPurchaseOrderPartSingle)         
				BEGIN
					SELECT @VendorRFQPOPartRecordId = [VendorRFQPOPartRecordId]
					FROM #tblPurchaseOrderPartSingle WITH(NOLOCK) WHERE [ID] = @ID;

					----Insert record in Part table --------
					INSERT INTO VendorRFQPurchaseOrderPart(
					   [VendorRFQPurchaseOrderId],[ItemMasterId],[PartNumber],[PartDescription],
					   [StockType],[ManufacturerId],[Manufacturer],[PriorityId],[Priority],[NeedByDate],[PromisedDate],[ConditionId],[Condition],
					   [QuantityOrdered],[UnitCost],[ExtendedCost],[WorkOrderId],[WorkOrderNo],[SubWorkOrderId],[SubWorkOrderNo],[SalesOrderId],
					   [SalesOrderNo],[ManagementStructureId],[Level1],[Level2],[Level3],[Level4],[Memo],[MasterCompanyId],[CreatedBy],[UpdatedBy],
					   [CreatedDate],[UpdatedDate],[IsActive],[IsDeleted],[PurchaseOrderId],[PurchaseOrderNumber],[UOMId],[UnitOfMeasure],[TraceableTo],
					   [TraceableToName],[TraceableToType],[TagTypeId],[TaggedBy],[TaggedByType],[TaggedByName],[TaggedByTypeName],[TagDate],[IsNoQuote])
					SELECT @NewID,[ItemMasterId],[PartNumber],[PartDescription],
						   [StockType],[ManufacturerId],[Manufacturer],[PriorityId],[Priority],[NeedByDate],[PromisedDate],[ConditionId],[Condition],
						   (CASE WHEN @IsCopyQty = 1 THEN [QuantityOrdered] ELSE 0 END),(CASE WHEN @IsCopyUnitPrice = 1 THEN [UnitCost] ELSE 0 END),
						   (CASE WHEN @IsCopyUnitPrice = 1 AND @IsCopyQty =  1 THEN [ExtendedCost] ELSE 0 END),NULL,NULL,NULL,NULL,NULL,
						   NULL,[ManagementStructureId],[Level1],[Level2],[Level3],[Level4],[Memo],@MasterCompanyId,@Username,@Username,
						   [CreatedDate],[UpdatedDate],[IsActive],[IsDeleted],NULL,NULL,[UOMId],[UnitOfMeasure],[TraceableTo],
						   [TraceableToName],[TraceableToType],[TagTypeId],[TaggedBy],[TaggedByType],[TaggedByName],[TaggedByTypeName],[TagDate],[IsNoQuote]
					FROM [dbo].[VendorRFQPurchaseOrderPart] WITH(NOLOCK) 
					WHERE [VendorRFQPurchaseOrderId] = @VendorRFQPurchaseOrderId
						  AND [VendorRFQPOPartRecordId] = @VendorRFQPOPartRecordId
					------End Part table -----------

					SET @NewPartID = IDENT_CURRENT('VendorRFQPurchaseOrderPart');  
					SET @ItemMasterId = (SELECT TOP 1 ItemMasterId FROM DBO.VendorRFQPurchaseOrderPart WHERE VendorRFQPOPartRecordId = @NewPartID)
					 /**************START:  RFQ PO Freight Data Copy ***************/
					 IF EXISTS (SELECT 1 FROM [dbo].[VendorRFQPOFreight] WITH(NOLOCK) WHERE [VendorRFQPurchaseOrderId] = @VendorRFQPurchaseOrderId AND ItemMasterId = @ItemMasterId AND LineNum = @Id AND ISNULL(IsDeleted,0) = 0)
					 BEGIN
						INSERT INTO [dbo].[VendorRFQPOFreight]
						   ([VendorRFQPurchaseOrderId],[VendorRFQPOPartRecordId],[ItemMasterId],[PartNumber],[ShipViaId],[ShipViaName],[MarkupPercentageId],[MarkupFixedPrice]
						   ,[HeaderMarkupId],[BillingMethodId],[BillingRate],[BillingAmount],[HeaderMarkupPercentageId],[Weight],[UOMId],[UOMName],[Length],[Width],[Height]
						   ,[DimensionUOMId],[DimensionUOMName],[CurrencyId],[CurrencyName],[Amount],[Memo],[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate]
						   ,[UpdatedDate],[IsActive],[IsDeleted],[LineNum],[ManufacturerId],[Manufacturer])
						SELECT
						   @NewID ,@NewPartID,ItemMasterId,PartNumber ,ShipViaId ,ShipViaName ,MarkupPercentageId ,MarkupFixedPrice ,HeaderMarkupId ,BillingMethodId ,BillingRate
						   ,BillingAmount ,HeaderMarkupPercentageId,Weight ,UOMId ,UOMName ,Length ,Width ,Height,DimensionUOMId ,DimensionUOMName ,CurrencyId,CurrencyName,Amount
						   ,Memo ,@MasterCompanyId,@Username ,@Username ,GETUTCDATE() ,GETUTCDATE(),IsActive,IsDeleted ,@Id,ManufacturerId,Manufacturer 
						FROM [dbo].[VendorRFQPOFreight] WITH(NOLOCK) 
						WHERE [VendorRFQPurchaseOrderId] = @VendorRFQPurchaseOrderId AND ISNULL(IsDeleted,0) = 0 AND ItemMasterId = @ItemMasterId AND LineNum = @Id
					 END
					 /************** END:  RFQ PO Freight Data Copy ***************/

					 /**************START:  RFQ PO Charges Data Copy ***************/
					 IF EXISTS (SELECT 1 FROM [dbo].[VendorRFQPOCharges] WITH(NOLOCK) WHERE [VendorRFQPurchaseOrderId] = @VendorRFQPurchaseOrderId AND ItemMasterId = @ItemMasterId AND LineNum = @Id AND ISNULL(IsDeleted,0) = 0)
					 BEGIN
						INSERT INTO [dbo].[VendorRFQPOCharges]
					   ([VendorRFQPurchaseOrderId],[VendorRFQPOPartRecordId],[ChargesTypeId],[VendorId],[Quantity],[MarkupPercentageId],[Description],[UnitCost],[ExtendedCost]
					   ,[MasterCompanyId],[MarkupFixedPrice],[BillingMethodId],[BillingAmount],[BillingRate],[HeaderMarkupId],[RefNum],[CreatedBy],[UpdatedBy],[CreatedDate]
					   ,[UpdatedDate],[IsActive],[IsDeleted],[HeaderMarkupPercentageId],[VendorName],[ChargeName],[MarkupName],[ItemMasterId],[PartNumber]
					   ,[ConditionId],[LineNum],[ManufacturerId],[Manufacturer],[UOMId])
					 SELECT
						@NewID,@NewPartID,ChargesTypeId,VendorId ,Quantity,MarkupPercentageId,Description ,UnitCost,ExtendedCost,@MasterCompanyId,MarkupFixedPrice,BillingMethodId
					   ,BillingAmount,BillingRate,HeaderMarkupId,RefNum,@Username,@Username,GETUTCDATE(),GETUTCDATE(),IsActive,IsDeleted ,HeaderMarkupPercentageId,VendorName,ChargeName
					   ,MarkupName,ItemMasterId,PartNumber,ConditionId,@Id,ManufacturerId ,Manufacturer,UOMId 
					   FROM DBO.VendorRFQPOCharges WITH(NOLOCK)  
					   WHERE [VendorRFQPurchaseOrderId] = @VendorRFQPurchaseOrderId AND ISNULL(IsDeleted,0) = 0 AND ItemMasterId = @ItemMasterId AND LineNum = @Id
					 END
					 
					 /************** END:  RFQ PO Charges Data Copy ***************/
					----- Start Add ManagementStructureDetails Header Data----
					INSERT INTO [dbo].[PurchaseOrderManagementStructureDetails]([ModuleID],[ReferenceID],[EntityMSID],
		 	   				[Level1Id],[Level1Name],[Level2Id],[Level2Name],[Level3Id],[Level3Name],[Level4Id],[Level4Name],[Level5Id],[Level5Name],
		 	   				[Level6Id],[Level6Name],[Level7Id],[Level7Name],[Level8Id],[Level8Name],[Level9Id],[Level9Name],[Level10Id],[Level10Name],
		 	   				[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted],[LastMSLevel],[AllMSlevels])
					SELECT [ModuleID],@NewPartID,[EntityMSID],
		 	   				[Level1Id],[Level1Name],[Level2Id],[Level2Name],[Level3Id],[Level3Name],[Level4Id],[Level4Name],[Level5Id],[Level5Name],
		 	   				[Level6Id],[Level6Name],[Level7Id],[Level7Name],[Level8Id],[Level8Name],[Level9Id],[Level9Name],[Level10Id],[Level10Name],
		 	   				@MasterCompanyId,@Username,@Username,[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted],[LastMSLevel],[AllMSlevels]
					FROM [dbo].[PurchaseOrderManagementStructureDetails] WITH(NOLOCK) 
					WHERE [ReferenceID] = @VendorRFQPOPartRecordId 
					AND [ModuleID] = @ManagementStructurePartModuleId;
					-----End ManagementStructureDetails Header---------

					------- Start Part Refrence Data ------------
					--IF EXISTS(SELECT 1 FROM [dbo].[VendorRFQPurchaseOrderPartReference] WITH(NOLOCK) WHERE VendorRFQPurchaseOrderId = @VendorRFQPurchaseOrderId)
					--BEGIN
					--		INSERT INTO VendorRFQPurchaseOrderPartReference([VendorRFQPurchaseOrderId],[VendorRFQPOPartRecordId],[ModuleId],[ReferenceId],[Qty],[RequestedQty],[IsReserved],[MasterCompanyId],
					--			   [CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted])
					--		SELECT @NewID,@NewPartID,[ModuleId],[ReferenceId],[Qty],[RequestedQty],[IsReserved],[MasterCompanyId],
					--			   [CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted]
					--		FROM [dbo].[VendorRFQPurchaseOrderPartReference] WITH(NOLOCK) 
					--		WHERE [VendorRFQPurchaseOrderId] = @VendorRFQPurchaseOrderId
					--		AND [VendorRFQPOPartRecordId] = @VendorRFQPOPartRecordId
					--		AND [MasterCompanyId] = @MasterCompanyId;
					--END
					------ End Part Refrence Data-----------

					SET @ID = @ID + 1;
				END
		 END
		 ---------End Part Data ------------------

		 --------Start Address Tab ---------------
		 IF EXISTS (SELECT 1 FROM [dbo].[AllAddress] WITH(NOLOCK) WHERE [ReffranceId] = @VendorRFQPurchaseOrderId AND ModuleId = @AddressModuleId)    
		 BEGIN 
				INSERT INTO [dbo].[AllAddress]([ReffranceId],[ModuleId],[UserType],[UserTypeName],[UserId],[UserName],[SiteId],[SiteName],    
				   [AddressId],[IsModuleOnly],[IsShippingAdd],[ShippingAccountNo],[Memo],[ContactId],[ContactName],[ContactPhoneNo],    
				   [Line1],[Line2],[Line3],[City],[StateOrProvince],[PostalCode],[CountryId],[Country],[MasterCompanyId],[CreatedBy],    
				   [UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted],[IsPrimary])    
				SELECT @NewID,@AddressModuleId,[UserType],[UserTypeName],[UserId],[UserName],[SiteId],[SiteName],    
				   [AddressId],[IsModuleOnly],[IsShippingAdd],[ShippingAccountNo],[Memo],[ContactId],[ContactName],[ContactPhoneNo],    
				   [Line1],[Line2],[Line3],[City],[StateOrProvince],[PostalCode],[CountryId],[Country],[MasterCompanyId],@Username,    
				   @Username,GETUTCDATE(),GETUTCDATE(),1,0,[IsPrimary]    
			    FROM [dbo].[AllAddress] WITH(NOLOCK) WHERE [ReffranceId] = @VendorRFQPurchaseOrderId AND [ModuleId] = @AddressModuleId;    
    
				INSERT INTO [dbo].[AllShipVia]([ReferenceId],[ModuleId],[UserType],[ShipViaId],[ShippingCost],[HandlingCost],[IsModuleShipVia],    
					[ShippingAccountNo],[ShipVia],[ShippingViaId],[MasterCompanyId],[CreatedBy],[UpdatedBy] ,[CreatedDate] ,[UpdatedDate] ,    
					[IsActive] ,[IsDeleted])    
				SELECT @NewID,@AddressModuleId,[UserType],[ShipViaId],[ShippingCost],[HandlingCost],[IsModuleShipVia],    
					[ShippingAccountNo],[ShipVia],[ShippingViaId],@MasterCompanyId,@Username,@Username ,GETUTCDATE() ,GETUTCDATE(),    
					1,0     
				FROM [dbo].[AllShipVia] WITH(NOLOCK) 
				WHERE [ReferenceId] = @VendorRFQPurchaseOrderId AND [ModuleId] = @AddressModuleId;  
		 END
		 --------End Address Tab  ---------------

		 -------Start Documnet Tab --------------
		 IF OBJECT_ID(N'tempdb..#tblPurchasOrderDocuments') IS NOT NULL    
		 BEGIN    
			 DROP TABLE #tblPurchasOrderDocuments    
		 END    
		 CREATE TABLE #tblPurchasOrderDocuments    
		 (    
			ID BIGINT NOT NULL IDENTITY,  
			CommonDocumentDetailId BIGINT NULL,
			ReferenceId BIGINT NULL, 
			AttachmentId BIGINT NULL,    
			MasterCompanyId INT NULL  
		 ) 

		 IF EXISTS (SELECT 1 FROM [dbo].[CommonDocumentDetails] WITH(NOLOCK) WHERE [ReferenceId] = @VendorRFQPurchaseOrderId)    
		 BEGIN
				INSERT INTO #tblPurchasOrderDocuments(CommonDocumentDetailId,ReferenceId,AttachmentId)
				SELECT [CommonDocumentDetailId],[ReferenceId],[AttachmentId]
				FROM [dbo].[CommonDocumentDetails] WITH(NOLOCK) 
				WHERE [ReferenceId] = @VendorRFQPurchaseOrderId 
				AND [ModuleId] = @AttachmentModuleId 
				AND [MasterCompanyId] = @MasterCompanyId;

				SELECT @DocId = 1;    
				WHILE @DocId <= (SELECT MAX(ID) FROM #tblPurchasOrderDocuments)         
				BEGIN
					 SELECT @CommonDocumentDetailId = [CommonDocumentDetailId],
							@ReferenceId = [ReferenceId], 
							@AttachmentId = [AttachmentId]
					 FROM #tblPurchasOrderDocuments WITH(NOLOCK) WHERE [ID] = @DocId;

					 IF(@AttachmentId > 0)
					 BEGIN
						  ------------ Attachment --------
						  INSERT [dbo].[Attachment]([ModuleId],[ReferenceId],[MasterCompanyId],[CreatedBy],
								 [CreatedDate],[UpdatedBy],[UpdatedDate],[IsActive],[IsDeleted])
						  SELECT @AttachmentModuleId,@NewID,[MasterCompanyId],@Username,
								 [CreatedDate],@Username,[UpdatedDate],[IsActive],[IsDeleted]
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
								 @Username,@Username,[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted],
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
							[CreatedDate],[UpdatedDate],@Username,@Username,[IsActive],[IsDeleted],[Name],
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
              , @AdhocComments     VARCHAR(150)    = 'USP_DuplicateRFQPO'   
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ CAST(ISNULL(@VendorRFQPurchaseOrderId, '') AS varchar(100))  
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