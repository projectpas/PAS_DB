/*****************************************************************************************             
 ** File:   [USP_CreateSalesOrderQuoteFromAI]             
 ** Author:  Amit Ghediya 
 ** Description: This stored procedure is used to create SO quote automatically from AI
 ** Purpose:           
 ** Date:  17/04/2025       
            
 ** RETURN VALUE:             
 **********************             
 ** Change History             
 **********************             
 ** PR     Date              Author              Change Description              
 ** --    --------         -------              --------------------------------            
	1     05/08/2025      Amit Ghediya			Created
	2     13/08/2025      Rajesh Gami			Implemented SourceBy And MarketPlaceRef
	3     14/08/2025      Devendra Shekh		Added New Param @QuoteSendReviewId, Handled Multiple Part 
	4     15/08/2025      Moin Bloch            Added @SoqId OUTPUT Param
	5     18/08/2025      Moin Bloch            Added @LeadSourceId For SOQ
	6     28/08/2025      Devendra Shekh		removed Text (Created From AI)
	7     09/06/2026      Amit Ghediya			Get latest from mgn stc table [PN-16491]
*********************************************************************************************/   
CREATE   PROCEDURE [dbo].[USP_CreateSalesOrderQuoteFromAI]
	@tbl_IlsRfqQuoteDetailsType IlsRfqQuoteDetailsType READONLY,
	@CustomerId BIGINT,
	@MasterCompanyId INT,
	@CreatedBy VARCHAR(256),
	@EmployeeId BIGINT = 2,
	@CustomerRfqId BIGINT,
	@ItemMasterId BIGINT, --For part data,
	@UnitSalesPriceTotal DECIMAL(18,2),
	@SourceBy VARCHAR(30) = NULL,
	@MarketplaceRef VARCHAR(50) = NULL,
	@QuoteSendReviewId INT = NULL,
	@SoqId BIGINT = 0 OUTPUT
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
				DECLARE @SOQModuleId INT = 0;
				DECLARE @VersionNumber VARCHAR(50);
				DECLARE @AccountTypeId INT;
				DECLARE @CustomerContactId BIGINT;
				DECLARE @ContractReference VARCHAR(100);
				DECLARE @CreditLimit DECIMAL(18,2);
				DECLARE @CreditTermId INT;
				DECLARE @RestrictPMA BIT;
				DECLARE @RestrictDER BIT;
				DECLARE @CustomerCode VARCHAR(100);
				DECLARE @CustomerContactEmail VARCHAR(200);
				DECLARE @CreditTermName VARCHAR(50);
				DECLARE @CustomerName VARCHAR(100);
				DECLARE @CustomerContactName VARCHAR(200);
				DECLARE @AccountTypeName VARCHAR(256);
				DECLARE @QuoteTypeName VARCHAR(50);
				DECLARE @SalesPersonId BIGINT = NULL;
				DECLARE @SalesPersonName VARCHAR(80);
				DECLARE @CustomerServiceRepId BIGINT = NULL;
				DECLARE @CustomerServiceRepName VARCHAR(80);
				DECLARE @ProbabilityName VARCHAR(50);
				DECLARE @LeadSourceName VARCHAR(50);
				DECLARE @EmployeeName VARCHAR(80);
				DECLARE @CustomerWarningName VARCHAR(500);
				DECLARE @ManagementStructureName VARCHAR(286);
				DECLARE @StatusName VARCHAR(50);
				DECLARE @IsEnforceApproval BIT;
				DECLARE @EnforceEffectiveDate DATETIME;
				DECLARE @ProbabilityId BIGINT = NULL;
				DECLARE @LeadSourceId BIGINT = NULL;
				DECLARE @CustomerWarningId BIGINT = 0;
				DECLARE @QuoteTypeId BIGINT = 0;
				DECLARE @ValidForDays INT;
				DECLARE @PriorityId BIGINT;
				DECLARE @OpenDate DATETIME;
				DECLARE @QuoteExpireDate DATETIME;
				DECLARE @CurrencyId INT = 0;
				DECLARE @ForeignExchangeRate DECIMAL(18,2) = 1;
				DECLARE @ManagementStructureId BIGINT = 1;
				DECLARE @Type VARCHAR(50)=NULL

				SET @OpenDate = (SELECT CAST(GETUTCDATE() AS DATE));
				SET @QuoteExpireDate = (SELECT CAST(DATEADD(DAY, 30, GETUTCDATE()) AS DATE));
				SELECT @CurrencyId = [CurrencyId] FROM Currency WHERE Code = 'USD' AND MasterCompanyId = @MasterCompanyId;

				SELECT TOP 1 @SalesOrderQuotePrefix = CodeTypeId FROM [dbo].[CodeTypes] WITH(NOLOCK) WHERE [CodeType] = 'Sales Order Quote';
				
				--Get Module for Update in CustomerRFQ table.
				SELECT @SOQModuleId  = [ModuleId] FROM [DBO].[Module] WITH(NOLOCK) WHERE [ModuleName] = 'SalesQuote';

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
				@QuoteTypeName = [Name] ,@QuoteTypeId = [Id]
				FROM [dbo].[MasterSalesOrderQuoteTypes] WITH(NOLOCK)
				WHERE [Name] = 'Parts Sales';

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
				WHERE CustomerWarningId = ISNULL(@CustomerWarningId,0);				

				-- Fetch Management Structure Name
				SELECT TOP 1 @ManagementStructureId = [EntityStructureId] FROM [dbo].[EntityStructureSetup] WITH(NOLOCK) WHERE MasterCompanyId = @MasterCompanyId;

				SELECT TOP 1
				@ManagementStructureName = Code+'-'+Name
				FROM [dbo].[ManagementStructure] WITH(NOLOCK)
				WHERE ManagementStructureId = ISNULL(@ManagementStructureId,0);

				
				

				DECLARE @StatusId BIGINT;
				select @StatusId = Id from MasterSalesOrderStatus where Name = 'Open';

				-- Fetch StatusName 
				SELECT TOP 1 
				@StatusName =  Name
				FROM [dbo].[MasterSalesOrderStatus] WITH(NOLOCK) 
				WHERE Id = ISNULL(@StatusId,0)

				-- Fetch Sales order quote settings details
				SELECT TOP 1
				@IsEnforceApproval = SOQS.IsApprovalRule,
				@EnforceEffectiveDate = SOQS.EffectiveDate,
				@ValidForDays = ISNULL(SOQS.ValidDays,0),
				@PriorityId = DefaultPriorityId
				FROM [dbo].[SalesOrderQuoteSettings] SOQS WITH(NOLOCK)
				WHERE IsActive = 1 AND IsDeleted = 0 AND MasterCompanyId = @MasterCompanyId 
							   

				IF(ISNULL(@CustomerRfqId,0) > 0)
				BEGIN
					SELECT @Type = [Type] FROM [dbo].[CustomerRfq] WITH(NOLOCK) WHERE [CustomerRfqId] = @CustomerRfqId

					IF @Type IS NOT NULL 
					BEGIN
						SELECT @LeadSourceId = [LeadSourceId] FROM [dbo].[LeadSource] WITH(NOLOCK) WHERE [LeadSources] = @Type AND [MasterCompanyId] = @MasterCompanyId						
					END
				END

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
					,[TotalCharges],[FreightBilingMethodId],[ChargesBilingMethodId],[FunctionalCurrencyId],[ReportCurrencyId],[ForeignExchangeRate],SourceBy,MarketplaceRef 
				)
				SELECT
					@QuoteTypeId,@OpenDate,@ValidForDays,@QuoteExpireDate,@AccountTypeId,@CustomerId,@CustomerContactId,NULL,
					@ContractReference,@SalesPersonId,NULL,@CustomerServiceRepId,@ProbabilityId,@LeadSourceId,@CreditLimit,
					@CreditTermId,@EmployeeId,@RestrictPMA,@RestrictDER,NULL,NULL,@CustomerWarningId,NULL,
					'',@MasterCompanyId,@CreatedBy,GETUTCDATE(),@CreatedBy,GETUTCDATE(),0,@StatusId,GETUTCDATE(),
					@ManagementStructureId,@Vesrion,NULL,0,0,@SalesOrderNumber,NULL,
					0,1,NULL,@QuoteTypeName,@AccountTypeName,@CustomerName,@SalesPersonName,
					@CustomerServiceRepName,@ProbabilityName,@LeadSourceName,@CreditTermName,@EmployeeName,NULL,
					@CustomerWarningName,@ManagementStructureName,@CustomerContactName,@VersionNumber,@CustomerCode,
					@CustomerContactEmail,NULL,@StatusName,NULL,NULL,
					NULL,NULL,@EnforceEffectiveDate,@IsEnforceApproval,0,
					0,0,0,@CurrencyId,@CurrencyId,@ForeignExchangeRate,@SourceBy, @MarketplaceRef;

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

					--IF (@IsCopySOQData = 1 AND @CopyOldSOQId > 0)
					--BEGIN
					--	IF NOT EXISTS (SELECT 1 FROM [dbo].[SOQuoteMarginSummary] WITH(NOLOCK) WHERE SalesOrderQuoteId = @SalesOrderQuoteId)
					--	BEGIN
					--		DECLARE 
					--			@Sales DECIMAL(18,2),
					--			@Misc DECIMAL(18,2),
					--			@NetSales DECIMAL(18,2),
					--			@ProductCost DECIMAL(18,2),
					--			@MarginAmount DECIMAL(18,2),
					--			@MarginPercentage DECIMAL(18,2),
					--			@FreightAmount DECIMAL(18,2);

					--		SELECT 
					--			@Sales = Sales,
					--			@Misc = Misc,
					--			@NetSales = NetSales,
					--			@ProductCost = ProductCost,
					--			@MarginAmount = MarginAmount,
					--			@MarginPercentage = MarginPercentage,
					--			@FreightAmount = FreightAmount
					--		FROM [dbo].[SOQuoteMarginSummary] WITH(NOLOCK)
					--		WHERE SalesOrderQuoteId = @CopyOldSOQId;

					--		IF @Sales IS NOT NULL
					--		BEGIN
					--			INSERT INTO [dbo].[SOQuoteMarginSummary] (
					--				SalesOrderQuoteId, Sales, Misc, NetSales,
					--				ProductCost, MarginAmount, MarginPercentage, FreightAmount
					--			)
					--			VALUES (
					--				@SalesOrderQuoteId, @Sales, @Misc, @NetSales,
					--				@ProductCost, @MarginAmount, @MarginPercentage, @FreightAmount
					--			);
					--		END
					--	END
					--END

					-- Update CustomerRfq for create SOQ from Received RFQ 
					IF(ISNULL(@CustomerRfqId,0) > 0)
					BEGIN
						 EXEC [dbo].[UpdateCustomerRfqQuoteReferenceId] @CustomerRfqId,@SalesOrderQuoteId,@SOQModuleId
					END

					---------------------------Start Part Add----------------------------------------
					DECLARE @ConditionId BIGINT,							
							@SOQPartLoopID AS INT,
							@MinsoqId AS INT,
							@RfqQuoteLoopID AS INT,
							@MinRFQId AS INT,
							@ILSQty INT,
							@RFQItemMasterId BIGINT,
							@NetSaleAmount DECIMAL(18,2) = 500;--Curruntly fix amount
					
						--Read all part which from RFQ
						IF OBJECT_ID(N'tempdb..#RfqQuoteDetail') IS NOT NULL
						BEGIN
							DROP TABLE #RfqQuoteDetail
						END

						CREATE TABLE #RfqQuoteDetail
						(
							ID bigint NOT NULL IDENTITY,
							[CustomerRfqQuoteDetailsId] [bigint] NULL,
							[CustomerRfqQuoteId] [bigint] NULL,
							[IlsQty] [int] NULL,
							[IlsTraceability] [varchar](50) NULL,
							[IlsUom] [varchar](50) NULL,
							[IlsPrice] [decimal](10, 2) NULL,
							[IlsPriceType] [varchar](50) NULL,
							[IlsTagDate] [datetime2](7) NULL,
							[IlsLeadTime] [varchar](50) NULL,
							[IlsMinQty] [int] NULL,
							[IlsComment] [varchar](max) NULL,
							[IlsCondition] [varchar](50) NULL,
							[ConditionId] [bigint] NULL,
							[ItemMasterId] [bigint] NULL
						)

						INSERT  INTO #RfqQuoteDetail([CustomerRfqQuoteDetailsId],[CustomerRfqQuoteId],[IlsQty],[IlsTraceability],[IlsUom],
														[IlsPrice],[IlsPriceType],[IlsTagDate],[IlsLeadTime],[IlsMinQty],
														[IlsComment],[IlsCondition],[ConditionId],[ItemMasterId])
												SELECT [CustomerRfqQuoteDetailsId],[CustomerRfqQuoteId],[IlsQty],[IlsTraceability],[IlsUom],
														[IlsPrice],[IlsPriceType],[IlsTagDate],[IlsLeadTime],[IlsMinQty],
														[IlsComment],[IlsCondition],[ConditionId],[ItemMasterId]
												FROM @tbl_IlsRfqQuoteDetailsType;
					--Create for SO Part
					IF OBJECT_ID(N'tempdb..#SOQPartDetails') IS NOT NULL
					BEGIN
						DROP TABLE #SOQPartDetails
					END

					CREATE TABLE #SOQPartDetails
					(
						ID bigint NOT NULL IDENTITY,
						SalesOrderQuotePartId bigint,
						SalesOrderQuoteId bigint,
						ItemMasterId bigint,
						ConditionId bigint,
						PriorityId bigint,
						StocklineId bigint,
						QuantityQuote int,
						SalesOrderQuoteStocklineId bigint,
						StatusId int,
						QtyRequested int,
						QtyQuoted int,
						QtyAvailable int,
						QtyOH int,
						CurrencyId int,
						FxRate decimal(18,4),
						GrossSaleAmount decimal(18,4),
						DiscountAmount decimal(18,4),
						NetSaleAmount decimal(18,4),
						TaxAmount decimal(18,4),
						UnitCostExtended decimal(18,4),
						MarginAmount decimal(18,4),
						CustomerRequestDate datetime2(7),
						PromisedDate datetime2(7),
						EstimatedShipDate datetime2(7),
						UnitSalesPrice decimal(18,4),
						MarkUpPercentage decimal(18,4),
						DiscountPercentage decimal(18,4),
						MarkUpAmount decimal(18,4),
						SalesPriceExtended decimal(18,4),
						UnitCost decimal(18,4),
						MarginPercentage decimal(18,4),
						TaxPercentage decimal(18,4),
						StatusName varchar(100),
						AltOrEqType varchar(25),
						Notes nvarchar(max),
						MasterCompanyId int,
						CreatedBy varchar(100),
						IsNoQuote BIT NULL,
						IsLotAssigned BIT NULL,
						LotId BIGINT NULL
					)

					SELECT @RfqQuoteLoopID = MAX(ID) FROM #RfqQuoteDetail;
					SELECT @MinRFQId = MIN(ID) FROM #RfqQuoteDetail;

					WHILE (@MinRFQId <= @RfqQuoteLoopID)
					BEGIN
						SELECT @UnitSalesPriceTotal = [IlsPrice],
							   @ConditionId = [ConditionId],
							   @ILSQty = IlsQty,
							   @RFQItemMasterId = CASE WHEN ISNULL(ItemMasterId, 0) > 0 THEN ItemMasterId ELSE @ItemMasterId END
						FROM #RfqQuoteDetail WHERE ID = @MinRFQId;

						--Set AI based Price
						SET @NetSaleAmount = ISNULL(@UnitSalesPriceTotal,0);

						INSERT INTO #SOQPartDetails (SalesOrderQuotePartId,SalesOrderQuoteId,ItemMasterId,ConditionId,PriorityId,StocklineId,QuantityQuote,SalesOrderQuoteStocklineId,StatusId,
						QtyRequested,QtyQuoted,QtyAvailable,QtyOH,CurrencyId,FxRate,GrossSaleAmount,DiscountAmount,NetSaleAmount,TaxAmount,UnitCostExtended,MarginAmount,
						CustomerRequestDate,PromisedDate,EstimatedShipDate,UnitSalesPrice,MarkUpPercentage,DiscountPercentage,MarkUpAmount,SalesPriceExtended,UnitCost,
						MarginPercentage,TaxPercentage,StatusName,AltOrEqType,Notes,MasterCompanyId,CreatedBy,IsNoQuote,IsLotAssigned,LotId)
						SELECT 0,@SalesOrderQuoteId,@RFQItemMasterId,@ConditionId,@PriorityId,NULL,@ILSQty,@ILSQty,NULL,
						@ILSQty,@ILSQty,0,0,@CurrencyId,1,0,0,@NetSaleAmount,0,0,@NetSaleAmount,
						NULL,NULL,NULL,@NetSaleAmount,0,0,0,0,0,
						0,0,NULL,NULL,'',@MasterCompanyId,@CreatedBy,NULL,0,NULL;

						SET @MinRFQId = @MinRFQId + 1;
					END

					SELECT @SOQPartLoopID = MAX(ID) FROM #SOQPartDetails;
					select @MinsoqId = MIN(ID) FROM #SOQPartDetails;

					WHILE (@MinsoqId <= @SOQPartLoopID)
					BEGIN
						DECLARE @SalesOrderQuotePartId BIGINT = 0;
						DECLARE @SalesOrderQuoteStocklineId BIGINT = 0;
						DECLARE @StocklineId BIGINT = 0;
						DECLARE @UnitSalesPrice AS decimal(18,4);
						DECLARE @MarkUpAmount AS decimal(18,4);
						DECLARE @MarkUpPercentage AS decimal(18,4);
						DECLARE @DiscountAmount AS decimal(18,4);
						DECLARE @MarginAmount AS decimal(18,4);
						DECLARE @UnitCost AS decimal(18,4);
						DECLARE @MarginPercentage AS decimal(18,4);
						DECLARE @DiscountPercentage AS decimal(18,4);
						DECLARE @QtyQuoted AS INT;
						DECLARE @QtyRequested AS INT;
						DECLARE @QuantityToQuote AS INT;
						DECLARE @Notes AS VARCHAR(MAX);
						DECLARE @CustomerRequestDate AS Datetime2(7);
						DECLARE @PromisedDate AS Datetime2(7);
						DECLARE @EstimatedShipDate AS Datetime2(7);
						DECLARE @IsNoQuote AS BIT = NULL;
						DECLARE @IsLotAssigned AS BIT = NULL;
						DECLARE @LotId AS BIGINT = 0;

						SELECT @SalesOrderQuotePartId = SalesOrderQuotePartId, @SalesOrderQuoteId = SalesOrderQuoteId, @ItemMasterId = ItemMasterId, @ConditionId = ConditionId, @StocklineId = StocklineId,
						@SalesOrderQuoteStocklineId = SalesOrderQuoteStocklineId, @MasterCompanyId = MasterCompanyId, @UnitSalesPrice = UnitSalesPrice, @MarkUpAmount = MarkUpAmount, @DiscountAmount = DiscountAmount, @QtyQuoted = QtyQuoted,
						@CreatedBy = CreatedBy, @MarkUpPercentage = MarkUpPercentage, @UnitCost = UnitCost, @MarginAmount = MarginAmount, @MarginPercentage = MarginPercentage,
						@DiscountPercentage = DiscountPercentage, @QtyRequested = QtyRequested, @QuantityToQuote = QuantityQuote, @Notes = Notes, 
						@CustomerRequestDate = CustomerRequestDate, @PromisedDate = PromisedDate, @EstimatedShipDate = EstimatedShipDate,@IsNoQuote = IsNoQuote,
						@IsLotAssigned = IsLotAssigned,@LotId = LotId
						FROM #SOQPartDetails WHERE ID = @MinsoqId;	
						

						IF (ISNULL(@SalesOrderQuotePartId, 0) = 0) -- Add New Part
						BEGIN
							DECLARE @SOQPartStatus BIGINT;
							SELECT @SOQPartStatus = SOPartStatusId FROM [DBO].[SOPartStatus] WITH (NOLOCK) WHERE [PartStatus] = 'Open';
							
							IF NOT EXISTS (SELECT * FROM [dbo].[SalesOrderQuotePartV1] WITH (NOLOCK) WHERE SalesOrderQuoteId = @SalesOrderQuoteId AND ItemMasterId = @ItemMasterId AND ConditionId = @ConditionId)
							BEGIN
								DECLARE @CurrencyCode VARCHAR(10) = '';
								--DECLARE @CurrencyId BIGINT = 0;
			
								SELECT @CurrencyId = Curr.CurrencyId, @CurrencyCode = Curr.Code FROM [DBO].[CustomerFinancial] CF WITH (NOLOCK) 
								LEFT JOIN [DBO].[Currency] Curr WITH (NOLOCK) ON CF.CurrencyId = Curr.CurrencyId 
								LEFT JOIN [DBO].[SalesOrderQuote] SOQ WITH (NOLOCK) ON SOQ.CustomerId = CF.CustomerId
								WHERE SOQ.SalesOrderQuoteId = @SalesOrderQuoteId;

								INSERT INTO [dbo].[SalesOrderQuotePartV1] ([SalesOrderQuoteId],[ItemMasterId],[ConditionId],[QtyRequested],[QtyQuoted],[CurrencyId],[FxRate],[PriorityId],[StatusId],[CustomerRequestDate],[PromisedDate],[EstimatedShipDate],[Notes],[MasterCompanyId],[CreatedBy],[CreatedDate],[UpdatedBy],[UpdatedDate],[IsActive],[IsDeleted],[IsLotAssigned],[LotId])
								SELECT SalesOrderQuoteId, ItemMasterId, ConditionId, QtyRequested, QtyQuoted, CurrencyId, FxRate, PriorityId, @SOQPartStatus, CustomerRequestDate, PromisedDate, EstimatedShipDate, Notes, MasterCompanyId, CreatedBy, GETUTCDATE(), CreatedBy, GETUTCDATE(), 1, 0,IsLotAssigned,LotId
								FROM #SOQPartDetails WHERE ID = @MinsoqId;
								
								SET @SalesOrderQuotePartId = SCOPE_IDENTITY();

								DECLARE @SalesPrice AS decimal(18,4);
								DECLARE @MarkUpAmt AS decimal(18,4);
								DECLARE @DiscAmt AS decimal(18,4);
								DECLARE @GrossAmt AS decimal(18,4);
								DECLARE @NetSalesAmt AS decimal(18,4);
								DECLARE @NetSalesPerUnitAmt AS decimal(18,4);

								SET @SalesPrice = ISNULL(@UnitSalesPrice, 0);
								SET @MarkUpAmt = ISNULL(@MarkUpAmount, 0);
								SET @DiscAmt = ISNULL(@DiscountAmount, 0);
								SET @GrossAmt = (@SalesPrice + @MarkUpAmt) * @QtyQuoted;
								SET @NetSalesAmt = @GrossAmt - (@DiscAmt * @QtyQuoted);
								SET @NetSalesPerUnitAmt = (@SalesPrice + @MarkUpAmt) - @DiscAmt;

								INSERT INTO [dbo].[SalesOrderQuotePartCost] ([SalesOrderQuoteId], [SalesOrderQuotePartId], [UnitSalesPrice], [UnitSalesPriceExtended], [MarkUpPercentage], [MarkUpAmount], [DiscountPercentage], [DiscountAmount],
								[GrossSaleAmount], [NetSaleAmount], [MiscCharges], [Freight], [TaxAmount], [TaxPercentage], [UnitCost], [UnitCostExtended], [MarginAmount], [MarginPercentage], [TotalRevenue], 
								[MasterCompanyId], [CreatedBy], [CreatedDate], [UpdatedBy], [UpdatedDate], [IsActive], [IsDeleted], [NetSaleAmountPerUnit])
								SELECT SalesOrderQuoteId, @SalesOrderQuotePartId, UnitSalesPrice, ISNULL((UnitSalesPrice * QtyQuoted), 0), MarkUpPercentage, ISNULL((MarkUpAmount * QtyQuoted), 0), DiscountPercentage, ISNULL((DiscountAmount * QtyQuoted), 0),
								ISNULL(@GrossAmt, 0), @NetSalesAmt, NULL, NULL, TaxAmount, TaxPercentage, UnitCost, ISNULL((UnitCost * QtyQuoted), 0), MarginAmount, MarginPercentage, 0,
								MasterCompanyId, CreatedBy, GETUTCDATE(), CreatedBy, GETUTCDATE(), 1, 0, @NetSalesPerUnitAmt
								FROM #SOQPartDetails WHERE ID = @MinsoqId;
							END
							ELSE
							BEGIN
								SELECT @SalesOrderQuotePartId = SalesOrderQuotePartId FROM [dbo].[SalesOrderQuotePartV1] WITH (NOLOCK) WHERE ItemMasterId = @ItemMasterId AND ConditionId = @ConditionId AND SalesOrderQuoteId = @SalesOrderQuoteId;
							END

							IF (@StockLineId IS NOT NULL AND @StockLineId > 0) -- Added at Stockline Level
							BEGIN
								DECLARE @InsertedSalesOrderQuoteStocklineId BIGINT;
								INSERT INTO [dbo].[SalesOrderQuoteStocklineV1] ([SalesOrderQuotePartId], [StockLineId], [ConditionId], [QtyQuoted], [QtyAvailable], [QtyOH], [CustomerRequestDate], [PromisedDate], [EstimatedShipDate], [StatusId], [MasterCompanyId], [CreatedBy], [CreatedDate], [UpdatedBy], [UpdatedDate], [IsActive], [IsDeleted], [Notes])
								SELECT @SalesOrderQuotePartId, STK.StockLineId, @ConditionId, @QuantityToQuote, STK.QuantityAvailable, STK.QuantityOnHand, @CustomerRequestDate, @PromisedDate, @EstimatedShipDate, @SOQPartStatus, @MasterCompanyId, @CreatedBy, GETUTCDATE(), @CreatedBy, GETUTCDATE(), 1, 0, @Notes
								FROM DBO.Stockline STK WHERE STK.StockLineId = @StockLineId;

								SET @InsertedSalesOrderQuoteStocklineId = SCOPE_IDENTITY();

								SET @SalesPrice = ISNULL(@UnitSalesPrice, 0);
								SET @MarkUpAmt = ISNULL(@MarkUpAmount, 0);
								SET @DiscAmt = ISNULL(@DiscountAmount, 0);
								SET @GrossAmt = (@SalesPrice + @MarkUpAmt) * @QtyQuoted;
								SET @NetSalesAmt = @GrossAmt - (@DiscAmt * @QtyQuoted);
								SET @NetSalesPerUnitAmt = (@SalesPrice + @MarkUpAmt) - @DiscAmt;

								INSERT INTO [dbo].[SalesOrderQuoteStockLineCost] ([SalesOrderQuoteId], [SalesOrderQuotePartId], [SalesOrderQuoteStocklineId], [UnitSalesPrice], [UnitSalesPriceExtended], [MarkUpPercentage], [MarkUpAmount], [NetSaleAmount],
								[UnitCost], [UnitCostExtended], [MarginAmount], [MarginPercentage], [DiscountPercentage], [DiscountAmount],
								[MasterCompanyId], [CreatedBy], [CreatedDate], [UpdatedBy], [UpdatedDate], [IsActive], [IsDeleted], [NetSaleAmountPerUnit])
				
								SELECT @SalesOrderQuoteId, @SalesOrderQuotePartId, @InsertedSalesOrderQuoteStocklineId, @UnitSalesPrice, ISNULL((@UnitSalesPrice * @QuantityToQuote), 0), @MarkUpPercentage, ISNULL((@MarkUpAmount * @QtyQuoted), 0), @NetSalesAmt,
								@UnitCost, ISNULL((@UnitCost * @QuantityToQuote), 0), @MarginAmount, @MarginPercentage, @DiscountPercentage, ISNULL((@DiscountAmount * @QtyQuoted), 0), 
								@MasterCompanyId, @CreatedBy, GETUTCDATE(), @CreatedBy, GETUTCDATE(), 1, 0, @NetSalesPerUnitAmt
								FROM [DBO].[StockLine] Stkl
								WHERE Stkl.StockLineId = @StockLineId;
							END
						END
						ELSE
						BEGIN
							DECLARE @IsQtyRequestedModified BIT;
							DECLARE @ExistingQtyReq INT;

							SELECT @ExistingQtyReq = SOP.QtyRequested FROM [DBO].[SalesOrderQuotePartV1] SOP WITH (NOLOCK) WHERE SOP.SalesOrderQuotePartId = @SalesOrderQuotePartId;

							SET @IsQtyRequestedModified = CASE WHEN @ExistingQtyReq <> @QtyRequested THEN 1 ELSE 0 END;

							UPDATE [DBO].[SalesOrderQuotePartV1]
							SET 
							CustomerRequestDate = @CustomerRequestDate,
							PromisedDate = @PromisedDate,
							EstimatedShipDate = @EstimatedShipDate,
							Notes = @Notes,
							IsNoQuote = @IsNoQuote,
							QtyRequested = @QtyRequested,
							QtyQuoted = @QtyQuoted
							WHERE SalesOrderQuotePartId = @SalesOrderQuotePartId

							-- Update Part Details
							DECLARE @QtyQuoted_U AS INT = 0;

							DECLARE @SalesPrice_U AS decimal(18,4);
							DECLARE @MarkUpAmt_U AS decimal(18,4);
							DECLARE @DiscAmt_U AS decimal(18,4);
							DECLARE @GrossAmt_U AS decimal(18,4);
							DECLARE @NetSalesAmt_U AS decimal(18,4);
							DECLARE @NetSalesPerUnitAmt_U AS decimal(18,4);

							SET @SalesPrice_U = ISNULL(@UnitSalesPrice, 0);
							SET @MarkUpAmt_U = ISNULL(@MarkUpAmount, 0) * @QtyQuoted;
							SET @DiscAmt_U = ISNULL(@DiscountAmount, 0) * @QtyQuoted;
							SET @GrossAmt_U = ((@SalesPrice_U * @QtyQuoted) + @MarkUpAmt_U);
							SET @NetSalesAmt_U = @GrossAmt_U - (@DiscAmt_U);
							SET @NetSalesPerUnitAmt_U = ((@SalesPrice_U) + ISNULL(@MarkUpAmount, 0)) - (ISNULL(@DiscountAmount, 0));

							UPDATE [DBO].[SalesOrderQuotePartCost]
							SET UnitSalesPrice = @SalesPrice_U,
							MarkUpPercentage = @MarkUpPercentage,
							MarkUpAmount = @MarkUpAmt_U,
							DiscountPercentage = @DiscountPercentage,
							DiscountAmount = @DiscAmt_U,
							GrossSaleAmount = ISNULL(@GrossAmt_U, 0),
							NetSaleAmount = ISNULL(@NetSalesAmt_U, 0),
							NetSaleAmountPerUnit = @NetSalesPerUnitAmt_U
							WHERE SalesOrderQuotePartId = @SalesOrderQuotePartId

							IF (@SalesOrderQuoteStocklineId IS NOT NULL AND @SalesOrderQuoteStocklineId > 0) -- Added at Stockline Level
							BEGIN
								UPDATE [DBO].[SalesOrderQuoteStocklineV1]
								SET CustomerRequestDate = @CustomerRequestDate,
								PromisedDate = @PromisedDate,
								EstimatedShipDate = @EstimatedShipDate,
								Notes = @Notes
								WHERE SalesOrderQuoteStocklineId = @SalesOrderQuoteStocklineId;

								UPDATE [DBO].[SalesOrderQuoteStockLineCost]
								SET UnitSalesPrice = @UnitSalesPrice,
								MarkUpPercentage = @MarkUpPercentage,
								DiscountPercentage = @DiscountPercentage,
								MarkUpAmount = @MarkUpAmt_U,
								DiscountAmount = @DiscAmt_U
								WHERE SalesOrderQuoteStocklineId = @SalesOrderQuoteStocklineId;
							END

							;WITH QuotedSums AS (
								SELECT SOP.SalesOrderQuotePartId, SUM(ISNULL(SOS.QtyQuoted, 0)) AS TotalQtyQuoted
								FROM [DBO].[SalesOrderQuotePartV1] SOP
								LEFT JOIN [DBO].[SalesOrderQuoteStocklineV1] SOS ON SOP.SalesOrderQuotePartId = SOS.SalesOrderQuotePartId
								WHERE SOS.SalesOrderQuotePartId IS NOT NULL
								GROUP BY SOP.SalesOrderQuotePartId
							)

							UPDATE SOP
							SET SOP.QtyRequested = @QtyRequested,
								SOP.QtyQuoted = CASE WHEN QS.TotalQtyQuoted > 0 THEN QS.TotalQtyQuoted ELSE SOP.QtyQuoted END
							FROM [DBO].[SalesOrderQuotePartV1] SOP
							INNER JOIN QuotedSums QS ON SOP.SalesOrderQuotePartId = QS.SalesOrderQuotePartId
							WHERE SOP.SalesOrderQuotePartId = @SalesOrderQuotePartId;

							IF NOT EXISTS (SELECT TOP 1 1 FROM [DBO].[SalesOrderQuoteStocklineV1] SOS WITH (NOLOCK) WHERE SOS.SalesOrderQuotePartId = @SalesOrderQuotePartId)
							BEGIN
								UPDATE SOP
								SET SOP.QtyQuoted = CASE WHEN @IsQtyRequestedModified = 1 THEN @QtyRequested ELSE @QtyQuoted END
								FROM [DBO].[SalesOrderQuotePartV1] SOP
								WHERE SOP.SalesOrderQuotePartId = @SalesOrderQuotePartId;
							END
						END

						SELECT @SalesOrderQuoteId, @SalesOrderQuotePartId, @CreatedBy, @MasterCompanyId;

						EXEC [dbo].[USP_UpdateSOQPartCostDetails] @SalesOrderQuoteId, @SalesOrderQuotePartId, @CreatedBy, @MasterCompanyId;

						SET @MinsoqId = @MinsoqId + 1;
					END
					---------------------------End Part Add----------------------------------------
				END
			END
			SET @SoqId = @SalesOrderQuoteId
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
													@Parameter7 = '''+ CAST(ISNULL(@SalesPersonId, '') AS varchar(100) ) + ''',
													@Parameter8 = '''+ CAST(ISNULL(@CustomerServiceRepId, '') AS varchar(100) ) + ''',
													@Parameter9 = '''+ CAST(ISNULL(@ProbabilityId, '') AS varchar(100) ) + ''',
													@Parameter10 = '''+ CAST(ISNULL(@LeadSourceId, '') AS varchar(100) ) + ''',
													@Parameter11 = '''+ CAST(ISNULL(@EmployeeId, '') AS varchar(100) ) + ''',
													@Parameter12 = '''+ CAST(ISNULL(@CustomerWarningId, '') AS varchar(100) ) + ''

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