/*************************************************************           
 ** File:   [USP_GetItemMasterDetailById]           
 ** Author: Rajesh Gami
 ** Description: This stored procedure is used to Get Item Master detail by Id
 ** Date:   28/Jan/2025
 ** PARAMETERS:           
 ** RETURN VALUE:
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date			Author  			Change Description            
 ** --   --------		-------				---------------------------     
    1    28/Jan/2025	Rajesh Gami			Created
    2    25/Mar/2025	Devendra Shekh		added new field: WorkOrderFormTypeId
	3    02/Apr/2025	Moin Bloch   		added new field: OemPN
	4	 28-Aug-2025	Bhargav saliya		added new field Ranking
	5	 22-Sep-2025	Divyesh Kathiriya   added new field: IsHotItem
	6    27/11/2025  Bhargav Saliya	  Modified(Get GL accound code and name from the GLAcount Table).
**************************************************************
 EXEC USP_GetItemMasterDetailById 96978
**************************************************************/
CREATE     PROCEDURE [dbo].[USP_GetItemMasterDetailById] 
@ItemMasterId bigint =0
AS
BEGIN
  SET NOCOUNT ON;
  SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
  BEGIN TRY
  BEGIN TRANSACTION
	BEGIN
		IF (@ItemMasterId >0)
		BEGIN
			WITH CTE_IntegrationPortal AS (
				SELECT
					iM.ItemMasterId,
					STRING_AGG(CAST(R.[Description] AS NVARCHAR(MAX)), ',') AS Ranking,
					STRING_AGG(mp.RankingId, ',') AS RankingIds
				FROM dbo.ItemMaster iM WITH(NOLOCK)
				left JOIN dbo.ItemMasterRanking mp WITH(NOLOCK) ON iM.ItemMasterId = mp.ItemMasterId
				left JOIN dbo.Ranking R WITH(NOLOCK) ON mp.RankingId = R.RankingId
				WHERE mp.RankingId IS NOT NULL GROUP BY iM.ItemMasterId
			),
		   -- WITH CTE_IntegrationPortal AS (
					--	SELECT
					--		iM.ItemMasterId,
					--		STRING_AGG(CAST(ip.[Description] AS NVARCHAR(MAX)), ',') AS integrationPortal,
					--		STRING_AGG(mp.IntegrationPortalId, ',') AS IntegrationPortalStringIds
					--	FROM dbo.ItemMaster iM WITH(NOLOCK)
					--	LEFT JOIN dbo.ItemMasterIntegrationPortal mp WITH(NOLOCK) ON iM.ItemMasterId = mp.ItemMasterId
					--	LEFT JOIN dbo.IntegrationPortal ip WITH(NOLOCK) ON mp.IntegrationPortalId = ip.IntegrationPortalId
					--	WHERE mp.IntegrationPortalId IS NOT NULL GROUP BY iM.ItemMasterId
					--),
			CTE_InventoryGLSetting AS (
					SELECT
						gl.InventoryGLSettingId,
						gl.StockInventoryName
					FROM dbo.InventoryGLSetting  gl WITH(NOLOCK)
					)

					SELECT
						iM.ItemMasterId,
						iM.PartNumber,
						iM.ItemTypeId,
						iM.PartDescription,
						iM.TurnTimeOverhaulHours,
						iM.TurnTimeRepairHours,
						iM.IsSerialized,
						iM.ItemGroupId,
						iM.ItemClassificationId,
						iM.IsHazardousMaterial,
						iM.IsExpirationDateAvailable,
						iM.ExpirationDate,
						iM.IsReceivedDateAvailable,
						iM.DaysReceived,
						iM.IsManufacturingDateAvailable,
						iM.ManufacturingDays,
						iM.IsTagDateAvailable,
						iM.TagDays,
						iM.IsOpenDateAvailable,
						iM.OpenDays,
						iM.IsShippedDateAvailable,
						iM.ShippedDays,
						iM.IsOtherDateAvailable,
						iM.OtherDays,
						iM.ShelfLife,
						iM.ManufacturerId,
						iM.SalesLastSalePriceDate,
						iM.SalesLastSalesDiscountPercentDate,
						iM.IsDER,
						iM.NationalStockNumber,
						iM.IsSchematic,
						iM.OverhaulHours,
						iM.RPHours,
						iM.TestHours,
						iM.RFQTracking,
						iM.GLAccountId,
						iM.PurchaseUnitOfMeasureId,
						iM.StockUnitOfMeasureId,
						iM.ConsumeUnitOfMeasureId,
						iM.LeadTimeDays,
						iM.ReorderQuantiy,
						iM.ReorderPoint,
						iM.MinimumOrderQuantity,
						iM.PriorityId,
						iM.Memo,
						iM.ExportSizeUnit,
						iM.PurchaseCurrencyId,
						iM.SalesCurrencyId,
						COALESCE(iM.SalesCurrency, '') AS SalesCurrency,
						COALESCE(iM.PurchaseCurrency, '') AS PurchaseCurrency,
						iM.MasterCompanyId,
						iM.IsTimeLife,
						iM.StockLevel,
						iM.ShelfLifeAvailable,
						iM.IsPma,
						iM.mfgHours,
						iM.turnTimeMfg,
						iM.turnTimeBenchTest,
						ISNULL(iM.RevisedPartId,0)RevisedPartId,
						ISNULL(iM.RevisedPart,'')RevisedPart,
						iM.SiteId,
						iM.WarehouseId,
						iM.LocationId,
						iM.ShelfId,
						iM.BinId,
						iM.ItemMasterAssetTypeId,
						COALESCE(iM.ManufacturerName, '') AS ManufacturerName,
						COALESCE(iM.SiteName, '') AS SiteName,
						COALESCE(iM.WarehouseName, '') AS WarehouseName,
						COALESCE(iM.LocationName, '') AS LocationName,
						COALESCE(iM.ShelfName, '') AS ShelfName,
						COALESCE(iM.BinName, '') AS BinName,
						itp.Ranking AS integrationPortal,
								itp.RankingIds AS IntegrationPortalStringIds,
						COALESCE(iM.Priority, '') AS priority,
						COALESCE(iM.ItemClassificationName, '') AS ItemClassification,
						COALESCE(iM.ItemGroup, '') AS itemGroup,
						COALESCE(iM.AssetAcquistionType, '') AS assetAcquistionType,
						COALESCE(iM.PurchaseUnitOfMeasure, '') AS purchaseUnitOfMeasure,
						COALESCE(iM.ConsumeUnitOfMeasure, '') AS consumeUnitOfMeasure,
						COALESCE(iM.StockUnitOfMeasure, '') AS stockUnitOfMeasure,
						(CASE WHEN ISNULL(G.[AccountCode], '') = '' THEN ISNULL(G.[AccountName], '') ELSE ISNULL(G.[AccountCode], '') + ' - ' + ISNULL(G.[AccountName], '') END) AS [glAccount],
						its.StockInventoryName AS inventoryGLSettingName,
						(CASE WHEN ISNULL(G2.[AccountCode], '') = '' THEN ISNULL(G2.[AccountName], '') ELSE ISNULL(G2.[AccountCode], '') + ' - ' + ISNULL(G2.[AccountName], '') END) AS [workInProgressGLAccName],
						(CASE WHEN ISNULL(G3.[AccountCode], '') = '' THEN ISNULL(G3.[AccountName], '') ELSE ISNULL(G3.[AccountCode], '') + ' - ' + ISNULL(G3.[AccountName], '') END) AS [inventoryToBillGLAccName],
						(CASE WHEN ISNULL(G4.[AccountCode], '') = '' THEN ISNULL(G4.[AccountName], '') ELSE ISNULL(G4.[AccountCode], '') + ' - ' + ISNULL(G4.[AccountName], '') END) AS [finishedGoodsGLAccName],
						(CASE WHEN ISNULL(G5.[AccountCode], '') = '' THEN ISNULL(G5.[AccountName], '') ELSE ISNULL(G5.[AccountCode], '') + ' - ' + ISNULL(G5.[AccountName], '') END) AS [inventoryExchAgreementGLAccName],
						(CASE WHEN ISNULL(G6.[AccountCode], '') = '' THEN ISNULL(G6.[AccountName], '') ELSE ISNULL(G6.[AccountCode], '') + ' - ' + ISNULL(G6.[AccountName], '') END) AS [inventoryReserveGLAccName],
						(CASE WHEN ISNULL(G7.[AccountCode], '') = '' THEN ISNULL(G7.[AccountName], '') ELSE ISNULL(G7.[AccountCode], '') + ' - ' + ISNULL(G7.[AccountName], '') END) AS [cogS_WorkOrderGLAccName],
						(CASE WHEN ISNULL(G8.[AccountCode], '') = '' THEN ISNULL(G8.[AccountName], '') ELSE ISNULL(G8.[AccountCode], '') + ' - ' + ISNULL(G8.[AccountName], '') END) AS [cogS_SalesOrderGLAccName],
						(CASE WHEN ISNULL(G14.[AccountCode], '') = '' THEN ISNULL(G14.[AccountName], '') ELSE ISNULL(G14.[AccountCode], '') + ' - ' + ISNULL(G14.[AccountName], '') END) AS [cogS_ExchSalesOrderGLAccName],
						(CASE WHEN ISNULL(G9.[AccountCode], '') = '' THEN ISNULL(G9.[AccountName], '') ELSE ISNULL(G9.[AccountCode], '') + ' - ' + ISNULL(G9.[AccountName], '') END) AS [cogS_QtyVarianceGLAccName],
						(CASE WHEN ISNULL(G10.[AccountCode], '') = '' THEN ISNULL(G10.[AccountName], '') ELSE ISNULL(G10.[AccountCode], '') + ' - ' + ISNULL(G10.[AccountName], '') END) AS [cogS_UnitCostVarianceGLAccName],
						(CASE WHEN ISNULL(G11.[AccountCode], '') = '' THEN ISNULL(G11.[AccountName], '') ELSE ISNULL(G11.[AccountCode], '') + ' - ' + ISNULL(G11.[AccountName], '') END) AS [revenueMroGLAccName],
						(CASE WHEN ISNULL(G12.[AccountCode], '') = '' THEN ISNULL(G12.[AccountName], '') ELSE ISNULL(G12.[AccountCode], '') + ' - ' + ISNULL(G12.[AccountName], '') END) AS [revenueSoGLAccName],
						(CASE WHEN ISNULL(G13.[AccountCode], '') = '' THEN ISNULL(G13.[AccountName], '') ELSE ISNULL(G13.[AccountCode], '') + ' - ' + ISNULL(G13.[AccountName], '') END) AS [revenueExchGLAccName],
						iM.IsOemPNId,
						imst.PartNumber AS [OemPN],
						iM.IsDeleted,
						iM.IsActive,
						iM.IsOEM,
						iM.MTBUR,
						iM.NE,
						iM.NS,
						iM.OH,
						iM.REP,
						iM.SVC,
						iM.Figure,
						iM.Item,
						iM.UNCode,
						iM.InventoryGLSettingId,
						iM.GoodsReceivedNotInvoicesGLAccId,
						iM.WorkInProgressGLAccId,
						iM.InventoryToBillGLAccId,
						iM.FinishedGoodsGLAccId,
						iM.InventoryExchAgreementGLAccId,
						iM.InventoryReserveGLAccId,
						iM.COGS_WorkOrderGLAccId,
						iM.COGS_SalesOrderGLAccId,
						iM.COGS_ExchSalesOrderGLAccId,
						iM.COGS_QtyVarianceGLAccId,
						iM.COGS_UnitCostVarianceGLAccId,
						iM.RevenueMroGLAccId,
						iM.RevenueSoGLAccId,
						iM.RevenueExchGLAccId,
						--COALESCE(iM.GoodsReceivedNotInvoicesGLAccName, '') AS GoodsReceivedNotInvoicesGLAccName,
						(CASE WHEN ISNULL(G1.[AccountCode], '') = '' THEN ISNULL(G1.[AccountName], '') ELSE ISNULL(G1.[AccountCode], '') + ' - ' + ISNULL(G1.[AccountName], '') END) AS [GoodsReceivedNotInvoicesGLAccName],
						iM.WorkOrderFormTypeId,
						ISNULL(iM.IsHotItem,0) AS IsHotItem
					FROM dbo.ItemMaster iM WITH(NOLOCK)
					LEFT JOIN CTE_IntegrationPortal itp ON iM.ItemMasterId = itp.ItemMasterId
					LEFT JOIN CTE_InventoryGLSetting its ON iM.InventoryGLSettingId = its.InventoryGLSettingId
					LEFT JOIN dbo.ItemMaster imst WITH(NOLOCK) ON iM.IsOemPNId = imst.ItemMasterId
					LEFT JOIN [dbo].[GLAccount] G  WITH (NOLOCK) ON G.[GLaccountId] = iM.[GLaccountId]
					LEFT JOIN [dbo].[GLAccount] G1  WITH (NOLOCK) ON G1.[GLaccountId] = iM.[GoodsReceivedNotInvoicesGLAccId]
					LEFT JOIN [dbo].[GLAccount] G2  WITH (NOLOCK) ON G2.[GLaccountId] = iM.[WorkInProgressGLAccId]
					LEFT JOIN [dbo].[GLAccount] G3  WITH (NOLOCK) ON G3.[GLaccountId] = iM.[InventoryToBillGLAccId]
					LEFT JOIN [dbo].[GLAccount] G4  WITH (NOLOCK) ON G4.[GLaccountId] = iM.[FinishedGoodsGLAccId]
					LEFT JOIN [dbo].[GLAccount] G5  WITH (NOLOCK) ON G5.[GLaccountId] = iM.[InventoryExchAgreementGLAccId]
					LEFT JOIN [dbo].[GLAccount] G6  WITH (NOLOCK) ON G6.[GLaccountId] = iM.[InventoryReserveGLAccId]
					LEFT JOIN [dbo].[GLAccount] G7  WITH (NOLOCK) ON G7.[GLaccountId] = iM.[COGS_WorkOrderGLAccId]
					LEFT JOIN [dbo].[GLAccount] G8  WITH (NOLOCK) ON G8.[GLaccountId] = iM.[COGS_SalesOrderGLAccId]
					LEFT JOIN [dbo].[GLAccount] G9  WITH (NOLOCK) ON G9.[GLaccountId] = iM.[COGS_QtyVarianceGLAccId]
					LEFT JOIN [dbo].[GLAccount] G10  WITH (NOLOCK) ON G10.[GLaccountId] = iM.[COGS_UnitCostVarianceGLAccId]
					LEFT JOIN [dbo].[GLAccount] G11  WITH (NOLOCK) ON G11.[GLaccountId] = iM.[RevenueMroGLAccId]
					LEFT JOIN [dbo].[GLAccount] G12  WITH (NOLOCK) ON G12.[GLaccountId] = iM.[RevenueSoGLAccId]
					LEFT JOIN [dbo].[GLAccount] G13  WITH (NOLOCK) ON G13.[GLaccountId] = iM.[RevenueExchGLAccId]
					LEFT JOIN [dbo].[GLAccount] G14  WITH (NOLOCK) ON G14.[GLaccountId] = iM.[COGS_ExchSalesOrderGLAccId]
					WHERE iM.ItemMasterId = @ItemMasterId;	  
		END
		
	END
	COMMIT  TRANSACTION
  END TRY
  BEGIN CATCH
		IF @@trancount > 0
			PRINT 'ROLLBACK'
			ROLLBACK TRAN;
		DECLARE @ErrorLogID int,
            @DatabaseName varchar(100) = DB_NAME()
            -----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            ,@AdhocComments varchar(150) = '[USP_GetItemMasterDetailById]',
            @ProcedureParameters varchar(3000) = '@ItemMasterId = ''' + CAST(ISNULL(@ItemMasterId, '') AS varchar(100)),
            @ApplicationName varchar(100) = 'PAS'
    -----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
    EXEC spLogException @DatabaseName = @DatabaseName,
                        @AdhocComments = @AdhocComments,
                        @ProcedureParameters = @ProcedureParameters,
                        @ApplicationName = @ApplicationName,
                        @ErrorLogID = @ErrorLogID OUTPUT;
    RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)
    RETURN (1);
  END CATCH
END