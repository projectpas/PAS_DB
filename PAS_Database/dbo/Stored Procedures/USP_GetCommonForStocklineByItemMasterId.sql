/*************************************************************           
 ** File:   [USP_GetCommonForStocklineByItemMasterId]           
 ** Author:   Sahdev Saliya
 ** Description: This stored procedure is used to Get CommonForStocklineByItemMasterId List
 ** Purpose:         
 ** Date:   31-10-2025       
          
 ** RETURN VALUE:           
  
 **************************************************************             
  ** Change History             
 **************************************************************             
 ** S NO   Date            Author          Change Description              
 ** --   --------         -------          --------------------------------            
    1    31-10-2025    Sahdev Saliya       Created  

	exec [dbo].[USP_GetCommonForStocklineByItemMasterId]
**************************************************************/
CREATE   PROCEDURE [DBO].[USP_GetCommonForStocklineByItemMasterId]
    @ItemMasterId BIGINT = NULL

AS
BEGIN
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
    SET NOCOUNT ON;

    BEGIN TRY
		SELECT TOP 1
			iM.ItemMasterId,
			iM.PartNumber,
			iM.PartDescription,
			iM.RevisedPartId,
			imxl.ExchangeCoreCost AS CoreUnitCost,
			iM.ItemMasterAssetTypeId AS AcquistionTypeId,
			imps.SP_CalSPByPP_UnitSalePrice AS UnitSalesPrice,
			imps.ConditionId,
			imps.PP_UnitPurchasePrice AS POUnitCost,
			rPart.PartNumber AS RevisedPart,
			iM.ItemGroup,
			iM.ItemMasterAssetTypeId,
			iM.GLAccountId,
			(gl.AccountCode + ' - ' + gl.AccountName) AS GLAccount,
			(SELECT STRING_AGG(inte.Description, ',')
				FROM [DBO].[ItemMaster] v WITH (NOLOCK)
				INNER JOIN [DBO].ItemMasterIntegrationPortal mp WITH (NOLOCK) ON v.ItemMasterId = mp.ItemMasterId
				INNER JOIN [DBO].IntegrationPortal inte WITH (NOLOCK) ON mp.IntegrationPortalId = inte.IntegrationPortalId
				WHERE v.ItemMasterId = iM.ItemMasterId
			) AS IntegrationPortal,

			(SELECT STRING_AGG(CAST(inte.IntegrationPortalId AS VARCHAR(20)), ',')
				FROM [DBO].[ItemMaster] v WITH (NOLOCK)
				INNER JOIN [DBO].ItemMasterIntegrationPortal mp WITH (NOLOCK) ON v.ItemMasterId = mp.ItemMasterId
				INNER JOIN [DBO].IntegrationPortal inte WITH (NOLOCK) ON mp.IntegrationPortalId = inte.IntegrationPortalId
				WHERE v.ItemMasterId = iM.ItemMasterId
			) AS IntegrationPortalIds,
			iM.ShelfLife,
			iM.ExpirationDate,
			iM.IsSerialized,
			ISNULL(imx.ExportECCN, '') AS ExportECCN,
			ISNULL(imx.ITARNumber, '') AS ITARNumber,
			iM.NationalStockNumber,
			iM.TagDays,
			iM.ManufacturingDays,
			iM.DaysReceived,
			iM.OpenDays,
			iM.SiteId,
			iM.WarehouseId,
			iM.LocationId,
			iM.ShelfId,
			iM.BinId,
			iM.IsManufacturingDateAvailable,
			iM.IsOEM,
			iM.IsOemPNId,
			iM.IsPma,
			iM.IsDER,
			iM.IsTimeLife,
			iM.IsActive,
			iM.ManufacturerId,
			iM.PurchaseUnitOfMeasureId,
			iM.IsExpirationDateAvailable,
			iM.IsReceivedDateAvailable,
			iM.IsTagDateAvailable,
			iM.InventoryGLSettingId,
			iM.ItemClassificationName AS Classification

    FROM [DBO].[ItemMaster] iM WITH (NOLOCK)
        LEFT JOIN [DBO].[ItemMaster] rPart WITH (NOLOCK) ON iM.RevisedPartId = rPart.ItemMasterId
        LEFT JOIN [DBO].[ItemMasterExchangeLoan] imxl WITH (NOLOCK) ON iM.ItemMasterId = imxl.ItemMasterId
        LEFT JOIN [DBO].[ItemMasterPurchaseSale] imps WITH (NOLOCK) ON iM.ItemMasterId = imps.ItemMasterId
        LEFT JOIN [DBO].[ItemMasterExportInfo] imx WITH (NOLOCK) ON iM.ItemMasterId = imx.ItemMasterId
        LEFT JOIN [DBO].[GLAccount] gl WITH (NOLOCK) ON iM.GLAccountId = gl.GLAccountId
    WHERE iM.ItemMasterId = @ItemMasterId;
    END TRY 

    BEGIN CATCH
		DECLARE @ErrorLogID INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_GetCommonForStocklineByItemMasterId'
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