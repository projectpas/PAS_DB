/*************************************************************           
 ** File:   [USP_BatchTriggerBasedonDistributionForWO]
 ** Author:  Subhash Saliya
 ** Description: This stored procedure is used for BatchTrigger Based on Distribution For WO
 ** Purpose:         
 ** Date:   07/18/2024	[mm/dd/yyyy]      
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date			Author				Change Description            
 ** --   --------		-------				--------------------------------          
    1    07/18/2024		Devendra Shekh		Created
    2    08/05/2024		Devendra Shekh		JE Number issue Resolved
	3    18/09/2024		AMIT GHEDIYA		Added for AutoPost Batch

************************************************************************/
CREATE   PROCEDURE [dbo].[USP_BatchTriggerBasedonDistributionForWO]
(
	@tbl_BatchTriggerWorkOrderType BatchTriggerWorkOrderType READONLY
)
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;
	BEGIN TRY
	BEGIN TRANSACTION
	BEGIN

		IF OBJECT_ID(N'tempdb..#BatchTriggerWorkOrderType') IS NOT NULL
        BEGIN
            DROP TABLE #BatchTriggerWorkOrderType
        END

        CREATE TABLE #BatchTriggerWorkOrderType
        (
			[BatchTriggerWorkOrderID] BIGINT NOT NULL IDENTITY,
			[DistributionMasterId] BIGINT NULL,
			[ReferenceId] BIGINT NULL,
			[ReferencePartId] BIGINT NULL,
			[ReferencePieceId] BIGINT NULL,
			[InvoiceId] BIGINT NULL,
			[StocklineId] BIGINT NULL,
			[Qty] INT NULL,
			[laborType] VARCHAR(200) NULL,
			[Issued]  BIT NULL,
			[Amount] DECIMAL(18,2) NULL,
			[ModuleName] VARCHAR(200) NULL,
			[MasterCompanyId] INT NULL,
			[UpdateBy] VARCHAR(200) NULL
        )

		DECLARE @DistributionMasterId BIGINT=NULL,
		@ReferenceId BIGINT=NULL,
		@ReferencePartId BIGINT=NULL,
		@ReferencePieceId BIGINT=NULL,
		@InvoiceId BIGINT=NULL,
		@StocklineId BIGINT=NULL,
		@Qty INT=0,
		@laborType VARCHAR(200)=NULL,
		@issued  BIT=0,
		@Amount DECIMAL(18,2)=0,
		@ModuleName VARCHAR(200)=NULL,
		@MasterCompanyId INT=0,
		@UpdateBy VARCHAR(200)=NULL;
		DECLARE @TotalRecords BIGINT = 0;
		DECLARE @StartCount BIGINT = 1;
		DECLARE @TotalAmount decimal(18,2)=0

		INSERT INTO #BatchTriggerWorkOrderType
		( [DistributionMasterId], [ReferenceId], [ReferencePartId], [ReferencePieceId], [InvoiceId], [StocklineId], [Qty], [laborType], [Issued], [Amount], [ModuleName], [MasterCompanyId], [UpdateBy] )
		SELECT [DistributionMasterId], [ReferenceId], [ReferencePartId], [ReferencePieceId], [InvoiceId], [StocklineId], [Qty], [laborType], [Issued], [Amount], [ModuleName], [MasterCompanyId], [UpdateBy]
		FROM @tbl_BatchTriggerWorkOrderType;

		SELECT @TotalRecords = COUNT([BatchTriggerWorkOrderID]), @TotalAmount = SUM([Amount]) FROM #BatchTriggerWorkOrderType;

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
		DECLARE @WopJounralTypeid BIGINT=0;
		DECLARE @StocklineNumber VARCHAR(100)
		DECLARE @UnEarnedAmount DECIMAL(18,2)=0
		DECLARE @AccountMSModuleId INT = 0		
		
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
		DECLARE @CreateNewBatch BIT = 0;
		DECLARE @LaborNewBatchCount INT = 0;
		DECLARE @isNewJENum BIT = 0;
		DECLARE @IsAutoPost INT = 0;

		WHILE(@TotalRecords >= @StartCount AND @TotalAmount <> 0)
		BEGIN

			SELECT	@DistributionMasterId = [DistributionMasterId], 
					@ReferenceId = [ReferenceId], 
					@ReferencePartId = [ReferencePartId], 
					@ReferencePieceId = [ReferencePieceId], 
					@InvoiceId = [InvoiceId], 
					@StocklineId = [StocklineId], 
					@Qty = [Qty], 
					@laborType = [laborType], 
					@issued = [Issued], 
					@Amount = [Amount], 
					@ModuleName = [ModuleName], 
					@MasterCompanyId = [MasterCompanyId], 
					@UpdateBy = [UpdateBy]
			FROM #BatchTriggerWorkOrderType WHERE [BatchTriggerWorkOrderID] = @StartCount;

			SELECT @IsAccountByPass = [IsAccountByPass] FROM [dbo].[MasterCompany] WITH(NOLOCK)  WHERE MasterCompanyId= @MasterCompanyId
			SELECT @DistributionCode = [DistributionCode] FROM [dbo].[DistributionMaster] WITH(NOLOCK)  WHERE ID= @DistributionMasterId
			SELECT @StatusId =Id, @StatusName= [name] FROM [dbo].[BatchStatus] WITH(NOLOCK)  WHERE [Name] = 'Open'
			SELECT top 1 @JournalTypeId = JournalTypeId FROM [dbo].[DistributionSetup] WITH(NOLOCK)  WHERE DistributionMasterId =@DistributionMasterId AND MasterCompanyId=@MasterCompanyId
			SELECT @JournalBatchHeaderId =JournalBatchHeaderId FROM [dbo].[BatchHeader] WITH(NOLOCK)  WHERE JournalTypeId= @JournalTypeId AND StatusId=@StatusId
			SELECT @JournalTypeCode = JournalTypeCode,@JournalTypename = JournalTypeName FROM [dbo].[JournalType] WITH(NOLOCK)  WHERE ID= @JournalTypeId
			SELECT @WopJounralTypeid = ID FROM [dbo].[JournalType] WITH(NOLOCK)  WHERE JournalTypeCode = 'WIP'
			SELECT @AccountMSModuleId = [ManagementStructureModuleId] FROM [dbo].[ManagementStructureModule] WITH(NOLOCK) WHERE [ModuleName] ='Accounting';
			SET @isNewJENum = 0;
			SET @JournalBatchDetailId = CASE WHEN @StartCount = 1 THEN 0 ELSE @JournalBatchDetailId END;
			
			IF((@JournalTypeCode ='WIP' OR @JournalTypeCode ='WOI' OR @JournalTypeCode ='MRO-WO' OR @JournalTypeCode ='FGI') AND @IsAccountByPass=0)
			BEGIN 
				SELECT @WorkOrderNumber = WorkOrderNum,
					   @CustomerId=CustomerId,
					   @CustomerName= CustomerName 
				  FROM [dbo].[WorkOrder] WITH(NOLOCK)  
				  WHERE [WorkOrderId] = @ReferenceId
		              
				IF(@ReferencePartId = 0)
				BEGIN
					SELECT TOP 1 @partId=WorkOrderPartNoId 
					  FROM [dbo].[WorkOrderWorkFlow] 
					  WITH(NOLOCK) WHERE WorkOrderId=@ReferenceId
				END
				ELSE 
				BEGIN
					SELECT @partId=WorkOrderPartNoId 
					  FROM [dbo].[WorkOrderWorkFlow] WITH(NOLOCK) 
					  WHERE WorkFlowWorkOrderId=@ReferencePartId
				END

				SELECT @ManagementStructureId = WOP.[ManagementStructureId], 
					   @ItemmasterId = WOP.[ItemMasterId], 
					   @CustRefNumber = WOP.[CustomerReference]					  
				  FROM [dbo].[WorkOrderPartNumber] WOP WITH(NOLOCK) 			  
				  WHERE WOP.[WorkOrderId] = @ReferenceId AND WOP.[ID] = @partId;

				SELECT @MPNName = partnumber 
				  FROM [dbo].[ItemMaster] WITH(NOLOCK)  
				 WHERE ItemMasterId=@ItemmasterId 

				SELECT @LastMSLevel=LastMSLevel,
					   @AllMSlevels=AllMSlevels 
				  FROM [dbo].[WorkOrderManagementStructureDetails] WITH(NOLOCK) 
				  WHERE ReferenceID=@partId

				SELECT TOP 1  @AccountingPeriodId=acc.AccountingCalendarId,
							  @AccountingPeriod=PeriodName 
				FROM [dbo].[EntityStructureSetup] est WITH(NOLOCK) 
				INNER JOIN [dbo].[ManagementStructureLevel] msl WITH(NOLOCK) on est.Level1Id = msl.ID 
				INNER JOIN [dbo].[AccountingCalendar] acc WITH(NOLOCK) on msl.LegalEntityId = acc.LegalEntityId and acc.IsDeleted =0
				WHERE est.EntityStructureId = @ManagementStructureId and acc.MasterCompanyId=@MasterCompanyId  and CAST(GETUTCDATE() as date)   >= CAST(FromDate as date) and  CAST(GETUTCDATE() as date) <= CAST(ToDate as date)
		    
				SET @ReferencePartId=@partId	

				IF OBJECT_ID(N'tempdb..#tmpCodePrefixes') IS NOT NULL
				BEGIN
					DROP TABLE #tmpCodePrefixes
				END
				
				CREATE TABLE #tmpCodePrefixes
				(
					ID BIGINT NOT NULL IDENTITY, 
					CodePrefixId BIGINT NULL,
					CodeTypeId BIGINT NULL,
					CurrentNumber BIGINT NULL,
					CodePrefix VARCHAR(50) NULL,
					CodeSufix VARCHAR(50) NULL,
					StartsFrom BIGINT NULL,
				)

				INSERT INTO #tmpCodePrefixes (CodePrefixId,CodeTypeId,CurrentNumber, CodePrefix, CodeSufix, StartsFrom) 
				SELECT CodePrefixId, CP.CodeTypeId, CurrentNummber, CodePrefix, CodeSufix, StartsFrom 
				FROM dbo.CodePrefixes CP WITH(NOLOCK) JOIN dbo.CodeTypes CT ON CP.CodeTypeId = CT.CodeTypeId
				WHERE CT.CodeTypeId IN (@CodeTypeId) AND CP.MasterCompanyId = @MasterCompanyId AND CP.IsActive = 1 AND CP.IsDeleted = 0;

				IF(EXISTS (SELECT 1 FROM #tmpCodePrefixes WHERE CodeTypeId = @CodeTypeId))
				BEGIN 
					IF(@JournalBatchDetailId = 0 AND @Amount <> 0)
					BEGIN
						SET @isNewJENum = 1;
						SELECT 
						@currentNo = CASE WHEN CurrentNumber > 0 THEN CAST(CurrentNumber AS BIGINT) + 1 
							ELSE CAST(StartsFrom AS BIGINT) + 1 END 
						FROM #tmpCodePrefixes WHERE CodeTypeId = @CodeTypeId

						SET @JournalTypeNumber = (SELECT * FROM dbo.udfGenerateCodeNumber(@currentNo,(SELECT CodePrefix FROM #tmpCodePrefixes WHERE CodeTypeId = @CodeTypeId), (SELECT CodeSufix FROM #tmpCodePrefixes WHERE CodeTypeId = @CodeTypeId)))
					END
				END
				ELSE 
				BEGIN
					ROLLBACK TRAN;
				END

				IF(UPPER(@DistributionCode) = UPPER('WOMATERIALGRIDTAB'))
				BEGIN				
					SELECT @PieceItemmasterId = WMS.[ItemMasterId],
						   @UnitPrice = WMS.[UnitCost],
						   @Amount = ISNULL((@Qty * WMS.[UnitCost]),0),
						   @LotId = STL.[LotId],
						   @LotNumber = LO.[LotNumber]					   
					  FROM [dbo].[WorkOrderMaterialStockLine] WMS WITH(NOLOCK) 
					  LEFT JOIN [dbo].[Stockline] STL ON STL.[StockLineId] = WMS.[StockLineId]
					  LEFT JOIN [dbo].[Lot] LO ON LO.[LotId] = STL.[LotId]		
					 WHERE WMS.[StockLineId] = @StocklineId;

					SET @JournalBatchDetailId = CASE WHEN @StartCount = 1 THEN 0 ELSE @JournalBatchDetailId END;
				 						        
					SELECT @PiecePN = partnumber 
					  FROM [dbo].[ItemMaster] WITH(NOLOCK)  
					 WHERE [ItemMasterId]=@PieceItemmasterId;

					SELECT top 1 @DistributionSetupId=ID,
								 @DistributionName=Name,
								 @JournalTypeId =JournalTypeId,
								 @GlAccountId=GlAccountId,
								 @GlAccountNumber=GlAccountNumber,
								 @GlAccountName=GlAccountName,
								 @CrDrType = CRDRType,
								 @IsAutoPost = ISNULL(IsAutoPost,0)
					FROM [dbo].[DistributionSetup] WITH(NOLOCK)  
					WHERE UPPER([DistributionSetupCode]) =UPPER('WIPPARTS') 
					  AND [DistributionMasterId] =@DistributionMasterId 
					  AND [MasterCompanyId] = @MasterCompanyId;

					IF EXISTS(SELECT 1 FROM [dbo].[DistributionSetup] WITH(NOLOCK) WHERE [DistributionMasterId] =@DistributionMasterId AND [MasterCompanyId]=@MasterCompanyId AND ISNULL([GlAccountId],0) = 0)
					BEGIN
						SET @ValidDistribution = 0;
					END

					IF EXISTS(SELECT 1 FROM [dbo].[Stockline] WITH(NOLOCK) WHERE [StockLineId]=@StocklineId AND ISNULL([GlAccountId],0) = 0)
					BEGIN
						SET @ValidDistribution = 0;
					END

					IF(@issued = 1 AND @Amount > 0 AND @ValidDistribution = 1)
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
				   				FROM BatchHeader WITH(NOLOCK) Order by JournalBatchHeaderId desc 

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
							
							--AutoPost Batch
							IF(@IsAutoPost = 1)
							BEGIN
								EXEC [dbo].[UpdateToPostFullBatch] @JournalBatchHeaderId,@UpdateBy;
							END
						END
						ELSE
						BEGIN
							SELECT @JournalBatchHeaderId=JournalBatchHeaderId,@CurrentPeriodId=isnull(AccountingPeriodId,0) FROM BatchHeader WITH(NOLOCK)  WHERE JournalTypeId= @JournalTypeId and StatusId=@StatusId
							SELECT @LineNumber = CASE WHEN LineNumber > 0 THEN CAST(LineNumber AS BIGINT) + 1 ELSE  1 END 
				   									FROM BatchDetails WITH(NOLOCK) WHERE JournalBatchHeaderId=@JournalBatchHeaderId  Order by JournalBatchDetailId desc 
				    
							IF(@CurrentPeriodId =0)
							BEGIN
								UPDATE dbo.BatchHeader SET AccountingPeriodId=@AccountingPeriodId,AccountingPeriod=@AccountingPeriod   WHERE JournalBatchHeaderId= @JournalBatchHeaderId
							END
							
							--AutoPost Batch
							IF(@IsAutoPost = 1)
							BEGIN
								EXEC [dbo].[UpdateToPostFullBatch] @JournalBatchHeaderId,@UpdateBy;
							END
						END
					
						IF(@JournalBatchDetailId = 0)
						BEGIN
							INSERT INTO [dbo].[BatchDetails]
							([JournalTypeNumber],[CurrentNumber],[DistributionSetupId],[DistributionName],[JournalBatchHeaderId],[LineNumber],[GlAccountId],[GlAccountNumber],[GlAccountName] ,[TransactionDate],[EntryDate],[JournalTypeId],[JournalTypeName],[IsDebit],[DebitAmount] ,[CreditAmount],[ManagementStructureId],[ModuleName],[LastMSLevel],[AllMSlevels],[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate] ,[IsActive] ,[IsDeleted],[AccountingPeriodId],[AccountingPeriod])
							VALUES
							(@JournalTypeNumber,@currentNo,@DistributionSetupId,@DistributionName,@JournalBatchHeaderId,1 ,@GlAccountId ,@GlAccountNumber ,@GlAccountName,GETUTCDATE(),GETUTCDATE(),@JournalTypeId ,@JournalTypename ,
							1,0,0,@ManagementStructureId ,@ModuleName,@LastMSLevel,@AllMSlevels ,@MasterCompanyId,@UpdateBy,@UpdateBy,GETUTCDATE(),GETUTCDATE(),1,0,@AccountingPeriodId,@AccountingPeriod)

							SET @JournalBatchDetailId = SCOPE_IDENTITY()
						END

						INSERT INTO [dbo].[CommonBatchDetails]
							([JournalBatchDetailId],[JournalTypeNumber],[CurrentNumber],[DistributionSetupId],[DistributionName],[JournalBatchHeaderId],[LineNumber],[GlAccountId],[GlAccountNumber],[GlAccountName] ,[TransactionDate],[EntryDate] ,[JournalTypeId],[JournalTypeName],[IsDebit],[DebitAmount] ,[CreditAmount],[ManagementStructureId]
							,[ModuleName],[LastMSLevel],[AllMSlevels],[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate] ,[IsActive] ,[IsDeleted],[LotId],[LotNumber])
						VALUES
							(@JournalBatchDetailId,@JournalTypeNumber,@currentNo,@DistributionSetupId,@DistributionName,@JournalBatchHeaderId,1 ,@GlAccountId ,@GlAccountNumber ,@GlAccountName,GETUTCDATE(),GETUTCDATE(),@JournalTypeId ,@JournalTypename ,
							CASE WHEN @CrDrType = 1 THEN 1 ELSE 0 END,
							CASE WHEN @CrDrType = 1 THEN @Amount ELSE 0 END,
							CASE WHEN @CrDrType = 1 THEN 0 ELSE @Amount END,
							@ManagementStructureId ,@ModuleName,@LastMSLevel,@AllMSlevels ,@MasterCompanyId,@UpdateBy,@UpdateBy,GETUTCDATE(),GETUTCDATE(),1,0,@LotId,@LotNumber)

						SET @CommonJournalBatchDetailId = SCOPE_IDENTITY()

						-----  Accounting MS Entry  -----

						EXEC [dbo].[PROCAddUpdateAccountingBatchMSData] @CommonJournalBatchDetailId,@ManagementStructureId,@MasterCompanyId,@UpdateBy,@AccountMSModuleId,1; 
										
						INSERT INTO [dbo].[WorkOrderBatchDetails]([JournalBatchDetailId],[JournalBatchHeaderId],[ReferenceId],[ReferenceName],[MPNPartId],[MPNName],[PiecePNId],[PiecePN],[CustomerId],[CustomerName] ,[InvoiceId],[InvoiceName],[ARControlNum] ,[CustRefNumber] ,[Qty],[UnitPrice],[LaborHrs],[DirectLaborCost],[OverheadCost],[CommonJournalBatchDetailId],[StocklineId],[StocklineNumber],[IsWorkOrder])
						VALUES (@JournalBatchDetailId,@JournalBatchHeaderId,@ReferenceId ,@WorkOrderNumber ,@ReferencePartId,@MPNName,@ReferencePieceId,@PiecePN,@CustomerId ,@CustomerName,null ,null,null,@CustRefNumber,@Qty,@UnitPrice,@LaborHrs,@DirectLaborCost,@OverheadCost,@CommonJournalBatchDetailId,@StocklineId,@StocklineNumber,1)
						
						SELECT TOP 1 @DistributionSetupId=ID,
									 @DistributionName=Name,
									 @JournalTypeId =JournalTypeId,
									 @CrDrType = CRDRType 
								FROM dbo.DistributionSetup WITH(NOLOCK)  
							   WHERE UPPER(DistributionSetupCode) =UPPER('INVENTORYPARTS') 
								 AND [DistributionMasterId] = @DistributionMasterId 
								 AND [MasterCompanyId] = @MasterCompanyId

						SELECT @GlAccountId=GlAccountId 
						  FROM [dbo].[Stockline] WITH(NOLOCK) 
						 WHERE [StockLineId]=@StocklineId
					
						SELECT @GlAccountNumber=AccountCode,
							   @GlAccountName=AccountName 
						  FROM dbo.GLAccount WITH(NOLOCK) WHERE GLAccountId=@GlAccountId

						SET @GlAccountId = ISNULL(@GlAccountId,0) 

						INSERT INTO [dbo].[CommonBatchDetails]
							(JournalBatchDetailId,JournalTypeNumber,CurrentNumber,DistributionSetupId,DistributionName,[JournalBatchHeaderId],[LineNumber],[GlAccountId],[GlAccountNumber],[GlAccountName] ,[TransactionDate],[EntryDate] ,[JournalTypeId],[JournalTypeName],[IsDebit],[DebitAmount] ,[CreditAmount],[ManagementStructureId],[ModuleName],LastMSLevel,AllMSlevels,[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate] ,[IsActive] ,[IsDeleted],[LotId],[LotNumber])
						VALUES
							(@JournalBatchDetailId,@JournalTypeNumber,@currentNo,@DistributionSetupId,@DistributionName,@JournalBatchHeaderId,1 ,@GlAccountId ,@GlAccountNumber ,@GlAccountName,GETUTCDATE(),GETUTCDATE(),@JournalTypeId ,@JournalTypename ,
							CASE WHEN @CrDrType = 1 THEN 1 ELSE 0 END,
							CASE WHEN @CrDrType = 1 THEN @Amount ELSE 0 END,
							CASE WHEN @CrDrType = 1 THEN 0 ELSE @Amount END,@ManagementStructureId ,@ModuleName,@LastMSLevel,@AllMSlevels ,@MasterCompanyId,@UpdateBy,@UpdateBy,GETUTCDATE(),GETUTCDATE(),1,0,@LotId,@LotNumber)

						SET @CommonJournalBatchDetailId = SCOPE_IDENTITY()
					
						-----  Accounting MS Entry  -----

						EXEC [dbo].[PROCAddUpdateAccountingBatchMSData] @CommonJournalBatchDetailId,@ManagementStructureId,@MasterCompanyId,@UpdateBy,@AccountMSModuleId,1; 
										
						INSERT INTO [dbo].[WorkOrderBatchDetails]
							(JournalBatchDetailId,[JournalBatchHeaderId],[ReferenceId],[ReferenceName],[MPNPartId],[MPNName],[PiecePNId],[PiecePN],[CustomerId],[CustomerName] ,[InvoiceId],[InvoiceName],[ARControlNum] ,[CustRefNumber] ,[Qty],[UnitPrice],[LaborHrs],[DirectLaborCost],[OverheadCost],[CommonJournalBatchDetailId],[StocklineId],[StocklineNumber],[IsWorkOrder])
						VALUES
							(@JournalBatchDetailId,@JournalBatchHeaderId,@ReferenceId ,@WorkOrderNumber ,@ReferencePartId,@MPNName,@ReferencePieceId,@PiecePN,@CustomerId ,@CustomerName,null ,null,null,@CustRefNumber,@Qty,@UnitPrice,@LaborHrs,@DirectLaborCost,@OverheadCost,@CommonJournalBatchDetailId,@StocklineId,@StocklineNumber,1)

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
					END
					ELSE
					BEGIN
						IF EXISTS(SELECT 1 FROM dbo.DistributionSetup WITH(NOLOCK) WHERE DistributionMasterId =@DistributionMasterId AND MasterCompanyId=@MasterCompanyId AND ISNULL(GlAccountId,0) = 0)
						BEGIN
							SET @ValidDistribution = 0;
						END

						IF EXISTS(SELECT 1 FROM dbo.Stockline WITH(NOLOCK) WHERE StockLineId=@StocklineId AND ISNULL(GlAccountId,0) = 0)
						BEGIN
							SET @ValidDistribution = 0;
						END
					
						IF(@Amount > 0 AND @ValidDistribution = 1)
						BEGIN
						
							IF NOT EXISTS(SELECT JournalBatchHeaderId FROM BatchHeader WITH(NOLOCK)  WHERE JournalTypeId= @JournalTypeId and MasterCompanyId=@MasterCompanyId and  CAST(EntryDate AS DATE) = CAST(GETUTCDATE() AS DATE)and StatusId=@StatusId)
							BEGIN
								IF NOT EXISTS(SELECT JournalBatchHeaderId FROM BatchHeader WITH(NOLOCK))
								BEGIN	
									SET @batch ='001'
									SET @Currentbatch='001'
								END
								ELSE
								BEGIN
									SELECT top 1 @Currentbatch = CASE WHEN CurrentNumber > 0 THEN CAST(CurrentNumber AS BIGINT) + 1 ELSE  1 END 
				   					FROM BatchHeader WITH(NOLOCK) Order by JournalBatchHeaderId desc 

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
							
								UPDATE dbo.BatchHeader SET CurrentNumber=@CurrentNumber  WHERE JournalBatchHeaderId= @JournalBatchHeaderId;
								
								--AutoPost Batch
								IF(@IsAutoPost = 1)
								BEGIN
									EXEC [dbo].[UpdateToPostFullBatch] @JournalBatchHeaderId,@UpdateBy;
								END
							END
							ELSE
							BEGIN
								SELECT @JournalBatchHeaderId=JournalBatchHeaderId,@CurrentPeriodId=isnull(AccountingPeriodId,0) FROM BatchHeader WITH(NOLOCK)  WHERE JournalTypeId= @JournalTypeId and StatusId=@StatusId
								SELECT @LineNumber = CASE WHEN LineNumber > 0 THEN CAST(LineNumber AS BIGINT) + 1 ELSE  1 END 
				   										FROM BatchDetails WITH(NOLOCK) WHERE JournalBatchHeaderId=@JournalBatchHeaderId  Order by JournalBatchDetailId desc 
				    
								IF(@CurrentPeriodId =0)
								BEGIN
									Update BatchHeader set AccountingPeriodId=@AccountingPeriodId,AccountingPeriod=@AccountingPeriod   WHERE JournalBatchHeaderId= @JournalBatchHeaderId
								END
								
								--AutoPost Batch
								IF(@IsAutoPost = 1)
								BEGIN
									EXEC [dbo].[UpdateToPostFullBatch] @JournalBatchHeaderId,@UpdateBy;
								END
							END

							IF(@JournalBatchDetailId = 0)
							BEGIN
								INSERT INTO [dbo].[BatchDetails]
								(JournalTypeNumber,CurrentNumber,DistributionSetupId,DistributionName,[JournalBatchHeaderId],[LineNumber],[GlAccountId],[GlAccountNumber],[GlAccountName] ,[TransactionDate],[EntryDate],[JournalTypeId],
								[JournalTypeName],[IsDebit],[DebitAmount] ,[CreditAmount],[ManagementStructureId],[ModuleName],LastMSLevel,AllMSlevels,[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate] ,[IsActive] ,[IsDeleted],[AccountingPeriodId],[AccountingPeriod])
								VALUES
								(@JournalTypeNumber,@currentNo,@DistributionSetupId,@DistributionName,@JournalBatchHeaderId,1 ,@GlAccountId ,@GlAccountNumber ,@GlAccountName,GETUTCDATE(),GETUTCDATE(),@JournalTypeId ,@JournalTypename ,
								1,0,0,@ManagementStructureId ,@ModuleName,@LastMSLevel,@AllMSlevels ,@MasterCompanyId,@UpdateBy,@UpdateBy,GETUTCDATE(),GETUTCDATE(),1,0,@AccountingPeriodId,@AccountingPeriod)

								SET @JournalBatchDetailId=SCOPE_IDENTITY()
							END

							INSERT INTO [dbo].[CommonBatchDetails]
								([JournalBatchDetailId],[JournalTypeNumber],[CurrentNumber],[DistributionSetupId],[DistributionName],[JournalBatchHeaderId],[LineNumber],[GlAccountId],[GlAccountNumber],[GlAccountName] ,[TransactionDate],[EntryDate] ,[JournalTypeId],[JournalTypeName],[IsDebit],[DebitAmount] ,[CreditAmount],[ManagementStructureId],[ModuleName],[LastMSLevel],[AllMSlevels],[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate] ,[IsActive] ,[IsDeleted],[LotId],[LotNumber])
							VALUES
								(@JournalBatchDetailId,@JournalTypeNumber,@currentNo,@DistributionSetupId,@DistributionName,@JournalBatchHeaderId,1 ,@GlAccountId ,@GlAccountNumber ,@GlAccountName,GETUTCDATE(),GETUTCDATE(),@JournalTypeId ,@JournalTypename ,
								CASE WHEN @CrDrType = 0 THEN 1 ELSE 0 END,
								CASE WHEN @CrDrType = 0 THEN @Amount ELSE 0 END,
								CASE WHEN @CrDrType = 0 THEN 0 ELSE @Amount END,
								@ManagementStructureId ,@ModuleName,@LastMSLevel,@AllMSlevels ,@MasterCompanyId,@UpdateBy,@UpdateBy,GETUTCDATE(),GETUTCDATE(),1,0,@LotId,@LotNumber)

							SET @CommonJournalBatchDetailId = SCOPE_IDENTITY();

							-----  Accounting MS Entry  -----

							EXEC [dbo].[PROCAddUpdateAccountingBatchMSData] @CommonJournalBatchDetailId,@ManagementStructureId,@MasterCompanyId,@UpdateBy,@AccountMSModuleId,1; 
					
					
							INSERT INTO [dbo].[WorkOrderBatchDetails]
								(JournalBatchDetailId,[JournalBatchHeaderId],[ReferenceId],[ReferenceName],[MPNPartId],[MPNName],[PiecePNId],[PiecePN],[CustomerId],[CustomerName] ,[InvoiceId],[InvoiceName],[ARControlNum] ,[CustRefNumber] ,
								[Qty],[UnitPrice],[LaborHrs],[DirectLaborCost],[OverheadCost],[CommonJournalBatchDetailId],[StocklineId],[StocklineNumber],[IsWorkOrder])
							VALUES
								(@JournalBatchDetailId,@JournalBatchHeaderId,@ReferenceId ,@WorkOrderNumber ,@ReferencePartId,@MPNName,@ReferencePieceId,@PiecePN,@CustomerId ,@CustomerName,null ,null,null,@CustRefNumber,
								@Qty,@UnitPrice,@LaborHrs,@DirectLaborCost,@OverheadCost,@CommonJournalBatchDetailId,@StocklineId,@StocklineNumber,1)

							SELECT top 1 @DistributionSetupId=ID,@DistributionName=Name,@JournalTypeId =JournalTypeId,@CrDrType = CRDRType from DistributionSetup WITH(NOLOCK)  
							WHERE UPPER(DistributionSetupCode) =UPPER('INVENTORYPARTS') and DistributionMasterId =@DistributionMasterId AND MasterCompanyId=@MasterCompanyId
						
							SELECT @GlAccountId=GlAccountId from Stockline WITH(NOLOCK) WHERE StockLineId=@StocklineId
							SELECT @GlAccountNumber=AccountCode,@GlAccountName=AccountName from GLAccount WITH(NOLOCK) WHERE GLAccountId=@GlAccountId

							SET @GlAccountId = ISNULL(@GlAccountId,0) 
					
							INSERT INTO [dbo].[CommonBatchDetails]
								(JournalBatchDetailId,JournalTypeNumber,CurrentNumber,DistributionSetupId,DistributionName,[JournalBatchHeaderId],[LineNumber],[GlAccountId],[GlAccountNumber],[GlAccountName] ,
								[TransactionDate],[EntryDate] ,[JournalTypeId],[JournalTypeName],[IsDebit],[DebitAmount] ,[CreditAmount],[ManagementStructureId],[ModuleName],LastMSLevel,AllMSlevels,[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate] ,[IsActive] ,[IsDeleted],[LotId],[LotNumber])
							VALUES
								(@JournalBatchDetailId,@JournalTypeNumber,@currentNo,@DistributionSetupId,@DistributionName,@JournalBatchHeaderId,1 ,@GlAccountId ,@GlAccountNumber ,@GlAccountName,GETUTCDATE(),GETUTCDATE(),@JournalTypeId ,@JournalTypename,
								CASE WHEN @CrDrType = 0 THEN 1 ELSE 0 END,
								CASE WHEN @CrDrType = 0 THEN @Amount ELSE 0 END,
								CASE WHEN @CrDrType = 0 THEN 0 ELSE @Amount END,
								@ManagementStructureId ,@ModuleName,@LastMSLevel,@AllMSlevels ,@MasterCompanyId,@UpdateBy,@UpdateBy,GETUTCDATE(),GETUTCDATE(),1,0,@LotId,@LotNumber)

							SET @CommonJournalBatchDetailId = SCOPE_IDENTITY()

							-----  Accounting MS Entry  -----

							EXEC [dbo].[PROCAddUpdateAccountingBatchMSData] @CommonJournalBatchDetailId,@ManagementStructureId,@MasterCompanyId,@UpdateBy,@AccountMSModuleId,1; 
					
							INSERT INTO [dbo].[WorkOrderBatchDetails]
								(JournalBatchDetailId,[JournalBatchHeaderId],[ReferenceId],[ReferenceName],[MPNPartId],[MPNName],[PiecePNId],[PiecePN],[CustomerId],[CustomerName] ,[InvoiceId],[InvoiceName],[ARControlNum] ,[CustRefNumber] ,[Qty],[UnitPrice],[LaborHrs],[DirectLaborCost],[OverheadCost],[CommonJournalBatchDetailId],[StocklineId],[StocklineNumber],[IsWorkOrder])
							VALUES
								(@JournalBatchDetailId,@JournalBatchHeaderId,@ReferenceId ,@WorkOrderNumber ,@ReferencePartId,@MPNName,@ReferencePieceId,@PiecePN,@CustomerId ,@CustomerName,null ,null,null,@CustRefNumber,@Qty,@UnitPrice,@LaborHrs,@DirectLaborCost,@OverheadCost,@CommonJournalBatchDetailId,@StocklineId,@StocklineNumber,1)

							SET @TotalDebit=0;
							SET @TotalCredit=0;
							SELECT @TotalDebit = SUM(DebitAmount),
								   @TotalCredit=SUM(CreditAmount) 
							  FROM [dbo].[CommonBatchDetails] WITH(NOLOCK) 
							  WHERE JournalBatchDetailId=@JournalBatchDetailId GROUP BY JournalBatchDetailId
						
							UPDATE dbo.BatchDetails 
							   SET DebitAmount=@TotalDebit,
								   CreditAmount=@TotalCredit,
								   UpdatedDate=GETUTCDATE(),
								   UpdatedBy=@UpdateBy 
							 WHERE JournalBatchDetailId=@JournalBatchDetailId;
						END
					END

					SELECT @TotalDebit =SUM(DebitAmount),@TotalCredit=SUM(CreditAmount) FROM BatchDetails WITH(NOLOCK) WHERE JournalBatchHeaderId=@JournalBatchHeaderId and IsDeleted=0 group by JournalBatchHeaderId
			   	         
					SET @TotalBalance = @TotalDebit - @TotalCredit
				         
					UPDATE [dbo].[BatchHeader] SET TotalDebit = @TotalDebit,TotalCredit = @TotalCredit,TotalBalance = @TotalBalance,UpdatedDate=GETUTCDATE(),UpdatedBy=@UpdateBy WHERE JournalBatchHeaderId= @JournalBatchHeaderId
	            
					IF(@isNewJENum = 1 AND @JournalBatchDetailId > 0)
					BEGIN
						UPDATE [dbo].[CodePrefixes] SET CurrentNummber = @currentNo WHERE CodeTypeId = @CodeTypeId AND MasterCompanyId = @MasterCompanyId
					END

				END

				IF(UPPER(@DistributionCode) = UPPER('WOLABORTAB'))
				BEGIN
					SET @Batchtype = 2
					DECLARE @Hours DECIMAL(18,2)
					DECLARE @Hourspay DECIMAL(18,2)
					DECLARE @LaborRate MONEY
					DECLARE @burdentRate MONEY
					
					SET @JournalBatchDetailId = CASE WHEN @StartCount = 1 THEN 0 ELSE @JournalBatchDetailId END;

					SELECT @LaborHrs=Isnull(AdjustedHours,0),@Hours=Isnull(AdjustedHours,0),@DirectLaborCost=TotalCost,@OverheadCost=DirectLaborOHCost,@LaborRate=ISNULL(DirectLaborOHCost,0),@burdentRate=ISNULL(BurdenRateAmount,0) 
					FROM WorkOrderLabor WITH(NOLOCK)  WHERE WorkOrderLaborId=@ReferencePieceId
					SET @Qty=0;

					IF(@laborType='DIRECTLABOR')
					BEGIN
						SET @Amount=Isnull((CAST(@Hours AS INT) + (@Hours - CAST(@Hours AS INT))/.6)*@LaborRate,0)
						SET @DirectLaborCost=@Amount
						SET @OverheadCost=0
						SELECT top 1 @DistributionSetupId=ID,@DistributionName=Name,@JournalTypeId =JournalTypeId,@GlAccountId=GlAccountId,@GlAccountNumber=GlAccountNumber,@GlAccountName=GlAccountName,@CrDrType = CRDRType,@IsAutoPost = ISNULL(IsAutoPost,0) 
						FROM DistributionSetup WITH(NOLOCK)  WHERE UPPER(DistributionSetupCode) =UPPER('WIPDIRECTLABOR') and DistributionMasterId =@DistributionMasterId AND MasterCompanyId=@MasterCompanyId
					END

					IF NOT EXISTS(SELECT woB.WorkOrderBatchId from WorkOrderBatchDetails woB WITH(NOLOCK)  WHERE PiecePNId= @ReferencePieceId and Batchtype=@Batchtype and DistributionSetupId=@DistributionSetupId)
					BEGIN
						 IF EXISTS(SELECT 1 FROM dbo.DistributionSetup WITH(NOLOCK) WHERE DistributionMasterId =@DistributionMasterId AND MasterCompanyId=@MasterCompanyId AND ISNULL(GlAccountId,0) = 0)
						 BEGIN
							SET @ValidDistribution = 0;
						 END

					
						 IF(@issued =1 and @Amount >0 AND @ValidDistribution = 1)
						 BEGIN

							IF NOT EXISTS(SELECT JournalBatchHeaderId FROM BatchHeader WITH(NOLOCK)  WHERE JournalTypeId= @JournalTypeId and MasterCompanyId=@MasterCompanyId and  CAST(EntryDate AS DATE) = CAST(GETUTCDATE() AS DATE)and StatusId=@StatusId)
							BEGIN
								IF NOT EXISTS(SELECT JournalBatchHeaderId FROM BatchHeader WITH(NOLOCK))
								BEGIN	
									SET @batch ='001'
									SET @Currentbatch='001'
								END
								ELSE
								BEGIN
									SELECT top 1 @Currentbatch = CASE WHEN CurrentNumber > 0 THEN CAST(CurrentNumber AS BIGINT) + 1 ELSE  1 END 
				   					FROM BatchHeader WITH(NOLOCK) Order by JournalBatchHeaderId desc 

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
											(@batch,@CurrentNumber,GETUTCDATE(),@AccountingPeriod,@AccountingPeriodId,@StatusId,@StatusName,@JournalTypeId,@JournalTypename,@Amount,@Amount,0,@MasterCompanyId,@UpdateBy,@UpdateBy,GETUTCDATE(),GETUTCDATE(),1,0,@ModuleName);
            	          
								SELECT @JournalBatchHeaderId = SCOPE_IDENTITY()
								Update BatchHeader set CurrentNumber=@CurrentNumber  WHERE JournalBatchHeaderId= @JournalBatchHeaderId

								--AutoPost Batch
								IF(@IsAutoPost = 1)
								BEGIN
									EXEC [dbo].[UpdateToPostFullBatch] @JournalBatchHeaderId,@UpdateBy;
								END
							END
							ELSE
							BEGIN
								SELECT @JournalBatchHeaderId=JournalBatchHeaderId,@CurrentPeriodId=isnull(AccountingPeriodId,0) FROM BatchHeader WITH(NOLOCK)  WHERE JournalTypeId= @JournalTypeId and StatusId=@StatusId
								SELECT @LineNumber = CASE WHEN LineNumber > 0 THEN CAST(LineNumber AS BIGINT) + 1 ELSE  1 END 
				   										FROM BatchDetails WITH(NOLOCK) WHERE JournalBatchHeaderId=@JournalBatchHeaderId  Order by JournalBatchDetailId desc 
				    
								IF(@CurrentPeriodId =0)
								BEGIN
									Update BatchHeader set AccountingPeriodId=@AccountingPeriodId,AccountingPeriod=@AccountingPeriod   WHERE JournalBatchHeaderId= @JournalBatchHeaderId
								END
								--AutoPost Batch
								IF(@IsAutoPost = 1)
								BEGIN
									EXEC [dbo].[UpdateToPostFullBatch] @JournalBatchHeaderId,@UpdateBy;
								END
							END
						
							IF(@JournalBatchDetailId = 0)
							BEGIN
								INSERT INTO [dbo].[BatchDetails]
								(JournalTypeNumber,CurrentNumber,DistributionSetupId,DistributionName,[JournalBatchHeaderId],[LineNumber],[GlAccountId],[GlAccountNumber],[GlAccountName] ,[TransactionDate],[EntryDate],[JournalTypeId],[JournalTypeName],
								[IsDebit],[DebitAmount] ,[CreditAmount],[ManagementStructureId],[ModuleName],LastMSLevel,AllMSlevels,[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate] ,[IsActive] ,[IsDeleted],[AccountingPeriodId],[AccountingPeriod])
								VALUES
								(@JournalTypeNumber,@currentNo,@DistributionSetupId,@DistributionName,@JournalBatchHeaderId,1 ,@GlAccountId ,@GlAccountNumber ,@GlAccountName,GETUTCDATE(),GETUTCDATE(),@JournalTypeId ,@JournalTypename ,
								1,0,0,@ManagementStructureId ,@ModuleName,@LastMSLevel,@AllMSlevels ,@MasterCompanyId,@UpdateBy,@UpdateBy,GETUTCDATE(),GETUTCDATE(),1,0,@AccountingPeriodId,@AccountingPeriod)
				                
               					SET @JournalBatchDetailId=SCOPE_IDENTITY()
							END

							INSERT INTO [dbo].[CommonBatchDetails]
								(JournalBatchDetailId,JournalTypeNumber,CurrentNumber,DistributionSetupId,DistributionName,[JournalBatchHeaderId],[LineNumber],[GlAccountId],[GlAccountNumber],[GlAccountName] ,[TransactionDate],[EntryDate] ,[JournalTypeId],[JournalTypeName],[IsDebit],[DebitAmount] ,[CreditAmount],
								[ManagementStructureId],[ModuleName],LastMSLevel,AllMSlevels,[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate] ,[IsActive] ,[IsDeleted])
							VALUES
								(@JournalBatchDetailId,@JournalTypeNumber,@currentNo,@DistributionSetupId,@DistributionName,@JournalBatchHeaderId,1 ,@GlAccountId ,@GlAccountNumber ,@GlAccountName,GETUTCDATE(),GETUTCDATE(),@JournalTypeId ,@JournalTypename ,
								CASE WHEN @CrDrType = 1 THEN 1 ELSE 0 END,
								CASE WHEN @CrDrType = 1 THEN @Amount ELSE 0 END,
								CASE WHEN @CrDrType = 1 THEN 0 ELSE @Amount END,
								@ManagementStructureId ,@ModuleName,@LastMSLevel,@AllMSlevels ,@MasterCompanyId,@UpdateBy,@UpdateBy,GETUTCDATE(),GETUTCDATE(),1,0)

							SET @CommonJournalBatchDetailId=SCOPE_IDENTITY()

							-----  Accounting MS Entry  -----

							EXEC [dbo].[PROCAddUpdateAccountingBatchMSData] @CommonJournalBatchDetailId,@ManagementStructureId,@MasterCompanyId,@UpdateBy,@AccountMSModuleId,1; 
					

							INSERT INTO [dbo].[WorkOrderBatchDetails]
								(JournalBatchDetailId,[JournalBatchHeaderId],[ReferenceId],[ReferenceName],[MPNPartId],[MPNName],[PiecePNId],[PiecePN],[CustomerId],[CustomerName] ,[InvoiceId],[InvoiceName],[ARControlNum] ,[CustRefNumber] ,[Qty],[UnitPrice],[LaborHrs],[DirectLaborCost],[OverheadCost],[CommonJournalBatchDetailId],[Batchtype],[DistributionSetupId],[IsWorkOrder])
							VALUES
								(@JournalBatchDetailId,@JournalBatchHeaderId,@ReferenceId ,@WorkOrderNumber ,@ReferencePartId,@MPNName,@ReferencePieceId,@PiecePN,@CustomerId ,@CustomerName,null ,null,null,@CustRefNumber,@Qty,@UnitPrice,@LaborHrs,@DirectLaborCost,@OverheadCost,@CommonJournalBatchDetailId,@Batchtype,@DistributionSetupId,1)

							IF(@laborType='DIRECTLABOR')
							BEGIN
								SELECT top 1 @DistributionSetupId=ID,@DistributionName=Name,@JournalTypeId =JournalTypeId,@GlAccountId=GlAccountId,@GlAccountNumber=GlAccountNumber,@GlAccountName=GlAccountName,@CrDrType = CRDRType 
								from DistributionSetup WITH(NOLOCK)  WHERE UPPER(DistributionSetupCode) =UPPER('DIRECTLABORP&LOFFSET') and DistributionMasterId =@DistributionMasterId  AND MasterCompanyId=@MasterCompanyId
							END

							INSERT INTO [dbo].[CommonBatchDetails]
								(JournalBatchDetailId,JournalTypeNumber,CurrentNumber,DistributionSetupId,DistributionName,[JournalBatchHeaderId],[LineNumber],[GlAccountId],[GlAccountNumber],[GlAccountName] ,[TransactionDate],[EntryDate] ,[JournalTypeId],[JournalTypeName],
								[IsDebit],[DebitAmount] ,[CreditAmount],[ManagementStructureId],[ModuleName],LastMSLevel,AllMSlevels,[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate] ,[IsActive] ,[IsDeleted])
							VALUES
								(@JournalBatchDetailId,@JournalTypeNumber,@currentNo,@DistributionSetupId,@DistributionName,@JournalBatchHeaderId,1 ,@GlAccountId ,@GlAccountNumber ,@GlAccountName,GETUTCDATE(),GETUTCDATE(),@JournalTypeId ,@JournalTypename ,
								CASE WHEN @CrDrType = 1 THEN 1 ELSE 0 END,
								CASE WHEN @CrDrType = 1 THEN @Amount ELSE 0 END,
								CASE WHEN @CrDrType = 1 THEN 0 ELSE @Amount END,
								@ManagementStructureId ,@ModuleName,@LastMSLevel,@AllMSlevels ,@MasterCompanyId,@UpdateBy,@UpdateBy,GETUTCDATE(),GETUTCDATE(),1,0)

							SET @CommonJournalBatchDetailId=SCOPE_IDENTITY()

							-----  Accounting MS Entry  -----

							EXEC [dbo].[PROCAddUpdateAccountingBatchMSData] @CommonJournalBatchDetailId,@ManagementStructureId,@MasterCompanyId,@UpdateBy,@AccountMSModuleId,1; 
					

							INSERT INTO [dbo].[WorkOrderBatchDetails]
								(JournalBatchDetailId,[JournalBatchHeaderId],[ReferenceId],[ReferenceName],[MPNPartId],[MPNName],[PiecePNId],[PiecePN],[CustomerId],[CustomerName] ,[InvoiceId],[InvoiceName],[ARControlNum] ,[CustRefNumber] ,
								[Qty],[UnitPrice],[LaborHrs],[DirectLaborCost],[OverheadCost],[CommonJournalBatchDetailId],[Batchtype],[DistributionSetupId],[IsWorkOrder])
							VALUES
								(@JournalBatchDetailId,@JournalBatchHeaderId,@ReferenceId ,@WorkOrderNumber ,@ReferencePartId,@MPNName,@ReferencePieceId,@PiecePN,@CustomerId ,@CustomerName,null ,null,null,@CustRefNumber,
								@Qty,@UnitPrice,@LaborHrs,@DirectLaborCost,@OverheadCost,@CommonJournalBatchDetailId,@Batchtype,@DistributionSetupId,1)

							-----------------LABOROVERHEAD --------------------------
							SET @Amount=Isnull((CAST(@Hours AS INT) + (@Hours - CAST(@Hours AS INT))/.6)*@burdentRate,0)
							SET @OverheadCost=@Amount
							SET @DirectLaborCost=0
							SELECT top 1 @DistributionSetupId=ID,@DistributionName=Name,@JournalTypeId =JournalTypeId,@GlAccountId=GlAccountId,@GlAccountNumber=GlAccountNumber,@GlAccountName=GlAccountName,@CrDrType = CRDRType 
							FROM DistributionSetup WITH(NOLOCK)  WHERE UPPER(DistributionSetupCode) =UPPER('WIPOVERHEAD') and DistributionMasterId =@DistributionMasterId AND MasterCompanyId=@MasterCompanyId

							INSERT INTO [dbo].[CommonBatchDetails]
								(JournalBatchDetailId,JournalTypeNumber,CurrentNumber,DistributionSetupId,DistributionName,[JournalBatchHeaderId],[LineNumber],[GlAccountId],[GlAccountNumber],[GlAccountName] ,[TransactionDate],[EntryDate] ,[JournalTypeId],[JournalTypeName],
								[IsDebit],[DebitAmount] ,[CreditAmount],[ManagementStructureId],[ModuleName],LastMSLevel,AllMSlevels,[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate] ,[IsActive] ,[IsDeleted])
							VALUES
								(@JournalBatchDetailId,@JournalTypeNumber,@currentNo,@DistributionSetupId,@DistributionName,@JournalBatchHeaderId,1 ,@GlAccountId ,@GlAccountNumber ,@GlAccountName,GETUTCDATE(),GETUTCDATE(),@JournalTypeId ,@JournalTypename ,
								CASE WHEN @CrDrType = 1 THEN 1 ELSE 0 END,
								CASE WHEN @CrDrType = 1 THEN @Amount ELSE 0 END,
								CASE WHEN @CrDrType = 1 THEN 0 ELSE @Amount END
								,@ManagementStructureId ,@ModuleName,@LastMSLevel,@AllMSlevels ,@MasterCompanyId,@UpdateBy,@UpdateBy,GETUTCDATE(),GETUTCDATE(),1,0)

							SET @CommonJournalBatchDetailId = SCOPE_IDENTITY()

							-----  Accounting MS Entry  -----

							EXEC [dbo].[PROCAddUpdateAccountingBatchMSData] @CommonJournalBatchDetailId,@ManagementStructureId,@MasterCompanyId,@UpdateBy,@AccountMSModuleId,1; 
					

							INSERT INTO [dbo].[WorkOrderBatchDetails]
								(JournalBatchDetailId,[JournalBatchHeaderId],[ReferenceId],[ReferenceName],[MPNPartId],[MPNName],[PiecePNId],[PiecePN],[CustomerId],[CustomerName] ,[InvoiceId],[InvoiceName],[ARControlNum] ,[CustRefNumber] ,
								Qty,UnitPrice,LaborHrs,DirectLaborCost,OverheadCost,CommonJournalBatchDetailId,Batchtype,DistributionSetupId,[IsWorkOrder])
							VALUES
								(@JournalBatchDetailId,@JournalBatchHeaderId,@ReferenceId ,@WorkOrderNumber ,@ReferencePartId,@MPNName,@ReferencePieceId,@PiecePN,@CustomerId ,@CustomerName,null ,null,null,@CustRefNumber,
								@Qty,@UnitPrice,@LaborHrs,@DirectLaborCost,@OverheadCost,@CommonJournalBatchDetailId,@Batchtype,@DistributionSetupId,1)

							----------OVERHEADP&LOFFSET--------------------

							SELECT top 1 @DistributionSetupId=ID,@DistributionName=Name,@JournalTypeId =JournalTypeId,@GlAccountId=GlAccountId,@GlAccountNumber=GlAccountNumber,@GlAccountName=GlAccountName,@CrDrType = CRDRType  
							FROM DistributionSetup WITH(NOLOCK)  WHERE UPPER(DistributionSetupCode) =UPPER('OVERHEADP&LOFFSET') and DistributionMasterId =@DistributionMasterId AND MasterCompanyId=@MasterCompanyId

							INSERT INTO [dbo].[CommonBatchDetails]
								(JournalBatchDetailId,JournalTypeNumber,CurrentNumber,DistributionSetupId,DistributionName,[JournalBatchHeaderId],[LineNumber],[GlAccountId],[GlAccountNumber],[GlAccountName] ,[TransactionDate],[EntryDate] ,[JournalTypeId],[JournalTypeName],
								[IsDebit],[DebitAmount] ,[CreditAmount],[ManagementStructureId],[ModuleName],LastMSLevel,AllMSlevels,[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate] ,[IsActive] ,[IsDeleted])
							VALUES
								(@JournalBatchDetailId,@JournalTypeNumber,@currentNo,@DistributionSetupId,@DistributionName,@JournalBatchHeaderId,1 ,@GlAccountId ,@GlAccountNumber ,@GlAccountName,GETUTCDATE(),GETUTCDATE(),@JournalTypeId ,@JournalTypename ,
								CASE WHEN @CrDrType = 1 THEN 1 ELSE 0 END,
								CASE WHEN @CrDrType = 1 THEN @Amount ELSE 0 END,
								CASE WHEN @CrDrType = 1 THEN 0 ELSE @Amount END
								,@ManagementStructureId ,@ModuleName,@LastMSLevel,@AllMSlevels ,@MasterCompanyId,@UpdateBy,@UpdateBy,GETUTCDATE(),GETUTCDATE(),1,0)

							SET @CommonJournalBatchDetailId=SCOPE_IDENTITY()

							-----  Accounting MS Entry  -----

							EXEC [dbo].[PROCAddUpdateAccountingBatchMSData] @CommonJournalBatchDetailId,@ManagementStructureId,@MasterCompanyId,@UpdateBy,@AccountMSModuleId,1; 
					

							INSERT INTO [dbo].[WorkOrderBatchDetails]
								(JournalBatchDetailId,[JournalBatchHeaderId],[ReferenceId],[ReferenceName],[MPNPartId],[MPNName],[PiecePNId],[PiecePN],[CustomerId],[CustomerName] ,[InvoiceId],[InvoiceName],[ARControlNum] ,[CustRefNumber] ,
								Qty,UnitPrice,LaborHrs,DirectLaborCost,OverheadCost,CommonJournalBatchDetailId,Batchtype,DistributionSetupId,[IsWorkOrder])
							VALUES
								(@JournalBatchDetailId,@JournalBatchHeaderId,@ReferenceId ,@WorkOrderNumber ,@ReferencePartId,@MPNName,@ReferencePieceId,@PiecePN,@CustomerId ,@CustomerName,null ,null,null,@CustRefNumber,
								@Qty,@UnitPrice,@LaborHrs,@DirectLaborCost,@OverheadCost,@CommonJournalBatchDetailId,@Batchtype,@DistributionSetupId,1)

							SET @TotalDebit=0;
							SET @TotalCredit=0;
							SELECT @TotalDebit =SUM(DebitAmount),@TotalCredit=SUM(CreditAmount) FROM [dbo].[CommonBatchDetails] WITH(NOLOCK) WHERE JournalBatchDetailId=@JournalBatchDetailId group by JournalBatchDetailId
							Update BatchDetails set DebitAmount=@TotalDebit,CreditAmount=@TotalCredit,UpdatedDate=GETUTCDATE(),UpdatedBy=@UpdateBy WHERE JournalBatchDetailId=@JournalBatchDetailId		

						 END
						 ELSE
						 BEGIN
							IF EXISTS(SELECT 1 FROM dbo.DistributionSetup WITH(NOLOCK) WHERE DistributionMasterId =@DistributionMasterId AND MasterCompanyId=@MasterCompanyId AND ISNULL(GlAccountId,0) = 0)
							 BEGIN
								SET @ValidDistribution = 0;
							 END

							IF(@Amount >0 AND @ValidDistribution = 1)
							BEGIN

								IF NOT EXISTS(SELECT JournalBatchHeaderId FROM BatchHeader WITH(NOLOCK)  WHERE JournalTypeId= @JournalTypeId and MasterCompanyId=@MasterCompanyId and  CAST(EntryDate AS DATE) = CAST(GETUTCDATE() AS DATE)and StatusId=@StatusId)
								BEGIN
									IF NOT EXISTS(SELECT JournalBatchHeaderId FROM BatchHeader WITH(NOLOCK))
									BEGIN	
										SET @batch ='001'
										SET @Currentbatch='001'
									END
									ELSE
									BEGIN
										SELECT top 1 @Currentbatch = CASE WHEN CurrentNumber > 0 THEN CAST(CurrentNumber AS BIGINT) + 1 ELSE  1 END 
				   						FROM BatchHeader WITH(NOLOCK) Order by JournalBatchHeaderId desc 

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
									Update BatchHeader set CurrentNumber=@CurrentNumber  WHERE JournalBatchHeaderId= @JournalBatchHeaderId

									--AutoPost Batch
									IF(@IsAutoPost = 1)
									BEGIN
										EXEC [dbo].[UpdateToPostFullBatch] @JournalBatchHeaderId,@UpdateBy;
									END
								END
								ELSE
								BEGIN
									SELECT @JournalBatchHeaderId=JournalBatchHeaderId,@CurrentPeriodId=isnull(AccountingPeriodId,0) FROM BatchHeader WITH(NOLOCK)  WHERE JournalTypeId= @JournalTypeId and StatusId=@StatusId
									SELECT @LineNumber = CASE WHEN LineNumber > 0 THEN CAST(LineNumber AS BIGINT) + 1 ELSE  1 END 
				   											FROM BatchDetails WITH(NOLOCK) WHERE JournalBatchHeaderId=@JournalBatchHeaderId  Order by JournalBatchDetailId desc 
				    
									IF(@CurrentPeriodId =0)
									BEGIN
										Update BatchHeader set AccountingPeriodId=@AccountingPeriodId,AccountingPeriod=@AccountingPeriod   WHERE JournalBatchHeaderId= @JournalBatchHeaderId
									END

									--AutoPost Batch
									IF(@IsAutoPost = 1)
									BEGIN
										EXEC [dbo].[UpdateToPostFullBatch] @JournalBatchHeaderId,@UpdateBy;
									END
								END
							
								IF(@JournalBatchDetailId = 0)
								BEGIN
									INSERT INTO [dbo].[BatchDetails]
										(JournalTypeNumber,CurrentNumber,DistributionSetupId,DistributionName,[JournalBatchHeaderId],[LineNumber],[GlAccountId],[GlAccountNumber],[GlAccountName] ,[TransactionDate],[EntryDate],[JournalTypeId],[JournalTypeName],
										[IsDebit],[DebitAmount] ,[CreditAmount],[ManagementStructureId],[ModuleName],LastMSLevel,AllMSlevels,[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate] ,[IsActive] ,[IsDeleted],[AccountingPeriodId],[AccountingPeriod])
									VALUES
										(@JournalTypeNumber,@currentNo,@DistributionSetupId,@DistributionName,@JournalBatchHeaderId,1 ,@GlAccountId ,@GlAccountNumber ,@GlAccountName,GETUTCDATE(),GETUTCDATE(),@JournalTypeId ,@JournalTypename ,
										1,0,0,@ManagementStructureId ,@ModuleName,@LastMSLevel,@AllMSlevels ,@MasterCompanyId,@UpdateBy,@UpdateBy,GETUTCDATE(),GETUTCDATE(),1,0,@AccountingPeriodId,@AccountingPeriod)
				                
               						SET @JournalBatchDetailId=SCOPE_IDENTITY()
								END

								INSERT INTO [dbo].[CommonBatchDetails]
									(JournalBatchDetailId,JournalTypeNumber,CurrentNumber,DistributionSetupId,DistributionName,[JournalBatchHeaderId],[LineNumber],[GlAccountId],[GlAccountNumber],[GlAccountName] ,[TransactionDate],[EntryDate] ,[JournalTypeId],[JournalTypeName],[IsDebit],[DebitAmount] ,[CreditAmount],
									[ManagementStructureId],[ModuleName],LastMSLevel,AllMSlevels,[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate] ,[IsActive] ,[IsDeleted])
								VALUES
									(@JournalBatchDetailId,@JournalTypeNumber,@currentNo,@DistributionSetupId,@DistributionName,@JournalBatchHeaderId,1 ,@GlAccountId ,@GlAccountNumber ,@GlAccountName,GETUTCDATE(),GETUTCDATE(),@JournalTypeId ,@JournalTypename ,
									CASE WHEN @CrDrType = 0 THEN 1 ELSE 0 END,
									CASE WHEN @CrDrType = 0 THEN @Amount ELSE 0 END,
									CASE WHEN @CrDrType = 0 THEN 0 ELSE @Amount END,
									@ManagementStructureId ,@ModuleName,@LastMSLevel,@AllMSlevels ,@MasterCompanyId,@UpdateBy,@UpdateBy,GETUTCDATE(),GETUTCDATE(),1,0)

								SET @CommonJournalBatchDetailId=SCOPE_IDENTITY()

								-----  Accounting MS Entry  -----

								EXEC [dbo].[PROCAddUpdateAccountingBatchMSData] @CommonJournalBatchDetailId,@ManagementStructureId,@MasterCompanyId,@UpdateBy,@AccountMSModuleId,1; 
					

								INSERT INTO [dbo].[WorkOrderBatchDetails]
									(JournalBatchDetailId,[JournalBatchHeaderId],[ReferenceId],[ReferenceName],[MPNPartId],[MPNName],[PiecePNId],[PiecePN],[CustomerId],[CustomerName] ,[InvoiceId],[InvoiceName],[ARControlNum] ,[CustRefNumber] ,Qty,UnitPrice,LaborHrs,DirectLaborCost,OverheadCost,CommonJournalBatchDetailId,Batchtype,DistributionSetupId ,[IsWorkOrder])
								VALUES
									(@JournalBatchDetailId,@JournalBatchHeaderId,@ReferenceId ,@WorkOrderNumber ,@ReferencePartId,@MPNName,@ReferencePieceId,@PiecePN,@CustomerId ,@CustomerName,null ,null,null,@CustRefNumber,@Qty,@UnitPrice,@LaborHrs,@DirectLaborCost,@OverheadCost,@CommonJournalBatchDetailId,@Batchtype,@DistributionSetupId ,1)

								IF(@laborType='DIRECTLABOR')
								BEGIN
									SELECT top 1 @DistributionSetupId=ID,@DistributionName=Name,@JournalTypeId =JournalTypeId,@GlAccountId=GlAccountId,@GlAccountNumber=GlAccountNumber,@GlAccountName=GlAccountName,@CrDrType = CRDRType 
									from DistributionSetup WITH(NOLOCK)  WHERE UPPER(DistributionSetupCode) =UPPER('DIRECTLABORP&LOFFSET') and DistributionMasterId =@DistributionMasterId  AND MasterCompanyId=@MasterCompanyId
								END

								INSERT INTO [dbo].[CommonBatchDetails]
									(JournalBatchDetailId,JournalTypeNumber,CurrentNumber,DistributionSetupId,DistributionName,[JournalBatchHeaderId],[LineNumber],[GlAccountId],[GlAccountNumber],[GlAccountName] ,[TransactionDate],[EntryDate] ,[JournalTypeId],[JournalTypeName],
									[IsDebit],[DebitAmount] ,[CreditAmount],[ManagementStructureId],[ModuleName],LastMSLevel,AllMSlevels,[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate] ,[IsActive] ,[IsDeleted])
								VALUES
									(@JournalBatchDetailId,@JournalTypeNumber,@currentNo,@DistributionSetupId,@DistributionName,@JournalBatchHeaderId,1 ,@GlAccountId ,@GlAccountNumber ,@GlAccountName,GETUTCDATE(),GETUTCDATE(),@JournalTypeId ,@JournalTypename ,
									CASE WHEN @CrDrType = 0 THEN 1 ELSE 0 END,
									CASE WHEN @CrDrType = 0 THEN @Amount ELSE 0 END,
									CASE WHEN @CrDrType = 0 THEN 0 ELSE @Amount END,
									@ManagementStructureId ,@ModuleName,@LastMSLevel,@AllMSlevels ,@MasterCompanyId,@UpdateBy,@UpdateBy,GETUTCDATE(),GETUTCDATE(),1,0)

								SET @CommonJournalBatchDetailId = SCOPE_IDENTITY()

								-----  Accounting MS Entry  -----

								EXEC [dbo].[PROCAddUpdateAccountingBatchMSData] @CommonJournalBatchDetailId,@ManagementStructureId,@MasterCompanyId,@UpdateBy,@AccountMSModuleId,1; 
					

								INSERT INTO [dbo].[WorkOrderBatchDetails]
									(JournalBatchDetailId,[JournalBatchHeaderId],[ReferenceId],[ReferenceName],[MPNPartId],[MPNName],[PiecePNId],[PiecePN],[CustomerId],[CustomerName] ,[InvoiceId],[InvoiceName],[ARControlNum] ,[CustRefNumber] ,
									Qty,UnitPrice,LaborHrs,DirectLaborCost,OverheadCost,CommonJournalBatchDetailId,Batchtype,DistributionSetupId ,[IsWorkOrder])
								VALUES
									(@JournalBatchDetailId,@JournalBatchHeaderId,@ReferenceId ,@WorkOrderNumber ,@ReferencePartId,@MPNName,@ReferencePieceId,@PiecePN,@CustomerId ,@CustomerName,null ,null,null,@CustRefNumber,
									@Qty,@UnitPrice,@LaborHrs,@DirectLaborCost,@OverheadCost,@CommonJournalBatchDetailId,@Batchtype,@DistributionSetupId,1)

								-----------------LABOROVERHEAD --------------------------
								SET @Amount=Isnull((CAST(@Hours AS INT) + (@Hours - CAST(@Hours AS INT))/.6)*@burdentRate,0)
								SET @OverheadCost=@Amount
								SET @DirectLaborCost=0
								SELECT top 1 @DistributionSetupId=ID,@DistributionName=Name,@JournalTypeId =JournalTypeId,@GlAccountId=GlAccountId,@GlAccountNumber=GlAccountNumber,@GlAccountName=GlAccountName,@CrDrType = CRDRType 
								FROM DistributionSetup WITH(NOLOCK)  WHERE UPPER(DistributionSetupCode) =UPPER('WIPOVERHEAD') and DistributionMasterId =@DistributionMasterId AND MasterCompanyId=@MasterCompanyId

								INSERT INTO [dbo].[CommonBatchDetails]
									(JournalBatchDetailId,JournalTypeNumber,CurrentNumber,DistributionSetupId,DistributionName,[JournalBatchHeaderId],[LineNumber],[GlAccountId],[GlAccountNumber],[GlAccountName] ,[TransactionDate],[EntryDate] ,[JournalTypeId],[JournalTypeName],
									[IsDebit],[DebitAmount] ,[CreditAmount],[ManagementStructureId],[ModuleName],LastMSLevel,AllMSlevels,[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate] ,[IsActive] ,[IsDeleted])
								VALUES
									(@JournalBatchDetailId,@JournalTypeNumber,@currentNo,@DistributionSetupId,@DistributionName,@JournalBatchHeaderId,1 ,@GlAccountId ,@GlAccountNumber ,@GlAccountName,GETUTCDATE(),GETUTCDATE(),@JournalTypeId ,@JournalTypename ,
									CASE WHEN @CrDrType = 0 THEN 1 ELSE 0 END,
									CASE WHEN @CrDrType = 0 THEN @Amount ELSE 0 END,
									CASE WHEN @CrDrType = 0 THEN 0 ELSE @Amount END
									,@ManagementStructureId ,@ModuleName,@LastMSLevel,@AllMSlevels ,@MasterCompanyId,@UpdateBy,@UpdateBy,GETUTCDATE(),GETUTCDATE(),1,0)

								SET @CommonJournalBatchDetailId = SCOPE_IDENTITY()

								-----  Accounting MS Entry  -----

								EXEC [dbo].[PROCAddUpdateAccountingBatchMSData] @CommonJournalBatchDetailId,@ManagementStructureId,@MasterCompanyId,@UpdateBy,@AccountMSModuleId,1; 
					

								INSERT INTO [dbo].[WorkOrderBatchDetails]
									(JournalBatchDetailId,[JournalBatchHeaderId],[ReferenceId],[ReferenceName],[MPNPartId],[MPNName],[PiecePNId],[PiecePN],[CustomerId],[CustomerName] ,[InvoiceId],[InvoiceName],[ARControlNum] ,[CustRefNumber] ,
									Qty,UnitPrice,LaborHrs,DirectLaborCost,OverheadCost,CommonJournalBatchDetailId,Batchtype,DistributionSetupId ,[IsWorkOrder])
								VALUES
									(@JournalBatchDetailId,@JournalBatchHeaderId,@ReferenceId ,@WorkOrderNumber ,@ReferencePartId,@MPNName,@ReferencePieceId,@PiecePN,@CustomerId ,@CustomerName,null ,null,null,@CustRefNumber,
									@Qty,@UnitPrice,@LaborHrs,@DirectLaborCost,@OverheadCost,@CommonJournalBatchDetailId,@Batchtype,@DistributionSetupId,1)

								----------OVERHEADP&LOFFSET--------------------

								SELECT top 1 @DistributionSetupId=ID,@DistributionName=Name,@JournalTypeId =JournalTypeId,@GlAccountId=GlAccountId,@GlAccountNumber=GlAccountNumber,@GlAccountName=GlAccountName,@CrDrType = CRDRType  
								FROM DistributionSetup WITH(NOLOCK)  WHERE UPPER(DistributionSetupCode) =UPPER('OVERHEADP&LOFFSET') and DistributionMasterId =@DistributionMasterId AND MasterCompanyId=@MasterCompanyId

								INSERT INTO [dbo].[CommonBatchDetails]
									(JournalBatchDetailId,JournalTypeNumber,CurrentNumber,DistributionSetupId,DistributionName,[JournalBatchHeaderId],[LineNumber],[GlAccountId],[GlAccountNumber],[GlAccountName] ,[TransactionDate],[EntryDate] ,[JournalTypeId],[JournalTypeName],
									[IsDebit],[DebitAmount] ,[CreditAmount],[ManagementStructureId],[ModuleName],LastMSLevel,AllMSlevels,[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate] ,[IsActive] ,[IsDeleted])
								VALUES
									(@JournalBatchDetailId,@JournalTypeNumber,@currentNo,@DistributionSetupId,@DistributionName,@JournalBatchHeaderId,1 ,@GlAccountId ,@GlAccountNumber ,@GlAccountName,GETUTCDATE(),GETUTCDATE(),@JournalTypeId ,@JournalTypename ,
									CASE WHEN @CrDrType = 0 THEN 1 ELSE 0 END,
									CASE WHEN @CrDrType = 0 THEN @Amount ELSE 0 END,
									CASE WHEN @CrDrType = 0 THEN 0 ELSE @Amount END
									,@ManagementStructureId ,@ModuleName,@LastMSLevel,@AllMSlevels ,@MasterCompanyId,@UpdateBy,@UpdateBy,GETUTCDATE(),GETUTCDATE(),1,0)

								SET @CommonJournalBatchDetailId = SCOPE_IDENTITY()

								-----  Accounting MS Entry  -----

								EXEC [dbo].[PROCAddUpdateAccountingBatchMSData] @CommonJournalBatchDetailId,@ManagementStructureId,@MasterCompanyId,@UpdateBy,@AccountMSModuleId,1; 
					

								INSERT INTO [dbo].[WorkOrderBatchDetails]
									(JournalBatchDetailId,[JournalBatchHeaderId],[ReferenceId],[ReferenceName],[MPNPartId],[MPNName],[PiecePNId],[PiecePN],[CustomerId],[CustomerName] ,[InvoiceId],[InvoiceName],[ARControlNum] ,[CustRefNumber] ,
									Qty,UnitPrice,LaborHrs,DirectLaborCost,OverheadCost,CommonJournalBatchDetailId,Batchtype,DistributionSetupId ,[IsWorkOrder])
								VALUES
									(@JournalBatchDetailId,@JournalBatchHeaderId,@ReferenceId ,@WorkOrderNumber ,@ReferencePartId,@MPNName,@ReferencePieceId,@PiecePN,@CustomerId ,@CustomerName,null ,null,null,@CustRefNumber,
									@Qty,@UnitPrice,@LaborHrs,@DirectLaborCost,@OverheadCost,@CommonJournalBatchDetailId,@Batchtype,@DistributionSetupId,1)

								SET @TotalDebit=0;
								SET @TotalCredit=0;
								SELECT @TotalDebit =SUM(DebitAmount),@TotalCredit=SUM(CreditAmount) FROM [dbo].[CommonBatchDetails] WITH(NOLOCK) WHERE JournalBatchDetailId=@JournalBatchDetailId group by JournalBatchDetailId
								Update BatchDetails set DebitAmount=@TotalDebit,CreditAmount=@TotalCredit,UpdatedDate=GETUTCDATE(),UpdatedBy=@UpdateBy WHERE JournalBatchDetailId=@JournalBatchDetailId		

							END
						 END
					
						 SET @TotalDebit=0;
						 SET @TotalCredit=0;
						 SELECT @TotalDebit =SUM(DebitAmount),@TotalCredit=SUM(CreditAmount) FROM [dbo].[CommonBatchDetails] WITH(NOLOCK) WHERE JournalBatchDetailId=@JournalBatchDetailId group by JournalBatchDetailId
						 Update BatchDetails set DebitAmount=@TotalDebit,CreditAmount=@TotalCredit,UpdatedDate=GETUTCDATE(),UpdatedBy=@UpdateBy WHERE JournalBatchDetailId=@JournalBatchDetailId
					END
					ELSE
					BEGIN
						IF EXISTS(SELECT 1 FROM dbo.DistributionSetup WITH(NOLOCK) WHERE DistributionMasterId =@DistributionMasterId AND MasterCompanyId=@MasterCompanyId AND ISNULL(GlAccountId,0) = 0)
						BEGIN
							SET @ValidDistribution = 0;
						END

						IF(@issued =0 and @Amount >0 AND @ValidDistribution = 1)
						BEGIN
						
							IF NOT EXISTS(SELECT JournalBatchHeaderId FROM BatchHeader WITH(NOLOCK)  WHERE JournalTypeId= @JournalTypeId and MasterCompanyId=@MasterCompanyId and  CAST(EntryDate AS DATE) = CAST(GETUTCDATE() AS DATE)and StatusId=@StatusId)
							BEGIN
								IF NOT EXISTS(SELECT JournalBatchHeaderId FROM BatchHeader WITH(NOLOCK))
								BEGIN	
									SET @batch ='001'
									SET @Currentbatch='001'
								END
								ELSE
								BEGIN
									SELECT top 1 @Currentbatch = CASE WHEN CurrentNumber > 0 THEN CAST(CurrentNumber AS BIGINT) + 1 ELSE  1 END 
				   					FROM BatchHeader WITH(NOLOCK) Order by JournalBatchHeaderId desc 

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
								Update BatchHeader set CurrentNumber=@CurrentNumber  WHERE JournalBatchHeaderId= @JournalBatchHeaderId

								--AutoPost Batch
								IF(@IsAutoPost = 1)
								BEGIN
									EXEC [dbo].[UpdateToPostFullBatch] @JournalBatchHeaderId,@UpdateBy;
								END
							END
							ELSE
							BEGIN
								SELECT @JournalBatchHeaderId=JournalBatchHeaderId,@CurrentPeriodId=isnull(AccountingPeriodId,0) FROM BatchHeader WITH(NOLOCK)  WHERE JournalTypeId= @JournalTypeId and StatusId=@StatusId
								SELECT @LineNumber = CASE WHEN LineNumber > 0 THEN CAST(LineNumber AS BIGINT) + 1 ELSE  1 END 
				   										FROM BatchDetails WITH(NOLOCK) WHERE JournalBatchHeaderId=@JournalBatchHeaderId  Order by JournalBatchDetailId desc 
				    
								IF(@CurrentPeriodId =0)
								BEGIN
									Update BatchHeader set AccountingPeriodId=@AccountingPeriodId,AccountingPeriod=@AccountingPeriod   WHERE JournalBatchHeaderId= @JournalBatchHeaderId
								END

								--AutoPost Batch
								IF(@IsAutoPost = 1)
								BEGIN
									EXEC [dbo].[UpdateToPostFullBatch] @JournalBatchHeaderId,@UpdateBy;
								END
							END

							IF(@JournalBatchDetailId = 0)
							BEGIN
								INSERT INTO [dbo].[BatchDetails]
									(JournalTypeNumber,CurrentNumber,DistributionSetupId,DistributionName,[JournalBatchHeaderId],[LineNumber],[GlAccountId],[GlAccountNumber],[GlAccountName] ,[TransactionDate],[EntryDate],[JournalTypeId],[JournalTypeName],
									[IsDebit],[DebitAmount] ,[CreditAmount],[ManagementStructureId],[ModuleName],LastMSLevel,AllMSlevels,[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate] ,[IsActive] ,[IsDeleted],[AccountingPeriodId],[AccountingPeriod])
								VALUES
									(@JournalTypeNumber,@currentNo,@DistributionSetupId,@DistributionName,@JournalBatchHeaderId,1 ,@GlAccountId ,@GlAccountNumber ,@GlAccountName,GETUTCDATE(),GETUTCDATE(),@JournalTypeId ,@JournalTypename ,
									1,0,0,@ManagementStructureId ,@ModuleName,@LastMSLevel,@AllMSlevels ,@MasterCompanyId,@UpdateBy,@UpdateBy,GETUTCDATE(),GETUTCDATE(),1,0,@AccountingPeriodId,@AccountingPeriod)
				                 
								SET @JournalBatchDetailId=SCOPE_IDENTITY()
							END

							INSERT INTO [dbo].[CommonBatchDetails]
								(JournalBatchDetailId,JournalTypeNumber,CurrentNumber,DistributionSetupId,DistributionName,[JournalBatchHeaderId],[LineNumber],[GlAccountId],[GlAccountNumber],[GlAccountName] ,[TransactionDate],[EntryDate] ,[JournalTypeId],[JournalTypeName],
								[IsDebit],[DebitAmount] ,[CreditAmount],[ManagementStructureId],[ModuleName],LastMSLevel,AllMSlevels,[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate] ,[IsActive] ,[IsDeleted])
							VALUES
								(@JournalBatchDetailId,@JournalTypeNumber,@currentNo,@DistributionSetupId,@DistributionName,@JournalBatchHeaderId,1 ,@GlAccountId ,@GlAccountNumber ,@GlAccountName,GETUTCDATE(),GETUTCDATE(),@JournalTypeId ,@JournalTypename,
								CASE WHEN @CrDrType = 1 THEN 1 ELSE 0 END,
								CASE WHEN @CrDrType = 1 THEN @Amount ELSE 0 END,
								CASE WHEN @CrDrType = 1 THEN 0 ELSE @Amount END,
								@ManagementStructureId ,@ModuleName,@LastMSLevel,@AllMSlevels ,@MasterCompanyId,@UpdateBy,@UpdateBy,GETUTCDATE(),GETUTCDATE(),1,0)

							SET @CommonJournalBatchDetailId = SCOPE_IDENTITY()

							-----  Accounting MS Entry  -----

							EXEC [dbo].[PROCAddUpdateAccountingBatchMSData] @CommonJournalBatchDetailId,@ManagementStructureId,@MasterCompanyId,@UpdateBy,@AccountMSModuleId,1; 
					

							INSERT INTO [dbo].[WorkOrderBatchDetails]
								(JournalBatchDetailId,[JournalBatchHeaderId],[ReferenceId],[ReferenceName],[MPNPartId],[MPNName],[PiecePNId],[PiecePN],[CustomerId],[CustomerName] ,[InvoiceId],[InvoiceName],[ARControlNum] ,[CustRefNumber] ,Qty,UnitPrice,LaborHrs,DirectLaborCost,OverheadCost,CommonJournalBatchDetailId,Batchtype,DistributionSetupId ,[IsWorkOrder])
							VALUES
								(@JournalBatchDetailId,@JournalBatchHeaderId,@ReferenceId ,@WorkOrderNumber ,@ReferencePartId,@MPNName,@ReferencePieceId,@PiecePN,@CustomerId ,@CustomerName,null ,null,null,@CustRefNumber,@Qty,@UnitPrice,@LaborHrs,@DirectLaborCost,@OverheadCost,@CommonJournalBatchDetailId,@Batchtype,@DistributionSetupId ,1)

							IF(@laborType='DIRECTLABOR')
							BEGIN
								SELECT top 1 @DistributionSetupId=ID,@DistributionName=Name,@JournalTypeId =JournalTypeId,@GlAccountId=GlAccountId,@GlAccountNumber=GlAccountNumber,@GlAccountName=GlAccountName,@CrDrType = CRDRType 
								from DistributionSetup WITH(NOLOCK)  WHERE UPPER(DistributionSetupCode) =UPPER('DIRECTLABORP&LOFFSET') and DistributionMasterId =@DistributionMasterId  AND MasterCompanyId=@MasterCompanyId
							END

							INSERT INTO [dbo].[CommonBatchDetails]
								(JournalBatchDetailId,JournalTypeNumber,CurrentNumber,DistributionSetupId,DistributionName,[JournalBatchHeaderId],[LineNumber],[GlAccountId],[GlAccountNumber],[GlAccountName] ,[TransactionDate],[EntryDate] ,[JournalTypeId],[JournalTypeName],
								[IsDebit],[DebitAmount] ,[CreditAmount],[ManagementStructureId],[ModuleName],LastMSLevel,AllMSlevels,[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate] ,[IsActive] ,[IsDeleted])
							VALUES
								(@JournalBatchDetailId,@JournalTypeNumber,@currentNo,@DistributionSetupId,@DistributionName,@JournalBatchHeaderId,1 ,@GlAccountId ,@GlAccountNumber ,@GlAccountName,GETUTCDATE(),GETUTCDATE(),@JournalTypeId ,@JournalTypename ,
								CASE WHEN @CrDrType = 1 THEN 1 ELSE 0 END,
								CASE WHEN @CrDrType = 1 THEN @Amount ELSE 0 END,
								CASE WHEN @CrDrType = 1 THEN 0 ELSE @Amount END,
								@ManagementStructureId ,@ModuleName,@LastMSLevel,@AllMSlevels ,@MasterCompanyId,@UpdateBy,@UpdateBy,GETUTCDATE(),GETUTCDATE(),1,0)

							SET @CommonJournalBatchDetailId = SCOPE_IDENTITY()

							-----  Accounting MS Entry  -----

							EXEC [dbo].[PROCAddUpdateAccountingBatchMSData] @CommonJournalBatchDetailId,@ManagementStructureId,@MasterCompanyId,@UpdateBy,@AccountMSModuleId,1; 
					

							INSERT INTO [dbo].[WorkOrderBatchDetails]
								(JournalBatchDetailId,[JournalBatchHeaderId],[ReferenceId],[ReferenceName],[MPNPartId],[MPNName],[PiecePNId],[PiecePN],[CustomerId],[CustomerName] ,[InvoiceId],[InvoiceName],[ARControlNum] ,[CustRefNumber] ,
								Qty,UnitPrice,LaborHrs,DirectLaborCost,OverheadCost,CommonJournalBatchDetailId,Batchtype,DistributionSetupId ,[IsWorkOrder])
							VALUES
								(@JournalBatchDetailId,@JournalBatchHeaderId,@ReferenceId ,@WorkOrderNumber ,@ReferencePartId,@MPNName,@ReferencePieceId,@PiecePN,@CustomerId ,@CustomerName,null ,null,null,@CustRefNumber,
								@Qty,@UnitPrice,@LaborHrs,@DirectLaborCost,@OverheadCost,@CommonJournalBatchDetailId,@Batchtype,@DistributionSetupId,1)

							-----------------LABOROVERHEAD --------------------------
							SET @Amount=Isnull((CAST(@Hours AS INT) + (@Hours - CAST(@Hours AS INT))/.6)*@burdentRate,0)
							SET @OverheadCost=@Amount
							SET @DirectLaborCost=0
							SELECT top 1 @DistributionSetupId=ID,@DistributionName=Name,@JournalTypeId =JournalTypeId,@GlAccountId=GlAccountId,@GlAccountNumber=GlAccountNumber,@GlAccountName=GlAccountName,@CrDrType = CRDRType 
							FROM DistributionSetup WITH(NOLOCK)  WHERE UPPER(DistributionSetupCode) =UPPER('WIPOVERHEAD') and DistributionMasterId =@DistributionMasterId AND MasterCompanyId=@MasterCompanyId

							INSERT INTO [dbo].[CommonBatchDetails]
								(JournalBatchDetailId,JournalTypeNumber,CurrentNumber,DistributionSetupId,DistributionName,[JournalBatchHeaderId],[LineNumber],[GlAccountId],[GlAccountNumber],[GlAccountName] ,[TransactionDate],[EntryDate] ,[JournalTypeId],[JournalTypeName],
								[IsDebit],[DebitAmount] ,[CreditAmount],[ManagementStructureId],[ModuleName],LastMSLevel,AllMSlevels,[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate] ,[IsActive] ,[IsDeleted])
							VALUES
								(@JournalBatchDetailId,@JournalTypeNumber,@currentNo,@DistributionSetupId,@DistributionName,@JournalBatchHeaderId,1 ,@GlAccountId ,@GlAccountNumber ,@GlAccountName,GETUTCDATE(),GETUTCDATE(),@JournalTypeId ,@JournalTypename ,
								CASE WHEN @CrDrType = 1 THEN 1 ELSE 0 END,
								CASE WHEN @CrDrType = 1 THEN @Amount ELSE 0 END,
								CASE WHEN @CrDrType = 1 THEN 0 ELSE @Amount END
								,@ManagementStructureId ,@ModuleName,@LastMSLevel,@AllMSlevels ,@MasterCompanyId,@UpdateBy,@UpdateBy,GETUTCDATE(),GETUTCDATE(),1,0)

							SET @CommonJournalBatchDetailId = SCOPE_IDENTITY()

							-----  Accounting MS Entry  -----

							EXEC [dbo].[PROCAddUpdateAccountingBatchMSData] @CommonJournalBatchDetailId,@ManagementStructureId,@MasterCompanyId,@UpdateBy,@AccountMSModuleId,1; 
					

							INSERT INTO [dbo].[WorkOrderBatchDetails]
								(JournalBatchDetailId,[JournalBatchHeaderId],[ReferenceId],[ReferenceName],[MPNPartId],[MPNName],[PiecePNId],[PiecePN],[CustomerId],[CustomerName] ,[InvoiceId],[InvoiceName],[ARControlNum] ,[CustRefNumber] ,
								Qty,UnitPrice,LaborHrs,DirectLaborCost,OverheadCost,CommonJournalBatchDetailId,Batchtype,DistributionSetupId ,[IsWorkOrder])
							VALUES
								(@JournalBatchDetailId,@JournalBatchHeaderId,@ReferenceId ,@WorkOrderNumber ,@ReferencePartId,@MPNName,@ReferencePieceId,@PiecePN,@CustomerId ,@CustomerName,null ,null,null,@CustRefNumber,
								@Qty,@UnitPrice,@LaborHrs,@DirectLaborCost,@OverheadCost,@CommonJournalBatchDetailId,@Batchtype,@DistributionSetupId,1)

							----------OVERHEADP&LOFFSET--------------------

							SELECT top 1 @DistributionSetupId=ID,@DistributionName=Name,@JournalTypeId =JournalTypeId,@GlAccountId=GlAccountId,@GlAccountNumber=GlAccountNumber,@GlAccountName=GlAccountName,@CrDrType = CRDRType  
							FROM DistributionSetup WITH(NOLOCK)  WHERE UPPER(DistributionSetupCode) =UPPER('OVERHEADP&LOFFSET') and DistributionMasterId =@DistributionMasterId AND MasterCompanyId=@MasterCompanyId

							INSERT INTO [dbo].[CommonBatchDetails]
								(JournalBatchDetailId,JournalTypeNumber,CurrentNumber,DistributionSetupId,DistributionName,[JournalBatchHeaderId],[LineNumber],[GlAccountId],[GlAccountNumber],[GlAccountName] ,[TransactionDate],[EntryDate] ,[JournalTypeId],[JournalTypeName],
								[IsDebit],[DebitAmount] ,[CreditAmount],[ManagementStructureId],[ModuleName],LastMSLevel,AllMSlevels,[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate] ,[IsActive] ,[IsDeleted])
							VALUES
								(@JournalBatchDetailId,@JournalTypeNumber,@currentNo,@DistributionSetupId,@DistributionName,@JournalBatchHeaderId,1 ,@GlAccountId ,@GlAccountNumber ,@GlAccountName,GETUTCDATE(),GETUTCDATE(),@JournalTypeId ,@JournalTypename ,
								CASE WHEN @CrDrType = 1 THEN 1 ELSE 0 END,
								CASE WHEN @CrDrType = 1 THEN @Amount ELSE 0 END,
								CASE WHEN @CrDrType = 1 THEN 0 ELSE @Amount END
								,@ManagementStructureId ,@ModuleName,@LastMSLevel,@AllMSlevels ,@MasterCompanyId,@UpdateBy,@UpdateBy,GETUTCDATE(),GETUTCDATE(),1,0)

							SET @CommonJournalBatchDetailId = SCOPE_IDENTITY()

							-----  Accounting MS Entry  -----

							EXEC [dbo].[PROCAddUpdateAccountingBatchMSData] @CommonJournalBatchDetailId,@ManagementStructureId,@MasterCompanyId,@UpdateBy,@AccountMSModuleId,1; 
					

							INSERT INTO [dbo].[WorkOrderBatchDetails]
								(JournalBatchDetailId,[JournalBatchHeaderId],[ReferenceId],[ReferenceName],[MPNPartId],[MPNName],[PiecePNId],[PiecePN],[CustomerId],[CustomerName] ,[InvoiceId],[InvoiceName],[ARControlNum] ,[CustRefNumber] ,
								Qty,UnitPrice,LaborHrs,DirectLaborCost,OverheadCost,CommonJournalBatchDetailId,Batchtype,DistributionSetupId,[IsWorkOrder])
							VALUES
								(@JournalBatchDetailId,@JournalBatchHeaderId,@ReferenceId ,@WorkOrderNumber ,@ReferencePartId,@MPNName,@ReferencePieceId,@PiecePN,@CustomerId ,@CustomerName,null ,null,null,@CustRefNumber,
								@Qty,@UnitPrice,@LaborHrs,@DirectLaborCost,@OverheadCost,@CommonJournalBatchDetailId,@Batchtype,@DistributionSetupId,1)

							SET @TotalDebit=0;
							SET @TotalCredit=0;
							SELECT @TotalDebit =SUM(DebitAmount),@TotalCredit=SUM(CreditAmount) FROM [dbo].[CommonBatchDetails] WITH(NOLOCK) WHERE JournalBatchDetailId=@JournalBatchDetailId group by JournalBatchDetailId
							Update BatchDetails set DebitAmount=@TotalDebit,CreditAmount=@TotalCredit,UpdatedDate=GETUTCDATE(),UpdatedBy=@UpdateBy WHERE JournalBatchDetailId=@JournalBatchDetailId		

						END

					END

					SELECT @TotalDebit =SUM(DebitAmount),@TotalCredit=SUM(CreditAmount) FROM BatchDetails WITH(NOLOCK) WHERE JournalBatchHeaderId=@JournalBatchHeaderId and IsDeleted=0 group by JournalBatchHeaderId
			   	                   
					SET @TotalBalance =@TotalDebit-@TotalCredit
				                   
					Update BatchHeader set TotalDebit=@TotalDebit,TotalCredit=@TotalCredit,TotalBalance=@TotalBalance,UpdatedDate=GETUTCDATE(),UpdatedBy=@UpdateBy   WHERE JournalBatchHeaderId= @JournalBatchHeaderId
					IF(@isNewJENum = 1 AND @JournalBatchDetailId > 0)
					BEGIN
						UPDATE CodePrefixes SET CurrentNummber = @currentNo WHERE CodeTypeId = @CodeTypeId AND MasterCompanyId = @MasterCompanyId
					END
				END

				IF(UPPER(@DistributionCode) = UPPER('WOSETTLEMENTTAB'))
				BEGIN
					SELECT @MaterialCost=PartsCost,@LaborCost=(Isnull(WOPN.LaborCost,0)-Isnull(WOPN.OverHeadCost,0)),@LaborOverHeadCost=(Isnull(WOPN.OverHeadCost,0)) from WorkOrderMPNCostDetails  WOPN WITH(NOLOCK)
							WHERE WOPN.WOPartNoId=@partId 
					 
					SET @FinishGoodAmount=Isnull((@MaterialCost+@LaborCost+@LaborOverHeadCost),0)

					SET @JournalBatchDetailId = CASE WHEN @StartCount = 1 THEN 0 ELSE @JournalBatchDetailId END;

					IF EXISTS(SELECT 1 FROM dbo.DistributionSetup WITH(NOLOCK) WHERE DistributionMasterId =@DistributionMasterId AND MasterCompanyId=@MasterCompanyId AND ISNULL(GlAccountId,0) = 0)
					BEGIN
						SET @ValidDistribution = 0;
					END

				
					IF(@issued = 1 AND @ValidDistribution = 1)
					BEGIN
						-----Finish Goods------
						IF(@FinishGoodAmount > 0 )
						BEGIN
							SELECT top 1 @DistributionSetupId=ID,@DistributionName=Name,@JournalTypeId =JournalTypeId,@GlAccountId=GlAccountId,@GlAccountNumber=GlAccountNumber,@GlAccountName=GlAccountName,@CrDrType = CRDRType,@IsAutoPost = ISNULL(IsAutoPost,0)
							FROM DistributionSetup WITH(NOLOCK)  WHERE UPPER(DistributionSetupCode) = UPPER('FGINVENTROY') and DistributionMasterId =@DistributionMasterId AND MasterCompanyId=@MasterCompanyId
				        
							IF NOT EXISTS(SELECT JournalBatchHeaderId FROM BatchHeader WITH(NOLOCK)  WHERE JournalTypeId= @JournalTypeId and MasterCompanyId=@MasterCompanyId and  CAST(EntryDate AS DATE) = CAST(GETUTCDATE() AS DATE)and StatusId=@StatusId)
							BEGIN
								IF NOT EXISTS(SELECT JournalBatchHeaderId FROM BatchHeader WITH(NOLOCK))
								BEGIN	
									SET @batch ='001'
									SET @Currentbatch='001'
								END
								ELSE
								BEGIN
									SELECT top 1 @Currentbatch = CASE WHEN CurrentNumber > 0 THEN CAST(CurrentNumber AS BIGINT) + 1 ELSE  1 END 
				   					FROM BatchHeader WITH(NOLOCK) Order by JournalBatchHeaderId desc 

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
								Update BatchHeader set CurrentNumber=@CurrentNumber  WHERE JournalBatchHeaderId= @JournalBatchHeaderId

								--AutoPost Batch
								IF(@IsAutoPost = 1)
								BEGIN
									EXEC [dbo].[UpdateToPostFullBatch] @JournalBatchHeaderId,@UpdateBy;
								END
							END
							ELSE
							BEGIN
								SELECT @JournalBatchHeaderId=JournalBatchHeaderId,@CurrentPeriodId=isnull(AccountingPeriodId,0) FROM BatchHeader WITH(NOLOCK)  WHERE JournalTypeId= @JournalTypeId and StatusId=@StatusId
								SELECT @LineNumber = CASE WHEN LineNumber > 0 THEN CAST(LineNumber AS BIGINT) + 1 ELSE  1 END 
				   										FROM BatchDetails WITH(NOLOCK) WHERE JournalBatchHeaderId=@JournalBatchHeaderId  Order by JournalBatchDetailId desc 
				    
								IF(@CurrentPeriodId =0)
								BEGIN
									Update BatchHeader set AccountingPeriodId=@AccountingPeriodId,AccountingPeriod=@AccountingPeriod   WHERE JournalBatchHeaderId= @JournalBatchHeaderId
								END

								--AutoPost Batch
								IF(@IsAutoPost = 1)
								BEGIN
									EXEC [dbo].[UpdateToPostFullBatch] @JournalBatchHeaderId,@UpdateBy;
								END
							END

							IF(@JournalBatchDetailId = 0)
							BEGIN
								INSERT INTO [dbo].[BatchDetails]
									(JournalTypeNumber,CurrentNumber,DistributionSetupId,DistributionName,[JournalBatchHeaderId],[LineNumber],[GlAccountId],[GlAccountNumber],[GlAccountName] ,[TransactionDate],[EntryDate],[JournalTypeId],[JournalTypeName],
									[IsDebit],[DebitAmount] ,[CreditAmount],[ManagementStructureId],[ModuleName],LastMSLevel,AllMSlevels,[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate] ,[IsActive] ,[IsDeleted],[AccountingPeriodId],[AccountingPeriod])
								VALUES
									(@JournalTypeNumber,@currentNo,@DistributionSetupId,@DistributionName,@JournalBatchHeaderId,1 ,@GlAccountId ,@GlAccountNumber ,@GlAccountName,GETUTCDATE(),GETUTCDATE(),@JournalTypeId ,@JournalTypename ,
									1,0,0,@ManagementStructureId ,@ModuleName,@LastMSLevel,@AllMSlevels ,@MasterCompanyId,@UpdateBy,@UpdateBy,GETUTCDATE(),GETUTCDATE(),1,0,@AccountingPeriodId,@AccountingPeriod)
					    
								SET @JournalBatchDetailId=SCOPE_IDENTITY()
							END

							INSERT INTO [dbo].[CommonBatchDetails]
								(JournalBatchDetailId,JournalTypeNumber,CurrentNumber,DistributionSetupId,DistributionName,[JournalBatchHeaderId],[LineNumber],[GlAccountId],[GlAccountNumber],[GlAccountName] ,[TransactionDate],[EntryDate] ,[JournalTypeId],[JournalTypeName],
								[IsDebit],[DebitAmount] ,[CreditAmount],[ManagementStructureId],[ModuleName],LastMSLevel,AllMSlevels,[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate] ,[IsActive] ,[IsDeleted])
							VALUES
								(@JournalBatchDetailId,@JournalTypeNumber,@currentNo,@DistributionSetupId,@DistributionName,@JournalBatchHeaderId,1 ,@GlAccountId ,@GlAccountNumber ,@GlAccountName,GETUTCDATE(),GETUTCDATE(),@JournalTypeId ,@JournalTypename,
								CASE WHEN @CrDrType = 1 THEN 1 ELSE 0 END,
								CASE WHEN @CrDrType = 1 THEN @FinishGoodAmount ELSE 0 END,
								CASE WHEN @CrDrType = 1 THEN 0 ELSE @FinishGoodAmount END
								,@ManagementStructureId ,@ModuleName,@LastMSLevel,@AllMSlevels ,@MasterCompanyId,@UpdateBy,@UpdateBy,GETUTCDATE(),GETUTCDATE(),1,0)
					    
							SET @CommonJournalBatchDetailId = SCOPE_IDENTITY()

							-----  Accounting MS Entry  -----

							EXEC [dbo].[PROCAddUpdateAccountingBatchMSData] @CommonJournalBatchDetailId,@ManagementStructureId,@MasterCompanyId,@UpdateBy,@AccountMSModuleId,1; 
					    
							INSERT INTO [dbo].[WorkOrderBatchDetails]
								(JournalBatchDetailId,[JournalBatchHeaderId],[ReferenceId],[ReferenceName],[MPNPartId],[MPNName],[PiecePNId],[PiecePN],[CustomerId],[CustomerName] ,[InvoiceId],[InvoiceName],[ARControlNum] ,[CustRefNumber] ,Qty,UnitPrice,LaborHrs,DirectLaborCost,OverheadCost,CommonJournalBatchDetailId,[IsWorkOrder])
							VALUES
								(@JournalBatchDetailId,@JournalBatchHeaderId,@ReferenceId ,@WorkOrderNumber ,@ReferencePartId,@MPNName,@ReferencePieceId,@PiecePN,@CustomerId ,@CustomerName,null ,null,null,@CustRefNumber,@Qty,@UnitPrice,@LaborHrs,@DirectLaborCost,@OverheadCost,@CommonJournalBatchDetailId,1)
					    
							IF(@MaterialCost > 0)
							BEGIN
								SELECT top 1 @DistributionSetupId=ID,@DistributionName=Name,@JournalTypeId =JournalTypeId,@GlAccountId=GlAccountId,@GlAccountNumber=GlAccountNumber,@GlAccountName=GlAccountName,@CrDrType = CRDRType 
								FROM DistributionSetup WITH(NOLOCK)  WHERE UPPER(DistributionSetupCode) =UPPER('FG-WIP-PARTS') and DistributionMasterId =@DistributionMasterId AND MasterCompanyId=@MasterCompanyId
					    
								INSERT INTO [dbo].[CommonBatchDetails]
									(JournalBatchDetailId,JournalTypeNumber,CurrentNumber,DistributionSetupId,DistributionName,[JournalBatchHeaderId],[LineNumber],[GlAccountId],[GlAccountNumber],[GlAccountName] ,[TransactionDate],[EntryDate] ,[JournalTypeId],[JournalTypeName],
									[IsDebit],[DebitAmount] ,[CreditAmount],[ManagementStructureId],[ModuleName],LastMSLevel,AllMSlevels,[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate] ,[IsActive] ,[IsDeleted])
								VALUES
									(@JournalBatchDetailId,@JournalTypeNumber,@currentNo,@DistributionSetupId,@DistributionName,@JournalBatchHeaderId,1 ,@GlAccountId ,@GlAccountNumber ,@GlAccountName,GETUTCDATE(),GETUTCDATE(),@JournalTypeId ,@JournalTypename,
									CASE WHEN @CrDrType = 1 THEN 1 ELSE 0 END,
									CASE WHEN @CrDrType = 1 THEN @MaterialCost ELSE 0 END,
									CASE WHEN @CrDrType = 1 THEN 0 ELSE @MaterialCost END
									,@ManagementStructureId ,@ModuleName,@LastMSLevel,@AllMSlevels ,@MasterCompanyId,@UpdateBy,@UpdateBy,GETUTCDATE(),GETUTCDATE(),1,0)
					    
								SET @CommonJournalBatchDetailId = SCOPE_IDENTITY()

								-----  Accounting MS Entry  -----

								EXEC [dbo].[PROCAddUpdateAccountingBatchMSData] @CommonJournalBatchDetailId,@ManagementStructureId,@MasterCompanyId,@UpdateBy,@AccountMSModuleId,1; 
					    
								INSERT INTO [dbo].[WorkOrderBatchDetails]
									(JournalBatchDetailId,[JournalBatchHeaderId],[ReferenceId],[ReferenceName],[MPNPartId],[MPNName],[PiecePNId],[PiecePN],[CustomerId],[CustomerName] ,[InvoiceId],[InvoiceName],[ARControlNum] ,[CustRefNumber] ,Qty,UnitPrice,LaborHrs,DirectLaborCost,OverheadCost,CommonJournalBatchDetailId ,[IsWorkOrder])
								VALUES
									(@JournalBatchDetailId,@JournalBatchHeaderId,@ReferenceId ,@WorkOrderNumber ,@ReferencePartId,@MPNName,@ReferencePieceId,@PiecePN,@CustomerId ,@CustomerName,null ,null,null,@CustRefNumber,@Qty,@UnitPrice,@LaborHrs,@DirectLaborCost,@OverheadCost,@CommonJournalBatchDetailId,1)
							END
						END

						-----WIPDIRECTLABOR------

						IF(@LaborCost >0)
						BEGIN
							SELECT top 1 @DistributionSetupId=ID,@DistributionName=Name,@JournalTypeId =JournalTypeId,@GlAccountId=GlAccountId,@GlAccountNumber=GlAccountNumber,@GlAccountName=GlAccountName,@CrDrType = CRDRType
							FROM DistributionSetup WITH(NOLOCK)  WHERE UPPER(DistributionSetupCode) =UPPER('FG-WIP-LABOR') and DistributionMasterId =@DistributionMasterId AND MasterCompanyId=@MasterCompanyId

							INSERT INTO [dbo].[CommonBatchDetails]
								(JournalBatchDetailId,JournalTypeNumber,CurrentNumber,DistributionSetupId,DistributionName,[JournalBatchHeaderId],[LineNumber],[GlAccountId],[GlAccountNumber],[GlAccountName] ,[TransactionDate],[EntryDate] ,[JournalTypeId],[JournalTypeName],
								[IsDebit],[DebitAmount] ,[CreditAmount],[ManagementStructureId],[ModuleName],LastMSLevel,AllMSlevels,[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate] ,[IsActive] ,[IsDeleted])
							VALUES
								(@JournalBatchDetailId,@JournalTypeNumber,@currentNo,@DistributionSetupId,@DistributionName,@JournalBatchHeaderId,1 ,@GlAccountId ,@GlAccountNumber ,@GlAccountName,GETUTCDATE(),GETUTCDATE(),@JournalTypeId ,@JournalTypename,
								CASE WHEN @CrDrType = 1 THEN 1 ELSE 0 END,
								CASE WHEN @CrDrType = 1 THEN @LaborCost ELSE 0 END,
								CASE WHEN @CrDrType = 1 THEN 0 ELSE @LaborCost END
								,@ManagementStructureId ,@ModuleName,@LastMSLevel,@AllMSlevels ,@MasterCompanyId,@UpdateBy,@UpdateBy,GETUTCDATE(),GETUTCDATE(),1,0)

							SET @CommonJournalBatchDetailId = SCOPE_IDENTITY()

							-----  Accounting MS Entry  -----

							EXEC [dbo].[PROCAddUpdateAccountingBatchMSData] @CommonJournalBatchDetailId,@ManagementStructureId,@MasterCompanyId,@UpdateBy,@AccountMSModuleId,1; 

							INSERT INTO [dbo].[WorkOrderBatchDetails]
								(JournalBatchDetailId,[JournalBatchHeaderId],[ReferenceId],[ReferenceName],[MPNPartId],[MPNName],[PiecePNId],[PiecePN],[CustomerId],[CustomerName] ,[InvoiceId],[InvoiceName],[ARControlNum] ,[CustRefNumber] ,Qty,UnitPrice,LaborHrs,DirectLaborCost,OverheadCost,CommonJournalBatchDetailId ,[IsWorkOrder])
							VALUES
								(@JournalBatchDetailId,@JournalBatchHeaderId,@ReferenceId ,@WorkOrderNumber ,@ReferencePartId,@MPNName,@ReferencePieceId,@PiecePN,@CustomerId ,@CustomerName,null ,null,null,@CustRefNumber,@Qty,@UnitPrice,@LaborHrs,@LaborCost,0,@CommonJournalBatchDetailId ,1)

						END

						-----WIPOVERHEAD------
						IF(@LaborOverHeadCost >0)
						BEGIN

							SELECT top 1 @DistributionSetupId=ID,@DistributionName=Name,@JournalTypeId =JournalTypeId,@GlAccountId=GlAccountId,@GlAccountNumber=GlAccountNumber,@GlAccountName=GlAccountName,@CrDrType = CRDRType
							FROM DistributionSetup WITH(NOLOCK)  WHERE UPPER(DistributionSetupCode) =UPPER('FG-WIP-OVERHEAD') and DistributionMasterId =@DistributionMasterId AND MasterCompanyId=@MasterCompanyId


							INSERT INTO [dbo].[CommonBatchDetails]
								(JournalBatchDetailId,JournalTypeNumber,CurrentNumber,DistributionSetupId,DistributionName,[JournalBatchHeaderId],[LineNumber],[GlAccountId],[GlAccountNumber],[GlAccountName] ,[TransactionDate],[EntryDate] ,[JournalTypeId],[JournalTypeName],
								[IsDebit],[DebitAmount] ,[CreditAmount],[ManagementStructureId],[ModuleName],LastMSLevel,AllMSlevels,[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate] ,[IsActive] ,[IsDeleted])
							VALUES
								(@JournalBatchDetailId,@JournalTypeNumber,@currentNo,@DistributionSetupId,@DistributionName,@JournalBatchHeaderId,1 ,@GlAccountId ,@GlAccountNumber ,@GlAccountName,GETUTCDATE(),GETUTCDATE(),@JournalTypeId ,@JournalTypename,
								CASE WHEN @CrDrType = 1 THEN 1 ELSE 0 END,
								CASE WHEN @CrDrType = 1 THEN @LaborOverHeadCost ELSE 0 END,
								CASE WHEN @CrDrType = 1 THEN 0 ELSE @LaborOverHeadCost END
								,@ManagementStructureId ,@ModuleName,@LastMSLevel,@AllMSlevels ,@MasterCompanyId,@UpdateBy,@UpdateBy,GETUTCDATE(),GETUTCDATE(),1,0)

							SET @CommonJournalBatchDetailId = SCOPE_IDENTITY()

							-----  Accounting MS Entry  -----

							EXEC [dbo].[PROCAddUpdateAccountingBatchMSData] @CommonJournalBatchDetailId,@ManagementStructureId,@MasterCompanyId,@UpdateBy,@AccountMSModuleId,1; 

							INSERT INTO [dbo].[WorkOrderBatchDetails]
								(JournalBatchDetailId,[JournalBatchHeaderId],[ReferenceId],[ReferenceName],[MPNPartId],[MPNName],[PiecePNId],[PiecePN],[CustomerId],[CustomerName] ,[InvoiceId],[InvoiceName],[ARControlNum] ,[CustRefNumber] ,Qty,UnitPrice,LaborHrs,DirectLaborCost,OverheadCost,CommonJournalBatchDetailId,[IsWorkOrder])
							VALUES
								(@JournalBatchDetailId,@JournalBatchHeaderId,@ReferenceId ,@WorkOrderNumber ,@ReferencePartId,@MPNName,@ReferencePieceId,@PiecePN,@CustomerId ,@CustomerName,null ,null,null,@CustRefNumber,@Qty,@UnitPrice,@LaborHrs,0,@LaborOverHeadCost,@CommonJournalBatchDetailId ,1)
							
						END

						SET @TotalDebit=0;
						SET @TotalCredit=0;
						SELECT @TotalDebit =SUM(DebitAmount),@TotalCredit=SUM(CreditAmount) FROM [dbo].[CommonBatchDetails] WITH(NOLOCK) WHERE JournalBatchDetailId=@JournalBatchDetailId group by JournalBatchDetailId
						Update BatchDetails set DebitAmount=@TotalDebit,CreditAmount=@TotalCredit,UpdatedDate=GETUTCDATE(),UpdatedBy=@UpdateBy WHERE JournalBatchDetailId=@JournalBatchDetailId

					          
						SELECT @TotalDebit =SUM(DebitAmount),@TotalCredit=SUM(CreditAmount) FROM BatchDetails WITH(NOLOCK) WHERE JournalBatchHeaderId=@JournalBatchHeaderId and IsDeleted=0 group by JournalBatchHeaderId 	          
						SET @TotalBalance =@TotalDebit-@TotalCredit
						IF(@isNewJENum = 1 AND @JournalBatchDetailId > 0)
						BEGIN
							UPDATE CodePrefixes SET CurrentNummber = @currentNo WHERE CodeTypeId = @CodeTypeId AND MasterCompanyId = @MasterCompanyId  
						END
						Update BatchHeader set TotalDebit=@TotalDebit,TotalCredit=@TotalCredit,TotalBalance=@TotalBalance,UpdatedDate=GETUTCDATE(),UpdatedBy=@UpdateBy   WHERE JournalBatchHeaderId= @JournalBatchHeaderId

					END
				
					--REVERSE WORK ORDER SETTLEMENT A/C ENTRY
					IF(@issued = 0 AND @ValidDistribution = 1)
					BEGIN
					 print'11'
						-----Finish Goods------
						IF(@FinishGoodAmount > 0 )
						BEGIN
							SELECT top 1 @DistributionSetupId=ID,@DistributionName=Name,@JournalTypeId =JournalTypeId,@GlAccountId=GlAccountId,@GlAccountNumber=GlAccountNumber,@GlAccountName=GlAccountName,@CrDrType = CRDRType,@IsAutoPost = ISNULL(IsAutoPost,0)
							FROM DistributionSetup WITH(NOLOCK)  WHERE UPPER(DistributionSetupCode) =UPPER('FGINVENTROY') and DistributionMasterId =@DistributionMasterId AND MasterCompanyId=@MasterCompanyId
				        
							IF NOT EXISTS(SELECT JournalBatchHeaderId FROM BatchHeader WITH(NOLOCK)  WHERE JournalTypeId= @JournalTypeId and MasterCompanyId=@MasterCompanyId and  CAST(EntryDate AS DATE) = CAST(GETUTCDATE() AS DATE)and StatusId=@StatusId)
							BEGIN
								IF NOT EXISTS(SELECT JournalBatchHeaderId FROM BatchHeader WITH(NOLOCK))
								BEGIN	
									SET @batch ='001'
									SET @Currentbatch='001'
								END
								ELSE
								BEGIN
									SELECT top 1 @Currentbatch = CASE WHEN CurrentNumber > 0 THEN CAST(CurrentNumber AS BIGINT) + 1 ELSE  1 END 
				   					FROM BatchHeader WITH(NOLOCK) Order by JournalBatchHeaderId desc 

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
								Update BatchHeader set CurrentNumber=@CurrentNumber  WHERE JournalBatchHeaderId= @JournalBatchHeaderId

								--AutoPost Batch
								IF(@IsAutoPost = 1)
								BEGIN
									EXEC [dbo].[UpdateToPostFullBatch] @JournalBatchHeaderId,@UpdateBy;
								END
							END
							ELSE
							BEGIN
								SELECT @JournalBatchHeaderId=JournalBatchHeaderId,@CurrentPeriodId=isnull(AccountingPeriodId,0) FROM BatchHeader WITH(NOLOCK)  WHERE JournalTypeId= @JournalTypeId and StatusId=@StatusId
								SELECT @LineNumber = CASE WHEN LineNumber > 0 THEN CAST(LineNumber AS BIGINT) + 1 ELSE  1 END 
				   										FROM BatchDetails WITH(NOLOCK) WHERE JournalBatchHeaderId=@JournalBatchHeaderId  Order by JournalBatchDetailId desc 
				    
								IF(@CurrentPeriodId =0)
								BEGIN
									Update BatchHeader set AccountingPeriodId=@AccountingPeriodId,AccountingPeriod=@AccountingPeriod   WHERE JournalBatchHeaderId= @JournalBatchHeaderId
								END

								--AutoPost Batch
								IF(@IsAutoPost = 1)
								BEGIN
									EXEC [dbo].[UpdateToPostFullBatch] @JournalBatchHeaderId,@UpdateBy;
								END
							END

							IF(@JournalBatchDetailId = 0)
							BEGIN
								INSERT INTO [dbo].[BatchDetails]
									(JournalTypeNumber,CurrentNumber,DistributionSetupId,DistributionName,[JournalBatchHeaderId],[LineNumber],[GlAccountId],[GlAccountNumber],[GlAccountName] ,[TransactionDate],[EntryDate],[JournalTypeId],[JournalTypeName],
									[IsDebit],[DebitAmount] ,[CreditAmount],[ManagementStructureId],[ModuleName],LastMSLevel,AllMSlevels,[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate] ,[IsActive] ,[IsDeleted],[AccountingPeriodId],[AccountingPeriod],[IsReversedJE])
								VALUES
									(@JournalTypeNumber,@currentNo,@DistributionSetupId,@DistributionName,@JournalBatchHeaderId,1 ,@GlAccountId ,@GlAccountNumber ,@GlAccountName,GETUTCDATE(),GETUTCDATE(),@JournalTypeId ,@JournalTypename ,
									1,0,0,@ManagementStructureId ,@ModuleName,@LastMSLevel,@AllMSlevels ,@MasterCompanyId,@UpdateBy,@UpdateBy,GETUTCDATE(),GETUTCDATE(),1,0,@AccountingPeriodId,@AccountingPeriod, 1)
					    
								SET @JournalBatchDetailId=SCOPE_IDENTITY()
							END

							INSERT INTO [dbo].[CommonBatchDetails]
								(JournalBatchDetailId,JournalTypeNumber,CurrentNumber,DistributionSetupId,DistributionName,[JournalBatchHeaderId],[LineNumber],[GlAccountId],[GlAccountNumber],[GlAccountName] ,[TransactionDate],[EntryDate] ,[JournalTypeId],[JournalTypeName],
								[IsDebit],[DebitAmount] ,[CreditAmount],[ManagementStructureId],[ModuleName],LastMSLevel,AllMSlevels,[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate] ,[IsActive] ,[IsDeleted])
							VALUES
								(@JournalBatchDetailId,@JournalTypeNumber,@currentNo,@DistributionSetupId,@DistributionName,@JournalBatchHeaderId,1 ,@GlAccountId ,@GlAccountNumber ,@GlAccountName,GETUTCDATE(),GETUTCDATE(),@JournalTypeId ,@JournalTypename,
								CASE WHEN @CrDrType = 0 THEN 1 ELSE 0 END,
								CASE WHEN @CrDrType = 0 THEN @FinishGoodAmount ELSE 0 END,
								CASE WHEN @CrDrType = 0 THEN 0 ELSE @FinishGoodAmount END
								,@ManagementStructureId ,@ModuleName,@LastMSLevel,@AllMSlevels ,@MasterCompanyId,@UpdateBy,@UpdateBy,GETUTCDATE(),GETUTCDATE(),1,0)
					    
							SET @CommonJournalBatchDetailId = SCOPE_IDENTITY()

							-----  Accounting MS Entry  -----

							EXEC [dbo].[PROCAddUpdateAccountingBatchMSData] @CommonJournalBatchDetailId,@ManagementStructureId,@MasterCompanyId,@UpdateBy,@AccountMSModuleId,1; 
											    
							INSERT INTO [dbo].[WorkOrderBatchDetails]
								(JournalBatchDetailId,[JournalBatchHeaderId],[ReferenceId],[ReferenceName],[MPNPartId],[MPNName],[PiecePNId],[PiecePN],[CustomerId],[CustomerName] ,[InvoiceId],[InvoiceName],[ARControlNum] ,[CustRefNumber] ,Qty,UnitPrice,LaborHrs,DirectLaborCost,OverheadCost,CommonJournalBatchDetailId ,[IsWorkOrder])
							VALUES
								(@JournalBatchDetailId,@JournalBatchHeaderId,@ReferenceId ,@WorkOrderNumber ,@ReferencePartId,@MPNName,@ReferencePieceId,@PiecePN,@CustomerId ,@CustomerName,null ,null,null,@CustRefNumber,@Qty,@UnitPrice,@LaborHrs,@DirectLaborCost,@OverheadCost,@CommonJournalBatchDetailId ,1)
					    
							IF(@MaterialCost > 0)
							BEGIN
								SELECT top 1 @DistributionSetupId=ID,@DistributionName=Name,@JournalTypeId =JournalTypeId,@GlAccountId=GlAccountId,@GlAccountNumber=GlAccountNumber,@GlAccountName=GlAccountName,@CrDrType = CRDRType 
								FROM DistributionSetup WITH(NOLOCK)  WHERE UPPER(DistributionSetupCode) =UPPER('FG-WIP-PARTS') and DistributionMasterId =@DistributionMasterId AND MasterCompanyId=@MasterCompanyId
					    
								INSERT INTO [dbo].[CommonBatchDetails]
									(JournalBatchDetailId,JournalTypeNumber,CurrentNumber,DistributionSetupId,DistributionName,[JournalBatchHeaderId],[LineNumber],[GlAccountId],[GlAccountNumber],[GlAccountName] ,[TransactionDate],[EntryDate] ,[JournalTypeId],[JournalTypeName],
									[IsDebit],[DebitAmount] ,[CreditAmount],[ManagementStructureId],[ModuleName],LastMSLevel,AllMSlevels,[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate] ,[IsActive] ,[IsDeleted])
								VALUES
									(@JournalBatchDetailId,@JournalTypeNumber,@currentNo,@DistributionSetupId,@DistributionName,@JournalBatchHeaderId,1 ,@GlAccountId ,@GlAccountNumber ,@GlAccountName,GETUTCDATE(),GETUTCDATE(),@JournalTypeId ,@JournalTypename,
									CASE WHEN @CrDrType = 0 THEN 1 ELSE 0 END,
									CASE WHEN @CrDrType = 0 THEN @MaterialCost ELSE 0 END,
									CASE WHEN @CrDrType = 0 THEN 0 ELSE @MaterialCost END
									,@ManagementStructureId ,@ModuleName,@LastMSLevel,@AllMSlevels ,@MasterCompanyId,@UpdateBy,@UpdateBy,GETUTCDATE(),GETUTCDATE(),1,0)
					    
								SET @CommonJournalBatchDetailId = SCOPE_IDENTITY()

								-----  Accounting MS Entry  -----

								EXEC [dbo].[PROCAddUpdateAccountingBatchMSData] @CommonJournalBatchDetailId,@ManagementStructureId,@MasterCompanyId,@UpdateBy,@AccountMSModuleId,1; 

					    
								INSERT INTO [dbo].[WorkOrderBatchDetails]
									(JournalBatchDetailId,[JournalBatchHeaderId],[ReferenceId],[ReferenceName],[MPNPartId],[MPNName],[PiecePNId],[PiecePN],[CustomerId],[CustomerName] ,[InvoiceId],[InvoiceName],[ARControlNum] ,[CustRefNumber] ,Qty,UnitPrice,LaborHrs,DirectLaborCost,OverheadCost,CommonJournalBatchDetailId,[IsWorkOrder])
								VALUES
									(@JournalBatchDetailId,@JournalBatchHeaderId,@ReferenceId ,@WorkOrderNumber ,@ReferencePartId,@MPNName,@ReferencePieceId,@PiecePN,@CustomerId ,@CustomerName,null ,null,null,@CustRefNumber,@Qty,@UnitPrice,@LaborHrs,@DirectLaborCost,@OverheadCost,@CommonJournalBatchDetailId,1)
							END
						END

						-----WIPDIRECTLABOR------

						IF(@LaborCost >0)
						BEGIN
							SELECT top 1 @DistributionSetupId=ID,@DistributionName=Name,@JournalTypeId =JournalTypeId,@GlAccountId=GlAccountId,@GlAccountNumber=GlAccountNumber,@GlAccountName=GlAccountName,@CrDrType = CRDRType
							FROM DistributionSetup WITH(NOLOCK)  WHERE UPPER(DistributionSetupCode) =UPPER('FG-WIP-LABOR') and DistributionMasterId =@DistributionMasterId AND MasterCompanyId=@MasterCompanyId

							INSERT INTO [dbo].[CommonBatchDetails]
								(JournalBatchDetailId,JournalTypeNumber,CurrentNumber,DistributionSetupId,DistributionName,[JournalBatchHeaderId],[LineNumber],[GlAccountId],[GlAccountNumber],[GlAccountName] ,[TransactionDate],[EntryDate] ,[JournalTypeId],[JournalTypeName],
								[IsDebit],[DebitAmount] ,[CreditAmount],[ManagementStructureId],[ModuleName],LastMSLevel,AllMSlevels,[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate] ,[IsActive] ,[IsDeleted])
							VALUES
								(@JournalBatchDetailId,@JournalTypeNumber,@currentNo,@DistributionSetupId,@DistributionName,@JournalBatchHeaderId,1 ,@GlAccountId ,@GlAccountNumber ,@GlAccountName,GETUTCDATE(),GETUTCDATE(),@JournalTypeId ,@JournalTypename,
								CASE WHEN @CrDrType = 0 THEN 1 ELSE 0 END,
								CASE WHEN @CrDrType = 0 THEN @LaborCost ELSE 0 END,
								CASE WHEN @CrDrType = 0 THEN 0 ELSE @LaborCost END
								,@ManagementStructureId ,@ModuleName,@LastMSLevel,@AllMSlevels ,@MasterCompanyId,@UpdateBy,@UpdateBy,GETUTCDATE(),GETUTCDATE(),1,0)

							SET @CommonJournalBatchDetailId = SCOPE_IDENTITY()

							-----  Accounting MS Entry  -----

							EXEC [dbo].[PROCAddUpdateAccountingBatchMSData] @CommonJournalBatchDetailId,@ManagementStructureId,@MasterCompanyId,@UpdateBy,@AccountMSModuleId,1; 
						
							INSERT INTO [dbo].[WorkOrderBatchDetails]
								(JournalBatchDetailId,[JournalBatchHeaderId],[ReferenceId],[ReferenceName],[MPNPartId],[MPNName],[PiecePNId],[PiecePN],[CustomerId],[CustomerName] ,[InvoiceId],[InvoiceName],[ARControlNum] ,[CustRefNumber] ,Qty,UnitPrice,LaborHrs,DirectLaborCost,OverheadCost,CommonJournalBatchDetailId ,[IsWorkOrder])
							VALUES
								(@JournalBatchDetailId,@JournalBatchHeaderId,@ReferenceId ,@WorkOrderNumber ,@ReferencePartId,@MPNName,@ReferencePieceId,@PiecePN,@CustomerId ,@CustomerName,null ,null,null,@CustRefNumber,@Qty,@UnitPrice,@LaborHrs,@LaborCost,0,@CommonJournalBatchDetailId,1)

						END

						-----WIPOVERHEAD------
						IF(@LaborOverHeadCost > 0)
						BEGIN

							SELECT top 1 @DistributionSetupId=ID,@DistributionName=Name,@JournalTypeId =JournalTypeId,@GlAccountId=GlAccountId,@GlAccountNumber=GlAccountNumber,@GlAccountName=GlAccountName,@CrDrType = CRDRType
							FROM DistributionSetup WITH(NOLOCK)  WHERE UPPER(DistributionSetupCode) =UPPER('FG-WIP-OVERHEAD') and DistributionMasterId =@DistributionMasterId AND MasterCompanyId=@MasterCompanyId


							INSERT INTO [dbo].[CommonBatchDetails]
								(JournalBatchDetailId,JournalTypeNumber,CurrentNumber,DistributionSetupId,DistributionName,[JournalBatchHeaderId],[LineNumber],[GlAccountId],[GlAccountNumber],[GlAccountName] ,[TransactionDate],[EntryDate] ,[JournalTypeId],[JournalTypeName],
								[IsDebit],[DebitAmount] ,[CreditAmount],[ManagementStructureId],[ModuleName],LastMSLevel,AllMSlevels,[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate] ,[IsActive] ,[IsDeleted])
							VALUES
								(@JournalBatchDetailId,@JournalTypeNumber,@currentNo,@DistributionSetupId,@DistributionName,@JournalBatchHeaderId,1 ,@GlAccountId ,@GlAccountNumber ,@GlAccountName,GETUTCDATE(),GETUTCDATE(),@JournalTypeId ,@JournalTypename,
								CASE WHEN @CrDrType = 0 THEN 1 ELSE 0 END,
								CASE WHEN @CrDrType = 0 THEN @LaborOverHeadCost ELSE 0 END,
								CASE WHEN @CrDrType = 0 THEN 0 ELSE @LaborOverHeadCost END
								,@ManagementStructureId ,@ModuleName,@LastMSLevel,@AllMSlevels ,@MasterCompanyId,@UpdateBy,@UpdateBy,GETUTCDATE(),GETUTCDATE(),1,0)

							SET @CommonJournalBatchDetailId=SCOPE_IDENTITY()

							-----  Accounting MS Entry  -----

							EXEC [dbo].[PROCAddUpdateAccountingBatchMSData] @CommonJournalBatchDetailId,@ManagementStructureId,@MasterCompanyId,@UpdateBy,@AccountMSModuleId,1; 
						
							INSERT INTO [dbo].[WorkOrderBatchDetails]
								(JournalBatchDetailId,[JournalBatchHeaderId],[ReferenceId],[ReferenceName],[MPNPartId],[MPNName],[PiecePNId],[PiecePN],[CustomerId],[CustomerName] ,[InvoiceId],[InvoiceName],[ARControlNum] ,[CustRefNumber] ,Qty,UnitPrice,LaborHrs,DirectLaborCost,OverheadCost,CommonJournalBatchDetailId ,[IsWorkOrder])
							VALUES
								(@JournalBatchDetailId,@JournalBatchHeaderId,@ReferenceId ,@WorkOrderNumber ,@ReferencePartId,@MPNName,@ReferencePieceId,@PiecePN,@CustomerId ,@CustomerName,null ,null,null,@CustRefNumber,@Qty,@UnitPrice,@LaborHrs,0,@LaborOverHeadCost,@CommonJournalBatchDetailId ,1)
							
						END

						SET @TotalDebit=0;
						SET @TotalCredit=0;
						SELECT @TotalDebit =SUM(DebitAmount),@TotalCredit=SUM(CreditAmount) FROM [dbo].[CommonBatchDetails] WITH(NOLOCK) WHERE JournalBatchDetailId=@JournalBatchDetailId group by JournalBatchDetailId
						Update BatchDetails set DebitAmount=@TotalDebit,CreditAmount=@TotalCredit,UpdatedDate=GETUTCDATE(),UpdatedBy=@UpdateBy WHERE JournalBatchDetailId=@JournalBatchDetailId

					          
						SELECT @TotalDebit =SUM(DebitAmount),@TotalCredit=SUM(CreditAmount) FROM BatchDetails WITH(NOLOCK) WHERE JournalBatchHeaderId=@JournalBatchHeaderId and IsDeleted=0 group by JournalBatchHeaderId 	          
						SET @TotalBalance =@TotalDebit-@TotalCredit
						IF(@isNewJENum = 1 AND @JournalBatchDetailId > 0)
						BEGIN
							UPDATE CodePrefixes SET CurrentNummber = @currentNo WHERE CodeTypeId = @CodeTypeId AND MasterCompanyId = @MasterCompanyId    
						END
						Update BatchHeader set TotalDebit=@TotalDebit,TotalCredit=@TotalCredit,TotalBalance=@TotalBalance,UpdatedDate=GETUTCDATE(),UpdatedBy=@UpdateBy   WHERE JournalBatchHeaderId= @JournalBatchHeaderId

					END
				
				END

				--IF(UPPER(@DistributionCode) = UPPER('MROWOSHIPMENT'))
				--BEGIN
				--	SELECT @MaterialCost = SUM(ISNULL(WOPN.PartsCost,0)),
				--	       @LaborCost = (SUM(ISNULL(WOPN.LaborCost,0)) - SUM(ISNULL(WOPN.OverHeadCost,0))),
				--		   @LaborOverHeadCost = SUM(ISNULL(WOPN.OverHeadCost,0)) 
				--	  FROM [dbo].[WorkOrderMPNCostDetails] WOPN 
	   --             INNER JOIN [dbo].[WorkOrderShippingItem] WOBIT ON WOPN.WOPartNoId= WOBIT.WorkOrderPartNumId
	   --             WHERE WorkOrderShippingId = @InvoiceId 
				--	  AND WOBIT.IsDeleted = 0 GROUP BY WorkOrderShippingId
	
				--	SET @FinishGoodAmount = ISNULL((@MaterialCost + @LaborCost + @LaborOverHeadCost),0)

				--	 SELECT @LotId = STL.[LotId],
				--	        @LotNumber = LO.[LotNumber]		
				--	  FROM [dbo].[WorkOrderPartNumber] WOP WITH(NOLOCK) 
				--	  LEFT JOIN [dbo].[Stockline] STL ON WOP.[StockLineId] = STL.[StockLineId]
				--	  LEFT JOIN [dbo].[Lot] LO ON LO.[LotId] = STL.[LotId]			  
				--	  WHERE WOP.[ID] = @ReferencePartId;
				
				--	SELECT TOP 1 @DistributionSetupId = ID,
				--	             @DistributionName = Name,
				--				 @JournalTypeId = JournalTypeId,
				--				 @GlAccountId = GlAccountId,
				--				 @GlAccountNumber = GlAccountNumber,
				--				 @GlAccountName = GlAccountName,
				--				 @CrDrType = CRDRType
				--	        FROM [dbo].[DistributionSetup] WITH(NOLOCK)  
				--		    WHERE UPPER(DistributionSetupCode) = UPPER('MROWOINVENTORYTOBILL') 
				--			AND DistributionMasterId =@DistributionMasterId 
				--			AND MasterCompanyId=@MasterCompanyId

				--	IF EXISTS(SELECT 1 FROM dbo.DistributionSetup WITH(NOLOCK) WHERE DistributionMasterId =@DistributionMasterId AND MasterCompanyId=@MasterCompanyId AND ISNULL(GlAccountId,0) = 0)
				--	BEGIN
				--		SET @ValidDistribution = 0;
				--	END

				--	IF(@ValidDistribution = 1)
				--	BEGIN
				--		IF NOT EXISTS(SELECT woB.WorkOrderBatchId FROM dbo.WorkOrderBatchDetails woB WITH(NOLOCK)  WHERE PiecePNId = @ReferencePieceId AND DistributionSetupId=@DistributionSetupId)
				--		BEGIN
				--			IF(@FinishGoodAmount > 0)
				--			BEGIN							
				--				IF NOT EXISTS(SELECT JournalBatchHeaderId FROM dbo.BatchHeader WITH(NOLOCK)  WHERE JournalTypeId= @JournalTypeId and MasterCompanyId=@MasterCompanyId and  CAST(EntryDate AS DATE) = CAST(GETUTCDATE() AS DATE)and StatusId=@StatusId)
				--				BEGIN
				--					IF NOT EXISTS(SELECT JournalBatchHeaderId FROM dbo.BatchHeader WITH(NOLOCK))
				--					BEGIN	
				--						SET @batch ='001'
				--						SET @Currentbatch='001'
				--					END
				--					ELSE
				--					BEGIN
				--						SELECT top 1 @Currentbatch = CASE WHEN CurrentNumber > 0 THEN CAST(CurrentNumber AS BIGINT) + 1 ELSE  1 END 
				--	   					FROM BatchHeader WITH(NOLOCK) Order by JournalBatchHeaderId desc 

				--						IF(CAST(@Currentbatch AS BIGINT) >99)
				--						BEGIN

				--							SET @batch = CASE WHEN CAST(@Currentbatch AS BIGINT) > 99 THEN cast(@Currentbatch as VARCHAR(100))
				--	   						ELSE CONCAT('00', CAST(@Currentbatch AS VARCHAR(50))) END 
				--						END
				--						ELSE IF(CAST(@Currentbatch AS BIGINT) >9)
				--						BEGIN

				--							SET @batch = CASE WHEN CAST(@Currentbatch AS BIGINT) > 99 THEN cast(@Currentbatch as VARCHAR(100))
				--	   						ELSE CONCAT('0', CAST(@Currentbatch AS VARCHAR(50))) END 
				--						END
				--						ELSE
				--						BEGIN
				--							SET @batch = CASE WHEN CAST(@Currentbatch AS BIGINT) > 99 THEN cast(@Currentbatch as VARCHAR(100))
				--	   						ELSE CONCAT('00', CAST(@Currentbatch AS VARCHAR(50))) END 

				--						END
				--					END
								
				--					SET @CurrentNumber = CAST(@Currentbatch AS BIGINT) 
								
				--					SET @batch = CAST(@JournalTypeCode + ' ' + CAST(@batch AS VARCHAR(100)) AS VARCHAR(100))
												          
				--					INSERT INTO [dbo].[BatchHeader]
				--								([BatchName],[CurrentNumber],[EntryDate],[AccountingPeriod],AccountingPeriodId,[StatusId],[StatusName],[JournalTypeId],[JournalTypeName],[TotalDebit],[TotalCredit],[TotalBalance],[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted],[Module])
				--					VALUES
				--								(@batch,@CurrentNumber,GETUTCDATE(),@AccountingPeriod,@AccountingPeriodId,@StatusId,@StatusName,@JournalTypeId,@JournalTypename,0,0,0,@MasterCompanyId,@UpdateBy,@UpdateBy,GETUTCDATE(),GETUTCDATE(),1,0,@ModuleName);
            	          
				--					SELECT @JournalBatchHeaderId = SCOPE_IDENTITY()
								
				--					UPDATE [dbo].[BatchHeader] SET CurrentNumber = @CurrentNumber WHERE [JournalBatchHeaderId] = @JournalBatchHeaderId

				--				END
				--				ELSE
				--				BEGIN
				--					SELECT @JournalBatchHeaderId=JournalBatchHeaderId,@CurrentPeriodId=isnull(AccountingPeriodId,0) FROM BatchHeader WITH(NOLOCK)  WHERE JournalTypeId= @JournalTypeId and StatusId=@StatusId
				--					SELECT @LineNumber = CASE WHEN LineNumber > 0 THEN CAST(LineNumber AS BIGINT) + 1 ELSE  1 END 
				--	   										FROM BatchDetails WITH(NOLOCK) WHERE JournalBatchHeaderId=@JournalBatchHeaderId  Order by JournalBatchDetailId desc 
				    
				--					IF(@CurrentPeriodId =0)
				--					BEGIN
				--						Update BatchHeader set AccountingPeriodId=@AccountingPeriodId,AccountingPeriod=@AccountingPeriod   WHERE JournalBatchHeaderId= @JournalBatchHeaderId
				--					END
				--				END

				--				-----Inventory to Bill ------
				
				--				IF(@StartCount = 1)
				--				BEGIN
				--					INSERT INTO [dbo].[BatchDetails]
				--						(JournalTypeNumber,CurrentNumber,DistributionSetupId,DistributionName,[JournalBatchHeaderId],[LineNumber],[GlAccountId],[GlAccountNumber],[GlAccountName] ,[TransactionDate],[EntryDate],[JournalTypeId],[JournalTypeName],
				--						[IsDebit],[DebitAmount] ,[CreditAmount],[ManagementStructureId],[ModuleName],LastMSLevel,AllMSlevels,[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate] ,[IsActive] ,[IsDeleted],[AccountingPeriodId],[AccountingPeriod])
				--					VALUES
				--						(@JournalTypeNumber,@currentNo,@DistributionSetupId,@DistributionName,@JournalBatchHeaderId,1 ,@GlAccountId ,@GlAccountNumber ,@GlAccountName,GETUTCDATE(),GETUTCDATE(),@JournalTypeId ,@JournalTypename ,
				--						1,0,0,@ManagementStructureId ,@ModuleName,@LastMSLevel,@AllMSlevels ,@MasterCompanyId,@UpdateBy,@UpdateBy,GETUTCDATE(),GETUTCDATE(),1,0,@AccountingPeriodId,@AccountingPeriod)
							 
				--					SET @JournalBatchDetailId=SCOPE_IDENTITY()
				--				END
				--				 INSERT INTO [dbo].[CommonBatchDetails]
				--					 (JournalBatchDetailId,JournalTypeNumber,CurrentNumber,DistributionSetupId,DistributionName,[JournalBatchHeaderId],[LineNumber],[GlAccountId],[GlAccountNumber],[GlAccountName] ,[TransactionDate],[EntryDate] ,[JournalTypeId],[JournalTypeName],
				--					 [IsDebit],[DebitAmount] ,[CreditAmount],[ManagementStructureId],[ModuleName],LastMSLevel,AllMSlevels,[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate] ,[IsActive] ,[IsDeleted],[LotId],[LotNumber])
				--				 VALUES
				--					 (@JournalBatchDetailId,@JournalTypeNumber,@currentNo,@DistributionSetupId,@DistributionName,@JournalBatchHeaderId,1 ,@GlAccountId ,@GlAccountNumber ,@GlAccountName,GETUTCDATE(),GETUTCDATE(),@JournalTypeId ,@JournalTypename,
				--					 CASE WHEN @CrDrType = 1 THEN 1 ELSE 0 END,
				--					 CASE WHEN @CrDrType = 1 THEN @FinishGoodAmount ELSE 0 END,
				--					 CASE WHEN @CrDrType = 1 THEN 0 ELSE @FinishGoodAmount END
				--					 ,@ManagementStructureId ,@ModuleName,@LastMSLevel,@AllMSlevels ,@MasterCompanyId,@UpdateBy,@UpdateBy,GETUTCDATE(),GETUTCDATE(),1,0,@LotId,@LotNumber)

				--				 SET @CommonJournalBatchDetailId=SCOPE_IDENTITY()

				--				 -----  Accounting MS Entry  -----

				--				EXEC [dbo].[PROCAddUpdateAccountingBatchMSData] @CommonJournalBatchDetailId,@ManagementStructureId,@MasterCompanyId,@UpdateBy,@AccountMSModuleId,1; 

				--				 INSERT INTO [dbo].[WorkOrderBatchDetails]
				--					(JournalBatchDetailId,[JournalBatchHeaderId],[ReferenceId],[ReferenceName],[MPNPartId],[MPNName],[PiecePNId],[PiecePN],[CustomerId],[CustomerName] ,[InvoiceId],[InvoiceName],[ARControlNum] ,[CustRefNumber] ,Qty,UnitPrice,LaborHrs,DirectLaborCost,OverheadCost,CommonJournalBatchDetailId,DistributionSetupId,[IsWorkOrder])
				--				 VALUES
				--					(@JournalBatchDetailId,@JournalBatchHeaderId,@ReferenceId ,@WorkOrderNumber ,@ReferencePartId,@MPNName,@ReferencePieceId,@PiecePN,@CustomerId ,@CustomerName,null ,null,null,@CustRefNumber,@Qty,@UnitPrice,@LaborHrs,@DirectLaborCost,@OverheadCost,@CommonJournalBatchDetailId,@DistributionSetupId,1)

				--				 SELECT TOP 1 @DistributionSetupId=ID,
				--				              @DistributionName=Name,
				--							  @JournalTypeId =JournalTypeId,
				--							  @GlAccountId=GlAccountId,
				--							  @GlAccountNumber=GlAccountNumber,
				--							  @GlAccountName=GlAccountName,
				--							  @CrDrType = CRDRType
				--				 FROM [dbo].[DistributionSetup] WITH(NOLOCK)  WHERE UPPER(DistributionSetupCode) =UPPER('MROWOFGINVENTROY') and DistributionMasterId =@DistributionMasterId AND MasterCompanyId=@MasterCompanyId

				--				  INSERT INTO [dbo].[CommonBatchDetails]
				--					  (JournalBatchDetailId,JournalTypeNumber,CurrentNumber,DistributionSetupId,DistributionName,[JournalBatchHeaderId],[LineNumber],[GlAccountId],[GlAccountNumber],[GlAccountName] ,[TransactionDate],[EntryDate] ,[JournalTypeId],[JournalTypeName],
				--					  [IsDebit],[DebitAmount] ,[CreditAmount],[ManagementStructureId],[ModuleName],LastMSLevel,AllMSlevels,[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate] ,[IsActive] ,[IsDeleted],[LotId],[LotNumber])
				--				  VALUES
				--					  (@JournalBatchDetailId,@JournalTypeNumber,@currentNo,@DistributionSetupId,@DistributionName,@JournalBatchHeaderId,1 ,@GlAccountId ,@GlAccountNumber ,@GlAccountName,GETUTCDATE(),GETUTCDATE(),@JournalTypeId ,@JournalTypename,
				--					  CASE WHEN @CrDrType = 1 THEN 1 ELSE 0 END,
				--					  CASE WHEN @CrDrType = 1 THEN @FinishGoodAmount ELSE 0 END,
				--					  CASE WHEN @CrDrType = 1 THEN 0 ELSE @FinishGoodAmount END
				--					 ,@ManagementStructureId ,@ModuleName,@LastMSLevel,@AllMSlevels ,@MasterCompanyId,@UpdateBy,@UpdateBy,GETUTCDATE(),GETUTCDATE(),1,0,@LotId,@LotNumber)

				--				  SET @CommonJournalBatchDetailId = SCOPE_IDENTITY()

				--				  -----  Accounting MS Entry  -----

				--				  EXEC [dbo].[PROCAddUpdateAccountingBatchMSData] @CommonJournalBatchDetailId,@ManagementStructureId,@MasterCompanyId,@UpdateBy,@AccountMSModuleId,1; 

				--				  INSERT INTO [dbo].[WorkOrderBatchDetails]
				--					(JournalBatchDetailId,[JournalBatchHeaderId],[ReferenceId],[ReferenceName],[MPNPartId],[MPNName],[PiecePNId],[PiecePN],[CustomerId],[CustomerName] ,[InvoiceId],[InvoiceName],[ARControlNum] ,[CustRefNumber] ,Qty,UnitPrice,LaborHrs,DirectLaborCost,OverheadCost,CommonJournalBatchDetailId,DistributionSetupId ,[IsWorkOrder])
				--				  VALUES
				--					(@JournalBatchDetailId,@JournalBatchHeaderId,@ReferenceId ,@WorkOrderNumber ,@ReferencePartId,@MPNName,@ReferencePieceId,@PiecePN,@CustomerId ,@CustomerName,null ,null,null,@CustRefNumber,@Qty,@UnitPrice,@LaborHrs,@DirectLaborCost,@OverheadCost,@CommonJournalBatchDetailId,@DistributionSetupId,1)

				--				 SET @TotalDebit=0;
				--				 SET @TotalCredit=0;

				--				 SELECT @TotalDebit = SUM(DebitAmount),
				--				        @TotalCredit = SUM(CreditAmount) 
				--				   FROM [dbo].[CommonBatchDetails] WITH(NOLOCK) 
				--				   WHERE JournalBatchDetailId=@JournalBatchDetailId GROUP BY JournalBatchDetailId
							 
				--				 UPDATE [dbo].[BatchDetails] 
				--				    SET [DebitAmount]=@TotalDebit,
				--					    [CreditAmount]=@TotalCredit,
				--						[UpdatedDate]=GETUTCDATE(),
				--						[UpdatedBy]=@UpdateBy 
				--				  WHERE [JournalBatchDetailId]=@JournalBatchDetailId;
				--			END
				--		END

				--		SELECT @TotalDebit =SUM(DebitAmount),@TotalCredit=SUM(CreditAmount) FROM BatchDetails WITH(NOLOCK) WHERE JournalBatchHeaderId=@JournalBatchHeaderId and IsDeleted=0 group by JournalBatchHeaderId
			   	          
				--		SET @TotalBalance = @TotalDebit - @TotalCredit
					
				--		UPDATE [dbo].[CodePrefixes] SET CurrentNummber = @currentNo WHERE CodeTypeId = @CodeTypeId AND MasterCompanyId = @MasterCompanyId    
					
				--		UPDATE [dbo].[BatchHeader]  SET TotalDebit=@TotalDebit,TotalCredit=@TotalCredit,TotalBalance=@TotalBalance,UpdatedDate=GETUTCDATE(),UpdatedBy=@UpdateBy   WHERE JournalBatchHeaderId= @JournalBatchHeaderId
				--	END
				--END
			
				IF(UPPER(@DistributionCode) = UPPER('WOINVOICINGTAB'))
				BEGIN
					SELECT @InvoiceNo = InvoiceNo,
						   @InvoiceTotalCost = ISNULL(GrandTotal,0),
						   --@MaterialCost = ISNULL(MaterialCost,0),
						   @FreightCost = ISNULL(FreightCost,0),
						   @SalesTax = ISNULL(SalesTax,0),
						   @OtherTax = ISNULL(OtherTax,0),
						   @MiscChargesCost = ISNULL(MiscChargesCost,0), 
						   @InvoiceDate = [InvoiceDate]
					  FROM [dbo].[WorkOrderBillingInvoicing] WITH(NOLOCK)
					 WHERE [BillingInvoicingId] = @InvoiceId  

					SET @JournalBatchDetailId = CASE WHEN @StartCount = 1 THEN 0 ELSE @JournalBatchDetailId END;
				
					SELECT TOP 1 @Qty = NoofPieces 
					  FROM [dbo].[WorkOrderBillingInvoicingItem] WITH(NOLOCK) 
					 WHERE [BillingInvoicingId] = @InvoiceId 

					SELECT @LaborCost = (SUM(ISNULL(WOPN.LaborCost,0)) - SUM(ISNULL(WOPN.OverHeadCost,0))),
						   @LaborOverHeadCost = SUM(ISNULL(WOPN.OverHeadCost,0)),
						   @MaterialCost = SUM(ISNULL(WOPN.PartsCost,0))
					  FROM [dbo].[WorkOrderMPNCostDetails]  WOPN WITH(NOLOCK)
					INNER JOIN [dbo].[WorkOrderBillingInvoicingItem] WOBIT WITH(NOLOCK) ON WOPN.WOPartNoId= WOBIT.WorkOrderPartId
					WHERE BillingInvoicingId = @InvoiceId AND IsVersionIncrease = 0 GROUP BY BillingInvoicingId
					 
					SET @RevenuWO = @InvoiceTotalCost - (@FreightCost + @MiscChargesCost + @SalesTax + @OtherTax)

					SET @FinishGoodAmount = ISNULL((@MaterialCost + @LaborCost + @LaborOverHeadCost),0)

					 SELECT @LotId = STL.[LotId],
							@LotNumber = LO.[LotNumber]		
					  FROM [dbo].[WorkOrderPartNumber] WOP WITH(NOLOCK) 
					  LEFT JOIN [dbo].[Stockline] STL ON WOP.[StockLineId] = STL.[StockLineId]
					  LEFT JOIN [dbo].[Lot] LO ON LO.[LotId] = STL.[LotId]			  
					  WHERE WOP.[ID] = @ReferencePartId;
			
					IF EXISTS(SELECT 1 FROM dbo.DistributionSetup WITH(NOLOCK) WHERE DistributionMasterId =@DistributionMasterId AND MasterCompanyId=@MasterCompanyId AND ISNULL(GlAccountId,0) = 0)
					BEGIN
						SET @ValidDistribution = 0;
					END

					IF(@issued = 1 AND @ValidDistribution = 1)
					BEGIN
						-----ACCOUNTSRECEIVABLETRADE------
						SELECT TOP 1 @DistributionSetupId=ID,
									 @DistributionName=Name,
									 @JournalTypeId =JournalTypeId,
									 @GlAccountId=GlAccountId,
									 @GlAccountNumber=GlAccountNumber,
									 @GlAccountName=GlAccountName,
									 @CrDrType = CRDRType
								FROM [dbo].[DistributionSetup] WITH(NOLOCK)  
							   WHERE UPPER(DistributionSetupCode) = UPPER('ACCOUNTSRECEIVABLETRADE') 
								AND DistributionMasterId = @DistributionMasterId 
								AND MasterCompanyId=@MasterCompanyId

						 IF(@InvoiceTotalCost > 0)
						 BEGIN
						
							IF NOT EXISTS(SELECT JournalBatchHeaderId FROM [dbo].[BatchHeader] WITH(NOLOCK)  WHERE JournalTypeId= @JournalTypeId and MasterCompanyId=@MasterCompanyId and  CAST(EntryDate AS DATE) = CAST(GETUTCDATE() AS DATE)and StatusId=@StatusId)
							BEGIN
								IF NOT EXISTS(SELECT JournalBatchHeaderId FROM [dbo].[BatchHeader] WITH(NOLOCK))
								BEGIN	
									SET @batch ='001'
									SET @Currentbatch='001'
								END
								ELSE
								BEGIN
									SELECT top 1 @Currentbatch = CASE WHEN CurrentNumber > 0 THEN CAST(CurrentNumber AS BIGINT) + 1 ELSE  1 END 
				   					FROM BatchHeader WITH(NOLOCK) Order by JournalBatchHeaderId desc 

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
								SET @batch = CAST(@JournalTypeCode +' '+CAST(@batch AS VARCHAR(100)) AS VARCHAR(100))
											          
								INSERT INTO [dbo].[BatchHeader]
											([BatchName],[CurrentNumber],[EntryDate],[AccountingPeriod],AccountingPeriodId,[StatusId],[StatusName],[JournalTypeId],[JournalTypeName],[TotalDebit],[TotalCredit],[TotalBalance],[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted],[Module])
								VALUES
											(@batch,@CurrentNumber,GETUTCDATE(),@AccountingPeriod,@AccountingPeriodId,@StatusId,@StatusName,@JournalTypeId,@JournalTypename,0,0,0,@MasterCompanyId,@UpdateBy,@UpdateBy,GETUTCDATE(),GETUTCDATE(),1,0,@ModuleName);
            	          
								SELECT @JournalBatchHeaderId = SCOPE_IDENTITY()

								UPDATE [dbo].[BatchHeader] SET CurrentNumber = @CurrentNumber WHERE JournalBatchHeaderId= @JournalBatchHeaderId
							END
							ELSE
							BEGIN
								SELECT @JournalBatchHeaderId=JournalBatchHeaderId,@CurrentPeriodId=isnull(AccountingPeriodId,0) FROM BatchHeader WITH(NOLOCK)  WHERE JournalTypeId= @JournalTypeId and StatusId=@StatusId
								SELECT @LineNumber = CASE WHEN LineNumber > 0 THEN CAST(LineNumber AS BIGINT) + 1 ELSE  1 END 
				   										FROM [dbo].[BatchDetails] WITH(NOLOCK) WHERE JournalBatchHeaderId=@JournalBatchHeaderId  Order by JournalBatchDetailId desc 
				    
								IF(@CurrentPeriodId =0)
								BEGIN
									UPDATE [dbo].[BatchHeader] 
									SET AccountingPeriodId=@AccountingPeriodId,
										AccountingPeriod=@AccountingPeriod   
									WHERE JournalBatchHeaderId= @JournalBatchHeaderId
								END
							END

							IF(@JournalBatchDetailId = 0)
							BEGIN
								 INSERT INTO [dbo].[BatchDetails]
									(JournalTypeNumber,CurrentNumber,DistributionSetupId,DistributionName,[JournalBatchHeaderId],[LineNumber],[GlAccountId],[GlAccountNumber],[GlAccountName] ,[TransactionDate],[EntryDate],[JournalTypeId],[JournalTypeName],
									[IsDebit],[DebitAmount] ,[CreditAmount],[ManagementStructureId],[ModuleName],LastMSLevel,AllMSlevels,[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate] ,[IsActive] ,[IsDeleted],[AccountingPeriodId],[AccountingPeriod])
								 VALUES
									(@JournalTypeNumber,@currentNo,@DistributionSetupId,@DistributionName,@JournalBatchHeaderId,1 ,@GlAccountId ,@GlAccountNumber ,@GlAccountName,@InvoiceDate,GETUTCDATE(),@JournalTypeId ,@JournalTypename ,
									1,0,0,@ManagementStructureId ,@ModuleName,@LastMSLevel,@AllMSlevels ,@MasterCompanyId,@UpdateBy,@UpdateBy,GETUTCDATE(),GETUTCDATE(),1,0,@AccountingPeriodId,@AccountingPeriod)
						
								SET @JournalBatchDetailId = SCOPE_IDENTITY()
							END

							INSERT INTO [dbo].[CommonBatchDetails]
								([JournalBatchDetailId],[JournalTypeNumber],[CurrentNumber],[DistributionSetupId],[DistributionName],[JournalBatchHeaderId],[LineNumber],[GlAccountId],[GlAccountNumber],[GlAccountName] ,[TransactionDate],[EntryDate] ,[JournalTypeId],[JournalTypeName],
								[IsDebit],[DebitAmount] ,[CreditAmount],[ManagementStructureId],[ModuleName],[LastMSLevel],[AllMSlevels],[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate] ,[IsActive] ,[IsDeleted],[LotId],[LotNumber])
							VALUES
								(@JournalBatchDetailId,@JournalTypeNumber,@currentNo,@DistributionSetupId,@DistributionName,@JournalBatchHeaderId,1 ,@GlAccountId ,@GlAccountNumber ,@GlAccountName,@InvoiceDate,GETUTCDATE(),@JournalTypeId ,@JournalTypename,
								CASE WHEN @CrDrType = 1 THEN 1 ELSE 0 END,
								CASE WHEN @CrDrType = 1 THEN @InvoiceTotalCost ELSE 0 END,
								CASE WHEN @CrDrType = 1 THEN 0 ELSE @InvoiceTotalCost END
								,@ManagementStructureId ,@ModuleName,@LastMSLevel,@AllMSlevels ,@MasterCompanyId,@UpdateBy,@UpdateBy,GETUTCDATE(),GETUTCDATE(),1,0,@LotId,@LotNumber)

							SET @CommonJournalBatchDetailId = SCOPE_IDENTITY()

							-----  Accounting MS Entry  -----

							EXEC [dbo].[PROCAddUpdateAccountingBatchMSData] @CommonJournalBatchDetailId,@ManagementStructureId,@MasterCompanyId,@UpdateBy,@AccountMSModuleId,1; 

							INSERT INTO [dbo].[WorkOrderBatchDetails]
								(JournalBatchDetailId,[JournalBatchHeaderId],[ReferenceId],[ReferenceName],[MPNPartId],[MPNName],[PiecePNId],[PiecePN],[CustomerId],[CustomerName] ,[InvoiceId],[InvoiceName],[ARControlNum] ,[CustRefNumber] ,Qty,UnitPrice,LaborHrs,DirectLaborCost,OverheadCost,CommonJournalBatchDetailId ,[IsWorkOrder])
							VALUES
								(@JournalBatchDetailId,@JournalBatchHeaderId,@ReferenceId ,@WorkOrderNumber ,@ReferencePartId,@MPNName,@ReferencePieceId,@PiecePN,@CustomerId ,@CustomerName,@InvoiceId ,@InvoiceNo,null,@CustRefNumber,@Qty,@UnitPrice,0,0,0,@CommonJournalBatchDetailId ,1)

						 END

						 -----COGSPARTS------
						 IF(@MaterialCost >0)
						 BEGIN
							SELECT top 1 @DistributionSetupId=ID,@DistributionName=Name,@JournalTypeId =JournalTypeId,@GlAccountId=GlAccountId,@GlAccountNumber=GlAccountNumber,@GlAccountName=GlAccountName,@CrDrType = CRDRType
							FROM DistributionSetup WITH(NOLOCK)  WHERE UPPER(DistributionSetupCode) =UPPER('COGSPARTS') and DistributionMasterId =@DistributionMasterId AND MasterCompanyId=@MasterCompanyId

							INSERT INTO [dbo].[CommonBatchDetails]
								(JournalBatchDetailId,JournalTypeNumber,CurrentNumber,DistributionSetupId,DistributionName,[JournalBatchHeaderId],[LineNumber],[GlAccountId],[GlAccountNumber],[GlAccountName] ,[TransactionDate],[EntryDate] ,[JournalTypeId],[JournalTypeName],
								[IsDebit],[DebitAmount] ,[CreditAmount],[ManagementStructureId],[ModuleName],LastMSLevel,AllMSlevels,[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate] ,[IsActive] ,[IsDeleted],[LotId],[LotNumber])
							VALUES
								(@JournalBatchDetailId,@JournalTypeNumber,@currentNo,@DistributionSetupId,@DistributionName,@JournalBatchHeaderId,1 ,@GlAccountId ,@GlAccountNumber ,@GlAccountName,@InvoiceDate,GETUTCDATE(),@JournalTypeId ,@JournalTypename,
								CASE WHEN @CrDrType = 1 THEN 1 ELSE 0 END,
								CASE WHEN @CrDrType = 1 THEN @MaterialCost ELSE 0 END,
								CASE WHEN @CrDrType = 1 THEN 0 ELSE @MaterialCost END
								,@ManagementStructureId ,@ModuleName,@LastMSLevel,@AllMSlevels ,@MasterCompanyId,@UpdateBy,@UpdateBy,GETUTCDATE(),GETUTCDATE(),1,0,@LotId,@LotNumber)

							SET @CommonJournalBatchDetailId = SCOPE_IDENTITY()

							-----  Accounting MS Entry  -----

							EXEC [dbo].[PROCAddUpdateAccountingBatchMSData] @CommonJournalBatchDetailId,@ManagementStructureId,@MasterCompanyId,@UpdateBy,@AccountMSModuleId,1; 

							INSERT INTO [dbo].[WorkOrderBatchDetails]
								(JournalBatchDetailId,[JournalBatchHeaderId],[ReferenceId],[ReferenceName],[MPNPartId],[MPNName],[PiecePNId],[PiecePN],[CustomerId],[CustomerName] ,[InvoiceId],[InvoiceName],[ARControlNum] ,[CustRefNumber] ,Qty,UnitPrice,LaborHrs,DirectLaborCost,OverheadCost,CommonJournalBatchDetailId ,[IsWorkOrder])
							VALUES
								(@JournalBatchDetailId,@JournalBatchHeaderId,@ReferenceId ,@WorkOrderNumber ,@ReferencePartId,@MPNName,@ReferencePieceId,@PiecePN,@CustomerId ,@CustomerName,@InvoiceId ,@InvoiceNo,null,@CustRefNumber,@Qty,@UnitPrice,@LaborHrs,@DirectLaborCost,@OverheadCost,@CommonJournalBatchDetailId ,1)
					  		
						END

						-----COGSDIRECTLABOR------
						IF(@LaborCost >0)
						BEGIN
							SELECT top 1 @DistributionSetupId=ID,@DistributionName=Name,@JournalTypeId =JournalTypeId,@GlAccountId=GlAccountId,@GlAccountNumber=GlAccountNumber,@GlAccountName=GlAccountName,@CrDrType = CRDRType 
							FROM DistributionSetup WITH(NOLOCK)  WHERE UPPER(DistributionSetupCode) =UPPER('COGSDIRECTLABOR') and DistributionMasterId =@DistributionMasterId AND MasterCompanyId=@MasterCompanyId

							INSERT INTO [dbo].[CommonBatchDetails]
								([JournalBatchDetailId],[JournalTypeNumber],[CurrentNumber],[DistributionSetupId],[DistributionName],[JournalBatchHeaderId],[LineNumber],[GlAccountId],[GlAccountNumber],[GlAccountName] ,[TransactionDate],[EntryDate] ,[JournalTypeId],[JournalTypeName],
								[IsDebit],[DebitAmount] ,[CreditAmount],[ManagementStructureId],[ModuleName],[LastMSLevel],[AllMSlevels],[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate] ,[IsActive] ,[IsDeleted],[LotId],[LotNumber])
							VALUES
								(@JournalBatchDetailId,@JournalTypeNumber,@currentNo,@DistributionSetupId,@DistributionName,@JournalBatchHeaderId,1 ,@GlAccountId ,@GlAccountNumber ,@GlAccountName,@InvoiceDate,GETUTCDATE(),@JournalTypeId ,@JournalTypename,
								CASE WHEN @CrDrType = 1 THEN 1 ELSE 0 END,
								CASE WHEN @CrDrType = 1 THEN @LaborCost ELSE 0 END,
								CASE WHEN @CrDrType = 1 THEN 0 ELSE @LaborCost END
								,@ManagementStructureId ,@ModuleName,@LastMSLevel,@AllMSlevels ,@MasterCompanyId,@UpdateBy,@UpdateBy,GETUTCDATE(),GETUTCDATE(),1,0,@LotId,@LotNumber)

							SET @CommonJournalBatchDetailId = SCOPE_IDENTITY()

							-----  Accounting MS Entry  -----

							EXEC [dbo].[PROCAddUpdateAccountingBatchMSData] @CommonJournalBatchDetailId,@ManagementStructureId,@MasterCompanyId,@UpdateBy,@AccountMSModuleId,1; 

							INSERT INTO [dbo].[WorkOrderBatchDetails]
								(JournalBatchDetailId,[JournalBatchHeaderId],[ReferenceId],[ReferenceName],[MPNPartId],[MPNName],[PiecePNId],[PiecePN],[CustomerId],[CustomerName] ,[InvoiceId],[InvoiceName],[ARControlNum] ,[CustRefNumber] ,Qty,UnitPrice,LaborHrs,DirectLaborCost,OverheadCost,CommonJournalBatchDetailId ,[IsWorkOrder])
							VALUES
								(@JournalBatchDetailId,@JournalBatchHeaderId,@ReferenceId ,@WorkOrderNumber ,@ReferencePartId,@MPNName,@ReferencePieceId,@PiecePN,@CustomerId ,@CustomerName,@InvoiceId ,@InvoiceNo,null,@CustRefNumber,@Qty,@UnitPrice,@LaborHrs,@LaborCost,0,@CommonJournalBatchDetailId,1)
					  		
						END

						-----COGSOVERHEAD------
						IF(@LaborOverHeadCost >0)
						BEGIN
							SELECT top 1 @DistributionSetupId=ID,@DistributionName=Name,@JournalTypeId =JournalTypeId,@GlAccountId=GlAccountId,@GlAccountNumber=GlAccountNumber,@GlAccountName=GlAccountName,@CrDrType = CRDRType 
							FROM DistributionSetup WITH(NOLOCK)  WHERE UPPER(DistributionSetupCode) =UPPER('COGSOVERHEAD') and DistributionMasterId =@DistributionMasterId AND MasterCompanyId=@MasterCompanyId

							INSERT INTO [dbo].[CommonBatchDetails]
								(JournalBatchDetailId,JournalTypeNumber,CurrentNumber,DistributionSetupId,DistributionName,[JournalBatchHeaderId],[LineNumber],[GlAccountId],[GlAccountNumber],[GlAccountName] ,[TransactionDate],[EntryDate] ,[JournalTypeId],[JournalTypeName],
								[IsDebit],[DebitAmount] ,[CreditAmount],[ManagementStructureId],[ModuleName],LastMSLevel,AllMSlevels,[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate] ,[IsActive] ,[IsDeleted],[LotId],[LotNumber])
							VALUES
								(@JournalBatchDetailId,@JournalTypeNumber,@currentNo,@DistributionSetupId,@DistributionName,@JournalBatchHeaderId,1 ,@GlAccountId ,@GlAccountNumber ,@GlAccountName,@InvoiceDate,GETUTCDATE(),@JournalTypeId ,@JournalTypename,
								CASE WHEN @CrDrType = 1 THEN 1 ELSE 0 END,
								CASE WHEN @CrDrType = 1 THEN @LaborOverHeadCost ELSE 0 END,
								CASE WHEN @CrDrType = 1 THEN 0 ELSE @LaborOverHeadCost END
								,@ManagementStructureId ,@ModuleName,@LastMSLevel,@AllMSlevels ,@MasterCompanyId,@UpdateBy,@UpdateBy,GETUTCDATE(),GETUTCDATE(),1,0,@LotId,@LotNumber)

							SET @CommonJournalBatchDetailId = SCOPE_IDENTITY()

							-----  Accounting MS Entry  -----

							EXEC [dbo].[PROCAddUpdateAccountingBatchMSData] @CommonJournalBatchDetailId,@ManagementStructureId,@MasterCompanyId,@UpdateBy,@AccountMSModuleId,1; 

							INSERT INTO [dbo].[WorkOrderBatchDetails]
								(JournalBatchDetailId,[JournalBatchHeaderId],[ReferenceId],[ReferenceName],[MPNPartId],[MPNName],[PiecePNId],[PiecePN],[CustomerId],[CustomerName] ,[InvoiceId],[InvoiceName],[ARControlNum] ,[CustRefNumber] ,Qty,UnitPrice,LaborHrs,DirectLaborCost,OverheadCost,CommonJournalBatchDetailId ,[IsWorkOrder])
							VALUES
								(@JournalBatchDetailId,@JournalBatchHeaderId,@ReferenceId ,@WorkOrderNumber ,@ReferencePartId,@MPNName,@ReferencePieceId,@PiecePN,@CustomerId ,@CustomerName,@InvoiceId ,@InvoiceNo,null,@CustRefNumber,@Qty,@UnitPrice,@LaborHrs,0,@LaborOverHeadCost,@CommonJournalBatchDetailId ,1)
					  		
						END

						-----Inventory to Bill-----
						IF(@FinishGoodAmount >0)
						BEGIN
							SELECT top 1 @DistributionSetupId=ID,@DistributionName=Name,@JournalTypeId =JournalTypeId,@GlAccountId=GlAccountId,@GlAccountNumber=GlAccountNumber,@GlAccountName=GlAccountName,@CrDrType = CRDRType 
							FROM DistributionSetup WITH(NOLOCK)  WHERE UPPER(DistributionSetupCode) = UPPER('WOIFINISHGOOD') and DistributionMasterId =@DistributionMasterId AND MasterCompanyId=@MasterCompanyId

							INSERT INTO [dbo].[CommonBatchDetails]
							  (JournalBatchDetailId,JournalTypeNumber,CurrentNumber,DistributionSetupId,DistributionName,[JournalBatchHeaderId],[LineNumber],[GlAccountId],[GlAccountNumber],[GlAccountName] ,[TransactionDate],[EntryDate] ,[JournalTypeId],[JournalTypeName],
							  [IsDebit],[DebitAmount] ,[CreditAmount],[ManagementStructureId],[ModuleName],LastMSLevel,AllMSlevels,[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate] ,[IsActive] ,[IsDeleted],[LotId],[LotNumber])
							VALUES
							  (@JournalBatchDetailId,@JournalTypeNumber,@currentNo,@DistributionSetupId,@DistributionName,@JournalBatchHeaderId,1 ,@GlAccountId ,@GlAccountNumber ,@GlAccountName,@InvoiceDate,GETUTCDATE(),@JournalTypeId ,@JournalTypename,
							  CASE WHEN @CrDrType = 1 THEN 1 ELSE 0 END,
							  CASE WHEN @CrDrType = 1 THEN @FinishGoodAmount ELSE 0 END,
							  CASE WHEN @CrDrType = 1 THEN 0 ELSE @FinishGoodAmount END
							  ,@ManagementStructureId ,@ModuleName,@LastMSLevel,@AllMSlevels ,@MasterCompanyId,@UpdateBy,@UpdateBy,GETUTCDATE(),GETUTCDATE(),1,0,@LotId,@LotNumber)

							SET @CommonJournalBatchDetailId = SCOPE_IDENTITY()

							-----  Accounting MS Entry  -----

							EXEC [dbo].[PROCAddUpdateAccountingBatchMSData] @CommonJournalBatchDetailId,@ManagementStructureId,@MasterCompanyId,@UpdateBy,@AccountMSModuleId,1; 

							INSERT INTO [dbo].[WorkOrderBatchDetails]
								(JournalBatchDetailId,[JournalBatchHeaderId],[ReferenceId],[ReferenceName],[MPNPartId],[MPNName],[PiecePNId],[PiecePN],[CustomerId],[CustomerName] ,[InvoiceId],[InvoiceName],[ARControlNum] ,[CustRefNumber] ,Qty,UnitPrice,LaborHrs,DirectLaborCost,OverheadCost,CommonJournalBatchDetailId ,[IsWorkOrder])
							VALUES
								(@JournalBatchDetailId,@JournalBatchHeaderId,@ReferenceId ,@WorkOrderNumber ,@ReferencePartId,@MPNName,@ReferencePieceId,@PiecePN,@CustomerId ,@CustomerName,@InvoiceId ,@InvoiceNo,null,@CustRefNumber,@Qty,@UnitPrice,@LaborHrs,@DirectLaborCost,@OverheadCost,@CommonJournalBatchDetailId,1)
					 
						END

						IF(@MiscChargesCost >0)
						BEGIN
							SELECT top 1 @DistributionSetupId=ID,@DistributionName=Name,@JournalTypeId =JournalTypeId,@GlAccountId=GlAccountId,@GlAccountNumber=GlAccountNumber,@GlAccountName=GlAccountName,@CrDrType = CRDRType
							FROM DistributionSetup WITH(NOLOCK)  WHERE UPPER(DistributionSetupCode) =UPPER('REVENUEMISCCHARGE') And DistributionMasterId=@DistributionMasterId AND MasterCompanyId=@MasterCompanyId

							INSERT INTO [dbo].[CommonBatchDetails]
								(JournalBatchDetailId,JournalTypeNumber,CurrentNumber,DistributionSetupId,DistributionName,[JournalBatchHeaderId],[LineNumber],[GlAccountId],[GlAccountNumber],[GlAccountName] ,[TransactionDate],[EntryDate] ,[JournalTypeId],[JournalTypeName],
								[IsDebit],[DebitAmount] ,[CreditAmount],[ManagementStructureId],[ModuleName],LastMSLevel,AllMSlevels,[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate] ,[IsActive] ,[IsDeleted],[LotId],[LotNumber])
							VALUES
								(@JournalBatchDetailId,@JournalTypeNumber,@currentNo,@DistributionSetupId,@DistributionName,@JournalBatchHeaderId,1 ,@GlAccountId ,@GlAccountNumber ,@GlAccountName,@InvoiceDate,GETUTCDATE(),@JournalTypeId ,@JournalTypename,
								CASE WHEN @CrDrType = 1 THEN 1 ELSE 0 END,
								CASE WHEN @CrDrType = 1 THEN @MiscChargesCost ELSE 0 END,
								CASE WHEN @CrDrType = 1 THEN 0 ELSE @MiscChargesCost END
								,@ManagementStructureId ,@ModuleName,@LastMSLevel,@AllMSlevels ,@MasterCompanyId,@UpdateBy,@UpdateBy,GETUTCDATE(),GETUTCDATE(),1,0,@LotId,@LotNumber)
						  
							SET @CommonJournalBatchDetailId = SCOPE_IDENTITY()

							-----  Accounting MS Entry  -----

							EXEC [dbo].[PROCAddUpdateAccountingBatchMSData] @CommonJournalBatchDetailId,@ManagementStructureId,@MasterCompanyId,@UpdateBy,@AccountMSModuleId,1; 

							INSERT INTO [dbo].[WorkOrderBatchDetails]
								(JournalBatchDetailId,[JournalBatchHeaderId],[ReferenceId],[ReferenceName],[MPNPartId],[MPNName],[PiecePNId],[PiecePN],[CustomerId],[CustomerName] ,[InvoiceId],[InvoiceName],[ARControlNum] ,[CustRefNumber] ,Qty,UnitPrice,LaborHrs,DirectLaborCost,OverheadCost,CommonJournalBatchDetailId ,[IsWorkOrder])
							VALUES
								(@JournalBatchDetailId,@JournalBatchHeaderId,@ReferenceId ,@WorkOrderNumber ,@ReferencePartId,@MPNName,@ReferencePieceId,@PiecePN,@CustomerId ,@CustomerName,@InvoiceId ,@InvoiceNo,null,@CustRefNumber,@Qty,@UnitPrice,0,0,0,@CommonJournalBatchDetailId,1)

						END

						-----REVENUEFREIGHT------

						IF(@FreightCost >0)
						BEGIN
							SELECT top 1 @DistributionSetupId=ID,@DistributionName=Name,@JournalTypeId =JournalTypeId,@GlAccountId=GlAccountId,@GlAccountNumber=GlAccountNumber,@GlAccountName=GlAccountName,@CrDrType=CRDRType
							FROM DistributionSetup WITH(NOLOCK)  WHERE UPPER(DistributionSetupCode) =UPPER('REVENUEFREIGHT') And DistributionMasterId=@DistributionMasterId AND MasterCompanyId=@MasterCompanyId

							INSERT INTO [dbo].[CommonBatchDetails]
								(JournalBatchDetailId,JournalTypeNumber,CurrentNumber,DistributionSetupId,DistributionName,[JournalBatchHeaderId],[LineNumber],[GlAccountId],[GlAccountNumber],[GlAccountName] ,[TransactionDate],[EntryDate] ,[JournalTypeId],[JournalTypeName]
								,[IsDebit],[DebitAmount] ,[CreditAmount],[ManagementStructureId],[ModuleName],LastMSLevel,AllMSlevels,[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate] ,[IsActive] ,[IsDeleted],[LotId],[LotNumber])
							VALUES
								(@JournalBatchDetailId,@JournalTypeNumber,@currentNo,@DistributionSetupId,@DistributionName,@JournalBatchHeaderId,1 ,@GlAccountId ,@GlAccountNumber ,@GlAccountName,@InvoiceDate,GETUTCDATE(),@JournalTypeId ,@JournalTypename,
								CASE WHEN @CrDrType = 1 THEN 1 ELSE 0 END,
								CASE WHEN @CrDrType = 1 THEN @FreightCost ELSE 0 END,
								CASE WHEN @CrDrType = 1 THEN 0 ELSE @FreightCost END
								,@ManagementStructureId ,@ModuleName,@LastMSLevel,@AllMSlevels ,@MasterCompanyId,@UpdateBy,@UpdateBy,GETUTCDATE(),GETUTCDATE(),1,0,@LotId,@LotNumber)
						  
							SET @CommonJournalBatchDetailId = SCOPE_IDENTITY()

							-----  Accounting MS Entry  -----

							EXEC [dbo].[PROCAddUpdateAccountingBatchMSData] @CommonJournalBatchDetailId,@ManagementStructureId,@MasterCompanyId,@UpdateBy,@AccountMSModuleId,1; 

							INSERT INTO [dbo].[WorkOrderBatchDetails]
								(JournalBatchDetailId,[JournalBatchHeaderId],[ReferenceId],[ReferenceName],[MPNPartId],[MPNName],[PiecePNId],[PiecePN],[CustomerId],[CustomerName] ,[InvoiceId],[InvoiceName],[ARControlNum] ,[CustRefNumber] ,Qty,UnitPrice,LaborHrs,DirectLaborCost,OverheadCost,CommonJournalBatchDetailId ,[IsWorkOrder])
							VALUES
								(@JournalBatchDetailId,@JournalBatchHeaderId,@ReferenceId ,@WorkOrderNumber ,@ReferencePartId,@MPNName,@ReferencePieceId,@PiecePN,@CustomerId ,@CustomerName,@InvoiceId ,@InvoiceNo,null,@CustRefNumber,@Qty,@UnitPrice,0,0,0,@CommonJournalBatchDetailId,1)

						END

						-----REVENUEWO------
						IF(@RevenuWO >0)
						BEGIN
							SELECT top 1 @DistributionSetupId=ID,@DistributionName=Name,@JournalTypeId =JournalTypeId,@GlAccountId=GlAccountId,@GlAccountNumber=GlAccountNumber,@GlAccountName=GlAccountName,@CrDrType=CRDRType
							FROM DistributionSetup WITH(NOLOCK)  WHERE UPPER(DistributionSetupCode) =UPPER('REVENUEWO') and DistributionMasterId =@DistributionMasterId AND MasterCompanyId=@MasterCompanyId

							INSERT INTO [dbo].[CommonBatchDetails]
								(JournalBatchDetailId,JournalTypeNumber,CurrentNumber,DistributionSetupId,DistributionName,[JournalBatchHeaderId],[LineNumber],[GlAccountId],[GlAccountNumber],[GlAccountName] ,[TransactionDate],[EntryDate] ,[JournalTypeId],[JournalTypeName],
								[IsDebit],[DebitAmount] ,[CreditAmount],[ManagementStructureId],[ModuleName],LastMSLevel,AllMSlevels,[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate] ,[IsActive] ,[IsDeleted],[LotId],[LotNumber])
							VALUES
								(@JournalBatchDetailId,@JournalTypeNumber,@currentNo,@DistributionSetupId,@DistributionName,@JournalBatchHeaderId,1 ,@GlAccountId ,@GlAccountNumber ,@GlAccountName,@InvoiceDate,GETUTCDATE(),@JournalTypeId ,@JournalTypename
								,CASE WHEN @CrDrType = 1 THEN 1 ELSE 0 END,
								CASE WHEN @CrDrType = 1 THEN @RevenuWO ELSE 0 END,
								CASE WHEN @CrDrType = 1 THEN 0 ELSE @RevenuWO END
								,@ManagementStructureId ,@ModuleName,@LastMSLevel,@AllMSlevels ,@MasterCompanyId,@UpdateBy,@UpdateBy,GETUTCDATE(),GETUTCDATE(),1,0,@LotId,@LotNumber)

							SET @CommonJournalBatchDetailId = SCOPE_IDENTITY()

							-----  Accounting MS Entry  -----

							EXEC [dbo].[PROCAddUpdateAccountingBatchMSData] @CommonJournalBatchDetailId,@ManagementStructureId,@MasterCompanyId,@UpdateBy,@AccountMSModuleId,1; 

							INSERT INTO [dbo].[WorkOrderBatchDetails]
								(JournalBatchDetailId,[JournalBatchHeaderId],[ReferenceId],[ReferenceName],[MPNPartId],[MPNName],[PiecePNId],[PiecePN],[CustomerId],[CustomerName] ,[InvoiceId],[InvoiceName],[ARControlNum] ,[CustRefNumber] ,Qty,UnitPrice,LaborHrs,DirectLaborCost,OverheadCost,CommonJournalBatchDetailId ,[IsWorkOrder])
							VALUES
								(@JournalBatchDetailId,@JournalBatchHeaderId,@ReferenceId ,@WorkOrderNumber ,@ReferencePartId,@MPNName,@ReferencePieceId,@PiecePN,@CustomerId ,@CustomerName,@InvoiceId ,@InvoiceNo,null,@CustRefNumber,@Qty,@UnitPrice,0,0,0,@CommonJournalBatchDetailId,1)

						END

						-----SALESTAXPAYABLEWOI------
						IF(@SalesTax >0)
						BEGIN						
							SELECT top 1 @DistributionSetupId=ID,@DistributionName=Name,@JournalTypeId =JournalTypeId,@GlAccountId=GlAccountId,@GlAccountNumber=GlAccountNumber,@GlAccountName=GlAccountName,@CrDrType=CRDRType
							from DistributionSetup WITH(NOLOCK)  WHERE UPPER(DistributionSetupCode) =UPPER('SALESTAXPAYABLEWOI') And DistributionMasterId=@DistributionMasterId AND MasterCompanyId=@MasterCompanyId

							INSERT INTO [dbo].[CommonBatchDetails]
								(JournalBatchDetailId,JournalTypeNumber,CurrentNumber,DistributionSetupId,DistributionName,[JournalBatchHeaderId],[LineNumber],[GlAccountId],[GlAccountNumber],[GlAccountName] ,[TransactionDate],[EntryDate] ,[JournalTypeId],[JournalTypeName]
								,[IsDebit],[DebitAmount] ,[CreditAmount],[ManagementStructureId],[ModuleName],LastMSLevel,AllMSlevels,[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate] ,[IsActive] ,[IsDeleted],[LotId],[LotNumber])
							VALUES
								(@JournalBatchDetailId,@JournalTypeNumber,@currentNo,@DistributionSetupId,@DistributionName,@JournalBatchHeaderId,1 ,@GlAccountId ,@GlAccountNumber ,@GlAccountName,@InvoiceDate,GETUTCDATE(),@JournalTypeId ,@JournalTypename
								,CASE WHEN @CrDrType = 1 THEN 1 ELSE 0 END,
								CASE WHEN @CrDrType = 1 THEN @SalesTax ELSE 0 END,
								CASE WHEN @CrDrType = 1 THEN 0 ELSE @SalesTax END
								,@ManagementStructureId ,@ModuleName,@LastMSLevel,@AllMSlevels ,@MasterCompanyId,@UpdateBy,@UpdateBy,GETUTCDATE(),GETUTCDATE(),1,0,@LotId,@LotNumber)
						    
							SET @CommonJournalBatchDetailId=SCOPE_IDENTITY()

							-----  Accounting MS Entry  -----

							EXEC [dbo].[PROCAddUpdateAccountingBatchMSData] @CommonJournalBatchDetailId,@ManagementStructureId,@MasterCompanyId,@UpdateBy,@AccountMSModuleId,1; 

							INSERT INTO [dbo].[WorkOrderBatchDetails]
								(JournalBatchDetailId,[JournalBatchHeaderId],[ReferenceId],[ReferenceName],[MPNPartId],[MPNName],[PiecePNId],[PiecePN],[CustomerId],[CustomerName] ,[InvoiceId],[InvoiceName],[ARControlNum] ,[CustRefNumber] ,Qty,UnitPrice,LaborHrs,DirectLaborCost,OverheadCost,CommonJournalBatchDetailId ,[IsWorkOrder])
							VALUES
								(@JournalBatchDetailId,@JournalBatchHeaderId,@ReferenceId ,@WorkOrderNumber ,@ReferencePartId,@MPNName,@ReferencePieceId,@PiecePN,@CustomerId ,@CustomerName,@InvoiceId ,@InvoiceNo,null,@CustRefNumber,@Qty,@UnitPrice,0,0,0,@CommonJournalBatchDetailId,1)

						END

						-----OTHERTAXPAYABLEWOI------
						IF(@OtherTax >0)
						BEGIN						
							SELECT top 1 @DistributionSetupId=ID,@DistributionName=Name,@JournalTypeId =JournalTypeId,@GlAccountId=GlAccountId,@GlAccountNumber=GlAccountNumber,@GlAccountName=GlAccountName,@CrDrType=CRDRType
							from DistributionSetup WITH(NOLOCK)  WHERE UPPER(DistributionSetupCode) =UPPER('WOIOTHERTAX') And DistributionMasterId=@DistributionMasterId AND MasterCompanyId=@MasterCompanyId

							INSERT INTO [dbo].[CommonBatchDetails]
								([JournalBatchDetailId],[JournalTypeNumber],[CurrentNumber],[DistributionSetupId],[DistributionName],[JournalBatchHeaderId],[LineNumber],[GlAccountId],[GlAccountNumber],[GlAccountName] ,[TransactionDate],[EntryDate] ,[JournalTypeId],[JournalTypeName]
								,[IsDebit],[DebitAmount] ,[CreditAmount],[ManagementStructureId],[ModuleName],[LastMSLevel],[AllMSlevels],[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate] ,[IsActive] ,[IsDeleted],[LotId],[LotNumber])
							VALUES
								(@JournalBatchDetailId,@JournalTypeNumber,@currentNo,@DistributionSetupId,@DistributionName,@JournalBatchHeaderId,1 ,@GlAccountId ,@GlAccountNumber ,@GlAccountName,@InvoiceDate,GETUTCDATE(),@JournalTypeId ,@JournalTypename
								,CASE WHEN @CrDrType = 1 THEN 1 ELSE 0 END,
								CASE WHEN @CrDrType = 1 THEN @OtherTax ELSE 0 END,
								CASE WHEN @CrDrType = 1 THEN 0 ELSE @OtherTax END
								,@ManagementStructureId ,@ModuleName,@LastMSLevel,@AllMSlevels ,@MasterCompanyId,@UpdateBy,@UpdateBy,GETUTCDATE(),GETUTCDATE(),1,0,@LotId,@LotNumber)
						    
							SET @CommonJournalBatchDetailId = SCOPE_IDENTITY()

							-----  Accounting MS Entry  -----

							EXEC [dbo].[PROCAddUpdateAccountingBatchMSData] @CommonJournalBatchDetailId,@ManagementStructureId,@MasterCompanyId,@UpdateBy,@AccountMSModuleId,1; 

							INSERT INTO [dbo].[WorkOrderBatchDetails]
								(JournalBatchDetailId,[JournalBatchHeaderId],[ReferenceId],[ReferenceName],[MPNPartId],[MPNName],[PiecePNId],[PiecePN],[CustomerId],[CustomerName] ,[InvoiceId],[InvoiceName],[ARControlNum] ,[CustRefNumber] ,Qty,UnitPrice,LaborHrs,DirectLaborCost,OverheadCost,CommonJournalBatchDetailId,[IsWorkOrder])
							VALUES
								(@JournalBatchDetailId,@JournalBatchHeaderId,@ReferenceId ,@WorkOrderNumber ,@ReferencePartId,@MPNName,@ReferencePieceId,@PiecePN,@CustomerId ,@CustomerName,@InvoiceId ,@InvoiceNo,null,@CustRefNumber,@Qty,@UnitPrice,0,0,0,@CommonJournalBatchDetailId,1)

						END
						-----UNEARNEDAMOUNTPAYABLEWOI------
						IF(@UnEarnedAmount >0)
						BEGIN						
							SELECT top 1 @DistributionSetupId=ID,@DistributionName=Name,@JournalTypeId =JournalTypeId,@GlAccountId=GlAccountId,@GlAccountNumber=GlAccountNumber,@GlAccountName=GlAccountName,@CrDrType=CRDRType
							from DistributionSetup WITH(NOLOCK)  WHERE UPPER(DistributionSetupCode) =UPPER('WOIUNEARNAMT') And DistributionMasterId=@DistributionMasterId AND MasterCompanyId=@MasterCompanyId

							INSERT INTO [dbo].[CommonBatchDetails]
								(JournalBatchDetailId,JournalTypeNumber,CurrentNumber,DistributionSetupId,DistributionName,[JournalBatchHeaderId],[LineNumber],[GlAccountId],[GlAccountNumber],[GlAccountName] ,[TransactionDate],[EntryDate] ,[JournalTypeId],[JournalTypeName]
								,[IsDebit],[DebitAmount] ,[CreditAmount],[ManagementStructureId],[ModuleName],LastMSLevel,AllMSlevels,[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate] ,[IsActive] ,[IsDeleted],[LotId],[LotNumber])
							VALUES
								(@JournalBatchDetailId,@JournalTypeNumber,@currentNo,@DistributionSetupId,@DistributionName,@JournalBatchHeaderId,1 ,@GlAccountId ,@GlAccountNumber ,@GlAccountName,@InvoiceDate,GETUTCDATE(),@JournalTypeId ,@JournalTypename
								,CASE WHEN @CrDrType = 1 THEN 1 ELSE 0 END,
								CASE WHEN @CrDrType = 1 THEN @UnEarnedAmount ELSE 0 END,
								CASE WHEN @CrDrType = 1 THEN 0 ELSE @UnEarnedAmount END
								,@ManagementStructureId ,@ModuleName,@LastMSLevel,@AllMSlevels ,@MasterCompanyId,@UpdateBy,@UpdateBy,GETUTCDATE(),GETUTCDATE(),1,0,@LotId,@LotNumber)
						    
							SET @CommonJournalBatchDetailId = SCOPE_IDENTITY()

							-----  Accounting MS Entry  -----

							EXEC [dbo].[PROCAddUpdateAccountingBatchMSData] @CommonJournalBatchDetailId,@ManagementStructureId,@MasterCompanyId,@UpdateBy,@AccountMSModuleId,1; 

							INSERT INTO [dbo].[WorkOrderBatchDetails]
								(JournalBatchDetailId,[JournalBatchHeaderId],[ReferenceId],[ReferenceName],[MPNPartId],[MPNName],[PiecePNId],[PiecePN],[CustomerId],[CustomerName] ,[InvoiceId],[InvoiceName],[ARControlNum] ,[CustRefNumber] ,Qty,UnitPrice,LaborHrs,DirectLaborCost,OverheadCost,CommonJournalBatchDetailId,[IsWorkOrder])
							VALUES
								(@JournalBatchDetailId,@JournalBatchHeaderId,@ReferenceId ,@WorkOrderNumber ,@ReferencePartId,@MPNName,@ReferencePieceId,@PiecePN,@CustomerId ,@CustomerName,@InvoiceId ,@InvoiceNo,null,@CustRefNumber,@Qty,@UnitPrice,0,0,0,@CommonJournalBatchDetailId,1)

						END

						-----UNEARNEDRECVAMOUNTPAYABLEWOI------
						IF(@UnEarnedAmount >0)
						BEGIN						
							SELECT top 1 @DistributionSetupId=ID,@DistributionName=Name,@JournalTypeId =JournalTypeId,@GlAccountId=GlAccountId,@GlAccountNumber=GlAccountNumber,@GlAccountName=GlAccountName,@CrDrType=CRDRType
							from DistributionSetup WITH(NOLOCK)  WHERE UPPER(DistributionSetupCode) =UPPER('ACCOUNTSRECEIVABLETRADE') And DistributionMasterId=@DistributionMasterId AND MasterCompanyId=@MasterCompanyId

							INSERT INTO [dbo].[CommonBatchDetails]
								(JournalBatchDetailId,JournalTypeNumber,CurrentNumber,DistributionSetupId,DistributionName,[JournalBatchHeaderId],[LineNumber],[GlAccountId],[GlAccountNumber],[GlAccountName] ,[TransactionDate],[EntryDate] ,[JournalTypeId],[JournalTypeName]
								,[IsDebit],[DebitAmount] ,[CreditAmount],[ManagementStructureId],[ModuleName],LastMSLevel,AllMSlevels,[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate] ,[IsActive] ,[IsDeleted],[LotId],[LotNumber])
							VALUES
								(@JournalBatchDetailId,@JournalTypeNumber,@currentNo,@DistributionSetupId,@DistributionName,@JournalBatchHeaderId,1 ,@GlAccountId ,@GlAccountNumber ,@GlAccountName,@InvoiceDate,GETUTCDATE(),@JournalTypeId ,@JournalTypename
								,CASE WHEN @CrDrType = 1 THEN 1 ELSE 0 END,
								CASE WHEN @CrDrType = 1 THEN 0 ELSE @UnEarnedAmount END,
								CASE WHEN @CrDrType = 1 THEN @UnEarnedAmount ELSE 0 END
								,@ManagementStructureId ,@ModuleName,@LastMSLevel,@AllMSlevels ,@MasterCompanyId,@UpdateBy,@UpdateBy,GETUTCDATE(),GETUTCDATE(),1,0,@LotId,@LotNumber)
						    
							SET @CommonJournalBatchDetailId = SCOPE_IDENTITY()

							-----  Accounting MS Entry  -----

							EXEC [dbo].[PROCAddUpdateAccountingBatchMSData] @CommonJournalBatchDetailId,@ManagementStructureId,@MasterCompanyId,@UpdateBy,@AccountMSModuleId,1; 

							INSERT INTO [dbo].[WorkOrderBatchDetails]
								(JournalBatchDetailId,[JournalBatchHeaderId],[ReferenceId],[ReferenceName],[MPNPartId],[MPNName],[PiecePNId],[PiecePN],[CustomerId],[CustomerName] ,[InvoiceId],[InvoiceName],[ARControlNum] ,[CustRefNumber] ,Qty,UnitPrice,LaborHrs,DirectLaborCost,OverheadCost,CommonJournalBatchDetailId ,[IsWorkOrder])
							VALUES
								(@JournalBatchDetailId,@JournalBatchHeaderId,@ReferenceId ,@WorkOrderNumber ,@ReferencePartId,@MPNName,@ReferencePieceId,@PiecePN,@CustomerId ,@CustomerName,@InvoiceId ,@InvoiceNo,null,@CustRefNumber,@Qty,@UnitPrice,0,0,0,@CommonJournalBatchDetailId,1)

						END

						SET @TotalDebit=0;
						SET @TotalCredit=0;
					
						SELECT @TotalDebit = SUM(DebitAmount),@TotalCredit = SUM(CreditAmount) FROM [dbo].[CommonBatchDetails] WITH(NOLOCK) WHERE JournalBatchDetailId=@JournalBatchDetailId group by JournalBatchDetailId
					
						UPDATE [dbo].[BatchDetails] SET DebitAmount=@TotalDebit,CreditAmount=@TotalCredit,UpdatedDate=GETUTCDATE(),UpdatedBy=@UpdateBy WHERE JournalBatchDetailId=@JournalBatchDetailId

					END

					--REVERSE WORK ORDER BILLING A/C ENTRY
					IF(@issued = 0 AND @ValidDistribution = 1)
					BEGIN

						CREATE TABLE #tmpCommonBatchDetails (
							ID BIGINT NOT NULL IDENTITY (1, 1),
							CommonJournalBatchDetailId	BIGINT NULL,
							JournalBatchHeaderId	BIGINT NULL,
							JournalBatchDetailId	BIGINT NULL,
							LineNumber	INT NULL,
							GlAccountId	BIGINT NULL,
							GlAccountNumber	VARCHAR(MAX) NULL,
							GlAccountName	VARCHAR(MAX) NULL,
							TransactionDate	DATETIME NULL,
							EntryDate	DATETIME NULL,
							JournalTypeId	BIGINT NULL,
							JournalTypeName	VARCHAR(MAX) NULL,
							IsDebit	BIT NULL,
							DebitAmount	DECIMAL(18,2) NULL,
							CreditAmount	DECIMAL(18,2) NULL,
							ManagementStructureId	BIGINT NULL,
							ModuleName	VARCHAR(MAX) NULL,
							MasterCompanyId	INT NULL,
							CreatedBy	VARCHAR(MAX) NULL,
							UpdatedBy	VARCHAR(MAX) NULL,
							CreatedDate	DATETIME2 NULL,
							UpdatedDate	DATETIME2 NULL,
							IsActive	BIT NULL,
							IsDeleted	BIT NULL,
							LastMSLevel	VARCHAR(MAX) NULL,
							AllMSlevels	VARCHAR(MAX) NULL,
							IsManualEntry	BIT NULL,
							DistributionSetupId	INT NULL,
							DistributionName	VARCHAR(MAX) NULL,
							JournalTypeNumber	VARCHAR(MAX) NULL,
							CurrentNumber	BIGINT NULL,
							IsYearEnd	BIT NULL,
							IsVersionIncrease	BIT NULL,
							ReferenceId	BIGINT NULL,
							LotId	BIGINT NULL,
							LotNumber	VARCHAR(MAX) NULL
						)
					
						INSERT INTO #tmpCommonBatchDetails (CommonJournalBatchDetailId,JournalBatchHeaderId,JournalBatchDetailId,LineNumber,GlAccountId,GlAccountNumber,
							GlAccountName,TransactionDate,EntryDate,JournalTypeId,JournalTypeName,IsDebit,DebitAmount,CreditAmount,ManagementStructureId,ModuleName,
							MasterCompanyId,CreatedBy,UpdatedBy,CreatedDate,UpdatedDate,IsActive,IsDeleted,LastMSLevel,AllMSlevels,IsManualEntry,DistributionSetupId,
							DistributionName,JournalTypeNumber,CurrentNumber,IsYearEnd,IsVersionIncrease,ReferenceId,LotId,LotNumber)
						SELECT CBD.CommonJournalBatchDetailId, CBD.JournalBatchHeaderId, CBD.JournalBatchDetailId, CBD.LineNumber, CBD.GlAccountId, CBD.GlAccountNumber,
							CBD.GlAccountName, CBD.TransactionDate, CBD.EntryDate, CBD.JournalTypeId,JournalTypeName, CBD.IsDebit,DebitAmount,CreditAmount,ManagementStructureId,ModuleName,
							CBD.MasterCompanyId, CBD.CreatedBy, CBD.UpdatedBy, CBD.CreatedDate, CBD.UpdatedDate, CBD.IsActive, CBD.IsDeleted, CBD.LastMSLevel,AllMSlevels,IsManualEntry,
							CBD.DistributionSetupId,DistributionName,JournalTypeNumber,CurrentNumber,IsYearEnd,IsVersionIncrease,CBD.ReferenceId,LotId,LotNumber 
						FROM dbo.CommonBatchDetails CBD WITH(NOLOCK)
								JOIN dbo.WorkOrderBatchDetails WOBD WITH(NOLOCK)  ON CBD.CommonJournalBatchDetailId = WOBD.CommonJournalBatchDetailId
								JOIN [dbo].[DistributionSetup] DS WITH(NOLOCK) ON DS.ID = CBD.DistributionSetupId
						WHERE WOBD.InvoiceId = @InvoiceId AND CBD.MasterCompanyId = @MasterCompanyId

						SELECT @temptotaldebitcount = SUM(ISNULL(DebitAmount,0)), @temptotalcreditcount =SUM(ISNULL(CreditAmount,0)) FROM #tmpCommonBatchDetails;

						IF(@temptotaldebitcount > 0 OR @temptotalcreditcount > 0)
						BEGIN
							DECLARE @CommonBatchDetailsId BIGINT;
							DECLARE @DebitAmount DECIMAL(18,2);
							DECLARE @CreditAmount DECIMAL(18,2);

							SELECT TOP 1 @DistributionSetupId=ID,
									 @DistributionName=Name,
									 @JournalTypeId =JournalTypeId,
									 @GlAccountId=GlAccountId,
									 @GlAccountNumber=GlAccountNumber,
									 @GlAccountName=GlAccountName,
									 @CrDrType = CRDRType
								FROM [dbo].[DistributionSetup] WITH(NOLOCK)  
							   WHERE UPPER(DistributionSetupCode) = UPPER('ACCOUNTSRECEIVABLETRADE') 
								AND DistributionMasterId = @DistributionMasterId 
								AND MasterCompanyId=@MasterCompanyId

							IF NOT EXISTS(SELECT JournalBatchHeaderId FROM [dbo].[BatchHeader] WITH(NOLOCK)  WHERE JournalTypeId = @JournalTypeId AND MasterCompanyId = @MasterCompanyId AND CAST(EntryDate AS DATE) = CAST(GETUTCDATE() AS DATE) AND StatusId = @StatusId)
							BEGIN
								IF NOT EXISTS(SELECT JournalBatchHeaderId FROM [dbo].[BatchHeader] WITH(NOLOCK))
								BEGIN	
									SET @batch ='001'
									SET @Currentbatch='001'
								END
								ELSE
								BEGIN
									SELECT top 1 @Currentbatch = CASE WHEN CurrentNumber > 0 THEN CAST(CurrentNumber AS BIGINT) + 1 ELSE  1 END 
				   					FROM BatchHeader WITH(NOLOCK) Order by JournalBatchHeaderId desc 

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
								SET @batch = CAST(@JournalTypeCode +' '+CAST(@batch AS VARCHAR(100)) AS VARCHAR(100))
										          
								INSERT INTO [dbo].[BatchHeader]
											([BatchName],[CurrentNumber],[EntryDate],[AccountingPeriod],AccountingPeriodId,[StatusId],[StatusName],[JournalTypeId],[JournalTypeName],[TotalDebit],[TotalCredit],[TotalBalance],[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted],[Module])
								VALUES
											(@batch,@CurrentNumber,GETUTCDATE(),@AccountingPeriod,@AccountingPeriodId,@StatusId,@StatusName,@JournalTypeId,@JournalTypename,0,0,0,@MasterCompanyId,@UpdateBy,@UpdateBy,GETUTCDATE(),GETUTCDATE(),1,0,@ModuleName);
            	        
								SELECT @JournalBatchHeaderId = SCOPE_IDENTITY()

								UPDATE [dbo].[BatchHeader] SET CurrentNumber = @CurrentNumber WHERE JournalBatchHeaderId= @JournalBatchHeaderId
							END
							ELSE
							BEGIN
								SELECT @JournalBatchHeaderId = JournalBatchHeaderId, @CurrentPeriodId = ISNULL(AccountingPeriodId,0) FROM dbo.BatchHeader WITH(NOLOCK)  WHERE JournalTypeId= @JournalTypeId and StatusId=@StatusId
								SELECT @LineNumber = CASE WHEN LineNumber > 0 THEN CAST(LineNumber AS BIGINT) + 1 ELSE  1 END 
				   										FROM [dbo].[BatchDetails] WITH(NOLOCK) WHERE JournalBatchHeaderId = @JournalBatchHeaderId  Order by JournalBatchDetailId desc 
				    
								IF(@CurrentPeriodId = 0)
								BEGIN
									UPDATE [dbo].[BatchHeader] 
									SET AccountingPeriodId = @AccountingPeriodId,
										AccountingPeriod = @AccountingPeriod   
									WHERE JournalBatchHeaderId = @JournalBatchHeaderId
								END
							END

							IF(@JournalBatchDetailId = 0)
							BEGIN
								 INSERT INTO [dbo].[BatchDetails]
									(JournalTypeNumber,CurrentNumber,DistributionSetupId,DistributionName,[JournalBatchHeaderId],[LineNumber],[GlAccountId],[GlAccountNumber],[GlAccountName] ,[TransactionDate],[EntryDate],[JournalTypeId],[JournalTypeName],
									[IsDebit],[DebitAmount] ,[CreditAmount],[ManagementStructureId],[ModuleName],LastMSLevel,AllMSlevels,[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate] ,[IsActive] ,[IsDeleted],[AccountingPeriodId],[AccountingPeriod], [IsReversedJE])
								 VALUES
									(@JournalTypeNumber, @currentNo, @DistributionSetupId, @Distributionname, @JournalBatchHeaderId, 1 , @GlAccountId , @GlAccountNumber , @GlAccountName, GETUTCDATE(), GETUTCDATE(),@JournalTypeId , @JournalTypename ,
									1,0,0, @ManagementStructureId, @ModuleName, NULL, NULL, @MasterCompanyId, @UpdateBy, @UpdateBy, GETUTCDATE(), GETUTCDATE(), 1, 0, @AccountingPeriodId, @AccountingPeriod, 1)
						
								SET @JournalBatchDetailId = SCOPE_IDENTITY()
							END

							SELECT  @MasterLoopID = MAX(ID) FROM #tmpCommonBatchDetails
							WHILE(@MasterLoopID > 0)
							BEGIN			
								SELECT @ManagementStructureId = ManagementStructureId FROM #tmpCommonBatchDetails WHERE ID  = @MasterLoopID;

								INSERT INTO [dbo].[CommonBatchDetails]
													(JournalBatchDetailId,JournalTypeNumber,CurrentNumber,DistributionSetupId,DistributionName,[JournalBatchHeaderId],[LineNumber],
													[GlAccountId],[GlAccountNumber],[GlAccountName] ,[TransactionDate],[EntryDate] ,[JournalTypeId],[JournalTypeName],
													[IsDebit],[DebitAmount] ,[CreditAmount],[ManagementStructureId],[ModuleName],LastMSLevel,AllMSlevels,[MasterCompanyId],
													[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate] ,[IsActive] ,[IsDeleted], [LotId],[LotNumber])
								SELECT  @JournalBatchDetailId,@JournalTypeNumber,@currentNo,DistributionSetupId,DistributionName,@JournalBatchHeaderId,1 
													,GlAccountId ,GlAccountNumber ,GlAccountName,GETUTCDATE(),GETUTCDATE(),@JournalTypeId ,@JournalTypename,
													CASE WHEN IsDebit = 0 THEN 1 ELSE 0 END,
													CreditAmount,
													DebitAmount,
													ManagementStructureId ,'WO',LastMSLevel,AllMSlevels ,MasterCompanyId,
													@UpdateBy,@UpdateBy,GETUTCDATE(),GETUTCDATE(),1,0,[LotId],[LotNumber]
								FROM #tmpCommonBatchDetails WHERE ID  = @MasterLoopID;
							
								SET @CommonJournalBatchDetailId = SCOPE_IDENTITY()

								-----  Accounting MS Entry  -----

								EXEC [dbo].[PROCAddUpdateAccountingBatchMSData] @CommonJournalBatchDetailId,@ManagementStructureId,@MasterCompanyId,@UpdateBy,@AccountMSModuleId,1; 

								INSERT INTO [dbo].[WorkOrderBatchDetails]
									(JournalBatchDetailId,[JournalBatchHeaderId],[ReferenceId],[ReferenceName],[MPNPartId],[MPNName],[PiecePNId],[PiecePN],[CustomerId],[CustomerName] ,[InvoiceId],[InvoiceName],[ARControlNum] ,[CustRefNumber] ,Qty,UnitPrice,LaborHrs,DirectLaborCost,OverheadCost,CommonJournalBatchDetailId ,[IsWorkOrder])
								VALUES
									(@JournalBatchDetailId,@JournalBatchHeaderId,@ReferenceId ,@WorkOrderNumber ,@ReferencePartId,@MPNName,@ReferencePieceId,@PiecePN,@CustomerId ,@CustomerName,@InvoiceId ,@InvoiceNo,null,@CustRefNumber,@Qty,@UnitPrice,0,0,0,@CommonJournalBatchDetailId ,1)
						
								SET @MasterLoopID = @MasterLoopID - 1;
							END

							SET @TotalDebit=0;
							SET @TotalCredit=0;
					
							SELECT @TotalDebit = SUM(DebitAmount),@TotalCredit = SUM(CreditAmount) FROM [dbo].[CommonBatchDetails] WITH(NOLOCK) WHERE JournalBatchDetailId=@JournalBatchDetailId group by JournalBatchDetailId
					
							UPDATE [dbo].[BatchDetails] SET DebitAmount=@TotalDebit,CreditAmount=@TotalCredit,UpdatedDate=GETUTCDATE(),UpdatedBy=@UpdateBy WHERE JournalBatchDetailId=@JournalBatchDetailId
						END
					
					END

					SELECT @TotalDebit = SUM(DebitAmount),@TotalCredit = SUM(CreditAmount) FROM [dbo].[BatchDetails] WITH(NOLOCK) WHERE JournalBatchHeaderId=@JournalBatchHeaderId and IsDeleted=0 group by JournalBatchHeaderId
			   	          
					SET @TotalBalance = @TotalDebit - @TotalCredit
					
					IF(@isNewJENum = 1 AND @JournalBatchDetailId > 0)
					BEGIN
						UPDATE [dbo].[CodePrefixes] SET CurrentNummber = @currentNo WHERE CodeTypeId = @CodeTypeId AND MasterCompanyId = @MasterCompanyId    
					END
			   
					UPDATE [dbo].[BatchHeader] SET TotalDebit = @TotalDebit,TotalCredit = @TotalCredit,TotalBalance = @TotalBalance,UpdatedDate = GETUTCDATE(),UpdatedBy=@UpdateBy WHERE JournalBatchHeaderId= @JournalBatchHeaderId

				END
			
				IF OBJECT_ID(N'tempdb..#tmpCodePrefixes') IS NOT NULL
				BEGIN
					DROP TABLE #tmpCodePrefixes 
				END

			END

			SET @StartCount += 1;
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
            , @AdhocComments     VARCHAR(150)    = 'USP_BatchTriggerBasedonDistributionForWO' 
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