/*************************************************************           
 ** File:		 [USP_AddItemMasterGeneralInfo]           
 ** Author:		 Divyesh Kathiriya
 ** Description: This Stored Procedure Is Used To Add ItemMaster.
 ** Purpose:         
 ** Date:   11-September-2025 
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date				Author				Change Description            
 ** --   -------------		----------------	--------------------------------          
    1    11-September-2025		Divyesh Kathiriya	Created	
    
 -- EXEC [USP_AddItemMasterGeneralInfo] 
**************************************************************/
Create   PROCEDURE [DBO].[USP_AddItemMasterGeneralInfo]
@tbl_ItemMasterTableType [DBO].[ItemMasterTableType] READONLY
AS
BEGIN
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	BEGIN TRY
	BEGIN TRANSACTION
		-- Declare variables
		DECLARE @ItemMasterId BIGINT, @MasterPartId BIGINT, @ManufacturerId BIGINT;
		DECLARE @MasterCompanyId INT;
		DECLARE @PartNumber VARCHAR(50), @PartDescription NVARCHAR(max);
		DECLARE @CreatedBy VARCHAR(256), @UpdatedBy VARCHAR(256), @ItemMasterRankingIds VARCHAR(256);
		DECLARE @ManufacturerName VARCHAR(100);
		DECLARE @IsActive BIT, @IsDeleted BIT;
		DECLARE @ItemMasterModuleId INT;	

		SELECT @ItemMasterModuleId = [AccountingModuleId] FROM dbo.[AccountingModule] WITH(NOLOCK) WHERE UPPER([AccountingModuleName]) = 'ITEMMASTER';

		SELECT 
			@PartNumber = [partnumber],
			@PartDescription = [PartDescription],
			@ManufacturerId = [ManufacturerId], 
			@ItemMasterRankingIds = [ItemMasterRankingIds],
			@MasterCompanyId = [MasterCompanyId], 
			@CreatedBy = [CreatedBy],
			@UpdatedBy = [UpdatedBy]			
		FROM @tbl_ItemMasterTableType;
		
		-- Item Master Ranking 
		IF OBJECT_ID(N'tempdb..##tmpitemmasterranking') IS NOT NULL        
		BEGIN        
			DROP TABLE #tmpitemmasterranking    
		END   

		CREATE TABLE #tmpitemmasterranking
		(        
			ItemMasterRankingIds VARCHAR(256) NULL    
		) 

		-- Error Msg
		IF OBJECT_ID(N'tempdb..#tmpmsg') IS NOT NULL        
		BEGIN        
			DROP TABLE #tmpmsg    
		END   

		CREATE TABLE #tmpmsg
		(        
			msg VARCHAR(100) NULL    
		) 
