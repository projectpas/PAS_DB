/*************************************************************
 ** File:   [GetAssetDetailsByInventoryID]
 ** Author:   Abhishek Jirawla
 ** Description: This stored procedure is used to get AssetData By InventoryId
 ** Purpose:
 ** Date:    09/12/2024

 ** PARAMETERS:

 ** RETURN VALUE:

 **************************************************************
  ** Change History
 **************************************************************
 ** PR   Date         Author				Change Description
 ** --   --------     -------				--------------------------------
    1    09/12/2024   Abhishek Jirawla		Created
	2    12-12-2024   ABHISHEK JIRAWLA		Change made for Asset Inventory Status and Asset Available Status
	3	 30-01-2026	  Divyesh Kathiriya		Add "CalibrationCertificateNumber"
	4	 15-07-2026	  Vishal Suthar			Fall back to DeprNonDeprTangibleAssets for AssetType
	5	 29-07-2026	  Abhishek Jirawala		Asset.AssetAttributeTypeId now always stores an AssetAttributeTypeId
											(never a DeprNonDeprTangibleAssetsId); joined dnta by its
											AssetAttributeTypeId FK instead of its own PK. Dropped the
											dnta.AssetAttributeTypeName fallback (column removed) - asty is now
											always joined so its name always resolves.

--  EXEC [GetAssetDetailsByInventoryID] 1123
**************************************************************/
CREATE     PROCEDURE [dbo].[GetAssetDetailsByInventoryID]
    @AssetInventoryId BIGINT
