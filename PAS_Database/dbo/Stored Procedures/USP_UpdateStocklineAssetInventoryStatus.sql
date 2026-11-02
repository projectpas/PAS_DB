/*************************************************************
 ** File:   [USP_UpdateStocklineAssetInventoryStatus]
 ** Author: Rajesh Gami
 ** Description: [PN-18407] Asset and Lease Configuration in Stockline - Edit Asset Inventory Status of an Asset stockline
 **              (same rules as Asset Inventory > Edit Asset Inventory Status: status + status note).
 **              Note: Asset Inventory requests an 'AssetWriteOff' batch for UnAvailable, but
 **              USP_CreateBatch_Asset_inventory has no branch for that combination, so no entry is posted
 **              there either - kept the same (no accounting).
 **************************************************************
 ** Change History
 **************************************************************
 ** PR   Date            Author          Change Description
 ** --   --------        -------         --------------------------------
    1    27/October/2026 RAJESH GAMI     Created [PN-18407]
**************************************************************/
CREATE   PROCEDURE [dbo].[USP_UpdateStocklineAssetInventoryStatus]
	@StockLineId            BIGINT,
	@AssetInventoryStatusId BIGINT,
	@UpdatedBy              VARCHAR(256)
AS
BEGIN
	SET NOCOUNT ON;
	BEGIN TRY
		DECLARE @StatusName VARCHAR(100);
		SELECT @StatusName = InventoryStatus.[Status]
		FROM dbo.AssetInventoryStatus InventoryStatus WITH (NOLOCK)
		WHERE InventoryStatus.AssetInventoryStatusId = @AssetInventoryStatusId;

		UPDATE AssetStockline SET
			AssetStockline.AssetInventoryStatusId = @AssetInventoryStatusId,
			-- 1 Available, 3 UnAvailable, 6 Active, 7 Inactive: no note (same as Asset Inventory)
			AssetStockline.AssetStatusNote        = CASE WHEN @AssetInventoryStatusId IN (1, 3, 6, 7) THEN ''
			                                             ELSE 'Current Inventory Status is ' + ISNULL(@StatusName, '') END,
			AssetStockline.UpdatedBy              = @UpdatedBy,
			AssetStockline.UpdatedDate            = GETUTCDATE()
		FROM dbo.Stockline AssetStockline
		WHERE AssetStockline.StockLineId = @StockLineId AND ISNULL(AssetStockline.IsAsset, 0) = 1;

		SELECT @StockLineId AS StockLineId;
	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
		DECLARE @ErrorLogID INT, @DatabaseName VARCHAR(100) = DB_NAME(),
		        @AdhocComments VARCHAR(150) = 'USP_UpdateStocklineAssetInventoryStatus',
		        @ProcedureParameters VARCHAR(3000) = '@StockLineId = ''' + CAST(ISNULL(@StockLineId, '') AS VARCHAR(100)),
		        @ApplicationName VARCHAR(100) = 'PAS';
		EXEC spLogException @DatabaseName = @DatabaseName, @AdhocComments = @AdhocComments, @ProcedureParameters = @ProcedureParameters,
		     @ApplicationName = @ApplicationName, @ErrorLogID = @ErrorLogID OUTPUT;
		RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID);
		RETURN (1);
	END CATCH
END
