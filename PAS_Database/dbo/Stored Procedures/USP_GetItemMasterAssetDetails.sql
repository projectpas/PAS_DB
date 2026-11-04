/*************************************************************
 ** File:   [USP_GetItemMasterAssetDetails]
 ** Author: Rajesh Gami
 ** Description: [PN-18406] Allow Asset in Item Master - returns the Asset (General Information) fields of an
 **              Item Master row, used by the Item Master create / edit screen when the Item Type is Asset.
 **************************************************************
 ** Change History
 **************************************************************
 ** PR   Date            Author          Change Description
 ** --   --------        -------         --------------------------------
    1    26/October/2026 RAJESH GAMI     Created [PN-18406]
**************************************************************/
CREATE   PROCEDURE [dbo].[USP_GetItemMasterAssetDetails]
	@ItemMasterId BIGINT
AS
BEGIN
	SET NOCOUNT ON;
	SELECT
		AssetItem.ItemMasterId,
		AssetItem.ItemTypeId,
		ISNULL(AssetItem.CurrencyId, AssetItem.PurchaseCurrencyId) AS AssetCurrencyId,
		CAST(ISNULL(AssetItem.IsAsset,0) AS BIT) AS IsAsset,
		AssetItem.[AssetName],
		AssetItem.[AssetManufacturerPN],
		AssetItem.[AssetEntryDate],
		AssetItem.[AssetIsTangible],
		AssetItem.[AssetIsIntangible],
		AssetItem.[AssetIsDepreciable],
		AssetItem.[AssetIsNonDepreciable],
		AssetItem.[AssetIsAmortizable],
		AssetItem.[AssetIsNonAmortizable],
		AssetItem.[AssetTangibleClassId],
		AssetItem.[AssetDeprNonDeprTangibleAssetsId],
		AssetItem.[AssetAttributeTypeId],
		AssetItem.[AssetClassSource],
		AssetItem.[AssetIntangibleTypeId],
		AssetItem.[AssetAlternateItemMasterId],
		AssetItem.[AssetParentItemMasterId],
		AssetItem.[AssetControlNumber],
		AssetItem.[AssetManagementStructureId],
		AssetItem.[AcquiredGLAccountId],
		AssetItem.[AcquiredGLAccountName],
		AssetItem.[DeprExpenseGLAccountId],
		AssetItem.[DeprExpenseGLAccountName],
		AssetItem.[AdDepsGLAccountId],
		AssetItem.[AdDepsGLAccountName],
		AssetItem.[AssetSaleGLAccountId],
		AssetItem.[AssetSaleGLAccountName],
		AssetItem.[AssetWriteOffGLAccountId],
		AssetItem.[AssetWriteOffGLAccountName],
		AssetItem.[AssetWriteDownGLAccountId],
		AssetItem.[AssetWriteDownGLAccountName],
		AssetItem.[CalibratedGLAccountId],
		AssetItem.[CalibratedGLAccountName],
		AssetItem.[IntangibleGLAccountId],
		AssetItem.[IntangibleGLAccountName],
		AssetItem.[AmortExpenseGLAccountId],
		AssetItem.[AmortExpenseGLAccountName],
		AssetItem.[AccAmortDeprGLAccountId],
		AssetItem.[AccAmortDeprGLAccountName],
		AssetItem.[IntangibleWriteOffGLAccountId],
		AssetItem.[IntangibleWriteOffGLAccountName],
		AssetItem.[IntangibleWriteDownGLAccountId],
		AssetItem.[IntangibleWriteDownGLAccountName],
		AssetItem.[MaintenanceGLAccountId],
		AssetItem.[MaintenanceGLAccountName],
		AssetItem.[WarrantyGLAccountId],
		AssetItem.[WarrantyGLAccountName],
		AssetItem.[CalibrationGlAccountId],
		AssetItem.[CalibrationGlAccountName],
		AssetItem.[CertificationGlAccountId],
		AssetItem.[CertificationGlAccountName],
		AssetItem.[InspectionGlaAccountId],
		AssetItem.[InspectionGlaAccountName],
		AssetItem.[VerificationGlAccountId],
		AssetItem.[VerificationGlAccountName],
		AlternateAssetItem.partnumber AS AssetAlternatePartNumber,
		ParentAssetItem.partnumber    AS AssetParentPartNumber,
		-- view (Item Master List > View on an Asset item)
		AssetItem.partnumber          AS PartNumber,
		AssetItem.PartDescription,
		AssetItem.StockUnitOfMeasure  AS UnitOfMeasureName,
		AssetItem.AssetAcquistionType AS AcquisitionTypeName,
		AssetItem.ManufacturerName,
		AssetItem.Model,
		AssetItem.isSerialized        AS IsSerialized,
		AssetCurrency.Code            AS CurrencyName,
		AssetItem.UnitCost,
		AssetItem.SiteName,
		AssetItem.WarehouseName,
		AssetItem.LocationName,
		AssetItem.ShelfName,
		AssetItem.BinName,
		AssetItem.Memo,
		AssetItem.IsActive,
		AssetTangibleClass.TangibleClassName,
		AssetIntangibleClass.AssetIntangibleName
	FROM dbo.ItemMaster AssetItem WITH (NOLOCK)
	LEFT JOIN dbo.ItemMaster AlternateAssetItem WITH (NOLOCK) ON AlternateAssetItem.ItemMasterId = AssetItem.AssetAlternateItemMasterId
	LEFT JOIN dbo.ItemMaster ParentAssetItem    WITH (NOLOCK) ON ParentAssetItem.ItemMasterId    = AssetItem.AssetParentItemMasterId
	LEFT JOIN dbo.Currency AssetCurrency WITH (NOLOCK) ON AssetCurrency.CurrencyId = ISNULL(AssetItem.CurrencyId, AssetItem.PurchaseCurrencyId)
	LEFT JOIN dbo.vw_DeprNonDeprTangibleAssets AssetTangibleClass WITH (NOLOCK) ON AssetTangibleClass.DeprNonDeprTangibleAssetsId = AssetItem.AssetDeprNonDeprTangibleAssetsId
	LEFT JOIN dbo.AssetIntangibleType AssetIntangibleClass WITH (NOLOCK) ON AssetIntangibleClass.AssetIntangibleTypeId = AssetItem.AssetIntangibleTypeId
	WHERE AssetItem.ItemMasterId = @ItemMasterId;
END
