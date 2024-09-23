/*************************************************************           
 ** File:   [USP_Assets_PostCheckBatchDetails]           
 ** Author: Amit Ghediya
 ** Description: This stored procedure is used insert account report in batch from Assets.
 ** Purpose:         
 ** Date:   08/08/2023 

 ** PARAMETERS:           
         
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author			Change Description            
 ** --   --------     -------			--------------------------------          
    1    08/08/2023   Amit Ghediya		Created	
	2    08/09/2023   Amit Ghediya		Update for Level set.	
	3    08/09/2023   Amit Ghediya		Delete DistributionSetup where name condition;
	4	 08/12/2023	  Satish Gohil		Dynamic GlAccount Added for particular distribution
	5	 08/16/2023	  Amit Ghediya		Updated Fix entry for ACCUMULATEDDEPRECIATION to DR. 
	6	 08/18/2023	  Amit Ghediya		Updated Ristrict for enty if amount is 0.00. 
	7    21/08/2023   Moin Bloch		Modify(Added Accounting MS Entry)    
	8	 25/04/2024	  Abhishek Jirawla  Making the sold item inactive and also updating the status note to 'Inventory is Sold'
    9    12/07/2024   Amit Ghediya		Update new Distribution used. 
   10    22/07/2024   Amit Ghediya		Update new BatchCode & J-Type Code as per new distribution.
   11    19/09/2024	  AMIT GHEDIYA		Added for AutoPost Batch
**************************************************************/