AS
BEGIN
    SET NOCOUNT ON;

	DECLARE @AssetInventoryInTangibleManagementStructureModuleId INT, @AssetInventoryTangibleManagementStructureModuleId INT, @CheckInInventoryStatusId INT

	SELECT @AssetInventoryInTangibleManagementStructureModuleId = ManagementStructureModuleId FROM DBO.ManagementStructureModule WITH (NOLOCK) WHERE ModuleName = 'AssetInventoryInTangible'

	SELECT @AssetInventoryTangibleManagementStructureModuleId = ManagementStructureModuleId FROM DBO.ManagementStructureModule WITH (NOLOCK) WHERE ModuleName = 'AssetInventoryTangible'

	SELECT @CheckInInventoryStatusId = AssetAvailableStatusId FROM AssetAvailableStatus WITH (NOLOCK) WHERE Status = 'CHECKED IN TO WO'

	IF EXISTS(SELECT TOP 1 * FROM DBO.AssetInventory WITH (NOLOCK) WHERE AssetInventoryId = @AssetInventoryId AND IsIntangible = 1)
	BEGIN
		PRINT 'Y'
		SELECT
			ISNULL(asset.InventoryNumber, '') AS InventoryNumber,
			ISNULL(asset.InventoryStatusId, 0) AS InventoryStatusId,
			COALESCE(ins.Status, ans.Status, '') AS InventoryStatus,
			ISNULL(asset.AssetId, 0) AS AssetId,
			ISNULL(asset.AssetInventoryId, 0) AS AssetInventoryId,
			ISNULL(asset.AssetRecordId, 0) AS AssetRecordId,
			ISNULL(asset.AssetStatusId, 0) AS AssetStatusId,
			ISNULL((SELECT TOP 1 p.Name
					FROM AssetStatus p  WITH (NOLOCK)
					WHERE p.AssetStatusId = asset.AssetStatusId), '') AS AssetStatus,
			ISNULL(asset.AlternateAssetRecordId, 0) AS AlternateAssetRecordId,
			ISNULL((SELECT TOP 1 p.AssetId
					FROM Asset p  WITH (NOLOCK)
					WHERE p.AssetRecordId = asset.AlternateAssetRecordId), 0) AS AlternateAssetRecord,
			ISNULL(asset.IsInsurance, 0) AS IsInsurance,
			ISNULL(asset.ManagementStructureId, 0) AS ManagementStructureId,
			ISNULL(asset.AssetIntangibleTypeId, 0) AS AssetIntangibleTypeId,
			ISNULL(aity.AssetIntangibleName, '') AS AssetIntangibleTypeName,
			ISNULL(asset.CreatedBy, 0) AS CreatedBy,
			ISNULL(asset.CreatedDate, GETDATE()) AS CreatedDate,
			ISNULL(asset.Description, '') AS Description,
			ISNULL(asset.EntryDate, GETDATE()) AS EntryDate,
			ISNULL(asset.IsActive, 0) AS IsActive,
			ISNULL(asset.IsDeleted, 0) AS IsDeleted,
			ISNULL(asset.IsTangible, 0) AS IsTangible,
			ISNULL(asset.IsIntangible, 0) AS IsIntangible,
			ISNULL(asset.MasterCompanyId, 0) AS MasterCompanyId,
			ISNULL(asset.MasterPartId, 0) AS MasterPartId,
			ISNULL(asset.Memo, '') AS Memo,
			ISNULL(asset.Name, '') AS Name,
			ISNULL(asset.UnexpiredTime, 0) AS UnexpiredTime,
			ISNULL(asset.IsDepreciable, 0) AS IsDepreciable,
			ISNULL(asset.IsNonDepreciable, 0) AS IsNonDepreciable,
			ISNULL(asset.IsAmortizable, 0) AS IsAmortizable,
			ISNULL(asset.IsNonAmortizable, 0) AS IsNonAmortizable,
			ISNULL(asset.UpdatedBy, 0) AS UpdatedBy,
			ISNULL(asset.UpdatedDate, GETDATE()) AS UpdatedDate,
			ISNULL(asset.AssetLife, 0) AS AssetLife,
			ISNULL(asset.Qty, 0) AS Qty,
			ISNULL(asset.AvailStatus, '') AS AvailStatus,
			ISNULL(asset.StklineNumber, '') AS StklineNumber,
			ISNULL(asset.ControlNumber, '') AS ControlNumber,
			ISNULL(asset.DepreciationMethodName, '') AS AmortizationMethod,
			ISNULL(asset.DepreciationFrequencyName, '') AS AmortizationFrequency,
			ISNULL(asty.IntangibleLifeYears, 0) AS IntangibleLife,
			--ISNULL(asset.CalibrationGLAccountName, '') AS IntangibleGLAccount,
			ISNULL(asset.IntangibleGLAccountName, '') AS IntangibleGLAccount,
			ISNULL(asset.AmortExpenseGLAccountName, '') AS AmortExpenseGLAccount,
			ISNULL(asset.AccAmortDeprGLAccountName, '') AS AccAmortDeprGLAccount,
			ISNULL(asset.IntangibleWriteDownGLAccountName, '') AS IntangibleWriteDownGLAccount,
			ISNULL(asset.IntangibleWriteOffGLAccountName, '') AS IntangibleWriteOffGLAccount,
			ISNULL(AMSD.AllMSlevels, '') AS AllMSlevels,
			ISNULL(AMSD.LastMSLevel, '') AS LastMSLevel,
			ISNULL(asset.SiteId, 0) AS SiteId,
			ISNULL(asset.WarehouseId, 0) AS WarehouseId,
			ISNULL(asset.LocationId, 0) AS LocationId,
			ISNULL(asset.ShelfId, 0) AS ShelfId,
			ISNULL(asset.BinId, 0) AS BinId,
			ISNULL(asset.SiteName, '') AS SiteName,
			ISNULL(asset.Warehouse, '') AS Warehouse,
			ISNULL(asset.Location, '') AS Location,
			ISNULL(asset.ShelfName, '') AS ShelfName,
			ISNULL(asset.BinName, '') AS BinName,
			ISNULL(asset.ReceiverNumber, '') AS ReceiverNumber,
			ISNULL(asset.ReceivedDate, GETDATE()) AS ReceivedDate,
			ISNULL(asset.StatusNote, '') AS StatusNote,
			ISNULL(wo.WorkOrderNum, '') AS WorkOrderNum,
			ISNULL(asset.DepreciationStartDate, GETDATE()) AS DepreciationStartDate
		FROM DBO.AssetInventory asset WITH (NOLOCK)
		LEFT JOIN DBO.TangibleClass at WITH (NOLOCK) ON asset.TangibleClassId = at.TangibleClassId
		LEFT JOIN DBO.AssetIntangibleType aity WITH (NOLOCK) ON asset.AssetIntangibleTypeId = aity.AssetIntangibleTypeId
		LEFT JOIN DBO.AssetIntangibleAttributeType asty WITH (NOLOCK) ON asset.AssetIntangibleTypeId = asty.AssetIntangibleTypeId
		LEFT JOIN DBO.CheckInCheckOutWorkOrderAsset ciwo
			ON asset.AssetInventoryId = ciwo.AssetInventoryId
			AND ciwo.InventoryStatusId = @CheckInInventoryStatusId -- CheckIn status
		LEFT JOIN DBO.WorkOrder wo WITH (NOLOCK) ON ciwo.WorkOrderId = wo.WorkOrderId
		LEFT JOIN DBO.AssetManagementStructureDetails AMSD
			ON asset.AssetInventoryId = AMSD.ReferenceID
			AND AMSD.ModuleID = @AssetInventoryInTangibleManagementStructureModuleId -- ManagementStructureModuleEnum.AssetInventoryInTangible
		LEFT JOIN DBO.AssetInventoryStatus ins WITH (NOLOCK) ON asset.InventoryStatusId = ins.AssetInventoryStatusId
		LEFT JOIN DBO.AssetAvailableStatus ans WITH (NOLOCK) ON asset.InventoryStatusId = ans.AssetAvailableStatusId
		WHERE asset.AssetInventoryId = @AssetInventoryId;

	END
	ELSE
	BEGIN
		PRINT 'N'
		SELECT
			asset.InventoryNumber,
			asset.InventoryStatusId,
			COALESCE(ins.Status, ans.Status, '') AS InventoryStatus,
			asset.AssetId,
			asset.AssetInventoryId,
			asset.AssetRecordId,
			asset.AlternateAssetRecordId,
			ISNULL((SELECT TOP 1 p.AssetId
					FROM Asset p  WITH (NOLOCK)
					WHERE p.AssetRecordId = asset.AlternateAssetRecordId), 0) AS AlternateAssetRecord,
			asset.AssetStatusId,
			ISNULL((SELECT TOP 1 p.Name
					FROM AssetStatus p  WITH (NOLOCK)
					WHERE p.AssetStatusId = asset.AssetStatusId), '') AS AssetStatus,
			asset.AssetAcquisitionTypeId,
			ISNULL(aacq.Name, '') AS AcquisitionType,
			asset.AssetCalibrationExpected,
			asset.AssetCalibrationExpectedTolerance,
			asset.SerialNo,
			ISNULL(manu.Name, '') AS ManufacturerName,
			ISNULL(at.TangibleClassName, '') AS AssetType,
			ISNULL(uom.ShortName, '') AS UnitOfMeasureName,
			ISNULL(curr.Code, '') AS CurrencyName,
			ISNULL(asset.IsInsurance, 0) AS IsInsurance,
			asset.CertificationFrequencyMonths,
			asset.AssetCalibrationMinTolerance,
			asset.AssetCalibrationMaxTolerance,
			ISNULL(asset.AssetCalibrationMemo, '') AS AssetCalibrationMemo,
			asset.AssetCalibrationMin,
			asset.AssetCalibratonMax,
			asset.AssetIntangibleTypeId,
			ISNULL(asset.AssetIsMaintenanceReqd, 0) AS AssetIsMaintenanceReqd,
			ISNULL(asset.AssetMaintenanceContractFile, '') AS AssetMaintenanceContractFile,
			ISNULL(asset.AssetMaintenanceContractFileExt, '') AS AssetMaintenanceContractFileExt,
			ISNULL(asset.AssetMaintenanceIsContract, 0) AS AssetMaintenanceIsContract,
			asset.AssetParentRecordId,
			ISNULL((SELECT TOP 1 p.AssetId
					FROM Asset p  WITH (NOLOCK)
					WHERE p.AssetRecordId = asset.AssetParentRecordId), 0) AS AssetParentRecord,
			asset.UnitOfMeasureId,
			ISNULL(uom.ShortName, '') AS UnitOfMeasureName,
			asset.TangibleClassId,
			asset.AssetLocationId,
			CASE
				WHEN alo.AssetLocationId IS NULL THEN ''
				ELSE CONCAT(alo.Code, '-', alo.Name)
			END AS AssetLocationName,
			asset.CalibrationCurrencyId,
			asset.CalibrationDefaultCost,
			asset.CalibrationDefaultVendorId,
			asset.CalibrationFrequencyDays,
			asset.CalibrationFrequencyMonths,
			asset.CalibratedGLAccountId CalibrationGlAccountId,
			ISNULL(asset.CalibratedGLAccountName, '') AS CalibrationGlAccount,
			--asset.CalibrationGlAccountId,
			--ISNULL(CalibrationGL.AccountName, '') AS CalibrationGlAccount,
			ISNULL(asset.CalibrationMemo, '') AS CalibrationMemo,
			ISNULL(asset.CalibrationRequired, 0) AS CalibrationRequired,
			asset.CertificationCurrencyId,
			asset.CertificationFrequencyDays,
			asset.CertificationDefaultVendorId,
			asset.CertificationDefaultCost,
			asset.CertificationGlAccountId,
			ISNULL(asset.CertificationMemo, '') AS CertificationMemo,
			ISNULL(asset.CertificationRequired, 0) AS CertificationRequired,
			asset.CreatedBy,
			asset.CreatedDate,
			asset.CurrencyId,
			asset.MaintenanceDefaultVendorId,
			asset.WarrantyDefaultVendorId,
			ISNULL(asset.Description, '') AS Description,
			asset.EntryDate,
			asset.ExpirationDate,
			asset.MaintenanceGLAccountId,
			asset.WarrantyGLAccountId,
			asset.InspectionCurrencyId,
			asset.InspectionDefaultCost,
			asset.InspectionDefaultVendorId,
			asset.InspectionFrequencyDays,
			asset.InspectionFrequencyMonths,
			asset.InspectionGlaAccountId,
			ISNULL(asset.InspectionMemo, '') AS InspectionMemo,
			ISNULL(asset.InspectionRequired, 0) AS InspectionRequired,
			ISNULL(asset.IsActive, 0) AS IsActive,
			ISNULL(asset.IsDeleted, 0) AS IsDeleted,
			ISNULL(asset.IsTangible, 0) AS IsTangible,
			ISNULL(asset.IsIntangible, 0) AS IsIntangible,
			ISNULL(asset.IsSerialized, 0) AS IsSerialized,
			ISNULL(asset.IsWarrantyRequired, 0) AS IsWarrantyRequired,
			asset.MaintenanceFrequencyDays,
			asset.MaintenanceFrequencyMonths,
			ISNULL(asset.MaintenanceMemo, '') AS MaintenanceMemo,
			asset.ManagementStructureId,
			asset.ManufacturedDate,
			asset.ManufacturerId,
			asset.MasterCompanyId,
			asset.MasterPartId,
			ISNULL(asset.Memo, '') AS Memo,
			ISNULL(asset.Model, '') AS Model,
			ISNULL(asset.Name, '') AS Name,
			asset.UnexpiredTime,
			ISNULL(asset.UnitCost, 0) AS UnitCost,
			ISNULL(asset.InstallationCost, 0) AS InstallationCost,
			ISNULL(asset.Freight, 0) AS Freight,
			ISNULL(asset.Insurance, 0) AS Insurance,
			ISNULL(asset.TotalCost, 0) AS TotalCost,
			ISNULL(ADH.AccumlatedDepr, 0) AS AccumlatedDepreciation,
			ISNULL(ADH.NetBookValue, asset.TotalCost) AS NetBookValue,
			ISNULL(asset.IsDepreciable, 0) AS IsDepreciable,
			ISNULL(asset.IsNonDepreciable, 0) AS IsNonDepreciable,
			asset.UpdatedBy,
			asset.UpdatedDate,
			asset.VerificationCurrencyId,
			asset.VerificationDefaultCost,
			asset.VerificationDefaultVendorId,
			asset.VerificationFrequencyDays,
			asset.VerificationFrequencyMonths,
			asset.VerificationGlAccountId,
			ISNULL(asset.VerificationMemo, '') AS VerificationMemo,
			ISNULL(asset.VerificationRequired, 0) AS VerificationRequired,
			asset.Warranty,
			ISNULL(asset.WarrantyCompany, '') AS WarrantyCompany,
			asset.WarrantyEndDate,
			ISNULL(asset.WarrantyFile, '') AS WarrantyFile,
			ISNULL(asset.WarrantyFileExt, '') AS WarrantyFileExt,
			asset.WarrantyStartDate,
			asset.WarrantyStatusId,
			asset.Taxes,
			asset.WarrantyCompanyId,
			ISNULL(wven.VendorName, '') AS WarrantyCompanyVendorName,
			ISNULL(asset.WarrantyCompanyName, '') AS WarrantyCompanyName,
			asset.WarrantyCompanySelectId,
			asset.AssetLife,
			ISNULL(asset.WarrantyMemo, '') AS WarrantyMemo,
			asset.Qty,
			asset.AvailStatus,
			asset.StklineNumber,
			asset.ControlNumber,
			ISNULL(CONCAT(wgla.AccountCode, '-', wgla.AccountName), '') AS WarrantyGlAccountName,
			ISNULL(CONCAT(mgla.AccountCode, '-', mgla.AccountName), '') AS GLAccountName,
			ISNULL(asty.ConventionType, 0) AS ConventionType,
			asset.DepreciationMethodId,
			ISNULL(asset.DepreciationMethodName, '') AS DepreciationMethod,
			asset.ResidualPercentage,
			asset.ResidualPercentageId AS ResidualValue,
			asset.DepreciationFrequencyId,
			ISNULL(asset.DepreciationFrequencyName, '') AS DepreciationFrequency,
			asset.AcquiredGLAccountId,
			asset.DeprExpenseGLAccountId,
			asset.AdDepsGLAccountId,
			asset.CalibratedGLAccountId,
			ISNULL(asset.CalibratedGLAccountName, '') AS CalibratedGLAccount,
			ISNULL(asset.AdDepsGLAccountName, '') AS AdDepsGLAccount,
			ISNULL(asset.AssetSaleGLAccountName, '') AS AssetSale,
			ISNULL(asset.AssetWriteOffGLAccountName, '') AS AssetWriteOff,
			ISNULL(asset.AssetWriteDownGLAccountName, '') AS AssetWriteDown,
			ISNULL(asset.AcquiredGLAccountName, '') AS AcquiredGLAccount,
			ISNULL(asset.DeprExpenseGLAccountName, '') AS DeprExpenseGLAccount,
			ISNULL(wsta.WarrantyStatus, '') AS WarrantyStatusName,
			ISNULL(cal.VendorName, '') AS CalibrationDefaultVendorName,
			ISNULL(cal.CurrencyName, '') AS CalibrationCurrencyName,
			cal.LastCalibrationDate,
			cal.NextCalibrationDate,
			cal.EmployeeId,
			cal.InternallyById AS CalibrationInternallyById,
			cal.InternallyBy AS CalibrationInternallyBy,
			cal.EmployeeName AS CalibrationPerformedBy,
			ISNULL(cer.VendorName, '') AS CertificationDefaultVendorName,
			ISNULL(cer.CurrencyName, '') AS CertificationCurrencyName,
			cer.LastCalibrationDate AS LastCertificationDate,
			cer.NextCalibrationDate AS NextCertificationDate,
			cer.EmployeeId AS CertificationEmployeeId,
			cer.InternallyById AS CertificationInternallyById,
			cer.InternallyBy AS CertificationInternallyBy,
			cer.EmployeeName AS CertificationPerformedBy,
			ISNULL(insp.VendorName, '') AS InspectionDefaultVendorName,
			ISNULL(insp.CurrencyName, '') AS InspectionCurrencyName,
			insp.LastCalibrationDate AS LastInspectionDate,
			insp.NextCalibrationDate AS NextInspectionDate,
			insp.EmployeeId AS InspectionEmployeeId,
			insp.InternallyById AS InspectionInternallyById,
			insp.InternallyBy AS InspectionInternallyBy,
			insp.EmployeeName AS InspectionPerformedBy,
			ISNULL(ver.VendorName, '') AS VerificationDefaultVendorName,
			ISNULL(ver.CurrencyName, '') AS VerificationCurrencyName,
			ver.LastCalibrationDate AS LastVerificationDate,
			ver.NextCalibrationDate AS NextVerificationDate,
			ver.EmployeeId AS VerificationEmployeeId,
			ver.InternallyById AS VerificationInternallyById,
			ver.InternallyBy AS VerificationInternallyBy,
			ver.EmployeeName AS VerificationPerformedBy,
			ISNULL(dve.VendorName, '') AS DefaultVendorName,
			ISNULL(wve.VendorName, '') AS WarrantyDefaultVendorName,
			ISNULL(wcs.ModuleName, '') AS WarrantyCompanySelectName,
			asset.SiteId,
			asset.WarehouseId,
			asset.LocationId,
			asset.ShelfId,
			asset.BinId,
			ISNULL(asset.SiteName, '') AS SiteName,
			ISNULL(asset.Warehouse, '') AS Warehouse,
			ISNULL(asset.Location, '') AS Location,
			ISNULL(asset.ShelfName, '') AS ShelfName,
			ISNULL(asset.BinName, '') AS BinName,
			ISNULL(AMSD.AllMSlevels, '') AS AllMSLevels,
			ISNULL(AMSD.LastMSLevel, '') AS LastMSLevel,
			asset.ReceiverNumber,
			asset.ReceivedDate,
			ISNULL(asset.StatusNote, '') AS StatusNote,
			ISNULL(wo.WorkOrderNum, '') AS WorkOrderNum,
			asset.DepreciationStartDate,
			ISNULL(asset.CalibrationCertificateNumber,'') AS CalibrationCertificateNumber
		FROM DBO.AssetInventory asset WITH (NOLOCK)
		LEFT JOIN DBO.Manufacturer manu WITH (NOLOCK) ON asset.ManufacturerId = manu.ManufacturerId
		LEFT JOIN DBO.CalibrationManagment cal WITH (NOLOCK) ON asset.AssetInventoryId = cal.AssetInventoryId AND cal.CalibrationTypeId = 1
		LEFT JOIN DBO.CalibrationManagment cer WITH (NOLOCK) ON asset.AssetInventoryId = cer.AssetInventoryId AND cer.CalibrationTypeId = 2
		LEFT JOIN DBO.CalibrationManagment insp WITH (NOLOCK) ON asset.AssetInventoryId = insp.AssetInventoryId AND insp.CalibrationTypeId = 3
		LEFT JOIN DBO.CalibrationManagment ver WITH (NOLOCK) ON asset.AssetInventoryId = ver.AssetInventoryId AND ver.CalibrationTypeId = 4
		LEFT JOIN DBO.CheckInCheckOutWorkOrderAsset ciwo WITH (NOLOCK) ON asset.AssetInventoryId = ciwo.AssetInventoryId AND ciwo.InventoryStatusId = 1
		LEFT JOIN DBO.WorkOrder wo WITH (NOLOCK) ON ciwo.WorkOrderId = wo.WorkOrderId
		LEFT JOIN DBO.TangibleClass at WITH (NOLOCK) ON asset.TangibleClassId = at.TangibleClassId
		LEFT JOIN DBO.UnitOfMeasure uom WITH (NOLOCK) ON asset.UnitOfMeasureId = uom.UnitOfMeasureId
		LEFT JOIN DBO.Currency curr WITH (NOLOCK) ON asset.CurrencyId = curr.CurrencyId
		LEFT JOIN DBO.AssetAcquisitionType aacq WITH (NOLOCK) ON asset.AssetAcquisitionTypeId = aacq.AssetAcquisitionTypeId
		LEFT JOIN DBO.Asset astSrc WITH (NOLOCK) ON asset.AssetRecordId = astSrc.AssetRecordId
		LEFT JOIN DBO.AssetAttributeType asty WITH (NOLOCK) ON asset.AssetAttributeTypeId = asty.AssetAttributeTypeId
		LEFT JOIN DBO.DeprNonDeprTangibleAssets dnta WITH (NOLOCK) ON asset.TangibleClassId = dnta.TangibleClassId
		LEFT JOIN DBO.TangibleClass atc WITH (NOLOCK) ON asset.TangibleClassId = atc.TangibleClassId
		LEFT JOIN DBO.GLAccount wgla WITH (NOLOCK) ON asset.WarrantyGLAccountId = wgla.GLAccountId
		LEFT JOIN DBO.GLAccount mgla WITH (NOLOCK) ON asset.MaintenanceGLAccountId = mgla.GLAccountId
		LEFT JOIN DBO.AssetLocation alo WITH (NOLOCK) ON asset.AssetLocationId = alo.AssetLocationId
		LEFT JOIN DBO.AssetWarrantyStatus wsta WITH (NOLOCK) ON asset.WarrantyStatusId = wsta.AssetWarrantyStatusId
		LEFT JOIN DBO.Vendor dve WITH (NOLOCK) ON asset.MaintenanceDefaultVendorId = dve.VendorId
		LEFT JOIN DBO.Vendor wve WITH (NOLOCK) ON asset.WarrantyDefaultVendorId = wve.VendorId
		LEFT JOIN DBO.Module wcs WITH (NOLOCK) ON asset.WarrantyCompanySelectId = wcs.ModuleId
		LEFT JOIN DBO.Vendor wven WITH (NOLOCK) ON asset.WarrantyCompanyId = wven.VendorId
		LEFT JOIN DBO.AssetManagementStructureDetails AMSD WITH (NOLOCK) ON asset.AssetInventoryId = AMSD.ReferenceID AND AMSD.ModuleID = @AssetInventoryTangibleManagementStructureModuleId
		LEFT JOIN DBO.AssetInventoryStatus ins WITH (NOLOCK) ON asset.InventoryStatusId = ins.AssetInventoryStatusId
		LEFT JOIN DBO.AssetAvailableStatus ans WITH (NOLOCK) ON asset.InventoryStatusId = ans.AssetAvailableStatusId
		LEFT JOIN  [dbo].[AssetDepreciationHistory] ADH  WITH (NOLOCK) ON asset.AssetInventoryId = ADH.AssetInventoryId
			AND ADH.ID = (SELECT MAX(ID) FROM AssetDepreciationHistory  WITH (NOLOCK) WHERE IsActive = 1 AND IsDelete = 0 AND AssetInventoryId = ADH.AssetInventoryId)
		WHERE asset.AssetInventoryId = @AssetInventoryId;

	END
END;