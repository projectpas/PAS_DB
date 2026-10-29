/*************************************************************
 ** File:   [USP_GetStocklineAssetDetails]
 ** Author: Rajesh Gami
 ** Description: [PN-18407] Asset and Lease Configuration in Stockline - returns the Asset fields of a Stockline (Edit / View
 **              of an Asset stockline). Core Stockline fields keep coming from the existing Stockline APIs.
 **************************************************************
 ** Change History
 **************************************************************
 ** PR   Date            Author          Change Description
 ** --   --------        -------         --------------------------------
    1    27/October/2026 RAJESH GAMI     Created [PN-18407]
**************************************************************/
CREATE   PROCEDURE [dbo].[USP_GetStocklineAssetDetails]
	@StockLineId BIGINT
AS
BEGIN
	SET NOCOUNT ON;
	BEGIN TRY
		SELECT
			AssetStockline.StockLineId,
			CAST(ISNULL(AssetStockline.IsAsset,0) AS BIT) AS IsAsset,
			AssetStockline.[IsLease],
			AssetStockline.[AssetName],
			AssetStockline.[AssetManufacturerPN],
			AssetStockline.[AssetInventoryNumber],
			AssetStockline.[AssetStatusId],
			AssetStockline.[AssetInventoryStatusId],
			AssetStockline.[AssetAvailableStatusId],
			AssetStockline.[AssetAvailStatus],
			AssetStockline.[AssetIsTangible],
			AssetStockline.[AssetIsIntangible],
			AssetStockline.[AssetIsDepreciable],
			AssetStockline.[AssetIsNonDepreciable],
			AssetStockline.[AssetIsAmortizable],
			AssetStockline.[AssetIsNonAmortizable],
			AssetStockline.[AssetTangibleClassId],
			AssetStockline.[AssetDeprNonDeprTangibleAssetsId],
			AssetStockline.[AssetAttributeTypeId],
			AssetStockline.[AssetIntangibleTypeId],
			AssetStockline.[AssetAlternateItemMasterId],
			AssetStockline.[AssetParentItemMasterId],
			AssetStockline.[AssetDepreciationStartDate],
			AssetStockline.[AssetStatusNote],
			AssetStockline.[AssetLocationId],
			AssetStockline.[AssetFreight],
			AssetStockline.[AssetInsurance],
			AssetStockline.[AssetTaxes],
			AssetStockline.[AssetInstallationCost],
			AssetStockline.[AssetTotalCost],
			AssetStockline.[DepreciationMethodId],
			AssetStockline.[DepreciationMethodName],
			AssetStockline.[ResidualPercentageId],
			AssetStockline.[ResidualPercentage],
			AssetStockline.[DepreciationFrequencyId],
			AssetStockline.[DepreciationFrequencyName],
			AssetStockline.[AssetLife],
			AssetStockline.[AcquiredGLAccountId],
			AssetStockline.[AcquiredGLAccountName],
			AssetStockline.[DeprExpenseGLAccountId],
			AssetStockline.[DeprExpenseGLAccountName],
			AssetStockline.[AdDepsGLAccountId],
			AssetStockline.[AdDepsGLAccountName],
			AssetStockline.[AssetSaleGLAccountId],
			AssetStockline.[AssetSaleGLAccountName],
			AssetStockline.[AssetWriteOffGLAccountId],
			AssetStockline.[AssetWriteOffGLAccountName],
			AssetStockline.[AssetWriteDownGLAccountId],
			AssetStockline.[AssetWriteDownGLAccountName],
			AssetStockline.[CalibratedGLAccountId],
			AssetStockline.[CalibratedGLAccountName],
			AssetStockline.[IntangibleGLAccountId],
			AssetStockline.[IntangibleGLAccountName],
			AssetStockline.[AmortExpenseGLAccountId],
			AssetStockline.[AmortExpenseGLAccountName],
			AssetStockline.[AccAmortDeprGLAccountId],
			AssetStockline.[AccAmortDeprGLAccountName],
			AssetStockline.[IntangibleWriteOffGLAccountId],
			AssetStockline.[IntangibleWriteOffGLAccountName],
			AssetStockline.[IntangibleWriteDownGLAccountId],
			AssetStockline.[IntangibleWriteDownGLAccountName],
			AssetStockline.[MaintenanceGLAccountId],
			AssetStockline.[MaintenanceGLAccountName],
			AssetStockline.[WarrantyGLAccountId],
			AssetStockline.[WarrantyGLAccountName],
			AssetStockline.[CalibrationGlAccountId],
			AssetStockline.[CalibrationGlAccountName],
			AssetStockline.[CertificationGlAccountId],
			AssetStockline.[CertificationGlAccountName],
			AssetStockline.[InspectionGlaAccountId],
			AssetStockline.[InspectionGlaAccountName],
			AssetStockline.[VerificationGlAccountId],
			AssetStockline.[VerificationGlAccountName],
			AssetStockline.[CalibrationRequired],
			AssetStockline.[CalibrationDefaultVendorId],
			AssetStockline.[CalibrationFrequencyMonths],
			AssetStockline.[CalibrationFrequencyDays],
			AssetStockline.[CalibrationDefaultCost],
			AssetStockline.[CalibrationCurrencyId],
			AssetStockline.[CalibrationProvider],
			AssetStockline.[CalibrationInternallyById],
			AssetStockline.[CalibrationPerformedById],
			AssetStockline.[LastCalibrationDate],
			AssetStockline.[NextCalibrationDate],
			AssetStockline.[CalibrationMemo],
			AssetStockline.[CertificationRequired],
			AssetStockline.[CertificationDefaultVendorId],
			AssetStockline.[CertificationFrequencyMonths],
			AssetStockline.[CertificationFrequencyDays],
			AssetStockline.[CertificationDefaultCost],
			AssetStockline.[CertificationCurrencyId],
			AssetStockline.[CertificationProvider],
			AssetStockline.[CertificationInternallyById],
			AssetStockline.[CertificationPerformedById],
			AssetStockline.[LastCertificationDate],
			AssetStockline.[NextCertificationDate],
			AssetStockline.[CertificationMemo],
			AssetStockline.[InspectionRequired],
			AssetStockline.[InspectionDefaultVendorId],
			AssetStockline.[InspectionFrequencyMonths],
			AssetStockline.[InspectionFrequencyDays],
			AssetStockline.[InspectionDefaultCost],
			AssetStockline.[InspectionCurrencyId],
			AssetStockline.[InspectionProvider],
			AssetStockline.[InspectionInternallyById],
			AssetStockline.[InspectionPerformedById],
			AssetStockline.[LastInspectionDate],
			AssetStockline.[NextInspectionDate],
			AssetStockline.[InspectionMemo],
			AssetStockline.[VerificationRequired],
			AssetStockline.[VerificationDefaultVendorId],
			AssetStockline.[VerificationFrequencyMonths],
			AssetStockline.[VerificationFrequencyDays],
			AssetStockline.[VerificationDefaultCost],
			AssetStockline.[VerificationCurrencyId],
			AssetStockline.[VerificationProvider],
			AssetStockline.[VerificationInternallyById],
			AssetStockline.[VerificationPerformedById],
			AssetStockline.[LastVerificationDate],
			AssetStockline.[NextVerificationDate],
			AssetStockline.[VerificationMemo],
			AssetStockline.[AssetCalibrationMin],
			AssetStockline.[AssetCalibrationMinTolerance],
			AssetStockline.[AssetCalibratonMax],
			AssetStockline.[AssetCalibrationMaxTolerance],
			AssetStockline.[AssetCalibrationExpected],
			AssetStockline.[AssetCalibrationExpectedTolerance],
			AssetStockline.[AssetCalibrationMemo],
			AssetStockline.[CalibrationCertificateNumber],
			AssetStockline.[AssetIsMaintenanceReqd],
			AssetStockline.[AssetMaintenanceIsContract],
			AssetStockline.[MaintenanceFrequencyMonths],
			AssetStockline.[MaintenanceFrequencyDays],
			AssetStockline.[MaintenanceDefaultVendorId],
			AssetStockline.[MaintenanceMemo],
			AssetStockline.[IsWarrantyRequired],
			AssetStockline.[WarrantyCompany],
			AssetStockline.[WarrantyCompanyId],
			AssetStockline.[WarrantyCompanyName],
			AssetStockline.[WarrantyCompanySelectId],
			AssetStockline.[WarrantyDefaultVendorId],
			AssetStockline.[WarrantyStartDate],
			AssetStockline.[WarrantyEndDate],
			AssetStockline.[WarrantyStatusId],
			AssetStockline.[WarrantyMemo],
			-- display names,
			AlternateAssetItem.partnumber AS AssetAlternatePartNumber,
			ParentAssetItem.partnumber    AS AssetParentPartNumber,
			AssetTangibleClass.TangibleClassName,
			AssetIntangibleClass.AssetIntangibleName,
			AssetInventoryStatusItem.[Status] AS AssetInventoryStatusName,
			AssetAvailableStatusItem.[Status] AS AssetAvailableStatusName,
			AssetStatusItem.[Name] AS AssetStatusName,
			AssetWarrantyStatusItem.WarrantyStatus AS WarrantyStatusName,
			AssetLocationItem.[Name] AS AssetLocationName,
			CalibrationVendor.VendorName AS CalibrationDefaultVendorName,
			CertificationVendor.VendorName AS CertificationDefaultVendorName,
			InspectionVendor.VendorName AS InspectionDefaultVendorName,
			VerificationVendor.VendorName AS VerificationDefaultVendorName,
			MaintenanceVendor.VendorName AS MaintenanceDefaultVendorName,
			WarrantyVendor.VendorName AS WarrantyDefaultVendorName,
			LTRIM(RTRIM(CONCAT(ISNULL(CalibrationInternallyByEmployee.FirstName,''), ' ', ISNULL(CalibrationInternallyByEmployee.LastName,'')))) AS CalibrationInternallyByName,
			LTRIM(RTRIM(CONCAT(ISNULL(CalibrationPerformedByEmployee.FirstName,''), ' ', ISNULL(CalibrationPerformedByEmployee.LastName,'')))) AS CalibrationPerformedByName,
			LTRIM(RTRIM(CONCAT(ISNULL(CertificationInternallyByEmployee.FirstName,''), ' ', ISNULL(CertificationInternallyByEmployee.LastName,'')))) AS CertificationInternallyByName,
			LTRIM(RTRIM(CONCAT(ISNULL(CertificationPerformedByEmployee.FirstName,''), ' ', ISNULL(CertificationPerformedByEmployee.LastName,'')))) AS CertificationPerformedByName,
			LTRIM(RTRIM(CONCAT(ISNULL(InspectionInternallyByEmployee.FirstName,''), ' ', ISNULL(InspectionInternallyByEmployee.LastName,'')))) AS InspectionInternallyByName,
			LTRIM(RTRIM(CONCAT(ISNULL(InspectionPerformedByEmployee.FirstName,''), ' ', ISNULL(InspectionPerformedByEmployee.LastName,'')))) AS InspectionPerformedByName,
			LTRIM(RTRIM(CONCAT(ISNULL(VerificationInternallyByEmployee.FirstName,''), ' ', ISNULL(VerificationInternallyByEmployee.LastName,'')))) AS VerificationInternallyByName,
			LTRIM(RTRIM(CONCAT(ISNULL(VerificationPerformedByEmployee.FirstName,''), ' ', ISNULL(VerificationPerformedByEmployee.LastName,'')))) AS VerificationPerformedByName
		FROM dbo.Stockline AssetStockline WITH (NOLOCK)
		LEFT JOIN dbo.ItemMaster AlternateAssetItem WITH (NOLOCK) ON AlternateAssetItem.ItemMasterId = AssetStockline.AssetAlternateItemMasterId
		LEFT JOIN dbo.ItemMaster ParentAssetItem    WITH (NOLOCK) ON ParentAssetItem.ItemMasterId    = AssetStockline.AssetParentItemMasterId
		LEFT JOIN dbo.vw_DeprNonDeprTangibleAssets AssetTangibleClass WITH (NOLOCK) ON AssetTangibleClass.DeprNonDeprTangibleAssetsId = AssetStockline.AssetDeprNonDeprTangibleAssetsId
		LEFT JOIN dbo.AssetIntangibleType AssetIntangibleClass WITH (NOLOCK) ON AssetIntangibleClass.AssetIntangibleTypeId = AssetStockline.AssetIntangibleTypeId
		LEFT JOIN dbo.AssetInventoryStatus AssetInventoryStatusItem WITH (NOLOCK) ON AssetInventoryStatusItem.AssetInventoryStatusId = AssetStockline.AssetInventoryStatusId
		LEFT JOIN dbo.AssetAvailableStatus AssetAvailableStatusItem WITH (NOLOCK) ON AssetAvailableStatusItem.AssetAvailableStatusId = AssetStockline.AssetAvailableStatusId
		LEFT JOIN dbo.AssetStatus AssetStatusItem WITH (NOLOCK) ON AssetStatusItem.AssetStatusId = AssetStockline.AssetStatusId
		LEFT JOIN dbo.AssetWarrantyStatus AssetWarrantyStatusItem WITH (NOLOCK) ON AssetWarrantyStatusItem.AssetWarrantyStatusId = AssetStockline.WarrantyStatusId
		LEFT JOIN dbo.AssetLocation AssetLocationItem WITH (NOLOCK) ON AssetLocationItem.AssetLocationId = AssetStockline.AssetLocationId
		LEFT JOIN dbo.Vendor CalibrationVendor WITH (NOLOCK) ON CalibrationVendor.VendorId = AssetStockline.CalibrationDefaultVendorId
		LEFT JOIN dbo.Vendor CertificationVendor WITH (NOLOCK) ON CertificationVendor.VendorId = AssetStockline.CertificationDefaultVendorId
		LEFT JOIN dbo.Vendor InspectionVendor WITH (NOLOCK) ON InspectionVendor.VendorId = AssetStockline.InspectionDefaultVendorId
		LEFT JOIN dbo.Vendor VerificationVendor WITH (NOLOCK) ON VerificationVendor.VendorId = AssetStockline.VerificationDefaultVendorId
		LEFT JOIN dbo.Vendor MaintenanceVendor WITH (NOLOCK) ON MaintenanceVendor.VendorId = AssetStockline.MaintenanceDefaultVendorId
		LEFT JOIN dbo.Vendor WarrantyVendor WITH (NOLOCK) ON WarrantyVendor.VendorId = AssetStockline.WarrantyDefaultVendorId
		LEFT JOIN dbo.Employee CalibrationInternallyByEmployee WITH (NOLOCK) ON CalibrationInternallyByEmployee.EmployeeId = AssetStockline.CalibrationInternallyById
		LEFT JOIN dbo.Employee CalibrationPerformedByEmployee WITH (NOLOCK) ON CalibrationPerformedByEmployee.EmployeeId = AssetStockline.CalibrationPerformedById
		LEFT JOIN dbo.Employee CertificationInternallyByEmployee WITH (NOLOCK) ON CertificationInternallyByEmployee.EmployeeId = AssetStockline.CertificationInternallyById
		LEFT JOIN dbo.Employee CertificationPerformedByEmployee WITH (NOLOCK) ON CertificationPerformedByEmployee.EmployeeId = AssetStockline.CertificationPerformedById
		LEFT JOIN dbo.Employee InspectionInternallyByEmployee WITH (NOLOCK) ON InspectionInternallyByEmployee.EmployeeId = AssetStockline.InspectionInternallyById
		LEFT JOIN dbo.Employee InspectionPerformedByEmployee WITH (NOLOCK) ON InspectionPerformedByEmployee.EmployeeId = AssetStockline.InspectionPerformedById
		LEFT JOIN dbo.Employee VerificationInternallyByEmployee WITH (NOLOCK) ON VerificationInternallyByEmployee.EmployeeId = AssetStockline.VerificationInternallyById
		LEFT JOIN dbo.Employee VerificationPerformedByEmployee WITH (NOLOCK) ON VerificationPerformedByEmployee.EmployeeId = AssetStockline.VerificationPerformedById
		WHERE AssetStockline.StockLineId = @StockLineId;
	END TRY
	BEGIN CATCH
		DECLARE @ErrorLogID INT, @DatabaseName VARCHAR(100) = DB_NAME(),
		        @AdhocComments VARCHAR(150) = 'USP_GetStocklineAssetDetails',
		        @ProcedureParameters VARCHAR(3000) = '@StockLineId = ''' + CAST(ISNULL(@StockLineId, '') AS VARCHAR(100)),
		        @ApplicationName VARCHAR(100) = 'PAS';
		EXEC spLogException @DatabaseName = @DatabaseName, @AdhocComments = @AdhocComments, @ProcedureParameters = @ProcedureParameters,
		     @ApplicationName = @ApplicationName, @ErrorLogID = @ErrorLogID OUTPUT;
		RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID);
		RETURN (1);
	END CATCH
END
