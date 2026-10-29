/*************************************************************
 ** File:   [USP_GetStocklineAssetAdjustmentHistory]
 ** Author: Rajesh Gami
 ** Description: [PN-18407] Asset and Lease Configuration in Stockline - Asset Adjustment History of an Asset stockline.
 **************************************************************
 ** Change History
 **************************************************************
 ** PR   Date            Author          Change Description
 ** --   --------        -------         --------------------------------
    1    27/October/2026 RAJESH GAMI     Created [PN-18407]
**************************************************************/
CREATE   PROCEDURE [dbo].[USP_GetStocklineAssetAdjustmentHistory]
	@StockLineId BIGINT
AS
BEGIN
	SET NOCOUNT ON;
	BEGIN TRY
		SELECT
			AssetAdjustment.StocklineAssetAdjustmentId,
			AssetAdjustment.StockLineId,
			AssetAdjustment.AssetInventoryAdjustmentDataTypeId,
			AdjustmentDataType.[Description] AS AdjustmentDataType,
			AssetAdjustment.ChangedFrom,
			AssetAdjustment.ChangedTo,
			AssetAdjustment.AdjustmentReason,
			AssetAdjustment.AdjustmentMemo,
			AssetAdjustment.CreatedDate,
			AssetAdjustment.CreatedBy,
			AssetAdjustment.UpdatedDate,
			AssetAdjustment.UpdatedBy
		FROM dbo.StocklineAssetAdjustment AssetAdjustment WITH (NOLOCK)
		LEFT JOIN dbo.AssetInventoryAdjustmentDataType AdjustmentDataType WITH (NOLOCK) ON AdjustmentDataType.AssetInventoryAdjustmentDataTypeId = AssetAdjustment.AssetInventoryAdjustmentDataTypeId
		WHERE AssetAdjustment.StockLineId = @StockLineId AND AssetAdjustment.IsDeleted = 0
		ORDER BY AssetAdjustment.StocklineAssetAdjustmentId DESC;
	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
		DECLARE @ErrorLogID INT, @DatabaseName VARCHAR(100) = DB_NAME(),
		        @AdhocComments VARCHAR(150) = 'USP_GetStocklineAssetAdjustmentHistory',
		        @ProcedureParameters VARCHAR(3000) = '@StockLineId = ''' + CAST(ISNULL(@StockLineId, '') AS VARCHAR(100)),
		        @ApplicationName VARCHAR(100) = 'PAS';
		EXEC spLogException @DatabaseName = @DatabaseName, @AdhocComments = @AdhocComments, @ProcedureParameters = @ProcedureParameters,
		     @ApplicationName = @ApplicationName, @ErrorLogID = @ErrorLogID OUTPUT;
		RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID);
		RETURN (1);
	END CATCH
END
