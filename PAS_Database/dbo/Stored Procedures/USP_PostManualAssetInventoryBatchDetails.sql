/*************************************************************           
 ** File:   [USP_PostManualAssetInventoryBatchDetails]           
 ** Author: Moin Bloch
 ** Description: This stored procedure is used insert manual asset inventory detail in batch
 ** Purpose:         
 ** Date:  27-12-2023

 ** PARAMETERS:           
         
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date				 Author					Change Description            
 ** --   --------			-------				--------------------------------          
	1    09/01/2023          Moin Bloch          Created
	2    14/02/2023		     Moin Bloch			 Updated Used Distribution Setup Code Insted of Name 
     
    EXEC USP_PostManualAssetInventoryBatchDetails 551,0,1
**************************************************************/
CREATE    PROCEDURE [dbo].[USP_PostManualAssetInventoryBatchDetails]
@AssetInventoryId BIGINT,
@OldUnitCost DECIMAL(18,2),
@IsCreate BIT
AS
BEGIN 
	BEGIN TRY
		DECLARE @CodeTypeId AS BIGINT = 74;
		DECLARE @MasterCompanyId BIGINT=0;   
		DECLARE @UpdateBy VARCHAR(100);
		DECLARE @currentNo AS BIGINT = 0;
		DECLARE @JournalTypeNumber VARCHAR(100);
		DECLARE @DistributionMasterId BIGINT;    
		DECLARE @DistributionCode VARCHAR(200); 
		DECLARE @CurrentManagementStructureId BIGINT=0; 
		DECLARE @StatusId INT;    
		DECLARE @StatusName VARCHAR(200);    
		DECLARE @AccountingPeriod VARCHAR(100);    
		DECLARE @AccountingPeriodId BIGINT=0;   
		DECLARE @JournalTypeId INT;    
		DECLARE @JournalTypeCode VARCHAR(200);
		DECLARE @JournalBatchHeaderId BIGINT;    
		DECLARE @JournalTypename VARCHAR(200);  
		DECLARE @batch VARCHAR(100);    
		DECLARE @Currentbatch VARCHAR(100);    
		DECLARE @CurrentNumber INT;    
		DECLARE @Amount DECIMAL(18,2); 
		DECLARE @CurrentPeriodId BIGINT=0; 
		DECLARE @LineNumber INT=1;    
		DECLARE @JournalBatchDetailId BIGINT=0;
		DECLARE @CommonBatchDetailId BIGINT=0;
		DECLARE @DistributionSetupId INT=0
		DECLARE @Distributionname VARCHAR(200) 
		DECLARE @GlAccountId INT
		DECLARE @StartsFrom VARCHAR(200)='00'
		DECLARE @GlAccountName VARCHAR(200) 
		DECLARE @GlAccountNumber VARCHAR(200) 
		DECLARE @TotalAmount DECIMAL(18,2)
		DECLARE @ManagementStructureId BIGINT
		DECLARE @LastMSLevel VARCHAR(200)
		DECLARE @AllMSlevels VARCHAR(max)
		DECLARE @ModuleId INT
		DECLARE @TotalDebit DECIMAL(18, 2) =0;
		DECLARE @TotalCredit DECIMAL(18, 2) =0;
		DECLARE @TotalBalance DECIMAL(18, 2) =0;
		DECLARE @VendorName VARCHAR(50);
		DECLARE @CRDRType BIGINT = 0;
		DECLARE @InventoryNumber VARCHAR(50) ='';
		DECLARE @WorkOrderNumber VARCHAR(200);
		DECLARE @partId BIGINT=0;
		DECLARE @ItemMasterId BIGINT=NULL;
		DECLARE @PurchaseOrderId BIGINT=0;
		DECLARE @PurchaseOrderNumber VARCHAR(50) ='';
		DECLARE @RepairOrderId BIGINT=0;
		DECLARE @RepairOrderNumber VARCHAR(50) ='';
		DECLARE @SiteId BIGINT;
		DECLARE @Site VARCHAR(100) ='';
		DECLARE @WarehouseId BIGINT;
		DECLARE @Warehouse VARCHAR(100) ='';
		DECLARE @LocationId BIGINT;
		DECLARE @Location VARCHAR(100) ='';
		DECLARE @BinId BIGINT;
		DECLARE @Bin VARCHAR(100) ='';
		DECLARE @ShelfId BIGINT;
		DECLARE @Shelf VARCHAR(100) ='';
		DECLARE @MPNName VARCHAR(200);
		DECLARE @Desc VARCHAR(100);
		DECLARE @VendorId BIGINT;
		DECLARE @StockType VARCHAR(50) = 'ASSET';
		DECLARE @StkGlAccountId BIGINT
		DECLARE @StkGlAccountName VARCHAR(200) 
		DECLARE @StkGlAccountNumber VARCHAR(200) 
		DECLARE @AccountMSModuleId INT = 0
		DECLARE @Moduleids VARCHAR(250) = ''

		SELECT @AccountMSModuleId = [ManagementStructureModuleId] FROM [dbo].[ManagementStructureModule] WITH(NOLOCK) WHERE [ModuleName] ='Accounting';

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
		
		SELECT @TotalAmount = SUM(ISNULL(AI.UnitCost * AI.Qty,0)) FROM [dbo].[AssetInventory] AI WITH(NOLOCK) WHERE AI.[AssetInventoryId] = @AssetInventoryId;

		print @TotalAmount

		IF(ISNULL(@TotalAmount,0) > 0)
		BEGIN	
		    SELECT @MasterCompanyId = [MasterCompanyId], @UpdateBy = [CreatedBy],@CurrentManagementStructureId = [ManagementStructureId] FROM [dbo].[AssetInventory] WITH(NOLOCK) WHERE [AssetInventoryId] = @AssetInventoryId;			
			SELECT @DistributionMasterId = [ID] FROM [dbo].[DistributionMaster] WITH(NOLOCK) WHERE UPPER([DistributionCode]) = UPPER('ManualAssetInventory');	
			SELECT @StatusId = [Id],@StatusName = [name] FROM [dbo].[BatchStatus] WITH(NOLOCK) WHERE UPPER([Name]) = UPPER('Open');
			SELECT TOP 1 @JournalTypeId = [JournalTypeId] FROM [dbo].[DistributionSetup] WITH(NOLOCK) WHERE [DistributionMasterId] = @DistributionMasterId;
			SELECT @JournalBatchHeaderId = [JournalBatchHeaderId] FROM [dbo].[BatchHeader] WITH(NOLOCK) WHERE [JournalTypeId] = @JournalTypeId AND [StatusId] = @StatusId;
			SELECT @JournalTypeCode = [JournalTypeCode],@JournalTypename = [JournalTypeName] FROM [dbo].[JournalType] WITH(NOLOCK) WHERE [ID] = @JournalTypeId;						
		    SELECT @Moduleids = (SELECT STRING_AGG([ManagementStructureModuleId],',') FROM [dbo].[ManagementStructureModule] WITH(NOLOCK) WHERE [ModuleName] IN ('AssetInventoryTangible','AssetInventoryInTangible'));

			SELECT @WorkOrderNumber = [InventoryNumber], 
			       @partId = [PurchaseOrderPartRecordId], 
				   @ItemMasterId = [MasterPartId],
				   @ManagementStructureId = [ManagementStructureId], 
				   @MasterCompanyId = sl.[MasterCompanyId],
			       @PurchaseOrderId = [PurchaseOrderId], 
				   @RepairOrderId = [RepairOrderId], 
				   @InventoryNumber = [InventoryNumber],
				   @SiteId = [SiteId], 
				   @Site=[SiteName], 
				   @WarehouseId=[WarehouseId], 
				   @Warehouse=[Warehouse],
			       @LocationId=[LocationId], 
				   @Location=[Location],  
				   @BinId=[BinId],
				   @Bin=[BinName], 
				   @ShelfId=[ShelfId], 
				   @Shelf=[ShelfName], 
			       @StkGlAccountId = sl.[AcquiredGLAccountId], 
				   @StkGlAccountName = gl.[AccountName], 
				   @StkGlAccountNumber = gl.[AccountCode]
			FROM [dbo].[AssetInventory] sl WITH(NOLOCK)
			LEFT JOIN [dbo].[GLAccount] gl WITH(NOLOCK) ON sl.AcquiredGLAccountId = gl.GLAccountId
			WHERE [AssetInventoryId] = @AssetInventoryId;
									
		    SELECT @LastMSLevel = LastMSLevel,
			       @AllMSlevels = AllMSlevels 
			  FROM [dbo].[AssetManagementStructureDetails] WITH(NOLOCK) 
			 WHERE [EntityMSID] = @ManagementStructureId 
			   AND [ModuleID] IN (SELECT Item FROM dbo.SplitString(@Moduleids,','))
			   AND [ReferenceID] = @AssetInventoryId;
			
			INSERT INTO #tmpCodePrefixes 
			      ([CodePrefixId],
				   [CodeTypeId],
				   [CurrentNumber],
				   [CodePrefix],
				   [CodeSufix],
				   [StartsFrom]) 
		 SELECT CP.[CodePrefixId], 
			    CP.[CodeTypeId], 
				CP.[CurrentNummber], 
				CP.[CodePrefix], 
				CP.[CodeSufix], 
				CP.[StartsFrom]
			FROM [dbo].[CodePrefixes] CP WITH(NOLOCK) 
			JOIN [dbo].[CodeTypes] CT WITH(NOLOCK) ON CP.[CodeTypeId] = CT.[CodeTypeId]
			WHERE CT.CodeTypeId IN (@CodeTypeId) 
			  AND CP.[MasterCompanyId] = @MasterCompanyId 
			  AND CP.[IsActive] = 1 
			  AND CP.[IsDeleted] = 0;

			print @CurrentManagementStructureId
			print @MasterCompanyId

			SELECT TOP 1  @AccountingPeriodId = acc.[AccountingCalendarId],
			              @AccountingPeriod = [PeriodName] 
			         FROM [dbo].[EntityStructureSetup] est WITH(NOLOCK) 
			   INNER JOIN [dbo].[ManagementStructureLevel] msl WITH(NOLOCK) ON est.Level1Id = msl.ID 
			   INNER JOIN [dbo].[AccountingCalendar] acc WITH(NOLOCK) ON msl.LegalEntityId = acc.LegalEntityId AND acc.IsDeleted =0
			    WHERE est.[EntityStructureId] = @CurrentManagementStructureId 
			      AND acc.[MasterCompanyId] = @MasterCompanyId  
			      AND CAST(GETUTCDATE() AS DATE) >= CAST([FromDate] AS DATE) 
			      AND CAST(GETUTCDATE() AS DATE) <= CAST([ToDate] AS DATE)

			IF(EXISTS (SELECT 1 FROM #tmpCodePrefixes WHERE [CodeTypeId] = @CodeTypeId))
			BEGIN 
				SELECT @currentNo = CASE WHEN [CurrentNumber] > 0 THEN CAST([CurrentNumber] AS BIGINT) + 1 ELSE CAST([StartsFrom] AS BIGINT) + 1 END 
				  FROM #tmpCodePrefixes WHERE CodeTypeId = @CodeTypeId
					  	  
				SET @JournalTypeNumber = (SELECT * FROM dbo.udfGenerateCodeNumber(@currentNo,(SELECT CodePrefix FROM #tmpCodePrefixes WHERE CodeTypeId = @CodeTypeId), (SELECT CodeSufix FROM #tmpCodePrefixes WHERE CodeTypeId = @CodeTypeId)))
			END
			ELSE 
			BEGIN
				ROLLBACK TRAN;
			END
			
			IF NOT EXISTS(SELECT [JournalBatchHeaderId] FROM [dbo].[BatchHeader] WITH(NOLOCK) WHERE [JournalTypeId] = @JournalTypeId AND [MasterCompanyId]=@MasterCompanyId AND CAST([EntryDate] AS DATE) = CAST(GETUTCDATE() AS DATE) AND [StatusId]=@StatusId)
			BEGIN
				IF NOT EXISTS(SELECT [JournalBatchHeaderId] FROM [dbo].[BatchHeader] WITH(NOLOCK))
				BEGIN  
					SET @batch ='001'  
					SET @Currentbatch='001' 
				END
				ELSE
				BEGIN 
					SELECT TOP 1 @Currentbatch = CASE WHEN CurrentNumber > 0 THEN CAST(CurrentNumber AS BIGINT) + 1 ELSE  1 END   
					  FROM [dbo].[BatchHeader] WITH(NOLOCK) ORDER BY JournalBatchHeaderId desc  

					IF(CAST(@Currentbatch AS BIGINT) >99)  
					BEGIN
						SET @batch = CASE WHEN CAST(@Currentbatch AS BIGINT) > 99 THEN CAST(@Currentbatch AS VARCHAR(100))  
						                  ELSE CONCAT('00', CAST(@Currentbatch AS VARCHAR(50))) 
									  END   
					END  
					ELSE IF(CAST(@Currentbatch AS BIGINT) >9)  
					BEGIN    
						SET @batch = CASE WHEN CAST(@Currentbatch AS BIGINT) > 99 THEN CAST(@Currentbatch AS VARCHAR(100))  
						                  ELSE CONCAT('0', CAST(@Currentbatch AS VARCHAR(50))) 
									  END   
					END
					ELSE
					BEGIN
					    SET @batch = CASE WHEN CAST(@Currentbatch AS BIGINT) > 99 THEN CAST(@Currentbatch AS VARCHAR(100))  
						                  ELSE CONCAT('00', CAST(@Currentbatch AS VARCHAR(50))) 
									  END     
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
							[StatusId],[StatusName],
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
							[Module])    
				     VALUES    
				           (@batch,
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
							@JournalTypeCode);    
                           
				SELECT @JournalBatchHeaderId = SCOPE_IDENTITY();   
				
				UPDATE [dbo].[BatchHeader] SET [CurrentNumber] = @CurrentNumber WHERE [JournalBatchHeaderId] = @JournalBatchHeaderId;  
			END
			ELSE
			BEGIN 
				SELECT @JournalBatchHeaderId = [JournalBatchHeaderId],@CurrentPeriodId = ISNULL([AccountingPeriodId],0) FROM [dbo].[BatchHeader] WITH(NOLOCK) WHERE [JournalTypeId]= @JournalTypeId AND [StatusId]=@StatusId   
				SELECT @LineNumber = CASE WHEN [LineNumber] > 0 THEN CAST([LineNumber] AS BIGINT) + 1 ELSE  1 END   
				  FROM [dbo].[BatchDetails] WITH(NOLOCK) 
				 WHERE [JournalBatchHeaderId] = @JournalBatchHeaderId 
				 ORDER BY [JournalBatchDetailId] DESC   
          
				IF(@CurrentPeriodId =0)  
				BEGIN  
				   UPDATE [dbo].[BatchHeader] SET [AccountingPeriodId]=@AccountingPeriodId,[AccountingPeriod]=@AccountingPeriod WHERE [JournalBatchHeaderId] = @JournalBatchHeaderId  
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
						@ManagementStructureId, 
						'ManualStockLine', 
			            @LastMSLevel, 
						@AllMSlevels, 
						@MasterCompanyId, 
						@UpdateBy, 
						@UpdateBy, 
						GETUTCDATE(), 
						GETUTCDATE(), 
						1, 
						0,
						@AccountingPeriodId,
						@AccountingPeriod)
		
			SET @JournalBatchDetailId = SCOPE_IDENTITY()

			 -----GOOD RECEIPT NOT INVOICED (GRNI)--------

			SELECT TOP 1 @DistributionSetupId = [ID],
			             @DistributionName = [Name],
						 @JournalTypeId = [JournalTypeId], 
						 @CRDRType = [CRDRType],
			             @GlAccountId = [GlAccountId],
						 @GlAccountNumber = [GlAccountNumber],
						 @GlAccountName = [GlAccountName] 
			        FROM [dbo].[DistributionSetup] WITH(NOLOCK) WHERE UPPER([DistributionSetupCode]) = UPPER('MAST_ASSET_GRNI') 
			         AND [DistributionMasterId] = @DistributionMasterId;
					 
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
						 CASE WHEN @CRDRType = 1 THEN 1 ELSE 0 END,
						 CASE WHEN @CRDRType = 1 THEN @TotalAmount ELSE 0 END,
						 CASE WHEN @CRDRType = 1 THEN 0 ELSE @TotalAmount END,				
				         @ManagementStructureId,
						 'AssetInventory',
						 @LastMSLevel,
						 @AllMSlevels,
						 @MasterCompanyId,
				         @UpdateBy,
						 @UpdateBy,
						 GETUTCDATE(),
						 GETUTCDATE(),
						 1,
						 0)

			SET @CommonBatchDetailId = SCOPE_IDENTITY()

			-----  Accounting MS Entry  -----

			EXEC [dbo].[PROCAddUpdateAccountingBatchMSData] @CommonBatchDetailId,@ManagementStructureId,@MasterCompanyId,@UpdateBy,@AccountMSModuleId,1; 
			
				INSERT INTO [StocklineBatchDetails]
				           ([JournalBatchDetailId],
						    [JournalBatchHeaderId],
							[VendorId],
							[VendorName],
							[ItemMasterId],
							[PartId],
							[PartNumber],
							[PoId],
							[PONum],
							[RoId], 
				            [RONum],
							[StocklineId],
							[StocklineNumber],
							[Consignment],
							[Description],
							[SiteId],
							[Site],
							[WarehouseId],
							[Warehouse],
							[LocationId],
							[Location],
							[BinId],
							[Bin], 
				            [ShelfId], 
							[Shelf], 
							[StockType],
							[CommonJournalBatchDetailId])
				     VALUES(@JournalBatchDetailId, 
					        @JournalBatchHeaderId,
							@VendorId, 
							@VendorName, 
							@ItemMasterId,
							@partId, 
							@MPNName, 
							@PurchaseOrderId,
							@PurchaseOrderNumber, 
							@RepairOrderId, 
				            @RepairOrderNumber, 
							@AssetInventoryId, 
							@InventoryNumber,
							'', 
							@Desc, 
							@SiteId, 
							@Site, 
							@WarehouseId, 
							@Warehouse, 
							@LocationId, 
							@Location, 
							@BinId, 
							@Bin, 
							@ShelfId, 
							@Shelf, 
				            @StockType,
							@CommonBatchDetailId)

			 -----Asset - INVENTORY--------
			 				
			 SELECT TOP 1 @DistributionSetupId = [ID],
			              @DistributionName = [Name],
						  @JournalTypeId = [JournalTypeId], 
						  @CRDRType = [CRDRType]
			              --@GlAccountId = [GlAccountId],
						  --@GlAccountNumber = [GlAccountNumber],
						  --@GlAccountName = GlAccountName 
			         FROM [dbo].[DistributionSetup] WITH(NOLOCK)					
					WHERE UPPER([DistributionSetupCode]) = UPPER('RPOASSETINV')
			          AND [DistributionMasterId] = @DistributionMasterId;

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
						 @StkGlAccountId,
						 @StkGlAccountNumber,
						 @StkGlAccountName,
						 GETUTCDATE(),
						 GETUTCDATE(),
						 @JournalTypeId,
						 @JournalTypename,				
				         1,
						 @TotalAmount,
						 0,
				         @ManagementStructureId,
						 'AssetInventory',
						 @LastMSLevel,
						 @AllMSlevels,
						 @MasterCompanyId,
				         @UpdateBy,
						 @UpdateBy,
						 GETUTCDATE(),
						 GETUTCDATE(),
						 1,
						 0)

			 SET @CommonBatchDetailId = SCOPE_IDENTITY()

			-----  Accounting MS Entry  -----

			EXEC [dbo].[PROCAddUpdateAccountingBatchMSData] @CommonBatchDetailId,@ManagementStructureId,@MasterCompanyId,@UpdateBy,@AccountMSModuleId,1; 
			
				INSERT INTO [StocklineBatchDetails]
				           ([JournalBatchDetailId], 
						    [JournalBatchHeaderId], 
							[VendorId], 
							[VendorName], 
							[ItemMasterId],
							[PartId], 
							[PartNumber], 
							[PoId], 
							[PONum], 
							[RoId], 
				            [RONum], 
							[StocklineId], 
							[StocklineNumber], 
							[Consignment], 
							[Description], 
							[SiteId], 
							[Site], 
							[WarehouseId], 
							[Warehouse], 
							[LocationId], 
							[Location], 
							[BinId], 
							[Bin], 
				            [ShelfId], 
							[Shelf], 
							[StockType],
							[CommonJournalBatchDetailId])
				     VALUES(@JournalBatchDetailId, 
					        @JournalBatchHeaderId, 
							@VendorId, 
							@VendorName, 
							@ItemMasterId, 
							@partId, 
							@MPNName, 
							@PurchaseOrderId, 
							@PurchaseOrderNumber, 
							@RepairOrderId, 
				            @RepairOrderNumber, 
							@AssetInventoryId, 
							@InventoryNumber, 
							'', 
							@Desc,
							@SiteId, 
							@Site, 
							@WarehouseId,
							@Warehouse, 
							@LocationId, 
							@Location, 
							@BinId, 
							@Bin, 
							@ShelfId, 
							@Shelf, 
				            @StockType,
							@CommonBatchDetailId)

			 -----Asset - INVENTORY--------

			SET @TotalDebit = 0;
			SET @TotalCredit = 0;

			SELECT @TotalDebit = SUM([DebitAmount]),
			       @TotalCredit = SUM([CreditAmount]) 
			  FROM [dbo].[CommonBatchDetails] WITH(NOLOCK) 
			 WHERE [JournalBatchDetailId] = @JournalBatchDetailId GROUP BY [JournalBatchDetailId];

			UPDATE [dbo].[BatchDetails] 
			   SET [DebitAmount] = @TotalDebit,
			       [CreditAmount] = @TotalCredit,
				   [UpdatedDate] = GETUTCDATE(),
				   [UpdatedBy] = @UpdateBy
		     WHERE [JournalBatchDetailId] = @JournalBatchDetailId;
		END
		
		SELECT @TotalDebit = SUM([DebitAmount]),
		       @TotalCredit = SUM([CreditAmount]) 
		  FROM [dbo].[BatchDetails] WITH(NOLOCK) 
		 WHERE [JournalBatchHeaderId] = @JournalBatchHeaderId AND [IsDeleted] = 0 

		SET @TotalBalance = (@TotalDebit - @TotalCredit);

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

	END TRY
	BEGIN CATCH
		DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
		-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_PostManualAssetInventoryBatchDetails'               
			  , @ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@AssetInventoryId, '') AS VARCHAR(100))  
              , @ApplicationName VARCHAR(100) = 'PAS'
		-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
              exec spLogException 
                       @DatabaseName           = @DatabaseName
                     , @AdhocComments          = @AdhocComments
                     , @ProcedureParameters    = @ProcedureParameters
                     , @ApplicationName        = @ApplicationName
                     , @ErrorLogID                    = @ErrorLogID OUTPUT ;
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
              RETURN(1);
	END CATCH
END