/*********************             
 ** File:   [CreateSalesOrderQuote]             
 ** Author:  Ekta Chandegra 
 ** Description: This stored procedure is used to CreateUpdateSalesOrderQuote
 ** Purpose:           
 ** Date:  17/04/2025       
            
 ** PARAMETERS: @SalesOrderQuoteId bigint  
           
 ** RETURN VALUE:             
 **********************             
 ** Change History             
 **********************             
 ** PR     Date              Author              Change Description              
 ** --    --------         -------              --------------------------------            
    1     17/04/2025      Ekta Chandegra        Created  


-- exec dbo.CreateSalesOrderQuote @QuoteTypeId=1,@OpenDate='2025-04-23 00:00:00',@ValidForDays=30,
	@QuoteExpireDate='2025-05-23 00:00:00',@CustomerId=44,@CustomerReference=N'',@SalesPersonId=55,
	@CustomerServiceRepId=0,@ProbabilityId=2,@LeadSourceId=6,@EmployeeId=223,@CustomerWarningId=0,
	@Memo=N'',@Notes=N'',@MasterCompanyId=1,@CreatedBy=N'EKTA CHANDEGRA',@StatusId=1,@StatusChangeDate='2025-04-23 16:24:41.990',
	@ManagementStructureId=1,@QtyRequested=0,@QtyToBeQuoted=0,@IsNewVersionCreated=0,@QuoteParentId=0,@TotalFreight=0,@TotalCharges=0,
	@FreightBilingMethodId=0,@ChargesBilingMethodId=0,@FunctionalCurrencyId=1,@ReportCurrencyId=1,@ForeignExchangeRate=1.000000,
	@IsCopySOQData=0,@CopyOldSOQId=0

************************/   
CREATE   PROCEDURE [dbo].[CreateSalesOrderQuote]
	@QuoteTypeId INT,
	@OpenDate DATETIME,
	@ValidForDays INT,
	@QuoteExpireDate DATETIME,
	@CustomerId BIGINT,
	@CustomerReference VARCHAR(100),
	@SalesPersonId BIGINT,
	@CustomerServiceRepId BIGINT,
	@ProbabilityId INT,
	@LeadSourceId INT,
	@EmployeeId BIGINT,
	@CustomerWarningId BIGINT,
	@Memo NVARCHAR(MAX),
	@Notes NVARCHAR(MAX),
	@MasterCompanyId INT,
	@CreatedBy VARCHAR(256),
	@StatusId INT,
	@StatusChangeDate DATETIME,
	@ManagementStructureId BIGINT,
	@QtyRequested INT,
	@QtyToBeQuoted INT,
	@IsNewVersionCreated BIT,
	@QuoteParentId BIGINT,
	@TotalFreight DECIMAL(20,2),
	@TotalCharges DECIMAL(20,2),
	@FreightBilingMethodId INT,
	@ChargesBilingMethodId INT,
	@FunctionalCurrencyId INT,
	@ReportCurrencyId INT,
	@ForeignExchangeRate DECIMAL(18,2),
	@IsCopySOQData BIT,
	@CopyOldSOQId BIGINT
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;
	BEGIN TRY
		BEGIN TRANSACTION
			BEGIN
				DECLARE @SalesOrderQuoteId BIGINT;
				DECLARE @SalesOrderQuotePrefix INT; 
				DECLARE @CurrentNumber BIGINT;
				DECLARE @Vesrion VARCHAR(50);

				SELECT TOP 1 @SalesOrderQuotePrefix = CodeTypeId FROM [dbo].[CodeTypes] WITH(NOLOCK) WHERE [CodeType] = 'Sales Order Quote';
				PRINT @SalesOrderQuotePrefix;

				DECLARE @AccountTypeId INT;
				DECLARE @CustomerContactId BIGINT;
				DECLARE @ContractReference VARCHAR(100);
				DECLARE @CreditLimit DECIMAL(18,2);
				DECLARE @CreditTermId INT;

				DECLARE @RestrictPMA BIT;
				DECLARE @RestrictDER BIT;

				DECLARE @QuoteTypeName VARCHAR(50);
				DECLARE @AccountTypeName VARCHAR(256);
				DECLARE @CustomerName VARCHAR(100);
				DECLARE @SalesPersonName VARCHAR(80);
				DECLARE @CustomerServiceRepName VARCHAR(80);
				DECLARE @ProbabilityName VARCHAR(50);
				DECLARE @LeadSourceName VARCHAR(50);
				DECLARE @EmployeeName VARCHAR(80);
				DECLARE @CustomerWarningName VARCHAR(500);
				DECLARE @ManagementStructureName VARCHAR(286);
				DECLARE @CustomerContactName VARCHAR(200);
				DECLARE @VersionNumber VARCHAR(50);
				DECLARE @CustomerCode VARCHAR(100);
				DECLARE @CustomerContactEmail VARCHAR(200);
				DECLARE @CreditTermName VARCHAR(50);
				DECLARE @StatusName VARCHAR(50);
				DECLARE @IsEnforceApproval BIT;
				DECLARE @EnforceEffectiveDate DATETIME;

				IF @CustomerServiceRepId = 0 
				BEGIN
					SET @CustomerServiceRepId = NULL
				END

				IF @SalesPersonId = 0 
				BEGIN
					SET @SalesPersonId = NULL
				END

				IF @LeadSourceId = 0 
				BEGIN
					SET @LeadSourceId = NULL
				END

				IF @ProbabilityId = 0 
				BEGIN
					SET @ProbabilityId = NULL
				END

				IF @QuoteParentId = 0 
				BEGIN
					SET @QuoteParentId = NULL
				END
					

				-- Fetch soqCodeData
				SELECT TOP 1 * INTO #soqCodeData FROM [dbo].[CodePrefixes] WITH(NOLOCK) WHERE [IsActive] = 1 AND [IsDeleted] = 0 AND [CodeTypeId] = @SalesOrderQuotePrefix AND [MasterCompanyId] = @MasterCompanyId

				-- Determine the current number
				IF EXISTS (SELECT 1 FROM #soqCodeData)
				BEGIN
					IF (SELECT CurrentNummber FROM #soqCodeData) > 0
					BEGIN
						SET @CurrentNumber = (SELECT CurrentNummber FROM #soqCodeData) + 1;
					END
					ELSE
					BEGIN
						SET @CurrentNumber = (SELECT StartsFrom FROM #soqCodeData) + 1;
					END

					-- Update soCodeData with new current number
					UPDATE CodePrefixes
					SET CurrentNummber = @CurrentNumber
					WHERE CodePrefixId = (SELECT CodePrefixId FROM #soqCodeData);

					-- Generate SalesOrderNumber
						DECLARE @SalesOrderNumber NVARCHAR(50);
						SET @SalesOrderNumber = (SELECT * FROM [dbo].[udfGenerateCodeNumberWithOutDash](@CurrentNumber, (SELECT CodePrefix FROM #soqCodeData), (SELECT CodeSufix FROM #soqCodeData)));
				END
				ELSE
				BEGIN
					-- Generate SalesOrderNumber without prefix/suffix
					SET @SalesOrderNumber = (SELECT * FROM [dbo].udfGenerateCodeNumberWithOutDash(0, '', ''));
				END

				-- Generate Version
				SET @Vesrion = 1
				--PRINT @version 

				SET @VersionNumber = [dbo].[GenearteVersionNumber] (@Vesrion)
				PRINT @VersionNumber

				-- Fetch customer details
				SELECT TOP 1
				@AccountTypeId = C.CustomerTypeId,
				@CustomerContactId = CC.CustomerContactId,
				@ContractReference = C.ContractReference,
				@RestrictDER = C.RestrictDER,
				@RestrictPMA = C.RestrictPMA,
				@CreditTermId = CF.CreditTermsId,
				@CreditTermName = CTS.Name,
				@CustomerContactEmail = CO.Email,
				@CustomerCode = C.CustomerCode,
				@CustomerContactName = CO.FirstName +' '+CO.LastName+'-'+CO.WorkPhone,
				@CustomerName = C.Name,
				@AccountTypeName = CT.CustomerTypeName,
				@CreditLimit = CF.CreditLimit
				FROM [dbo].[Customer] C WITH(NOLOCK)
				LEFT JOIN [dbo].[CustomerContact]  CC WITH(NOLOCK)  ON CC.CustomerId = C.CustomerId AND CC.IsDefaultContact = 1
				LEFT JOIN [dbo].[Contact] CO WITH(NOLOCK)  ON CO.ContactId = CC.ContactId
				LEFT JOIN [dbo].[CustomerType] CT WITH(NOLOCK) ON CT.CustomerTypeId = C.CustomerTypeId 
				LEFT JOIN [dbo].[CustomerFinancial]  CF WITH(NOLOCK)  ON CF.CustomerId = C.CustomerId 
				LEFT JOIN [dbo].[CreditTerms] CTS WITH(NOLOCK) ON CTS.CreditTermsId = CF.CreditTermsId
				WHERE C.CustomerId = @CustomerId

				-- Fetch Quote Type Name
				SELECT TOP 1 
				@QuoteTypeName = Name 
				FROM [dbo].[MasterSalesOrderQuoteTypes] WITH(NOLOCK)
				WHERE Id = ISNULL(@QuoteTypeId,0)

				-- Fetch Sales Person Name
				SELECT TOP 1
				@SalesPersonName = FirstName +' '+LastName
				FROM [dbo].[Employee] WITH(NOLOCK)
				WHERE EmployeeId = ISNULL(@SalesPersonId,0)

				-- Fetch Customer Service Rep Name
				SELECT TOP 1
				@CustomerServiceRepName = FirstName +' '+LastName
				FROM [dbo].[Employee] WITH(NOLOCK)
				WHERE EmployeeId = ISNULL(@CustomerServiceRepId,0)

				-- Fetch Proability Name
				SELECT TOP 1
				@ProbabilityName = PercentValue
				FROM [dbo].[Percent] WITH(NOLOCK)
				WHERE PercentId = ISNULL(@ProbabilityId,0)

				-- Fetch Lead Source Name
				SELECT TOP 1
				@LeadSourceName = LeadSources
				FROM [dbo].[LeadSource] WITH(NOLOCK)
				WHERE LeadSourceId = ISNULL(@LeadSourceId,0)

				-- Fetch Employee Name
				SELECT TOP 1
				@EmployeeName = FirstName+' '+LastName
				FROM [dbo].[Employee] WITH(NOLOCK)
				WHERE EmployeeId = ISNULL(@EmployeeId,0)

				-- Fetch Customer Warning Name
				SELECT TOP 1
				@CustomerWarningName = WarningMessage
				FROM [dbo].[CustomerWarning] WITH(NOLOCK)
				WHERE CustomerWarningId = ISNULL(@CustomerWarningId,0)


				-- Fetch Management Structure Name
				SELECT TOP 1
				@ManagementStructureName = Code+'-'+Name
				FROM [dbo].[ManagementStructure] WITH(NOLOCK)
				WHERE ManagementStructureId = ISNULL(@ManagementStructureId,0)

				-- Fetch StatusName 
				SELECT TOP 1 
				@StatusName =  Name
				FROM [dbo].[MasterSalesOrderStatus] WITH(NOLOCK) 
				WHERE Id = ISNULL(@StatusId,0)

				-- Fetch Sales order quote settings details
				SELECT TOP 1
				@IsEnforceApproval = SOQS.IsApprovalRule,
				@EnforceEffectiveDate = SOQS.EffectiveDate
				FROM [dbo].[SalesOrderQuoteSettings] SOQS WITH(NOLOCK)
				WHERE IsActive = 1 AND IsDeleted = 0 AND MasterCompanyId = @MasterCompanyId 

				INSERT INTO [dbo].[SalesOrderQuote]
				(
					 [QuoteTypeId],[OpenDate],[ValidForDays],[QuoteExpireDate],[AccountTypeId],[CustomerId],[CustomerContactId],[CustomerReference] 
					,[ContractReference],[SalesPersonId],[AgentName],[CustomerSeviceRepId],[ProbabilityId],[LeadSourceId],[CreditLimit] 
					,[CreditTermId],[EmployeeId],[RestrictPMA],[RestrictDER],[ApprovedDate],[CurrencyId],[CustomerWarningId],[Memo] 
					,[Notes],[MasterCompanyId],[CreatedBy],[CreatedDate],[UpdatedBy],[UpdatedDate],[IsDeleted],[StatusId],[StatusChangeDate] 
					,[ManagementStructureId],[Version],[AgentId],[QtyRequested],[QtyToBeQuoted],[SalesOrderQuoteNumber],[QuoteSentDate] 
					,[IsNewVersionCreated],[IsActive],[QuoteParentId],[QuoteTypeName],[AccountTypeName],[CustomerName],[SalesPersonName] 
					,[CustomerServiceRepName],[ProbabilityName],[LeadSourceName],[CreditTermName],[EmployeeName],[CurrencyName] 
					,[CustomerWarningName],[ManagementStructureName],[CustomerContactName],[VersionNumber],[CustomerCode]
					,[CustomerContactEmail],[CreditLimitName],[StatusName],[ManagementStructureName1],[ManagementStructureName2] 
					,[ManagementStructureName3],[ManagementStructureName4],[EnforceEffectiveDate],[IsEnforceApproval],[TotalFreight]
					,[TotalCharges],[FreightBilingMethodId],[ChargesBilingMethodId],[FunctionalCurrencyId],[ReportCurrencyId],[ForeignExchangeRate] 
				)
				SELECT
					@QuoteTypeId,@OpenDate,@ValidForDays,@QuoteExpireDate,@AccountTypeId,@CustomerId,@CustomerContactId,@CustomerReference,
					@ContractReference,@SalesPersonId,NULL,@CustomerServiceRepId,@ProbabilityId,@LeadSourceId,@CreditLimit,
					@CreditTermId,@EmployeeId,@RestrictPMA,@RestrictDER,NULL,NULL,@CustomerWarningId,@Memo,
					@Notes,@MasterCompanyId,@CreatedBy,GETUTCDATE(),@CreatedBy,GETUTCDATE(),0,@StatusId,@StatusChangeDate,
					@ManagementStructureId,@Vesrion,NULL,@QtyRequested,@QtyToBeQuoted,@SalesOrderNumber,NULL,
					@IsNewVersionCreated,1,@QuoteParentId,@QuoteTypeName,@AccountTypeName,@CustomerName,@SalesPersonName,
					@CustomerServiceRepName,@ProbabilityName,@LeadSourceName,@CreditTermName,@EmployeeName,NULL,
					@CustomerWarningName,@ManagementStructureName,@CustomerContactName,@VersionNumber,@CustomerCode,
					@CustomerContactEmail,NULL,@StatusName,NULL,NULL,
					NULL,NULL,@EnforceEffectiveDate,@IsEnforceApproval,@TotalFreight,
					@TotalCharges,@FreightBilingMethodId,@ChargesBilingMethodId,@FunctionalCurrencyId,@ReportCurrencyId,@ForeignExchangeRate;

				SELECT @SalesOrderQuoteId = SCOPE_IDENTITY();

				DECLARE @ModuleID INT;
				DECLARE @ReferenceID BIGINT;
				DECLARE @MSDetailsId BIGINT;

				-- Fetch Sales Order Quote ManagementStructureModule Id
				SELECT @ModuleID = ManagementStructureModuleId FROM [dbo].[ManagementStructureModule] WITH(NOLOCK) WHERE ModuleName = 'SalesOrderQuote'

				SET @ReferenceID = @SalesOrderQuoteId
		
				-- Save SO record in SalesOrderManagementStructureDetails table
				EXEC [dbo].[USP_SaveSOMSDetails] @ModuleID, @ReferenceID, @ManagementStructureId, @MasterCompanyId, @CreatedBy, @MSDetailsId OUTPUT;

				IF @SalesOrderQuoteId IS NOT NULL
				BEGIN
					EXEC [dbo].[UpdateSOQNameColumnsWithId] @SalesOrderQuoteId

					IF (@IsCopySOQData = 1 AND @CopyOldSOQId > 0)
					BEGIN
						IF NOT EXISTS (SELECT 1 FROM [dbo].[SOQuoteMarginSummary] WITH(NOLOCK) WHERE SalesOrderQuoteId = @SalesOrderQuoteId)
						BEGIN
							DECLARE 
								@Sales DECIMAL(18,2),
								@Misc DECIMAL(18,2),
								@NetSales DECIMAL(18,2),
								@ProductCost DECIMAL(18,2),
								@MarginAmount DECIMAL(18,2),
								@MarginPercentage DECIMAL(18,2),
								@FreightAmount DECIMAL(18,2);

							SELECT 
								@Sales = Sales,
								@Misc = Misc,
								@NetSales = NetSales,
								@ProductCost = ProductCost,
								@MarginAmount = MarginAmount,
								@MarginPercentage = MarginPercentage,
								@FreightAmount = FreightAmount
							FROM [dbo].[SOQuoteMarginSummary] WITH(NOLOCK)
							WHERE SalesOrderQuoteId = @CopyOldSOQId;

							IF @Sales IS NOT NULL
							BEGIN
								INSERT INTO [dbo].[SOQuoteMarginSummary] (
									SalesOrderQuoteId, Sales, Misc, NetSales,
									ProductCost, MarginAmount, MarginPercentage, FreightAmount
								)
								VALUES (
									@SalesOrderQuoteId, @Sales, @Misc, @NetSales,
									@ProductCost, @MarginAmount, @MarginPercentage, @FreightAmount
								);
							END
						END
					END
				END
			END

			SELECT @SalesOrderQuoteId AS SalesOrderQuoteId
			COMMIT TRANSACTION
	END TRY
	BEGIN CATCH
	DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------    
            , @AdhocComments     VARCHAR(150)    = 'CreateSalesOrderQuote'     
            , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ CAST(ISNULL(@QuoteTypeId, '') AS varchar(100) ) + ''',
													@Parameter2 = '''+ CAST(ISNULL(@OpenDate, '') AS varchar(100) ) + ''',
													@Parameter3 = '''+ CAST(ISNULL(@ValidForDays, '') AS varchar(100) ) + ''',
													@Parameter4 = '''+ CAST(ISNULL(@QuoteExpireDate, '') AS varchar(100) ) + ''',
													@Parameter5 = '''+ CAST(ISNULL(@CustomerId , '') AS varchar(100) ) + ''',
													@Parameter6 = '''+ CAST(ISNULL(@CustomerReference , '') AS varchar(100) ) + ''',
													@Parameter7 = '''+ CAST(ISNULL(@SalesPersonId, '') AS varchar(100) ) + ''',
													@Parameter8 = '''+ CAST(ISNULL(@CustomerServiceRepId, '') AS varchar(100) ) + ''',
													@Parameter9 = '''+ CAST(ISNULL(@ProbabilityId, '') AS varchar(100) ) + ''',
													@Parameter10 = '''+ CAST(ISNULL(@LeadSourceId, '') AS varchar(100) ) + ''',
													@Parameter11 = '''+ CAST(ISNULL(@EmployeeId, '') AS varchar(100) ) + ''',
													@Parameter12 = '''+ CAST(ISNULL(@CustomerWarningId, '') AS varchar(100) ) + ''',
													@Parameter13 = '''+ CAST(ISNULL(@Memo, '') AS varchar(100) ) + ''',
													@Parameter14 = '''+ CAST(ISNULL(@Notes, '') AS varchar(100) ) + ''',
													@Parameter15 = '''+ CAST(ISNULL(@MasterCompanyId , '') AS varchar(100) ) + ''',
													@Parameter16 = '''+ CAST(ISNULL(@CreatedBy, '') AS varchar(100) ) + ''',
													@Parameter17 = '''+ CAST(ISNULL(@StatusId, '') AS varchar(100) ) + ''',
													@Parameter18 = '''+ CAST(ISNULL(@StatusChangeDate, '') AS varchar(100) ) + ''',
													@Parameter19 = '''+ CAST(ISNULL(@ManagementStructureId, '') AS varchar(100) ) + ''',
													@Parameter20 = '''+ CAST(ISNULL(@QtyRequested , '') AS varchar(100) ) + ''',
													@Parameter21 = '''+ CAST(ISNULL(@QtyToBeQuoted , '') AS varchar(100) ) + ''',
													@Parameter22 = '''+ CAST(ISNULL(@IsNewVersionCreated, '') AS varchar(100) ) + ''',
													@Parameter23 = '''+ CAST(ISNULL(@QuoteParentId, '') AS varchar(100) ) + ''',
													@Parameter24 = '''+ CAST(ISNULL(@TotalFreight , '') AS varchar(100) ) + ''',
													@Parameter25 = '''+ CAST(ISNULL(@TotalCharges , '') AS varchar(100) ) + ''',
													@Parameter26 = '''+ CAST(ISNULL(@FreightBilingMethodId, '') AS varchar(100) ) + ''',
													@Parameter27 = '''+ CAST(ISNULL(@ChargesBilingMethodId , '') AS varchar(100) ) + ''',
													@Parameter28 = '''+ CAST(ISNULL(@FunctionalCurrencyId , '') AS varchar(100) ) + ''',
													@Parameter29 = '''+ CAST(ISNULL(@ReportCurrencyId , '') AS varchar(100) ) + ''',
													@Parameter31 = '''+ CAST(ISNULL(@ForeignExchangeRate, '') AS varchar(100) ) + ''',
													@Parameter32 = '''+ CAST(ISNULL(@IsCopySOQData, '') AS varchar(100) ) + ''',
													@Parameter33 = '''+ CAST(ISNULL(@CopyOldSOQId, '') AS varchar(100) ) + '' 

			,@ApplicationName VARCHAR(100) = 'PAS'    
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