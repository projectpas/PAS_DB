/*************************************************************
 ** File:   [USP_SaveStocklineAssetAdjustment]
 ** Author: Rajesh Gami
 ** Description: [PN-18407] Asset and Lease Configuration in Stockline - Asset Adjustment of an Asset stockline (same adjustment
 **              types as Asset Inventory > Asset Adjustment). One call per adjusted field.
 **                1 Management Structure -> Stockline.ManagementStructureId + Stockline MS details
 **                3 Useful Life          -> Stockline.AssetLife
 **                4 Asset ID             -> Stockline.ItemMasterId / PartNumber / PNDescription (another Item Master Asset)
 **                5 Location             -> Stockline.AssetLocationId (AssetLocation)
 **                2, 6, 7                -> history row only (no field change - same as Asset Inventory)
 **              No accounting entry (Asset Inventory adjustment posts none).
 **************************************************************
 ** Change History
 **************************************************************
 ** PR   Date            Author          Change Description
 ** --   --------        -------         --------------------------------
    1    27/October/2026 RAJESH GAMI     Created [PN-18407]
**************************************************************/
CREATE   PROCEDURE [dbo].[USP_SaveStocklineAssetAdjustment]
	@StockLineId          BIGINT,
	@AdjustmentDataTypeId INT,
	@ChangedTo            VARCHAR(250) = NULL,
	@AdjustmentMemo       NVARCHAR(MAX) = NULL,
	@AdjustmentReasonId   INT = NULL,
	@AdjustmentReason     VARCHAR(250) = NULL,
	@MasterCompanyId      INT,
	@CreatedBy            VARCHAR(256)
