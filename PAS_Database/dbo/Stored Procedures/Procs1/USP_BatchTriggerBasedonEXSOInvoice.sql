/*************************************************************           
 ** File:   [USP_BatchTriggerBasedonEXSOInvoice]
 ** Author:  Moin Bloch
 ** Description: This stored procedure is used to store Batch Details on Excahnge SO Shipping.
 ** Purpose:         
 ** Date:   08/04/2023
          
 ** PARAMETERS: @DistributionMasterId BIGINT,@ReferenceId BIGINT,@ReferencePartId BIGINT,@ReferencePieceId BIGINT,@InvoiceId BIGINT,@StocklineId BIGINT,@Qty INT,@Amount DECIMAL(18,2),@ModuleName VARCHAR(200),@MasterCompanyId INT,@UpdateBy VARCHAR(200) 
         
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    07/08/2023   Moin Bloch    Created
	2    09/08/2023   Moin Bloch    Added Billing Batch Entry and Core Return Batch Entry
	3    18/08/2023   Moin Bloch    Modify(Added Accounting MS Entry)
	4    01/12/2023   Moin Bloch    Modify(Added LotId And Lot Number in CommonBatchDetails)
	5    11/12/2023   Moin Bloch    Modify(If Invoice Entry NOT EXISTS Then only Invoice Entry Will Store)
     
   EXEC [dbo].[USP_BatchTriggerBasedonEXSOInvoice] 
************************************************************************/
CREATE   PROCEDURE [dbo].[USP_BatchTriggerBasedonEXSOInvoice]
@DistributionMasterId BIGINT=NULL,
@ReferenceId BIGINT=NULL,
@ReferencePartId BIGINT=NULL,
@ReferencePieceId BIGINT=NULL,
@InvoiceId BIGINT=NULL,
@StocklineId BIGINT=NULL,
@Qty INT=0,
@Amount DECIMAL(18,2),
@ModuleName VARCHAR(200),
@MasterCompanyId INT,
@UpdateBy VARCHAR(200) 
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;
	BEGIN TRY
	  BEGIN TRANSACTION  
	  BEGIN  	
		DECLARE @JournalTypeId INT
	    DECLARE @JournalTypeCode VARCHAR(200) 
	    DECLARE @JournalBatchHeaderId BIGINT
	    DECLARE @GlAccountId INT
	    DECLARE @StatusId INT
	    DECLARE @StatusName VARCHAR(200)
	    DECLARE @StartsFrom VARCHAR(200)='00'
	    DECLARE @CurrentNumber INT
	    DECLARE @GlAccountName VARCHAR(200) 
	    DECLARE @GlAccountNumber VARCHAR(200) 
	    DECLARE @JournalTypename VARCHAR(200) 
	    DECLARE @Distributionname VARCHAR(200) 
	    DECLARE @CustomerId BIGINT
	    DECLARE @ManagementStructureId BIGINT
	    DECLARE @CustomerName VARCHAR(200)
        DECLARE @ExchangeSalesOrderNumber VARCHAR(200) 
        DECLARE @MPNName VARCHAR(200) 
	    DECLARE @PiecePNId BIGINT
        DECLARE @PiecePN VARCHAR(200) 
        DECLARE @ItemmasterId BIGINT
	    DECLARE @PieceItemmasterId BIGINT
	    DECLARE @CustRefNumber VARCHAR(200)
	    DECLARE @LineNumber INT=1
	    DECLARE @TotalDebit DECIMAL(18,2)=0
	    DECLARE @TotalCredit DECIMAL(18,2)=0
	    DECLARE @TotalBalance DECIMAL(18,2)=0
	    DECLARE @UnitPrice DECIMAL(18,2)=0
	    DECLARE @LaborHrs DECIMAL(18,2)=0
	    DECLARE @DirectLaborCost DECIMAL(18,2)=0
	    DECLARE @OverheadCost DECIMAL(18,2)=0
	    DECLARE @partId BIGINT=0
		DECLARE @batch VARCHAR(100)
		DECLARE @AccountingPeriod VARCHAR(100)
		DECLARE @AccountingPeriodId BIGINT=0
		DECLARE @CurrentPeriodId BIGINT=0
		DECLARE @Currentbatch VARCHAR(100)
	    DECLARE @LastMSLevel VARCHAR(200)
		DECLARE @AllMSlevels VARCHAR(max)
		DECLARE @DistributionSetupId INT=0
		DECLARE @IsAccountByPass BIT=0
		DECLARE @DistributionCode VARCHAR(200)
		DECLARE @InvoiceTotalCost DECIMAL(18,2)=0
		DECLARE @InvoiceNo VARCHAR(100)
		DECLARE @CurrentManagementStructureId BIGINT=0
		DECLARE @JournalBatchDetailId BIGINT=0
	    DECLARE @currentNo AS BIGINT = 0;
		DECLARE @CodeTypeId AS BIGINT = 74;
		DECLARE @JournalTypeNumber VARCHAR(100);
		DECLARE @CustomerTypeId INT=0;
		DECLARE @CustomerTypeName VARCHAR(50);
		DECLARE @StocklineNumber VARCHAR(50);
		DECLARE @FreightBillingMethodId INT;
		DECLARE @ChargesBillingMethodId INT;
		DECLARE @CommonJournalBatchDetailId BIGINT=0;
		DECLARE @PartGLAccountId BIGINT;
		DECLARE @STKGlAccountId INT;
		DECLARE @STKGlAccountName VARCHAR(200);
		DECLARE @STKGlAccountNumber VARCHAR(200);
		DECLARE @PartUnitSalesPrices DECIMAL(18,2);
		DECLARE @STKId BIGINT;
		DECLARE @CrDrType BIGINT;
		DECLARE @ValidDistribution BIT = 1;
		DECLARE @EXSOHeaderMSModuleId BIGINT;
		DECLARE @AccountMSModuleId INT = 0
		DECLARE @LotId BIGINT=0;
		DECLARE @LotNumber VARCHAR(50);

		SELECT @IsAccountByPass = [IsAccountByPass] FROM [dbo].[MasterCompany] WITH(NOLOCK)  WHERE [MasterCompanyId] = @MasterCompanyId;
	    SELECT @DistributionCode = [DistributionCode] FROM [dbo].[DistributionMaster] WITH(NOLOCK)  WHERE [ID] = @DistributionMasterId;
		SELECT TOP 1 @JournalTypeId = [JournalTypeId] FROM [dbo].[DistributionSetup] WITH(NOLOCK) WHERE [DistributionMasterId] = @DistributionMasterId;
		SELECT @JournalTypeCode = [JournalTypeCode], @JournalTypename = [JournalTypeName] FROM [dbo].[JournalType] WITH(NOLOCK)  WHERE [ID] = @JournalTypeId;
		SELECT @StatusId = [Id], @StatusName = [name] FROM [dbo].[BatchStatus] WITH(NOLOCK) WHERE [Name] = 'Open';
		SELECT @JournalBatchHeaderId = [JournalBatchHeaderId] FROM [dbo].[BatchHeader] WITH(NOLOCK)  WHERE [JournalTypeId] = @JournalTypeId AND [StatusId] = @StatusId;	       	    		
		SELECT @EXSOHeaderMSModuleId = [ManagementStructureModuleId] from [dbo].[ManagementStructureModule] WITH(NOLOCK) WHERE [ModuleName] = 'ExchangeSOHeader';
		SELECT @CodeTypeId = [CodeTypeId] FROM [dbo].[CodeTypes] WITH(NOLOCK) WHERE UPPER([CodeType]) = UPPER('JOURNALTYPE');
		SELECT @AccountMSModuleId = [ManagementStructureModuleId] FROM [dbo].[ManagementStructureModule] WITH(NOLOCK) WHERE [ModuleName] ='Accounting';
		
		SELECT @CurrentManagementStructureId = [ManagementStructureId] FROM [dbo].[Employee] WITH(NOLOCK) 
		  WHERE CONCAT(TRIM([FirstName]),'',TRIM([LastName])) IN (REPLACE(@UpdateBy, ' ', '')) AND [MasterCompanyId] = @MasterCompanyId

		IF((@JournalTypeCode ='EXPS' OR  @JournalTypeCode ='EXFB' OR @JournalTypeCode ='EXCR') AND @IsAccountByPass = 0)
		BEGIN
			SELECT @ExchangeSalesOrderNumber = [ExchangeSalesOrderNumber],
			       @CustomerId = [CustomerId],				   
				   @CustRefNumber = [CustomerReference],
				   @ManagementStructureId = [ManagementStructureId]			      
			 FROM [dbo].[ExchangeSalesOrder] WITH(NOLOCK)  WHERE [ExchangeSalesOrderId] = @ReferenceId;
					  
			SELECT @CustomerTypeId = CUS.[CustomerAffiliationId],
			       @CustomerTypeName = CAF.[Description] 
			 FROM [dbo].[Customer] CUS WITH(NOLOCK)
			 	INNER JOIN [dbo].[CustomerAffiliation] CAF WITH(NOLOCK) ON CUS.[CustomerAffiliationId] = CAF.[CustomerAffiliationId] 
			 WHERE CUS.[CustomerId] = @CustomerId;
			 			
			SET @partId = @ReferencePartId;
						
			IF(@JournalTypeCode = 'EXCR')
			BEGIN
				SELECT @partId = ExchangeSalesOrderPartId FROM [dbo].[ExchangeSalesOrderPart] EP WITH(NOLOCK) WHERE EP.[ExchangeSalesOrderId] = @ReferenceId;
			END
	        
			SELECT @ItemmasterId = EP.[ItemMasterId],
			        @MPNName = IM.[partnumber],
					@StockLineId = EP.[StockLineId]
			  FROM [dbo].[ExchangeSalesOrderPart] EP WITH(NOLOCK) 
			  INNER JOIN [dbo].[ItemMaster] IM WITH(NOLOCK) ON EP.[ItemMasterId] = IM.[ItemMasterId]
			 WHERE EP.[ExchangeSalesOrderId] = @ReferenceId AND EP.[ExchangeSalesOrderPartId] = @partId
			 	        
	        SELECT @LastMSLevel = [LastMSLevel],
			       @AllMSlevels = [AllMSlevels] 
			  FROM [dbo].[ExchangeManagementStructureDetails] WITH(NOLOCK) 
			 WHERE [ReferenceID] = @ReferenceId AND [ModuleID] = @EXSOHeaderMSModuleId;
			 
			SELECT @StocklineNumber = [StockLineNumber] FROM [dbo].[Stockline] WITH(NOLOCK) WHERE [StockLineId] = @StockLineId;

			SELECT TOP 1  @AccountingPeriodId = ACC.[AccountingCalendarId],
			              @AccountingPeriod = ACC.[PeriodName] 
					FROM [dbo].[EntityStructureSetup] EST WITH(NOLOCK) 
			INNER JOIN [dbo].[ManagementStructureLevel] MSL WITH(NOLOCK) ON EST.Level1Id = MSL.ID 
			INNER JOIN [dbo].[AccountingCalendar] ACC WITH(NOLOCK) ON MSL.LegalEntityId = ACC.LegalEntityId AND ACC.IsDeleted = 0
			WHERE EST.[EntityStructureId] = @CurrentManagementStructureId 
			AND ACC.[MasterCompanyId] = @MasterCompanyId 
			AND CAST(GETUTCDATE() AS DATE) >= CAST(FromDate AS DATE) AND CAST(GETUTCDATE() AS DATE) <= CAST(ToDate AS DATE)
		            
			--SELECT @InvoiceNo = [InvoiceNo] FROM [dbo].[ExchangeSalesOrderBillingInvoicing] WITH(NOLOCK) WHERE [SOBillingInvoicingId] = @InvoiceId;

			IF OBJECT_ID(N'tempdb..#tmpCodePrefixes') IS NOT NULL
			BEGIN
				DROP TABLE #tmpCodePrefixes
			END
				
			CREATE TABLE #tmpCodePrefixes
			(
				[ID] BIGINT NOT NULL IDENTITY, 
				[CodePrefixId] BIGINT NULL,
				[CodeTypeId] BIGINT NULL,
				[CurrentNumber] BIGINT NULL,
				[CodePrefix] VARCHAR(50) NULL,
				[CodeSufix] VARCHAR(50) NULL,
				[StartsFrom] BIGINT NULL,
			)

			INSERT INTO #tmpCodePrefixes ([CodePrefixId],[CodeTypeId],[CurrentNumber], [CodePrefix], [CodeSufix], [StartsFrom]) 
			SELECT [CodePrefixId], CP.[CodeTypeId], [CurrentNummber], [CodePrefix], [CodeSufix], [StartsFrom] 
			FROM [dbo].[CodePrefixes] CP WITH(NOLOCK) JOIN [dbo].[CodeTypes] CT ON CP.[CodeTypeId] = CT.CodeTypeId
			WHERE CT.[CodeTypeId] IN (@CodeTypeId) AND CP.[MasterCompanyId] = @MasterCompanyId AND CP.[IsActive] = 1 AND CP.[IsDeleted] = 0;

			IF(EXISTS (SELECT 1 FROM #tmpCodePrefixes WHERE [CodeTypeId] = @CodeTypeId))
			BEGIN 
				SELECT @currentNo = CASE WHEN [CurrentNumber] > 0 THEN CAST([CurrentNumber] AS BIGINT) + 1 ELSE CAST([StartsFrom] AS BIGINT) + 1 END 
				FROM #tmpCodePrefixes WHERE [CodeTypeId] = @CodeTypeId

				SET @JournalTypeNumber = (SELECT * FROM dbo.udfGenerateCodeNumber(@currentNo,(SELECT [CodePrefix] FROM #tmpCodePrefixes WHERE [CodeTypeId] = @CodeTypeId), (SELECT [CodeSufix] FROM #tmpCodePrefixes WHERE [CodeTypeId] = @CodeTypeId)))
			END
			ELSE 
			BEGIN
				ROLLBACK TRAN;
			END

			IF(UPPER(@DistributionCode) = UPPER('EX-SHIPMENT'))
	        BEGIN				
				SELECT @InvoiceNo = [SOShippingNum] FROM [dbo].[ExchangeSalesOrderShipping] WITH(NOLOCK) WHERE [ExchangeSalesOrderShippingId] = @InvoiceId;
				
				IF EXISTS(SELECT 1 FROM [dbo].[DistributionSetup] WITH(NOLOCK) WHERE [DistributionMasterId] = @DistributionMasterId AND [MasterCompanyId] = @MasterCompanyId AND ISNULL([GlAccountId],0) = 0)
				BEGIN
					SET @ValidDistribution = 0;
				END

				IF(@ValidDistribution = 1)
				BEGIN					
					SELECT @PartUnitSalesPrices = (SUM(ISNULL(ESOP.[UnitCost],0)) * SUM(ISNULL(ESOP.[qty],0)))
					FROM [dbo].[ExchangeSalesOrderShipping] ESOI WITH(NOLOCK)
					INNER JOIN [dbo].[ExchangeSalesOrderShippingItem] ESSI WITH(NOLOCK) ON ESOI.[ExchangeSalesOrderShippingId] = ESSI.[ExchangeSalesOrderShippingId]
					INNER JOIN [dbo].[ExchangeSalesOrderPart] ESOP WITH(NOLOCK) ON ESSI.[ExchangeSalesOrderPartId] = ESOP.[ExchangeSalesOrderPartId]
					INNER JOIN [dbo].[Stockline] STL WITH(NOLOCK) ON ESOP.[StockLineId] = STL.[StockLineId]
					WHERE ESOI.[ExchangeSalesOrderShippingId] = @InvoiceId
					
					IF(@PartUnitSalesPrices > 0)
					BEGIN
						IF NOT EXISTS(SELECT [JournalBatchHeaderId] FROM [dbo].[BatchHeader] WITH(NOLOCK) WHERE [JournalTypeId] = @JournalTypeId AND [MasterCompanyId]=@MasterCompanyId AND CAST([EntryDate] AS DATE) = CAST(GETUTCDATE() AS DATE) AND [StatusId] = @StatusId AND [CustomerTypeId]=@CustomerTypeId)
						BEGIN
							IF NOT EXISTS(SELECT [JournalBatchHeaderId] FROM [dbo].[BatchHeader] WITH(NOLOCK))
							BEGIN
								SET @batch ='001'
								SET @Currentbatch='001'
							END
							ELSE
							BEGIN
								SELECT TOP 1 @Currentbatch = CASE WHEN [CurrentNumber] > 0 THEN CAST([CurrentNumber] AS BIGINT) + 1 
				   							                      ELSE  1 END 
				   					FROM [dbo].[BatchHeader] WITH(NOLOCK) ORDER BY [JournalBatchHeaderId] DESC 

								IF(CAST(@Currentbatch AS BIGINT) > 99)
								BEGIN
									SET @batch = CASE WHEN CAST(@Currentbatch AS BIGINT) > 99 THEN CAST(@Currentbatch AS VARCHAR(100))
				   							          ELSE CONCAT('00', CAST(@Currentbatch AS VARCHAR(50))) END 
								END
								ELSE IF(CAST(@Currentbatch AS BIGINT) > 9)
								BEGIN
									SET @batch = CASE WHEN CAST(@Currentbatch AS BIGINT) > 99 THEN CAST(@Currentbatch AS VARCHAR(100))
				   							          ELSE CONCAT('0', CAST(@Currentbatch AS VARCHAR(50))) END 
								END
								ELSE
								BEGIN
									SET @batch = CASE WHEN CAST(@Currentbatch AS BIGINT) > 99 THEN CAST(@Currentbatch AS VARCHAR(100))
				   							          ELSE CONCAT('00', CAST(@Currentbatch AS VARCHAR(50))) END 
								END			               
							END

							SET @CurrentNumber = CAST(@Currentbatch AS BIGINT) 

							SET @batch = CAST(@JournalTypeCode +' '+ CAST(@batch AS VARCHAR(100)) AS VARCHAR(100))					
				          
							INSERT INTO [dbo].[BatchHeader]
							           ([BatchName],
									    [CurrentNumber],
										[EntryDate],
										[AccountingPeriod],
										[AccountingPeriodId],
										[StatusId],
										[StatusName],
										[JournalTypeId],
										[JournalTypeName],
										[TotalDebit],
										[TotalCredit],
										[TotalBalance],
										[MasterCompanyId],
										[CreatedBy],
										[UpdatedBy],
										[CreatedDate],
										[UpdatedDate],
										[IsActive],
										[IsDeleted],
										[Module],
										[CustomerTypeId])
							      VALUES(@batch,
								         @CurrentNumber,
										 GETUTCDATE(),
										 @AccountingPeriod,
										 @AccountingPeriodId,
										 @StatusId,
										 @StatusName,
										 @JournalTypeId,
										 @JournalTypename,
										 @Amount,
										 @Amount,
										 0,
										 @MasterCompanyId,
										 @UpdateBy,
										 @UpdateBy,
										 GETUTCDATE(),
										 GETUTCDATE(),
										 1,
										 0,
										 'EXPS',
										 @CustomerTypeId);
            	          
							SELECT @JournalBatchHeaderId = SCOPE_IDENTITY();

							UPDATE [dbo].[BatchHeader] 
							   SET [CurrentNumber] = @CurrentNumber 
							 WHERE [JournalBatchHeaderId] = @JournalBatchHeaderId;		   
						END
						ELSE 
						BEGIN
							SELECT @JournalBatchHeaderId = JournalBatchHeaderId,
							       @CurrentPeriodId = ISNULL(AccountingPeriodId,0) 
							 FROM [dbo].[BatchHeader] WITH(NOLOCK)  
							 WHERE [JournalTypeId] = @JournalTypeId AND 
							       [StatusId] = @StatusId AND 
								   [CustomerTypeId] = @CustomerTypeId;

							SELECT @LineNumber = CASE WHEN [LineNumber] > 0 THEN CAST([LineNumber] AS BIGINT) + 1 ELSE  1 END 
				   			  FROM [dbo].[BatchDetails] WITH(NOLOCK) 
							  WHERE [JournalBatchHeaderId] = @JournalBatchHeaderId  ORDER BY [JournalBatchDetailId] DESC 
				    
							IF(@CurrentPeriodId = 0)
							BEGIN
								UPDATE [dbo].[BatchHeader] 
								   SET [AccountingPeriodId] = @AccountingPeriodId,
								       [AccountingPeriod]= @AccountingPeriod   
								 WHERE [JournalBatchHeaderId] = @JournalBatchHeaderId
							END
						END
						
						INSERT INTO [dbo].[BatchDetails]
						           ([JournalTypeNumber],
								    [CurrentNumber],
									[DistributionSetupId], 
									[DistributionName], 
									[JournalBatchHeaderId], 
									[LineNumber], 
									[GlAccountId], 
									[GlAccountNumber], 
									[GlAccountName], 
									[TransactionDate], 
									[EntryDate], 
									[JournalTypeId], 
									[JournalTypeName], 
						            [IsDebit], 
									[DebitAmount], 
									[CreditAmount], 
									[ManagementStructureId], 
									[ModuleName], 
									[LastMSLevel], 
									[AllMSlevels], 
									[MasterCompanyId], 
									[CreatedBy], 
									[UpdatedBy], 
									[CreatedDate], 
									[UpdatedDate], 
									[IsActive], 
									[IsDeleted],
									[AccountingPeriodId],
									[AccountingPeriod])
							 VALUES(@JournalTypeNumber,
							        @currentNo,
									0, 
									NULL, 
									@JournalBatchHeaderId, 
									1, 
									0, 
									NULL, 
									NULL,
									GETUTCDATE(), 
									GETUTCDATE(), 
									@JournalTypeId, 
									@JournalTypename, 
							        1, 
									0, 
									0, 
									0, 
									@ModuleName, 
									NULL, 
									NULL, 
									@MasterCompanyId, 
									@UpdateBy, 
									@UpdateBy, 
									GETUTCDATE(), 
									GETUTCDATE(), 
									1, 
									0,
									@AccountingPeriodId,
									@AccountingPeriod)
						
						SET @JournalBatchDetailId = SCOPE_IDENTITY();
					END

					---- GL Account wise Inventory on Exchange Agreeement and Inventory-Parts Entry ----
					DECLARE @ExchangeSalesOrderPartDetailsCursor1 AS CURSOR;
					SET @ExchangeSalesOrderPartDetailsCursor1 = CURSOR FAST_FORWARD FOR	
					SELECT STL.[GLAccountId] AS PartGLAccountId FROM [dbo].[ExchangeSalesOrderShipping] ESOI WITH(NOLOCK)
					INNER JOIN [dbo].[ExchangeSalesOrderShippingItem] ESSI WITH(NOLOCK) ON ESOI.[ExchangeSalesOrderShippingId] = ESSI.[ExchangeSalesOrderShippingId]
					INNER JOIN [dbo].[ExchangeSalesOrderPart] ESOP WITH(NOLOCK) ON ESSI.[ExchangeSalesOrderPartId] = ESOP.[ExchangeSalesOrderPartId]
					INNER JOIN [dbo].[Stockline] STL WITH(NOLOCK) ON ESOP.[StockLineId] = STL.[StockLineId]
					WHERE ESOI.[ExchangeSalesOrderShippingId] = @InvoiceId GROUP BY STL.[GLAccountId]

					OPEN @ExchangeSalesOrderPartDetailsCursor1;
					FETCH NEXT FROM @ExchangeSalesOrderPartDetailsCursor1 INTO @PartGLAccountId;
					WHILE @@FETCH_STATUS = 0
					BEGIN					
						SELECT @PartUnitSalesPrices = (SUM(ISNULL(ESOP.UnitCost,0)) * SUM(ISNULL(ESOP.qty,0)))
					    FROM [dbo].[ExchangeSalesOrderShipping] ESOI WITH(NOLOCK)
					    INNER JOIN [dbo].[ExchangeSalesOrderShippingItem] ESSI WITH(NOLOCK) ON ESOI.ExchangeSalesOrderShippingId = ESSI.ExchangeSalesOrderShippingId
					    INNER JOIN [dbo].[ExchangeSalesOrderPart] ESOP WITH(NOLOCK) ON ESSI.ExchangeSalesOrderPartId = ESOP.ExchangeSalesOrderPartId
					    INNER JOIN [dbo].[Stockline] STL WITH(NOLOCK) ON ESOP.StockLineId = STL.StockLineId
					    WHERE ESOI.[ExchangeSalesOrderShippingId] = @InvoiceId AND STL.GLAccountId= @PartGLAccountId;
									
						SELECT TOP 1 @STKId = STL.StockLineId 
						FROM [dbo].[ExchangeSalesOrderShipping] ESOI WITH(NOLOCK)
					    INNER JOIN [dbo].[ExchangeSalesOrderShippingItem] ESSI WITH(NOLOCK) ON ESOI.ExchangeSalesOrderShippingId = ESSI.ExchangeSalesOrderShippingId
					    INNER JOIN [dbo].[ExchangeSalesOrderPart] ESOP WITH(NOLOCK) ON ESSI.ExchangeSalesOrderPartId = ESOP.ExchangeSalesOrderPartId
						INNER JOIN [dbo].[Stockline] STL WITH(NOLOCK) ON ESOP.StockLineId = STL.StockLineId
						WHERE ESOI.[ExchangeSalesOrderShippingId] = @InvoiceId AND STL.GLAccountId= @PartGLAccountId;

						SELECT  @STKGlAccountId = SL.[GLAccountId],
						        @STKGlAccountNumber = GL.[AccountCode],
								@STKGlAccountName = GL.[AccountName], 
								@LotId = SL.LotId,
								@LotNumber = LO.[LotNumber],
								@StocklineId = SL.[StockLineId],
								@StocklineNumber = SL.[StockLineNumber]
						   FROM [dbo].[Stockline] SL WITH(NOLOCK)
						  INNER JOIN [dbo].[GLAccount] GL WITH(NOLOCK) ON SL.GLAccountId = GL.GLAccountId 
						   LEFT JOIN [dbo].[Lot] LO WITH(NOLOCK) ON  LO.LotId = SL.LotId  
						    WHERE SL.[StockLineId] = @STKId;

						--------------------------------------------------- Inventory on Exchange Agreeement Start ---------------------------------------------------
						IF(@PartUnitSalesPrices > 0)
						BEGIN
							SELECT TOP 1 @DistributionSetupId = [ID],
							             @DistributionName = [Name],
									     @JournalTypeId = [JournalTypeId],
									     @GlAccountId = [GlAccountId],
									     @GlAccountNumber = [GlAccountNumber],
									     @GlAccountName = [GlAccountName],
									     @CrDrType = [CRDRType]
							        FROM [dbo].[DistributionSetup] WITH(NOLOCK) 
							       WHERE UPPER([DistributionSetupCode]) = UPPER('EX-INVAGM') 
							         AND [DistributionMasterId] = @DistributionMasterId 
							         AND [MasterCompanyId] = @MasterCompanyId	

							INSERT INTO [dbo].[CommonBatchDetails]
									   ([JournalBatchDetailId],
									    [JournalTypeNumber],
										[CurrentNumber],
										[DistributionSetupId],
										[DistributionName],
										[JournalBatchHeaderId],
										[LineNumber],
										[GlAccountId],
										[GlAccountNumber],
										[GlAccountName],
										[TransactionDate],
										[EntryDate],
										[JournalTypeId],
										[JournalTypeName],
								        [IsDebit],
										[DebitAmount],
										[CreditAmount],
										[ManagementStructureId],
										[ModuleName],
										[LastMSLevel],
										[AllMSlevels],
										[MasterCompanyId],
										[CreatedBy],
										[UpdatedBy],
										[CreatedDate],
										[UpdatedDate],
										[IsActive],
										[IsDeleted],
										[LotId],
										[LotNumber]
										)
							     VALUES
								       (@JournalBatchDetailId,
									    @JournalTypeNumber,
										@currentNo,
										@DistributionSetupId,
										@DistributionName,
										@JournalBatchHeaderId,
										1,
										@GlAccountId,
										@GlAccountNumber,
										@GlAccountName,
										GETUTCDATE(),
										GETUTCDATE(),
										@JournalTypeId,
										@JournalTypename,
								        CASE WHEN @CrDrType = 1 THEN 1 ELSE 0 END,
								        CASE WHEN @CrDrType = 1 THEN @PartUnitSalesPrices ELSE 0 END,
								        CASE WHEN @CrDrType = 1 THEN 0 ELSE @PartUnitSalesPrices END,
								        @ManagementStructureId,
										@ModuleName,
										@LastMSLevel,
										@AllMSlevels,
										@MasterCompanyId,
										@UpdateBy,
										@UpdateBy,
										GETUTCDATE(),
										GETUTCDATE(),
										1,
										0,
										@LotId,
										@LotNumber);

							SET @CommonJournalBatchDetailId = SCOPE_IDENTITY();

							-----  Accounting MS Entry  -----

							EXEC [dbo].[PROCAddUpdateAccountingBatchMSData] @CommonJournalBatchDetailId,@ManagementStructureId,@MasterCompanyId,@UpdateBy,@AccountMSModuleId,1; 
														
                            INSERT INTO [dbo].[ExchangeBatchDetails]
                                       ([CommonJournalBatchDetailId]
                                       ,[JournalBatchDetailId]
                                       ,[JournalBatchHeaderId]
                                       ,[ExchangeSalesOrderId]
                                       ,[ExchangeSalesOrderNumber]
                                       ,[CustomerId]
                                       ,[CustomerReference]
                                       ,[ExchangeSalesOrderPartId]
                                       ,[ItemMasterId]
                                       ,[StockLineId]
                                       ,[StocklineNumber]
                                       ,[InvoiceId]
                                       ,[InvoiceNo]
									   ,[TypeId]
									   ,[DistSetupCode])
                                 VALUES
                                       (@CommonJournalBatchDetailId
									   ,@JournalBatchDetailId
                                       ,@JournalBatchHeaderId
                                       ,@ReferenceId
                                       ,@ExchangeSalesOrderNumber
									   ,@CustomerId
									   ,@CustRefNumber
									   ,@partId
									   ,@ItemmasterId
									   ,@StocklineId
									   ,@StocklineNumber
									   ,@InvoiceId
									   ,@InvoiceNo
									   ,1
									   ,'EX-INVAGM');                                                               
						END	
						---------------------------------------------------End ---------------------------------------------------

						--------------------------------------------------- Inventory - Parts Start ---------------------------------------------------
 
						IF(@PartUnitSalesPrices > 0)
						BEGIN
							SELECT TOP 1 @DistributionSetupId = ID,
							             @DistributionName =[Name],
										 @JournalTypeId = [JournalTypeId],
										 @GlAccountId = [GlAccountId],
										 @GlAccountNumber = [GlAccountNumber],
										 @GlAccountName = [GlAccountName],
										 @CrDrType = [CRDRType]
							        FROM [dbo].[DistributionSetup] WITH(NOLOCK)  
									WHERE UPPER(DistributionSetupCode) = UPPER('EX-INVPARTS') 
									AND [DistributionMasterId] = @DistributionMasterId 
									AND [MasterCompanyId] = @MasterCompanyId;	
													    
				    		INSERT INTO [dbo].[CommonBatchDetails]
				    			       ([JournalBatchDetailId],
									    [JournalTypeNumber],
									    [CurrentNumber],
									    [DistributionSetupId],
									    [DistributionName],
									    [JournalBatchHeaderId],
									    [LineNumber],
									    [GlAccountId],
									    [GlAccountNumber],
									    [GlAccountName],
									    [TransactionDate],
									    [EntryDate],
									    [JournalTypeId],
									    [JournalTypeName],
								        [IsDebit],
									    [DebitAmount],
									    [CreditAmount],
									    [ManagementStructureId],
									    [ModuleName],
									    [LastMSLevel],
									    [AllMSlevels],
									    [MasterCompanyId],
									    [CreatedBy],
									    [UpdatedBy],
									    [CreatedDate],
									    [UpdatedDate],
									    [IsActive],
									    [IsDeleted],
										[LotId],
										[LotNumber])
				    		     VALUES
				    			       (@JournalBatchDetailId,
									    @JournalTypeNumber,
										@currentNo,
										@DistributionSetupId,
										@DistributionName,
										@JournalBatchHeaderId,
										1,
										@GlAccountId,
										@GlAccountNumber,
										@GlAccountName,
										GETUTCDATE(),
										GETUTCDATE(),
										@JournalTypeId,
										@JournalTypename,
								        CASE WHEN @CrDrType = 1 THEN 1 ELSE 0 END,
								        CASE WHEN @CrDrType = 1 THEN @PartUnitSalesPrices ELSE 0 END,
								        CASE WHEN @CrDrType = 1 THEN 0 ELSE @PartUnitSalesPrices END,
								        @ManagementStructureId ,
										@ModuleName,
										@LastMSLevel,
										@AllMSlevels,
										@MasterCompanyId,
										@UpdateBy,
										@UpdateBy,
										GETUTCDATE(),
										GETUTCDATE(),
										1,
										0,
										@LotId,
										@LotNumber);
				    
							SET @CommonJournalBatchDetailId = SCOPE_IDENTITY();

							-----  Accounting MS Entry  -----

							EXEC [dbo].[PROCAddUpdateAccountingBatchMSData] @CommonJournalBatchDetailId,@ManagementStructureId,@MasterCompanyId,@UpdateBy,@AccountMSModuleId,1; 
				    							
							INSERT INTO [dbo].[ExchangeBatchDetails]
                                       ([CommonJournalBatchDetailId]
                                       ,[JournalBatchDetailId]
                                       ,[JournalBatchHeaderId]
                                       ,[ExchangeSalesOrderId]
                                       ,[ExchangeSalesOrderNumber]
                                       ,[CustomerId]
                                       ,[CustomerReference]
                                       ,[ExchangeSalesOrderPartId]
                                       ,[ItemMasterId]
                                       ,[StockLineId]
                                       ,[StocklineNumber]
                                       ,[InvoiceId]
                                       ,[InvoiceNo]
									   ,[TypeId]
									   ,[DistSetupCode])
                                 VALUES
                                       (@CommonJournalBatchDetailId
									   ,@JournalBatchDetailId
                                       ,@JournalBatchHeaderId
                                       ,@ReferenceId
                                       ,@ExchangeSalesOrderNumber
									   ,@CustomerId
									   ,@CustRefNumber
									   ,@partId
									   ,@ItemmasterId
									   ,@StocklineId
									   ,@StocklineNumber
									   ,@InvoiceId
									   ,@InvoiceNo
									   ,1
									   ,'EX-INVPARTS');    
				    	 
						END
					    ---------------------------------------------------End ---------------------------------------------------

						FETCH NEXT FROM @ExchangeSalesOrderPartDetailsCursor1 INTO @PartGLAccountId
					END
					CLOSE @ExchangeSalesOrderPartDetailsCursor1  
					DEALLOCATE @ExchangeSalesOrderPartDetailsCursor1

					----GL Account wise COGS-Parts and Inventory-Parts Entry----
					SET @TotalDebit=0;
					SET @TotalCredit=0;
					SELECT @TotalDebit = SUM(ISNULL([DebitAmount],0)),
					       @TotalCredit = SUM(ISNULL([CreditAmount],0)) 
					FROM [dbo].[CommonBatchDetails] WITH(NOLOCK) 
					WHERE [JournalBatchDetailId] = @JournalBatchDetailId 
					GROUP BY [JournalBatchDetailId];

					UPDATE [dbo].[BatchDetails] 
					   SET [DebitAmount] = @TotalDebit,
					       [CreditAmount] = @TotalCredit,
						   [UpdatedDate] = GETUTCDATE(),
						   [UpdatedBy] = @UpdateBy 
					 WHERE [JournalBatchDetailId] = @JournalBatchDetailId;

					 SELECT @TotalDebit = SUM(ISNULL([DebitAmount],0)),
							@TotalCredit = SUM(ISNULL([CreditAmount],0)) 
					 FROM [dbo].[BatchDetails] WITH(NOLOCK) 
					 WHERE [JournalBatchHeaderId] = @JournalBatchHeaderId 
					   AND [IsDeleted] = 0 
					 GROUP BY [JournalBatchHeaderId]
			   	          
					SET @TotalBalance = (@TotalDebit - @TotalCredit)

					UPDATE [dbo].[CodePrefixes] 
					   SET [CurrentNummber] = @currentNo 
					 WHERE [CodeTypeId] = @CodeTypeId 
					   AND [MasterCompanyId] = @MasterCompanyId;    

					UPDATE [dbo].[BatchHeader]  
					   SET [TotalDebit] = @TotalDebit,
						   [TotalCredit] = @TotalCredit,
						   [TotalBalance] = @TotalBalance,
						   [UpdatedDate] = GETUTCDATE(),
						   [UpdatedBy] = @UpdateBy 
					 WHERE [JournalBatchHeaderId] = @JournalBatchHeaderId;

				END

			END			

			IF(UPPER(@DistributionCode) = UPPER('EX-FEEBILLING'))
			BEGIN				
				IF NOT EXISTS(SELECT 1 FROM [dbo].[ExchangeBatchDetails] EBD WITH(NOLOCK) WHERE EBD.[ExchangeSalesOrderId] = @ReferenceId AND EBD.[CustomerId] = @CustomerId AND EBD.[InvoiceId] = @InvoiceId)
				BEGIN

				SELECT @InvoiceNo = [InvoiceNo] FROM [dbo].[ExchangeSalesOrderBillingInvoicing] WITH(NOLOCK) WHERE [SOBillingInvoicingId] = @InvoiceId;

				IF EXISTS(SELECT 1 FROM [dbo].[DistributionSetup] WITH(NOLOCK) WHERE [DistributionMasterId] = @DistributionMasterId AND [MasterCompanyId] = @MasterCompanyId AND ISNULL(GlAccountId,0) = 0)
				BEGIN
					SET @ValidDistribution = 0;
				END
				IF(@ValidDistribution = 1)
				BEGIN
					DECLARE @TotalBillingAmount DECIMAL(18,2) = 0;
					DECLARE @TotalCogsAmount DECIMAL(18,2) = 0;
					DECLARE @MiscChargesCost DECIMAL(18,2) = 0;
					DECLARE @FreightCost DECIMAL(18,2) = 0;		
					DECLARE @TotalSalesTaxAmount DECIMAL(18,2) = 0;		
					DECLARE @TotalOtherTaxAmount DECIMAL(18,2) = 0;	
					DECLARE @TotalBilling DECIMAL(18,2) = 0;	
					DECLARE @TotalCreditBilling DECIMAL(18,2) = 0;	
					
					DECLARE @EXCHBillingTypeId INT = 0;
					DECLARE @ExchangeBillingStatusId INT = 0,@ChargesBillingTypeId INT = 0,@FreightBillingTypeId INT = 0
					DECLARE @BillInvoiceNo VARCHAR(100),@CogsInvoiceNo VARCHAR(100),@ChargesInvoiceNo VARCHAR(100),@FreightInvoiceNo VARCHAR(100)
					
					SELECT @EXCHBillingTypeId = [ExchangeBillingTypeId] FROM [dbo].[ExchangeBillingType] WITH(NOLOCK) WHERE UPPER([Description]) = UPPER('EXCH FEE');
				    SELECT @ChargesBillingTypeId = [ExchangeBillingTypeId] FROM [dbo].[ExchangeBillingType] WITH(NOLOCK) WHERE UPPER([Description]) = UPPER('CHARGES');
					SELECT @FreightBillingTypeId = [ExchangeBillingTypeId] FROM [dbo].[ExchangeBillingType] WITH(NOLOCK) WHERE UPPER([Description]) = UPPER('FREIGHT');
					
					SELECT @ExchangeBillingStatusId = [ExchangeBillingStatusId] FROM [dbo].[ExchangeBillingStatus] WITH(NOLOCK) WHERE UPPER([Name]) = UPPER('INVOICED');
					------------------------------------------Total Exchange Billing Amount------------------------------------------
					
					SELECT @TotalBillingAmount = ISNULL(ESOB.[GrandTotal],0),			       
						   @BillInvoiceNo = ESOB.[InvoiceNo]
					FROM [dbo].[ExchangeSalesOrderBillingInvoicing] ESOB WITH(NOLOCK) 
					INNER JOIN [dbo].[ExchangeSalesOrderScheduleBilling] ESOS  WITH(NOLOCK) ON ESOB.ExchangeSalesOrderId = ESOS.ExchangeSalesOrderId 					
					WHERE [SOBillingInvoicingId] = @InvoiceId 
					AND [BillingTypeId] = @EXCHBillingTypeId 
					AND [StatusId] = @ExchangeBillingStatusId;
					
					SELECT  @StocklineId = esop.[StockLineId],
					        @partId = esop.[ItemMasterId],
							@MPNName = itm.[partnumber]
					FROM [dbo].[ExchangeSalesOrderPart] esop WITH(NOLOCK) 
					 LEFT JOIN [dbo].[ItemMaster] itm WITH(NOLOCK) ON itm.[ItemMasterId] = esop.[ItemMasterId]					
					WHERE esop.ExchangeSalesOrderPartId = @ReferencePartId ;
										
					SELECT @LotId = SL.[LotId],
						   @LotNumber = LO.[LotNumber],						  
						   @StocklineNumber = SL.[StockLineNumber]
					  FROM [dbo].[Stockline] SL WITH(NOLOCK)					 
					  LEFT JOIN [dbo].[Lot] LO WITH(NOLOCK) ON LO.LotId = SL.LotId  
					  WHERE SL.[StockLineId] = @StocklineId;
					------------------------------------------Total Cogs Amount------------------------------------------							

					SELECT @TotalCogsAmount = (ISNULL(ESOB.[CogsAmount],0)),					       
						   @CogsInvoiceNo = ESOB.[InvoiceNo]
					FROM [dbo].[ExchangeSalesOrderBillingInvoicing] ESOB WITH(NOLOCK) 
					INNER JOIN [dbo].[ExchangeSalesOrderScheduleBilling] ESOS  WITH(NOLOCK) ON ESOB.ExchangeSalesOrderId = ESOS.ExchangeSalesOrderId 					
					WHERE [SOBillingInvoicingId] = @InvoiceId 
					--AND ESOS.[BillingTypeId] = @EXCHBillingTypeId 
					AND ESOS.[StatusId] = @ExchangeBillingStatusId
					
					------------------------------------------Total Charges Amount------------------------------------------							
				
					SELECT @MiscChargesCost = ISNULL(ESOB.[MiscCharges],0),
						   @ChargesInvoiceNo = ESOB.[InvoiceNo]
					FROM [dbo].[ExchangeSalesOrderBillingInvoicing] ESOB WITH(NOLOCK) 
					INNER JOIN [dbo].[ExchangeSalesOrderScheduleBilling] ESOS  WITH(NOLOCK) ON ESOB.ExchangeSalesOrderId = ESOS.ExchangeSalesOrderId 					
					WHERE [SOBillingInvoicingId] = @InvoiceId AND ESOS.[BillingTypeId] = @ChargesBillingTypeId AND ESOS.[StatusId] = @ExchangeBillingStatusId;

					------------------------------------------Total Freight Amount------------------------------------------							

					SELECT @FreightCost = ISNULL(ESOB.[Freight],0),
						   @FreightInvoiceNo = ESOB.[InvoiceNo]
					FROM [dbo].[ExchangeSalesOrderBillingInvoicing] ESOB WITH(NOLOCK) 
					INNER JOIN [dbo].[ExchangeSalesOrderScheduleBilling] ESOS  WITH(NOLOCK) ON ESOB.ExchangeSalesOrderId = ESOS.ExchangeSalesOrderId 					
					WHERE [SOBillingInvoicingId] = @InvoiceId AND ESOS.[BillingTypeId] = @FreightBillingTypeId AND ESOS.[StatusId] = @ExchangeBillingStatusId;

					------------------------------------------Total SALES TAX Amount------------------------------------------			
					
					SELECT @TotalSalesTaxAmount = ISNULL(ESOB.[SalesTax],0)
					FROM [dbo].[ExchangeSalesOrderBillingInvoicing] ESOB WITH(NOLOCK) 
					INNER JOIN [dbo].[ExchangeSalesOrderScheduleBilling] ESOS  WITH(NOLOCK) ON ESOB.ExchangeSalesOrderId = ESOS.ExchangeSalesOrderId 					
					WHERE [SOBillingInvoicingId] = @InvoiceId AND ESOS.[BillingTypeId] = @EXCHBillingTypeId AND ESOS.[StatusId] = @ExchangeBillingStatusId;

					------------------------------------------Total Other TAX Amount------------------------------------------	
					
					SELECT @TotalOtherTaxAmount = ISNULL(ESOB.[OtherTax],0)					       						
					FROM [dbo].[ExchangeSalesOrderBillingInvoicing] ESOB WITH(NOLOCK) 
					INNER JOIN [dbo].[ExchangeSalesOrderScheduleBilling] ESOS  WITH(NOLOCK) ON ESOB.ExchangeSalesOrderId = ESOS.ExchangeSalesOrderId 					
					WHERE [SOBillingInvoicingId] = @InvoiceId AND ESOS.[BillingTypeId] = @EXCHBillingTypeId AND ESOS.[StatusId] = @ExchangeBillingStatusId;
					
					--SET @TotalBilling = (@TotalBillingAmount + @MiscChargesCost + @FreightCost + @TotalSalesTaxAmount + @TotalOtherTaxAmount);
					SET @TotalBilling = (@TotalBillingAmount);
					SET @TotalCreditBilling = (@TotalBillingAmount - @MiscChargesCost - @FreightCost - @TotalSalesTaxAmount - @TotalOtherTaxAmount);

					IF(@TotalBillingAmount > 0)
					BEGIN
						IF NOT EXISTS(SELECT [JournalBatchHeaderId] FROM dbo.BatchHeader WITH(NOLOCK)  WHERE [JournalTypeId] = @JournalTypeId AND [MasterCompanyId] = @MasterCompanyId AND CAST(EntryDate AS DATE) = CAST(GETUTCDATE() AS DATE) AND [StatusId] = @StatusId AND [CustomerTypeId] = @CustomerTypeId)
						BEGIN
							IF NOT EXISTS(SELECT [JournalBatchHeaderId] FROM [dbo].[BatchHeader] WITH(NOLOCK))
							BEGIN
								SET @batch ='001'
								SET @Currentbatch='001'
							END
							ELSE
							BEGIN
								SELECT TOP 1 @Currentbatch = CASE WHEN [CurrentNumber] > 0 THEN CAST([CurrentNumber] AS BIGINT) + 1 
				   							                      ELSE  1 END 
				   					FROM [dbo].[BatchHeader] WITH(NOLOCK) ORDER BY [JournalBatchHeaderId] DESC 

								IF(CAST(@Currentbatch AS BIGINT) > 99)
								BEGIN
									SET @batch = CASE WHEN CAST(@Currentbatch AS BIGINT) > 99 THEN CAST(@Currentbatch AS VARCHAR(100))
				   							          ELSE CONCAT('00', CAST(@Currentbatch AS VARCHAR(50))) END 
								END
								ELSE IF(CAST(@Currentbatch AS BIGINT) > 9)
								BEGIN
									SET @batch = CASE WHEN CAST(@Currentbatch AS BIGINT) > 99 THEN CAST(@Currentbatch AS VARCHAR(100))
				   							          ELSE CONCAT('0', CAST(@Currentbatch AS VARCHAR(50))) END 
								END
								ELSE
								BEGIN
									SET @batch = CASE WHEN CAST(@Currentbatch AS BIGINT) > 99 THEN CAST(@Currentbatch AS VARCHAR(100))
				   							          ELSE CONCAT('00', CAST(@Currentbatch AS VARCHAR(50))) END 
								END			               
							END
														
							SET @CurrentNumber = CAST(@Currentbatch AS BIGINT) 

							SET @batch = CAST(@JournalTypeCode +' '+ CAST(@batch AS VARCHAR(100)) AS VARCHAR(100))	

							INSERT INTO [dbo].[BatchHeader]
							           ([BatchName],
									    [CurrentNumber],
										[EntryDate],
										[AccountingPeriod],
										[AccountingPeriodId],
										[StatusId],
										[StatusName],
										[JournalTypeId],
										[JournalTypeName],
										[TotalDebit],
										[TotalCredit],
										[TotalBalance],
										[MasterCompanyId],
										[CreatedBy],
										[UpdatedBy],
										[CreatedDate],
										[UpdatedDate],
										[IsActive],
										[IsDeleted],
										[Module],
										[CustomerTypeId])
							      VALUES(@batch,
								         @CurrentNumber,
										 GETUTCDATE(),
										 @AccountingPeriod,
										 @AccountingPeriodId,
										 @StatusId,
										 @StatusName,
										 @JournalTypeId,
										 @JournalTypename,
										 @Amount,
										 @Amount,
										 0,
										 @MasterCompanyId,
										 @UpdateBy,
										 @UpdateBy,
										 GETUTCDATE(),
										 GETUTCDATE(),
										 1,
										 0,
										 'EXFB',
										 @CustomerTypeId);
            	          
							SELECT @JournalBatchHeaderId = SCOPE_IDENTITY();

							UPDATE [dbo].[BatchHeader] 
							   SET [CurrentNumber] = @CurrentNumber 
							 WHERE [JournalBatchHeaderId] = @JournalBatchHeaderId;		
						END
						ELSE 
						BEGIN
							SELECT @JournalBatchHeaderId = JournalBatchHeaderId,
							       @CurrentPeriodId = ISNULL(AccountingPeriodId,0) 
							 FROM [dbo].[BatchHeader] WITH(NOLOCK)  
							 WHERE [JournalTypeId] = @JournalTypeId AND 
							       [StatusId] = @StatusId AND 
								   [CustomerTypeId] = @CustomerTypeId;

							SELECT @LineNumber = CASE WHEN [LineNumber] > 0 THEN CAST([LineNumber] AS BIGINT) + 1 ELSE  1 END 
				   			  FROM [dbo].[BatchDetails] WITH(NOLOCK) 
							  WHERE [JournalBatchHeaderId] = @JournalBatchHeaderId  ORDER BY [JournalBatchDetailId] DESC 
				    
							IF(@CurrentPeriodId = 0)
							BEGIN
								UPDATE [dbo].[BatchHeader] 
								   SET [AccountingPeriodId] = @AccountingPeriodId,
								       [AccountingPeriod]= @AccountingPeriod   
								 WHERE [JournalBatchHeaderId] = @JournalBatchHeaderId
							END
						END						

						INSERT INTO [dbo].[BatchDetails]
						           ([JournalTypeNumber],
								    [CurrentNumber],
									[DistributionSetupId], 
									[DistributionName], 
									[JournalBatchHeaderId], 
									[LineNumber], 
									[GlAccountId], 
									[GlAccountNumber], 
									[GlAccountName], 
									[TransactionDate], 
									[EntryDate], 
									[JournalTypeId], 
									[JournalTypeName], 
						            [IsDebit], 
									[DebitAmount], 
									[CreditAmount], 
									[ManagementStructureId], 
									[ModuleName], 
									[LastMSLevel], 
									[AllMSlevels], 
									[MasterCompanyId], 
									[CreatedBy], 
									[UpdatedBy], 
									[CreatedDate], 
									[UpdatedDate], 
									[IsActive], 
									[IsDeleted],
									[AccountingPeriodId],
									[AccountingPeriod])
							 VALUES(@JournalTypeNumber,
							        @currentNo,
									0, 
									NULL, 
									@JournalBatchHeaderId, 
									1, 
									0, 
									NULL, 
									NULL,
									GETUTCDATE(), 
									GETUTCDATE(), 
									@JournalTypeId, 
									@JournalTypename, 
							        1, 
									0, 
									0, 
									0, 
									@ModuleName, 
									NULL, 
									NULL, 
									@MasterCompanyId, 
									@UpdateBy, 
									@UpdateBy, 
									GETUTCDATE(), 
									GETUTCDATE(), 
									1, 
									0,
									@AccountingPeriodId,
									@AccountingPeriod)
						
						SET @JournalBatchDetailId = SCOPE_IDENTITY();

						SELECT TOP 1 @DistributionSetupId = [ID],
									 @DistributionName = [Name],
									 @JournalTypeId = [JournalTypeId],
									 @GlAccountId = [GlAccountId],
									 @GlAccountNumber = [GlAccountNumber],
									 @GlAccountName = [GlAccountName],
									 @CrDrType = [CRDRType]
								FROM [dbo].[DistributionSetup] WITH(NOLOCK) 
							   WHERE UPPER([DistributionSetupCode]) = UPPER('EX-FBACCRECTRADE') 
								 AND [DistributionMasterId] = @DistributionMasterId 
								 AND [MasterCompanyId] = @MasterCompanyId;

						INSERT INTO [dbo].[CommonBatchDetails]
									   ([JournalBatchDetailId],
									    [JournalTypeNumber],
										[CurrentNumber],
										[DistributionSetupId],
										[DistributionName],
										[JournalBatchHeaderId],
										[LineNumber],
										[GlAccountId],
										[GlAccountNumber],
										[GlAccountName],
										[TransactionDate],
										[EntryDate],
										[JournalTypeId],
										[JournalTypeName],
								        [IsDebit],
										[DebitAmount],
										[CreditAmount],
										[ManagementStructureId],
										[ModuleName],
										[LastMSLevel],
										[AllMSlevels],
										[MasterCompanyId],
										[CreatedBy],
										[UpdatedBy],
										[CreatedDate],
										[UpdatedDate],
										[IsActive],
										[IsDeleted],
										[LotId],
										[LotNumber]
										)
							     VALUES
								       (@JournalBatchDetailId,
									    @JournalTypeNumber,
										@currentNo,
										@DistributionSetupId,
										@DistributionName,
										@JournalBatchHeaderId,
										1,
										@GlAccountId,
										@GlAccountNumber,
										@GlAccountName,
										GETUTCDATE(),
										GETUTCDATE(),
										@JournalTypeId,
										@JournalTypename,
								        CASE WHEN @CrDrType = 1 THEN 1 ELSE 0 END,
								        CASE WHEN @CrDrType = 1 THEN @TotalBilling ELSE 0 END,
								        CASE WHEN @CrDrType = 1 THEN 0 ELSE @TotalBilling END,
								        @ManagementStructureId,
										@ModuleName,
										@LastMSLevel,
										@AllMSlevels,
										@MasterCompanyId,
										@UpdateBy,
										@UpdateBy,
										GETUTCDATE(),
										GETUTCDATE(),
										1,
										0,
										@LotId,
										@LotNumber);

						SET @CommonJournalBatchDetailId = SCOPE_IDENTITY();

						-----  Accounting MS Entry  -----

						EXEC [dbo].[PROCAddUpdateAccountingBatchMSData] @CommonJournalBatchDetailId,@ManagementStructureId,@MasterCompanyId,@UpdateBy,@AccountMSModuleId,1; 

						INSERT INTO [dbo].[ExchangeBatchDetails]
                                       ([CommonJournalBatchDetailId]
                                       ,[JournalBatchDetailId]
                                       ,[JournalBatchHeaderId]
                                       ,[ExchangeSalesOrderId]
                                       ,[ExchangeSalesOrderNumber]
                                       ,[CustomerId]
                                       ,[CustomerReference]
                                       ,[ExchangeSalesOrderPartId]
                                       ,[ItemMasterId]
                                       ,[StockLineId]
                                       ,[StocklineNumber]
                                       ,[InvoiceId]
                                       ,[InvoiceNo]
									   ,[TypeId]
									   ,[DistSetupCode])
                                 VALUES
                                       (@CommonJournalBatchDetailId
									   ,@JournalBatchDetailId
                                       ,@JournalBatchHeaderId
                                       ,@ReferenceId
                                       ,@ExchangeSalesOrderNumber
									   ,@CustomerId
									   ,@CustRefNumber
									   ,@partId
									   ,@ItemmasterId
									   ,@StocklineId
									   ,@StocklineNumber
									   ,@InvoiceId
									   ,@BillInvoiceNo
									   ,2
									   ,'EX-FBACCRECTRADE'); 

					END
					IF(@TotalCogsAmount > 0)
					BEGIN
						SELECT TOP 1 @DistributionSetupId = [ID], @DistributionName = [Name], @JournalTypeId = [JournalTypeId], @GlAccountId = [GlAccountId], 
						             @GlAccountNumber = [GlAccountNumber], @GlAccountName = [GlAccountName], @CrDrType = [CRDRType]
								FROM [dbo].[DistributionSetup] WITH(NOLOCK) 
							   WHERE UPPER([DistributionSetupCode]) = UPPER('EX-FBCOGSPARTS') 
								 AND [DistributionMasterId] = @DistributionMasterId 
								 AND [MasterCompanyId] = @MasterCompanyId;

						INSERT INTO [dbo].[CommonBatchDetails]
									   ([JournalBatchDetailId],
									    [JournalTypeNumber],
										[CurrentNumber],
										[DistributionSetupId],
										[DistributionName],
										[JournalBatchHeaderId],
										[LineNumber],
										[GlAccountId],
										[GlAccountNumber],
										[GlAccountName],
										[TransactionDate],
										[EntryDate],
										[JournalTypeId],
										[JournalTypeName],
								        [IsDebit],
										[DebitAmount],
										[CreditAmount],
										[ManagementStructureId],
										[ModuleName],
										[LastMSLevel],
										[AllMSlevels],
										[MasterCompanyId],
										[CreatedBy],
										[UpdatedBy],
										[CreatedDate],
										[UpdatedDate],
										[IsActive],
										[IsDeleted],
										[LotId],
										[LotNumber])
							     VALUES
								       (@JournalBatchDetailId,
									    @JournalTypeNumber,
										@currentNo,
										@DistributionSetupId,
										@DistributionName,
										@JournalBatchHeaderId,
										1,
										@GlAccountId,
										@GlAccountNumber,
										@GlAccountName,
										GETUTCDATE(),
										GETUTCDATE(),
										@JournalTypeId,
										@JournalTypename,
								        CASE WHEN @CrDrType = 1 THEN 1 ELSE 0 END,
								        CASE WHEN @CrDrType = 1 THEN @TotalCogsAmount ELSE 0 END,
								        CASE WHEN @CrDrType = 1 THEN 0 ELSE @TotalCogsAmount END,
								        @ManagementStructureId,
										@ModuleName,
										@LastMSLevel,
										@AllMSlevels,
										@MasterCompanyId,
										@UpdateBy,
										@UpdateBy,
										GETUTCDATE(),
										GETUTCDATE(),
										1,
										0,
										@LotId,
										@LotNumber);

						SET @CommonJournalBatchDetailId = SCOPE_IDENTITY();

						-----  Accounting MS Entry  -----

						EXEC [dbo].[PROCAddUpdateAccountingBatchMSData] @CommonJournalBatchDetailId,@ManagementStructureId,@MasterCompanyId,@UpdateBy,@AccountMSModuleId,1; 

						INSERT INTO [dbo].[ExchangeBatchDetails]
                                       ([CommonJournalBatchDetailId]
                                       ,[JournalBatchDetailId]
                                       ,[JournalBatchHeaderId]
                                       ,[ExchangeSalesOrderId]
                                       ,[ExchangeSalesOrderNumber]
                                       ,[CustomerId]
                                       ,[CustomerReference]
                                       ,[ExchangeSalesOrderPartId]
                                       ,[ItemMasterId]
                                       ,[StockLineId]
                                       ,[StocklineNumber]
                                       ,[InvoiceId]
                                       ,[InvoiceNo]
									   ,[TypeId]
									   ,[DistSetupCode])
                                 VALUES
                                       (@CommonJournalBatchDetailId
									   ,@JournalBatchDetailId
                                       ,@JournalBatchHeaderId
                                       ,@ReferenceId
                                       ,@ExchangeSalesOrderNumber
									   ,@CustomerId
									   ,@CustRefNumber
									   ,@partId
									   ,@ItemmasterId
									   ,@StocklineId
									   ,@StocklineNumber
									   ,@InvoiceId
									   ,@CogsInvoiceNo
									   ,2
									   ,'EX-FBCOGSPARTS'); 
					END
					IF(@TotalCreditBilling > 0)
					BEGIN
						SELECT TOP 1 @DistributionSetupId = [ID],
									 @DistributionName = [Name],
									 @JournalTypeId = [JournalTypeId],
									 @GlAccountId = [GlAccountId],
									 @GlAccountNumber = [GlAccountNumber],
									 @GlAccountName = [GlAccountName],
									 @CrDrType = [CRDRType]
								FROM [dbo].[DistributionSetup] WITH(NOLOCK) 
							   WHERE UPPER([DistributionSetupCode]) = UPPER('EX-FBREVENUE') 
								 AND [DistributionMasterId] = @DistributionMasterId 
								 AND [MasterCompanyId] = @MasterCompanyId;

						INSERT INTO [dbo].[CommonBatchDetails]
									   ([JournalBatchDetailId],
									    [JournalTypeNumber],
										[CurrentNumber],
										[DistributionSetupId],
										[DistributionName],
										[JournalBatchHeaderId],
										[LineNumber],
										[GlAccountId],
										[GlAccountNumber],
										[GlAccountName],
										[TransactionDate],
										[EntryDate],
										[JournalTypeId],
										[JournalTypeName],
								        [IsDebit],
										[DebitAmount],
										[CreditAmount],
										[ManagementStructureId],
										[ModuleName],
										[LastMSLevel],
										[AllMSlevels],
										[MasterCompanyId],
										[CreatedBy],
										[UpdatedBy],
										[CreatedDate],
										[UpdatedDate],
										[IsActive],
										[IsDeleted],
										[LotId],
										[LotNumber])
							     VALUES
								       (@JournalBatchDetailId,
									    @JournalTypeNumber,
										@currentNo,
										@DistributionSetupId,
										@DistributionName,
										@JournalBatchHeaderId,
										1,
										@GlAccountId,
										@GlAccountNumber,
										@GlAccountName,
										GETUTCDATE(),
										GETUTCDATE(),
										@JournalTypeId,
										@JournalTypename,
								        CASE WHEN @CrDrType = 1 THEN 1 ELSE 0 END,
								        CASE WHEN @CrDrType = 1 THEN @TotalCreditBilling ELSE 0 END,
								        CASE WHEN @CrDrType = 1 THEN 0 ELSE @TotalCreditBilling END,
								        @ManagementStructureId,
										@ModuleName,
										@LastMSLevel,
										@AllMSlevels,
										@MasterCompanyId,
										@UpdateBy,
										@UpdateBy,
										GETUTCDATE(),
										GETUTCDATE(),
										1,
										0,
										@LotId,
										@LotNumber)

						SET @CommonJournalBatchDetailId = SCOPE_IDENTITY();

						-----  Accounting MS Entry  -----

						EXEC [dbo].[PROCAddUpdateAccountingBatchMSData] @CommonJournalBatchDetailId,@ManagementStructureId,@MasterCompanyId,@UpdateBy,@AccountMSModuleId,1; 

						INSERT INTO [dbo].[ExchangeBatchDetails]
                                       ([CommonJournalBatchDetailId]
                                       ,[JournalBatchDetailId]
                                       ,[JournalBatchHeaderId]
                                       ,[ExchangeSalesOrderId]
                                       ,[ExchangeSalesOrderNumber]
                                       ,[CustomerId]
                                       ,[CustomerReference]
                                       ,[ExchangeSalesOrderPartId]
                                       ,[ItemMasterId]
                                       ,[StockLineId]
                                       ,[StocklineNumber]
                                       ,[InvoiceId]
                                       ,[InvoiceNo]
									   ,[TypeId]
									   ,[DistSetupCode])
                                 VALUES
                                       (@CommonJournalBatchDetailId
									   ,@JournalBatchDetailId
                                       ,@JournalBatchHeaderId
                                       ,@ReferenceId
                                       ,@ExchangeSalesOrderNumber
									   ,@CustomerId
									   ,@CustRefNumber
									   ,@partId
									   ,@ItemmasterId
									   ,@StocklineId
									   ,@StocklineNumber
									   ,@InvoiceId
									   ,@BillInvoiceNo
									   ,2
									   ,'EX-FBREVENUE'); 

					END
					IF(@MiscChargesCost > 0)
					BEGIN
						SELECT TOP 1 @DistributionSetupId = [ID],
									 @DistributionName = [Name],
									 @JournalTypeId = [JournalTypeId],
									 @GlAccountId = [GlAccountId],
									 @GlAccountNumber = [GlAccountNumber],
									 @GlAccountName = [GlAccountName],
									 @CrDrType = [CRDRType]
								FROM [dbo].[DistributionSetup] WITH(NOLOCK) 
							   WHERE UPPER([DistributionSetupCode]) = UPPER('EX-FBMISCCHARGE') 
								 AND [DistributionMasterId] = @DistributionMasterId 
								 AND [MasterCompanyId] = @MasterCompanyId;

						INSERT INTO [dbo].[CommonBatchDetails]
									   ([JournalBatchDetailId],
									    [JournalTypeNumber],
										[CurrentNumber],
										[DistributionSetupId],
										[DistributionName],
										[JournalBatchHeaderId],
										[LineNumber],
										[GlAccountId],
										[GlAccountNumber],
										[GlAccountName],
										[TransactionDate],
										[EntryDate],
										[JournalTypeId],
										[JournalTypeName],
								        [IsDebit],
										[DebitAmount],
										[CreditAmount],
										[ManagementStructureId],
										[ModuleName],
										[LastMSLevel],
										[AllMSlevels],
										[MasterCompanyId],
										[CreatedBy],
										[UpdatedBy],
										[CreatedDate],
										[UpdatedDate],
										[IsActive],
										[IsDeleted],
										[LotId],
										[LotNumber])
							     VALUES
								       (@JournalBatchDetailId,
									    @JournalTypeNumber,
										@currentNo,
										@DistributionSetupId,
										@DistributionName,
										@JournalBatchHeaderId,
										1,
										@GlAccountId,
										@GlAccountNumber,
										@GlAccountName,
										GETUTCDATE(),
										GETUTCDATE(),
										@JournalTypeId,
										@JournalTypename,
								        CASE WHEN @CrDrType = 1 THEN 1 ELSE 0 END,
								        CASE WHEN @CrDrType = 1 THEN @MiscChargesCost ELSE 0 END,
								        CASE WHEN @CrDrType = 1 THEN 0 ELSE @MiscChargesCost END,
								        @ManagementStructureId,
										@ModuleName,
										@LastMSLevel,
										@AllMSlevels,
										@MasterCompanyId,
										@UpdateBy,
										@UpdateBy,
										GETUTCDATE(),
										GETUTCDATE(),
										1,
										0,
										@LotId,
										@LotNumber)

						SET @CommonJournalBatchDetailId = SCOPE_IDENTITY();

						-----  Accounting MS Entry  -----

						EXEC [dbo].[PROCAddUpdateAccountingBatchMSData] @CommonJournalBatchDetailId,@ManagementStructureId,@MasterCompanyId,@UpdateBy,@AccountMSModuleId,1; 

						INSERT INTO [dbo].[ExchangeBatchDetails]
                                       ([CommonJournalBatchDetailId]
                                       ,[JournalBatchDetailId]
                                       ,[JournalBatchHeaderId]
                                       ,[ExchangeSalesOrderId]
                                       ,[ExchangeSalesOrderNumber]
                                       ,[CustomerId]
                                       ,[CustomerReference]
                                       ,[ExchangeSalesOrderPartId]
                                       ,[ItemMasterId]
                                       ,[StockLineId]
                                       ,[StocklineNumber]
                                       ,[InvoiceId]
                                       ,[InvoiceNo]
									   ,[TypeId]
									   ,[DistSetupCode])
                                 VALUES
                                       (@CommonJournalBatchDetailId
									   ,@JournalBatchDetailId
                                       ,@JournalBatchHeaderId
                                       ,@ReferenceId
                                       ,@ExchangeSalesOrderNumber
									   ,@CustomerId
									   ,@CustRefNumber
									   ,@partId
									   ,@ItemmasterId
									   ,@StocklineId
									   ,@StocklineNumber
									   ,@InvoiceId
									   ,@ChargesInvoiceNo
									   ,2
									   ,'EX-FBMISCCHARGE');

					END
					IF(@FreightCost > 0)
					BEGIN
						SELECT TOP 1 @DistributionSetupId = [ID],
									 @DistributionName = [Name],
									 @JournalTypeId = [JournalTypeId],
									 @GlAccountId = [GlAccountId],
									 @GlAccountNumber = [GlAccountNumber],
									 @GlAccountName = [GlAccountName],
									 @CrDrType = [CRDRType]
								FROM [dbo].[DistributionSetup] WITH(NOLOCK) 
							   WHERE UPPER([DistributionSetupCode]) = UPPER('EX-FBREVENUEFREIGHT') 
								 AND [DistributionMasterId] = @DistributionMasterId 
								 AND [MasterCompanyId] = @MasterCompanyId;

						INSERT INTO [dbo].[CommonBatchDetails]
									   ([JournalBatchDetailId],
									    [JournalTypeNumber],
										[CurrentNumber],
										[DistributionSetupId],
										[DistributionName],
										[JournalBatchHeaderId],
										[LineNumber],
										[GlAccountId],
										[GlAccountNumber],
										[GlAccountName],
										[TransactionDate],
										[EntryDate],
										[JournalTypeId],
										[JournalTypeName],
								        [IsDebit],
										[DebitAmount],
										[CreditAmount],
										[ManagementStructureId],
										[ModuleName],
										[LastMSLevel],
										[AllMSlevels],
										[MasterCompanyId],
										[CreatedBy],
										[UpdatedBy],
										[CreatedDate],
										[UpdatedDate],
										[IsActive],
										[IsDeleted],
										[LotId],
										[LotNumber])
							     VALUES
								       (@JournalBatchDetailId,
									    @JournalTypeNumber,
										@currentNo,
										@DistributionSetupId,
										@DistributionName,
										@JournalBatchHeaderId,
										1,
										@GlAccountId,
										@GlAccountNumber,
										@GlAccountName,
										GETUTCDATE(),
										GETUTCDATE(),
										@JournalTypeId,
										@JournalTypename,
								        CASE WHEN @CrDrType = 1 THEN 1 ELSE 0 END,
								        CASE WHEN @CrDrType = 1 THEN @FreightCost ELSE 0 END,
								        CASE WHEN @CrDrType = 1 THEN 0 ELSE @FreightCost END,
								        @ManagementStructureId,
										@ModuleName,
										@LastMSLevel,
										@AllMSlevels,
										@MasterCompanyId,
										@UpdateBy,
										@UpdateBy,
										GETUTCDATE(),
										GETUTCDATE(),
										1,
										0,
										@LotId,
										@LotNumber)

						SET @CommonJournalBatchDetailId = SCOPE_IDENTITY();

						-----  Accounting MS Entry  -----

						EXEC [dbo].[PROCAddUpdateAccountingBatchMSData] @CommonJournalBatchDetailId,@ManagementStructureId,@MasterCompanyId,@UpdateBy,@AccountMSModuleId,1; 

						INSERT INTO [dbo].[ExchangeBatchDetails]
                                       ([CommonJournalBatchDetailId]
                                       ,[JournalBatchDetailId]
                                       ,[JournalBatchHeaderId]
                                       ,[ExchangeSalesOrderId]
                                       ,[ExchangeSalesOrderNumber]
                                       ,[CustomerId]
                                       ,[CustomerReference]
                                       ,[ExchangeSalesOrderPartId]
                                       ,[ItemMasterId]
                                       ,[StockLineId]
                                       ,[StocklineNumber]
                                       ,[InvoiceId]
                                       ,[InvoiceNo]
									   ,[TypeId]
									   ,[DistSetupCode])
                                 VALUES
                                       (@CommonJournalBatchDetailId
									   ,@JournalBatchDetailId
                                       ,@JournalBatchHeaderId
                                       ,@ReferenceId
                                       ,@ExchangeSalesOrderNumber
									   ,@CustomerId
									   ,@CustRefNumber
									   ,@partId
									   ,@ItemmasterId
									   ,@StocklineId
									   ,@StocklineNumber
									   ,@InvoiceId
									   ,@FreightInvoiceNo
									   ,2
									   ,'EX-FBREVENUEFREIGHT');

					END
					IF(@TotalCogsAmount > 0)
					BEGIN
						SELECT TOP 1 @DistributionSetupId = [ID], @DistributionName = [Name], @JournalTypeId = [JournalTypeId], @GlAccountId = [GlAccountId], 
						             @GlAccountNumber = [GlAccountNumber], @GlAccountName = [GlAccountName], @CrDrType = [CRDRType]
								FROM [dbo].[DistributionSetup] WITH(NOLOCK) 
							   WHERE UPPER([DistributionSetupCode]) = UPPER('EX-FBINVAGM') 
								 AND [DistributionMasterId] = @DistributionMasterId 
								 AND [MasterCompanyId] = @MasterCompanyId;

						INSERT INTO [dbo].[CommonBatchDetails]
									   ([JournalBatchDetailId],
									    [JournalTypeNumber],
										[CurrentNumber],
										[DistributionSetupId],
										[DistributionName],
										[JournalBatchHeaderId],
										[LineNumber],
										[GlAccountId],
										[GlAccountNumber],
										[GlAccountName],
										[TransactionDate],
										[EntryDate],
										[JournalTypeId],
										[JournalTypeName],
								        [IsDebit],
										[DebitAmount],
										[CreditAmount],
										[ManagementStructureId],
										[ModuleName],
										[LastMSLevel],
										[AllMSlevels],
										[MasterCompanyId],
										[CreatedBy],
										[UpdatedBy],
										[CreatedDate],
										[UpdatedDate],
										[IsActive],
										[IsDeleted],
										[LotId],
										[LotNumber])
							     VALUES
								       (@JournalBatchDetailId,
									    @JournalTypeNumber,
										@currentNo,
										@DistributionSetupId,
										@DistributionName,
										@JournalBatchHeaderId,
										1,
										@GlAccountId,
										@GlAccountNumber,
										@GlAccountName,
										GETUTCDATE(),
										GETUTCDATE(),
										@JournalTypeId,
										@JournalTypename,
								        CASE WHEN @CrDrType = 1 THEN 1 ELSE 0 END,
								        CASE WHEN @CrDrType = 1 THEN @TotalCogsAmount ELSE 0 END,
								        CASE WHEN @CrDrType = 1 THEN 0 ELSE @TotalCogsAmount END,
								        @ManagementStructureId,
										@ModuleName,
										@LastMSLevel,
										@AllMSlevels,
										@MasterCompanyId,
										@UpdateBy,
										@UpdateBy,
										GETUTCDATE(),
										GETUTCDATE(),
										1,
										0,
										@LotId,
										@LotNumber)

						SET @CommonJournalBatchDetailId = SCOPE_IDENTITY();

						-----  Accounting MS Entry  -----

						EXEC [dbo].[PROCAddUpdateAccountingBatchMSData] @CommonJournalBatchDetailId,@ManagementStructureId,@MasterCompanyId,@UpdateBy,@AccountMSModuleId,1; 

						INSERT INTO [dbo].[ExchangeBatchDetails]
                                       ([CommonJournalBatchDetailId]
                                       ,[JournalBatchDetailId]
                                       ,[JournalBatchHeaderId]
                                       ,[ExchangeSalesOrderId]
                                       ,[ExchangeSalesOrderNumber]
                                       ,[CustomerId]
                                       ,[CustomerReference]
                                       ,[ExchangeSalesOrderPartId]
                                       ,[ItemMasterId]
                                       ,[StockLineId]
                                       ,[StocklineNumber]
                                       ,[InvoiceId]
                                       ,[InvoiceNo]
									   ,[TypeId]
									   ,[DistSetupCode])
                                 VALUES
                                       (@CommonJournalBatchDetailId
									   ,@JournalBatchDetailId
                                       ,@JournalBatchHeaderId
                                       ,@ReferenceId
                                       ,@ExchangeSalesOrderNumber
									   ,@CustomerId
									   ,@CustRefNumber
									   ,@partId
									   ,@ItemmasterId
									   ,@StocklineId
									   ,@StocklineNumber
									   ,@InvoiceId
									   ,@CogsInvoiceNo
									   ,2
									   ,'EX-FBINVAGM');
					END
					IF(@TotalSalesTaxAmount > 0)
					BEGIN
						SELECT TOP 1 @DistributionSetupId = [ID],
									 @DistributionName = [Name],
									 @JournalTypeId = [JournalTypeId],
									 @GlAccountId = [GlAccountId],
									 @GlAccountNumber = [GlAccountNumber],
									 @GlAccountName = [GlAccountName],
									 @CrDrType = [CRDRType]
								FROM [dbo].[DistributionSetup] WITH(NOLOCK) 
							   WHERE UPPER([DistributionSetupCode]) = UPPER('EX-FBSTP') 
								 AND [DistributionMasterId] = @DistributionMasterId 
								 AND [MasterCompanyId] = @MasterCompanyId;

						INSERT INTO [dbo].[CommonBatchDetails]
									   ([JournalBatchDetailId],
									    [JournalTypeNumber],
										[CurrentNumber],
										[DistributionSetupId],
										[DistributionName],
										[JournalBatchHeaderId],
										[LineNumber],
										[GlAccountId],
										[GlAccountNumber],
										[GlAccountName],
										[TransactionDate],
										[EntryDate],
										[JournalTypeId],
										[JournalTypeName],
								        [IsDebit],
										[DebitAmount],
										[CreditAmount],
										[ManagementStructureId],
										[ModuleName],
										[LastMSLevel],
										[AllMSlevels],
										[MasterCompanyId],
										[CreatedBy],
										[UpdatedBy],
										[CreatedDate],
										[UpdatedDate],
										[IsActive],
										[IsDeleted],
										[LotId],
										[LotNumber])
							     VALUES
								       (@JournalBatchDetailId,
									    @JournalTypeNumber,
										@currentNo,
										@DistributionSetupId,
										@DistributionName,
										@JournalBatchHeaderId,
										1,
										@GlAccountId,
										@GlAccountNumber,
										@GlAccountName,
										GETUTCDATE(),
										GETUTCDATE(),
										@JournalTypeId,
										@JournalTypename,
								        CASE WHEN @CrDrType = 1 THEN 1 ELSE 0 END,
								        CASE WHEN @CrDrType = 1 THEN @TotalSalesTaxAmount ELSE 0 END,
								        CASE WHEN @CrDrType = 1 THEN 0 ELSE @TotalSalesTaxAmount END,
								        @ManagementStructureId,
										@ModuleName,
										@LastMSLevel,
										@AllMSlevels,
										@MasterCompanyId,
										@UpdateBy,
										@UpdateBy,
										GETUTCDATE(),
										GETUTCDATE(),
										1,
										0,
										@LotId,
										@LotNumber)


						SET @CommonJournalBatchDetailId = SCOPE_IDENTITY();

						-----  Accounting MS Entry  -----

						EXEC [dbo].[PROCAddUpdateAccountingBatchMSData] @CommonJournalBatchDetailId,@ManagementStructureId,@MasterCompanyId,@UpdateBy,@AccountMSModuleId,1; 

						INSERT INTO [dbo].[ExchangeBatchDetails]
                                       ([CommonJournalBatchDetailId]
                                       ,[JournalBatchDetailId]
                                       ,[JournalBatchHeaderId]
                                       ,[ExchangeSalesOrderId]
                                       ,[ExchangeSalesOrderNumber]
                                       ,[CustomerId]
                                       ,[CustomerReference]
                                       ,[ExchangeSalesOrderPartId]
                                       ,[ItemMasterId]
                                       ,[StockLineId]
                                       ,[StocklineNumber]
                                       ,[InvoiceId]
                                       ,[InvoiceNo]
									   ,[TypeId]
									   ,[DistSetupCode])
                                 VALUES
                                       (@CommonJournalBatchDetailId
									   ,@JournalBatchDetailId
                                       ,@JournalBatchHeaderId
                                       ,@ReferenceId
                                       ,@ExchangeSalesOrderNumber
									   ,@CustomerId
									   ,@CustRefNumber
									   ,@partId
									   ,@ItemmasterId
									   ,@StocklineId
									   ,@StocklineNumber
									   ,@InvoiceId
									   ,@BillInvoiceNo
									   ,2
									   ,'EX-FBSTP');

					END
					IF(@TotalOtherTaxAmount > 0)
					BEGIN
						SELECT TOP 1 @DistributionSetupId = [ID],
									 @DistributionName = [Name],
									 @JournalTypeId = [JournalTypeId],
									 @GlAccountId = [GlAccountId],
									 @GlAccountNumber = [GlAccountNumber],
									 @GlAccountName = [GlAccountName],
									 @CrDrType = [CRDRType]
								FROM [dbo].[DistributionSetup] WITH(NOLOCK) 
							   WHERE UPPER([DistributionSetupCode]) = UPPER('EX-FBTPO') 
								 AND [DistributionMasterId] = @DistributionMasterId 
								 AND [MasterCompanyId] = @MasterCompanyId;

						INSERT INTO [dbo].[CommonBatchDetails]
									   ([JournalBatchDetailId],
									    [JournalTypeNumber],
										[CurrentNumber],
										[DistributionSetupId],
										[DistributionName],
										[JournalBatchHeaderId],
										[LineNumber],
										[GlAccountId],
										[GlAccountNumber],
										[GlAccountName],
										[TransactionDate],
										[EntryDate],
										[JournalTypeId],
										[JournalTypeName],
								        [IsDebit],
										[DebitAmount],
										[CreditAmount],
										[ManagementStructureId],
										[ModuleName],
										[LastMSLevel],
										[AllMSlevels],
										[MasterCompanyId],
										[CreatedBy],
										[UpdatedBy],
										[CreatedDate],
										[UpdatedDate],
										[IsActive],
										[IsDeleted],
										[LotId],
										[LotNumber])
							     VALUES
								       (@JournalBatchDetailId,
									    @JournalTypeNumber,
										@currentNo,
										@DistributionSetupId,
										@DistributionName,
										@JournalBatchHeaderId,
										1,
										@GlAccountId,
										@GlAccountNumber,
										@GlAccountName,
										GETUTCDATE(),
										GETUTCDATE(),
										@JournalTypeId,
										@JournalTypename,
								        CASE WHEN @CrDrType = 1 THEN 1 ELSE 0 END,
								        CASE WHEN @CrDrType = 1 THEN @TotalOtherTaxAmount ELSE 0 END,
								        CASE WHEN @CrDrType = 1 THEN 0 ELSE @TotalOtherTaxAmount END,
								        @ManagementStructureId,
										@ModuleName,
										@LastMSLevel,
										@AllMSlevels,
										@MasterCompanyId,
										@UpdateBy,
										@UpdateBy,
										GETUTCDATE(),
										GETUTCDATE(),
										1,
										0,
										@LotId,
										@LotNumber)

						SET @CommonJournalBatchDetailId = SCOPE_IDENTITY();

						-----  Accounting MS Entry  -----

						EXEC [dbo].[PROCAddUpdateAccountingBatchMSData] @CommonJournalBatchDetailId,@ManagementStructureId,@MasterCompanyId,@UpdateBy,@AccountMSModuleId,1; 

						INSERT INTO [dbo].[ExchangeBatchDetails]
                                       ([CommonJournalBatchDetailId]
                                       ,[JournalBatchDetailId]
                                       ,[JournalBatchHeaderId]
                                       ,[ExchangeSalesOrderId]
                                       ,[ExchangeSalesOrderNumber]
                                       ,[CustomerId]
                                       ,[CustomerReference]
                                       ,[ExchangeSalesOrderPartId]
                                       ,[ItemMasterId]
                                       ,[StockLineId]
                                       ,[StocklineNumber]
                                       ,[InvoiceId]
                                       ,[InvoiceNo]
									   ,[TypeId]
									   ,[DistSetupCode])
                                 VALUES
                                       (@CommonJournalBatchDetailId
									   ,@JournalBatchDetailId
                                       ,@JournalBatchHeaderId
                                       ,@ReferenceId
                                       ,@ExchangeSalesOrderNumber
									   ,@CustomerId
									   ,@CustRefNumber
									   ,@partId
									   ,@ItemmasterId
									   ,@StocklineId
									   ,@StocklineNumber
									   ,@InvoiceId
									   ,@BillInvoiceNo
									   ,2
									   ,'EX-FBTPO')

					END
											
					SET @TotalDebit = 0;
					SET @TotalCredit = 0;

					SELECT @TotalDebit = SUM(ISNULL([DebitAmount],0)),
					       @TotalCredit = SUM(ISNULL([CreditAmount],0)) 
					FROM [dbo].[CommonBatchDetails] WITH(NOLOCK) WHERE 
					[JournalBatchDetailId] = @JournalBatchDetailId 
					GROUP BY [JournalBatchDetailId]
					
					UPDATE [dbo].[BatchDetails] 
					   SET [DebitAmount] = @TotalDebit,
					       [CreditAmount] = @TotalCredit,
						   [UpdatedDate] = GETUTCDATE(),
						   [UpdatedBy] = @UpdateBy   
					 WHERE [JournalBatchDetailId] = @JournalBatchDetailId

					SELECT @TotalDebit = SUM(ISNULL([DebitAmount],0)),
					       @TotalCredit = SUM(ISNULL([CreditAmount],0)) 
					  FROM [dbo].[BatchDetails] WITH(NOLOCK) WHERE 
					       [JournalBatchHeaderId] = @JournalBatchHeaderId AND IsDeleted = 0 
					       GROUP BY [JournalBatchHeaderId]
			   	          
					SET @TotalBalance = @TotalDebit - @TotalCredit

					UPDATE [dbo].[CodePrefixes] 
					   SET [CurrentNummber] = @currentNo 
					 WHERE [CodeTypeId] = @CodeTypeId 
					   AND [MasterCompanyId] = @MasterCompanyId;
					   
					UPDATE [dbo].[BatchHeader] 
					   SET [TotalDebit] = @TotalDebit,
					       [TotalCredit] = @TotalCredit,
						   [TotalBalance] = @TotalBalance,
						   [UpdatedDate] = GETUTCDATE(),
						   [UpdatedBy] = @UpdateBy
				     WHERE [JournalBatchHeaderId] = @JournalBatchHeaderId;

				END

				END
			END			

			IF(UPPER(@DistributionCode) = UPPER('EX-CORERETURNED'))
	        BEGIN
				SELECT @InvoiceNo = [ReceivingNumber] FROM [dbo].[ReceivingCustomerWork] WITH(NOLOCK) WHERE [ReceivingCustomerWorkId] = @InvoiceId;
				IF EXISTS(SELECT 1 FROM [dbo].[DistributionSetup] WITH(NOLOCK) WHERE [DistributionMasterId] = @DistributionMasterId AND [MasterCompanyId] = @MasterCompanyId AND ISNULL(GlAccountId,0) = 0)
				BEGIN
					SET @ValidDistribution = 0;
				END
				IF(@ValidDistribution = 1)
				BEGIN
					DECLARE @CoreReturnAmount DECIMAL(18,2) = 0;
									
					SELECT @CoreReturnAmount = ISNULL(ESOP.[ExchangeListPrice],0)
					  FROM [dbo].[ExchangeSalesOrderPart] ESOP WITH(NOLOCK) WHERE ESOP.[ExchangeSalesOrderPartId] = @partId;
				
					IF(@CoreReturnAmount > 0)
					BEGIN
						IF NOT EXISTS(SELECT [JournalBatchHeaderId] FROM [dbo].[BatchHeader] WITH(NOLOCK) WHERE [JournalTypeId] = @JournalTypeId AND [MasterCompanyId]=@MasterCompanyId AND CAST([EntryDate] AS DATE) = CAST(GETUTCDATE() AS DATE) AND [StatusId] = @StatusId AND [CustomerTypeId] = @CustomerTypeId)
						BEGIN
							IF NOT EXISTS(SELECT [JournalBatchHeaderId] FROM [dbo].[BatchHeader] WITH(NOLOCK))
							BEGIN
								SET @batch ='001'
								SET @Currentbatch='001'
							END
							ELSE
							BEGIN
								SELECT TOP 1 @Currentbatch = CASE WHEN [CurrentNumber] > 0 THEN CAST([CurrentNumber] AS BIGINT) + 1 
				   							                      ELSE  1 END 
				   					FROM [dbo].[BatchHeader] WITH(NOLOCK) ORDER BY [JournalBatchHeaderId] DESC 

								IF(CAST(@Currentbatch AS BIGINT) > 99)
								BEGIN
									SET @batch = CASE WHEN CAST(@Currentbatch AS BIGINT) > 99 THEN CAST(@Currentbatch AS VARCHAR(100))
				   							          ELSE CONCAT('00', CAST(@Currentbatch AS VARCHAR(50))) END 
								END
								ELSE IF(CAST(@Currentbatch AS BIGINT) > 9)
								BEGIN
									SET @batch = CASE WHEN CAST(@Currentbatch AS BIGINT) > 99 THEN CAST(@Currentbatch AS VARCHAR(100))
				   							          ELSE CONCAT('0', CAST(@Currentbatch AS VARCHAR(50))) END 
								END
								ELSE
								BEGIN
									SET @batch = CASE WHEN CAST(@Currentbatch AS BIGINT) > 99 THEN CAST(@Currentbatch AS VARCHAR(100))
				   							          ELSE CONCAT('00', CAST(@Currentbatch AS VARCHAR(50))) END 
								END			               
							END

							SET @CurrentNumber = CAST(@Currentbatch AS BIGINT) 

							SET @batch = CAST(@JournalTypeCode +' '+ CAST(@batch AS VARCHAR(100)) AS VARCHAR(100))					
				          
							INSERT INTO [dbo].[BatchHeader]
							           ([BatchName],
									    [CurrentNumber],
										[EntryDate],
										[AccountingPeriod],
										[AccountingPeriodId],
										[StatusId],
										[StatusName],
										[JournalTypeId],
										[JournalTypeName],
										[TotalDebit],
										[TotalCredit],
										[TotalBalance],
										[MasterCompanyId],
										[CreatedBy],
										[UpdatedBy],
										[CreatedDate],
										[UpdatedDate],
										[IsActive],
										[IsDeleted],
										[Module],
										[CustomerTypeId])
							      VALUES(@batch,
								         @CurrentNumber,
										 GETUTCDATE(),
										 @AccountingPeriod,
										 @AccountingPeriodId,
										 @StatusId,
										 @StatusName,
										 @JournalTypeId,
										 @JournalTypename,
										 @Amount,
										 @Amount,
										 0,
										 @MasterCompanyId,
										 @UpdateBy,
										 @UpdateBy,
										 GETUTCDATE(),
										 GETUTCDATE(),
										 1,
										 0,
										 'EXCR',
										 @CustomerTypeId);
            	          
							SELECT @JournalBatchHeaderId = SCOPE_IDENTITY();

							UPDATE [dbo].[BatchHeader] 
							   SET [CurrentNumber] = @CurrentNumber 
							 WHERE [JournalBatchHeaderId] = @JournalBatchHeaderId;		   
						END
						ELSE 
						BEGIN
							SELECT @JournalBatchHeaderId = JournalBatchHeaderId,
							       @CurrentPeriodId = ISNULL(AccountingPeriodId,0) 
							 FROM [dbo].[BatchHeader] WITH(NOLOCK)  
							 WHERE [JournalTypeId] = @JournalTypeId AND 
							       [StatusId] = @StatusId AND 
								   [CustomerTypeId] = @CustomerTypeId;

							SELECT @LineNumber = CASE WHEN [LineNumber] > 0 THEN CAST([LineNumber] AS BIGINT) + 1 ELSE  1 END 
				   			  FROM [dbo].[BatchDetails] WITH(NOLOCK) 
							  WHERE [JournalBatchHeaderId] = @JournalBatchHeaderId  ORDER BY [JournalBatchDetailId] DESC 
				    
							IF(@CurrentPeriodId = 0)
							BEGIN
								UPDATE [dbo].[BatchHeader] 
								   SET [AccountingPeriodId] = @AccountingPeriodId,
								       [AccountingPeriod]= @AccountingPeriod   
								 WHERE [JournalBatchHeaderId] = @JournalBatchHeaderId
							END
						END
						
						INSERT INTO [dbo].[BatchDetails]
						           ([JournalTypeNumber],
								    [CurrentNumber],
									[DistributionSetupId], 
									[DistributionName], 
									[JournalBatchHeaderId], 
									[LineNumber], 
									[GlAccountId], 
									[GlAccountNumber], 
									[GlAccountName], 
									[TransactionDate], 
									[EntryDate], 
									[JournalTypeId], 
									[JournalTypeName], 
						            [IsDebit], 
									[DebitAmount], 
									[CreditAmount], 
									[ManagementStructureId], 
									[ModuleName], 
									[LastMSLevel], 
									[AllMSlevels], 
									[MasterCompanyId], 
									[CreatedBy], 
									[UpdatedBy], 
									[CreatedDate], 
									[UpdatedDate], 
									[IsActive], 
									[IsDeleted],
									[AccountingPeriodId],
									[AccountingPeriod])
							 VALUES(@JournalTypeNumber,
							        @currentNo,
									0, 
									NULL, 
									@JournalBatchHeaderId, 
									1, 
									0, 
									NULL, 
									NULL,
									GETUTCDATE(), 
									GETUTCDATE(), 
									@JournalTypeId, 
									@JournalTypename, 
							        1, 
									0, 
									0, 
									0, 
									@ModuleName, 
									NULL, 
									NULL, 
									@MasterCompanyId, 
									@UpdateBy, 
									@UpdateBy, 
									GETUTCDATE(), 
									GETUTCDATE(), 
									1, 
									0,
									@AccountingPeriodId,
									@AccountingPeriod)
						
						SET @JournalBatchDetailId = SCOPE_IDENTITY();

						----------------------------------------------------- Core Returned  Inventory -----------------------------------------------------

						SELECT TOP 1 @DistributionSetupId = [ID],
									 @DistributionName = [Name],
									 @JournalTypeId = [JournalTypeId],
									 @GlAccountId = [GlAccountId],
									 @GlAccountNumber = [GlAccountNumber],
									 @GlAccountName = [GlAccountName],
									 @CrDrType = [CRDRType]
								FROM [dbo].[DistributionSetup] WITH(NOLOCK) 
							   WHERE UPPER([DistributionSetupCode]) = UPPER('EX-CRINV') 
								 AND [DistributionMasterId] = @DistributionMasterId 
								 AND [MasterCompanyId] = @MasterCompanyId;

						INSERT INTO [dbo].[CommonBatchDetails]
									   ([JournalBatchDetailId],
									    [JournalTypeNumber],
										[CurrentNumber],
										[DistributionSetupId],
										[DistributionName],
										[JournalBatchHeaderId],
										[LineNumber],
										[GlAccountId],
										[GlAccountNumber],
										[GlAccountName],
										[TransactionDate],
										[EntryDate],
										[JournalTypeId],
										[JournalTypeName],
								        [IsDebit],
										[DebitAmount],
										[CreditAmount],
										[ManagementStructureId],
										[ModuleName],
										[LastMSLevel],
										[AllMSlevels],
										[MasterCompanyId],
										[CreatedBy],
										[UpdatedBy],
										[CreatedDate],
										[UpdatedDate],
										[IsActive],
										[IsDeleted])
							     VALUES
								       (@JournalBatchDetailId,
									    @JournalTypeNumber,
										@currentNo,
										@DistributionSetupId,
										@DistributionName,
										@JournalBatchHeaderId,
										1,
										@GlAccountId,
										@GlAccountNumber,
										@GlAccountName,
										GETUTCDATE(),
										GETUTCDATE(),
										@JournalTypeId,
										@JournalTypename,
								        CASE WHEN @CrDrType = 1 THEN 1 ELSE 0 END,
								        CASE WHEN @CrDrType = 1 THEN @CoreReturnAmount ELSE 0 END,
								        CASE WHEN @CrDrType = 1 THEN 0 ELSE @CoreReturnAmount END,
								        @ManagementStructureId,
										@ModuleName,
										@LastMSLevel,
										@AllMSlevels,
										@MasterCompanyId,
										@UpdateBy,
										@UpdateBy,
										GETUTCDATE(),
										GETUTCDATE(),
										1,
										0);

						SET @CommonJournalBatchDetailId = SCOPE_IDENTITY();

						-----  Accounting MS Entry  -----

						EXEC [dbo].[PROCAddUpdateAccountingBatchMSData] @CommonJournalBatchDetailId,@ManagementStructureId,@MasterCompanyId,@UpdateBy,@AccountMSModuleId,1; 

						INSERT INTO [dbo].[ExchangeBatchDetails]
                                       ([CommonJournalBatchDetailId]
                                       ,[JournalBatchDetailId]
                                       ,[JournalBatchHeaderId]
                                       ,[ExchangeSalesOrderId]
                                       ,[ExchangeSalesOrderNumber]
                                       ,[CustomerId]
                                       ,[CustomerReference]
                                       ,[ExchangeSalesOrderPartId]
                                       ,[ItemMasterId]
                                       ,[StockLineId]
                                       ,[StocklineNumber]
                                       ,[InvoiceId]
                                       ,[InvoiceNo]
									   ,[TypeId]
									   ,[DistSetupCode])
                                 VALUES
                                       (@CommonJournalBatchDetailId
									   ,@JournalBatchDetailId
                                       ,@JournalBatchHeaderId
                                       ,@ReferenceId
                                       ,@ExchangeSalesOrderNumber
									   ,@CustomerId
									   ,@CustRefNumber
									   ,@partId
									   ,@ItemmasterId
									   ,@StocklineId
									   ,@StocklineNumber
									   ,@InvoiceId
									   ,@InvoiceNo
									   ,3
									   ,'EX-CRINV'); 

						----------------------------------------------------- Core Returned Inventory On Exchange Agreeement -----------------------------------------------------

						SELECT TOP 1 @DistributionSetupId = [ID],
									 @DistributionName = [Name],
									 @JournalTypeId = [JournalTypeId],
									 @GlAccountId = [GlAccountId],
									 @GlAccountNumber = [GlAccountNumber],
									 @GlAccountName = [GlAccountName],
									 @CrDrType = [CRDRType]
								FROM [dbo].[DistributionSetup] WITH(NOLOCK) 
							   WHERE UPPER([DistributionSetupCode]) = UPPER('EX-CRINVAGM') 
								 AND [DistributionMasterId] = @DistributionMasterId 
								 AND [MasterCompanyId] = @MasterCompanyId;
						
						INSERT INTO [dbo].[CommonBatchDetails]
									   ([JournalBatchDetailId],
									    [JournalTypeNumber],
										[CurrentNumber],
										[DistributionSetupId],
										[DistributionName],
										[JournalBatchHeaderId],
										[LineNumber],
										[GlAccountId],
										[GlAccountNumber],
										[GlAccountName],
										[TransactionDate],
										[EntryDate],
										[JournalTypeId],
										[JournalTypeName],
								        [IsDebit],
										[DebitAmount],
										[CreditAmount],
										[ManagementStructureId],
										[ModuleName],
										[LastMSLevel],
										[AllMSlevels],
										[MasterCompanyId],
										[CreatedBy],
										[UpdatedBy],
										[CreatedDate],
										[UpdatedDate],
										[IsActive],
										[IsDeleted])
							     VALUES
								       (@JournalBatchDetailId,
									    @JournalTypeNumber,
										@currentNo,
										@DistributionSetupId,
										@DistributionName,
										@JournalBatchHeaderId,
										1,
										@GlAccountId,
										@GlAccountNumber,
										@GlAccountName,
										GETUTCDATE(),
										GETUTCDATE(),
										@JournalTypeId,
										@JournalTypename,
								        CASE WHEN @CrDrType = 1 THEN 1 ELSE 0 END,
								        CASE WHEN @CrDrType = 1 THEN @CoreReturnAmount ELSE 0 END,
								        CASE WHEN @CrDrType = 1 THEN 0 ELSE @CoreReturnAmount END,
								        @ManagementStructureId,
										@ModuleName,
										@LastMSLevel,
										@AllMSlevels,
										@MasterCompanyId,
										@UpdateBy,
										@UpdateBy,
										GETUTCDATE(),
										GETUTCDATE(),
										1,
										0);

						SET @CommonJournalBatchDetailId = SCOPE_IDENTITY();

						-----  Accounting MS Entry  -----

						EXEC [dbo].[PROCAddUpdateAccountingBatchMSData] @CommonJournalBatchDetailId,@ManagementStructureId,@MasterCompanyId,@UpdateBy,@AccountMSModuleId,1; 

						INSERT INTO [dbo].[ExchangeBatchDetails]
                                       ([CommonJournalBatchDetailId]
                                       ,[JournalBatchDetailId]
                                       ,[JournalBatchHeaderId]
                                       ,[ExchangeSalesOrderId]
                                       ,[ExchangeSalesOrderNumber]
                                       ,[CustomerId]
                                       ,[CustomerReference]
                                       ,[ExchangeSalesOrderPartId]
                                       ,[ItemMasterId]
                                       ,[StockLineId]
                                       ,[StocklineNumber]
                                       ,[InvoiceId]
                                       ,[InvoiceNo]
									   ,[TypeId]
									   ,[DistSetupCode])
                                 VALUES
                                       (@CommonJournalBatchDetailId
									   ,@JournalBatchDetailId
                                       ,@JournalBatchHeaderId
                                       ,@ReferenceId
                                       ,@ExchangeSalesOrderNumber
									   ,@CustomerId
									   ,@CustRefNumber
									   ,@partId
									   ,@ItemmasterId
									   ,@StocklineId
									   ,@StocklineNumber
									   ,@InvoiceId
									   ,@InvoiceNo
									   ,3
									   ,'EX-CRINVAGM'); 
						
						----------------------------------------------------Updating Receiving Customer Batch Entry Flag Here -----------------------------------------------------

						UPDATE [dbo].[ReceivingCustomerWork] SET [IsExchangeBatchEntry] = 1 WHERE [ReceivingCustomerWorkId] = @InvoiceId;

					END
					SET @TotalDebit = 0;
					SET @TotalCredit = 0;

					SELECT @TotalDebit = SUM(ISNULL([DebitAmount],0)),
					       @TotalCredit = SUM(ISNULL([CreditAmount],0)) 
					FROM [dbo].[CommonBatchDetails] WITH(NOLOCK) WHERE 
					[JournalBatchDetailId] = @JournalBatchDetailId 
					GROUP BY [JournalBatchDetailId]
					
					UPDATE [dbo].[BatchDetails] 
					   SET [DebitAmount] = @TotalDebit,
					       [CreditAmount] = @TotalCredit,
						   [UpdatedDate] = GETUTCDATE(),
						   [UpdatedBy] = @UpdateBy   
					 WHERE [JournalBatchDetailId] = @JournalBatchDetailId

					SELECT @TotalDebit = SUM(ISNULL([DebitAmount],0)),
					       @TotalCredit = SUM(ISNULL([CreditAmount],0)) 
					  FROM [dbo].[BatchDetails] WITH(NOLOCK) WHERE 
					       [JournalBatchHeaderId] = @JournalBatchHeaderId AND IsDeleted = 0 
					       GROUP BY [JournalBatchHeaderId]
			   	          
					SET @TotalBalance = @TotalDebit - @TotalCredit

					UPDATE [dbo].[CodePrefixes] 
					   SET [CurrentNummber] = @currentNo 
					 WHERE [CodeTypeId] = @CodeTypeId 
					   AND [MasterCompanyId] = @MasterCompanyId;
					   
					UPDATE [dbo].[BatchHeader] 
					   SET [TotalDebit] = @TotalDebit,
					       [TotalCredit] = @TotalCredit,
						   [TotalBalance] = @TotalBalance,
						   [UpdatedDate] = GETUTCDATE(),
						   [UpdatedBy] = @UpdateBy
				     WHERE [JournalBatchHeaderId] = @JournalBatchHeaderId;

				END

			END		
			
		END
	END
  COMMIT  TRANSACTION  		
 END TRY
BEGIN CATCH  
		IF @@trancount > 0
		PRINT 'ROLLBACK'
		ROLLBACK TRANSACTION;  
		DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
        , @AdhocComments     VARCHAR(150)    = 'USP_BatchTriggerBasedonEXSOInvoice' 
        , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@DistributionMasterId, '') + ''
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