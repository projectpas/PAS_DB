/*************************************************************           
 ** File:   [USP_BatchTriggerBasedonDistribution]
 ** Author:  Subhash Saliya
 ** Description: This stored procedure is used USP_BatchTriggerBasedonDistribution
 ** Purpose:         
 ** Date:   08/10/2022      
          
 ** PARAMETERS: @JournalBatchHeaderId BIGINT
         
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    10/02/2026  Moin Bloch     CREATED
	2    20/02/2026  Moin Bloch     Tender Stockline Multiply by Tendered Quantity PN-15505
	3    24/04/2026  Moin Bloch     Tender Stockline GLAccount Fix
	4    01/July/2026			 RAJESH GAMI						[PN-17008] - Merge Non Stock Inventory to ItemMaster : Get only Stock Inventory Data Where IsNonStock = 0
	5	 23/06/2026	 Moin Bloch   	Modify (Added IsBypassAccounting Flag to bypass Accounting Entry PN-16871)

   EXEC [dbo].[USP_TearDownWOBatchTriggerBasedonDistribution] 4,3915,0,0,459,0,0,'',0,0.00,'WO',1,'ADMIN User'

************************************************************************/
CREATE   PROCEDURE [dbo].[USP_TearDownWOBatchTriggerBasedonDistribution]
@DistributionMasterId BIGINT=NULL,
@ReferenceId BIGINT=NULL,
@ReferencePartId BIGINT=NULL,
@StocklineId BIGINT=NULL,
@MasterCompanyId INT=0,
@UpdateBy VARCHAR(200)=NULL
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
        DECLARE @WorkOrderNumber VARCHAR(200) 
        DECLARE @MPNName VARCHAR(200) 
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
		DECLARE @Batchtype INT=1
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
	    DECLARE @MaterialCost DECIMAL(18,2)=0
	    DECLARE @LaborOverHeadCost DECIMAL(18,2)=0
	    DECLARE @FreightCost DECIMAL(18,2)=0
		DECLARE @SalesTax DECIMAL(18,2)=0
		DECLARE @OtherTax DECIMAL(18,2)=0
		DECLARE @InvoiceNo VARCHAR(100)
		DECLARE @MiscChargesCost DECIMAL(18,2)=0
		DECLARE @LaborCost DECIMAL(18,2)=0
		DECLARE @InvoiceLaborCost DECIMAL(18,2)=0
		DECLARE @RevenuWO DECIMAL(18,2)=0
		DECLARE @FinishGoodAmount DECIMAL(18,2)=0
		DECLARE @JournalBatchDetailId BIGINT=0
		DECLARE @CommonJournalBatchDetailId BIGINT=0;
		--DECLARE @WopJounralTypeid BIGINT=0;
		DECLARE @StocklineNumber VARCHAR(100)		
		DECLARE @AccountMSModuleId INT = 0
		DECLARE @Amount DECIMAL(18,2) = 0	
		DECLARE @Qty DECIMAL(18,2) = 0	
		
		SELECT @IsAccountByPass = [IsAccountByPass] FROM [dbo].[MasterCompany] WITH(NOLOCK)  WHERE MasterCompanyId= @MasterCompanyId

	    SELECT @DistributionCode = [DistributionCode] FROM [dbo].[DistributionMaster] WITH(NOLOCK)  WHERE ID= @DistributionMasterId

	    SELECT @StatusId = [Id], @StatusName= [name] FROM [dbo].[BatchStatus] WITH(NOLOCK)  WHERE [Name] = 'Open'

	    SELECT TOP 1 @JournalTypeId = [JournalTypeId] FROM [dbo].[DistributionSetup] WITH(NOLOCK)  WHERE [DistributionMasterId] = @DistributionMasterId AND [MasterCompanyId] = @MasterCompanyId
	   
		SELECT @JournalBatchHeaderId =JournalBatchHeaderId FROM [dbo].[BatchHeader] WITH(NOLOCK)  WHERE JournalTypeId= @JournalTypeId AND StatusId=@StatusId
	    
		SELECT @JournalTypeCode = JournalTypeCode,@JournalTypename = JournalTypeName FROM [dbo].[JournalType] WITH(NOLOCK)  WHERE ID= @JournalTypeId
	
		SELECT @AccountMSModuleId = [ManagementStructureModuleId] FROM [dbo].[ManagementStructureModule] WITH(NOLOCK) WHERE [ModuleName] ='Accounting';
		
		DECLARE @currentNo AS BIGINT = 0;
		DECLARE @CodeTypeId AS BIGINT = 74;
		DECLARE @JournalTypeNumber VARCHAR(100);
		DECLARE @CrDrType INT=0
		DECLARE @ValidDistribution BIT = 1;
		DECLARE @LotId BIGINT = 0;
		DECLARE @LotNumber VARCHAR(50) = '';
		DECLARE @InvoiceDate DATETIME2(7) = NULL
		DECLARE @MasterLoopID AS INT;
		DECLARE @temptotaldebitcount DECIMAL(18,2)= 0 ;
		DECLARE @temptotalcreditcount DECIMAL(18,2)= 0;
		DECLARE @IsAutoPost INT = 0;
		DECLARE @IsBatchGenerated INT = 0;
		DECLARE @CurrencyCode VARCHAR(20) = '';
		DECLARE @FXRate DECIMAL(18,2) = 1;	
		DECLARE @ReferenceModule VARCHAR(100) = 'TWO';
		DECLARE @ModuleName VARCHAR(50) = 'TWO';
		DECLARE @IsBypassAccounting BIT = 0;		

		IF((@JournalTypeCode ='WTD' OR @JournalTypeCode ='WTDTS' OR @JournalTypeCode ='WTDIL') AND @IsAccountByPass=0)
		BEGIN 
			SELECT @WorkOrderNumber = WorkOrderNum,
			       @CustomerId=CustomerId,
				   @CustomerName= CustomerName 
			  FROM [dbo].[WorkOrder] WITH(NOLOCK)  
			  WHERE [WorkOrderId] = @ReferenceId
		    
			IF(ISNULL(@CustomerId, 0) > 0)
			BEGIN
				SELECT @CurrencyCode = ISNULL(CY.Code, '') FROM [dbo].[Customer] CU WITH(NOLOCK) LEFT JOIN [DBO].[CustomerFinancial] CF WITH(NOLOCK) ON CU.CustomerId = CF.CustomerId LEFT JOIN [DBO].[Currency] CY WITH(NOLOCK) ON CF.CurrencyId = CY.CurrencyId WHERE CU.CustomerId = @CustomerId;
			END
			
	        SELECT @ManagementStructureId = WOP.[ManagementStructureId], 
			       @ItemmasterId = WOP.[ItemMasterId], 
				   @CustRefNumber = WOP.[CustomerReference]					  
			  FROM [dbo].[WorkOrderPartNumber] WOP WITH(NOLOCK) 			  
			  WHERE WOP.[WorkOrderId] = @ReferenceId AND WOP.[ID] = @ReferencePartId;

	        SELECT @MPNName = partnumber 
			  FROM [dbo].[ItemMaster] WITH(NOLOCK)  
			 WHERE ItemMasterId=@ItemmasterId 

	         AND ISNULL(dbo.ItemMaster.IsNonStock,0) = 0
	        SELECT @LastMSLevel=LastMSLevel,
			       @AllMSlevels=AllMSlevels 
			  FROM [dbo].[WorkOrderManagementStructureDetails] WITH(NOLOCK) 
			  WHERE ReferenceID=@ReferencePartId

			SELECT TOP 1  @AccountingPeriodId=acc.AccountingCalendarId,
			              @AccountingPeriod=PeriodName 
			FROM [dbo].[EntityStructureSetup] est WITH(NOLOCK) 
			INNER JOIN [dbo].[ManagementStructureLevel] msl WITH(NOLOCK) ON est.Level1Id = msl.ID 
			INNER JOIN [dbo].[AccountingCalendar] acc WITH(NOLOCK) ON msl.LegalEntityId = acc.LegalEntityId AND acc.IsDeleted =0
			WHERE est.[EntityStructureId] = @ManagementStructureId and acc.MasterCompanyId=@MasterCompanyId  AND CAST(GETUTCDATE() AS DATE) >= CAST(FromDate AS DATE) AND  CAST(GETUTCDATE() AS DATE) <= CAST(ToDate AS DATE)
		    
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

			INSERT INTO #tmpCodePrefixes (CodePrefixId,CodeTypeId,CurrentNumber, CodePrefix, CodeSufix, StartsFrom) 
			SELECT CodePrefixId, CP.CodeTypeId, CurrentNummber, CodePrefix, CodeSufix, StartsFrom 
			FROM dbo.CodePrefixes CP WITH(NOLOCK) JOIN dbo.CodeTypes CT WITH(NOLOCK) ON CP.CodeTypeId = CT.CodeTypeId
			WHERE CT.CodeTypeId IN (@CodeTypeId) AND CP.MasterCompanyId = @MasterCompanyId AND CP.IsActive = 1 AND CP.IsDeleted = 0;

			IF(EXISTS (SELECT 1 FROM #tmpCodePrefixes WHERE CodeTypeId = @CodeTypeId))
			BEGIN 
				SELECT 
					@currentNo = CASE WHEN CurrentNumber > 0 THEN CAST(CurrentNumber AS BIGINT) + 1 
						ELSE CAST(StartsFrom AS BIGINT) + 1 END 
				FROM #tmpCodePrefixes WHERE CodeTypeId = @CodeTypeId

				SET @JournalTypeNumber = (SELECT * FROM dbo.udfGenerateCodeNumber(@currentNo,(SELECT CodePrefix FROM #tmpCodePrefixes WHERE CodeTypeId = @CodeTypeId), (SELECT CodeSufix FROM #tmpCodePrefixes WHERE CodeTypeId = @CodeTypeId)))
			END
			ELSE 
			BEGIN
				ROLLBACK TRAN;
			END

			IF(UPPER(@DistributionCode) = UPPER('CREATETEARDOWNWO'))
			BEGIN				
				SELECT @Amount = ISNULL(STL.[UnitCost],0),		   
					   @LotId = STL.[LotId],
				       @LotNumber = LO.[LotNumber]					   
				  FROM [dbo].[Stockline] STL WITH(NOLOCK)
				  LEFT JOIN [dbo].[Lot] LO WITH(NOLOCK) ON LO.[LotId] = STL.[LotId]		
				 WHERE STL.[StockLineId] = @StocklineId;
				 
				SELECT TOP 1 @DistributionSetupId = [ID],
				             @DistributionName=[Name],
							 @JournalTypeId = [JournalTypeId],
							 @GlAccountId = [GlAccountId],
							 @GlAccountNumber = [GlAccountNumber],
							 @GlAccountName = [GlAccountName],
							 @CrDrType = [CRDRType],
							 @IsAutoPost = ISNULL([IsAutoPost],0),
							 @IsBypassAccounting = ISNULL([IsBypassAccounting],0)
				FROM [dbo].[DistributionSetup] WITH(NOLOCK)  
				WHERE UPPER([DistributionSetupCode]) =UPPER('TDWOWIPPARTS') 
				  AND [DistributionMasterId] = @DistributionMasterId 
				  AND [MasterCompanyId] = @MasterCompanyId;

				--GL Selection Saved At StockLine 
				SELECT	@GlAccountId = SL.WorkInProgressGLAccId	FROM [dbo].[Stockline] SL WITH(NOLOCK) WHERE SL.[StockLineId] = @StocklineId;
				SELECT	@GlAccountNumber = [AccountCode], @GlAccountName = [AccountName] FROM [dbo].[GLAccount] WITH(NOLOCK) WHERE [GLAccountId] = @GlAccountId

				IF EXISTS(SELECT 1 FROM [dbo].[DistributionSetup] WITH(NOLOCK) WHERE [DistributionMasterId] =@DistributionMasterId AND [MasterCompanyId]=@MasterCompanyId AND ISNULL([GlAccountId],0) = 0 AND ISNULL([IsManualText],0) = 0)
				BEGIN
					SET @ValidDistribution = 0;
				END

				IF EXISTS(SELECT 1 FROM [dbo].[Stockline] WITH(NOLOCK) WHERE [StockLineId]=@StocklineId AND ISNULL([GlAccountId],0) = 0)
				BEGIN
					SET @ValidDistribution = 0;
				END

				IF(@Amount > 0 AND @ValidDistribution = 1)
				BEGIN					
					IF NOT EXISTS(SELECT [JournalBatchHeaderId] FROM [dbo].[BatchHeader] WITH(NOLOCK) WHERE [JournalTypeId] = @JournalTypeId AND [MasterCompanyId] = @MasterCompanyId AND CAST([EntryDate] AS DATE) = CAST(GETUTCDATE() AS DATE) AND [StatusId] = @StatusId)
					BEGIN
						IF NOT EXISTS(SELECT JournalBatchHeaderId FROM BatchHeader WITH(NOLOCK))
						BEGIN	
							SET @batch ='001'
							SET @Currentbatch='001'
						END
						ELSE
						BEGIN
							SELECT top 1 @Currentbatch = CASE WHEN CurrentNumber > 0 THEN CAST(CurrentNumber AS BIGINT) + 1 ELSE  1 END 
				   			FROM [dbo].[BatchHeader] WITH(NOLOCK) Order by JournalBatchHeaderId desc 

							IF(CAST(@Currentbatch AS BIGINT) >99)
							BEGIN

								SET @batch = CASE WHEN CAST(@Currentbatch AS BIGINT) > 99 THEN cast(@Currentbatch as VARCHAR(100))
				   				ELSE CONCAT('00', CAST(@Currentbatch AS VARCHAR(50))) END 
							END
							ELSE IF(CAST(@Currentbatch AS BIGINT) >9)
							BEGIN

								SET @batch = CASE WHEN CAST(@Currentbatch AS BIGINT) > 99 THEN cast(@Currentbatch as VARCHAR(100))
				   				ELSE CONCAT('0', CAST(@Currentbatch AS VARCHAR(50))) END 
							END
							ELSE
							BEGIN
								SET @batch = CASE WHEN CAST(@Currentbatch AS BIGINT) > 99 THEN cast(@Currentbatch as VARCHAR(100))
				   				ELSE CONCAT('00', CAST(@Currentbatch AS VARCHAR(50))) END 

							END
						END
						SET @CurrentNumber = CAST(@Currentbatch AS BIGINT) 
						SET @batch = CAST(@JournalTypeCode +' '+cast(@batch as VARCHAR(100)) as VARCHAR(100))
						print @CurrentNumber
				          
						INSERT INTO [dbo].[BatchHeader]
									([BatchName],[CurrentNumber],[EntryDate],[AccountingPeriod],AccountingPeriodId,[StatusId],[StatusName],[JournalTypeId],[JournalTypeName],[TotalDebit],[TotalCredit],[TotalBalance],[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted],[Module])
						VALUES
									(@batch,@CurrentNumber,GETUTCDATE(),@AccountingPeriod,@AccountingPeriodId,@StatusId,@StatusName,@JournalTypeId,@JournalTypename,0,0,0,@MasterCompanyId,@UpdateBy,@UpdateBy,GETUTCDATE(),GETUTCDATE(),1,0,@ModuleName);
            	          
						SELECT @JournalBatchHeaderId = SCOPE_IDENTITY()
						
						UPDATE dbo.BatchHeader SET CurrentNumber=@CurrentNumber  WHERE JournalBatchHeaderId= @JournalBatchHeaderId
					END
					ELSE
					BEGIN
						SELECT @JournalBatchHeaderId=JournalBatchHeaderId,@CurrentPeriodId=isnull(AccountingPeriodId,0) FROM dbo.BatchHeader WITH(NOLOCK)  WHERE JournalTypeId= @JournalTypeId and StatusId=@StatusId
						SELECT @LineNumber = CASE WHEN LineNumber > 0 THEN CAST(LineNumber AS BIGINT) + 1 ELSE  1 END 
				   								FROM [dbo].[BatchDetails] WITH(NOLOCK) WHERE JournalBatchHeaderId=@JournalBatchHeaderId  Order by JournalBatchDetailId desc 
				    
						IF(@CurrentPeriodId =0)
						BEGIN
							UPDATE dbo.BatchHeader SET AccountingPeriodId=@AccountingPeriodId,AccountingPeriod=@AccountingPeriod   WHERE JournalBatchHeaderId= @JournalBatchHeaderId
						END		
						
						SET @IsBatchGenerated = 1;
					END
					
					INSERT INTO [dbo].[BatchDetails]
						([JournalTypeNumber],[CurrentNumber],[DistributionSetupId],[DistributionName],[JournalBatchHeaderId],[LineNumber],[GlAccountId],[GlAccountNumber],[GlAccountName] ,[TransactionDate],[EntryDate],[JournalTypeId],[JournalTypeName],[IsDebit],[DebitAmount] ,[CreditAmount],[ManagementStructureId],[ModuleName],[LastMSLevel],[AllMSlevels],[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate] ,[IsActive] ,[IsDeleted],[AccountingPeriodId],[AccountingPeriod])
					VALUES
						(@JournalTypeNumber,@currentNo,@DistributionSetupId,@DistributionName,@JournalBatchHeaderId,1 ,@GlAccountId ,@GlAccountNumber ,@GlAccountName,GETUTCDATE(),GETUTCDATE(),@JournalTypeId ,@JournalTypename ,
						1,0,0,@ManagementStructureId ,@ModuleName,@LastMSLevel,@AllMSlevels ,@MasterCompanyId,@UpdateBy,@UpdateBy,GETUTCDATE(),GETUTCDATE(),1,0,@AccountingPeriodId,@AccountingPeriod)

					SET @JournalBatchDetailId = SCOPE_IDENTITY()

					IF(@IsBypassAccounting = 0)
					BEGIN

					INSERT INTO [dbo].[CommonBatchDetails]
						([JournalBatchDetailId],[JournalTypeNumber],[CurrentNumber],[DistributionSetupId],[DistributionName],[JournalBatchHeaderId],[LineNumber],[GlAccountId],[GlAccountNumber],[GlAccountName] ,[TransactionDate],[EntryDate] ,[JournalTypeId],[JournalTypeName],[IsDebit],[DebitAmount] ,[CreditAmount],[ManagementStructureId]
						,[ModuleName],[LastMSLevel],[AllMSlevels],[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate] ,[IsActive] ,[IsDeleted],[LotId],[LotNumber],[ReferenceNumber],[ReferenceName],[LocalCurrency],[FXRate],[ForeignCurrency],[ReferenceId],[ReferenceModule])
					VALUES
						(@JournalBatchDetailId,@JournalTypeNumber,@currentNo,@DistributionSetupId,@DistributionName,@JournalBatchHeaderId,1 ,@GlAccountId ,@GlAccountNumber ,@GlAccountName,GETUTCDATE(),GETUTCDATE(),@JournalTypeId ,@JournalTypename ,
						CASE WHEN @CrDrType = 1 THEN 1 ELSE 0 END,
						CASE WHEN @CrDrType = 1 THEN @Amount ELSE 0 END,
						CASE WHEN @CrDrType = 1 THEN 0 ELSE @Amount END,
						@ManagementStructureId ,@ModuleName,@LastMSLevel,@AllMSlevels ,@MasterCompanyId,@UpdateBy,@UpdateBy,GETUTCDATE(),GETUTCDATE(),1,0,@LotId,@LotNumber,@WorkOrderNumber,@CustomerName,@CurrencyCode,@FXRate,@CurrencyCode,@ReferenceId,@ReferenceModule)

					SET @CommonJournalBatchDetailId = SCOPE_IDENTITY()

					-----  Accounting MS Entry  -----

					EXEC [dbo].[PROCAddUpdateAccountingBatchMSData] @CommonJournalBatchDetailId,@ManagementStructureId,@MasterCompanyId,@UpdateBy,@AccountMSModuleId,1; 
										
					INSERT INTO [dbo].[WorkOrderBatchDetails]([JournalBatchDetailId],[JournalBatchHeaderId],[ReferenceId],[ReferenceName],[MPNPartId],[MPNName],[PiecePNId],[PiecePN],[CustomerId],[CustomerName] ,[InvoiceId],[InvoiceName],[ARControlNum] ,[CustRefNumber] ,[Qty],[UnitPrice],[LaborHrs],[DirectLaborCost],[OverheadCost],[CommonJournalBatchDetailId],[StocklineId],[StocklineNumber],[IsWorkOrder])
					VALUES (@JournalBatchDetailId,@JournalBatchHeaderId,@ReferenceId ,@WorkOrderNumber ,@ReferencePartId,@MPNName,0,NULL,@CustomerId ,@CustomerName,null ,null,null,@CustRefNumber,@Qty,@UnitPrice,@LaborHrs,@DirectLaborCost,@OverheadCost,@CommonJournalBatchDetailId,@StocklineId,@StocklineNumber,1)
						
					END

					SELECT TOP 1 @DistributionSetupId=ID,
					             @DistributionName=Name,
								 @JournalTypeId =JournalTypeId,
								 @CrDrType = CRDRType, 
								 @IsBypassAccounting = ISNULL([IsBypassAccounting],0)
							FROM dbo.DistributionSetup WITH(NOLOCK)  
						   WHERE UPPER(DistributionSetupCode) =UPPER('TDWOINVENTORYPARTS') 
						     AND [DistributionMasterId] = @DistributionMasterId 
						     AND [MasterCompanyId] = @MasterCompanyId

					SELECT @GlAccountId=GlAccountId 
					  FROM [dbo].[Stockline] WITH(NOLOCK) 
					 WHERE [StockLineId]=@StocklineId
					
					SELECT @GlAccountNumber=AccountCode,
					       @GlAccountName=AccountName 
					  FROM dbo.GLAccount WITH(NOLOCK) WHERE GLAccountId=@GlAccountId

					SET @GlAccountId = ISNULL(@GlAccountId,0)
					
					IF(@IsBypassAccounting = 0)
					BEGIN

					INSERT INTO [dbo].[CommonBatchDetails](JournalBatchDetailId,JournalTypeNumber,CurrentNumber,DistributionSetupId,DistributionName,[JournalBatchHeaderId],[LineNumber],[GlAccountId],[GlAccountNumber],[GlAccountName] ,[TransactionDate],[EntryDate] ,[JournalTypeId],[JournalTypeName],[IsDebit],[DebitAmount] ,[CreditAmount],[ManagementStructureId],[ModuleName],LastMSLevel,AllMSlevels,[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate] ,[IsActive] ,[IsDeleted],[LotId],[LotNumber],[ReferenceNumber],[ReferenceName],[LocalCurrency],[FXRate],[ForeignCurrency],[ReferenceId],[ReferenceModule])
					VALUES(@JournalBatchDetailId,@JournalTypeNumber,@currentNo,@DistributionSetupId,@DistributionName,@JournalBatchHeaderId,1 ,@GlAccountId ,@GlAccountNumber ,@GlAccountName,GETUTCDATE(),GETUTCDATE(),@JournalTypeId ,@JournalTypename ,
						CASE WHEN @CrDrType = 1 THEN 1 ELSE 0 END,
						CASE WHEN @CrDrType = 1 THEN @Amount ELSE 0 END,
						CASE WHEN @CrDrType = 1 THEN 0 ELSE @Amount END,@ManagementStructureId ,@ModuleName,@LastMSLevel,@AllMSlevels ,@MasterCompanyId,@UpdateBy,@UpdateBy,GETUTCDATE(),GETUTCDATE(),1,0,@LotId,@LotNumber,@WorkOrderNumber,@CustomerName,@CurrencyCode,@FXRate,@CurrencyCode,@ReferenceId,@ReferenceModule)

					SET @CommonJournalBatchDetailId = SCOPE_IDENTITY()
					
					-----  Accounting MS Entry  -----

					EXEC [dbo].[PROCAddUpdateAccountingBatchMSData] @CommonJournalBatchDetailId,@ManagementStructureId,@MasterCompanyId,@UpdateBy,@AccountMSModuleId,1; 
										
					INSERT INTO [dbo].[WorkOrderBatchDetails](JournalBatchDetailId,[JournalBatchHeaderId],[ReferenceId],[ReferenceName],[MPNPartId],[MPNName],[PiecePNId],[PiecePN],[CustomerId],[CustomerName] ,[InvoiceId],[InvoiceName],[ARControlNum] ,[CustRefNumber] ,[Qty],[UnitPrice],[LaborHrs],[DirectLaborCost],[OverheadCost],[CommonJournalBatchDetailId],[StocklineId],[StocklineNumber],[IsWorkOrder])
					VALUES(@JournalBatchDetailId,@JournalBatchHeaderId,@ReferenceId ,@WorkOrderNumber ,@ReferencePartId,@MPNName,0,NULL,@CustomerId ,@CustomerName,NULL ,NULL,NULL,@CustRefNumber,@Qty,@UnitPrice,@LaborHrs,@DirectLaborCost,@OverheadCost,@CommonJournalBatchDetailId,@StocklineId,@StocklineNumber,1)

					END

					SET @TotalDebit=0;
					SET @TotalCredit=0;

					SELECT @TotalDebit = SUM(DebitAmount),
					       @TotalCredit = SUM(CreditAmount) 
					  FROM [dbo].[CommonBatchDetails] WITH(NOLOCK) 
					  WHERE [JournalBatchDetailId]=@JournalBatchDetailId GROUP BY JournalBatchDetailId
					
					UPDATE [dbo].[BatchDetails] 
					   SET [DebitAmount] = @TotalDebit,
					       [CreditAmount]=@TotalCredit,
						   [UpdatedDate]=GETUTCDATE(),
						   [UpdatedBy]=@UpdateBy 
					 WHERE [JournalBatchDetailId]=@JournalBatchDetailId;

					 --AutoPost Batch
					IF(@IsAutoPost = 1 AND @IsBatchGenerated = 0)
					BEGIN
						EXEC [dbo].[UpdateToPostFullBatch] @JournalBatchHeaderId,@UpdateBy;
					END
					IF(@IsAutoPost = 1 AND @IsBatchGenerated = 1)
					BEGIN
						EXEC [dbo].[USP_UpdateCommonBatchStatus] @JournalBatchDetailId,@UpdateBy,@AccountingPeriodId,@AccountingPeriod;
					END
				END
				
				SELECT @TotalDebit = SUM([DebitAmount]),@TotalCredit = SUM([CreditAmount]) FROM [dbo].[BatchDetails] WITH(NOLOCK) WHERE [JournalBatchHeaderId] = @JournalBatchHeaderId AND [IsDeleted] = 0 GROUP BY [JournalBatchHeaderId]
			   	         
			    SET @TotalBalance = @TotalDebit - @TotalCredit
				         
			    UPDATE [dbo].[BatchHeader] SET [TotalDebit] = @TotalDebit,[TotalCredit] = @TotalCredit,[TotalBalance] = @TotalBalance,[UpdatedDate]=GETUTCDATE(),[UpdatedBy]=@UpdateBy WHERE [JournalBatchHeaderId] = @JournalBatchHeaderId
	            
				UPDATE [dbo].[CodePrefixes] SET [CurrentNummber] = @currentNo WHERE [CodeTypeId] = @CodeTypeId AND MasterCompanyId = @MasterCompanyId

			END
			IF(UPPER(@DistributionCode) = UPPER('TENDERINGSTOCKLINETWO'))
			BEGIN				
				SELECT @Amount = (ISNULL(STL.[UnitCost],0) * ISNULL(STL.[QuantityAvailable],0)),					   
					   @LotId = STL.[LotId],
				       @LotNumber = LO.[LotNumber]					   
				  FROM [dbo].[Stockline] STL WITH(NOLOCK)
				  LEFT JOIN [dbo].[Lot] LO WITH(NOLOCK) ON LO.[LotId] = STL.[LotId]		
				 WHERE STL.[StockLineId] = @StocklineId;
				 
				SELECT TOP 1 @DistributionSetupId = [ID],
				             @DistributionName=[Name],
							 @JournalTypeId = [JournalTypeId],
							 @GlAccountId = [GlAccountId],
							 @GlAccountNumber = [GlAccountNumber],
							 @GlAccountName = [GlAccountName],
							 @CrDrType = [CRDRType],
							 @IsAutoPost = ISNULL([IsAutoPost],0),
							 @IsBypassAccounting = ISNULL([IsBypassAccounting],0)
				FROM [dbo].[DistributionSetup] WITH(NOLOCK)  
				WHERE UPPER([DistributionSetupCode]) =UPPER('TDSWOINVENTORYPARTS') 
				  AND [DistributionMasterId] = @DistributionMasterId 
				  AND [MasterCompanyId] = @MasterCompanyId;

				--GL Selection Saved At StockLine 				
				SELECT @GlAccountId=GlAccountId FROM [dbo].[Stockline] WITH(NOLOCK) WHERE [StockLineId]=@StocklineId
				SELECT	@GlAccountNumber = [AccountCode], @GlAccountName = [AccountName] FROM [dbo].[GLAccount] WITH(NOLOCK) WHERE [GLAccountId] = @GlAccountId

				IF EXISTS(SELECT 1 FROM [dbo].[DistributionSetup] WITH(NOLOCK) WHERE [DistributionMasterId] =@DistributionMasterId AND [MasterCompanyId]=@MasterCompanyId AND ISNULL([GlAccountId],0) = 0 AND ISNULL([IsManualText],0) = 0)
				BEGIN
					SET @ValidDistribution = 0;
				END

				IF EXISTS(SELECT 1 FROM [dbo].[Stockline] WITH(NOLOCK) WHERE [StockLineId]=@StocklineId AND ISNULL([GlAccountId],0) = 0)
				BEGIN
					SET @ValidDistribution = 0;
				END

				IF(@Amount > 0 AND @ValidDistribution = 1)
				BEGIN					
					IF NOT EXISTS(SELECT [JournalBatchHeaderId] FROM [dbo].[BatchHeader] WITH(NOLOCK) WHERE [JournalTypeId] = @JournalTypeId AND [MasterCompanyId] = @MasterCompanyId AND CAST([EntryDate] AS DATE) = CAST(GETUTCDATE() AS DATE) AND [StatusId] = @StatusId)
					BEGIN
						IF NOT EXISTS(SELECT JournalBatchHeaderId FROM BatchHeader WITH(NOLOCK))
						BEGIN	
							SET @batch ='001'
							SET @Currentbatch='001'
						END
						ELSE
						BEGIN
							SELECT top 1 @Currentbatch = CASE WHEN CurrentNumber > 0 THEN CAST(CurrentNumber AS BIGINT) + 1 ELSE  1 END 
				   			FROM [dbo].[BatchHeader] WITH(NOLOCK) Order by JournalBatchHeaderId desc 

							IF(CAST(@Currentbatch AS BIGINT) >99)
							BEGIN

								SET @batch = CASE WHEN CAST(@Currentbatch AS BIGINT) > 99 THEN cast(@Currentbatch as VARCHAR(100))
				   				ELSE CONCAT('00', CAST(@Currentbatch AS VARCHAR(50))) END 
							END
							ELSE IF(CAST(@Currentbatch AS BIGINT) >9)
							BEGIN

								SET @batch = CASE WHEN CAST(@Currentbatch AS BIGINT) > 99 THEN cast(@Currentbatch as VARCHAR(100))
				   				ELSE CONCAT('0', CAST(@Currentbatch AS VARCHAR(50))) END 
							END
							ELSE
							BEGIN
								SET @batch = CASE WHEN CAST(@Currentbatch AS BIGINT) > 99 THEN cast(@Currentbatch as VARCHAR(100))
				   				ELSE CONCAT('00', CAST(@Currentbatch AS VARCHAR(50))) END 

							END
						END
						SET @CurrentNumber = CAST(@Currentbatch AS BIGINT) 
						SET @batch = CAST(@JournalTypeCode +' '+cast(@batch as VARCHAR(100)) as VARCHAR(100))
						print @CurrentNumber
				          
						INSERT INTO [dbo].[BatchHeader]
									([BatchName],[CurrentNumber],[EntryDate],[AccountingPeriod],AccountingPeriodId,[StatusId],[StatusName],[JournalTypeId],[JournalTypeName],[TotalDebit],[TotalCredit],[TotalBalance],[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted],[Module])
						VALUES
									(@batch,@CurrentNumber,GETUTCDATE(),@AccountingPeriod,@AccountingPeriodId,@StatusId,@StatusName,@JournalTypeId,@JournalTypename,0,0,0,@MasterCompanyId,@UpdateBy,@UpdateBy,GETUTCDATE(),GETUTCDATE(),1,0,@ModuleName);
            	          
						SELECT @JournalBatchHeaderId = SCOPE_IDENTITY()
						
						UPDATE dbo.BatchHeader SET CurrentNumber=@CurrentNumber  WHERE JournalBatchHeaderId= @JournalBatchHeaderId
					END
					ELSE
					BEGIN
						SELECT @JournalBatchHeaderId=JournalBatchHeaderId,@CurrentPeriodId=isnull(AccountingPeriodId,0) FROM dbo.BatchHeader WITH(NOLOCK)  WHERE JournalTypeId= @JournalTypeId and StatusId=@StatusId
						SELECT @LineNumber = CASE WHEN LineNumber > 0 THEN CAST(LineNumber AS BIGINT) + 1 ELSE  1 END 
				   								FROM [dbo].[BatchDetails] WITH(NOLOCK) WHERE JournalBatchHeaderId=@JournalBatchHeaderId  Order by JournalBatchDetailId desc 
				    
						IF(@CurrentPeriodId =0)
						BEGIN
							UPDATE dbo.BatchHeader SET AccountingPeriodId=@AccountingPeriodId,AccountingPeriod=@AccountingPeriod   WHERE JournalBatchHeaderId= @JournalBatchHeaderId
						END		
						
						SET @IsBatchGenerated = 1;
					END
					
					INSERT INTO [dbo].[BatchDetails]
						([JournalTypeNumber],[CurrentNumber],[DistributionSetupId],[DistributionName],[JournalBatchHeaderId],[LineNumber],[GlAccountId],[GlAccountNumber],[GlAccountName] ,[TransactionDate],[EntryDate],[JournalTypeId],[JournalTypeName],[IsDebit],[DebitAmount] ,[CreditAmount],[ManagementStructureId],[ModuleName],[LastMSLevel],[AllMSlevels],[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate] ,[IsActive] ,[IsDeleted],[AccountingPeriodId],[AccountingPeriod])
					VALUES
						(@JournalTypeNumber,@currentNo,@DistributionSetupId,@DistributionName,@JournalBatchHeaderId,1 ,@GlAccountId ,@GlAccountNumber ,@GlAccountName,GETUTCDATE(),GETUTCDATE(),@JournalTypeId ,@JournalTypename ,
						1,0,0,@ManagementStructureId ,@ModuleName,@LastMSLevel,@AllMSlevels ,@MasterCompanyId,@UpdateBy,@UpdateBy,GETUTCDATE(),GETUTCDATE(),1,0,@AccountingPeriodId,@AccountingPeriod)

					SET @JournalBatchDetailId = SCOPE_IDENTITY()

					IF(@IsBypassAccounting = 0)
					BEGIN

					INSERT INTO [dbo].[CommonBatchDetails]
						([JournalBatchDetailId],[JournalTypeNumber],[CurrentNumber],[DistributionSetupId],[DistributionName],[JournalBatchHeaderId],[LineNumber],[GlAccountId],[GlAccountNumber],[GlAccountName] ,[TransactionDate],[EntryDate] ,[JournalTypeId],[JournalTypeName],[IsDebit],[DebitAmount] ,[CreditAmount],[ManagementStructureId]
						,[ModuleName],[LastMSLevel],[AllMSlevels],[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate] ,[IsActive] ,[IsDeleted],[LotId],[LotNumber],[ReferenceNumber],[ReferenceName],[LocalCurrency],[FXRate],[ForeignCurrency],[ReferenceId],[ReferenceModule])
					VALUES
						(@JournalBatchDetailId,@JournalTypeNumber,@currentNo,@DistributionSetupId,@DistributionName,@JournalBatchHeaderId,1 ,@GlAccountId ,@GlAccountNumber ,@GlAccountName,GETUTCDATE(),GETUTCDATE(),@JournalTypeId ,@JournalTypename ,
						CASE WHEN @CrDrType = 1 THEN 1 ELSE 0 END,
						CASE WHEN @CrDrType = 1 THEN @Amount ELSE 0 END,
						CASE WHEN @CrDrType = 1 THEN 0 ELSE @Amount END,
						@ManagementStructureId ,@ModuleName,@LastMSLevel,@AllMSlevels ,@MasterCompanyId,@UpdateBy,@UpdateBy,GETUTCDATE(),GETUTCDATE(),1,0,@LotId,@LotNumber,@WorkOrderNumber,@CustomerName,@CurrencyCode,@FXRate,@CurrencyCode,@ReferenceId,@ReferenceModule)

					SET @CommonJournalBatchDetailId = SCOPE_IDENTITY()

					-----  Accounting MS Entry  -----

					EXEC [dbo].[PROCAddUpdateAccountingBatchMSData] @CommonJournalBatchDetailId,@ManagementStructureId,@MasterCompanyId,@UpdateBy,@AccountMSModuleId,1; 
										
					INSERT INTO [dbo].[WorkOrderBatchDetails]([JournalBatchDetailId],[JournalBatchHeaderId],[ReferenceId],[ReferenceName],[MPNPartId],[MPNName],[PiecePNId],[PiecePN],[CustomerId],[CustomerName] ,[InvoiceId],[InvoiceName],[ARControlNum] ,[CustRefNumber] ,[Qty],[UnitPrice],[LaborHrs],[DirectLaborCost],[OverheadCost],[CommonJournalBatchDetailId],[StocklineId],[StocklineNumber],[IsWorkOrder])
					VALUES (@JournalBatchDetailId,@JournalBatchHeaderId,@ReferenceId ,@WorkOrderNumber ,@ReferencePartId,@MPNName,0,NULL,@CustomerId ,@CustomerName,null ,null,null,@CustRefNumber,@Qty,@UnitPrice,@LaborHrs,@DirectLaborCost,@OverheadCost,@CommonJournalBatchDetailId,@StocklineId,@StocklineNumber,1)
					
					END

					SELECT TOP 1 @DistributionSetupId=ID,
					             @DistributionName=Name,
								 @JournalTypeId =JournalTypeId,
								 @CrDrType = CRDRType, 
								 @IsBypassAccounting = ISNULL([IsBypassAccounting],0)
							FROM dbo.DistributionSetup WITH(NOLOCK)  
						   WHERE UPPER(DistributionSetupCode) =UPPER('TDSWOWIPPARTS') 
						     AND [DistributionMasterId] = @DistributionMasterId 
						     AND [MasterCompanyId] = @MasterCompanyId
				    
					SELECT @GlAccountId = SL.WorkInProgressGLAccId	FROM [dbo].[Stockline] SL WITH(NOLOCK) WHERE SL.[StockLineId] = @StocklineId;
					
					SELECT @GlAccountNumber=AccountCode,
					       @GlAccountName=AccountName 
					  FROM dbo.GLAccount WITH(NOLOCK) WHERE GLAccountId=@GlAccountId

					SET @GlAccountId = ISNULL(@GlAccountId,0) 

					IF(@IsBypassAccounting = 0)
					BEGIN

					INSERT INTO [dbo].[CommonBatchDetails](JournalBatchDetailId,JournalTypeNumber,CurrentNumber,DistributionSetupId,DistributionName,[JournalBatchHeaderId],[LineNumber],[GlAccountId],[GlAccountNumber],[GlAccountName] ,[TransactionDate],[EntryDate] ,[JournalTypeId],[JournalTypeName],[IsDebit],[DebitAmount] ,[CreditAmount],[ManagementStructureId],[ModuleName],LastMSLevel,AllMSlevels,[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate] ,[IsActive] ,[IsDeleted],[LotId],[LotNumber],[ReferenceNumber],[ReferenceName],[LocalCurrency],[FXRate],[ForeignCurrency],[ReferenceId],[ReferenceModule])
					VALUES(@JournalBatchDetailId,@JournalTypeNumber,@currentNo,@DistributionSetupId,@DistributionName,@JournalBatchHeaderId,1 ,@GlAccountId ,@GlAccountNumber ,@GlAccountName,GETUTCDATE(),GETUTCDATE(),@JournalTypeId ,@JournalTypename ,
						CASE WHEN @CrDrType = 1 THEN 1 ELSE 0 END,
						CASE WHEN @CrDrType = 1 THEN @Amount ELSE 0 END,
						CASE WHEN @CrDrType = 1 THEN 0 ELSE @Amount END,@ManagementStructureId ,@ModuleName,@LastMSLevel,@AllMSlevels ,@MasterCompanyId,@UpdateBy,@UpdateBy,GETUTCDATE(),GETUTCDATE(),1,0,@LotId,@LotNumber,@WorkOrderNumber,@CustomerName,@CurrencyCode,@FXRate,@CurrencyCode,@ReferenceId,@ReferenceModule)

					SET @CommonJournalBatchDetailId = SCOPE_IDENTITY()
					
					-----  Accounting MS Entry  -----

					EXEC [dbo].[PROCAddUpdateAccountingBatchMSData] @CommonJournalBatchDetailId,@ManagementStructureId,@MasterCompanyId,@UpdateBy,@AccountMSModuleId,1; 
										
					INSERT INTO [dbo].[WorkOrderBatchDetails](JournalBatchDetailId,[JournalBatchHeaderId],[ReferenceId],[ReferenceName],[MPNPartId],[MPNName],[PiecePNId],[PiecePN],[CustomerId],[CustomerName] ,[InvoiceId],[InvoiceName],[ARControlNum] ,[CustRefNumber] ,[Qty],[UnitPrice],[LaborHrs],[DirectLaborCost],[OverheadCost],[CommonJournalBatchDetailId],[StocklineId],[StocklineNumber],[IsWorkOrder])
					VALUES(@JournalBatchDetailId,@JournalBatchHeaderId,@ReferenceId ,@WorkOrderNumber ,@ReferencePartId,@MPNName,0,NULL,@CustomerId ,@CustomerName,NULL ,NULL,NULL,@CustRefNumber,@Qty,@UnitPrice,@LaborHrs,@DirectLaborCost,@OverheadCost,@CommonJournalBatchDetailId,@StocklineId,@StocklineNumber,1)

					END

					SET @TotalDebit=0;
					SET @TotalCredit=0;

					SELECT @TotalDebit = SUM(DebitAmount),
					       @TotalCredit = SUM(CreditAmount) 
					  FROM [dbo].[CommonBatchDetails] WITH(NOLOCK) 
					  WHERE [JournalBatchDetailId]=@JournalBatchDetailId GROUP BY JournalBatchDetailId
					
					UPDATE [dbo].[BatchDetails] 
					   SET [DebitAmount] = @TotalDebit,
					       [CreditAmount]=@TotalCredit,
						   [UpdatedDate]=GETUTCDATE(),
						   [UpdatedBy]=@UpdateBy 
					 WHERE [JournalBatchDetailId]=@JournalBatchDetailId;

					 --AutoPost Batch
					IF(@IsAutoPost = 1 AND @IsBatchGenerated = 0)
					BEGIN
						EXEC [dbo].[UpdateToPostFullBatch] @JournalBatchHeaderId,@UpdateBy;
					END
					IF(@IsAutoPost = 1 AND @IsBatchGenerated = 1)
					BEGIN
						EXEC [dbo].[USP_UpdateCommonBatchStatus] @JournalBatchDetailId,@UpdateBy,@AccountingPeriodId,@AccountingPeriod;
					END
				END
				
				SELECT @TotalDebit = SUM([DebitAmount]),@TotalCredit = SUM([CreditAmount]) FROM [dbo].[BatchDetails] WITH(NOLOCK) WHERE [JournalBatchHeaderId] = @JournalBatchHeaderId AND [IsDeleted] = 0 GROUP BY [JournalBatchHeaderId]
			   	         
			    SET @TotalBalance = @TotalDebit - @TotalCredit
				         
			    UPDATE [dbo].[BatchHeader] SET [TotalDebit] = @TotalDebit,[TotalCredit] = @TotalCredit,[TotalBalance] = @TotalBalance,[UpdatedDate]=GETUTCDATE(),[UpdatedBy]=@UpdateBy WHERE [JournalBatchHeaderId] = @JournalBatchHeaderId
	            
				UPDATE [dbo].[CodePrefixes] SET [CurrentNummber] = @currentNo WHERE [CodeTypeId] = @CodeTypeId AND MasterCompanyId = @MasterCompanyId

			END
									
			IF OBJECT_ID(N'tempdb..#tmpCodePrefixes') IS NOT NULL
			BEGIN
				DROP TABLE #tmpCodePrefixes 
			END

		END

	END
	COMMIT  TRANSACTION
	END TRY    
	BEGIN CATCH      
		IF @@trancount > 0
			PRINT 'ROLLBACK'
			ROLLBACK TRAN;
			DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            , @AdhocComments     VARCHAR(150)    = 'USP_TearDownWOBatchTriggerBasedonDistribution' 
			, @ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@DistributionMasterId, 0) AS VARCHAR(100))  
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