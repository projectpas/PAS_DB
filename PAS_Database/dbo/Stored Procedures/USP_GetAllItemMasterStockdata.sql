/*************************************************************           
 ** File:   [USP_GetAllItemMasterStockdata]          
 ** Author:   Bhargav Saliya
 ** Description: 
 ** Purpose:         
 ** Date:   02-Sep-2025       
          
 ** RETURN VALUE:           
  
 **************************************************************             
  ** Change History             
 **************************************************************             
    1    02-09-2025    Bhargav Saliya       Created  
	2    01/July/2026			 RAJESH GAMI						[PN-17008] - Merge Non Stock Inventory to ItemMaster : Get only Stock Inventory Data Where IsNonStock = 0
 ** S NO   Date            Author          Change Description              
 ** --   --------         -------          --------------------------------            
--EXEC USP_GetAllItemMasterStockdata @MasterCompanyId = 1
**************************************************************/ 
CREATE   PROCEDURE [dbo].[USP_GetAllItemMasterStockdata]
    @MasterCompanyId INT
AS
BEGIN
    SET NOCOUNT ON;

	DECLARE @ItemMasterStockType INT= 1;

	IF OBJECT_ID('tempdb..#Results') IS NOT NULL
	DROP TABLE #Results

	IF OBJECT_ID('tempdb..#tmpItemManufacturer') IS NOT NULL
	DROP TABLE #tmpItemManufacturer

	IF OBJECT_ID('tempdb..#tmpGLAccount') IS NOT NULL
	DROP TABLE #tmpGLAccount

	IF OBJECT_ID('tempdb..#tmpPriority') IS NOT NULL
	DROP TABLE #tmpPriority

	IF OBJECT_ID('tempdb..#tmpItemClassfication') IS NOT NULL
	DROP TABLE #tmpItemClassfication
	BEGIN TRY
		SELECT 
			im.ItemMasterId,
			im.ItemTypeId,
			im.PartAlternatePartId,
			im.ItemGroupId,
			im.ItemClassificationId,
			ISNULL(im.IsHazardousMaterial,0) AS IsHazardousMaterial,
			ISNULL(im.IsExpirationDateAvailable,0) AS IsExpirationDateAvailable,
			im.ExpirationDate,
			ISNULL(im.IsReceivedDateAvailable,0) AS IsReceivedDateAvailable,
			im.DaysReceived,
			ISNULL(im.IsManufacturingDateAvailable,0) AS IsManufacturingDateAvailable,
			im.ManufacturingDays,
			ISNULL(im.IsTagDateAvailable,0) AS IsTagDateAvailable,
			im.TagDays,
			ISNULL(im.IsOpenDateAvailable,0) AS IsOpenDateAvailable,
			im.OpenDays,
			ISNULL(im.IsShippedDateAvailable,0) AS IsShippedDateAvailable,
			im.ShippedDays,
			ISNULL(im.IsOtherDateAvailable,0) AS IsOtherDateAvailable,
			im.OtherDays,
			im.ProvisionId,
			im.ManufacturerId,
			ISNULL(im.IsDER,0) AS IsDER,
			im.NationalStockNumber,
			ISNULL(im.IsSchematic,0) AS IsSchematic,
			im.OverhaulHours,
			im.RPHours,
			im.TestHours,
			ISNULL(im.RFQTracking,0) AS RFQTracking,
			im.GLAccountId,
			im.PurchaseUnitOfMeasureId,
			im.StockUnitOfMeasureId,
			im.ConsumeUnitOfMeasureId,
			im.LeadTimeDays,
			im.ReorderPoint,
			im.ReorderQuantiy,
			im.MinimumOrderQuantity,
			im.PartListPrice,
			im.PriorityId,
			im.WarningId,
			im.Memo,
			im.ExportCountryId,
			im.ExportValue,
			im.ExportCurrencyId,
			im.ExportWeight,
			im.ExportWeightUnit,
			im.ExportSizeLength,
			im.ExportSizeWidth,
			im.ExportSizeHeight,
			im.ExportSizeUnit,
			im.ExportClassificationId,
			im.PurchaseCurrencyId,
			ISNULL(im.SalesIsFixedPrice,0) AS SalesIsFixedPrice,
			im.SalesCurrencyId,
			im.SalesLastSalePriceDate,
			im.SalesLastSalesDiscountPercentDate,
			im.IsActive,
			im.CurrencyId,
			im.MasterCompanyId,
			im.CreatedBy,
			im.UpdatedBy,
			im.CreatedDate,
			im.UpdatedDate,
			im.TurnTimeOverhaulHours,
			im.TurnTimeRepairHours,
			im.SoldUnitOfMeasureId,
			ISNULL(im.IsDeleted,0) AS IsDeleted,
			im.ExportUomId,
			im.partnumber,
			im.PartDescription,
			im.isTimeLife,
			im.isSerialized,
			im.ManagementStructureId,
			im.ShelfLife,
			im.DiscountPurchasePercent,
			im.UnitCost,
			im.ListPrice,
			im.PriceDate,
			im.ItemNonStockClassificationId,
			im.StockLevel,
			im.ExportECCN,
			im.ITARNumber,
			im.ShelfLifeAvailable,
			im.mfgHours,
			im.IsPma,
			im.turnTimeMfg,
			im.turnTimeBenchTest,
			im.IsExportUnspecified,
			im.IsExportNONMilitary,
			im.IsExportMilitary,
			im.IsExportDual,
			im.IsOemPNId,
			im.MasterPartId,
			im.RepairUnitOfMeasureId,
			im.RevisedPartId,
			im.SiteId,
			im.WarehouseId,
			im.LocationId,
			im.ShelfId,
			im.BinId,
			im.ItemMasterAssetTypeId,
			im.IsHotItem,
			im.ExportSizeUnitOfMeasureId,
			im.IsAcquiredMethodBuy,
			im.IsOEM,
			im.RevisedPart,
			im.OEMPN,
			im.ItemClassificationName,
			im.ItemGroup,
			im.AssetAcquistionType,
			im.ManufacturerName,
			im.PurchaseUnitOfMeasure,
			im.StockUnitOfMeasure,
			im.ConsumeUnitOfMeasure,
			im.PurchaseCurrency,
			im.SalesCurrency,
			im.GLAccount,
			im.Priority,
			im.SiteName,
			im.WarehouseName,
			im.LocationName,
			im.ShelfName,
			im.BinName,
			im.CurrentStlNo,
			im.MTBUR,
			im.NE,
			im.NS,
			im.OH,
			im.REP,
			im.SVC,
			im.Figure,
			im.Item,
			im.UNCode,
			im.InventoryGLSettingId,
			im.GoodsReceivedNotInvoicesGLAccId,
			im.WorkInProgressGLAccId,
			im.InventoryToBillGLAccId,
			im.FinishedGoodsGLAccId,
			im.InventoryExchAgreementGLAccId,
			im.InventoryReserveGLAccId,
			im.COGS_WorkOrderGLAccId,
			im.COGS_SalesOrderGLAccId,
			im.COGS_QtyVarianceGLAccId,
			im.COGS_UnitCostVarianceGLAccId,
			im.RevenueMroGLAccId,
			im.RevenueSoGLAccId,
			im.RevenueExchGLAccId,
			im.COGS_ExchSalesOrderGLAccId,
			im.GoodsReceivedNotInvoicesGLAccName,
			im.WorkInProgressGLAccName,
			im.InventoryToBillGLAccName,
			im.FinishedGoodsGLAccName,
			im.InventoryExchAgreementGLAccName,
			im.InventoryReserveGLAccName,
			im.COGS_WorkOrderGLAccName,
			im.COGS_SalesOrderGLAccName,
			im.COGS_QtyVarianceGLAccName,
			im.COGS_UnitCostVarianceGLAccName,
			im.RevenueMroGLAccName,
			im.RevenueSoGLAccName,
			im.RevenueExchGLAccName,
			im.COGS_ExchSalesOrderGLAccName,
			im.QuickBooksReferenceId,
			im.IsUpdated,
			im.LastSyncDate,
			im.SyncToken,
			im.WorkOrderFormTypeId
		into #Results
		FROM dbo.ItemMaster im WITH (NOLOCK)
		WHERE @ItemMasterStockType = im.ItemTypeId AND ISNULL(im.IsDeleted,0) = 0 AND im.MasterCompanyId = @MasterCompanyId  

		 AND ISNULL(im.IsNonStock,0) = 0
		SELECT TOP 1
			M.ManufacturerId
			,M.Name
			,M.Comments
			,M.MasterCompanyId
			,M.CreatedBy
			,M.UpdatedBy
			,M.CreatedDate
			,M.UpdatedDate
			,ISNULL(M.IsActive,0) AS IsActive
			,ISNULL(M.IsDeleted,0) AS IsDeleted 	
		into #tmpItemManufacturer
		FROM dbo.Manufacturer M WITH (NOLOCK)
		WHERE ISNULL(M.IsDeleted,0) = 0 AND M.MasterCompanyId = @MasterCompanyId  

		select TOP 1
			G.GLAccountId
			,G.OldAccountCode
			,G.AccountCode
			,G.AccountName
			,G.AccountDescription
			,ISNULL(G.AllowManualJE,0) AS AllowManualJE
			,G.GLAccountTypeId
			,G.GLClassFlowClassificationId
			,G.MasterCompanyId
			,G.CreatedBy
			,G.UpdatedBy
			,G.CreatedDate
			,G.UpdatedDate
			,ISNULL(G.IsActive,0) AS IsActive
			,ISNULL(G.IsDeleted,0) AS IsDeleted 
			,G.POROCategoryId
			,G.GLAccountNodeId
			,G.LedgerId
			,G.LedgerName
			,ISNULL(G.InterCompany,0) AS InterCompany
			,G.Category1099Id
			,G.Threshold
			,ISNULL(G.IsManualJEReference,0) AS IsManualJEReference
			,G.ReferenceTypeId
			,G.SubLedgerId
			,G.QuickBooksReferenceId
			,ISNULL(G.IsUpdated,0) AS IsUpdated
			,G.LastSyncDate
			,G.SyncToken
		INTO #tmpGLAccount
		FROM dbo.GLAccount G WITH (NOLOCK)
		WHERE ISNULL(G.IsDeleted,0) = 0 AND G.MasterCompanyId = @MasterCompanyId  

		SELECT TOP 1
			P.PriorityId
			,P.Description
			,P.Memo
			,P.MasterCompanyId
			,P.CreatedBy
			,P.UpdatedBy
			,P.CreatedDate
			,P.UpdatedDate
			,ISNULL(P.IsActive,0) AS IsActive
			,ISNULL(P.IsDeleted,0) AS IsDeleted
		INTO #tmpPriority
		FROM dbo.[Priority]  P WITH (NOLOCK)
		WHERE ISNULL(P.IsDeleted,0) = 0 AND P.MasterCompanyId = @MasterCompanyId 

		SELECT TOP 1
			I.ItemClassificationId
			,I.ItemClassificationCode
			,I.Description
			,I.Memo
			,I.MastercompanyId
			,I.CreatedBy
			,I.UpdatedBy
			,I.CreatedDate
			,I.UpdatedDate
			,ISNULL(I.IsActive,0) AS IsActive
			,ISNULL(I.IsDeleted,0) AS IsDeleted
			,I.ItemTypeId
		INTO #tmpItemClassfication
		FROM dbo.[ItemClassification]  I WITH (NOLOCK)
		WHERE ISNULL(I.IsDeleted,0) = 0 AND I.MasterCompanyId = @MasterCompanyId 

		SELECT * FROM #Results
		SELECT * FROM #tmpItemManufacturer
		SELECT * FROM #tmpGLAccount
		SELECT * FROM #tmpPriority
		SELECT * FROM #tmpItemClassfication
	END TRY
	BEGIN CATCH      
				IF @@trancount > 0
					PRINT 'ROLLBACK'
					DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

	-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
				  , @AdhocComments     VARCHAR(150)    = 'USP_GetAllItemMasterStockdata' 
				  , @ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@MasterCompanyId, '') as varchar(100))   
				  , @ApplicationName VARCHAR(100) = 'PAS'
	-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------

				  exec spLogException 
						   @DatabaseName			= @DatabaseName
						 , @AdhocComments			= @AdhocComments
						 , @ProcedureParameters		= @ProcedureParameters
						 , @ApplicationName			= @ApplicationName
						 , @ErrorLogID              = @ErrorLogID OUTPUT ;
				  RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
				  RETURN
	END CATCH
END