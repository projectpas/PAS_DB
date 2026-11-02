/*************************************************************
 ** File:   [USP_GetStocklineAssetPrintLabelData]
 ** Author: Rajesh Gami
 ** Description: [PN-18407] Asset and Lease Configuration in Stockline - data for Print Asset Inventory Label of an Asset stockline
 **              (same fields Asset Inventory prints; template = AssetInventoryPrintLabel).
 **************************************************************
 ** Change History
 **************************************************************
 ** PR   Date            Author          Change Description
 ** --   --------        -------         --------------------------------
    1    27/October/2026 RAJESH GAMI     Created [PN-18407]
**************************************************************/
CREATE   PROCEDURE [dbo].[USP_GetStocklineAssetPrintLabelData]
	@StockLineId BIGINT
AS
BEGIN
	SET NOCOUNT ON;
	BEGIN TRY
		SELECT TOP 1
			AssetStockline.StockLineId,
			AssetStockline.PartNumber,
			AssetStockline.PNDescription AS PartDescription,
			AssetStockline.StockLineNumber,
			AssetStockline.AssetInventoryNumber,
			AssetStockline.SerialNumber,
			AssetStockline.ControlNumber,
			AssetStockline.[Site] AS SiteName,
			AssetStockline.Warehouse,
			AssetStockline.[Location],
			AssetStockline.Shelf AS ShelfName,
			AssetStockline.Bin AS BinName,
			ISNULL(StocklineVendor.VendorName, '') AS VendorName,
			CAST(ISNULL(AssetStockline.Quantity, 0) AS INT) AS Quantity,
			ISNULL(AssetStockline.PurchaseOrderNumber, AssetStockline.RepairOrderNumber) AS PurchaseOrderNumber,
			AssetStockline.ExpirationDate,
			AssetStockline.Manufacturer,
			AssetStockline.ReceiverNumber,
			AssetStockline.ReceivedDate,
			AssetStockline.Memo,
			AssetAttribute.AssetAttributeTypeName AS ClassName,
			CalibrationVendor.VendorName AS CalibrationDefaultVendorName,
			AssetStockline.LastCalibrationDate,
			AssetStockline.NextCalibrationDate,
			LTRIM(RTRIM(CONCAT(ISNULL(CalibrationEmployee.FirstName, ''), ' ', ISNULL(CalibrationEmployee.LastName, '')))) AS CalibrationPerformedBy,
			AssetStockline.MasterCompanyId,
			AssetStockline.UpdatedDate
		FROM dbo.Stockline AssetStockline WITH (NOLOCK)
		LEFT JOIN dbo.Vendor StocklineVendor WITH (NOLOCK) ON StocklineVendor.VendorId = AssetStockline.VendorId
		LEFT JOIN dbo.AssetAttributeType AssetAttribute WITH (NOLOCK) ON AssetAttribute.AssetAttributeTypeId = AssetStockline.AssetAttributeTypeId
		LEFT JOIN dbo.Vendor CalibrationVendor WITH (NOLOCK) ON CalibrationVendor.VendorId = AssetStockline.CalibrationDefaultVendorId
		LEFT JOIN dbo.Employee CalibrationEmployee WITH (NOLOCK) ON CalibrationEmployee.EmployeeId = AssetStockline.CalibrationPerformedById
		WHERE AssetStockline.StockLineId = @StockLineId;
	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
		DECLARE @ErrorLogID INT, @DatabaseName VARCHAR(100) = DB_NAME(),
		        @AdhocComments VARCHAR(150) = 'USP_GetStocklineAssetPrintLabelData',
		        @ProcedureParameters VARCHAR(3000) = '@StockLineId = ''' + CAST(ISNULL(@StockLineId, '') AS VARCHAR(100)),
		        @ApplicationName VARCHAR(100) = 'PAS';
		EXEC spLogException @DatabaseName = @DatabaseName, @AdhocComments = @AdhocComments, @ProcedureParameters = @ProcedureParameters,
		     @ApplicationName = @ApplicationName, @ErrorLogID = @ErrorLogID OUTPUT;
		RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID);
		RETURN (1);
	END CATCH
END
