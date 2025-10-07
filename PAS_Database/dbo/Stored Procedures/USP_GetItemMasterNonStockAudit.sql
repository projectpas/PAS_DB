/*************************************************************           
 ** File:   [USP_GetItemMasterNonStockAudit]           
 ** Author:   Sahdev Saliya
 ** Description: This stored procedure is used to Get ItemMasterNonStockAudit List
 ** Purpose:         
 ** Date:   25-09-2025       
          
 ** RETURN VALUE:           
  
 **************************************************************             
  ** Change History             
 **************************************************************             
 ** S NO   Date            Author          Change Description              
 ** --   --------         -------          --------------------------------            
    1    25-09-2025    Sahdev Saliya       Created  

	exec [dbo].[USP_GetItemMasterNonStockAudit] @Id = 8 
**************************************************************/
CREATE    PROCEDURE [dbo].[USP_GetItemMasterNonStockAudit]
@Id BIGINT

AS
BEGIN 	
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
    SET NOCOUNT ON;

	BEGIN TRY

		SELECT 
			iM.ItemMasterNonStockId,
			iM.MasterPartId,
			iM.PartNumber,
			iM.ItemTypeId,
			iM.PartDescription,
			iM.ItemGroupId,
			iM.ItemNonStockClassificationId,
			iM.ManufacturerId,
			iM.GLAccountId,
			CONCAT(gl.AccountCode, ' - ', gl.AccountName) AS glAccount,
			iM.IsHazardousMaterial,
			imCls.Description AS ItemNonStockClassification,
			itg.Description AS itemGroup  ,
			ISNULL(mfg.[Name], '') AS ManufacturerName,
			iM.PurchaseUnitOfMeasureId,
			ipuom.ShortName AS purchaseUnitOfMeasure,
			iM.PriceDate,
			iM.ListPrice,
			iM.UnitCost,
			iM.DiscountPurchasePercent,
			iM.IsAcquiredMethodBuy,
			iM.CurrencyId,
			ISNULL(cucy.Code,'')AS  CurrencyName,
			iM.SiteId,
			iM.WarehouseId,
			iM.ShelfId,
			iM.LocationId,
			iM.BinId,
			iM.IsSerialized,
			iM.IsMfgExpirationDate,
			iM.LeadTimeDays,
			iM.StockLevel,
			iM.ReorderPoint,
			iM.ReorderQuantiy,
			iM.InWarranty,
			iM.Site,
			iM.Warehouse,
            iM.Location,
            iM.Shelf,
            iM.Bin,
			iM.CreatedBy,
            iM.CreatedDate,
            iM.UpdatedBy,
            iM.UpdatedDate,
            iM.IsActive,
            iM.IsDeleted,
			iM.MfgExpirationDate
		from  [DBO].ItemMasterNonStockAudit  iM WITH (NOLOCK)
		LEFT JOIN [DBO].[Manufacturer] mfg WITH (NOLOCK) ON  iM.ManufacturerId = mfg.ManufacturerId
		LEFT JOIN [DBO].ItemClassification imCls WITH (NOLOCK) ON iM.ItemNonStockClassificationId = imCls.ItemClassificationId 
		LEFT JOIN [DBO].Itemgroup itg WITH (NOLOCK) ON iM.ItemGroupId = itg.ItemGroupId
		LEFT JOIN [DBO].GLAccount gl WITH (NOLOCK) ON iM.GLAccountId = gl.GLAccountId
		LEFT JOIN [DBO].Currency cucy WITH (NOLOCK) ON iM.CurrencyId = cucy.CurrencyId
		LEFT JOIN [DBO].UnitOfMeasure ipuom WITH (NOLOCK) ON iM.PurchaseUnitOfMeasureId = ipuom.UnitOfMeasureId
		WHERE iM.ItemMasterNonStockId = @Id

	END TRY 
	BEGIN CATCH
		DECLARE @ErrorLogID INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_GetItemMasterNonStockAudit'
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