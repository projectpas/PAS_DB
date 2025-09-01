/*************************************************************
 ** File:  [USP_CreateExchangeQuoteVersion] 
 ** Author:   Ekta Chandegra
 ** Description: This stored procedure is used to CreateExchangeQuoteVersion
 ** Purpose:
 ** Date:  09/01/2025	
 ** PARAMETERS: 
 ** RETURN VALUE:
 **************************************************************
  ** Change History
 **************************************************************
 ** PR   Date				Author				Change Description            
 ** --   --------			-------				--------------------------------          
    1    09/01/2025		  Ekta Chandegra		  Created

exec [dbo].[USP_CreateExchangeQuoteVersion] @CurrentExchangeQuoteId=132,@CustomerReference=N'',
@PriorityId=3,@SalesPersonId=73,@CreatedBy=N'roza diaz',@MasterCompanyId=1,@ManagementStructureId=1,
@EmployeeId=237,@CustomerContactId=124,@CustomerSeviceRepId=14,@Memo=N'',@Notes=N'',@FunctionalCurrencyId=1,
@ReportCurrencyId=1,@ForeignExchangeRate=1.000000
**************************************************************/

CREATE   PROCEDURE [dbo].[USP_CreateExchangeQuoteVersion]
	@CurrentExchangeQuoteId BIGINT,
	@CustomerReference VARCHAR(100),
	@PriorityId INT,
	@SalesPersonId BIGINT,
	@CreatedBy VARCHAR(256),
	@MasterCompanyId INT,
	@ManagementStructureId BIGINT,
	@EmployeeId BIGINT,
	@CustomerContactId BIGINT,
	@CustomerSeviceRepId BIGINT,
	@Memo NVARCHAR(MAX),	
	@Notes NVARCHAR(MAX),
	@FunctionalCurrencyId INT,
	@ReportCurrencyId INT,
	@ForeignExchangeRate DECIMAL(18,2)
