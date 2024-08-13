/*********************           
 ** File:   [USP_DuplicateSpeedQuote]           
 ** Author:   Abhishek Jirawla  
 ** Description: Duplicate Speed Quote 
 ** Purpose:         
 ** Date:   07/25/2024
          
 ** PARAMETERS:           
   
 ** RETURN VALUE:           
  
 **********************           
  ** Change History           
 **********************           
 ** S NO   Date         Author  		Change Description            
 ** --   --------     -------			--------------------------------          
    1	07/25/2024	Abhishek Jirawla	Created
    2	08/06/2024	Rajesh Gami     	Implemented 'CustomerReference','IsCopyUnitPrice','IsCopyQty','IsCopyNote' for the make duplicate
**********************/
CREATE  PROCEDURE [dbo].[USP_DuplicateSpeedQuote]
	@SpeedQuoteId BIGINT,
	@MasterCompanyId INT,
	@CodeTypeId INT,
	@Username VARCHAR(250),
	@CustomerReference VARCHAR(100),
	@IsCopyUnitPrice BIT,
	@IsCopyQty BIT,
	@IsCopyNote BIT,
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
				 @SQModuleId BIGINT,
				 @AttachmentModuleId BIGINT,
				 @Id INT,
				 @DocId INT,
				 @NewID BIGINT,
				 @SpeedQuoteNumber VARCHAR(250),
				 @SpeedQuotePartId BIGINT,
				 @CreditTermName VARCHAR(250),
				 @NewPartID BIGINT; 

		SELECT @CustomerId = CustomerId FROM [dbo].[SpeedQuote] WITH(NOLOCK)  WHERE SpeedQuoteId = @SpeedQuoteId
		
		SELECT @OpenStatus = [Id] FROM [dbo].[MasterSpeedQuoteStatus] WITH(NOLOCK)  WHERE [Name] = 'Open'

		SELECT @PartOpenStatus = SOPartStatusId FROM [dbo].[SOPartStatus] WITH(NOLOCK)  WHERE PartStatus = 'Open'

		SELECT @CreditTermsId = CreditTermsId FROM [dbo].[CustomerFinancial] WITH(NOLOCK)  WHERE CustomerId = @CustomerId
		SELECT @CreditLimit = CreditLimit FROM [dbo].[CustomerFinancial] WITH(NOLOCK)  WHERE CustomerId = @CustomerId
		SELECT @ARBalance = ARBalance FROM [dbo].[CustomerCreditTermsHistory] WITH(NOLOCK)  WHERE CustomerId = @CustomerId

		SELECT @CreditTermName = [Name] FROM CreditTerms WITH(NOLOCK) WHERE [CreditTermsId] = @CreditTermsId

		SELECT @ManagementStructureHeaderModuleId = [ManagementStructureModuleId] FROM [dbo].[ManagementStructureModule] WITH(NOLOCK) WHERE [ModuleName] = 'SpeedQuote';

		SELECT @ManagementStructurePartModuleId = [ManagementStructureModuleId] FROM [dbo].[ManagementStructureModule] WITH(NOLOCK) WHERE [ModuleName] = 'SpeedQuote';

		SELECT @SQModuleId = ModuleId FROM [dbo].[Module] WITH(NOLOCK) WHERE [ModuleName] = 'SpeedQuote';

		SELECT @AttachmentModuleId = AttachmentModuleId FROM [dbo].[AttachmentModule] WITH(NOLOCK)  WHERE [Name] = 'SpeedQuote';

		SELECT @ValidForDays = ISNULL(ValidDays, 10), @IsApprovalRule = ISNULL(IsApprovalRule, 0) FROM SpeedQuoteSettings WITH(NOLOCK)

		SELECT @QuoteExpireDate = DATEADD(day, ISNULL(@ValidForDays, 10) , GETUTCDATE());
		
		SELECT @CurrentNummber = [CurrentNummber],@CodePrefix = [CodePrefix],@CodeSufix = [CodeSufix] FROM [dbo].[CodePrefixes] WITH(NOLOCK)    
        WHERE [CodeTypeId] = @CodeTypeId AND [MasterCompanyId] = @MasterCompanyId;

		SET @SpeedQuoteNumber = (SELECT * FROM dbo.udfGenerateCodeNumber(CAST(@CurrentNummber AS BIGINT) + 1, @CodePrefix, @CodeSufix)); 

		INSERT INTO [dbo].[SpeedQuote]
           ([SpeedQuoteTypeId], [OpenDate],[ValidForDays],[QuoteExpireDate],[AccountTypeId],[CustomerId],[CustomerContactId],[CustomerReference],[ContractReference],[SalesPersonId],[AgentName],[CustomerSeviceRepId]
		   ,[ProbabilityId],[LeadSourceId],[LeadSourceReference],[CreditLimit],[CreditTermId],[EmployeeId],[RestrictPMA],[RestrictDER],[ApprovedDate],[CurrencyId],[CustomerWarningId],[Memo],[Notes],[MasterCompanyId]
		   ,[CreatedBy],[CreatedDate],[UpdatedBy],[UpdatedDate],[IsDeleted],[StatusId],[StatusChangeDate],[ManagementStructureId],[Version],[AgentId],[QtyRequested],[QtyToBeQuoted],[SpeedQuoteNumber],[QuoteSentDate]
		   ,[IsNewVersionCreated],[IsActive],[QuoteParentId],[QuoteTypeName],[AccountTypeName],[CustomerName],[SalesPersonName],[CustomerServiceRepName],[ProbabilityName],[LeadSourceName],[CreditTermName],[EmployeeName]
		   ,[CurrencyName],[CustomerWarningName],[ManagementStructureName],[CustomerContactName],[VersionNumber],[CustomerCode],[CustomerContactEmail],[CreditLimitName],[StatusName],[Level1],[Level2],[Level3],
		   [Level4])
		(SELECT [SpeedQuoteTypeId], GETUTCDATE(), ISNULL(@ValidForDays, 10),@QuoteExpireDate,[AccountTypeId],[CustomerId],[CustomerContactId],@CustomerReference,[ContractReference],[SalesPersonId],[AgentName],[CustomerSeviceRepId]
		   ,[ProbabilityId],[LeadSourceId],[LeadSourceReference],@CreditLimit,@CreditTermsId,[EmployeeId],[RestrictPMA],[RestrictDER],[ApprovedDate],[CurrencyId],[CustomerWarningId],[Memo],[Notes],@MasterCompanyId
		   ,@Username,GETUTCDATE(),@Username,GETUTCDATE(),0,@OpenStatus,GETUTCDATE(),[ManagementStructureId],[Version],[AgentId],[QtyRequested],[QtyToBeQuoted],@SpeedQuoteNumber,[QuoteSentDate]
		   ,[IsNewVersionCreated],1,[QuoteParentId],[QuoteTypeName],[AccountTypeName],[CustomerName],[SalesPersonName],[CustomerServiceRepName],[ProbabilityName],[LeadSourceName],@CreditTermName,[EmployeeName]
		   ,[CurrencyName],[CustomerWarningName],[ManagementStructureName],[CustomerContactName],[VersionNumber],[CustomerCode],[CustomerContactEmail],[CreditLimitName],[StatusName],[Level1],[Level2],[Level3],
		   [Level4]
		FROM [dbo].[SpeedQuote] WITH(NOLOCK)
		WHERE SpeedQuoteId = @SpeedQuoteId)
		
		SET @NewID = IDENT_CURRENT('SpeedQuote');

		 ------Start Update CodePrifix No ------
		 UPDATE dbo.CodePrefixes SET CurrentNummber = CAST(@CurrentNummber AS BIGINT) + 1 WHERE CodeTypeId = @CodeTypeId AND MasterCompanyId = @MasterCompanyId;  
		 ------End CodePrifix Update ---------

		  ----- Start Add ManagementStructureDetails Header Data----
		 INSERT INTO [dbo].[WorkOrderManagementStructureDetails]([ModuleID],[ReferenceID],[EntityMSID],
		 			[Level1Id],[Level1Name],[Level2Id],[Level2Name],[Level3Id],[Level3Name],[Level4Id],[Level4Name],[Level5Id],[Level5Name],
		 			[Level6Id],[Level6Name],[Level7Id],[Level7Name],[Level8Id],[Level8Name],[Level9Id],[Level9Name],[Level10Id],[Level10Name],
		 			[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted],[LastMSLevel],[AllMSlevels])
		 SELECT @ManagementStructureHeaderModuleId,@NewID,[EntityMSID],
		 			[Level1Id],[Level1Name],[Level2Id],[Level2Name],[Level3Id],[Level3Name],[Level4Id],[Level4Name],[Level5Id],[Level5Name],
		 			[Level6Id],[Level6Name],[Level7Id],[Level7Name],[Level8Id],[Level8Name],[Level9Id],[Level9Name],[Level10Id],[Level10Name],
		 			@MasterCompanyId,@Username,@Username,GETUTCDATE(),GETUTCDATE(),[IsActive],[IsDeleted],[LastMSLevel],[AllMSlevels]
		 FROM [dbo].[WorkOrderManagementStructureDetails] WITH(NOLOCK) 
		 WHERE [ReferenceID] = @SpeedQuoteId 
		 AND [ModuleID] = @ManagementStructureHeaderModuleId;
		 -----End ManagementStructureDetails Header---------

		 IF OBJECT_ID(N'tempdb.#tblSpeedQuotePartSingle') IS NOT NULL    
		 BEGIN    
			 DROP TABLE #tblSpeedQuotePartSingle   
		 END    
		 CREATE TABLE #tblSpeedQuotePartSingle
		 (    
			ID BIGINT NOT NULL IDENTITY,     
			SpeedQuotePartId BIGINT NULL,    
			SpeedQuoteId BIGINT NULL, 
			MasterCompanyId INT NULL
		 ) 
		 ------- Start Part Data ------------
		 IF EXISTS(SELECT 1 FROM [dbo].[SpeedQuotePart] WITH(NOLOCK) WHERE SpeedQuoteId = @SpeedQuoteId)
		 BEGIN
				INSERT INTO #tblSpeedQuotePartSingle(SpeedQuotePartId,SpeedQuoteId,MasterCompanyId)
				SELECT SpeedQuotePartId,SpeedQuoteId,MasterCompanyId
				FROM [dbo].[SpeedQuotePart] WITH(NOLOCK) 
				WHERE [SpeedQuoteId] = @SpeedQuoteId
				SELECT @ID = 1;    
				WHILE @ID <= (SELECT MAX(ID) FROM #tblSpeedQuotePartSingle)
				BEGIN
					SELECT @SpeedQuotePartId = [SpeedQuotePartId]
					FROM #tblSpeedQuotePartSingle WITH(NOLOCK) WHERE [ID] = @ID;
					----Insert record in Part table --------
					INSERT INTO SpeedQuotePart(
						[SpeedQuoteId],[ItemMasterId],[QuantityRequested],[ConditionId],[UnitSalePrice],[UnitCost],[MarginAmount],[MarginPercentage],[SalesPriceExtended],[UnitCostExtended]
						,[MarginAmountExtended],[MarginPercentageExtended],[CreatedBy],[CreatedDate],[UpdatedBy],[UpdatedDate],[IsDeleted],[IsActive],[MasterCompanyId],[Notes],[CurrencyId]
						,[PartNumber],[PartDescription],[ConditionName],[CurrencyName],[ManufacturerId],[Manufacturer],[Type],[TAT],[StatusId],[StatusName],[ItemNo],[Code])
					SELECT @NewID,[ItemMasterId]
						,(CASE WHEN @IsCopyQty = 1 THEN QuantityRequested ELSE 0 END)
						,[ConditionId]
						,(CASE WHEN @IsCopyUnitPrice = 1 THEN UnitSalePrice ELSE 0 END)
						,[UnitCost],[MarginAmount],[MarginPercentage]
						,(CASE WHEN @IsCopyUnitPrice = 1 AND @IsCopyQty =  1 THEN SalesPriceExtended ELSE 0 END)
						,[UnitCostExtended]
						,[MarginAmountExtended],[MarginPercentageExtended],@Username,GETUTCDATE(),@Username,GETUTCDATE(),[IsDeleted],[IsActive],@MasterCompanyId
						,(CASE WHEN @IsCopyNote = 1 THEN [Notes] ELSE '' END)
						,[CurrencyId]
						,[PartNumber],[PartDescription],[ConditionName],[CurrencyName],[ManufacturerId],[Manufacturer],[Type],[TAT],[StatusId],[StatusName],[ItemNo],[Code]
					FROM [dbo].[SpeedQuotePart] WITH(NOLOCK) 
					WHERE SpeedQuoteId = @SpeedQuoteId
						  AND [SpeedQuotePartId] = @SpeedQuotePartId
					------End Part table -----------

					SET @NewPartID = IDENT_CURRENT('SpeedQuotePart'); 
					
					----- Start Add Exclusion Part Data----
					INSERT INTO [dbo].[SpeedQuoteExclusionPart]
						([SpeedQuoteId],[SpeedQuotePartId],[ItemMasterId],[PN],[Description],[ExPartNumber],[ExPartDescription],[ExQuantity]
						,[ExItemMasterId],[ExStockType],[ExUnitPrice],[ExExtPrice],[ExOccurance],[ExCurr],[ExNotes],[MasterCompanyId],[CreatedBy]
						,[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted],[ItemNo],[ConditionId])
					SELECT @NewID,@NewPartID,[ItemMasterId],[PN],[Description],[ExPartNumber],[ExPartDescription]
						,(CASE WHEN @IsCopyQty = 1 THEN [ExQuantity] ELSE 0 END)
						,[ExItemMasterId]
						,[ExStockType]
						,(CASE WHEN @IsCopyUnitPrice = 1 THEN [ExUnitPrice] ELSE 0 END)
						,(CASE WHEN @IsCopyUnitPrice = 1 AND @IsCopyQty =  1 THEN [ExExtPrice] ELSE 0 END)
						,[ExOccurance],[ExCurr],(CASE WHEN @IsCopyNote = 1 THEN [ExNotes] ELSE '' END),@MasterCompanyId,@Username
						,@Username,GETUTCDATE(),GETUTCDATE(),[IsActive],[IsDeleted],[ItemNo],[ConditionId]
					FROM [dbo].[SpeedQuoteExclusionPart] WITH(NOLOCK) 
					WHERE SpeedQuoteId = @SpeedQuoteId
						  AND [SpeedQuotePartId] = @SpeedQuotePartId

					SET @ID = @ID + 1;
				END
		 END
		 --------End Parts Tab  ---------------

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
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ CAST(ISNULL(@SpeedQuoteId, '') AS varchar(100))  
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