AS
BEGIN
	SET NOCOUNT ON;
	BEGIN TRY
		BEGIN TRANSACTION;
		DECLARE @ChangedFromId BIGINT, @ChangedToId BIGINT, @ChangedFromText VARCHAR(250), @ChangedToText VARCHAR(250);
		DECLARE @StocklineMSModuleId INT;
		SELECT @StocklineMSModuleId = MSModule.ManagementStructureModuleId FROM dbo.ManagementStructureModule MSModule WITH (NOLOCK) WHERE MSModule.ModuleName = 'Stockline';

		IF @AdjustmentDataTypeId = 1 -- Management Structure
		BEGIN
			SET @ChangedToId = TRY_CAST(@ChangedTo AS BIGINT);
			SELECT @ChangedFromId = AssetStockline.ManagementStructureId FROM dbo.Stockline AssetStockline WITH (NOLOCK) WHERE AssetStockline.StockLineId = @StockLineId;
			SELECT TOP 1 @ChangedFromText = MSDetails.LastMSLevel FROM dbo.StocklineManagementStructureDetails MSDetails WITH (NOLOCK)
			WHERE MSDetails.ReferenceID = @StockLineId AND MSDetails.ModuleID = @StocklineMSModuleId ORDER BY MSDetails.MSDetailsId DESC;

			UPDATE dbo.Stockline SET ManagementStructureId = @ChangedToId WHERE StockLineId = @StockLineId;
			EXEC [dbo].[USP_UpdateSLMSDetails] @StocklineMSModuleId, @StockLineId, @ChangedToId, @CreatedBy;

			SELECT TOP 1 @ChangedToText = MSDetails.LastMSLevel FROM dbo.StocklineManagementStructureDetails MSDetails WITH (NOLOCK)
			WHERE MSDetails.ReferenceID = @StockLineId AND MSDetails.ModuleID = @StocklineMSModuleId ORDER BY MSDetails.MSDetailsId DESC;
		END
		ELSE IF @AdjustmentDataTypeId = 3 -- Useful Life
		BEGIN
			SELECT @ChangedFromText = CAST(AssetStockline.AssetLife AS VARCHAR(50)) FROM dbo.Stockline AssetStockline WITH (NOLOCK) WHERE AssetStockline.StockLineId = @StockLineId;
			SET @ChangedToText = CAST(TRY_CAST(@ChangedTo AS INT) AS VARCHAR(50));
			UPDATE dbo.Stockline SET AssetLife = TRY_CAST(@ChangedTo AS INT) WHERE StockLineId = @StockLineId;
		END
		ELSE IF @AdjustmentDataTypeId = 4 -- Asset ID (another Item Master Asset)
		BEGIN
			SET @ChangedToId = TRY_CAST(@ChangedTo AS BIGINT);
			SELECT @ChangedFromId = AssetStockline.ItemMasterId, @ChangedFromText = AssetStockline.PartNumber FROM dbo.Stockline AssetStockline WITH (NOLOCK) WHERE AssetStockline.StockLineId = @StockLineId;
			UPDATE AssetStockline SET
				AssetStockline.ItemMasterId  = AssetItem.ItemMasterId,
				AssetStockline.PartNumber    = AssetItem.partnumber,
				AssetStockline.PNDescription = AssetItem.PartDescription
			FROM dbo.Stockline AssetStockline
			INNER JOIN dbo.ItemMaster AssetItem WITH (NOLOCK) ON AssetItem.ItemMasterId = @ChangedToId AND ISNULL(AssetItem.IsAsset, 0) = 1
			WHERE AssetStockline.StockLineId = @StockLineId;
			SELECT @ChangedToText = AssetItem.partnumber FROM dbo.ItemMaster AssetItem WITH (NOLOCK) WHERE AssetItem.ItemMasterId = @ChangedToId;
		END
		ELSE IF @AdjustmentDataTypeId = 5 -- Location
		BEGIN
			SET @ChangedToId = TRY_CAST(@ChangedTo AS BIGINT);
			SELECT @ChangedFromId = AssetStockline.AssetLocationId FROM dbo.Stockline AssetStockline WITH (NOLOCK) WHERE AssetStockline.StockLineId = @StockLineId;
			SELECT @ChangedFromText = AssetLocationItem.[Name] FROM dbo.AssetLocation AssetLocationItem WITH (NOLOCK) WHERE AssetLocationItem.AssetLocationId = @ChangedFromId;
			SELECT @ChangedToText = AssetLocationItem.[Name] FROM dbo.AssetLocation AssetLocationItem WITH (NOLOCK) WHERE AssetLocationItem.AssetLocationId = @ChangedToId;
			UPDATE dbo.Stockline SET AssetLocationId = @ChangedToId WHERE StockLineId = @StockLineId;
		END
		ELSE
		BEGIN
			SET @ChangedToText = LEFT(@ChangedTo, 250);
		END

		UPDATE dbo.Stockline SET UpdatedBy = @CreatedBy, UpdatedDate = GETUTCDATE() WHERE StockLineId = @StockLineId;
		IF @AdjustmentDataTypeId IN (1, 4)
			EXEC [dbo].[UpdateStocklineColumnsWithId] @StockLineId;

		INSERT INTO dbo.StocklineAssetAdjustment
			(StockLineId, AssetInventoryAdjustmentDataTypeId, ChangedFromId, ChangedToId, ChangedFrom, ChangedTo, AdjustmentMemo,
			 AdjustmentReasonId, AdjustmentReason, MasterCompanyId, CreatedBy, UpdatedBy, CreatedDate, UpdatedDate, IsActive, IsDeleted)
		VALUES
			(@StockLineId, @AdjustmentDataTypeId, @ChangedFromId, @ChangedToId, @ChangedFromText, @ChangedToText, @AdjustmentMemo,
			 NULLIF(@AdjustmentReasonId, 0), @AdjustmentReason, @MasterCompanyId, @CreatedBy, @CreatedBy, GETUTCDATE(), GETUTCDATE(), 1, 0);

		COMMIT TRANSACTION;
		SELECT SCOPE_IDENTITY() AS StocklineAssetAdjustmentId;
	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
		DECLARE @ErrorLogID INT, @DatabaseName VARCHAR(100) = DB_NAME(),
		        @AdhocComments VARCHAR(150) = 'USP_SaveStocklineAssetAdjustment',
		        @ProcedureParameters VARCHAR(3000) = '@StockLineId = ''' + CAST(ISNULL(@StockLineId, '') AS VARCHAR(100)),
		        @ApplicationName VARCHAR(100) = 'PAS';
		EXEC spLogException @DatabaseName = @DatabaseName, @AdhocComments = @AdhocComments, @ProcedureParameters = @ProcedureParameters,
		     @ApplicationName = @ApplicationName, @ErrorLogID = @ErrorLogID OUTPUT;
		RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID);
		RETURN (1);
	END CATCH
END
