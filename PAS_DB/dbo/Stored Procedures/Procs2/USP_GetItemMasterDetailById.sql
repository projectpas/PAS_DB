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
	8    02/12/2025  Bhargav Saliya	  Revert Changes.
	9    26-Mar-2026    Sahdev Saliya       Added [LifeLimitedPart] :-([IsFlightHoursAvailable], [IsFlightCyclesAvailable], [IsLandingsAvailable], [IsStartsAvailable], [IsCalendarTimeAvailable], [FlightHours], [FlightMinutes], [FlightCycles], [Landings], [Starts], [CalendarHours], [CalendarMinutes]) (PN-15833, PN-16649_65)

**************************************************************
 EXEC USP_GetItemMasterDetailById 96978
**************************************************************/
create       PROCEDURE [dbo].[USP_GetItemMasterDetailById] 
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
						COALESCE(iM.GLAccount, '') AS glAccount,
						its.StockInventoryName AS inventoryGLSettingName,
						COALESCE(iM.WorkInProgressGLAccName, '') AS workInProgressGLAccName,
						COALESCE(iM.InventoryToBillGLAccName, '') AS inventoryToBillGLAccName,
						COALESCE(iM.FinishedGoodsGLAccName, '') AS finishedGoodsGLAccName,
						COALESCE(iM.InventoryExchAgreementGLAccName, '') AS inventoryExchAgreementGLAccName,
						COALESCE(iM.InventoryReserveGLAccName, '') AS inventoryReserveGLAccName,
						COALESCE(iM.COGS_WorkOrderGLAccName, '') AS cogS_WorkOrderGLAccName,
						COALESCE(iM.COGS_SalesOrderGLAccName, '') AS cogS_SalesOrderGLAccName,
						COALESCE(iM.COGS_ExchSalesOrderGLAccName, '') AS cogS_ExchSalesOrderGLAccName,
						COALESCE(iM.COGS_QtyVarianceGLAccName, '') AS cogS_QtyVarianceGLAccName,
						COALESCE(iM.COGS_UnitCostVarianceGLAccName, '') AS cogS_UnitCostVarianceGLAccName,
						COALESCE(iM.RevenueMroGLAccName, '') AS revenueMroGLAccName,
						COALESCE(iM.RevenueSoGLAccName, '') AS revenueSoGLAccName,
						COALESCE(iM.RevenueExchGLAccName, '') AS revenueExchGLAccName,
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
						COALESCE(iM.GoodsReceivedNotInvoicesGLAccName, '') AS GoodsReceivedNotInvoicesGLAccName,
						iM.WorkOrderFormTypeId,
						ISNULL(iM.IsHotItem,0) AS IsHotItem,
						iM.LifeLimitedPart,
				        iM.IsFlightHoursAvailable,
						iM.IsFlightCyclesAvailable,
						iM.IsLandingsAvailable,
						iM.IsStartsAvailable,
						iM.IsCalendarTimeAvailable,
						iM.FlightHours,
					    iM.FlightMinutes,
				        iM.FlightCycles,
						iM.Landings,
						iM.Starts,
						iM.CalendarHours,
						iM.CalendarMinutes
					FROM dbo.ItemMaster iM WITH(NOLOCK)
					LEFT JOIN CTE_IntegrationPortal itp ON iM.ItemMasterId = itp.ItemMasterId
					LEFT JOIN CTE_InventoryGLSetting its ON iM.InventoryGLSettingId = its.InventoryGLSettingId
					LEFT JOIN dbo.ItemMaster imst WITH(NOLOCK) ON iM.IsOemPNId = imst.ItemMasterId
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