AS
BEGIN
	SET NOCOUNT ON;
	BEGIN TRY
		DECLARE @NewExchangeQuoteId BIGINT, @NewExchangeQuotePartId BIGINT, @ExchangeQuoteAttachmentModuleId INT, @ExchangeQuoteModuleId INT;

		SELECT @ExchangeQuoteModuleId =  ModuleId FROM [dbo].[Module] WITH(NOLOCK) WHERE ModuleName = 'ExchangeQuote';

		SELECT @ExchangeQuoteAttachmentModuleId = AttachmentModuleId FROM [dbo].[AttachmentModule] WITH(NOLOCK) where Name = 'ExchangeQuote';

		DECLARE @Vesrion INT;
		-- Generate Version
		SELECT @Vesrion = Version FROM [dbo].[ExchangeQuote] WITH(NOLOCK) WHERE ExchangeQuoteId = @CurrentExchangeQuoteId;
		SET @Vesrion = @Vesrion + 1;

		DECLARE @VersionNumber VARCHAR(50);
		SET @VersionNumber = [dbo].[GenearteVersionNumber] (@Vesrion);

		DECLARE @SalesPersonName VARCHAR(80);
		SELECT TOP 1 @SalesPersonName = [FirstName] + ' ' + [LastName] FROM [dbo].[Employee] WITH(NOLOCK) WHERE EmployeeId = @SalesPersonId;

		DECLARE @CustomerContactName VARCHAR(200);
		SELECT TOP 1 @CustomerContactId = CustomerContactId, 
		@CustomerContactName = C.FirstName + ' '+ C.LastName + '-' + C.WorkPhone
		FROM [dbo].[CustomerContact] CC WITH(NOLOCK)
		LEFT JOIN [dbo].[Contact] C WITH(NOLOCK) ON C.ContactId = CC.ContactId
		WHERE customerContactId = @CustomerContactId;

		DECLARE @CustomerServiceRepName VARCHAR(80);
		SELECT TOP 1 @CustomerServiceRepName = [FirstName] + ' ' + [LastName] FROM [dbo].[Employee] WITH(NOLOCK) WHERE EmployeeId = @CustomerSeviceRepId;

		DECLARE @EmployeeName VARCHAR(80);
		SELECT TOP 1 @EmployeeName = [FirstName] + ' ' + [LastName] FROM [dbo].[Employee] WITH(NOLOCK) WHERE EmployeeId = @EmployeeId;

		DECLARE @EnforceApproval BIT, @EnforceEffectiveDate DATETIME
		SELECT TOP 1 @EnforceApproval = IsApprovalRule, @EnforceEffectiveDate = EffectiveDate
		FROM [dbo].[ExchangeQuoteSetting] WITH(NOLOCK) WHERE MasterCompanyId = @MasterCompanyId AND ISNULL(IsActive,0) = 1;

		DECLARE @AttachmentMap TABLE
		(
			OldAttachmentId BIGINT,
			NewAttachmentId BIGINT
		);


		INSERT INTO [dbo].[ExchangeQuote]
           ([Type]
           ,[TypeName]
           ,[ExchangeQuoteNumber]
           ,[CustomerReference]
           ,[OpenDate]
           ,[QuoteExpireDate]
           ,[Version]
           ,[VersionNumber]
           ,[VersionDate]
           ,[PriorityId]
           ,[StatusId]
           ,[StatusName]
           ,[StatusChangeDate]
           ,[CustomerId]
           ,[CustomerName]
           ,[CustomerCode]
           ,[CustomerContactId]
           ,[CreditLimit]
           ,[CreditTermId]
           ,[CreditLimitName]
           ,[CreditTermName]
           ,[BalanceDue]
           ,[SalesPersonId]
           ,[SalesPersonName]
           ,[ApprovedById]
           ,[ApprovedByName]
           ,[ApprovedDate]
           ,[CreatedBy]
           ,[CreatedDate]
           ,[UpdatedBy]
           ,[UpdatedDate]
           ,[IsDeleted]
           ,[IsActive]
           ,[MasterCompanyId]
           ,[ManagementStructureId]
           ,[EmployeeId]
           ,[IsApproved]
           ,[CustomerContactName]
           ,[CustomerContactEmail]
           ,[ValidForDays]
           ,[CustomerSeviceRepId]
           ,[CustomerServiceRepName]
           ,[CustomerWarningId]
           ,[CustomerWarningName]
           ,[EmployeeName]
           ,[ManagementStructureName1]
           ,[ManagementStructureName2]
           ,[ManagementStructureName3]
           ,[ManagementStructureName4]
           ,[Memo]
           ,[Notes]
           ,[AgentId]
           ,[AgentName]
           ,[ManagementStructureName]
           ,[AccountTypeId]
           ,[RestrictPMA]
           ,[RestrictDER]
           ,[ContractReference]
           ,[EnforceEffectiveDate]
           ,[IsEnforceApproval]
           ,[IsNewVersionCreated]
           ,[QuoteParentId]
           ,[IsFreightFlatRate]
           ,[FreightFlatRate]
           ,[IsChargeFlatRate]
           ,[ChargeFlatRate]
           ,[FunctionalCurrencyId]
           ,[ReportCurrencyId]
           ,[ForeignExchangeRate])
		SELECT
			[Type]
           ,[TypeName]
           ,[ExchangeQuoteNumber]
           ,@CustomerReference
           ,[OpenDate]
           ,[QuoteExpireDate]
           ,@Vesrion
           ,@VersionNumber
           ,[VersionDate]
           ,@PriorityId
           ,[StatusId]
           ,[StatusName]
           ,[StatusChangeDate]
           ,[CustomerId]
           ,[CustomerName]
           ,[CustomerCode]
           ,[CustomerContactId]
           ,[CreditLimit]
           ,[CreditTermId]
           ,[CreditLimitName]
           ,[CreditTermName]
           ,[BalanceDue]
           ,@SalesPersonId
           ,@SalesPersonName
           ,[ApprovedById]
           ,[ApprovedByName]
           ,[ApprovedDate]
           ,@CreatedBy
           ,GETUTCDATE()
           ,@CreatedBy
           ,GETUTCDATE()
           ,0
           ,1
           ,@MasterCompanyId
           ,@ManagementStructureId
           ,@EmployeeId
           ,[IsApproved]
           ,@CustomerContactName
           ,[CustomerContactEmail]
           ,[ValidForDays]
           ,@CustomerSeviceRepId
           ,@CustomerServiceRepName
           ,[CustomerWarningId]
           ,[CustomerWarningName]
           ,@EmployeeName
           ,[ManagementStructureName1]
           ,[ManagementStructureName2]
           ,[ManagementStructureName3]
           ,[ManagementStructureName4]
           ,@Memo
           ,@Notes
           ,[AgentId]
           ,[AgentName]
           ,[ManagementStructureName]
           ,[AccountTypeId]
           ,[RestrictPMA]
           ,[RestrictDER]
           ,[ContractReference]
           ,@EnforceEffectiveDate
           ,@EnforceApproval
           ,[IsNewVersionCreated]
           ,[QuoteParentId]
           ,[IsFreightFlatRate]
           ,[FreightFlatRate]
           ,[IsChargeFlatRate]
           ,[ChargeFlatRate]
           ,@FunctionalCurrencyId
           ,@ReportCurrencyId
           ,@ForeignExchangeRate
		FROM [dbo].[ExchangeQuote] WITH(NOLOCK)
		WHERE ExchangeQuoteId = @CurrentExchangeQuoteId;

		SET @NewExchangeQuoteId = SCOPE_IDENTITY();

		DECLARE @ModuleID INT;
		DECLARE @ReferenceID BIGINT;
		DECLARE @MSDetailsId BIGINT;

		-- Fetch Sales Order Quote ManagementStructureModule Id
		SELECT @ModuleID = ManagementStructureModuleId FROM [dbo].[ManagementStructureModule] WITH(NOLOCK) WHERE ModuleName = 'ExchangeQuoteHeader';
		
		SET @ReferenceID = @NewExchangeQuoteId;

		-- Step 2: Save MSDetails (assuming SaveMSDetails is a procedure)
		EXEC [dbo].[PROCAddExchangeMSData] @ReferenceId,@ManagementStructureId,@MasterCompanyId, @CreatedBy, @CreatedBy, @ModuleID, 1;

		----------------------------------------------------------------
		-- Step 3. Copy Parts
		----------------------------------------------------------------

		INSERT INTO [dbo].[ExchangeQuotePart]
		  ([ExchangeQuoteId]
		  ,[ItemMasterId]
		  ,[StockLineId]
		  ,[ExchangeCurrencyId]
		  ,[LoanCurrencyId]
		  ,[ExchangeListPrice]
		  ,[EntryDate]
		  ,[ExchangeOverhaulPrice]
		  ,[ExchangeCorePrice]
		  ,[EstOfFeeBilling]
		  ,[BillingStartDate]
		  ,[ExchangeOutrightPrice]
		  ,[DaysForCoreReturn]
		  ,[BillingIntervalDays]
		  ,[CurrencyId]
	      ,[Currency]
	      ,[DepositeAmount]
		  ,[CoreDueDate]
		  ,[MasterCompanyId]
		  ,[CreatedBy]
		  ,[CreatedDate]
		  ,[UpdatedBy]
		  ,[UpdatedDate]
		  ,[IsDeleted]
		  ,[IsActive]
		  ,[ConditionId]
		  ,[StockLineName]
		  ,[PartNumber]
		  ,[PartDescription]
		  ,[ConditionName]
		  ,[IsRemark]
		  ,[RemarkText]
		  ,[ExchangeOverhaulCost]
		  ,[QtyQuoted]
		  ,[MethodType]
		  ,[IsConvertedToSalesOrder]
		  ,[CustomerRequestDate]
		  ,[PromisedDate]
		  ,[EstimatedShipDate])
		SELECT 
			@NewExchangeQuoteId
		   ,[ItemMasterId]
		   ,[StockLineId]
		   ,[ExchangeCurrencyId]
		   ,[LoanCurrencyId]
		   ,[ExchangeListPrice]
		   ,[EntryDate]
		   ,[ExchangeOverhaulPrice]
		   ,[ExchangeCorePrice]
		   ,[EstOfFeeBilling]
		   ,[BillingStartDate]
		   ,[ExchangeOutrightPrice]
		   ,[DaysForCoreReturn]
		   ,[BillingIntervalDays]
		   ,[CurrencyId]
		   ,[Currency]
		   ,[DepositeAmount]
		   ,[CoreDueDate]
		   ,[MasterCompanyId]
		   ,[CreatedBy]
		   ,GETUTCDATE()
		   ,[UpdatedBy]
		   ,GETUTCDATE()
		   ,0
		   ,1
		   ,[ConditionId]
		   ,[StockLineName]
		   ,[PartNumber]
		   ,[PartDescription]
		   ,[ConditionName]
		   ,[IsRemark]
		   ,[RemarkText]
		   ,[ExchangeOverhaulCost]
		   ,[QtyQuoted]
		   ,[MethodType]
		   ,[IsConvertedToSalesOrder]
		   ,[CustomerRequestDate]
		   ,[PromisedDate]
		   ,[EstimatedShipDate]
		FROM  [dbo].[ExchangeQuotePart] WITH(NOLOCK)
		WHERE [ExchangeQuoteId] = @CurrentExchangeQuoteId

		SET @NewExchangeQuotePartId = SCOPE_IDENTITY();

 		SELECT @NewExchangeQuotePartId AS ExchangeQuotePartId;

		----------------------------------------------------------------
		-- 4. Copy Schedule Billings
		----------------------------------------------------------------
		INSERT INTO ExchangeQuoteScheduleBilling
		(
			ExchangeQuotePartId,
			ExchangeQuoteId,
			ScheduleBillingDate,
			PeriodicBillingAmount,
			Cogs,
			CogsAmount
		)
		SELECT
			@NewExchangeQuotePartId,
			@NewExchangeQuoteId,
			sb.ScheduleBillingDate,
			sb.PeriodicBillingAmount,
			sb.Cogs,
			sb.CogsAmount
		FROM ExchangeQuoteScheduleBilling sb WITH(NOLOCK)
		WHERE sb.ExchangeQuoteId = @CurrentExchangeQuoteId;

		----------------------------------------------------------------
		-- 5. Copy Freight
		----------------------------------------------------------------
		INSERT INTO [dbo].[ExchangeQuoteFreight]
		   ([ExchangeQuoteId]
		   ,[ExchangeQuotePartId]
		   ,[ShipViaId]
		   ,[Weight]
		   ,[Memo]
		   ,[Amount]
		   ,[MarkupPercentageId]
		   ,[MarkupFixedPrice]
		   ,[HeaderMarkupId]
		   ,[BillingMethodId]
		   ,[BillingRate]
		   ,[BillingAmount]
		   ,[Length]
		   ,[Width]
		   ,[Height]
		   ,[UOMId]
		   ,[DimensionUOMId]
		   ,[CurrencyId]
		   ,[MasterCompanyId]
		   ,[CreatedBy]
		   ,[UpdatedBy]
		   ,[CreatedDate]
		   ,[UpdatedDate]
		   ,[IsActive]
		   ,[IsDeleted]
		   ,[HeaderMarkupPercentageId]
		   ,[ShipViaName]
		   ,[UOMName]
		   ,[DimensionUOMName]
		   ,[CurrencyName])
		SELECT 
			@NewExchangeQuoteId
		   ,@NewExchangeQuotePartId
		   ,[ShipViaId]
		   ,[Weight]
		   ,[Memo]
		   ,[Amount]
		   ,[MarkupPercentageId]
		   ,[MarkupFixedPrice]
		   ,[HeaderMarkupId]
		   ,[BillingMethodId]
		   ,[BillingRate]
		   ,[BillingAmount]
		   ,[Length]
		   ,[Width]
		   ,[Height]
		   ,[UOMId]
		   ,[DimensionUOMId]
		   ,[CurrencyId]
		   ,[MasterCompanyId]
		   ,[CreatedBy]
		   ,[UpdatedBy]
		   ,GETUTCDATE()
		   ,GETUTCDATE()
		   ,1
		   ,0
		   ,[HeaderMarkupPercentageId]
		   ,[ShipViaName]
		   ,[UOMName]
		   ,[DimensionUOMName]
		   ,[CurrencyName]
		FROM [dbo].[ExchangeQuoteFreight] WITH(NOLOCK)
		WHERE ExchangeQuoteId = @CurrentExchangeQuoteId
		AND ISNULL(IsActive,0) = 1 AND ISNULL(IsDeleted,0) = 0;

		----------------------------------------------------------------
		-- 6. Copy Charges
		----------------------------------------------------------------
		INSERT INTO [dbo].[ExchangeQuoteCharges]
		   ([ExchangeQuoteId]
		   ,[ExchangeQuotePartId]
		   ,[ChargesTypeId]
		   ,[VendorId]
		   ,[Quantity]
		   ,[MarkupPercentageId]
		   ,[Description]
		   ,[UnitCost]
		   ,[ExtendedCost]
		   ,[MasterCompanyId]
		   ,[MarkupFixedPrice]
		   ,[BillingMethodId]
		   ,[BillingAmount]
		   ,[BillingRate]
		   ,[HeaderMarkupId]
		   ,[RefNum]
		   ,[CreatedBy]
		   ,[UpdatedBy]
		   ,[CreatedDate]
		   ,[UpdatedDate]
		   ,[IsActive]
		   ,[IsDeleted]
		   ,[HeaderMarkupPercentageId]
		   ,[VendorName]
		   ,[ChargeName]
		   ,[MarkupName]
		   ,[UOMId])
		SELECT
			@NewExchangeQuoteId
			,@NewExchangeQuotePartId
			,[ChargesTypeId]
			,[VendorId]
			,[Quantity]
			,[MarkupPercentageId]
			,[Description]
			,[UnitCost]
			,[ExtendedCost]
			,[MasterCompanyId]
			,[MarkupFixedPrice]
			,[BillingMethodId]
			,[BillingAmount]
			,[BillingRate]
			,[HeaderMarkupId]
			,[RefNum]
			,[CreatedBy]
			,[UpdatedBy]
			,GETUTCDATE()
			,GETUTCDATE()
			,1
			,0
			,[HeaderMarkupPercentageId]
			,[VendorName]
			,[ChargeName]
			,[MarkupName]
			,[UOMId]
		   FROM [dbo].[ExchangeQuoteCharges] WITH(NOLOCK)
		   WHERE ExchangeQuoteId = @CurrentExchangeQuoteId
		   AND ISNULL(IsActive,0) = 1 AND ISNULL(IsDeleted,0) = 0;

		 ----------------------------------------------------------------
		 -- 7. Copy Documents (Corrected)
		 ----------------------------------------------------------------

		INSERT INTO [dbo].[Attachment]
			([ModuleId], [ReferenceId], [MasterCompanyId], [CreatedBy], [CreatedDate], [UpdatedBy], [UpdatedDate], [IsActive], [IsDeleted], [SubModuleId], [SubReferenceId])
		OUTPUT inserted.SubReferenceId, inserted.AttachmentId
		INTO @AttachmentMap (OldAttachmentId, NewAttachmentId)
		SELECT
			A.[ModuleId],
			@NewExchangeQuoteId,
			A.[MasterCompanyId],
			@CreatedBy,
			GETUTCDATE(),
			@CreatedBy,
			GETUTCDATE(),
			1,
			0,
			A.[SubModuleId],
			A.AttachmentId -- This is the key part - we're using the old ID to create the map
		FROM [dbo].[Attachment] A WITH(NOLOCK)
		WHERE A.AttachmentId IN (SELECT DISTINCT AttachmentId FROM [dbo].[CommonDocumentDetails] WITH(NOLOCK) WHERE ReferenceId = @CurrentExchangeQuoteId AND ModuleId = @ExchangeQuoteAttachmentModuleId AND IsDeleted = 0);

		-- Now, copy AttachmentDetails using the map. This part is correct.
		INSERT INTO [dbo].[AttachmentDetails]
			([AttachmentId], [FileName], [Description], [Link], [FileFormat], [FileSize], [FileType], [CreatedDate], [UpdatedDate], [CreatedBy], [UpdatedBy], [IsActive], [IsDeleted], [Name], [Memo], [TypeId])
		SELECT
			map.NewAttachmentId,
			AD.[FileName],
			AD.[Description],
			AD.[Link],
			AD.[FileFormat],
			AD.[FileSize],
			AD.[FileType],
			GETUTCDATE(),
			GETUTCDATE(),
			@CreatedBy,
			@CreatedBy,
			1,
			0,
			AD.[Name],
			AD.[Memo],
			AD.[TypeId]
		FROM [dbo].[AttachmentDetails] AD WITH(NOLOCK)
		JOIN @AttachmentMap map ON AD.AttachmentId = map.OldAttachmentId
		WHERE AD.IsActive = 1 AND AD.IsDeleted = 0;

		-- Let's refine the final INSERT
		INSERT INTO [dbo].[CommonDocumentDetails]
			([ModuleId], [ReferenceId], [AttachmentId], [DocName], [DocMemo], [DocDescription], [MasterCompanyId], [CreatedBy], [UpdatedBy], [CreatedDate], [UpdatedDate], [IsActive], [IsDeleted], [DocumentTypeId], [ExpirationDate], [ReferenceIndex], [ModuleType], [SubModuleId], [SubReferenceId])
		SELECT
			CDD.[ModuleId],
			@NewExchangeQuoteId,
			map.NewAttachmentId, 
			CDD.[DocName],
			CDD.[DocMemo],
			CDD.[DocDescription],
			CDD.[MasterCompanyId],
			@CreatedBy,
			@CreatedBy,
			GETUTCDATE(),
			GETUTCDATE(),
			1,
			0,
			CDD.[DocumentTypeId],
			CDD.[ExpirationDate],
			CDD.[ReferenceIndex],
			CDD.[ModuleType],
			CDD.[SubModuleId],
			CDD.[SubReferenceId]
		FROM [dbo].[CommonDocumentDetails] CDD WITH(NOLOCK)
		JOIN [dbo].[Attachment] A WITH(NOLOCK) ON CDD.AttachmentId = A.AttachmentId AND A.ReferenceId = @CurrentExchangeQuoteId
		JOIN @AttachmentMap map ON A.AttachmentId = map.OldAttachmentId 
		WHERE CDD.ReferenceId = @CurrentExchangeQuoteId AND CDD.ModuleId = @ExchangeQuoteAttachmentModuleId AND CDD.IsDeleted = 0;
        
		----------------------------------------------------------------
		-- 8. Copy Address
		----------------------------------------------------------------
		 INSERT INTO [dbo].[AllAddress]
			 ([ReffranceId]
			 ,[ModuleId]
			 ,[UserType]
			 ,[UserTypeName]
			 ,[UserId]
			 ,[UserName]
			 ,[SiteId]
			 ,[SiteName]
			 ,[AddressId]
			 ,[IsModuleOnly]
			 ,[IsShippingAdd]
			 ,[ShippingAccountNo]
			 ,[Memo]
			 ,[ContactId]
			 ,[ContactName]
			 ,[ContactPhoneNo]
			 ,[Line1]
			 ,[Line2]
			 ,[Line3]
			 ,[City]
			 ,[StateOrProvince]
			 ,[PostalCode]
			 ,[CountryId]
			 ,[Country]
			 ,[MasterCompanyId]
			 ,[CreatedBy]
			 ,[UpdatedBy]
			 ,[CreatedDate]
			 ,[UpdatedDate]
			 ,[IsActive]
			 ,[IsDeleted]
			 ,[IsPrimary])
		SELECT
			[ReffranceId]
			,[ModuleId]
			,[UserType]
			,[UserTypeName]
			,[UserId]
			,[UserName]
			,[SiteId]
			,[SiteName]
			,[AddressId]
			,[IsModuleOnly]
			,[IsShippingAdd]
			,[ShippingAccountNo]
			,[Memo]
			,[ContactId]
			,[ContactName]
			,[ContactPhoneNo]
			,[Line1]
			,[Line2]
			,[Line3]
			,[City]
			,[StateOrProvince]
			,[PostalCode]
			,[CountryId]
			,[Country]
			,[MasterCompanyId]
			,[CreatedBy]
			,[UpdatedBy]
			,[CreatedDate]
			,[UpdatedDate]
			,[IsActive]
			,[IsDeleted]
			,[IsPrimary]
		FROM [dbo].[AllAddress] WITH(NOLOCK)
		WHERE ReffranceId = @CurrentExchangeQuoteId AND ModuleId = @ExchangeQuoteModuleId 
		AND ISNULL(IsActive,0) = 1 AND  ISNULL(IsDeleted,0) = 0;

		----------------------------------------------------------------
		-- 9. Copy Email
		----------------------------------------------------------------
		INSERT INTO [dbo].[Email]
			([EmailTypeId]
			,[Subject]
			,[ContactById]
			,[ContactDate]
			,[EmailBody]
			,[ToEmail]
			,[FromEmail]
			,[AttachmentId]
			,[ModuleId]
			,[ReferenceId]
			,[MasterCompanyId]
			,[CreatedBy]
			,[UpdatedBy]
			,[CreatedDate]
			,[UpdatedDate]
			,[IsActive]
			,[IsDeleted]
			,[BCC]
			,[CC]
			,[CustomerContactId]
			,[WorkOrderPartNo]
			,[Type]
			,[EmailStatus]
			,[EmailSentTime]
			,[IsAttach]
			,[EmailStatusId]
			,[AttemptCount]
			,[EmployeeId])
		SELECT 
			[EmailTypeId]
			,[Subject]
			,[ContactById]
			,[ContactDate]
			,[EmailBody]
			,[ToEmail]
			,[FromEmail]
			,[AttachmentId]
			,[ModuleId]
			,@NewExchangeQuoteId
			,[MasterCompanyId]
			,[CreatedBy]
			,[UpdatedBy]
			,GETUTCDATE()
			,GETUTCDATE()
			,1
			,0
			,[BCC]
			,[CC]
			,[CustomerContactId]
			,[WorkOrderPartNo]
			,[Type]
			,[EmailStatus]
			,[EmailSentTime]
			,[IsAttach]
			,[EmailStatusId]
			,[AttemptCount]
			,[EmployeeId]
		FROM [dbo].[Email] WITH(NOLOCK)
		WHERE ReferenceId = @CurrentExchangeQuoteId AND ModuleId = @ExchangeQuoteModuleId
		AND ISNULL(IsActive,0) = 1 AND  ISNULL(IsDeleted,0) = 0;

		----------------------------------------------------------------
		-- 10. Copy Memo
		----------------------------------------------------------------
		INSERT INTO [dbo].[Memo]
			([MemoCode]
			,[Description]
			,[ModuleId]
			,[ReferenceId]
			,[MasterCompanyId]
			,[CreatedBy]
			,[UpdatedBy]
			,[CreatedDate]
			,[UpdatedDate]
			,[IsActive]
			,[IsDeleted]
			,[WorkOrderPartNo])
		SELECT
		   [MemoCode]
		   ,[Description]
		   ,@ExchangeQuoteModuleId
		   ,@NewExchangeQuoteId
		   ,[MasterCompanyId]
		   ,[CreatedBy]
		   ,[UpdatedBy]
		   ,GETUTCDATE()
		   ,GETUTCDATE()
		   ,1
		   ,0
		   ,[WorkOrderPartNo]
		FROM [dbo].[Memo] WITH(NOLOCK)
		WHERE ReferenceId = @CurrentExchangeQuoteId AND ModuleId = @ExchangeQuoteModuleId
		AND ISNULL(IsActive,0) = 1 AND  ISNULL(IsDeleted,0) = 0;

		----------------------------------------------------------------
		-- 11. Copy Phone
	   ----------------------------------------------------------------
	   INSERT INTO [dbo].[CommunicationPhone]
		   ([PhoneNo]
		   ,[ContactById]
		   ,[Notes]
		   ,[ModuleId]
		   ,[ReferenceId]
		   ,[MasterCompanyId]
		   ,[CreatedBy]
		   ,[UpdatedBy]
		   ,[CreatedDate]
		   ,[UpdatedDate]
		   ,[IsActive]
		   ,[IsDeleted]
		   ,[CustomerContactId]
		   ,[WorkOrderPartNo]
		   ,[PhoneType])
 		SELECT 
			[PhoneNo]
		   ,[ContactById]
		   ,[Notes]
		   ,@ExchangeQuoteModuleId
		   ,@NewExchangeQuoteId
		   ,[MasterCompanyId]
		   ,[CreatedBy]
		   ,[UpdatedBy]
		   ,GETUTCDATE()
		   ,GETUTCDATE()
		   ,1
		   ,0
		   ,[CustomerContactId]
		   ,[WorkOrderPartNo]
		   ,[PhoneType]
		FROM [dbo].[CommunicationPhone] WITH(NOLOCK)
		WHERE ReferenceId = @CurrentExchangeQuoteId AND ModuleId = @ExchangeQuoteModuleId
		AND ISNULL(IsActive,0) = 1 AND  ISNULL(IsDeleted,0) = 0;

		----------------------------------------------------------------
		-- 12. Copy Text
		----------------------------------------------------------------
		INSERT INTO [dbo].[CommunicationText]
			([Mobile]
			,[ContactById]
			,[Notes]
			,[ModuleId]
			,[ReferenceId]
			,[MasterCompanyId]
			,[CreatedBy]
			,[UpdatedBy]
			,[CreatedDate]
			,[UpdatedDate]
			,[IsActive]
			,[IsDeleted]
			,[CustomerContactId]
			,[WorkOrderPartNo])
		SELECT
			[Mobile]
			,[ContactById]
			,[Notes]
			,[ModuleId]
			,@NewExchangeQuoteId
			,[MasterCompanyId]
			,[CreatedBy]
			,[UpdatedBy]
			,GETUTCDATE()
			,GETUTCDATE()
			,1
			,0
			,[CustomerContactId]
			,[WorkOrderPartNo]
		FROM [dbo].[CommunicationText] WITH(NOLOCK)
		WHERE ReferenceId = @CurrentExchangeQuoteId AND ModuleId = @ExchangeQuoteModuleId
		AND ISNULL(IsActive,0) = 1 AND  ISNULL(IsDeleted,0) = 0;

		----------------------------------------------------------------
		-- 13. Copy Approvals
		----------------------------------------------------------------
		INSERT INTO [dbo].[ExchangeQuoteApproval]
			([ExchangeQuoteId]
			,[ExchangeQuotePartId]
			,[CustomerId]
			,[InternalMemo]
			,[InternalSentDate]
			,[InternalApprovedDate]
			,[InternalApprovedById]
			,[CustomerSentDate]
			,[CustomerApprovedDate]
			,[CustomerApprovedById]
			,[ApprovalActionId]
			,[CustomerStatusId]
			,[InternalStatusId]
			,[CustomerMemo]
			,[MasterCompanyId]
			,[CreatedBy]
			,[UpdatedBy]
			,[CreatedDate]
			,[UpdatedDate]
			,[IsActive]
			,[IsDeleted]
			,[CustomerName]
			,[InternalApprovedBy]
			,[CustomerApprovedBy]
			,[ApprovalAction]
			,[CustomerStatus]
			,[InternalStatus]
			,[RejectedById]
			,[RejectedByName]
			,[RejectedDate]
			,[InternalSentToId]
			,[InternalSentToName]
			,[InternalSentById]
			,[InternalRejectedById]
			,[InternalRejectedBy]
			,[InternalRejectedDate])
		SELECT
			 @NewExchangeQuoteId
			,@NewExchangeQuotePartId
			,[CustomerId]
			,[InternalMemo]
			,[InternalSentDate]
			,[InternalApprovedDate]
			,[InternalApprovedById]
			,[CustomerSentDate]
			,[CustomerApprovedDate]
			,[CustomerApprovedById]
			,[ApprovalActionId]
			,[CustomerStatusId]
			,[InternalStatusId]
			,[CustomerMemo]
			,[MasterCompanyId]
			,[CreatedBy]
			,[UpdatedBy]
			,GETUTCDATE()
			,GETUTCDATE()
			,1
			,0
			,[CustomerName]
			,[InternalApprovedBy]
			,[CustomerApprovedBy]
			,[ApprovalAction]
			,[CustomerStatus]
			,[InternalStatus]
			,[RejectedById]
			,[RejectedByName]
			,[RejectedDate]
			,[InternalSentToId]
			,[InternalSentToName]
			,[InternalSentById]
			,[InternalRejectedById]
			,[InternalRejectedBy]
			,[InternalRejectedDate]
		FROM [dbo].[ExchangeQuoteApproval] WITH(NOLOCK)
		WHERE ExchangeQuoteId = @CurrentExchangeQuoteId
		AND ISNULL(IsActive,0) = 1 AND ISNULL(IsDeleted,0) = 0

		----------------------------------------------------------------
		-- 14. Update Old Quote to mark version created
		----------------------------------------------------------------
		UPDATE [dbo].[ExchangeQuote]
		SET IsNewVersionCreated = 1,
			UpdatedDate = GETUTCDATE()
		WHERE ExchangeQuoteId = @CurrentExchangeQuoteId;

		SELECT @NewExchangeQuoteId AS ExchangeQuoteId ,@NewExchangeQuotePartId AS ExchangeQuotePartId ;

	END TRY
	BEGIN CATCH
	END CATCH
END