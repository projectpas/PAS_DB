/*********************             
 ** File:   UPDATE CUSTOMER IN WO           
 ** Author:  HEMANT SALIYA  
 ** Description: This SP Is Used to Get Item Master By Id
 ** Purpose:           
 ** Date:   27-MAY-2024
    
 ************************************************************             
  ** Change History             
 ************************************************************             
 ** PR   Date         Author			Change Description              
 ** --   --------     -------			--------------------------------            
    1    27-MAY-2024   HEMANT SALIYA      Created  
   
exec USP_GetItemMasterById 
*************************************************************/   
  
CREATE   PROCEDURE [dbo].[USP_GetItemMasterById] 	
@ItemMasterId BIGINT = NULL	
AS  
BEGIN  
 SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED  
 SET NOCOUNT ON;  
 BEGIN TRY
		
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
			iM.RevisedPartId,
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
			(SELECT STRING_AGG(CAST(e.IntegrationPortalId AS VARCHAR), ',')
			 FROM ItemMasterIntegrationPortal e
			 WHERE e.ItemMasterId = iM.ItemMasterId) AS IntegrationPortalIds,
			iM.IsHotItem, 
			imst.PartNumber AS oemPN,
			COALESCE(iM.RevisedPart, '') AS RevisedPart,
			COALESCE(iM.ItemClassificationName, '') AS ItemClassification,
			COALESCE(iM.ItemGroup, '') AS itemGroup,
			COALESCE(iM.AssetAcquistionType, '') AS assetAcquistionType,
			COALESCE(iM.PurchaseUnitOfMeasure, '') AS purchaseUnitOfMeasure,
			COALESCE(iM.ConsumeUnitOfMeasure, '') AS consumeUnitOfMeasure,
			COALESCE(iM.StockUnitOfMeasure, '') AS stockUnitOfMeasure,
			COALESCE(iM.GLAccount, '') AS glAccount,
			(SELECT STRING_AGG(inte.Description, ',')
			 FROM ItemMasterIntegrationPortal mp
			 JOIN IntegrationPortal inte ON mp.IntegrationPortalId = inte.IntegrationPortalId
			 WHERE mp.ItemMasterId = iM.ItemMasterId) AS integrationPortal,
			iM.IsOemPNId,
			COALESCE(iM.Priority, '') AS priority,
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
			iM.Item
		FROM dbo.ItemMaster iM WITH (NOLOCK)
			LEFT JOIN dbo.ItemMaster imst ON iM.IsOemPNId = imst.ItemMasterId
		WHERE 
			iM.ItemMasterId = @ItemMasterId;

  
 END TRY      
 BEGIN CATCH  
	--SELECT
 --   ERROR_NUMBER() AS ErrorNumber,
 --   ERROR_STATE() AS ErrorState,
 --   ERROR_SEVERITY() AS ErrorSeverity,
 --   ERROR_PROCEDURE() AS ErrorProcedure,
 --   ERROR_LINE() AS ErrorLine,
 --   ERROR_MESSAGE() AS ErrorMessage;
  DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()   
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------  
        , @AdhocComments     VARCHAR(150)    = 'USP_UpdateWorkOrderCustomerDetails'   
        ,@ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@ItemMasterId, '') AS varchar(100))   
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
 END CATCH  
END