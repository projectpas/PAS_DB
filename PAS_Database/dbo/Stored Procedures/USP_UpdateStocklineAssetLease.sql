/*************************************************************
 ** File:   [USP_UpdateStocklineAssetLease]
 ** Author: Rajesh Gami
 ** Description: [PN-18407] Asset and Lease Configuration in Stockline - Edit Asset Stockline > Is Lease toggle.
 **              Saves only Stockline.IsLease right after the confirmation (no full Stockline update).
 **************************************************************
 ** Change History
 **************************************************************
 ** PR   Date            Author          Change Description
 ** --   --------        -------         --------------------------------
    1    28/October/2026 RAJESH GAMI     Created [PN-18407]
**************************************************************/
CREATE   PROCEDURE [dbo].[USP_UpdateStocklineAssetLease]
	@StockLineId BIGINT,
	@IsLease     BIT,
	@UpdatedBy   VARCHAR(256)
AS
BEGIN
	SET NOCOUNT ON;
	BEGIN TRY
		UPDATE AssetStockline SET
			AssetStockline.IsLease     = ISNULL(@IsLease, 0),
			AssetStockline.UpdatedBy   = @UpdatedBy,
			AssetStockline.UpdatedDate = GETUTCDATE()
		FROM dbo.Stockline AssetStockline
		WHERE AssetStockline.StockLineId = @StockLineId AND ISNULL(AssetStockline.IsAsset, 0) = 1;

		SELECT @StockLineId AS StockLineId;
	END TRY
	BEGIN CATCH
		DECLARE @ErrorLogID INT, @DatabaseName VARCHAR(100) = DB_NAME(),
		        @AdhocComments VARCHAR(150) = 'USP_UpdateStocklineAssetLease',
		        @ProcedureParameters VARCHAR(3000) = '@StockLineId = ''' + CAST(ISNULL(@StockLineId, '') AS VARCHAR(100)),
		        @ApplicationName VARCHAR(100) = 'PAS';
		EXEC spLogException @DatabaseName = @DatabaseName, @AdhocComments = @AdhocComments, @ProcedureParameters = @ProcedureParameters,
		     @ApplicationName = @ApplicationName, @ErrorLogID = @ErrorLogID OUTPUT;
		RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID);
		RETURN (1);
	END CATCH
END
