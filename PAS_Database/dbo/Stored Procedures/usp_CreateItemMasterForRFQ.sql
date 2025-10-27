/***************************************************************  
 ** File:  [usp_CreateItemMasterForRFQ]            
 ** Author:   Devendra Shekh
 ** Description: create the ItemMaster for the RFQ
 ** Date:  27-Oct-2025
 ** Change History             
 **************************************************************             
 ** PR   Date				Author  				Change Description              
 ** --   --------			-------				--------------------------------            
    1    27-Oct-2025		Devendra Shekh			Created
**************************************************************/
CREATE   PROCEDURE [dbo].[usp_CreateItemMasterForRFQ]
    @PartNumber VARCHAR(250),
    @PartDescription VARCHAR(250),
    @MasterCompanyId INT,
    @EmployeeId BIGINT,
	@UserName VARCHAR(256),
	@ItemMasterId BIGINT OUTPUT
AS
BEGIN
SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

	BEGIN TRY

		DECLARE @ManufacturerId BIGINT, @ItemTypeId INT, @ItemGroupId BIGINT, @ItemClassificationId BIGINT, @PriorityId BIGINT, @UnitOfMeasureId BIGINT, @FunctionalCurrencyId BIGINT, @ReportingCurrencyId BIGINT,
				@SiteId BIGINT, @PartSourceVal AS VARCHAR(200) = 'OEM', @AssetAcquisitionTypeId BIGINT, @GlAccountId BIGINT, @MasterPartId BIGINT;
		DECLARE @WorkOrderFormTypeId INT = 3;
		DECLARE @ItemMasterModuleId INT;	

        IF OBJECT_ID(N'tempdb..#tmp_PartNumber') IS NOT NULL        
		BEGIN        
			DROP TABLE #tmp_PartNumber    
		END 

		CREATE TABLE #tmp_PartNumber
		(
			[Id] INT IDENTITY(1,1) NOT NULL,
			[PartNumber] VARCHAR(250),
			[PartDescription] VARCHAR(250),
			[MasterCompanyId] INT,
			[EmployeeId] BIGINT,
		)

		INSERT INTO #tmp_PartNumber ([PartNumber], [PartDescription], [MasterCompanyId], [EmployeeId]) VALUES(@PartNumber, ISNULL(@PartDescription, @PartNumber), @MasterCompanyId, @EmployeeId);

		SELECT @ItemMasterModuleId = [AccountingModuleId] FROM dbo.[AccountingModule] WITH(NOLOCK) WHERE UPPER([AccountingModuleName]) = 'ITEMMASTER';
		SELECT @ItemTypeId = [ItemTypeId] FROM [dbo].[ItemType] WITH(NOLOCK) WHERE [Description] = 'STOCK';
		SELECT TOP 1 @ItemGroupId = [ItemGroupId] FROM [dbo].[ItemGroup] WITH(NOLOCK) WHERE (TRIM([ItemGroupCode]) = 'NA' OR TRIM([ItemGroupCode]) = 'N/A') AND [MasterCompanyId] = @MasterCompanyId;
		SELECT TOP 1 @ItemClassificationId = [ItemClassificationId] FROM [dbo].[ItemClassification] WITH(NOLOCK) WHERE (TRIM([ItemClassificationCode]) = 'NA' OR TRIM([ItemClassificationCode]) = 'N/A') AND [MastercompanyId] = @MasterCompanyId AND [ItemTypeId] = @ItemTypeId;
		SELECT TOP 1 @ManufacturerId = [ManufacturerId] FROM [dbo].[Manufacturer] WITH(NOLOCK) WHERE (TRIM([Name]) = 'NA' OR TRIM([Name]) = 'N/A') AND [MasterCompanyId] = @MasterCompanyId;
		SELECT @PriorityId = [PriorityId] FROM [dbo].[Priority] WITH(NOLOCK) WHERE [Description] = 'ROUTINE' AND [MasterCompanyId] = @MasterCompanyId;
		SELECT TOP 1 @AssetAcquisitionTypeId = [AssetAcquisitionTypeId] FROM [dbo].[AssetAcquisitionType] WITH(NOLOCK) WHERE (TRIM([Code]) = 'NA' OR TRIM([Code]) = 'N/A') AND [MasterCompanyId] = @MasterCompanyId;
		SELECT TOP 1 @GlAccountId = [GLAccountId] FROM [dbo].[GLAccount] WITH(NOLOCK) WHERE [MasterCompanyId] = @MasterCompanyId;
		SELECT TOP 1 @MasterPartId = [MasterPartId] FROM [dbo].[MasterParts] WITH(NOLOCK) WHERE [MasterCompanyId] = @MasterCompanyId;
		SELECT TOP 1 @UnitOfMeasureId = [UnitOfMeasureId] FROM [dbo].[ItemMasterSettings] WITH(NOLOCK) WHERE [MasterCompanyId] = @MasterCompanyId;
		SELECT TOP 1 @FunctionalCurrencyId = LE.FunctionalCurrencyId, @ReportingCurrencyId = LE.ReportingCurrencyId, @SiteId = ISNULL(ST.SiteId, 0)
			FROM [dbo].[Employee] EM WITH(NOLOCK)
			LEFT JOIN [dbo].[LegalEntity] LE WITH(NOLOCK) ON EM.LegalEntityId = LE.LegalEntityId
			LEFT JOIN [dbo].[Site] ST WITH(NOLOCK) ON LE.LegalEntityId = ST.LegalEntityId AND ST.IsDefault = 1
			WHERE EM.EmployeeId = @EmployeeId AND EM.MasterCompanyId = @MasterCompanyId;

		INSERT INTO [DBO].[ItemMaster] (
			[ItemTypeId], [PartAlternatePartId], [ItemGroupId], [ItemClassificationId], [IsHazardousMaterial], [IsExpirationDateAvailable], [ExpirationDate], [IsReceivedDateAvailable], [DaysReceived], [IsManufacturingDateAvailable],
			[ManufacturingDays], [IsTagDateAvailable], [TagDays], [IsOpenDateAvailable], [OpenDays], [IsShippedDateAvailable], [ShippedDays], [IsOtherDateAvailable], [OtherDays],
			[ManufacturerId], [IsDER], [NationalStockNumber], [IsSchematic], [OverhaulHours], [RPHours], [TestHours], [RFQTracking], [GLAccountId], [PurchaseUnitOfMeasureId],
			[StockUnitOfMeasureId], [ConsumeUnitOfMeasureId], [LeadTimeDays], [ReorderPoint], [ReorderQuantiy], [MinimumOrderQuantity], [PriorityId], [Memo], [ExportSizeUnit],
			[PurchaseCurrencyId], [SalesCurrencyId], [SalesLastSalePriceDate], [SalesLastSalesDiscountPercentDate], [MasterCompanyId], [CreatedBy], [UpdatedBy],
			[CreatedDate], [UpdatedDate], [IsActive], [IsDeleted], [TurnTimeOverhaulHours], [TurnTimeRepairHours], [PartNumber], [PartDescription], [IsTimeLife],
			[IsSerialized], [ShelfLife], [StockLevel], [ShelfLifeAvailable],[mfgHours], [IsPma], [turnTimeMfg], [turnTimeBenchTest],
			[IsOemPNId], [MasterPartId], [RepairUnitOfMeasureId], [RevisedPartId], [SiteId], [WarehouseId], [LocationId], [ShelfId], [BinId], [ItemMasterAssetTypeId],
			[IsHotItem], [IsOEM], [RevisedPart], [OEMPN], [ItemClassificationName], [ItemGroup], [AssetAcquistionType], [ManufacturerName],
			[PurchaseUnitOfMeasure], [StockUnitOfMeasure], [ConsumeUnitOfMeasure], [PurchaseCurrency], [SalesCurrency], [GLAccount], [Priority], [SiteName], [WarehouseName], [LocationName],
			[ShelfName], [BinName], [CurrentStlNo], [MTBUR], [NE], [NS], [OH], [REP], [SVC], [Figure],
			[Item], [UNCode], [InventoryGLSettingId], [GoodsReceivedNotInvoicesGLAccId], [WorkInProgressGLAccId], [InventoryToBillGLAccId], [FinishedGoodsGLAccId], [InventoryExchAgreementGLAccId], [InventoryReserveGLAccId], [COGS_WorkOrderGLAccId],
			[COGS_SalesOrderGLAccId], [COGS_QtyVarianceGLAccId], [COGS_UnitCostVarianceGLAccId], [RevenueMroGLAccId], [RevenueSoGLAccId], [RevenueExchGLAccId], [COGS_ExchSalesOrderGLAccId], [GoodsReceivedNotInvoicesGLAccName], [WorkInProgressGLAccName], [InventoryToBillGLAccName],
			[FinishedGoodsGLAccName], [InventoryExchAgreementGLAccName], [InventoryReserveGLAccName], [COGS_WorkOrderGLAccName], [COGS_SalesOrderGLAccName], [COGS_QtyVarianceGLAccName], [COGS_UnitCostVarianceGLAccName], [RevenueMroGLAccName], [RevenueSoGLAccName], [RevenueExchGLAccName],
			[COGS_ExchSalesOrderGLAccName], [IsUpdated], [WorkOrderFormTypeId]
		)
		SELECT
			@ItemTypeId, NULL, @ItemGroupId, @ItemClassificationId, 0, 0, NULL, 0, 0, 0,
			0, 0, 0, 0, 0, 0, 0, 0, 0,
			@ManufacturerId, 0, NULL, 0, 0, 0, 0, 0, @GlAccountId, @UnitOfMeasureId,
			@UnitOfMeasureId, @UnitOfMeasureId, 0, 0, 0, 0, @PriorityId, NULL, NULL,
			@FunctionalCurrencyId, @ReportingCurrencyId, GETUTCDATE(), GETUTCDATE(), @MasterCompanyId, @UserName, @UserName,
			GETUTCDATE(), GETUTCDATE(), 1, 0, 0, 0, TMP.[PartNumber], TMP.[PartDescription], 0,
			0, 0, 0, 0, 0, 0, 0, 0,
			NULL, @MasterPartId, NULL, NULL, @SiteId, NULL, NULL, NULL, NULL, @AssetAcquisitionTypeId,
			0, 1, NULL, NULL, NULL, NULL, NULL, NULL,
			NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,
			NULL, NULL, 0, 0, 0, 0, 0, 0, 0, NULL,
			NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,
			NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,
			NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,
			NULL, NULL, @WorkOrderFormTypeId
		FROM #tmp_PartNumber TMP;

		SET @ItemMasterId = SCOPE_IDENTITY();

		EXEC [DBO].[usp_UpdateItemMasterWithGLAccountNames] @ItemMasterId, @PartSourceVal, @MasterCompanyId;

		EXEC [DBO].[UpdateItemMasterDetail] @ItemMasterId;				

		EXEC [DBO].[QuickBooks_UpdateModuleCountDetails] @MasterCompanyId, @ItemMasterModuleId; 
		
	END TRY
	BEGIN CATCH    
		DECLARE @ErrorLogID int,    
			@DatabaseName varchar(100) = DB_NAME()    
		-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------    
			,@AdhocComments varchar(150) = 'usp_CreateItemMasterForRFQ'    
			,@ProcedureParameters varchar(3000) = '@MasterCompanyId = ''' + CAST(ISNULL(@MasterCompanyId, '') AS varchar(100))   
			,@ApplicationName varchar(100) = 'PAS'    
		-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------    
		EXEC spLogException @DatabaseName = @DatabaseName,    
			@AdhocComments = @AdhocComments,    
			@ProcedureParameters = @ProcedureParameters,    
			@ApplicationName = @ApplicationName,    
			@ErrorLogID = @ErrorLogID OUTPUT;    
		RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)    
	END CATCH    
END