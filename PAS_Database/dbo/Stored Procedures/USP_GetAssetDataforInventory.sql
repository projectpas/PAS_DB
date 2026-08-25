/***************************************************************
 ** File:  [USP_GetAssetDataforInventory]
 ** Author: Ayushi Patel
 ** Description: Get Asset Details
 ** Purpose:
 ** Date:  12-Jun-2025

 ** Change History
 **************************************************************
 ** PR   Date				Author  			Change Description
 ** --   --------			-------				--------------------------------
    1    2025-06-12		    Ayushi Patel		Created
    2	 02-FEB-2026	    Divyesh Kathiriya	Add "CalibrationCertificateNumber"
    3	 15-JUL-2026	    Vishal Suthar		Fall back to DeprNonDeprTangibleAssets for AssetTypeName/DeprExpenseGLAccount/AdDepsGLAccount, add CalibratedGLAccount
    4	 29-JUL-2026	    Abhishek Jirawala	Asset.AssetAttributeTypeId now always stores an AssetAttributeTypeId (never a
	                                        DeprNonDeprTangibleAssetsId); DeprNonDeprTangibleAssets is now a GL-calibrated
	                                        override joined by its AssetAttributeTypeId FK instead of by its own PK.
	                                        AssetAttributeTypeName removed from DeprNonDeprTangibleAssets (name now
	                                        always comes from the joined AssetAttributeType row).
    5	 06-AUG-2026	    Abhishek Jirawala	Return asset.DeprNonDeprTangibleAssetsId so the resolved GL-calibrated
	                                        row carries forward when this asset is selected for a new AssetInventory.

	exec [USP_GetAssetDataforInventory] 211
***************************************************************/
CREATE   PROCEDURE [dbo].[USP_GetAssetDataforInventory]
    @assetRecordId BIGINT
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        DECLARE @IsIntangible BIT;

        -- Check if the asset is intangible
        SELECT @IsIntangible = IsIntangible
        FROM dbo.Asset WITH (NOLOCK)
        WHERE AssetRecordId = @assetRecordId;

        IF @IsIntangible = 1
        BEGIN
            SELECT
                asset.AssetId,
                asset.Name,
                asset.Description,
                asset.AssetRecordId,
                ISNULL(altAsset.AssetId, '') AS AlternateAssetId,
                ISNULL(parentAsset.AssetId, '') AS AssetParentId,
                asset.ManufacturerPN AS PartNumber,
                asset.CreatedBy,
                asset.CreatedDate,
                asset.EntryDate,
                ISNULL(asset.IsActive, 0) AS IsActive,
                ISNULL(asset.IsDeleted, 0) AS IsDeleted,
                ISNULL(asset.IsDepreciable, 0) AS IsDepreciable,
                ISNULL(asset.IsIntangible, 0) AS IsIntangible,
                asset.TangibleClassId,
                asset.DeprNonDeprTangibleAssetsId,
                asset.AssetIntangibleTypeId,
                ISNULL(aity.AssetIntangibleName, '') AS AssetIntangibleTypeName,
                asset.ManagementStructureId,
                asset.MasterCompanyId,
                asset.MasterPartId,
                ISNULL(asset.IsTangible, 0) AS IsTangible,
                ISNULL(asset.IsNonDepreciable, 0) AS IsNonDepreciable,
                ISNULL(asset.IsAmortizable, 0) AS IsAmortizable,
                ISNULL(asset.IsNonAmortizable, 0) AS IsNonAmortizable,
                asset.UpdatedBy,
                asset.UpdatedDate,
                asset.UnitOfMeasureId,
                ISNULL(uom.ShortName, '') AS UnitOfMeasureName,
                ISNULL(asdm.AssetDepreciationMethodName, '') AS AmortizationMethod,
                ISNULL(asdf.Name, '') AS AmortizationFrequency,
                ISNULL(asty.IntangibleLifeYears, 0) AS IntangibleLife,
                ISNULL(iaccGL.AccountCode + '-' + iaccGL.AccountName, '') AS IntangibleGLAccount,
                ISNULL(aeGL.AccountCode + '-' + aeGL.AccountName, '') AS AmortExpenseGLAccount,
                ISNULL(aadGL.AccountCode + '-' + aadGL.AccountName, '') AS AccAmortDeprGLAccount,
                ISNULL(iwdGL.AccountCode + '-' + iwdGL.AccountName, '') AS IntangibleWriteDownGLAccount,
                ISNULL(iwoGL.AccountCode + '-' + iwoGL.AccountName, '') AS IntangibleWriteOffGLAccount
            FROM dbo.Asset asset WITH (NOLOCK)
            LEFT JOIN dbo.Asset altAsset WITH (NOLOCK) ON altAsset.AssetRecordId = asset.AlternateAssetRecordId
            LEFT JOIN dbo.Asset parentAsset WITH (NOLOCK) ON parentAsset.AssetRecordId = asset.AssetParentRecordId
            LEFT JOIN dbo.AssetIntangibleType aity WITH (NOLOCK) ON asset.AssetIntangibleTypeId = aity.AssetIntangibleTypeId
            LEFT JOIN dbo.AssetIntangibleAttributeType asty WITH (NOLOCK) ON asset.AssetIntangibleTypeId = asty.AssetIntangibleTypeId
            LEFT JOIN dbo.AssetDepreciationMethod asdm WITH (NOLOCK) ON asty.AssetDepreciationMethodId = asdm.AssetDepreciationMethodId
            LEFT JOIN dbo.AssetDepreciationFrequency asdf WITH (NOLOCK) ON asty.AssetAmortizationIntervalId = asdf.AssetDepreciationFrequencyId
            LEFT JOIN dbo.UnitOfMeasure uom WITH (NOLOCK) ON asset.UnitOfMeasureId = uom.UnitOfMeasureId
            LEFT JOIN dbo.GLAccount iaccGL WITH (NOLOCK) ON asty.IntangibleGLAccountId = iaccGL.GLAccountId
            LEFT JOIN dbo.GLAccount aeGL WITH (NOLOCK) ON asty.AmortExpenseGLAccountId = aeGL.GLAccountId
            LEFT JOIN dbo.GLAccount aadGL WITH (NOLOCK) ON asty.AccAmortDeprGLAccountId = aadGL.GLAccountId
            LEFT JOIN dbo.GLAccount iwdGL WITH (NOLOCK) ON asty.IntangibleWriteDownGLAccountId = iwdGL.GLAccountId
            LEFT JOIN dbo.GLAccount iwoGL WITH (NOLOCK) ON asty.IntangibleWriteOffGLAccountId = iwoGL.GLAccountId
            WHERE asset.AssetRecordId = @assetRecordId;
        END
        ELSE
        BEGIN
            SELECT
                asset.AssetId,
                asset.Name,
                asset.Description,
                asset.AssetRecordId,
                asset.ManufacturerPN AS PartNumber,
                ISNULL(altAsset.AssetId, '') AS AlternateAssetId,
                ISNULL(parentAsset.AssetId, '') AS AssetParentId,
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
                ISNULL(ascal.CalibrationRequired, 0) AS CalibrationRequired,
                ISNULL(ascal.CertificationCurrencyId, 0) AS CertificationCurrencyId,
                ISNULL(ascal.CertificationFrequencyMonths, 0) AS CertificationFrequencyMonths,
                ISNULL(ascal.CertificationFrequencyDays, 0) AS CertificationFrequencyDays,
                ISNULL(ascal.CertificationDefaultVendorId, 0) AS CertificationDefaultVendorId,
                ISNULL(ascal.CertificationDefaultCost, 0) AS CertificationDefaultCost,
                ISNULL(ascal.CertificationGlAccountId, 0) AS CertificationGlAccountId,
                ISNULL(ascal.CertificationMemo, '') AS CertificationMemo,
                ISNULL(ascal.CertificationRequired, 0) AS CertificationRequired,
                ISNULL(asmai.MaintenanceDefaultVendorId, 0) AS MaintenanceDefaultVendorId,
                ISNULL(asmai.WarrantyDefaultVendorId, 0) AS WarrantyDefaultVendorId,
                ISNULL(asmai.MaintenanceGLAccountId, 0) AS MaintenanceGLAccountId,
                ISNULL(asmai.WarrantyGLAccountId, 0) AS WarrantyGLAccountId,
                ISNULL(ascal.InspectionCurrencyId, 0) AS InspectionCurrencyId,
                ISNULL(ascal.InspectionDefaultCost, 0) AS InspectionDefaultCost,
                ISNULL(ascal.InspectionDefaultVendorId, 0) AS InspectionDefaultVendorId,
                ISNULL(ascal.InspectionFrequencyDays, 0) AS InspectionFrequencyDays,
                ISNULL(ascal.InspectionFrequencyMonths, 0) AS InspectionFrequencyMonths,
                ISNULL(ascal.InspectionGlaAccountId, 0) AS InspectionGlaAccountId,
                ISNULL(ascal.InspectionMemo, '') AS InspectionMemo,
                ISNULL(ascal.InspectionRequired, 0) AS InspectionRequired,
                ISNULL(ascal.VerificationCurrencyId, 0) AS VerificationCurrencyId,
                ISNULL(ascal.VerificationDefaultCost, 0) AS VerificationDefaultCost,
                ISNULL(ascal.VerificationDefaultVendorId, 0) AS VerificationDefaultVendorId,
                ISNULL(ascal.VerificationFrequencyDays, 0) AS VerificationFrequencyDays,
                ISNULL(ascal.VerificationFrequencyMonths, 0) AS VerificationFrequencyMonths,
                ISNULL(ascal.VerificationGlAccountId, 0) AS VerificationGlAccountId,
                ISNULL(ascal.VerificationMemo, '') AS VerificationMemo,
                ISNULL(ascal.VerificationRequired, 0) AS VerificationRequired,
                --ISNULL(ascal.CalibrationCurrencyName, '') AS CalibrationCurrencyName,
                --ISNULL(ascal.CertificationCurrencyName, '') AS CertificationCurrencyName,
                --ISNULL(ascal.InspectionCurrencyName, '') AS InspectionCurrencyName,
                --ISNULL(ascal.VerificationCurrencyName, '') AS VerificationCurrencyName,
				ISNULL(calCur.Code, '') AS CalibrationCurrencyName,
				ISNULL(certCur.Code, '') AS CertificationCurrencyName,
				ISNULL(inspCur.Code, '') AS InspectionCurrencyName,
				ISNULL(verCur.Code, '') AS VerificationCurrencyName,
                ISNULL(asmai.WarrantyCompany, '') AS WarrantyCompany,
                asset.AssetIntangibleTypeId,
                asset.AssetMaintenanceContractFile,
                asset.AssetMaintenanceContractFileExt,
                asset.AssetMaintenanceIsContract,
                ISNULL(asset.AssetParentRecordId, '') AS AssetParentId,
                asset.TangibleClassId,
                asset.DeprNonDeprTangibleAssetsId,
                ISNULL(atc.TangibleClassName, '') AS AssetTypeName,
                asset.AssetAttributeTypeId,
                asset.AssetLocationId,
                ISNULL(aloc.Code + '-' + aloc.Name, '') AS AsetLocationName,
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
                ISNULL(asset.IsActive, 0) AS IsActive,
                ISNULL(asset.IsDeleted, 0) AS IsDeleted,
                ISNULL(asset.IsDepreciable, 0) AS IsDepreciable,
                ISNULL(asset.IsIntangible, 0) AS IsIntangible,
                ISNULL(asset.IsSerialized, 0) AS IsSerialized,
                ISNULL(asset.IsTangible, 0) AS IsTangible,
                asset.ManagementStructureId,
                asset.ManufacturedDate,
                asset.ManufacturerId,
                ISNULL(manu.Name, '') AS ManufacturerName,
                asset.MasterCompanyId,
                asset.MasterPartId,
                asset.Memo,
                asset.Model,
                asset.UnexpiredTime,
                asset.UnitCost,
                ISNULL(asset.IsNonDepreciable, 0) AS IsNonDepreciable,
                ISNULL(asset.IsAmortizable, 0) AS IsAmortizable,
                ISNULL(asset.IsNonAmortizable, 0) AS IsNonAmortizable,
                asset.UnitOfMeasureId,
                ISNULL(uom.ShortName, '') AS UnitOfMeasureName,
                asset.UpdatedBy,
                asset.UpdatedDate,
                ISNULL(vgla.AccountCode + '-' + vgla.AccountName, '') AS VerificationGlAccountName,
                ISNULL(asty.ConventionType, 0) AS ConventionType,
                ISNULL(asty.DepreciationMethod, 0) AS DepreciationMethodId,
                ISNULL(asdm.AssetDepreciationMethodName, '') AS DepreciationMethod,
                ISNULL(per.PercentValue, 0) AS ResidualPercentage,
                ISNULL(dnta.AssetLife, 0) AS AssetLife,                
                ISNULL(asdf.AssetDepreciationFrequencyId, '') AS DepreciationFrequencyId,
                ISNULL(asdf.Name, '') AS DepreciationFrequency,
                ISNULL(accGL.AccountCode + '-' + accGL.AccountName, '') AS AcquiredGLAccount,
                ISNULL(deprGL.AccountCode + '-' + deprGL.AccountName, ISNULL(dntaDeprGL.AccountCode + '-' + dntaDeprGL.AccountName, '')) AS DeprExpenseGLAccount,
                ISNULL(addeppsGL.AccountCode + '-' + addeppsGL.AccountName, ISNULL(dntaAdGL.AccountCode + '-' + dntaAdGL.AccountName, '')) AS AdDepsGLAccount,
                ISNULL(calGL.AccountCode + '-' + calGL.AccountName, '') AS CalibratedGLAccount,
                ISNULL(assGL.AccountCode + '-' + assGL.AccountName, '') AS AssetSale,
                ISNULL(aswGL.AccountCode + '-' + aswGL.AccountName, '') AS AssetWriteOff,
                ISNULL(aswdGL.AccountCode + '-' + aswdGL.AccountName, '') AS AssetWriteDown,
                ISNULL(ascal.CalibrationProvider, 'Vendor') AS CalibrationProvider,
                ISNULL(ascal.CertificationProvider, 'Vendor') AS CertificationProvider,
                ISNULL(ascal.InspectionProvider, 'Vendor') AS InspectionProvider,
                ISNULL(ascal.VerificationProvider, 'Vendor') AS VerificationProvider,
                asset.SiteId,
                asset.AssetLocationId AS LocationId,
                asset.WarehouseId,
                asset.ShelfId,
                asset.BinId,
                ISNULL(asmai.IsWarrantyRequired, 0) AS IsWarrantyRequired,
                ISNULL(asmai.MaintenanceFrequencyDays, 0) AS MaintenanceFrequencyDays,
                ISNULL(asmai.MaintenanceFrequencyMonths, 0) AS MaintenanceFrequencyMonths,
                ISNULL(asmai.MaintenanceMemo, '') AS MaintenanceMemo,
                ISNULL(ascal.CalibrationCertificateNumber, '') AS CalibrationCertificateNumber
            FROM dbo.Asset asset WITH (NOLOCK)
            LEFT JOIN dbo.Asset altAsset WITH (NOLOCK) ON altAsset.AssetRecordId = asset.AlternateAssetRecordId
			LEFT JOIN dbo.Asset parentAsset WITH (NOLOCK) ON parentAsset.AssetRecordId = asset.AssetParentRecordId
            LEFT JOIN dbo.AssetCalibration ascal WITH (NOLOCK) ON asset.AssetRecordId = ascal.AssetRecordId
            LEFT JOIN dbo.AssetMaintenance asmai WITH (NOLOCK) ON asset.AssetRecordId = asmai.AssetRecordId
            LEFT JOIN dbo.AssetAcquisitionType ac WITH (NOLOCK) ON asset.AssetAcquisitionTypeId = ac.AssetAcquisitionTypeId
            LEFT JOIN dbo.Manufacturer manu WITH (NOLOCK) ON asset.ManufacturerId = manu.ManufacturerId
            LEFT JOIN dbo.UnitOfMeasure uom WITH (NOLOCK) ON asset.UnitOfMeasureId = uom.UnitOfMeasureId
            LEFT JOIN dbo.Currency curr WITH (NOLOCK) ON asset.CurrencyId = curr.CurrencyId
			LEFT JOIN dbo.Currency calCur WITH (NOLOCK) ON ascal.CalibrationCurrencyId = calCur.CurrencyId
			LEFT JOIN dbo.Currency certCur WITH (NOLOCK) ON ascal.CertificationCurrencyId = certCur.CurrencyId
			LEFT JOIN dbo.Currency inspCur WITH (NOLOCK) ON ascal.InspectionCurrencyId = inspCur.CurrencyId
			LEFT JOIN dbo.Currency verCur WITH (NOLOCK) ON ascal.VerificationCurrencyId = verCur.CurrencyId
            LEFT JOIN dbo.GLAccount cagla WITH (NOLOCK) ON ascal.CalibrationGlAccountId = cagla.GLAccountId
            LEFT JOIN dbo.GLAccount cegla WITH (NOLOCK) ON ascal.CertificationGlAccountId = cegla.GLAccountId
            LEFT JOIN dbo.GLAccount ingla WITH (NOLOCK) ON ascal.InspectionGlaAccountId = ingla.GLAccountId
            LEFT JOIN dbo.GLAccount vgla WITH (NOLOCK) ON ascal.VerificationGlAccountId = vgla.GLAccountId
            LEFT JOIN dbo.GLAccount mgla WITH (NOLOCK) ON asmai.MaintenanceGLAccountId = mgla.GLAccountId
            LEFT JOIN dbo.GLAccount wgla WITH (NOLOCK) ON asmai.WarrantyGLAccountId = wgla.GLAccountId
            LEFT JOIN dbo.AssetAttributeType asty WITH (NOLOCK) ON asset.AssetAttributeTypeId = asty.AssetAttributeTypeId
            LEFT JOIN dbo.DeprNonDeprTangibleAssets dnta WITH (NOLOCK) ON asset.TangibleClassId = dnta.TangibleClassId
            LEFT JOIN dbo.TangibleClass atc WITH (NOLOCK) ON dnta.TangibleClassId = atc.TangibleClassId
            LEFT JOIN dbo.GLAccount calGL WITH (NOLOCK) ON dnta.CalibratedGLAccountId = calGL.GLAccountId
            LEFT JOIN dbo.GLAccount dntaDeprGL WITH (NOLOCK) ON dnta.DeprExpenseGLAccountId = dntaDeprGL.GLAccountId
            LEFT JOIN dbo.GLAccount dntaAdGL WITH (NOLOCK) ON dnta.AccumDeprGLAccountId = dntaAdGL.GLAccountId
            LEFT JOIN dbo.AssetLocation aloc WITH (NOLOCK) ON asset.AssetLocationId = aloc.AssetLocationId
            LEFT JOIN dbo.AssetDepreciationMethod asdm WITH (NOLOCK) ON dnta.AssetDeprMethodId = asdm.AssetDepreciationMethodId
            LEFT JOIN dbo.AssetDepreciationFrequency asdf WITH (NOLOCK) ON dnta.DepreciationFrequencyId = asdf.AssetDepreciationFrequencyId
            LEFT JOIN dbo.[Percent] per WITH (NOLOCK) ON dnta.ResidualPercentage = per.PercentId
            LEFT JOIN dbo.GLAccount accGL WITH (NOLOCK) ON dnta.AcquiredGLAccountId = accGL.GLAccountId
            LEFT JOIN dbo.GLAccount deprGL WITH (NOLOCK) ON asty.DeprExpenseGLAccountId = deprGL.GLAccountId
            LEFT JOIN dbo.GLAccount addeppsGL WITH (NOLOCK) ON asty.AdDepsGLAccountId = addeppsGL.GLAccountId
            LEFT JOIN dbo.GLAccount assGL WITH (NOLOCK) ON dnta.AssetSaleGLAccountId = assGL.GLAccountId
            LEFT JOIN dbo.GLAccount aswGL WITH (NOLOCK) ON dnta.AssetWriteOffGLAccountId = aswGL.GLAccountId
            LEFT JOIN dbo.GLAccount aswdGL WITH (NOLOCK) ON dnta.AssetWriteDownGLAccountId = aswdGL.GLAccountId
            WHERE asset.AssetRecordId = @assetRecordId;
        END
    END TRY
    BEGIN CATCH
        DECLARE @ErrorLogID INT,
                @DatabaseName VARCHAR(100) = DB_NAME(),
                @AdhocComments VARCHAR(150) = 'USP_GetAssetDataforInventory',
                @ProcedureParameters VARCHAR(3000) = '@assetRecordId = ' + CAST(@assetRecordId AS VARCHAR),
                @ApplicationName VARCHAR(100) = 'PAS';

        EXEC spLogException
            @DatabaseName = @DatabaseName,
            @AdhocComments = @AdhocComments,
            @ProcedureParameters = @ProcedureParameters,
            @ApplicationName = @ApplicationName,
            @ErrorLogID = @ErrorLogID OUTPUT;

        RAISERROR('Unexpected Error Occurred in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID);
        RETURN (1);
    END CATCH
END;