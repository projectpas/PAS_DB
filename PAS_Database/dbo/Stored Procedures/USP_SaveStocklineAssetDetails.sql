/*************************************************************
 ** File:   [USP_SaveStocklineAssetDetails]
 ** Author: Rajesh Gami
 ** Description: [PN-18407] Asset and Lease Configuration in Stockline - saves the Asset fields of a Stockline whose
 **              Type is "Asset". Called by the API right after the normal Stockline create / update
 **              (USP_CreateStockLine), so the core Stockline columns (PN, Qty, Serial, Unit Cost, Curr,
 **              Site..Bin, Management Structure, Memo) keep using the existing Stockline flow.
 **              - IsAsset = 1, IsNonStock = 0, ItemTypeId = ItemType 'Asset'
 **              - Depreciation / Amortization info and class GLs are copied from the selected class
 **                (Tangible -> vw_DeprNonDeprTangibleAssets, Intangible -> AssetIntangibleAttributeType)
 **              - Each GL Id is stored with its "Code-Name" text (Item Master / Asset GL pattern)
 **              - GLAccountId : Acquired GL (Tangible) / Intangible GL (Intangible) / Maintenance GL
 **              - AssetTotalCost = (Unit Cost x Qty) + Freight + Insurance + Taxes + Installation Cost
 **              Columns/params are generated from one list (PN-18407 cols.py) - add a new asset field
 **              there so Table / SP / API DTO stay in sync.
 **************************************************************
 ** Change History
 **************************************************************
 ** PR   Date            Author          Change Description
 ** --   --------        -------         --------------------------------
    1    27/October/2026 RAJESH GAMI     Created [PN-18407]
**************************************************************/
CREATE   PROCEDURE [dbo].[USP_SaveStocklineAssetDetails]
	@StockLineId BIGINT,
	@MasterCompanyId INT,
	@UpdatedBy VARCHAR(256),
	@IsLease                            BIT = NULL,
	@AssetName                          VARCHAR(50) = NULL,
	@AssetManufacturerPN                NVARCHAR(80) = NULL,
	@AssetInventoryNumber               VARCHAR(100) = NULL,
	@AssetStatusId                      BIGINT = NULL,
	@AssetInventoryStatusId             BIGINT = NULL,
	@AssetAvailableStatusId             BIGINT = NULL,
	@AssetAvailStatus                   VARCHAR(100) = NULL,
	@AssetIsTangible                    BIT = NULL,
	@AssetIsIntangible                  BIT = NULL,
	@AssetIsDepreciable                 BIT = NULL,
	@AssetIsNonDepreciable              BIT = NULL,
	@AssetIsAmortizable                 BIT = NULL,
	@AssetIsNonAmortizable              BIT = NULL,
	@AssetTangibleClassId               BIGINT = NULL,
	@AssetDeprNonDeprTangibleAssetsId   BIGINT = NULL,
	@AssetAttributeTypeId               BIGINT = NULL,
	@AssetIntangibleTypeId              BIGINT = NULL,
	@AssetAlternateItemMasterId         BIGINT = NULL,
	@AssetParentItemMasterId            BIGINT = NULL,
	@AssetDepreciationStartDate         DATETIME2(7) = NULL,
	@AssetFreight                       DECIMAL(18,6) = NULL,
	@AssetInsurance                     DECIMAL(18,6) = NULL,
	@AssetTaxes                         DECIMAL(18,6) = NULL,
	@AssetInstallationCost              DECIMAL(18,6) = NULL,
	@MaintenanceGLAccountId             BIGINT = NULL,
	@WarrantyGLAccountId                BIGINT = NULL,
	@CalibrationGlAccountId             BIGINT = NULL,
	@CertificationGlAccountId           BIGINT = NULL,
	@InspectionGlaAccountId             BIGINT = NULL,
	@VerificationGlAccountId            BIGINT = NULL,
	@CalibrationRequired                BIT = NULL,
	@CalibrationDefaultVendorId         BIGINT = NULL,
	@CalibrationFrequencyMonths         INT = NULL,
	@CalibrationFrequencyDays           BIGINT = NULL,
	@CalibrationDefaultCost             DECIMAL(18,6) = NULL,
	@CalibrationCurrencyId              INT = NULL,
	@CalibrationProvider                VARCHAR(20) = NULL,
	@CalibrationInternallyById          BIGINT = NULL,
	@CalibrationPerformedById           BIGINT = NULL,
	@LastCalibrationDate                DATETIME2(7) = NULL,
	@NextCalibrationDate                DATETIME2(7) = NULL,
	@CalibrationMemo                    NVARCHAR(MAX) = NULL,
	@CertificationRequired              BIT = NULL,
	@CertificationDefaultVendorId       BIGINT = NULL,
	@CertificationFrequencyMonths       INT = NULL,
	@CertificationFrequencyDays         BIGINT = NULL,
	@CertificationDefaultCost           DECIMAL(18,6) = NULL,
	@CertificationCurrencyId            INT = NULL,
	@CertificationProvider              VARCHAR(20) = NULL,
	@CertificationInternallyById        BIGINT = NULL,
	@CertificationPerformedById         BIGINT = NULL,
	@LastCertificationDate              DATETIME2(7) = NULL,
	@NextCertificationDate              DATETIME2(7) = NULL,
	@CertificationMemo                  NVARCHAR(MAX) = NULL,
	@InspectionRequired                 BIT = NULL,
	@InspectionDefaultVendorId          BIGINT = NULL,
	@InspectionFrequencyMonths          INT = NULL,
	@InspectionFrequencyDays            BIGINT = NULL,
	@InspectionDefaultCost              DECIMAL(18,6) = NULL,
	@InspectionCurrencyId               INT = NULL,
	@InspectionProvider                 VARCHAR(20) = NULL,
	@InspectionInternallyById           BIGINT = NULL,
	@InspectionPerformedById            BIGINT = NULL,
	@LastInspectionDate                 DATETIME2(7) = NULL,
	@NextInspectionDate                 DATETIME2(7) = NULL,
	@InspectionMemo                     NVARCHAR(MAX) = NULL,
	@VerificationRequired               BIT = NULL,
	@VerificationDefaultVendorId        BIGINT = NULL,
	@VerificationFrequencyMonths        INT = NULL,
	@VerificationFrequencyDays          BIGINT = NULL,
	@VerificationDefaultCost            DECIMAL(18,6) = NULL,
	@VerificationCurrencyId             INT = NULL,
	@VerificationProvider               VARCHAR(20) = NULL,
	@VerificationInternallyById         BIGINT = NULL,
	@VerificationPerformedById          BIGINT = NULL,
	@LastVerificationDate               DATETIME2(7) = NULL,
	@NextVerificationDate               DATETIME2(7) = NULL,
	@VerificationMemo                   NVARCHAR(MAX) = NULL,
	@AssetCalibrationMin                VARCHAR(30) = NULL,
	@AssetCalibrationMinTolerance       VARCHAR(30) = NULL,
	@AssetCalibratonMax                 VARCHAR(30) = NULL,
	@AssetCalibrationMaxTolerance       VARCHAR(30) = NULL,
	@AssetCalibrationExpected           VARCHAR(30) = NULL,
	@AssetCalibrationExpectedTolerance  VARCHAR(30) = NULL,
	@AssetCalibrationMemo               NVARCHAR(MAX) = NULL,
	@CalibrationCertificateNumber       NVARCHAR(500) = NULL,
	@AssetIsMaintenanceReqd             BIT = NULL,
	@AssetMaintenanceIsContract         BIT = NULL,
	@MaintenanceFrequencyMonths         INT = NULL,
	@MaintenanceFrequencyDays           BIGINT = NULL,
	@MaintenanceDefaultVendorId         BIGINT = NULL,
	@MaintenanceMemo                    NVARCHAR(MAX) = NULL,
	@IsWarrantyRequired                 BIT = NULL,
	@WarrantyCompany                    VARCHAR(100) = NULL,
	@WarrantyCompanyId                  BIGINT = NULL,
	@WarrantyCompanyName                VARCHAR(100) = NULL,
	@WarrantyCompanySelectId            INT = NULL,
	@WarrantyDefaultVendorId            BIGINT = NULL,
	@WarrantyStartDate                  DATETIME2(7) = NULL,
	@WarrantyEndDate                    DATETIME2(7) = NULL,
	@WarrantyStatusId                   BIGINT = NULL,
	@WarrantyMemo                       NVARCHAR(MAX) = NULL
