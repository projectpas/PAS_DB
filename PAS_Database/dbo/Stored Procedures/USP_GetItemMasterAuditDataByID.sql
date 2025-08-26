/*************************************************************           
 ** File:		 [USP_GetItemMasterAuditDataByID]           
 ** Author:		 Divyesh Kathiriya
 ** Description: This Stored Procedure Is Used To Get Item Master History By Id.
 ** Purpose:         
 ** Date:   18-August-2025 
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date				Author				Change Description            
 ** --   -------------		----------------	--------------------------------          
    1    18-August-2025		Divyesh Kathiriya	Created
    
 -- EXEC [USP_GetItemMasterAuditDataByID] @ItemMasterId=96920
**************************************************************/
CREATE   PROCEDURE [DBO].[USP_GetItemMasterAuditDataByID]
@ItemMasterId BIGINT
AS
BEGIN
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	BEGIN TRY	

        SELECT 
              [ItemMasterAuditId],
              [ItemMasterId],
              [ItemTypeId],
              [PartAlternatePartId],
              [ItemGroupId],
              [ItemClassificationId],
              [IsHazardousMaterial],
              [IsExpirationDateAvailable],
              [ExpirationDate],
              [IsReceivedDateAvailable],
              [DaysReceived],
              [IsManufacturingDateAvailable],
              [ManufacturingDays],
              [IsTagDateAvailable],
              [TagDays],
              [IsOpenDateAvailable],
              [OpenDays],
              [IsShippedDateAvailable],
              [ShippedDays],
              [IsOtherDateAvailable],
              [OtherDays],
              [ProvisionId],
              [ManufacturerId],
              [IsDER],
              [NationalStockNumber],
              [IsSchematic],
              [OverhaulHours],
              [RPHours],
              [TestHours],
              [RFQTracking],
              [GLAccountId],
              [PurchaseUnitOfMeasureId],
              [StockUnitOfMeasureId],
              [ConsumeUnitOfMeasureId],
              [LeadTimeDays],
              [ReorderPoint],
              [ReorderQuantiy],
              [MinimumOrderQuantity],
              [PartListPrice],
              [PriorityId],
              [WarningId],
              [Memo],
              [ExportCountryId],
              [ExportValue],
              [ExportCurrencyId],
              [ExportWeight],
              [ExportWeightUnit],
              [ExportSizeLength],
              [ExportSizeWidth],
              [ExportSizeHeight],
              [ExportSizeUnit],
              [ExportClassificationId],
              [PurchaseCurrencyId],
              [SalesIsFixedPrice],
              [SalesCurrencyId],
              [SalesLastSalePriceDate],
              [SalesLastSalesDiscountPercentDate],
              ISNULL([IsActive], 0) AS IsActive,
              [CurrencyId],
              [MasterCompanyId],
              [CreatedBy],
              [UpdatedBy],
              [CreatedDate],
              [UpdatedDate],
              [TurnTimeOverhaulHours],
              [TurnTimeRepairHours],
              [SoldUnitOfMeasureId],
              ISNULL([IsDeleted], 0) AS IsDeleted,
              [ExportUomId],
              [partnumber],
              [PartDescription],
              [isTimeLife],
              [isSerialized],
              [ManagementStructureId],
              [ShelfLife],
              [DiscountPurchasePercent],
              [UnitCost],
              [ListPrice],
              [PriceDate],
              [ItemNonStockClassificationId],
              [StockLevel],
              [ExportECCN],
              [ITARNumber],
              [ShelfLifeAvailable],
              [mfgHours],
              [IsPma],
              [turnTimeMfg],
              [turnTimeBenchTest],
              [IsExportUnspecified],
              [IsExportNONMilitary],
              [IsExportMilitary],
              [IsExportDual],
              [IsOemPNId],
              [MasterPartId],
              [RepairUnitOfMeasureId],
              [RevisedPartId],
              [SiteId],
              [WarehouseId],
              [LocationId],
              [ShelfId],
              [BinId],
              [ItemMasterAssetTypeId],
              [IsHotItem],
              [ExportSizeUnitOfMeasureId],
              [IsAcquiredMethodBuy],
              [IsOEM],
              [RevisedPart],
              [OEMPN],
              [ItemClassificationName],
              [ItemGroup],
              [AssetAcquistionType],
              [ManufacturerName],
              [PurchaseUnitOfMeasure],
              [StockUnitOfMeasure],
              [ConsumeUnitOfMeasure],
              [PurchaseCurrency],
              [SalesCurrency],
              [GLAccount],
              [Priority],
              [SiteName],
              [WarehouseName],
              [LocationName],
              [ShelfName],
              [BinName],
              [CurrentStlNo],
              [MTBUR],
              [NE],
              [NS],
              [OH],
              [REP],
              [SVC],
              [Figure],
              [Item],
              [UNCode],
              [InventoryGLSettingId],
              [GoodsReceivedNotInvoicesGLAccId],
              [WorkInProgressGLAccId],
              [InventoryToBillGLAccId],
              [FinishedGoodsGLAccId],
              [InventoryExchAgreementGLAccId],
              [InventoryReserveGLAccId],
              [COGS_WorkOrderGLAccId],
              [COGS_SalesOrderGLAccId],
              [COGS_QtyVarianceGLAccId],
              [COGS_UnitCostVarianceGLAccId],
              [RevenueMroGLAccId],
              [RevenueSoGLAccId],
              [RevenueExchGLAccId],
              [COGS_ExchSalesOrderGLAccId],
              [GoodsReceivedNotInvoicesGLAccName],
              [WorkInProgressGLAccName],
              [InventoryToBillGLAccName],
              [FinishedGoodsGLAccName],
              [InventoryExchAgreementGLAccName],
              [InventoryReserveGLAccName],
              [COGS_WorkOrderGLAccName],
              [COGS_SalesOrderGLAccName],
              [COGS_QtyVarianceGLAccName],
              [COGS_UnitCostVarianceGLAccName],
              [RevenueMroGLAccName],
              [RevenueSoGLAccName],
              [RevenueExchGLAccName],
              [COGS_ExchSalesOrderGLAccName],
              [QuickBooksReferenceId],
              [IsUpdated],
              [LastSyncDate],
              [SyncToken],
              [WorkOrderFormTypeId]
		FROM [DBO].[ItemMasterAudit] WITH (NOLOCK)
		WHERE [ItemMasterId] = @ItemMasterId
		ORDER BY [ItemMasterAuditId] DESC;	  
	
	END TRY 
	BEGIN CATCH
	
		DECLARE @ErrorLogID INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_GetItemMasterAuditDataByID'
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