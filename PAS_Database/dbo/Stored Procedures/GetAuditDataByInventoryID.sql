
/*************************************************************           
 ** File:   [GetAuditDataByInventoryID]           
 ** Author:   Abhishek Jirawla
 ** Description: This stored procedure is used retrieve Asset Inventory Audit details
 ** Purpose:         
 ** Date:   05/13/2024
          
 ** PARAMETERS: @AssetInventoryId BIGINT
         
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    05/13/2024   Abhishek Jirawla Created
     
--EXEC [GetAuditDataByInventoryID] 521
**************************************************************/
CREATE   PROCEDURE GetAuditDataByInventoryID
    @AssetInventoryId BIGINT
AS
BEGIN
   	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON  
	BEGIN TRY  

	DECLARE @ManagementStructureModuleId INT;
	SELECT @ManagementStructureModuleId = ManagementStructureModuleId FROM ManagementStructureModule WHERE ModuleName = 'AssetInventoryTangible'

	DECLARE @IsIntangible BIT;
	SELECT @IsIntangible = IsIntangible FROM AssetInventory WHERE AssetInventoryId = @AssetInventoryId

	IF (@IsIntangible = 1)
	BEGIN
		SELECT
			a.InventoryNumber,
			a.InventoryStatusId,
			ins.Status AS InventoryStatus,
			a.AssetId,
			a.AssetInventoryId,
			a.AssetRecordId,
			a.AssetStatusId,
			(SELECT p.AssetId FROM Asset p WITH(NOLOCK) WHERE p.AssetRecordId = a.AlternateAssetRecordId) AS AlternateAssetRecordId,
			(SELECT p.Name FROM AssetStatus p WITH(NOLOCK) WHERE p.AssetStatusId = a.AssetStatusId) AS AssetStatus,
			a.AssetIntangibleTypeId,
			(CASE WHEN aity.AssetIntangibleTypeId IS NULL THEN '' ELSE aity.AssetIntangibleName END) AS AssetIntangibleTypeName,
			(SELECT p.AssetId FROM Asset p WITH(NOLOCK) WHERE p.AssetRecordId = a.AssetParentRecordId) AS AssetParentRecordId,
			a.UnitOfMeasureId,
			a.ManagementStructureId,
			a.CreatedBy,
			a.CreatedDate,
			a.Description,
			a.EntryDate,
			a.IsActive,
			a.IsDeleted,
			a.IsDepreciable,
			a.IsIntangible,
			a.MasterCompanyId,
			a.MasterPartId,
			a.Memo,
			a.Name,
			a.UnexpiredTime,
			a.Amortizable,
			a.NonAmortizable,
			a.UpdatedBy,
			a.UpdatedDate,
			a.AssetLife,
			a.DepreciationMethodName AS AmortizationMethod,
			a.DepreciationFrequencyName AS AmortizationFrequency,
			(CASE WHEN asty.IntangibleLifeYears IS NULL THEN 0 ELSE asty.IntangibleLifeYears END) AS IntangibleLifeYears,
			a.AmortExpenseGLAccountName AS AmortExpenseGLAccount,
			a.AccAmortDeprGLAccountName AS AccAmortDeprGLAccount,
			a.IntangibleWriteDownGLAccountName AS IntangibleWriteDownGLAccount,
			a.IntangibleWriteOffGLAccountName AS IntangibleWriteOffGLAccount,
			a.SiteName,
			a.Warehouse,
			a.Location,
			a.ShelfName,
			a.BinName,
			(CASE WHEN AMSD.AllMSlevels IS NULL THEN '' ELSE AMSD.AllMSlevels END) AS AllMSlevels,
			(CASE WHEN AMSD.LastMSLevel IS NULL THEN '' ELSE AMSD.LastMSLevel END) AS LastMSLevel
	   FROM AssetInventoryAudit a  WITH(NOLOCK)
			LEFT JOIN AssetIntangibleType aity WITH(NOLOCK) ON a.AssetIntangibleTypeId = aity.AssetIntangibleTypeId
			LEFT JOIN AssetIntangibleAttributeType asty WITH(NOLOCK) ON a.AssetIntangibleTypeId = asty.AssetIntangibleTypeId
			LEFT JOIN AssetManagementStructureDetailsAudit AMSD WITH(NOLOCK) ON a.AssetInventoryId = AMSD.ReferenceID AND AMSD.ModuleID = @ManagementStructureModuleId
			LEFT JOIN AssetInventoryStatus ins WITH(NOLOCK) ON a.InventoryStatusId = ins.AssetInventoryStatusId
		WHERE a.AssetInventoryId = @AssetInventoryId
		ORDER BY a.UpdatedDate DESC;
	END
	ELSE
	BEGIN
		SELECT
			a.InventoryNumber,
			a.InventoryStatusId,
			ins.Status AS InventoryStatus,
			a.AssetId,
			a.AssetInventoryId,
			a.AssetRecordId,
			a.AssetStatusId,
			(SELECT p.AssetId FROM Asset p WITH(NOLOCK) WHERE p.AssetRecordId = a.AlternateAssetRecordId) AS AlternateAssetRecordId,
			(SELECT p.Name FROM AssetStatus p WITH(NOLOCK) WHERE p.AssetStatusId = a.AssetStatusId) AS AssetStatus,
			a.AssetAcquisitionTypeId,
			aacq.Name AS AcquisitionType,
			a.AssetCalibrationExpected,
			a.AssetCalibrationExpectedTolerance,
			a.SerialNo,
			manu.Name AS ManufacturerName,
			asty.AssetAttributeTypeName AS AssetType,
			uom.ShortName AS UOMShortName,
			curr.Code AS CurrencyName,
			a.isInsurance,
			a.CertificationFrequencyMonths,
			a.AssetCalibrationMinTolerance,
			a.AssetCalibrationMaxTolerance,
			a.AssetCalibrationMemo,
			a.AssetCalibrationMin,
			a.AssetCalibratonMax,
			a.AssetIntangibleTypeId,
			a.AssetIsMaintenanceReqd,
			a.AssetMaintenanceContractFile,
			a.AssetMaintenanceContractFileExt,
			a.AssetMaintenanceIsContract,
			(SELECT p.AssetId FROM Asset p WITH(NOLOCK) WHERE p.AssetRecordId = a.AssetParentRecordId) AS AssetParentRecordId,
			a.UnitOfMeasureId,
			uom.ShortName AS UnitOfMeasureName,
			a.TangibleClassId,
			a.AssetLocationId,
			(CASE WHEN alo.AssetLocationId IS NULL THEN '' ELSE CONCAT(alo.Code, '-', alo.Name) END) AS AssetLocationName,
			a.CalibrationCurrencyId,
			a.CalibrationDefaultCost,
			a.CalibrationDefaultVendorId,
			a.CalibrationFrequencyDays,
			a.CalibrationFrequencyMonths,
			a.CalibrationGlAccountId,
			(CASE WHEN caGL.GLAccountId IS NULL THEN '' ELSE CONCAT(caGL.AccountCode, '-', caGL.AccountName) END) AS CalibrationGlAccountName,
			a.CalibrationMemo,
			a.CalibrationRequired,
			a.CertificationCurrencyId,
			a.CertificationFrequencyDays,
			a.CertificationDefaultVendorId,
			a.CertificationDefaultCost,
			a.CertificationGlAccountId,
			(CASE WHEN ceGL.GLAccountId IS NULL THEN '' ELSE CONCAT(ceGL.AccountCode, '-', ceGL.AccountName) END) AS CertificationGlAccountName,
			a.CertificationMemo,
			a.CertificationRequired,
			a.CreatedBy,
			a.CreatedDate,
			a.CurrencyId,
			a.MaintenanceDefaultVendorId,
			a.WarrantyDefaultVendorId,
			a.Description,
			a.EntryDate,
			a.ExpirationDate,
			a.MaintenanceGLAccountId,
			a.WarrantyGLAccountId,
			a.InspectionCurrencyId,
			a.InspectionDefaultCost,
			a.InspectionDefaultVendorId,
			a.InspectionFrequencyDays,
			a.InspectionFrequencyMonths,
			a.InspectionGlaAccountId,
			(CASE WHEN iaGL.GLAccountId IS NULL THEN '' ELSE CONCAT(iaGL.AccountCode, '-', iaGL.AccountName) END) AS InspectionGlaAccountName,
			a.InspectionMemo,
			a.InspectionRequired,
			a.IsActive,
			a.IsDeleted,
			a.IsDepreciable,
			a.IsIntangible,
			a.IsSerialized,
			a.IsWarrantyRequired,
			a.MaintenanceFrequencyDays,
			a.MaintenanceFrequencyMonths,
			a.MaintenanceMemo,
			a.ManagementStructureId,
			a.ManufacturedDate,
			a.ManufacturerId,
			a.MasterCompanyId,
			a.MasterPartId,
			a.Memo,
			a.Model,
			a.Name,
			a.UnexpiredTime,
			a.UnitCost,
			a.InstallationCost,
			a.Freight,
			a.Insurance,
			a.TotalCost,
			a.Depreciable,
			a.NonDepreciable,
			a.Amortizable,
			a.NonAmortizable,
			a.UpdatedBy,
			a.UpdatedDate,
			a.VerificationCurrencyId,
			a.VerificationDefaultCost,
			a.VerificationDefaultVendorId,
			a.VerificationFrequencyDays,
			a.VerificationFrequencyMonths,
			a.VerificationGlAccountId,
			a.VerificationMemo,
			a.VerificationRequired,
			a.Warranty,
			a.WarrantyCompany,
			a.WarrantyEndDate,
			a.WarrantyFile,
			a.WarrantyFileExt,
			a.WarrantyStartDate,
			a.WarrantyStatusId,
			a.Taxes,
			a.WarrantyCompanyId,
			a.WarrantyCompanyName,
			(CASE WHEN wven.VendorId IS NULL THEN '' ELSE wven.VendorName END) AS WarrantyCompanyVendorName,
			a.WarrantyCompanySelectId,
			a.AssetLife,
			a.WarrantyMemo,
			(CASE WHEN vgla.GLAccountId IS NULL THEN '' ELSE CONCAT(vgla.AccountCode, '-', vgla.AccountName) END) AS VerificationGlAccountName,
			(CASE WHEN wgla.GLAccountId IS NULL THEN '' ELSE CONCAT(wgla.AccountCode, '-', wgla.AccountName) END) AS WarrantyGlAccountName,
			(CASE WHEN mgla.GLAccountId IS NULL THEN '' ELSE CONCAT(mgla.AccountCode, '-', mgla.AccountName) END) AS GLAccountName,
			(CASE WHEN asty.ConventionType IS NULL THEN 0 ELSE asty.ConventionType END) AS ConventionType,
			a.DepreciationMethodId,
			a.DepreciationMethodName AS DepreciationMethod,
			a.ResidualPercentage,
			a.ResidualPercentageId AS ResidualValue,
			a.DepreciationFrequencyId,
			a.DepreciationFrequencyName AS DepreciationFrequency,
			a.AcquiredGLAccountId,
			a.DeprExpenseGLAccountId,
			a.AdDepsGLAccountId,
			a.AdDepsGLAccountName AS AdDepsGLAccountName,
			a.AssetSaleGLAccountName AS AssetSaleGLAccountName,
			a.AssetWriteOffGLAccountName AS AssetWriteOffGLAccountName,
			a.AssetWriteDownGLAccountName AS AssetWriteDownGLAccountName,
			a.AcquiredGLAccountName AS AcquiredGLAccountName,
			a.DeprExpenseGLAccountName AS DeprExpenseGLAccountName,
			(CASE WHEN alo.AssetLocationId IS NULL THEN '' ELSE CONCAT(alo.Code, '-', alo.Name) END) AS Asset_LocationName,
			(CASE WHEN wsta.AssetWarrantyStatusId IS NULL THEN '' ELSE wsta.WarrantyStatus END) AS WarrantyStatusName,
			(CASE WHEN cave.VendorId IS NULL THEN '' ELSE cave.VendorName END) AS CalibrationDefaultVendorName,
			(CASE WHEN cacu.CurrencyId IS NULL THEN '' ELSE cacu.Code END) AS CalibrationCurrencyName,
			(CASE WHEN ceve.VendorId IS NULL THEN '' ELSE ceve.VendorName END) AS CertificationDefaultVendorName,
			(CASE WHEN cecu.CurrencyId IS NULL THEN '' ELSE cecu.Code END) AS CertificationCurrencyName,
			(CASE WHEN ive.VendorId IS NULL THEN '' ELSE ive.VendorName END) AS InspectionDefaultVendorName,
			(CASE WHEN icu.CurrencyId IS NULL THEN '' ELSE icu.Code END) AS InspectionCurrencyName,
			(CASE WHEN vve.VendorId IS NULL THEN '' ELSE vve.VendorName END) AS VerificationDefaultVendorName,
			(CASE WHEN vcu.CurrencyId IS NULL THEN '' ELSE vcu.Code END) AS VerificationCurrencyName,
			(CASE WHEN wve.VendorId IS NULL THEN '' ELSE wve.VendorName END) AS WarrantyDefaultVendorName,
			(CASE WHEN wcs.ModuleId IS NULL THEN '' ELSE wcs.ModuleName END) AS WarrantyCompanySelectName,
			(CASE WHEN dve.VendorId IS NULL THEN '' ELSE wve.VendorName END) AS DefaultVendorName,
			a.SiteName,
			a.Warehouse,
			a.Location,
			a.ShelfName,
			a.BinName,
			(CASE WHEN AMSD.AllMSlevels IS NULL THEN '' ELSE AMSD.AllMSlevels END) AS AllMSlevels,
			(CASE WHEN AMSD.LastMSLevel IS NULL THEN '' ELSE AMSD.LastMSLevel END) AS LastMSLevel
	   FROM AssetInventoryAudit a  WITH(NOLOCK)
			LEFT JOIN Manufacturer manu WITH(NOLOCK) ON a.ManufacturerId = manu.ManufacturerId
			LEFT JOIN TangibleClass at WITH(NOLOCK) ON a.TangibleClassId = at.TangibleClassId
			LEFT JOIN UnitOfMeasure uom WITH(NOLOCK) ON a.UnitOfMeasureId = uom.UnitOfMeasureId
			LEFT JOIN Currency curr WITH(NOLOCK) ON a.CurrencyId = curr.CurrencyId
			LEFT JOIN AssetAcquisitionType aacq WITH(NOLOCK) ON a.AssetAcquisitionTypeId = aacq.AssetAcquisitionTypeId
			LEFT JOIN AssetAttributeType asty WITH(NOLOCK) ON a.AssetAttributeTypeId = asty.AssetAttributeTypeId
			LEFT JOIN GLAccount caGL WITH(NOLOCK) ON a.CalibrationGlAccountId = caGL.GLAccountId
			LEFT JOIN GLAccount ceGL WITH(NOLOCK) ON a.CertificationGlAccountId = ceGL.GLAccountId
			LEFT JOIN GLAccount iaGL WITH(NOLOCK) ON a.InspectionGlaAccountId = iaGL.GLAccountId
			LEFT JOIN GLAccount vgla WITH(NOLOCK) ON a.VerificationGlAccountId = vgla.GLAccountId
			LEFT JOIN GLAccount wgla WITH(NOLOCK) ON a.WarrantyGLAccountId = wgla.GLAccountId
			LEFT JOIN GLAccount mgla WITH(NOLOCK) ON a.MaintenanceGLAccountId = mgla.GLAccountId
			LEFT JOIN AssetLocation alo WITH(NOLOCK) ON a.AssetLocationId = alo.AssetLocationId
			LEFT JOIN AssetWarrantyStatus wsta WITH(NOLOCK) ON a.WarrantyStatusId = wsta.AssetWarrantyStatusId
			LEFT JOIN Vendor cave WITH(NOLOCK) ON a.CalibrationDefaultVendorId = cave.VendorId
			LEFT JOIN Vendor ceve WITH(NOLOCK) ON a.CertificationDefaultVendorId = ceve.VendorId
			LEFT JOIN Vendor ive WITH(NOLOCK) ON a.InspectionDefaultVendorId = ive.VendorId
			LEFT JOIN Vendor vve WITH(NOLOCK) ON a.VerificationDefaultVendorId = vve.VendorId
			LEFT JOIN Vendor dve WITH(NOLOCK) ON a.MaintenanceDefaultVendorId = dve.VendorId
			LEFT JOIN Vendor wve WITH(NOLOCK) ON a.WarrantyDefaultVendorId = wve.VendorId
			LEFT JOIN Currency cacu WITH(NOLOCK) ON a.CalibrationCurrencyId = cacu.CurrencyId
			LEFT JOIN Currency cecu WITH(NOLOCK) ON a.CertificationCurrencyId = cecu.CurrencyId
			LEFT JOIN Currency icu WITH(NOLOCK) ON a.InspectionCurrencyId = icu.CurrencyId
			LEFT JOIN Currency vcu WITH(NOLOCK) ON a.VerificationCurrencyId = vcu.CurrencyId
			LEFT JOIN Module wcs WITH(NOLOCK) ON a.WarrantyCompanySelectId = wcs.ModuleId
			LEFT JOIN Vendor wven WITH(NOLOCK) ON a.WarrantyCompanyId = wven.VendorId
			LEFT JOIN AssetManagementStructureDetailsAudit AMSD WITH(NOLOCK) ON a.AssetInventoryId = AMSD.ReferenceID AND AMSD.ModuleID = @ManagementStructureModuleId
			LEFT JOIN AssetInventoryStatus ins WITH(NOLOCK) ON a.InventoryStatusId = ins.AssetInventoryStatusId
		WHERE a.AssetInventoryId = @AssetInventoryId
		ORDER BY a.UpdatedDate DESC;
	END

    

	END TRY
	BEGIN CATCH	
			DECLARE @ErrorLogID INT
			,@DatabaseName VARCHAR(100) = db_name()
			-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
			,@AdhocComments VARCHAR(150) = 'GetAuditDataByInventoryID'
			,@ProcedureParameters VARCHAR(3000) = 'AssetInventoryId = ''' + CAST(ISNULL(@AssetInventoryId, '') as varchar(100))
			,@ApplicationName VARCHAR(100) = 'PAS'
		-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
		EXEC spLogException @DatabaseName = @DatabaseName
			,@AdhocComments = @AdhocComments
			,@ProcedureParameters = @ProcedureParameters
			,@ApplicationName = @ApplicationName
			,@ErrorLogID = @ErrorLogID OUTPUT;

		RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)
		RETURN (1);

	END CATCH
END;