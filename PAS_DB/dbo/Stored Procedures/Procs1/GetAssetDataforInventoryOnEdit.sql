
/*************************************************************
 ** File:   [GetAssetDataforInventoryOnEdit]
 ** Author:   Abhishek Jirawla
 ** Description: This stored procedure is used to get Asset Data for Inventory on Edit
 ** Purpose:
 ** Date:    09/12/2024

 ** PARAMETERS:

 ** RETURN VALUE:

 **************************************************************
  ** Change History
 **************************************************************
 ** PR   Date         Author			Change Description
 ** --   --------     -------			--------------------------------
    1    09/12/2024   Abhishek Jirawla	Created
    2    15/07/2026   Vishal Suthar     Fall back to DeprNonDeprTangibleAssets for AssetTypeName
    3    29/07/2026   Abhishek Jirawala Asset.AssetAttributeTypeId now always stores an AssetAttributeTypeId
                                        (never a DeprNonDeprTangibleAssetsId); joined dnta by its
                                        AssetAttributeTypeId FK instead of its own PK. Dropped the
                                        dnta.AssetAttributeTypeName fallback (column removed) - asty is now
                                        always joined so its name always resolves.

--  EXEC [GetAssetDataforInventoryOnEdit] 221
**************************************************************/

CREATE     PROCEDURE [dbo].[GetAssetDataforInventoryOnEdit]
    @AssetRecordId BIGINT,
	@AssetInventoryId BIGINT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (SELECT TOP 1 * FROM DBO.Asset WITH (NOLOCK) WHERE AssetRecordId = @AssetRecordId AND IsIntangible = 1)
    BEGIN
        SELECT TOP 1
            a.AssetId,
            a.Name,
            a.Description,
            a.AssetRecordId,
            ISNULL(
                (SELECT TOP 1 AssetId FROM DBO.Asset WITH (NOLOCK) WHERE AssetRecordId = a.AlternateAssetRecordId),
                '') AS AlternateAssetId,
            ISNULL(
                (SELECT TOP 1 AssetId FROM DBO.Asset WITH (NOLOCK) WHERE AssetRecordId = a.AssetParentRecordId),
                '') AS AssetParentId,
            a.ManufacturerPN AS PartNumber,
            a.CreatedBy,
            a.CreatedDate,
            a.EntryDate,
            a.IsDeleted,
            a.IsDepreciable,
            a.IsIntangible,
            a.TangibleClassId,
            a.AssetIntangibleTypeId,
            ISNULL(ai.AssetIntangibleName, '') AS AssetIntangibleTypeName,
            a.ManagementStructureId,
            a.MasterCompanyId,
            a.MasterPartId,
            a.IsTangible,
            a.IsNonDepreciable,
            a.IsAmortizable,
            a.IsNonAmortizable,
            a.UpdatedBy,
            a.UpdatedDate,
            a.UnitOfMeasureId,
            ISNULL(u.ShortName, '') AS UnitOfMeasureName
        FROM DBO.Asset a WITH (NOLOCK)
			LEFT JOIN DBO.AssetIntangibleType ai WITH (NOLOCK) ON a.AssetIntangibleTypeId = ai.AssetIntangibleTypeId
			LEFT JOIN DBO.UnitOfMeasure u WITH (NOLOCK) ON a.UnitOfMeasureId = u.UnitOfMeasureId
        WHERE a.AssetRecordId = @AssetRecordId;
    END
    ELSE
    BEGIN
        SELECT TOP 1
			asset.AssetId,
			asset.Name,
			asset.Description,
			asset.AssetRecordId,
			asset.ManufacturerPN AS PartNumber,
			CASE
				WHEN asset.AlternateAssetRecordId IS NULL THEN ''
				ELSE (SELECT p.AssetId FROM DBO.Asset p WITH (NOLOCK) WHERE p.AssetRecordId = asset.AlternateAssetRecordId)
			END AS AlternateAssetId,
			asset.AssetAcquisitionTypeId,
			ac.Name AS AcquisitionType,
			ISNULL(ascal.AssetCalibrationExpected, '') AS AssetCalibrationExpected,
			ISNULL(ascal.AssetCalibrationExpectedTolerance, '') AS AssetCalibrationExpectedTolerance,
			ISNULL(ascal.AssetCalibrationMaxTolerance, '') AS AssetCalibrationMaxTolerance,
			ISNULL(ascal.AssetCalibrationMemo, '') AS AssetCalibrationMemo,
			ISNULL(ascal.AssetCalibrationMinTolerance, '') AS AssetCalibrationMinTolerance,
			ISNULL(ascal.AssetCalibrationMin, '') AS AssetCalibrationMin,
			ISNULL(ascal.AssetCalibratonMax, '') AS AssetCalibratonMax,
			ISNULL(asmai.AssetIsMaintenanceReqd, 0) AS AssetIsMaintenanceReqd,
			ISNULL(ascal.CalibrationCurrencyId, 0) AS CalibrationCurrencyId,
			ISNULL(ascal.CalibrationDefaultCost, 0) AS CalibrationDefaultCost,
			ISNULL(ascal.CalibrationDefaultVendorId, 0) AS CalibrationDefaultVendorId,
			ISNULL(ascal.CalibrationFrequencyDays, 0) AS CalibrationFrequencyDays,
			ISNULL(ascal.CalibrationFrequencyMonths, 0) AS CalibrationFrequencyMonths,
			ISNULL(ascal.CalibrationGlAccountId, 0) AS CalibrationGlAccountId,
			ISNULL(ascal.CalibrationMemo, '') AS CalibrationMemo,
			ISNULL(vencali.VendorName, '') AS CalibrationDefaultVendorName,
			ISNULL(ascal.CalibrationRequired, 0) AS CalibrationRequired,
			ISNULL(ascal.CertificationCurrencyId, 0) AS CertificationCurrencyId,
			ISNULL(ascal.CertificationFrequencyMonths, 0) AS CertificationFrequencyMonths,
			ISNULL(ascal.CertificationFrequencyDays, 0) AS CertificationFrequencyDays,
			ISNULL(ascal.CertificationDefaultVendorId, 0) AS CertificationDefaultVendorId,
			ISNULL(ascal.CertificationDefaultCost, 0) AS CertificationDefaultCost,
			ISNULL(ascal.CertificationGlAccountId, 0) AS CertificationGlAccountId,
			ISNULL(ascal.CertificationMemo, '') AS CertificationMemo,
			ISNULL(vencert.VendorName, '') AS CertificationDefaultVendorName,
			ISNULL(ascal.CertificationRequired, 0) AS CertificationRequired,
			ISNULL(asmai.MaintenanceDefaultVendorId, 0) AS MaintenanceDefaultVendorId,
			ISNULL(venmain.VendorName, '') AS MaintenanceDefaultVendorName,
			ISNULL(asmai.WarrantyDefaultVendorId, 0) AS WarrantyDefaultVendorId,
			ISNULL(venwar.VendorName, '') AS WarrantyDefaultVendorName,
			ISNULL(asmai.MaintenanceGLAccountId, 0) AS MaintenanceGLAccountId,
			ISNULL(asmai.WarrantyGLAccountId, 0) AS WarrantyGLAccountId,
			ISNULL(ascal.InspectionCurrencyId, 0) AS InspectionCurrencyId,
			ISNULL(ascal.InspectionDefaultCost, 0) AS InspectionDefaultCost,
			ISNULL(ascal.InspectionDefaultVendorId, 0) AS InspectionDefaultVendorId,
			ISNULL(venins.VendorName, '') AS InspectionDefaultVendorName,
			ISNULL(ascal.InspectionFrequencyDays, 0) AS InspectionFrequencyDays,
			ISNULL(ascal.InspectionFrequencyMonths, 0) AS InspectionFrequencyMonths,
			ISNULL(ascal.InspectionGlaAccountId, 0) AS InspectionGlaAccountId,
			ISNULL(ascal.InspectionMemo, '') AS InspectionMemo,
			ISNULL(ascal.InspectionRequired, 0) AS InspectionRequired,
			ISNULL(asmai.IsWarrantyRequired, 0) AS IsWarrantyRequired,
			ISNULL(asmai.MaintenanceFrequencyDays, 0) AS MaintenanceFrequencyDays,
			ISNULL(asmai.MaintenanceFrequencyMonths, 0) AS MaintenanceFrequencyMonths,
			ISNULL(asmai.MaintenanceMemo, '') AS MaintenanceMemo,
			ISNULL(ascal.VerificationCurrencyId, 0) AS VerificationCurrencyId,
			ISNULL(ascal.VerificationDefaultCost, 0) AS VerificationDefaultCost,
			ISNULL(ascal.VerificationDefaultVendorId, 0) AS VerificationDefaultVendorId,
			ISNULL(venveri.VendorName, '') AS VerificationDefaultVendorName,
			ISNULL(ascal.VerificationFrequencyDays, 0) AS VerificationFrequencyDays,
			ISNULL(ascal.VerificationFrequencyMonths, 0) AS VerificationFrequencyMonths,
			ISNULL(ascal.VerificationGlAccountId, 0) AS VerificationGlAccountId,
			ISNULL(ascal.VerificationMemo, '') AS VerificationMemo,
			ISNULL(ascal.VerificationRequired, 0) AS VerificationRequired,
			CalibrationCurrencyName = CASE
											WHEN ascal.CalibrationCurrencyId IS NULL THEN ''
											ELSE c.Code
											END,
			CertificationCurrencyName = CASE
											WHEN ascal.CertificationCurrencyId IS NULL THEN ''
											ELSE c.Code
										END,
			InspectionCurrencyName = CASE
										WHEN ascal.InspectionCurrencyId IS NULL THEN ''
										ELSE c.Code
									END,
			VerificationCurrencyName = CASE
											WHEN ascal.VerificationCurrencyId IS NULL THEN ''
											ELSE c.Code
										END,
			ISNULL(asmai.WarrantyCompany, '') AS WarrantyCompany,
			asset.AssetIntangibleTypeId,
			asset.AssetMaintenanceContractFile,
			asset.AssetMaintenanceContractFileExt,
			asset.AssetMaintenanceIsContract,
			CASE
				WHEN asset.AssetParentRecordId IS NULL THEN ''
				ELSE (SELECT p.AssetId FROM DBO.Asset p WITH (NOLOCK) WHERE p.AssetRecordId = asset.AssetParentRecordId)
			END AS AssetParentId,
			asset.TangibleClassId,
			ISNULL(asty.AssetAttributeTypeName, '') AS AssetTypeName,
			asset.AssetAttributeTypeId,
			asset.AssetLocationId,
			(SELECT p.Code + '-' + p.Name FROM DBO.AssetLocation p WITH (NOLOCK) WHERE p.AssetLocationId = asset.AssetLocationId) AS AsetLocationName,
			ISNULL(cagla.AccountCode + '-' + cagla.AccountName, '') AS CalibrationGlAccountName,
			ISNULL(cegla.AccountCode + '-' + cegla.AccountName, '') AS CertificationGlAccountName,
			asset.CreatedBy,
			asset.CreatedDate,
			asset.CurrencyId,
			ISNULL(curr.Code, '') AS CurrencyName,
			asset.EntryDate,
			asset.ExpirationDate,
			ISNULL(mgla.AccountCode + '-' + mgla.AccountName, '') AS GLAccountName,
			ISNULL(wgla.AccountCode + '-' + wgla.AccountName, '') AS warrantyGlAccountName,
			ISNULL(ingla.AccountCode + '-' + ingla.AccountName, '') AS InspectionGlaAccountName,
			asset.IsDeleted,
			asset.IsDepreciable,
			asset.IsIntangible,
			asset.IsSerialized,
			asset.IsTangible,
			asset.ManagementStructureId,
			asset.ManufacturedDate,
			asset.ManufacturerId,
			ISNULL(manu.Name, '') AS ManufacturerName,
			asset.MasterCompanyId,
			asset.MasterPartId,
			asset.Memo,
			asset.Model,
			asset.UnexpiredTime,
			ISNULL(asset.UnitCost, 0) AS UnitCost,
			asset.IsNonDepreciable,
			asset.IsAmortizable,
			asset.IsNonAmortizable,
			asset.UnitOfMeasureId,
			ISNULL(uom.ShortName, '') AS UnitOfMeasureName,
			asset.UpdatedBy,
			asset.UpdatedDate,
			ISNULL(vgla.AccountCode + '-' + vgla.AccountName, '') AS VerificationGlAccountName,
			ISNULL(asty.ConventionType, 0) AS ConventionType,
			ISNULL(ascali.CalibrationProvider, 'Vendor') AS CalibrationProvider,
			ISNULL(ascali.CertificationProvider, 'Vendor') AS CertificationProvider,
			ISNULL(ascali.InspectionProvider, 'Vendor') AS InspectionProvider,
			ISNULL(ascali.VerificationProvider, 'Vendor') AS VerificationProvider,
			asset.SiteId,
			ISNULL(asssite.Name, '') AS SiteName,
			asset.AssetLocationId AS LocationId,
			ISNULL(assloc.Name, '') AS LocationName,
			ISNULL(asswarehouse.Name, '') AS WarehouseName,
			asset.WarehouseId,
			asset.ShelfId,
			ISNULL(assshelf.Name, '') AS ShelfName,
			asset.BinId,
			ISNULL(assbin.Name, '') AS BinName
		FROM DBO.Asset asset WITH (NOLOCK)
			LEFT JOIN DBO.AssetInventory ascal WITH (NOLOCK) ON asset.AssetRecordId = ascal.AssetRecordId
			LEFT JOIN DBO.AssetCalibration ascali WITH (NOLOCK) ON asset.AssetRecordId = ascali.AssetRecordId
			LEFT JOIN DBO.AssetMaintenance asmai WITH (NOLOCK) ON asset.AssetRecordId = asmai.AssetRecordId
			LEFT JOIN DBO.AssetAcquisitionType ac WITH (NOLOCK) ON asset.AssetAcquisitionTypeId = ac.AssetAcquisitionTypeId
			LEFT JOIN DBO.TangibleClass at WITH (NOLOCK) ON asset.TangibleClassId = at.TangibleClassId
			LEFT JOIN DBO.AssetAttributeType asty WITH (NOLOCK) ON asset.AssetAttributeTypeId = asty.AssetAttributeTypeId
			LEFT JOIN DBO.DeprNonDeprTangibleAssets dnta WITH (NOLOCK) ON asset.AssetAttributeTypeId = dnta.AssetAttributeTypeId
			LEFT JOIN DBO.Vendor vencali WITH (NOLOCK) ON ascal.CalibrationDefaultVendorId = vencali.VendorId
			LEFT JOIN DBO.Vendor vencert WITH (NOLOCK) ON ascal.CertificationDefaultVendorId = vencert.VendorId
			LEFT JOIN DBO.Vendor venins WITH (NOLOCK) ON ascal.InspectionDefaultVendorId = venins.VendorId
			LEFT JOIN DBO.Vendor venveri WITH (NOLOCK) ON ascal.VerificationDefaultVendorId = venveri.VendorId
			LEFT JOIN DBO.Vendor venmain WITH (NOLOCK) ON asmai.MaintenanceDefaultVendorId = venmain.VendorId
			LEFT JOIN DBO.Vendor venwar WITH (NOLOCK) ON asmai.WarrantyDefaultVendorId = venwar.VendorId
			LEFT JOIN DBO.Site asssite WITH (NOLOCK) ON asset.SiteId = asssite.SiteId
			LEFT JOIN DBO.Warehouse asswarehouse WITH (NOLOCK) ON asset.WarehouseId = asswarehouse.WarehouseId
			LEFT JOIN DBO.Location assloc WITH (NOLOCK) ON asset.AssetLocationId = assloc.LocationId
			LEFT JOIN DBO.Shelf assshelf WITH (NOLOCK) ON asset.ShelfId = assshelf.ShelfId
			LEFT JOIN DBO.Bin assbin WITH (NOLOCK) ON asset.BinId = assbin.BinId
			LEFT JOIN DBO.Manufacturer manu WITH (NOLOCK) ON asset.ManufacturerId = manu.ManufacturerId
			LEFT JOIN DBO.UnitOfMeasure uom WITH (NOLOCK) ON asset.UnitOfMeasureId = uom.UnitOfMeasureId
			LEFT JOIN DBO.Currency curr WITH (NOLOCK) ON asset.CurrencyId = curr.CurrencyId
			LEFT JOIN DBO.GLAccount cagla WITH (NOLOCK) ON ascal.CalibrationGlAccountId = cagla.GLAccountId
			LEFT JOIN DBO.GLAccount cegla WITH (NOLOCK) ON ascal.CertificationGlAccountId = cegla.GLAccountId
			LEFT JOIN DBO.GLAccount ingla WITH (NOLOCK) ON ascal.InspectionGlaAccountId = ingla.GLAccountId
			LEFT JOIN DBO.GLAccount vgla WITH (NOLOCK) ON ascal.VerificationGlAccountId = vgla.GLAccountId
			LEFT JOIN DBO.GLAccount wgla WITH (NOLOCK) ON asmai.WarrantyGLAccountId = wgla.GLAccountId
			LEFT JOIN DBO.GLAccount mgla WITH (NOLOCK) ON asmai.MaintenanceGLAccountId = mgla.GLAccountId
			LEFT JOIN DBO.Currency c WITH (NOLOCK) ON c.CurrencyId = ascal.CalibrationCurrencyId OR c.CurrencyId = ascal.CertificationCurrencyId OR c.CurrencyId = ascal.InspectionCurrencyId OR c.CurrencyId = ascal.VerificationCurrencyId
		WHERE asset.AssetRecordId = @assetRecordId and ascal.AssetInventoryId = @AssetInventoryId;
    END
END