CREATE     PROCEDURE [dbo].[USP_Assets_PostCheckBatchDetails]
(
	@AssetInventoryId BIGINT,
	@CashAmount DECIMAL(18,2),
	@DepreciationAmount DECIMAL(18,2),
	@InstallCost DECIMAL(18,2),
	@Status VARCHAR(100),
	@UpdateBy VARCHAR(100)
)
AS
BEGIN 
	BEGIN TRY
		DECLARE @CodeTypeId AS BIGINT = 74;
		DECLARE @MasterCompanyId bigint=0;   
		DECLARE @currentNo AS BIGINT = 0;
		DECLARE @JournalTypeNumber varchar(100);
		DECLARE @DistributionMasterId bigint;    
		DECLARE @DistributionCode varchar(200); 
		DECLARE @CurrentManagementStructureId bigint=0; 
		DECLARE @StatusId int;    
		DECLARE @StatusName varchar(200);    
		DECLARE @AccountingPeriod varchar(100);    
		DECLARE @AccountingPeriodId bigint=0;   
		DECLARE @JournalTypeId int;    
		DECLARE @JournalTypeCode varchar(200);
		DECLARE @JournalBatchHeaderId bigint;    
		DECLARE @JournalTypename varchar(200);  
		DECLARE @batch varchar(100);    
		DECLARE @Currentbatch varchar(100);    
		DECLARE @CurrentNumber int;    
		DECLARE @CurrentPeriodId bigint=0; 
		DECLARE @LineNumber int=1;    
		DECLARE @JournalBatchDetailId BIGINT=0;
		DECLARE @CommonBatchDetailId BIGINT=0;
		DECLARE @DistributionSetupId int=0
		DECLARE @Distributionname varchar(200) 
		DECLARE @GlAccountId int
		DECLARE @StartsFrom varchar(200)='00'
		DECLARE @GlAccountName varchar(200) 
		DECLARE @GlAccountNumber varchar(200) 
		DECLARE @ExtAmount DECIMAL(18,2)
		DECLARE @BankId INT =0;
		DECLARE @ManagementStructureId bigint
		DECLARE @LastMSLevel varchar(200)
		DECLARE @AllMSlevels varchar(max)
		DECLARE @ModuleId INT
		DECLARE @TotalDebit decimal(18, 2) =0;
		DECLARE @TotalCredit decimal(18, 2) =0;
		DECLARE @TotalBalance decimal(18, 2) =0;
		DECLARE @ExtNumber VARCHAR(20);
		DECLARE @VendorName VARCHAR(50);
		DECLARE @ExtDate Datetime;
		DECLARE @stklineId BIGINT;
		DECLARE @DistributionCodeName VARCHAR(100);
		DECLARE @CrDrType int=0;
		DECLARE @CodePrefix VARCHAR(50);
		DECLARE @FinalSaleAsset DECIMAL(18,2)=0;
		DECLARE @BenifitAmount DECIMAL(18,2)=0;
		DECLARE @IsSaleAssetDRCR INT = 0;
		DECLARE @SaleAssetDRCR INT = 1;
		DECLARE @AssetInventoryStatusId BIGINT;
		DECLARE @AssetInventoryName varchar(100);
		DECLARE @SiteId BIGINT;
		DECLARE @Site varchar(100)='';
		DECLARE @WarehouseId BIGINT;
		DECLARE @Warehouse varchar(100)='';
		DECLARE @LocationId BIGINT;
		DECLARE @Location varchar(100)='';
		DECLARE @BinId BIGINT;
		DECLARE @Bin varchar(100)='';
		DECLARE @ShelfId BIGINT;
		DECLARE @Shelf varchar(100)='';
		DECLARE @Desc varchar(100);
		DECLARE @StocktypeAsset varchar(50)='ASSET';

		SET @DistributionCodeName = 'ASSET SALE/WRITE DOWN/WRITE OFF';
		DECLARE @AcquiredGLAccountId AS BIGINT = 0;
		DECLARE @DeprExpenseGLAccountId AS BIGINT = 0;
		DECLARE @AdDepsGLAccountId AS BIGINT = 0;
		DECLARE @AssetSaleGLAccountId AS BIGINT = 0;
		DECLARE @AssetWriteOffGLAccountId AS BIGINT = 0;
		DECLARE @AssetWriteDownGLAccountId AS BIGINT = 0;
		DECLARE @IntangibleGLAccountId AS BIGINT = 0;
		DECLARE @AmortExpenseGLAccountId AS BIGINT = 0;
		DECLARE @AccAmortDeprGLAccountId AS BIGINT = 0;
		DECLARE @IntangibleWriteDownGLAccountId AS BIGINT = 0;
		DECLARE @IntangibleWriteOffGLAccountId AS BIGINT = 0;
		DECLARE @AccountMSModuleId INT = 0;
		DECLARE @WrittenOffStatus VARCHAR(100) = 'WrittenOff';
		DECLARE @SoldStatus VARCHAR(100) = 'Sold';
		DECLARE @ModuleName VARCHAR(10) = 'AST';
		DECLARE @IsAutoPost INT = 0;

		SELECT @AccountMSModuleId = [ManagementStructureModuleId] FROM [dbo].[ManagementStructureModule] WITH(NOLOCK) WHERE [ModuleName] ='Accounting';

		SELECT @CodeTypeId = CodeTypeId FROM [DBO].[CodeTypes] WITH(NOLOCK) WHERE CodeType = 'JournalType';

		SELECT @AssetInventoryStatusId = AssetInventoryStatusId FROM [DBO].[AssetInventoryStatus] WITH(NOLOCK) 
		WHERE Status = @Status;

		--Update Assets Status to Sold/WriteOff & Qty to 0
		UPDATE [DBO].[AssetInventory] 
		SET InventoryStatusId = @AssetInventoryStatusId , 
			Qty = 0 ,
			ReceivablesAmount = @CashAmount,
			IsActive = 0,
			StatusNote = 'Inventory is Sold'
		WHERE AssetInventoryId = @AssetInventoryId;

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

		IF(ISNULL(@CashAmount,0) > 0)
		BEGIN
			SELECT @SiteId=[SiteId],@Site=[SiteName],@WarehouseId=[WarehouseId],@Warehouse=[Warehouse],
			@LocationId=[LocationId],@Location=[Location],@BinId=[BinId],@Bin=[BinName],@ShelfId=[ShelfId],
			@Shelf=[ShelfName],@AssetInventoryName=InventoryNumber,@ManagementStructureId = ManagementStructureId,
			@MasterCompanyId=MasterCompanyId FROM [DBO].[AssetInventory] WITH(NOLOCK) 
			WHERE AssetInventoryId = @AssetInventoryId;

			SELECT TOP 1  @IsAutoPost = ISNULL(IsAutoPost,0)
				FROM [DBO].[DistributionSetup] WITH(NOLOCK)  WHERE DistributionSetupCode = 'CASHARTRADEAROTHERSALE' AND MasterCompanyId = @MasterCompanyId;

			SELECT @DeprExpenseGLAccountId= DeprExpenseGLAccountId,@AdDepsGLAccountId= AdDepsGLAccountId,
			@AssetSaleGLAccountId=AssetSaleGLAccountId
			FROM DBO.AssetInventory WITH(NOLOCK) WHERE AssetInventoryId=@AssetInventoryId;

			SET @Desc = 'Inventory Num -' + @AssetInventoryName;
			SELECT @DistributionMasterId =ID,@DistributionCode =DistributionCode FROM DistributionMaster WITH(NOLOCK) WHERE UPPER(DistributionCode)= UPPER('ASSETSALEWRITEDOWNWRITEOFF')
			
			SELECT TOP 1 @JournalTypeId =JournalTypeId FROM [DBO].[DistributionSetup] WITH(NOLOCK)  
			WHERE DistributionMasterId = @DistributionMasterId AND MasterCompanyId = @MasterCompanyId AND DistributionSetupCode='CASHARTRADEAROTHERSALE';
			
			SELECT @StatusId =Id,@StatusName=name FROM [DBO].[BatchStatus] WITH(NOLOCK)  WHERE Name= 'Open'
			SELECT @JournalBatchHeaderId = JournalBatchHeaderId FROM [DBO].[BatchHeader] WITH(NOLOCK)  WHERE JournalTypeId= @JournalTypeId and StatusId=@StatusId
			SELECT @JournalTypeCode =JournalTypeCode,@JournalTypename=JournalTypeName FROM [DBO].[JournalType] WITH(NOLOCK)  WHERE ID= @JournalTypeId
			SELECT @CurrentManagementStructureId = ManagementStructureId FROM [DBO].[Employee] WITH(NOLOCK)  WHERE CONCAT(TRIM(FirstName),'',TRIM(LastName)) IN (REPLACE(@UpdateBy, ' ', '')) and MasterCompanyId=@MasterCompanyId
			SELECT @LastMSLevel = LastMSLevel,@AllMSlevels = AllMSlevels FROM [DBO].[AssetManagementStructureDetails] WITH(NOLOCK) WHERE ReferenceID = @ManagementStructureId;
			
			INSERT INTO #tmpCodePrefixes (CodePrefixId,CodeTypeId,CurrentNumber, CodePrefix, CodeSufix, StartsFrom) 
			SELECT CodePrefixId, CP.CodeTypeId, CurrentNummber, CodePrefix, CodeSufix, StartsFrom 
			FROM [DBO].[CodePrefixes] CP WITH(NOLOCK) JOIN [DBO].[CodeTypes] CT WITH(NOLOCK) ON CP.CodeTypeId = CT.CodeTypeId
			WHERE CT.CodeTypeId IN (@CodeTypeId) AND CP.MasterCompanyId = @MasterCompanyId AND CP.IsActive = 1 AND CP.IsDeleted = 0;
			
			SELECT TOP 1  @AccountingPeriodId=acc.AccountingCalendarId,@AccountingPeriod=PeriodName 
			FROM [DBO].[EntityStructureSetup] est WITH(NOLOCK) 
			INNER JOIN [DBO].[ManagementStructureLevel] msl WITH(NOLOCK) ON est.Level1Id = msl.ID 
			INNER JOIN [DBO].[AccountingCalendar] acc WITH(NOLOCK) ON msl.LegalEntityId = acc.LegalEntityId and acc.IsDeleted =0
			WHERE est.EntityStructureId=@CurrentManagementStructureId AND acc.MasterCompanyId=@MasterCompanyId  

			AND CAST(GETUTCDATE() AS DATE)   >= CAST(FromDate AS DATE) AND  CAST(GETUTCDATE() AS DATE) <= CAST(ToDate AS DATE)
			
			IF(EXISTS (SELECT 1 FROM #tmpCodePrefixes WHERE CodeTypeId = @CodeTypeId))
			BEGIN 
				SELECT 
					@currentNo = CASE WHEN CurrentNumber > 0 THEN CAST(CurrentNumber AS BIGINT) + 1 
					ELSE CAST(StartsFrom AS BIGINT) + 1 END 
					FROM #tmpCodePrefixes WHERE CodeTypeId = @CodeTypeId
					  	  
				SET @JournalTypeNumber = (SELECT * FROM [DBO].[udfGenerateCodeNumber](@currentNo,(SELECT CodePrefix FROM #tmpCodePrefixes WHERE CodeTypeId = @CodeTypeId), (SELECT CodeSufix FROM #tmpCodePrefixes WHERE CodeTypeId = @CodeTypeId)))
			END
			ELSE 
			BEGIN 
				ROLLBACK TRAN;
			END

			IF NOT EXISTS(SELECT JournalBatchHeaderId FROM [DBO].[BatchHeader] WITH(NOLOCK)  WHERE JournalTypeId= @JournalTypeId and MasterCompanyId=@MasterCompanyId and CAST(EntryDate AS DATE) = CAST(GETUTCDATE() AS DATE)and StatusId=@StatusId)
			BEGIN
				IF NOT EXISTS(SELECT JournalBatchHeaderId FROM [DBO].[BatchHeader] WITH(NOLOCK))
				BEGIN  
					set @batch ='001'  
					set @Currentbatch='001' 
				END
				ELSE
				BEGIN 
					SELECT top 1 @Currentbatch = CASE WHEN CurrentNumber > 0 THEN CAST(CurrentNumber AS BIGINT) + 1   
					  ELSE  1 END   
					FROM [DBO].[BatchHeader] WITH(NOLOCK) ORDER BY JournalBatchHeaderId DESC  

					IF(CAST(@Currentbatch AS BIGINT) >99)  
					BEGIN
						SET @batch = CASE WHEN CAST(@Currentbatch AS BIGINT) > 99 THEN cast(@Currentbatch AS VARCHAR(100))  
						  ELSE CONCAT('00', CAST(@Currentbatch AS VARCHAR(50))) END   
					END  
					ELSE IF(CAST(@Currentbatch AS BIGINT) >9)  
					BEGIN    
						SET @batch = CASE WHEN CAST(@Currentbatch AS BIGINT) > 99 THEN cast(@Currentbatch AS VARCHAR(100))  
						  ELSE CONCAT('0', CAST(@Currentbatch AS VARCHAR(50))) END   
					END
					ELSE
					BEGIN
					   SET @batch = CASE WHEN CAST(@Currentbatch AS BIGINT) > 99 THEN cast(@Currentbatch AS VARCHAR(100))  
						  ELSE CONCAT('00', CAST(@Currentbatch AS VARCHAR(50))) END   
					END  
				END
			
				SET @CurrentNumber = CAST(@Currentbatch AS BIGINT)     
							  SET @batch = CAST(@JournalTypeCode +' '+CAST(@batch AS VARCHAR(100)) AS VARCHAR(100))  

				INSERT INTO [dbo].[BatchHeader]    
				  ([BatchName],[CurrentNumber],[EntryDate],[AccountingPeriod],AccountingPeriodId,[StatusId],[StatusName],
				  [JournalTypeId],[JournalTypeName],[TotalDebit],[TotalCredit],[TotalBalance],[MasterCompanyId],
				  [CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted],[Module])    
				VALUES    
				  (@batch,@CurrentNumber,GETUTCDATE(),@AccountingPeriod,@AccountingPeriodId,@StatusId,@StatusName,
				  @JournalTypeId,@JournalTypename,@CashAmount,@CashAmount,0,@MasterCompanyId,
				  @UpdateBy,@UpdateBy,GETUTCDATE(),GETUTCDATE(),1,0,'ASSETSALE');    
                           
				SELECT @JournalBatchHeaderId = SCOPE_IDENTITY()    
				UPDATE [dbo].[BatchHeader] set CurrentNumber=@CurrentNumber WHERE JournalBatchHeaderId= @JournalBatchHeaderId  
			END
			ELSE
			BEGIN 
				SELECT @JournalBatchHeaderId=JournalBatchHeaderId,@CurrentPeriodId=isnull(AccountingPeriodId,0) FROM [DBO].[BatchHeader] WITH(NOLOCK)  WHERE JournalTypeId= @JournalTypeId and StatusId=@StatusId   
				   SELECT @LineNumber = CASE WHEN LineNumber > 0 THEN CAST(LineNumber AS BIGINT) + 1 ELSE  1 END   
						 FROM [DBO].[BatchDetails] WITH(NOLOCK) WHERE JournalBatchHeaderId=@JournalBatchHeaderId  ORDER BY JournalBatchDetailId DESC   
          
				IF(@CurrentPeriodId =0)  
				BEGIN  
				   Update [DBO].[BatchHeader] SET AccountingPeriodId=@AccountingPeriodId,AccountingPeriod=@AccountingPeriod  WHERE JournalBatchHeaderId= @JournalBatchHeaderId  
				END  
			END

			--AutoPost Batch
			IF(@IsAutoPost = 1)
			BEGIN
				EXEC [dbo].[UpdateToPostFullBatch] @JournalBatchHeaderId,@UpdateBy;
			END

			INSERT INTO [DBO].[BatchDetails](JournalTypeNumber,CurrentNumber,DistributionSetupId, DistributionName, [JournalBatchHeaderId], [LineNumber], [GlAccountId], [GlAccountNumber], [GlAccountName], 
			[TransactionDate], [EntryDate], [JournalTypeId], [JournalTypeName], [IsDebit], [DebitAmount], [CreditAmount], [ManagementStructureId], [ModuleName], LastMSLevel, AllMSlevels, [MasterCompanyId], 
			[CreatedBy], [UpdatedBy], [CreatedDate], [UpdatedDate], [IsActive], [IsDeleted], [AccountingPeriodId], [AccountingPeriod])
			VALUES(@JournalTypeNumber,@currentNo,0, NULL, @JournalBatchHeaderId, 1, 0, NULL, NULL, GETUTCDATE(), GETUTCDATE(), 
			@JournalTypeId, @JournalTypename, 1, 0, 0, @ManagementStructureId, @DistributionCodeName, 
			NULL, NULL, @MasterCompanyId, @UpdateBy, @UpdateBy, GETUTCDATE(), GETUTCDATE(), 1, 0, @AccountingPeriodId, @AccountingPeriod)
		
			SET @JournalBatchDetailId=SCOPE_IDENTITY()

			-----Cash/AR Trade/AR Other--------
			IF(@CashAmount > 0)
			BEGIN 
				SELECT TOP 1 @DistributionSetupId=ID,@DistributionName=Name,@JournalTypeId =JournalTypeId,
				@GlAccountId=GlAccountId,@GlAccountNumber=GlAccountNumber,@GlAccountName=GlAccountName ,@CrDrType = CRDRType
				FROM [DBO].[DistributionSetup] WITH(NOLOCK)  WHERE DistributionSetupCode = 'CASHARTRADEAROTHERSALE' AND MasterCompanyId = @MasterCompanyId;

				INSERT INTO [dbo].[CommonBatchDetails]
					(JournalBatchDetailId,JournalTypeNumber,CurrentNumber,DistributionSetupId,DistributionName,[JournalBatchHeaderId],[LineNumber],
					[GlAccountId],[GlAccountNumber],[GlAccountName] ,[TransactionDate],[EntryDate] ,[JournalTypeId],[JournalTypeName],
					[IsDebit],[DebitAmount] ,[CreditAmount],[ManagementStructureId],[ModuleName],LastMSLevel,AllMSlevels,[MasterCompanyId],
					[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate] ,[IsActive] ,[IsDeleted])
				VALUES	
					(@JournalBatchDetailId,@JournalTypeNumber,@currentNo,@DistributionSetupId,@DistributionName,@JournalBatchHeaderId,1 
					,@GlAccountId ,@GlAccountNumber ,@GlAccountName,GETUTCDATE(),GETUTCDATE(),@JournalTypeId ,@JournalTypename,
					CASE WHEN @CrDrType = 1 THEN 1 ELSE 0 END,
					CASE WHEN @CrDrType = 1 THEN @CashAmount ELSE 0 END,
					CASE WHEN @CrDrType = 1 THEN 0 ELSE @CashAmount END,
					@ManagementStructureId ,@ModuleName,@LastMSLevel,@AllMSlevels ,@MasterCompanyId,
					@UpdateBy,@UpdateBy,GETUTCDATE(),GETUTCDATE(),1,0)

				SET @CommonBatchDetailId = SCOPE_IDENTITY()

				-----  Accounting MS Entry  -----

				EXEC [dbo].[PROCAddUpdateAccountingBatchMSData] @CommonBatchDetailId,@ManagementStructureId,@MasterCompanyId,@UpdateBy,@AccountMSModuleId,1; 
					
				
				INSERT INTO [DBO].[StocklineBatchDetails]
					(JournalBatchDetailId,JournalBatchHeaderId,VendorId,VendorName,ItemMasterId,PartId,PartNumber,PoId,PONum,RoId,RONum,StocklineId,StocklineNumber,Consignment,[Description],
					[SiteId],[Site],[WarehouseId],[Warehouse],[LocationId],[Location],[BinId],[Bin],[ShelfId],[Shelf],[StockType],[CommonJournalBatchDetailId])
				VALUES
					(@JournalBatchDetailId,@JournalBatchHeaderId,NULL,NULL,NULL,NULL,NULL,@AssetInventoryId,@AssetInventoryName,@AssetInventoryId,@AssetInventoryName,@AssetInventoryId,
					NULL,'',@Desc,@SiteId,@Site,@WarehouseId,@Warehouse,@LocationId,@Location,@BinId,@Bin,@ShelfId,@Shelf,@StocktypeAsset,@CommonBatchDetailId)
			END
			
			-----Cash/AR Trade/AR Other--------

			-----ACCUMULATED DEPRECIATION--------
			IF(@DepreciationAmount > 0)
			BEGIN 
				SELECT TOP 1 @DistributionSetupId=ID,@DistributionName=Name,@JournalTypeId =JournalTypeId,
				@GlAccountId=GlAccountId,@GlAccountNumber=GlAccountNumber,@GlAccountName=GlAccountName ,@CrDrType = CRDRType
				FROM [DBO].[DistributionSetup] WITH(NOLOCK)  WHERE DistributionSetupCode = 'ACCUMULATEDDEPRECIATIONSALE' AND MasterCompanyId = @MasterCompanyId 

				SELECT @GlAccountNumber=AccountCode,@GlAccountName=AccountName,@GlAccountId=@AdDepsGLAccountId
				FROM DBO.GLAccount WITH(NOLOCK) where GLAccountId=@AdDepsGLAccountId

				INSERT INTO [dbo].[CommonBatchDetails]
					(JournalBatchDetailId,JournalTypeNumber,CurrentNumber,DistributionSetupId,DistributionName,[JournalBatchHeaderId],[LineNumber],
					[GlAccountId],[GlAccountNumber],[GlAccountName] ,[TransactionDate],[EntryDate] ,[JournalTypeId],[JournalTypeName],
					[IsDebit],[DebitAmount] ,[CreditAmount],[ManagementStructureId],[ModuleName],LastMSLevel,AllMSlevels,[MasterCompanyId],
					[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate] ,[IsActive] ,[IsDeleted])
				VALUES	
					(@JournalBatchDetailId,@JournalTypeNumber,@currentNo,@DistributionSetupId,@DistributionName,@JournalBatchHeaderId,1 
					,@GlAccountId ,@GlAccountNumber ,@GlAccountName,GETUTCDATE(),GETUTCDATE(),@JournalTypeId ,@JournalTypename,
					CASE WHEN @CrDrType = 1 THEN 1 ELSE 0 END,
					CASE WHEN @CrDrType = 1 THEN @DepreciationAmount ELSE 0 END,
					CASE WHEN @CrDrType = 1 THEN 0 ELSE @DepreciationAmount END,
					--1,@DepreciationAmount,0,
					@ManagementStructureId ,@ModuleName,@LastMSLevel,@AllMSlevels ,@MasterCompanyId,
					@UpdateBy,@UpdateBy,GETUTCDATE(),GETUTCDATE(),1,0)

				SET @CommonBatchDetailId = SCOPE_IDENTITY()

				-----  Accounting MS Entry  -----

				EXEC [dbo].[PROCAddUpdateAccountingBatchMSData] @CommonBatchDetailId,@ManagementStructureId,@MasterCompanyId,@UpdateBy,@AccountMSModuleId,1; 

				INSERT INTO [DBO].[StocklineBatchDetails]
					(JournalBatchDetailId,JournalBatchHeaderId,VendorId,VendorName,ItemMasterId,PartId,PartNumber,PoId,PONum,RoId,RONum,StocklineId,StocklineNumber,Consignment,[Description],
					[SiteId],[Site],[WarehouseId],[Warehouse],[LocationId],[Location],[BinId],[Bin],[ShelfId],[Shelf],[StockType],[CommonJournalBatchDetailId])
				VALUES
					(@JournalBatchDetailId,@JournalBatchHeaderId,NULL,NULL,NULL,NULL,NULL,@AssetInventoryId,@AssetInventoryName,@AssetInventoryId,@AssetInventoryName,@AssetInventoryId,
					NULL,'',@Desc,@SiteId,@Site,@WarehouseId,@Warehouse,@LocationId,@Location,@BinId,@Bin,@ShelfId,@Shelf,@StocktypeAsset,@CommonBatchDetailId)
			END
			
			-----ACCUMULATED DEPRECIATION--------
			
			SET @BenifitAmount = (@DepreciationAmount +  @CashAmount)
			SET @FinalSaleAsset = (@BenifitAmount - @InstallCost);

			IF(@FinalSaleAsset > 0)
			BEGIN
				SET @IsSaleAssetDRCR = @SaleAssetDRCR;
			END
			ELSE
			BEGIN
				SET @FinalSaleAsset = ABS(@FinalSaleAsset);
			END

			-----Loss/(Gain) On Disposal--------

			IF(@WrittenOffStatus = @Status)
			BEGIN
				IF(@FinalSaleAsset > 0)
				BEGIN
					SELECT TOP 1 @DistributionSetupId=ID,@DistributionName=Name,@JournalTypeId =JournalTypeId,
					@GlAccountId=GlAccountId,@GlAccountNumber=GlAccountNumber,@GlAccountName=GlAccountName ,@CrDrType = CRDRType
					FROM [DBO].[DistributionSetup] WITH(NOLOCK)  WHERE DistributionSetupCode = 'LOSSGAINONDISPOSALSALE' AND MasterCompanyId = @MasterCompanyId

					SELECT @GlAccountNumber=AccountCode,@GlAccountName=AccountName,@GlAccountId=@AdDepsGLAccountId
					FROM DBO.GLAccount WITH(NOLOCK) where GLAccountId=@AdDepsGLAccountId;

					INSERT INTO [dbo].[CommonBatchDetails]
					(JournalBatchDetailId,JournalTypeNumber,CurrentNumber,DistributionSetupId,DistributionName,[JournalBatchHeaderId],[LineNumber],
					[GlAccountId],[GlAccountNumber],[GlAccountName] ,[TransactionDate],[EntryDate] ,[JournalTypeId],[JournalTypeName],
					[IsDebit],[DebitAmount] ,[CreditAmount],[ManagementStructureId],[ModuleName],LastMSLevel,AllMSlevels,[MasterCompanyId],
					[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate] ,[IsActive] ,[IsDeleted])
					VALUES	
					(@JournalBatchDetailId,@JournalTypeNumber,@currentNo,@DistributionSetupId,@DistributionName,@JournalBatchHeaderId,1 
					,@GlAccountId ,@GlAccountNumber ,@GlAccountName,GETUTCDATE(),GETUTCDATE(),@JournalTypeId ,@JournalTypename,
					CASE WHEN @IsSaleAssetDRCR = 1 THEN 0 ELSE 1 END,
					CASE WHEN @IsSaleAssetDRCR = 1 THEN 0 ELSE @FinalSaleAsset END,
					CASE WHEN @IsSaleAssetDRCR = 1 THEN @FinalSaleAsset ELSE 0 END,
					@ManagementStructureId ,@ModuleName,@LastMSLevel,@AllMSlevels ,@MasterCompanyId,
					@UpdateBy,@UpdateBy,GETUTCDATE(),GETUTCDATE(),1,0)

					SET @CommonBatchDetailId = SCOPE_IDENTITY()

					-----  Accounting MS Entry  -----

					EXEC [dbo].[PROCAddUpdateAccountingBatchMSData] @CommonBatchDetailId,@ManagementStructureId,@MasterCompanyId,@UpdateBy,@AccountMSModuleId,1; 
			
					INSERT INTO [DBO].[StocklineBatchDetails]
						(JournalBatchDetailId,JournalBatchHeaderId,VendorId,VendorName,ItemMasterId,PartId,PartNumber,PoId,PONum,RoId,RONum,StocklineId,StocklineNumber,Consignment,[Description],
						[SiteId],[Site],[WarehouseId],[Warehouse],[LocationId],[Location],[BinId],[Bin],[ShelfId],[Shelf],[StockType],[CommonJournalBatchDetailId])
					VALUES
						(@JournalBatchDetailId,@JournalBatchHeaderId,NULL,NULL,NULL,NULL,NULL,@AssetInventoryId,@AssetInventoryName,@AssetInventoryId,@AssetInventoryName,@AssetInventoryId,
						NULL,'',@Desc,@SiteId,@Site,@WarehouseId,@Warehouse,@LocationId,@Location,@BinId,@Bin,@ShelfId,@Shelf,@StocktypeAsset,@CommonBatchDetailId)
				END

				IF(@FinalSaleAsset < 0)
				BEGIN 
					SELECT TOP 1 @DistributionSetupId=ID,@DistributionName=Name,@JournalTypeId =JournalTypeId,
					@GlAccountId=GlAccountId,@GlAccountNumber=GlAccountNumber,@GlAccountName=GlAccountName ,@CrDrType = CRDRType
					FROM [DBO].[DistributionSetup] WITH(NOLOCK)  WHERE DistributionSetupCode = 'LOSSGAINONDISPOSALSALE' AND MasterCompanyId = @MasterCompanyId

					SELECT @GlAccountNumber=AccountCode,@GlAccountName=AccountName,@GlAccountId=@AdDepsGLAccountId
					FROM DBO.GLAccount WITH(NOLOCK) where GLAccountId=@AdDepsGLAccountId;

					INSERT INTO [dbo].[CommonBatchDetails]
						(JournalBatchDetailId,JournalTypeNumber,CurrentNumber,DistributionSetupId,DistributionName,[JournalBatchHeaderId],[LineNumber],
						[GlAccountId],[GlAccountNumber],[GlAccountName] ,[TransactionDate],[EntryDate] ,[JournalTypeId],[JournalTypeName],
						[IsDebit],[DebitAmount] ,[CreditAmount],[ManagementStructureId],[ModuleName],LastMSLevel,AllMSlevels,[MasterCompanyId],
						[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate] ,[IsActive] ,[IsDeleted])
					VALUES	
						(@JournalBatchDetailId,@JournalTypeNumber,@currentNo,@DistributionSetupId,@DistributionName,@JournalBatchHeaderId,1 
						,@GlAccountId ,@GlAccountNumber ,@GlAccountName,GETUTCDATE(),GETUTCDATE(),@JournalTypeId ,@JournalTypename,
						CASE WHEN @IsSaleAssetDRCR = 1 THEN 0 ELSE 1 END,
						CASE WHEN @IsSaleAssetDRCR = 1 THEN 0 ELSE @FinalSaleAsset END,
						CASE WHEN @IsSaleAssetDRCR = 1 THEN @FinalSaleAsset ELSE 0 END,
						@ManagementStructureId ,@ModuleName,@LastMSLevel,@AllMSlevels ,@MasterCompanyId,
						@UpdateBy,@UpdateBy,GETUTCDATE(),GETUTCDATE(),1,0)

					SET @CommonBatchDetailId = SCOPE_IDENTITY()

					-----  Accounting MS Entry  -----

					EXEC [dbo].[PROCAddUpdateAccountingBatchMSData] @CommonBatchDetailId,@ManagementStructureId,@MasterCompanyId,@UpdateBy,@AccountMSModuleId,1; 
			
					INSERT INTO [DBO].[StocklineBatchDetails]
						(JournalBatchDetailId,JournalBatchHeaderId,VendorId,VendorName,ItemMasterId,PartId,PartNumber,PoId,PONum,RoId,RONum,StocklineId,StocklineNumber,Consignment,[Description],
						[SiteId],[Site],[WarehouseId],[Warehouse],[LocationId],[Location],[BinId],[Bin],[ShelfId],[Shelf],[StockType],[CommonJournalBatchDetailId])
					VALUES
						(@JournalBatchDetailId,@JournalBatchHeaderId,NULL,NULL,NULL,NULL,NULL,@AssetInventoryId,@AssetInventoryName,@AssetInventoryId,@AssetInventoryName,@AssetInventoryId,
						NULL,'',@Desc,@SiteId,@Site,@WarehouseId,@Warehouse,@LocationId,@Location,@BinId,@Bin,@ShelfId,@Shelf,@StocktypeAsset,@CommonBatchDetailId)
				END
			END
			
			-----Loss/(Gain) On Disposal--------

			-----Loss/(Gain) On Write Off--------

			IF(@SoldStatus = @Status)
			BEGIN
				IF(@FinalSaleAsset > 0)
				BEGIN
					SELECT TOP 1 @DistributionSetupId=ID,@DistributionName=Name,@JournalTypeId =JournalTypeId,
					@GlAccountId=GlAccountId,@GlAccountNumber=GlAccountNumber,@GlAccountName=GlAccountName ,@CrDrType = CRDRType
					FROM [DBO].[DistributionSetup] WITH(NOLOCK)  WHERE DistributionSetupCode = 'LOSSGAINONWRITEOFFSALE' AND MasterCompanyId = @MasterCompanyId

					SELECT @GlAccountNumber=AccountCode,@GlAccountName=AccountName,@GlAccountId=@AdDepsGLAccountId
					FROM DBO.GLAccount WITH(NOLOCK) where GLAccountId=@AdDepsGLAccountId;

					INSERT INTO [dbo].[CommonBatchDetails]
					(JournalBatchDetailId,JournalTypeNumber,CurrentNumber,DistributionSetupId,DistributionName,[JournalBatchHeaderId],[LineNumber],
					[GlAccountId],[GlAccountNumber],[GlAccountName] ,[TransactionDate],[EntryDate] ,[JournalTypeId],[JournalTypeName],
					[IsDebit],[DebitAmount] ,[CreditAmount],[ManagementStructureId],[ModuleName],LastMSLevel,AllMSlevels,[MasterCompanyId],
					[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate] ,[IsActive] ,[IsDeleted])
					VALUES	
					(@JournalBatchDetailId,@JournalTypeNumber,@currentNo,@DistributionSetupId,@DistributionName,@JournalBatchHeaderId,1 
					,@GlAccountId ,@GlAccountNumber ,@GlAccountName,GETUTCDATE(),GETUTCDATE(),@JournalTypeId ,@JournalTypename,
					CASE WHEN @IsSaleAssetDRCR = 1 THEN 0 ELSE 1 END,
					CASE WHEN @IsSaleAssetDRCR = 1 THEN 0 ELSE @FinalSaleAsset END,
					CASE WHEN @IsSaleAssetDRCR = 1 THEN @FinalSaleAsset ELSE 0 END,
					@ManagementStructureId ,@ModuleName,@LastMSLevel,@AllMSlevels ,@MasterCompanyId,
					@UpdateBy,@UpdateBy,GETUTCDATE(),GETUTCDATE(),1,0)

					SET @CommonBatchDetailId = SCOPE_IDENTITY()

					-----  Accounting MS Entry  -----

					EXEC [dbo].[PROCAddUpdateAccountingBatchMSData] @CommonBatchDetailId,@ManagementStructureId,@MasterCompanyId,@UpdateBy,@AccountMSModuleId,1; 
			
					INSERT INTO [DBO].[StocklineBatchDetails]
						(JournalBatchDetailId,JournalBatchHeaderId,VendorId,VendorName,ItemMasterId,PartId,PartNumber,PoId,PONum,RoId,RONum,StocklineId,StocklineNumber,Consignment,[Description],
						[SiteId],[Site],[WarehouseId],[Warehouse],[LocationId],[Location],[BinId],[Bin],[ShelfId],[Shelf],[StockType],[CommonJournalBatchDetailId])
					VALUES
						(@JournalBatchDetailId,@JournalBatchHeaderId,NULL,NULL,NULL,NULL,NULL,@AssetInventoryId,@AssetInventoryName,@AssetInventoryId,@AssetInventoryName,@AssetInventoryId,
						NULL,'',@Desc,@SiteId,@Site,@WarehouseId,@Warehouse,@LocationId,@Location,@BinId,@Bin,@ShelfId,@Shelf,@StocktypeAsset,@CommonBatchDetailId)
				END

				IF(@FinalSaleAsset < 0)
				BEGIN 
					SELECT TOP 1 @DistributionSetupId=ID,@DistributionName=Name,@JournalTypeId =JournalTypeId,
					@GlAccountId=GlAccountId,@GlAccountNumber=GlAccountNumber,@GlAccountName=GlAccountName ,@CrDrType = CRDRType
					FROM [DBO].[DistributionSetup] WITH(NOLOCK)  WHERE DistributionSetupCode = 'LOSSGAINONWRITEOFFSALE' AND MasterCompanyId = @MasterCompanyId

					SELECT @GlAccountNumber=AccountCode,@GlAccountName=AccountName,@GlAccountId=@AdDepsGLAccountId
					FROM DBO.GLAccount WITH(NOLOCK) where GLAccountId=@AdDepsGLAccountId;

					INSERT INTO [dbo].[CommonBatchDetails]
						(JournalBatchDetailId,JournalTypeNumber,CurrentNumber,DistributionSetupId,DistributionName,[JournalBatchHeaderId],[LineNumber],
						[GlAccountId],[GlAccountNumber],[GlAccountName] ,[TransactionDate],[EntryDate] ,[JournalTypeId],[JournalTypeName],
						[IsDebit],[DebitAmount] ,[CreditAmount],[ManagementStructureId],[ModuleName],LastMSLevel,AllMSlevels,[MasterCompanyId],
						[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate] ,[IsActive] ,[IsDeleted])
					VALUES	
						(@JournalBatchDetailId,@JournalTypeNumber,@currentNo,@DistributionSetupId,@DistributionName,@JournalBatchHeaderId,1 
						,@GlAccountId ,@GlAccountNumber ,@GlAccountName,GETUTCDATE(),GETUTCDATE(),@JournalTypeId ,@JournalTypename,
						CASE WHEN @IsSaleAssetDRCR = 1 THEN 0 ELSE 1 END,
						CASE WHEN @IsSaleAssetDRCR = 1 THEN 0 ELSE @FinalSaleAsset END,
						CASE WHEN @IsSaleAssetDRCR = 1 THEN @FinalSaleAsset ELSE 0 END,
						@ManagementStructureId ,@ModuleName,@LastMSLevel,@AllMSlevels ,@MasterCompanyId,
						@UpdateBy,@UpdateBy,GETUTCDATE(),GETUTCDATE(),1,0)

					SET @CommonBatchDetailId = SCOPE_IDENTITY()

					-----  Accounting MS Entry  -----

					EXEC [dbo].[PROCAddUpdateAccountingBatchMSData] @CommonBatchDetailId,@ManagementStructureId,@MasterCompanyId,@UpdateBy,@AccountMSModuleId,1; 
			
					INSERT INTO [DBO].[StocklineBatchDetails]
						(JournalBatchDetailId,JournalBatchHeaderId,VendorId,VendorName,ItemMasterId,PartId,PartNumber,PoId,PONum,RoId,RONum,StocklineId,StocklineNumber,Consignment,[Description],
						[SiteId],[Site],[WarehouseId],[Warehouse],[LocationId],[Location],[BinId],[Bin],[ShelfId],[Shelf],[StockType],[CommonJournalBatchDetailId])
					VALUES
						(@JournalBatchDetailId,@JournalBatchHeaderId,NULL,NULL,NULL,NULL,NULL,@AssetInventoryId,@AssetInventoryName,@AssetInventoryId,@AssetInventoryName,@AssetInventoryId,
						NULL,'',@Desc,@SiteId,@Site,@WarehouseId,@Warehouse,@LocationId,@Location,@BinId,@Bin,@ShelfId,@Shelf,@StocktypeAsset,@CommonBatchDetailId)
				END
			END
			-----Loss/(Gain) On Write Off--------

			-----Asset Installed Cost--------
			IF(@InstallCost > 0)
			BEGIN 
				SELECT TOP 1 @DistributionSetupId=ID,@DistributionName=Name,@JournalTypeId =JournalTypeId,
				@GlAccountId=GlAccountId,@GlAccountNumber=GlAccountNumber,@GlAccountName=GlAccountName ,@CrDrType = CRDRType
				FROM [DBO].[DistributionSetup] WITH(NOLOCK)  WHERE DistributionSetupCode = 'ASSETINSTALLEDCOSTSALE'  AND MasterCompanyId = @MasterCompanyId

				SELECT @GlAccountNumber=AccountCode,@GlAccountName=AccountName,@GlAccountId=@AdDepsGLAccountId
				FROM DBO.GLAccount WITH(NOLOCK) where GLAccountId=@AdDepsGLAccountId

				INSERT INTO [dbo].[CommonBatchDetails]
					(JournalBatchDetailId,JournalTypeNumber,CurrentNumber,DistributionSetupId,DistributionName,[JournalBatchHeaderId],[LineNumber],
					[GlAccountId],[GlAccountNumber],[GlAccountName] ,[TransactionDate],[EntryDate] ,[JournalTypeId],[JournalTypeName],
					[IsDebit],[DebitAmount] ,[CreditAmount],[ManagementStructureId],[ModuleName],LastMSLevel,AllMSlevels,[MasterCompanyId],
					[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate] ,[IsActive] ,[IsDeleted])
				VALUES	
					(@JournalBatchDetailId,@JournalTypeNumber,@currentNo,@DistributionSetupId,@DistributionName,@JournalBatchHeaderId,1 
					,@GlAccountId ,@GlAccountNumber ,@GlAccountName,GETUTCDATE(),GETUTCDATE(),@JournalTypeId ,@JournalTypename,
					CASE WHEN @CrDrType = 1 THEN 1 ELSE 0 END,
					CASE WHEN @CrDrType = 1 THEN @InstallCost ELSE 0 END,
					CASE WHEN @CrDrType = 1 THEN 0 ELSE @InstallCost END,
					@ManagementStructureId ,@ModuleName,@LastMSLevel,@AllMSlevels ,@MasterCompanyId,
					@UpdateBy,@UpdateBy,GETUTCDATE(),GETUTCDATE(),1,0)

				SET @CommonBatchDetailId = SCOPE_IDENTITY()

				-----  Accounting MS Entry  -----

				EXEC [dbo].[PROCAddUpdateAccountingBatchMSData] @CommonBatchDetailId,@ManagementStructureId,@MasterCompanyId,@UpdateBy,@AccountMSModuleId,1; 

				INSERT INTO [DBO].[StocklineBatchDetails]
					(JournalBatchDetailId,JournalBatchHeaderId,VendorId,VendorName,ItemMasterId,PartId,PartNumber,PoId,PONum,RoId,RONum,StocklineId,StocklineNumber,Consignment,[Description],
					[SiteId],[Site],[WarehouseId],[Warehouse],[LocationId],[Location],[BinId],[Bin],[ShelfId],[Shelf],[StockType],[CommonJournalBatchDetailId])
				VALUES
					(@JournalBatchDetailId,@JournalBatchHeaderId,NULL,NULL,NULL,NULL,NULL,@AssetInventoryId,@AssetInventoryName,@AssetInventoryId,@AssetInventoryName,@AssetInventoryId,
					NULL,'',@Desc,@SiteId,@Site,@WarehouseId,@Warehouse,@LocationId,@Location,@BinId,@Bin,@ShelfId,@Shelf,@StocktypeAsset,@CommonBatchDetailId)
			END
			
			-----Asset Installed Cost--------

			SET @TotalDebit=0;
			SET @TotalCredit=0;
			SELECT @TotalDebit =SUM(DebitAmount),@TotalCredit=SUM(CreditAmount) FROM [dbo].[CommonBatchDetails] WITH(NOLOCK) WHERE JournalBatchDetailId=@JournalBatchDetailId GROUP BY JournalBatchDetailId
			Update [dbo].[BatchDetails] SET DebitAmount=@TotalDebit,CreditAmount=@TotalCredit,UpdatedDate=GETUTCDATE(),UpdatedBy=@UpdateBy  WHERE JournalBatchDetailId=@JournalBatchDetailId
		END

		
		SELECT @TotalDebit =SUM(DebitAmount),@TotalCredit=SUM(CreditAmount) FROM [DBO].[BatchDetails] 
		WITH(NOLOCK) WHERE JournalBatchHeaderId=@JournalBatchHeaderId and IsDeleted=0 
		SET @TotalBalance =@TotalDebit-@TotalCredit

		UPDATE [DBO].[CodePrefixes] SET CurrentNummber = @currentNo WHERE CodeTypeId = @CodeTypeId AND MasterCompanyId = @MasterCompanyId    
	    UPDATE [DBO].[BatchHeader] SET TotalDebit=@TotalDebit,TotalCredit=@TotalCredit,TotalBalance=@TotalBalance,UpdatedDate=GETUTCDATE(),UpdatedBy=@UpdateBy WHERE JournalBatchHeaderId= @JournalBatchHeaderId

	END TRY
	BEGIN CATCH
		DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
		-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_Assets_PostCheckBatchDetails' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''
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