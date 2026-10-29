/*************************************************************
 ** File:   [USP_RemoveStocklineAsset]
 ** Author: Rajesh Gami
 ** Description: [PN-18407] Asset and Lease Configuration in Stockline - Stockline List > Remove of an
 **              Asset stockline (soft delete, same as Asset Inventory > Remove).
 **              Not removed when any quantity is reserved / issued (returns a message instead).
 **************************************************************
 ** Change History
 **************************************************************
 ** PR   Date            Author          Change Description
 ** --   --------        -------         --------------------------------
    1    27/October/2026 RAJESH GAMI     Created [PN-18407]
**************************************************************/
CREATE   PROCEDURE [dbo].[USP_RemoveStocklineAsset]
	@StockLineId BIGINT,
	@UpdatedBy   VARCHAR(256)
AS
BEGIN
	SET NOCOUNT ON;
	BEGIN TRY
		IF EXISTS (SELECT 1 FROM dbo.Stockline AssetStockline WITH (NOLOCK)
		           WHERE AssetStockline.StockLineId = @StockLineId
		             AND (ISNULL(AssetStockline.QuantityReserved, 0) > 0 OR ISNULL(AssetStockline.QuantityIssued, 0) > 0))
		BEGIN
			SELECT CAST(0 AS BIT) AS IsRemoved, 'Asset is reserved / issued, it can not be removed.' AS ErrorMessage;
			RETURN;
		END

		UPDATE dbo.Stockline SET
			IsDeleted   = 1,
			UpdatedBy   = @UpdatedBy,
			UpdatedDate = GETUTCDATE()
		WHERE StockLineId = @StockLineId AND ISNULL(IsAsset, 0) = 1;

		SELECT CAST(1 AS BIT) AS IsRemoved, '' AS ErrorMessage;
	END TRY
	BEGIN CATCH
		DECLARE @ErrorLogID INT, @DatabaseName VARCHAR(100) = DB_NAME(),
		        @AdhocComments VARCHAR(150) = 'USP_RemoveStocklineAsset',
		        @ProcedureParameters VARCHAR(3000) = '@StockLineId = ''' + CAST(ISNULL(@StockLineId, '') AS VARCHAR(100)),
		        @ApplicationName VARCHAR(100) = 'PAS';
		EXEC spLogException @DatabaseName = @DatabaseName, @AdhocComments = @AdhocComments, @ProcedureParameters = @ProcedureParameters,
		     @ApplicationName = @ApplicationName, @ErrorLogID = @ErrorLogID OUTPUT;
		RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID);
		RETURN (1);
	END CATCH
END