/***************Start Save Item Details***************/	

		IF NOT EXISTS (SELECT 1 FROM [DBO].[ItemMaster] WITH(NOLOCK) WHERE [ManufacturerId] = @ManufacturerId AND [PartNumber] = @PartNumber AND [MasterCompanyId] = @MasterCompanyId)
		BEGIN
			INSERT INTO [DBO].[MasterParts] ([PartNumber], [Description],  [ManufacturerId], [MasterCompanyId], [CreatedBy], [CreatedDate], [UpdatedBy], [UpdatedDate], [IsActive], [IsDeleted])
			VALUES (@PartNumber, @PartDescription, @ManufacturerId, @MasterCompanyId, @CreatedBy, GETUTCDATE(), @UpdatedBy, GETUTCDATE(), 1, 0);

			SET @MasterPartId = SCOPE_IDENTITY();			           
            
			INSERT INTO [DBO].[ItemMaster](				
				[ItemTypeId], [PartAlternatePartId], [ItemGroupId], [ItemClassificationId], [IsHazardousMaterial], [IsExpirationDateAvailable], [ExpirationDate], [IsReceivedDateAvailable], [DaysReceived], [IsManufacturingDateAvailable],
				[ManufacturingDays], [IsTagDateAvailable], [TagDays], [IsOpenDateAvailable], [OpenDays], [IsShippedDateAvailable], [ShippedDays], [IsOtherDateAvailable], [OtherDays], 
				[ManufacturerId], [IsDER], [NationalStockNumber], [IsSchematic], [OverhaulHours], [RPHours], [TestHours], [RFQTracking], [GLAccountId], [PurchaseUnitOfMeasureId],
				[StockUnitOfMeasureId], [ConsumeUnitOfMeasureId], [LeadTimeDays], [ReorderPoint], [ReorderQuantiy], [MinimumOrderQuantity], [PriorityId], [Memo], [ExportSizeUnit], 
				[PurchaseCurrencyId], [SalesCurrencyId], [SalesLastSalePriceDate], [SalesLastSalesDiscountPercentDate], [MasterCompanyId], [CreatedBy], [UpdatedBy],
				[CreatedDate], [UpdatedDate], [IsActive], [IsDeleted], [TurnTimeOverhaulHours], [TurnTimeRepairHours], [PartNumber], [PartDescription], [IsTimeLife],
				[IsSerialized], [ShelfLife], [StockLevel], [ShelfLifeAvailable],[mfgHours], [IsPma], [turnTimeMfg], [turnTimeBenchTest] ,
				[IsOemPNId], [MasterPartId], [RepairUnitOfMeasureId], [RevisedPartId], [SiteId], [WarehouseId], [LocationId], [ShelfId], [BinId], [ItemMasterAssetTypeId],
				[IsHotItem], [IsOEM], [RevisedPart], [OEMPN], [ItemClassificationName], [ItemGroup], [AssetAcquistionType], [ManufacturerName],
				[PurchaseUnitOfMeasure], [StockUnitOfMeasure], [ConsumeUnitOfMeasure], [PurchaseCurrency], [SalesCurrency], [GLAccount], [Priority], [SiteName], [WarehouseName], [LocationName],
				[ShelfName], [BinName], [CurrentStlNo], [MTBUR], [NE], [NS], [OH], [REP], [SVC], [Figure],
				[Item], [UNCode], [InventoryGLSettingId], [GoodsReceivedNotInvoicesGLAccId], [WorkInProgressGLAccId], [InventoryToBillGLAccId], [FinishedGoodsGLAccId], [InventoryExchAgreementGLAccId], [InventoryReserveGLAccId], [COGS_WorkOrderGLAccId],
				[COGS_SalesOrderGLAccId], [COGS_QtyVarianceGLAccId], [COGS_UnitCostVarianceGLAccId], [RevenueMroGLAccId], [RevenueSoGLAccId], [RevenueExchGLAccId], [COGS_ExchSalesOrderGLAccId], [GoodsReceivedNotInvoicesGLAccName], [WorkInProgressGLAccName], [InventoryToBillGLAccName],
				[FinishedGoodsGLAccName], [InventoryExchAgreementGLAccName], [InventoryReserveGLAccName], [COGS_WorkOrderGLAccName], [COGS_SalesOrderGLAccName], [COGS_QtyVarianceGLAccName], [COGS_UnitCostVarianceGLAccName], [RevenueMroGLAccName], [RevenueSoGLAccName], [RevenueExchGLAccName],
				[COGS_ExchSalesOrderGLAccName], [IsUpdated], [WorkOrderFormTypeId])
			SELECT
				[ItemTypeId], [PartAlternatePartId], [ItemGroupId], [ItemClassificationId], [IsHazardousMaterial], [IsExpirationDateAvailable], [ExpirationDate], [IsReceivedDateAvailable], [DaysReceived], [IsManufacturingDateAvailable],
				[ManufacturingDays], [IsTagDateAvailable], [TagDays], [IsOpenDateAvailable], [OpenDays], [IsShippedDateAvailable], [ShippedDays], [IsOtherDateAvailable], [OtherDays], 
				[ManufacturerId], [IsDER], [NationalStockNumber], [IsSchematic], [OverhaulHours], [RPHours], [TestHours], [RFQTracking], [GLAccountId], [PurchaseUnitOfMeasureId],
				[StockUnitOfMeasureId], [ConsumeUnitOfMeasureId], [LeadTimeDays], [ReorderPoint], [ReorderQuantiy], [MinimumOrderQuantity], [PriorityId], [Memo], [ExportSizeUnit], 
				[PurchaseCurrencyId], [SalesCurrencyId], [SalesLastSalePriceDate], [SalesLastSalesDiscountPercentDate], [MasterCompanyId], [CreatedBy], [UpdatedBy],
				GETUTCDATE(), GETUTCDATE(), 1, 0, [TurnTimeOverhaulHours], [TurnTimeRepairHours], [PartNumber], [PartDescription], [IsTimeLife],
				[IsSerialized], [ShelfLife], [StockLevel], [ShelfLifeAvailable], [mfgHours], [IsPma], [turnTimeMfg], [turnTimeBenchTest],
				[IsOemPNId], @MasterPartId, [RepairUnitOfMeasureId], [RevisedPartId], [SiteId], [WarehouseId], [LocationId], [ShelfId], [BinId], [ItemMasterAssetTypeId],
				[IsHotItem], [IsOEM], [RevisedPart], [OEMPN], [ItemClassificationName], [ItemGroup], [AssetAcquistionType], [ManufacturerName],
				[PurchaseUnitOfMeasure], [StockUnitOfMeasure], [ConsumeUnitOfMeasure], [PurchaseCurrency], [SalesCurrency], [GLAccount], [Priority], [SiteName], [WarehouseName], [LocationName],
				[ShelfName], [BinName], [CurrentStlNo], [MTBUR], [NE], [NS], [OH], [REP], [SVC], [Figure],
				[Item], [UNCode], [InventoryGLSettingId], [GoodsReceivedNotInvoicesGLAccId], [WorkInProgressGLAccId], [InventoryToBillGLAccId], [FinishedGoodsGLAccId], [InventoryExchAgreementGLAccId], [InventoryReserveGLAccId], [COGS_WorkOrderGLAccId],
				[COGS_SalesOrderGLAccId], [COGS_QtyVarianceGLAccId], [COGS_UnitCostVarianceGLAccId], [RevenueMroGLAccId], [RevenueSoGLAccId], [RevenueExchGLAccId], [COGS_ExchSalesOrderGLAccId], [GoodsReceivedNotInvoicesGLAccName], [WorkInProgressGLAccName], [InventoryToBillGLAccName],
				[FinishedGoodsGLAccName], [InventoryExchAgreementGLAccName], [InventoryReserveGLAccName], [COGS_WorkOrderGLAccName], [COGS_SalesOrderGLAccName], [COGS_QtyVarianceGLAccName], [COGS_UnitCostVarianceGLAccName], [RevenueMroGLAccName], [RevenueSoGLAccName], [RevenueExchGLAccName],
				[COGS_ExchSalesOrderGLAccName], [IsUpdated], [WorkOrderFormTypeId]
			FROM @tbl_ItemMasterTableType;

			SET @ItemMasterId = SCOPE_IDENTITY();

			-- Insert into ItemMasterRanking
			IF(@ItemMasterRankingIds IS NOT NULL AND @ItemMasterRankingIds <> '' AND @ItemMasterId > 0)
			BEGIN							
				INSERT INTO #tmpitemmasterranking (ItemMasterRankingIds)
				SELECT * FROM STRING_SPLIT(@ItemMasterRankingIds, ',')

				INSERT INTO [DBO].[ItemMasterRanking] (
					[ItemMasterId], [RankingId], [MasterCompanyId], [CreatedBy], [UpdatedBy], [CreatedDate], [UpdatedDate], [IsActive], [IsDeleted])
				SELECT 
					@ItemMasterId, ItemMasterRankingIds, @MasterCompanyId, @CreatedBy, @UpdatedBy, GETUTCDATE(), GETUTCDATE(), 1, 0 
				FROM #tmpitemmasterranking						
			END   

			-- Get Manufacturer Name
			SELECT @ManufacturerName = [Name] FROM [DBO].[Manufacturer] WITH(NOLOCK) WHERE [ManufacturerId] = @ManufacturerId;

			EXEC [DBO].[UpdateItemMasterDetail] @ItemMasterId;				

			EXEC [DBO].[QuickBooks_UpdateModuleCountDetails] @MasterCompanyId, @ItemMasterModuleId; 

		END
		ELSE
		BEGIN
			INSERT INTO #tmpmsg(msg) VALUES ('Duplicate PN for the same manufacturer is not allowed');
		END
		
		
/***************End Save Item Details***************/	

		IF EXISTS (SELECT 1 FROM #tmpmsg)
		BEGIN
			SELECT msg FROM #tmpmsg;			          
		END
		ELSE
		BEGIN			
			SELECT @ItemMasterId AS [ItemMasterId], @ManufacturerName AS [ManufacturerName], @MasterPartId AS [MasterPartId];
		END		
	
	COMMIT  TRANSACTION
	END TRY 
	BEGIN CATCH
	IF @@trancount > 0  
		PRINT 'ROLLBACK'  
		ROLLBACK TRAN;  
		DECLARE @ErrorLogID INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_AddItemMasterGeneralInfo'
			  , @ProcedureParameters VARCHAR(3000) = '@Parameter1 = '''
              , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
		EXEC spLogException @DatabaseName = @DatabaseName
			,@AdhocComments = @AdhocComments
			,@ProcedureParameters = @ProcedureParameters
			,@ApplicationName = @ApplicationName
			,@ErrorLogID = @ErrorLogID OUTPUT;

		RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)

		RETURN (1); 
	END CATCH

END