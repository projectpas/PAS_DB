/*************************************************************           
 ** File:   [USP_GetCommonForNonStocklineByItemMasterId]
 ** Author:   Nakul Chandigra   
 ** Description: This stored procedure is used to Get CommonForNonStocklineByItemMasterId List
 ** Purpose:         
 ** Date:   22-06-2026        
          
 ** RETURN VALUE:           
  
 **************************************************************             
  ** Change History             
 **************************************************************             
 ** S NO   Date            Author          Change Description              
 ** --   --------         -------          --------------------------------            
    1    22-06-2026     Nakul Chandigra        Created   (PN-16138)

	exec [dbo].[USP_GetCommonForStocklineByItemMasterId] 169785
**************************************************************/
Create     PROCEDURE [dbo].[USP_GetCommonForNonStocklineByItemMasterId]
    @ItemMasterId BIGINT = NULL

AS
BEGIN
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
    SET NOCOUNT ON;

    BEGIN TRY

       SELECT TOP 1
            iM.ItemMasterNonStockId,
            iM.MasterPartId,
            iM.PartNumber,
            iM.ItemTypeId,
            iM.PartDescription,
            iM.ItemGroupId,
            iM.ItemNonStockClassificationId,
            iM.ManufacturerId,
            iM.GLAccountId,
            ISNULL(gl.AccountCode, '') + ' - ' + ISNULL(gl.AccountName, '') AS GlAccount,
            iM.IsHazardousMaterial,
            imCls.Description AS ItemNonStockClassification,
            itg.Description AS ItemGroup,
            ISNULL(mfg.Name, '') AS ManufacturerName,
            iM.PurchaseUnitOfMeasureId, 
            uom.ShortName AS PurchaseUnitOfMeasure,
            iM.PriceDate,
            iM.ListPrice,
            iM.UnitCost,
            iM.DiscountPurchasePercent,
            iM.IsAcquiredMethodBuy,
            iM.CurrencyId,
            ISNULL(cucy.Code, '') AS CurrencyName,
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
            iM.MfgExpirationDate,
            ISNULL(iM.PurchaseUnitOfMeasureId,0) PurchaseUnitOfMeasureId,
            ISNULL(uom.Class,'Decimal') as Class,
			ISNULL(uom.DecimalPlaces,2) as DecimalPlaces
        FROM dbo.ItemMasterNonStock iM WITH (NOLOCK)
        LEFT JOIN dbo.Manufacturer mfg WITH (NOLOCK) ON iM.ManufacturerId = mfg.ManufacturerId
        LEFT JOIN dbo.ItemClassification imCls WITH (NOLOCK) ON iM.ItemNonStockClassificationId = imCls.ItemClassificationId
        LEFT JOIN dbo.Itemgroup itg WITH (NOLOCK) ON iM.ItemGroupId = itg.ItemGroupId
        LEFT JOIN dbo.GLAccount gl WITH (NOLOCK) ON iM.GLAccountId = gl.GLAccountId
        LEFT JOIN dbo.Currency cucy WITH (NOLOCK) ON iM.CurrencyId = cucy.CurrencyId
        LEFT JOIN dbo.UnitOfMeasure uom WITH (NOLOCK) ON iM.PurchaseUnitOfMeasureId = uom.UnitOfMeasureId
        WHERE iM.MasterPartId = @ItemMasterId; 

    END TRY 
    BEGIN CATCH
		DECLARE @ErrorLogID INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_GetCommonForNonStocklineByItemMasterId'
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