/*************************************************************
 ** File:   [USP_CopyStocklineAssetDetailsFromRO]
 ** Author: Rajesh Gami
 ** Description: [PN-18407] Asset and Lease Configuration in Stockline - RO Receiving of an Asset stockline.
 **              The stockline received back from the RO (created from the Stock receiving draft) stays Asset:
 **              IsAsset + all asset fields are copied from the RO part's original stockline, it gets a new
 **              Asset Inventory Num (Asset Inventory code prefix) and AssetTotalCost is recalculated with its own
 **              Unit Cost / Qty. Only RO parts with isAsset = 0 (Stockline) are used - Asset Inventory RO is not touched.
 **              Accounting stays the normal RO receive posting.
 ** Purpose:
 ** Date:   30/October/2026
 ** PARAMETERS: @RepairOrderId BIGINT, @UpdatedBy VARCHAR(256)
 ** RETURN VALUE:
 **************************************************************
 ** Change History
 **************************************************************
 ** PR   Date            Author          Change Description
 ** --   --------        -------         --------------------------------
    1    30/October/2026 RAJESH GAMI     Created [PN-18407]
**************************************************************/
CREATE   PROCEDURE [dbo].[USP_CopyStocklineAssetDetailsFromRO]
	@RepairOrderId BIGINT,
	@UpdatedBy     VARCHAR(256) = NULL