AS
BEGIN
	SET NOCOUNT ON;
	BEGIN TRY
		DECLARE @AssetItemTypeId INT;
		SELECT TOP 1 @AssetItemTypeId = AssetItemType.ItemTypeId
		FROM dbo.ItemType AssetItemType WITH (NOLOCK)
		WHERE AssetItemType.[Name] = 'Asset' AND AssetItemType.MasterCompanyId = @MasterCompanyId AND ISNULL(AssetItemType.IsDeleted,0) = 0;

		IF @AssetItemTypeId IS NULL
			SELECT TOP 1 @AssetItemTypeId = AssetItemType.ItemTypeId
			FROM dbo.ItemType AssetItemType WITH (NOLOCK)
			WHERE AssetItemType.[Name] = 'Asset' AND ISNULL(AssetItemType.IsDeleted,0) = 0
			ORDER BY AssetItemType.ItemTypeId;

		SET @AssetIsTangible   = ISNULL(@AssetIsTangible, 0);
		SET @AssetIsIntangible = ISNULL(@AssetIsIntangible, 0);

		/* Depreciation / Amortization info + class GL accounts */
		DECLARE @DepreciationMethodId BIGINT, @DepreciationMethodName VARCHAR(250), @ResidualPercentageId BIGINT, @ResidualPercentage DECIMAL(18,6),
		        @DepreciationFrequencyId BIGINT, @DepreciationFrequencyName VARCHAR(250), @AssetLife INT;
		DECLARE @AcquiredGLAccountId BIGINT, @DeprExpenseGLAccountId BIGINT, @AdDepsGLAccountId BIGINT, @AssetSaleGLAccountId BIGINT, @AssetWriteOffGLAccountId BIGINT, @AssetWriteDownGLAccountId BIGINT, @CalibratedGLAccountId BIGINT, @IntangibleGLAccountId BIGINT, @AmortExpenseGLAccountId BIGINT, @AccAmortDeprGLAccountId BIGINT, @IntangibleWriteOffGLAccountId BIGINT, @IntangibleWriteDownGLAccountId BIGINT;

		IF @AssetIsTangible = 1
		BEGIN
			SELECT TOP 1
				@DepreciationMethodId      = TangibleClass.AssetDeprMethodId,
				@DepreciationMethodName    = TangibleClass.DepreciationMethodName,
				@ResidualPercentageId      = TangibleClass.ResidualPercentage,
				@ResidualPercentage        = TRY_CAST(TangibleClass.ResidualPercentageName AS DECIMAL(18,6)),
				@DepreciationFrequencyId   = TangibleClass.DepreciationFrequencyId,
				@DepreciationFrequencyName = TangibleClass.DepreciationFrequencyName,
				@AssetLife                 = TangibleClass.AssetLife,
				@AcquiredGLAccountId       = TangibleClass.AcquiredGLAccountId,
				@DeprExpenseGLAccountId    = TangibleClass.DeprExpenseGLAccountId,
				@AdDepsGLAccountId         = TangibleClass.AccumDeprGLAccountId,
				@AssetSaleGLAccountId      = TangibleClass.AssetSaleGLAccountId,
				@AssetWriteOffGLAccountId  = TangibleClass.AssetWriteOffGLAccountId,
				@AssetWriteDownGLAccountId = TangibleClass.AssetWriteDownGLAccountId,
				@CalibratedGLAccountId     = TangibleClass.CalibratedGLAccountId
			FROM dbo.vw_DeprNonDeprTangibleAssets TangibleClass WITH (NOLOCK)
			WHERE TangibleClass.MasterCompanyId = @MasterCompanyId
			  AND ((ISNULL(@AssetDeprNonDeprTangibleAssetsId,0) > 0 AND TangibleClass.DeprNonDeprTangibleAssetsId = @AssetDeprNonDeprTangibleAssetsId)
			    OR (ISNULL(@AssetDeprNonDeprTangibleAssetsId,0) = 0 AND TangibleClass.TangibleClassId = @AssetTangibleClassId AND ISNULL(TangibleClass.IsDeleted,0) = 0))
			ORDER BY TangibleClass.DeprNonDeprTangibleAssetsId DESC;
		END

		IF @AssetIsIntangible = 1
		BEGIN
			SELECT TOP 1
				@DepreciationMethodId           = IntangibleClass.AssetDepreciationMethodId,
				@DepreciationMethodName         = DepreciationMethod.AssetDepreciationMethodName,
				@DepreciationFrequencyId        = IntangibleClass.AssetAmortizationIntervalId,
				@DepreciationFrequencyName      = AmortizationInterval.AssetAmortizationIntervalName,
				@AssetLife                      = IntangibleClass.IntangibleLifeYears,
				@IntangibleGLAccountId          = IntangibleClass.IntangibleGLAccountId,
				@AmortExpenseGLAccountId        = IntangibleClass.AmortExpenseGLAccountId,
				@AccAmortDeprGLAccountId        = IntangibleClass.AccAmortDeprGLAccountId,
				@IntangibleWriteOffGLAccountId  = IntangibleClass.IntangibleWriteOffGLAccountId,
				@IntangibleWriteDownGLAccountId = IntangibleClass.IntangibleWriteDownGLAccountId
			FROM dbo.AssetIntangibleAttributeType IntangibleClass WITH (NOLOCK)
			LEFT JOIN dbo.AssetDepreciationMethod DepreciationMethod WITH (NOLOCK) ON DepreciationMethod.AssetDepreciationMethodId = IntangibleClass.AssetDepreciationMethodId
			LEFT JOIN dbo.AssetAmortizationInterval AmortizationInterval WITH (NOLOCK) ON AmortizationInterval.AssetAmortizationIntervalId = IntangibleClass.AssetAmortizationIntervalId
			WHERE IntangibleClass.AssetIntangibleTypeId = @AssetIntangibleTypeId
			  AND IntangibleClass.MasterCompanyId = @MasterCompanyId
			  AND ISNULL(IntangibleClass.IsDeleted,0) = 0
			ORDER BY IntangibleClass.AssetIntangibleAttributeTypeId DESC;
		END

		UPDATE AssetStockline SET
			AssetStockline.IsAsset    = 1,
			AssetStockline.IsNonStock = 0,
			AssetStockline.ItemTypeId = ISNULL(@AssetItemTypeId, AssetStockline.ItemTypeId),
			/* General */
			AssetStockline.IsLease                            = ISNULL(@IsLease,0),
			AssetStockline.AssetName                          = @AssetName,
			AssetStockline.AssetManufacturerPN                = UPPER(@AssetManufacturerPN),
			AssetStockline.AssetInventoryNumber               = CASE WHEN ISNULL(@AssetInventoryNumber,'') <> '' THEN @AssetInventoryNumber ELSE AssetStockline.AssetInventoryNumber END,
			AssetStockline.AssetStatusId                      = @AssetStatusId,
			AssetStockline.AssetInventoryStatusId             = @AssetInventoryStatusId,
			AssetStockline.AssetAvailableStatusId             = @AssetAvailableStatusId,
			AssetStockline.AssetAvailStatus                   = @AssetAvailStatus,
			AssetStockline.AssetIsTangible                    = @AssetIsTangible,
			AssetStockline.AssetIsIntangible                  = @AssetIsIntangible,
			AssetStockline.AssetIsDepreciable                 = CASE WHEN @AssetIsTangible = 1 THEN ISNULL(@AssetIsDepreciable,0) END,
			AssetStockline.AssetIsNonDepreciable              = CASE WHEN @AssetIsTangible = 1 THEN ISNULL(@AssetIsNonDepreciable,0) END,
			AssetStockline.AssetIsAmortizable                 = CASE WHEN @AssetIsIntangible = 1 THEN ISNULL(@AssetIsAmortizable,0) END,
			AssetStockline.AssetIsNonAmortizable              = CASE WHEN @AssetIsIntangible = 1 THEN ISNULL(@AssetIsNonAmortizable,0) END,
			AssetStockline.AssetTangibleClassId               = CASE WHEN @AssetIsTangible = 1 THEN @AssetTangibleClassId END,
			AssetStockline.AssetDeprNonDeprTangibleAssetsId   = CASE WHEN @AssetIsTangible = 1 THEN @AssetDeprNonDeprTangibleAssetsId END,
			AssetStockline.AssetAttributeTypeId               = CASE WHEN @AssetIsTangible = 1 THEN @AssetAttributeTypeId END,
			AssetStockline.AssetIntangibleTypeId              = CASE WHEN @AssetIsIntangible = 1 THEN @AssetIntangibleTypeId END,
			AssetStockline.AssetAlternateItemMasterId         = NULLIF(@AssetAlternateItemMasterId, 0),
			AssetStockline.AssetParentItemMasterId            = CASE WHEN @AssetIsTangible = 1 THEN @AssetParentItemMasterId END,
			AssetStockline.AssetDepreciationStartDate         = @AssetDepreciationStartDate,

			/* Cost */
			AssetStockline.AssetFreight                       = @AssetFreight,
			AssetStockline.AssetInsurance                     = @AssetInsurance,
			AssetStockline.AssetTaxes                         = @AssetTaxes,
			AssetStockline.AssetInstallationCost              = @AssetInstallationCost,
			AssetStockline.AssetTotalCost                     = (ISNULL(AssetStockline.UnitCost,0) * ISNULL(AssetStockline.Quantity,0)) + ISNULL(@AssetFreight,0) + ISNULL(@AssetInsurance,0) + ISNULL(@AssetTaxes,0) + ISNULL(@AssetInstallationCost,0),

			/* Depreciation */
			AssetStockline.DepreciationMethodId               = @DepreciationMethodId,
			AssetStockline.DepreciationMethodName             = @DepreciationMethodName,
			AssetStockline.ResidualPercentageId               = @ResidualPercentageId,
			AssetStockline.ResidualPercentage                 = @ResidualPercentage,
			AssetStockline.DepreciationFrequencyId            = @DepreciationFrequencyId,
			AssetStockline.DepreciationFrequencyName          = @DepreciationFrequencyName,
			AssetStockline.AssetLife                          = @AssetLife,

			/* GL */
			AssetStockline.AcquiredGLAccountId                = @AcquiredGLAccountId,
			AssetStockline.AcquiredGLAccountName              = (SELECT ISNULL(GL.AccountCode,'') + '-' + ISNULL(GL.AccountName,'') FROM dbo.GLAccount GL WITH (NOLOCK) WHERE GL.GLAccountId = NULLIF(@AcquiredGLAccountId, 0)),
			AssetStockline.DeprExpenseGLAccountId             = @DeprExpenseGLAccountId,
			AssetStockline.DeprExpenseGLAccountName           = (SELECT ISNULL(GL.AccountCode,'') + '-' + ISNULL(GL.AccountName,'') FROM dbo.GLAccount GL WITH (NOLOCK) WHERE GL.GLAccountId = NULLIF(@DeprExpenseGLAccountId, 0)),
			AssetStockline.AdDepsGLAccountId                  = @AdDepsGLAccountId,
			AssetStockline.AdDepsGLAccountName                = (SELECT ISNULL(GL.AccountCode,'') + '-' + ISNULL(GL.AccountName,'') FROM dbo.GLAccount GL WITH (NOLOCK) WHERE GL.GLAccountId = NULLIF(@AdDepsGLAccountId, 0)),
			AssetStockline.AssetSaleGLAccountId               = @AssetSaleGLAccountId,
			AssetStockline.AssetSaleGLAccountName             = (SELECT ISNULL(GL.AccountCode,'') + '-' + ISNULL(GL.AccountName,'') FROM dbo.GLAccount GL WITH (NOLOCK) WHERE GL.GLAccountId = NULLIF(@AssetSaleGLAccountId, 0)),
			AssetStockline.AssetWriteOffGLAccountId           = @AssetWriteOffGLAccountId,
			AssetStockline.AssetWriteOffGLAccountName         = (SELECT ISNULL(GL.AccountCode,'') + '-' + ISNULL(GL.AccountName,'') FROM dbo.GLAccount GL WITH (NOLOCK) WHERE GL.GLAccountId = NULLIF(@AssetWriteOffGLAccountId, 0)),
			AssetStockline.AssetWriteDownGLAccountId          = @AssetWriteDownGLAccountId,
			AssetStockline.AssetWriteDownGLAccountName        = (SELECT ISNULL(GL.AccountCode,'') + '-' + ISNULL(GL.AccountName,'') FROM dbo.GLAccount GL WITH (NOLOCK) WHERE GL.GLAccountId = NULLIF(@AssetWriteDownGLAccountId, 0)),
			AssetStockline.CalibratedGLAccountId              = @CalibratedGLAccountId,
			AssetStockline.CalibratedGLAccountName            = (SELECT ISNULL(GL.AccountCode,'') + '-' + ISNULL(GL.AccountName,'') FROM dbo.GLAccount GL WITH (NOLOCK) WHERE GL.GLAccountId = NULLIF(@CalibratedGLAccountId, 0)),
			AssetStockline.IntangibleGLAccountId              = @IntangibleGLAccountId,
			AssetStockline.IntangibleGLAccountName            = (SELECT ISNULL(GL.AccountCode,'') + '-' + ISNULL(GL.AccountName,'') FROM dbo.GLAccount GL WITH (NOLOCK) WHERE GL.GLAccountId = NULLIF(@IntangibleGLAccountId, 0)),
			AssetStockline.AmortExpenseGLAccountId            = @AmortExpenseGLAccountId,
			AssetStockline.AmortExpenseGLAccountName          = (SELECT ISNULL(GL.AccountCode,'') + '-' + ISNULL(GL.AccountName,'') FROM dbo.GLAccount GL WITH (NOLOCK) WHERE GL.GLAccountId = NULLIF(@AmortExpenseGLAccountId, 0)),
			AssetStockline.AccAmortDeprGLAccountId            = @AccAmortDeprGLAccountId,
			AssetStockline.AccAmortDeprGLAccountName          = (SELECT ISNULL(GL.AccountCode,'') + '-' + ISNULL(GL.AccountName,'') FROM dbo.GLAccount GL WITH (NOLOCK) WHERE GL.GLAccountId = NULLIF(@AccAmortDeprGLAccountId, 0)),
			AssetStockline.IntangibleWriteOffGLAccountId      = @IntangibleWriteOffGLAccountId,
			AssetStockline.IntangibleWriteOffGLAccountName    = (SELECT ISNULL(GL.AccountCode,'') + '-' + ISNULL(GL.AccountName,'') FROM dbo.GLAccount GL WITH (NOLOCK) WHERE GL.GLAccountId = NULLIF(@IntangibleWriteOffGLAccountId, 0)),
			AssetStockline.IntangibleWriteDownGLAccountId     = @IntangibleWriteDownGLAccountId,
			AssetStockline.IntangibleWriteDownGLAccountName   = (SELECT ISNULL(GL.AccountCode,'') + '-' + ISNULL(GL.AccountName,'') FROM dbo.GLAccount GL WITH (NOLOCK) WHERE GL.GLAccountId = NULLIF(@IntangibleWriteDownGLAccountId, 0)),
			AssetStockline.MaintenanceGLAccountId             = NULLIF(@MaintenanceGLAccountId, 0),
			AssetStockline.MaintenanceGLAccountName           = (SELECT ISNULL(GL.AccountCode,'') + '-' + ISNULL(GL.AccountName,'') FROM dbo.GLAccount GL WITH (NOLOCK) WHERE GL.GLAccountId = NULLIF(@MaintenanceGLAccountId, 0)),
			AssetStockline.WarrantyGLAccountId                = NULLIF(@WarrantyGLAccountId, 0),
			AssetStockline.WarrantyGLAccountName              = (SELECT ISNULL(GL.AccountCode,'') + '-' + ISNULL(GL.AccountName,'') FROM dbo.GLAccount GL WITH (NOLOCK) WHERE GL.GLAccountId = NULLIF(@WarrantyGLAccountId, 0)),
			AssetStockline.CalibrationGlAccountId             = NULLIF(@CalibrationGlAccountId, 0),
			AssetStockline.CalibrationGlAccountName           = (SELECT ISNULL(GL.AccountCode,'') + '-' + ISNULL(GL.AccountName,'') FROM dbo.GLAccount GL WITH (NOLOCK) WHERE GL.GLAccountId = NULLIF(@CalibrationGlAccountId, 0)),
			AssetStockline.CertificationGlAccountId           = NULLIF(@CertificationGlAccountId, 0),
			AssetStockline.CertificationGlAccountName         = (SELECT ISNULL(GL.AccountCode,'') + '-' + ISNULL(GL.AccountName,'') FROM dbo.GLAccount GL WITH (NOLOCK) WHERE GL.GLAccountId = NULLIF(@CertificationGlAccountId, 0)),
			AssetStockline.InspectionGlaAccountId             = NULLIF(@InspectionGlaAccountId, 0),
			AssetStockline.InspectionGlaAccountName           = (SELECT ISNULL(GL.AccountCode,'') + '-' + ISNULL(GL.AccountName,'') FROM dbo.GLAccount GL WITH (NOLOCK) WHERE GL.GLAccountId = NULLIF(@InspectionGlaAccountId, 0)),
			AssetStockline.VerificationGlAccountId            = NULLIF(@VerificationGlAccountId, 0),
			AssetStockline.VerificationGlAccountName          = (SELECT ISNULL(GL.AccountCode,'') + '-' + ISNULL(GL.AccountName,'') FROM dbo.GLAccount GL WITH (NOLOCK) WHERE GL.GLAccountId = NULLIF(@VerificationGlAccountId, 0)),

			/* Calibration */
			AssetStockline.CalibrationRequired                = ISNULL(@CalibrationRequired,0),
			AssetStockline.CalibrationDefaultVendorId         = @CalibrationDefaultVendorId,
			AssetStockline.CalibrationFrequencyMonths         = @CalibrationFrequencyMonths,
			AssetStockline.CalibrationFrequencyDays           = @CalibrationFrequencyDays,
			AssetStockline.CalibrationDefaultCost             = @CalibrationDefaultCost,
			AssetStockline.CalibrationCurrencyId              = @CalibrationCurrencyId,
			AssetStockline.CalibrationProvider                = @CalibrationProvider,
			AssetStockline.CalibrationInternallyById          = @CalibrationInternallyById,
			AssetStockline.CalibrationPerformedById           = @CalibrationPerformedById,
			AssetStockline.LastCalibrationDate                = @LastCalibrationDate,
			AssetStockline.NextCalibrationDate                = @NextCalibrationDate,
			AssetStockline.CalibrationMemo                    = @CalibrationMemo,
			AssetStockline.CertificationRequired              = ISNULL(@CertificationRequired,0),
			AssetStockline.CertificationDefaultVendorId       = @CertificationDefaultVendorId,
			AssetStockline.CertificationFrequencyMonths       = @CertificationFrequencyMonths,
			AssetStockline.CertificationFrequencyDays         = @CertificationFrequencyDays,
			AssetStockline.CertificationDefaultCost           = @CertificationDefaultCost,
			AssetStockline.CertificationCurrencyId            = @CertificationCurrencyId,
			AssetStockline.CertificationProvider              = @CertificationProvider,
			AssetStockline.CertificationInternallyById        = @CertificationInternallyById,
			AssetStockline.CertificationPerformedById         = @CertificationPerformedById,
			AssetStockline.LastCertificationDate              = @LastCertificationDate,
			AssetStockline.NextCertificationDate              = @NextCertificationDate,
			AssetStockline.CertificationMemo                  = @CertificationMemo,
			AssetStockline.InspectionRequired                 = ISNULL(@InspectionRequired,0),
			AssetStockline.InspectionDefaultVendorId          = @InspectionDefaultVendorId,
			AssetStockline.InspectionFrequencyMonths          = @InspectionFrequencyMonths,
			AssetStockline.InspectionFrequencyDays            = @InspectionFrequencyDays,
			AssetStockline.InspectionDefaultCost              = @InspectionDefaultCost,
			AssetStockline.InspectionCurrencyId               = @InspectionCurrencyId,
			AssetStockline.InspectionProvider                 = @InspectionProvider,
			AssetStockline.InspectionInternallyById           = @InspectionInternallyById,
			AssetStockline.InspectionPerformedById            = @InspectionPerformedById,
			AssetStockline.LastInspectionDate                 = @LastInspectionDate,
			AssetStockline.NextInspectionDate                 = @NextInspectionDate,
			AssetStockline.InspectionMemo                     = @InspectionMemo,
			AssetStockline.VerificationRequired               = ISNULL(@VerificationRequired,0),
			AssetStockline.VerificationDefaultVendorId        = @VerificationDefaultVendorId,
			AssetStockline.VerificationFrequencyMonths        = @VerificationFrequencyMonths,
			AssetStockline.VerificationFrequencyDays          = @VerificationFrequencyDays,
			AssetStockline.VerificationDefaultCost            = @VerificationDefaultCost,
			AssetStockline.VerificationCurrencyId             = @VerificationCurrencyId,
			AssetStockline.VerificationProvider               = @VerificationProvider,
			AssetStockline.VerificationInternallyById         = @VerificationInternallyById,
			AssetStockline.VerificationPerformedById          = @VerificationPerformedById,
			AssetStockline.LastVerificationDate               = @LastVerificationDate,
			AssetStockline.NextVerificationDate               = @NextVerificationDate,
			AssetStockline.VerificationMemo                   = @VerificationMemo,
			AssetStockline.AssetCalibrationMin                = @AssetCalibrationMin,
			AssetStockline.AssetCalibrationMinTolerance       = @AssetCalibrationMinTolerance,
			AssetStockline.AssetCalibratonMax                 = @AssetCalibratonMax,
			AssetStockline.AssetCalibrationMaxTolerance       = @AssetCalibrationMaxTolerance,
			AssetStockline.AssetCalibrationExpected           = @AssetCalibrationExpected,
			AssetStockline.AssetCalibrationExpectedTolerance  = @AssetCalibrationExpectedTolerance,
			AssetStockline.AssetCalibrationMemo               = @AssetCalibrationMemo,
			AssetStockline.CalibrationCertificateNumber       = @CalibrationCertificateNumber,

			/* Maintenance */
			AssetStockline.AssetIsMaintenanceReqd             = ISNULL(@AssetIsMaintenanceReqd,0),
			AssetStockline.AssetMaintenanceIsContract         = ISNULL(@AssetMaintenanceIsContract,0),
			AssetStockline.MaintenanceFrequencyMonths         = @MaintenanceFrequencyMonths,
			AssetStockline.MaintenanceFrequencyDays           = @MaintenanceFrequencyDays,
			AssetStockline.MaintenanceDefaultVendorId         = @MaintenanceDefaultVendorId,
			AssetStockline.MaintenanceMemo                    = @MaintenanceMemo,

			/* Warranty */
			AssetStockline.IsWarrantyRequired                 = ISNULL(@IsWarrantyRequired,0),
			AssetStockline.WarrantyCompany                    = @WarrantyCompany,
			AssetStockline.WarrantyCompanyId                  = @WarrantyCompanyId,
			AssetStockline.WarrantyCompanyName                = @WarrantyCompanyName,
			AssetStockline.WarrantyCompanySelectId            = @WarrantyCompanySelectId,
			AssetStockline.WarrantyDefaultVendorId            = @WarrantyDefaultVendorId,
			AssetStockline.WarrantyStartDate                  = @WarrantyStartDate,
			AssetStockline.WarrantyEndDate                    = @WarrantyEndDate,
			AssetStockline.WarrantyStatusId                   = @WarrantyStatusId,
			AssetStockline.WarrantyMemo                       = @WarrantyMemo,

			/* GLAccountId: Acquired GL (Tangible) / Intangible GL (Intangible) / Maintenance GL - same rule as Item Master */
			AssetStockline.GLAccountId = COALESCE(CASE WHEN @AssetIsTangible = 1 THEN @AcquiredGLAccountId
			                                           WHEN @AssetIsIntangible = 1 THEN @IntangibleGLAccountId END,
			                                      NULLIF(@MaintenanceGLAccountId, 0), AssetStockline.GLAccountId),
			AssetStockline.UpdatedBy   = @UpdatedBy,
			AssetStockline.UpdatedDate = GETUTCDATE()
		FROM dbo.Stockline AssetStockline
		WHERE AssetStockline.StockLineId = @StockLineId;

		/* keep GlAccountName and the other Stockline name columns in sync with the Ids */
		EXEC [dbo].[UpdateStocklineColumnsWithId] @StockLineId;

		SELECT @StockLineId AS StockLineId;
	END TRY
	BEGIN CATCH
		DECLARE @ErrorLogID INT, @DatabaseName VARCHAR(100) = DB_NAME(),
		        @AdhocComments VARCHAR(150) = 'USP_SaveStocklineAssetDetails',
		        @ProcedureParameters VARCHAR(3000) = '@StockLineId = ''' + CAST(ISNULL(@StockLineId, '') AS VARCHAR(100)),
		        @ApplicationName VARCHAR(100) = 'PAS';
		EXEC spLogException @DatabaseName = @DatabaseName, @AdhocComments = @AdhocComments, @ProcedureParameters = @ProcedureParameters,
		     @ApplicationName = @ApplicationName, @ErrorLogID = @ErrorLogID OUTPUT;
		RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID);
		RETURN (1);
	END CATCH
END