AS
BEGIN
	SET NOCOUNT ON;
	BEGIN TRY
		DECLARE @AssetInventoryNumberCodeType INT = 37; -- CodePrefixEnum.AssetInventoryNumber
		DECLARE @ReceivedStocklineId BIGINT, @OriginalStocklineId BIGINT, @MasterCompanyId INT,
		        @AssetCodePrefixId BIGINT, @AssetCurrentNumber BIGINT, @AssetCodePrefix VARCHAR(50), @AssetCodeSuffix VARCHAR(50),
		        @AssetInventoryNumber VARCHAR(100);

		IF OBJECT_ID('tempdb..#ReceivedAssetStockline') IS NOT NULL DROP TABLE #ReceivedAssetStockline;

		SELECT ReceivedStockline.StockLineId AS ReceivedStocklineId,
		       OriginalStockline.StockLineId AS OriginalStocklineId,
		       ReceivedStockline.MasterCompanyId
		INTO #ReceivedAssetStockline
		FROM dbo.Stockline ReceivedStockline WITH (NOLOCK)
		JOIN dbo.RepairOrderPart RepairOrderPart WITH (NOLOCK) ON RepairOrderPart.RepairOrderPartRecordId = ReceivedStockline.RepairOrderPartRecordId
		JOIN dbo.Stockline OriginalStockline WITH (NOLOCK) ON OriginalStockline.StockLineId = RepairOrderPart.StockLineId
		WHERE ReceivedStockline.RepairOrderId = @RepairOrderId
		  AND ISNULL(ReceivedStockline.IsDeleted, 0) = 0
		  AND ISNULL(ReceivedStockline.IsAsset, 0) = 0
		  AND ISNULL(RepairOrderPart.IsAsset, 0) = 0
		  AND ISNULL(OriginalStockline.IsAsset, 0) = 1
		  AND OriginalStockline.StockLineId <> ReceivedStockline.StockLineId;

		WHILE EXISTS (SELECT 1 FROM #ReceivedAssetStockline)
		BEGIN
			SELECT TOP 1 @ReceivedStocklineId = ReceivedStocklineId, @OriginalStocklineId = OriginalStocklineId, @MasterCompanyId = MasterCompanyId
			FROM #ReceivedAssetStockline ORDER BY ReceivedStocklineId;

			SELECT @AssetCodePrefixId = NULL, @AssetCurrentNumber = NULL, @AssetCodePrefix = NULL, @AssetCodeSuffix = NULL, @AssetInventoryNumber = NULL;
			SELECT TOP 1 @AssetCodePrefixId = CodePrefixId, @AssetCurrentNumber = ISNULL(CurrentNummber, 0) + 1,
			       @AssetCodePrefix = CodePrefix, @AssetCodeSuffix = CodeSufix
			FROM dbo.CodePrefixes WITH (NOLOCK)
			WHERE CodeTypeId = @AssetInventoryNumberCodeType AND MasterCompanyId = @MasterCompanyId AND IsActive = 1 AND IsDeleted = 0;

			IF (@AssetCodePrefixId IS NOT NULL)
			BEGIN
				UPDATE dbo.CodePrefixes SET CurrentNummber = @AssetCurrentNumber WHERE CodePrefixId = @AssetCodePrefixId;
				SET @AssetInventoryNumber = (SELECT TOP 1 StocklineNumber FROM dbo.udfGenerateCodeNumber(@AssetCurrentNumber, @AssetCodePrefix, @AssetCodeSuffix));
			END

			UPDATE ReceivedStockline SET
			ReceivedStockline.IsAsset                           = 1,
			ReceivedStockline.AssetInventoryNumber              = @AssetInventoryNumber,
			ReceivedStockline.IsLease                           = OriginalStockline.IsLease,
			ReceivedStockline.AssetName                         = OriginalStockline.AssetName,
			ReceivedStockline.AssetManufacturerPN               = OriginalStockline.AssetManufacturerPN,
			ReceivedStockline.AssetStatusId                     = OriginalStockline.AssetStatusId,
			ReceivedStockline.AssetInventoryStatusId            = OriginalStockline.AssetInventoryStatusId,
			ReceivedStockline.AssetAvailableStatusId            = OriginalStockline.AssetAvailableStatusId,
			ReceivedStockline.AssetAvailStatus                  = OriginalStockline.AssetAvailStatus,
			ReceivedStockline.AssetIsTangible                   = OriginalStockline.AssetIsTangible,
			ReceivedStockline.AssetIsIntangible                 = OriginalStockline.AssetIsIntangible,
			ReceivedStockline.AssetIsDepreciable                = OriginalStockline.AssetIsDepreciable,
			ReceivedStockline.AssetIsNonDepreciable             = OriginalStockline.AssetIsNonDepreciable,
			ReceivedStockline.AssetIsAmortizable                = OriginalStockline.AssetIsAmortizable,
			ReceivedStockline.AssetIsNonAmortizable             = OriginalStockline.AssetIsNonAmortizable,
			ReceivedStockline.AssetTangibleClassId              = OriginalStockline.AssetTangibleClassId,
			ReceivedStockline.AssetDeprNonDeprTangibleAssetsId  = OriginalStockline.AssetDeprNonDeprTangibleAssetsId,
			ReceivedStockline.AssetAttributeTypeId              = OriginalStockline.AssetAttributeTypeId,
			ReceivedStockline.AssetIntangibleTypeId             = OriginalStockline.AssetIntangibleTypeId,
			ReceivedStockline.AssetAlternateItemMasterId        = OriginalStockline.AssetAlternateItemMasterId,
			ReceivedStockline.AssetParentItemMasterId           = OriginalStockline.AssetParentItemMasterId,
			ReceivedStockline.AssetDepreciationStartDate        = OriginalStockline.AssetDepreciationStartDate,
			ReceivedStockline.AssetStatusNote                   = OriginalStockline.AssetStatusNote,
			ReceivedStockline.AssetLocationId                   = OriginalStockline.AssetLocationId,
			ReceivedStockline.AssetFreight                      = OriginalStockline.AssetFreight,
			ReceivedStockline.AssetInsurance                    = OriginalStockline.AssetInsurance,
			ReceivedStockline.AssetTaxes                        = OriginalStockline.AssetTaxes,
			ReceivedStockline.AssetInstallationCost             = OriginalStockline.AssetInstallationCost,
			ReceivedStockline.DepreciationMethodId              = OriginalStockline.DepreciationMethodId,
			ReceivedStockline.DepreciationMethodName            = OriginalStockline.DepreciationMethodName,
			ReceivedStockline.ResidualPercentageId              = OriginalStockline.ResidualPercentageId,
			ReceivedStockline.ResidualPercentage                = OriginalStockline.ResidualPercentage,
			ReceivedStockline.DepreciationFrequencyId           = OriginalStockline.DepreciationFrequencyId,
			ReceivedStockline.DepreciationFrequencyName         = OriginalStockline.DepreciationFrequencyName,
			ReceivedStockline.AssetLife                         = OriginalStockline.AssetLife,
			ReceivedStockline.AcquiredGLAccountId               = OriginalStockline.AcquiredGLAccountId,
			ReceivedStockline.AcquiredGLAccountName             = OriginalStockline.AcquiredGLAccountName,
			ReceivedStockline.DeprExpenseGLAccountId            = OriginalStockline.DeprExpenseGLAccountId,
			ReceivedStockline.DeprExpenseGLAccountName          = OriginalStockline.DeprExpenseGLAccountName,
			ReceivedStockline.AdDepsGLAccountId                 = OriginalStockline.AdDepsGLAccountId,
			ReceivedStockline.AdDepsGLAccountName               = OriginalStockline.AdDepsGLAccountName,
			ReceivedStockline.AssetSaleGLAccountId              = OriginalStockline.AssetSaleGLAccountId,
			ReceivedStockline.AssetSaleGLAccountName            = OriginalStockline.AssetSaleGLAccountName,
			ReceivedStockline.AssetWriteOffGLAccountId          = OriginalStockline.AssetWriteOffGLAccountId,
			ReceivedStockline.AssetWriteOffGLAccountName        = OriginalStockline.AssetWriteOffGLAccountName,
			ReceivedStockline.AssetWriteDownGLAccountId         = OriginalStockline.AssetWriteDownGLAccountId,
			ReceivedStockline.AssetWriteDownGLAccountName       = OriginalStockline.AssetWriteDownGLAccountName,
			ReceivedStockline.CalibratedGLAccountId             = OriginalStockline.CalibratedGLAccountId,
			ReceivedStockline.CalibratedGLAccountName           = OriginalStockline.CalibratedGLAccountName,
			ReceivedStockline.IntangibleGLAccountId             = OriginalStockline.IntangibleGLAccountId,
			ReceivedStockline.IntangibleGLAccountName           = OriginalStockline.IntangibleGLAccountName,
			ReceivedStockline.AmortExpenseGLAccountId           = OriginalStockline.AmortExpenseGLAccountId,
			ReceivedStockline.AmortExpenseGLAccountName         = OriginalStockline.AmortExpenseGLAccountName,
			ReceivedStockline.AccAmortDeprGLAccountId           = OriginalStockline.AccAmortDeprGLAccountId,
			ReceivedStockline.AccAmortDeprGLAccountName         = OriginalStockline.AccAmortDeprGLAccountName,
			ReceivedStockline.IntangibleWriteOffGLAccountId     = OriginalStockline.IntangibleWriteOffGLAccountId,
			ReceivedStockline.IntangibleWriteOffGLAccountName   = OriginalStockline.IntangibleWriteOffGLAccountName,
			ReceivedStockline.IntangibleWriteDownGLAccountId    = OriginalStockline.IntangibleWriteDownGLAccountId,
			ReceivedStockline.IntangibleWriteDownGLAccountName  = OriginalStockline.IntangibleWriteDownGLAccountName,
			ReceivedStockline.MaintenanceGLAccountId            = OriginalStockline.MaintenanceGLAccountId,
			ReceivedStockline.MaintenanceGLAccountName          = OriginalStockline.MaintenanceGLAccountName,
			ReceivedStockline.WarrantyGLAccountId               = OriginalStockline.WarrantyGLAccountId,
			ReceivedStockline.WarrantyGLAccountName             = OriginalStockline.WarrantyGLAccountName,
			ReceivedStockline.CalibrationGlAccountId            = OriginalStockline.CalibrationGlAccountId,
			ReceivedStockline.CalibrationGlAccountName          = OriginalStockline.CalibrationGlAccountName,
			ReceivedStockline.CertificationGlAccountId          = OriginalStockline.CertificationGlAccountId,
			ReceivedStockline.CertificationGlAccountName        = OriginalStockline.CertificationGlAccountName,
			ReceivedStockline.InspectionGlaAccountId            = OriginalStockline.InspectionGlaAccountId,
			ReceivedStockline.InspectionGlaAccountName          = OriginalStockline.InspectionGlaAccountName,
			ReceivedStockline.VerificationGlAccountId           = OriginalStockline.VerificationGlAccountId,
			ReceivedStockline.VerificationGlAccountName         = OriginalStockline.VerificationGlAccountName,
			ReceivedStockline.CalibrationRequired               = OriginalStockline.CalibrationRequired,
			ReceivedStockline.CalibrationDefaultVendorId        = OriginalStockline.CalibrationDefaultVendorId,
			ReceivedStockline.CalibrationFrequencyMonths        = OriginalStockline.CalibrationFrequencyMonths,
			ReceivedStockline.CalibrationFrequencyDays          = OriginalStockline.CalibrationFrequencyDays,
			ReceivedStockline.CalibrationDefaultCost            = OriginalStockline.CalibrationDefaultCost,
			ReceivedStockline.CalibrationCurrencyId             = OriginalStockline.CalibrationCurrencyId,
			ReceivedStockline.CalibrationProvider               = OriginalStockline.CalibrationProvider,
			ReceivedStockline.CalibrationInternallyById         = OriginalStockline.CalibrationInternallyById,
			ReceivedStockline.CalibrationPerformedById          = OriginalStockline.CalibrationPerformedById,
			ReceivedStockline.LastCalibrationDate               = OriginalStockline.LastCalibrationDate,
			ReceivedStockline.NextCalibrationDate               = OriginalStockline.NextCalibrationDate,
			ReceivedStockline.CalibrationMemo                   = OriginalStockline.CalibrationMemo,
			ReceivedStockline.CertificationRequired             = OriginalStockline.CertificationRequired,
			ReceivedStockline.CertificationDefaultVendorId      = OriginalStockline.CertificationDefaultVendorId,
			ReceivedStockline.CertificationFrequencyMonths      = OriginalStockline.CertificationFrequencyMonths,
			ReceivedStockline.CertificationFrequencyDays        = OriginalStockline.CertificationFrequencyDays,
			ReceivedStockline.CertificationDefaultCost          = OriginalStockline.CertificationDefaultCost,
			ReceivedStockline.CertificationCurrencyId           = OriginalStockline.CertificationCurrencyId,
			ReceivedStockline.CertificationProvider             = OriginalStockline.CertificationProvider,
			ReceivedStockline.CertificationInternallyById       = OriginalStockline.CertificationInternallyById,
			ReceivedStockline.CertificationPerformedById        = OriginalStockline.CertificationPerformedById,
			ReceivedStockline.LastCertificationDate             = OriginalStockline.LastCertificationDate,
			ReceivedStockline.NextCertificationDate             = OriginalStockline.NextCertificationDate,
			ReceivedStockline.CertificationMemo                 = OriginalStockline.CertificationMemo,
			ReceivedStockline.InspectionRequired                = OriginalStockline.InspectionRequired,
			ReceivedStockline.InspectionDefaultVendorId         = OriginalStockline.InspectionDefaultVendorId,
			ReceivedStockline.InspectionFrequencyMonths         = OriginalStockline.InspectionFrequencyMonths,
			ReceivedStockline.InspectionFrequencyDays           = OriginalStockline.InspectionFrequencyDays,
			ReceivedStockline.InspectionDefaultCost             = OriginalStockline.InspectionDefaultCost,
			ReceivedStockline.InspectionCurrencyId              = OriginalStockline.InspectionCurrencyId,
			ReceivedStockline.InspectionProvider                = OriginalStockline.InspectionProvider,
			ReceivedStockline.InspectionInternallyById          = OriginalStockline.InspectionInternallyById,
			ReceivedStockline.InspectionPerformedById           = OriginalStockline.InspectionPerformedById,
			ReceivedStockline.LastInspectionDate                = OriginalStockline.LastInspectionDate,
			ReceivedStockline.NextInspectionDate                = OriginalStockline.NextInspectionDate,
			ReceivedStockline.InspectionMemo                    = OriginalStockline.InspectionMemo,
			ReceivedStockline.VerificationRequired              = OriginalStockline.VerificationRequired,
			ReceivedStockline.VerificationDefaultVendorId       = OriginalStockline.VerificationDefaultVendorId,
			ReceivedStockline.VerificationFrequencyMonths       = OriginalStockline.VerificationFrequencyMonths,
			ReceivedStockline.VerificationFrequencyDays         = OriginalStockline.VerificationFrequencyDays,
			ReceivedStockline.VerificationDefaultCost           = OriginalStockline.VerificationDefaultCost,
			ReceivedStockline.VerificationCurrencyId            = OriginalStockline.VerificationCurrencyId,
			ReceivedStockline.VerificationProvider              = OriginalStockline.VerificationProvider,
			ReceivedStockline.VerificationInternallyById        = OriginalStockline.VerificationInternallyById,
			ReceivedStockline.VerificationPerformedById         = OriginalStockline.VerificationPerformedById,
			ReceivedStockline.LastVerificationDate              = OriginalStockline.LastVerificationDate,
			ReceivedStockline.NextVerificationDate              = OriginalStockline.NextVerificationDate,
			ReceivedStockline.VerificationMemo                  = OriginalStockline.VerificationMemo,
			ReceivedStockline.AssetCalibrationMin               = OriginalStockline.AssetCalibrationMin,
			ReceivedStockline.AssetCalibrationMinTolerance      = OriginalStockline.AssetCalibrationMinTolerance,
			ReceivedStockline.AssetCalibratonMax                = OriginalStockline.AssetCalibratonMax,
			ReceivedStockline.AssetCalibrationMaxTolerance      = OriginalStockline.AssetCalibrationMaxTolerance,
			ReceivedStockline.AssetCalibrationExpected          = OriginalStockline.AssetCalibrationExpected,
			ReceivedStockline.AssetCalibrationExpectedTolerance = OriginalStockline.AssetCalibrationExpectedTolerance,
			ReceivedStockline.AssetCalibrationMemo              = OriginalStockline.AssetCalibrationMemo,
			ReceivedStockline.CalibrationCertificateNumber      = OriginalStockline.CalibrationCertificateNumber,
			ReceivedStockline.AssetIsMaintenanceReqd            = OriginalStockline.AssetIsMaintenanceReqd,
			ReceivedStockline.AssetMaintenanceIsContract        = OriginalStockline.AssetMaintenanceIsContract,
			ReceivedStockline.MaintenanceFrequencyMonths        = OriginalStockline.MaintenanceFrequencyMonths,
			ReceivedStockline.MaintenanceFrequencyDays          = OriginalStockline.MaintenanceFrequencyDays,
			ReceivedStockline.MaintenanceDefaultVendorId        = OriginalStockline.MaintenanceDefaultVendorId,
			ReceivedStockline.MaintenanceMemo                   = OriginalStockline.MaintenanceMemo,
			ReceivedStockline.IsWarrantyRequired                = OriginalStockline.IsWarrantyRequired,
			ReceivedStockline.WarrantyCompany                   = OriginalStockline.WarrantyCompany,
			ReceivedStockline.WarrantyCompanyId                 = OriginalStockline.WarrantyCompanyId,
			ReceivedStockline.WarrantyCompanyName               = OriginalStockline.WarrantyCompanyName,
			ReceivedStockline.WarrantyCompanySelectId           = OriginalStockline.WarrantyCompanySelectId,
			ReceivedStockline.WarrantyDefaultVendorId           = OriginalStockline.WarrantyDefaultVendorId,
			ReceivedStockline.WarrantyStartDate                 = OriginalStockline.WarrantyStartDate,
			ReceivedStockline.WarrantyEndDate                   = OriginalStockline.WarrantyEndDate,
			ReceivedStockline.WarrantyStatusId                  = OriginalStockline.WarrantyStatusId,
			ReceivedStockline.WarrantyMemo                      = OriginalStockline.WarrantyMemo,
			ReceivedStockline.AssetTotalCost                    = (ISNULL(ReceivedStockline.UnitCost, 0) * ISNULL(ReceivedStockline.Quantity, 0)) + ISNULL(OriginalStockline.AssetFreight, 0) + ISNULL(OriginalStockline.AssetInsurance, 0) + ISNULL(OriginalStockline.AssetTaxes, 0) + ISNULL(OriginalStockline.AssetInstallationCost, 0),
			ReceivedStockline.UpdatedBy                         = ISNULL(@UpdatedBy, ReceivedStockline.UpdatedBy),
			ReceivedStockline.UpdatedDate                       = GETUTCDATE()
			FROM dbo.Stockline ReceivedStockline
			JOIN dbo.Stockline OriginalStockline ON OriginalStockline.StockLineId = @OriginalStocklineId
			WHERE ReceivedStockline.StockLineId = @ReceivedStocklineId;

			DELETE FROM #ReceivedAssetStockline WHERE ReceivedStocklineId = @ReceivedStocklineId;
		END

		IF OBJECT_ID('tempdb..#ReceivedAssetStockline') IS NOT NULL DROP TABLE #ReceivedAssetStockline;
	END TRY
	BEGIN CATCH
		DECLARE @ErrorLogID INT, @DatabaseName VARCHAR(100) = DB_NAME(),
		        @AdhocComments VARCHAR(150) = 'USP_CopyStocklineAssetDetailsFromRO',
		        @ProcedureParameters VARCHAR(3000) = '@RepairOrderId = ''' + CAST(ISNULL(@RepairOrderId, '') AS VARCHAR(100)),
		        @ApplicationName VARCHAR(100) = 'PAS';
		EXEC spLogException @DatabaseName = @DatabaseName, @AdhocComments = @AdhocComments, @ProcedureParameters = @ProcedureParameters,
		     @ApplicationName = @ApplicationName, @ErrorLogID = @ErrorLogID OUTPUT;
		RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID);
		RETURN (1);
	END CATCH
END
