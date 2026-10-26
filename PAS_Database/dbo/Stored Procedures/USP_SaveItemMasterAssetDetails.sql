/*************************************************************
 ** File:   [USP_SaveItemMasterAssetDetails]
 ** Author: Rajesh Gami
 ** Description: [PN-18406] Allow Asset in Item Master - saves the Asset (General Information) fields of an
 **              Item Master row whose Item Type is "Asset". Called by the API right after the Item Master
 **              general info insert (USP_AddItemMasterGeneralInfo) / update (USP_UpdateItemMaster).
 **              - ItemTypeId  : ItemType where Name = 'Asset' for the company
 **              - GL accounts : copied from the selected class, same source as Create Asset shows them
 **                              Tangible   -> DeprNonDeprTangibleAssets (Acquired, Depr Expense, Accum Depr,
 **                                            Sale, Write Off, Write Down, Calibrated)
 **                              Intangible -> AssetIntangibleAttributeType (Intangible, Amort Expense,
 **                                            Acc Amort Depr, Write Off, Write Down)
 **                              Each GL Id is stored with its "Code-Name" text (Item Master GL pattern).
 **              - GLAccountId : Acquired GL (Tangible) / Intangible GL (Intangible) / Maintenance GL (other)
 **************************************************************
 ** Change History
 **************************************************************
 ** PR   Date            Author          Change Description
 ** --   --------        -------         --------------------------------
    1    26/October/2026 RAJESH GAMI     Created [PN-18406]
**************************************************************/
CREATE   PROCEDURE [dbo].[USP_SaveItemMasterAssetDetails]
	@ItemMasterId                     BIGINT,
	@MasterCompanyId                  INT,
	@UpdatedBy                        VARCHAR(256),
	@AssetName                        VARCHAR(50) = NULL,
	@AssetManufacturerPN              NVARCHAR(80) = NULL,
	@AssetEntryDate                   DATETIME2(7) = NULL,
	@AssetIsTangible                  BIT = NULL,
	@AssetIsIntangible                BIT = NULL,
	@AssetIsDepreciable               BIT = NULL,
	@AssetIsNonDepreciable            BIT = NULL,
	@AssetIsAmortizable               BIT = NULL,
	@AssetIsNonAmortizable            BIT = NULL,
	@AssetTangibleClassId             BIGINT = NULL,
	@AssetDeprNonDeprTangibleAssetsId BIGINT = NULL,
	@AssetAttributeTypeId             BIGINT = NULL,
	@AssetClassSource                 VARCHAR(30) = NULL,
	@AssetIntangibleTypeId            BIGINT = NULL,
	@AssetAlternateItemMasterId       BIGINT = NULL,
	@AssetParentItemMasterId          BIGINT = NULL,
	@AssetControlNumber               VARCHAR(20) = NULL,
	@AssetManagementStructureId       BIGINT = NULL
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

		/* Tangible class GL accounts */
		DECLARE @AcquiredGLAccountId BIGINT, @DeprExpenseGLAccountId BIGINT, @AdDepsGLAccountId BIGINT, @AssetSaleGLAccountId BIGINT,
		        @AssetWriteOffGLAccountId BIGINT, @AssetWriteDownGLAccountId BIGINT, @CalibratedGLAccountId BIGINT;
		IF @AssetIsTangible = 1
		BEGIN
			SELECT TOP 1
				@AcquiredGLAccountId       = TangibleClass.AcquiredGLAccountId,
				@DeprExpenseGLAccountId    = TangibleClass.DeprExpenseGLAccountId,
				@AdDepsGLAccountId         = TangibleClass.AccumDeprGLAccountId,
				@AssetSaleGLAccountId      = TangibleClass.AssetSaleGLAccountId,
				@AssetWriteOffGLAccountId  = TangibleClass.AssetWriteOffGLAccountId,
				@AssetWriteDownGLAccountId = TangibleClass.AssetWriteDownGLAccountId,
				@CalibratedGLAccountId     = TangibleClass.CalibratedGLAccountId
			FROM dbo.DeprNonDeprTangibleAssets TangibleClass WITH (NOLOCK)
			WHERE TangibleClass.MasterCompanyId = @MasterCompanyId
			  AND ((ISNULL(@AssetDeprNonDeprTangibleAssetsId,0) > 0 AND TangibleClass.DeprNonDeprTangibleAssetsId = @AssetDeprNonDeprTangibleAssetsId)
			    OR (ISNULL(@AssetDeprNonDeprTangibleAssetsId,0) = 0 AND TangibleClass.TangibleClassId = @AssetTangibleClassId AND ISNULL(TangibleClass.IsDeleted,0) = 0))
			ORDER BY TangibleClass.DeprNonDeprTangibleAssetsId DESC;
		END

		/* Intangible class GL accounts */
		DECLARE @IntangibleGLAccountId BIGINT, @AmortExpenseGLAccountId BIGINT, @AccAmortDeprGLAccountId BIGINT,
		        @IntangibleWriteOffGLAccountId BIGINT, @IntangibleWriteDownGLAccountId BIGINT;
		IF @AssetIsIntangible = 1
		BEGIN
			SELECT TOP 1
				@IntangibleGLAccountId          = IntangibleClass.IntangibleGLAccountId,
				@AmortExpenseGLAccountId        = IntangibleClass.AmortExpenseGLAccountId,
				@AccAmortDeprGLAccountId        = IntangibleClass.AccAmortDeprGLAccountId,
				@IntangibleWriteOffGLAccountId  = IntangibleClass.IntangibleWriteOffGLAccountId,
				@IntangibleWriteDownGLAccountId = IntangibleClass.IntangibleWriteDownGLAccountId
			FROM dbo.AssetIntangibleAttributeType IntangibleClass WITH (NOLOCK)
			WHERE IntangibleClass.AssetIntangibleTypeId = @AssetIntangibleTypeId
			  AND IntangibleClass.MasterCompanyId = @MasterCompanyId
			  AND ISNULL(IntangibleClass.IsDeleted,0) = 0
			ORDER BY IntangibleClass.AssetIntangibleAttributeTypeId DESC;
		END

		UPDATE AssetItem SET
			AssetItem.IsAsset                          = 1,
			AssetItem.IsNonStock                       = 0,
			AssetItem.ItemTypeId                       = ISNULL(@AssetItemTypeId, AssetItem.ItemTypeId),
			AssetItem.AssetName                        = @AssetName,
			AssetItem.AssetManufacturerPN              = UPPER(@AssetManufacturerPN),
			AssetItem.AssetEntryDate                   = @AssetEntryDate,
			AssetItem.AssetIsTangible                  = @AssetIsTangible,
			AssetItem.AssetIsIntangible                = @AssetIsIntangible,
			AssetItem.AssetIsDepreciable               = CASE WHEN @AssetIsTangible = 1 THEN ISNULL(@AssetIsDepreciable,0) ELSE 0 END,
			AssetItem.AssetIsNonDepreciable            = CASE WHEN @AssetIsTangible = 1 THEN ISNULL(@AssetIsNonDepreciable,0) ELSE 0 END,
			AssetItem.AssetIsAmortizable               = CASE WHEN @AssetIsIntangible = 1 THEN ISNULL(@AssetIsAmortizable,0) ELSE 0 END,
			AssetItem.AssetIsNonAmortizable            = CASE WHEN @AssetIsIntangible = 1 THEN ISNULL(@AssetIsNonAmortizable,0) ELSE 0 END,
			AssetItem.AssetTangibleClassId             = CASE WHEN @AssetIsTangible = 1 THEN @AssetTangibleClassId END,
			AssetItem.AssetDeprNonDeprTangibleAssetsId = CASE WHEN @AssetIsTangible = 1 THEN @AssetDeprNonDeprTangibleAssetsId END,
			AssetItem.AssetAttributeTypeId             = CASE WHEN @AssetIsTangible = 1 THEN @AssetAttributeTypeId END,
			AssetItem.AssetClassSource                 = CASE WHEN @AssetIsTangible = 1 THEN @AssetClassSource END,
			AssetItem.AssetIntangibleTypeId            = CASE WHEN @AssetIsIntangible = 1 THEN @AssetIntangibleTypeId END,
			AssetItem.AssetAlternateItemMasterId       = NULLIF(@AssetAlternateItemMasterId, 0),
			AssetItem.AssetParentItemMasterId          = CASE WHEN @AssetIsTangible = 1 THEN NULLIF(@AssetParentItemMasterId, 0) END,
			AssetItem.AssetControlNumber               = CASE WHEN ISNULL(@AssetControlNumber,'') <> '' THEN @AssetControlNumber ELSE AssetItem.AssetControlNumber END,
			AssetItem.AssetManagementStructureId       = ISNULL(NULLIF(@AssetManagementStructureId, 0), AssetItem.AssetManagementStructureId),

			AssetItem.AcquiredGLAccountId              = @AcquiredGLAccountId,
			AssetItem.AcquiredGLAccountName            = (SELECT ISNULL(GL.AccountCode,'') + '-' + ISNULL(GL.AccountName,'') FROM dbo.GLAccount GL WITH (NOLOCK) WHERE GL.GLAccountId = @AcquiredGLAccountId),
			AssetItem.DeprExpenseGLAccountId           = @DeprExpenseGLAccountId,
			AssetItem.DeprExpenseGLAccountName         = (SELECT ISNULL(GL.AccountCode,'') + '-' + ISNULL(GL.AccountName,'') FROM dbo.GLAccount GL WITH (NOLOCK) WHERE GL.GLAccountId = @DeprExpenseGLAccountId),
			AssetItem.AdDepsGLAccountId                = @AdDepsGLAccountId,
			AssetItem.AdDepsGLAccountName              = (SELECT ISNULL(GL.AccountCode,'') + '-' + ISNULL(GL.AccountName,'') FROM dbo.GLAccount GL WITH (NOLOCK) WHERE GL.GLAccountId = @AdDepsGLAccountId),
			AssetItem.AssetSaleGLAccountId             = @AssetSaleGLAccountId,
			AssetItem.AssetSaleGLAccountName           = (SELECT ISNULL(GL.AccountCode,'') + '-' + ISNULL(GL.AccountName,'') FROM dbo.GLAccount GL WITH (NOLOCK) WHERE GL.GLAccountId = @AssetSaleGLAccountId),
			AssetItem.AssetWriteOffGLAccountId         = @AssetWriteOffGLAccountId,
			AssetItem.AssetWriteOffGLAccountName       = (SELECT ISNULL(GL.AccountCode,'') + '-' + ISNULL(GL.AccountName,'') FROM dbo.GLAccount GL WITH (NOLOCK) WHERE GL.GLAccountId = @AssetWriteOffGLAccountId),
			AssetItem.AssetWriteDownGLAccountId        = @AssetWriteDownGLAccountId,
			AssetItem.AssetWriteDownGLAccountName      = (SELECT ISNULL(GL.AccountCode,'') + '-' + ISNULL(GL.AccountName,'') FROM dbo.GLAccount GL WITH (NOLOCK) WHERE GL.GLAccountId = @AssetWriteDownGLAccountId),
			AssetItem.CalibratedGLAccountId            = @CalibratedGLAccountId,
			AssetItem.CalibratedGLAccountName          = (SELECT ISNULL(GL.AccountCode,'') + '-' + ISNULL(GL.AccountName,'') FROM dbo.GLAccount GL WITH (NOLOCK) WHERE GL.GLAccountId = @CalibratedGLAccountId),

			AssetItem.IntangibleGLAccountId            = @IntangibleGLAccountId,
			AssetItem.IntangibleGLAccountName          = (SELECT ISNULL(GL.AccountCode,'') + '-' + ISNULL(GL.AccountName,'') FROM dbo.GLAccount GL WITH (NOLOCK) WHERE GL.GLAccountId = @IntangibleGLAccountId),
			AssetItem.AmortExpenseGLAccountId          = @AmortExpenseGLAccountId,
			AssetItem.AmortExpenseGLAccountName        = (SELECT ISNULL(GL.AccountCode,'') + '-' + ISNULL(GL.AccountName,'') FROM dbo.GLAccount GL WITH (NOLOCK) WHERE GL.GLAccountId = @AmortExpenseGLAccountId),
			AssetItem.AccAmortDeprGLAccountId          = @AccAmortDeprGLAccountId,
			AssetItem.AccAmortDeprGLAccountName        = (SELECT ISNULL(GL.AccountCode,'') + '-' + ISNULL(GL.AccountName,'') FROM dbo.GLAccount GL WITH (NOLOCK) WHERE GL.GLAccountId = @AccAmortDeprGLAccountId),
			AssetItem.IntangibleWriteOffGLAccountId    = @IntangibleWriteOffGLAccountId,
			AssetItem.IntangibleWriteOffGLAccountName  = (SELECT ISNULL(GL.AccountCode,'') + '-' + ISNULL(GL.AccountName,'') FROM dbo.GLAccount GL WITH (NOLOCK) WHERE GL.GLAccountId = @IntangibleWriteOffGLAccountId),
			AssetItem.IntangibleWriteDownGLAccountId   = @IntangibleWriteDownGLAccountId,
			AssetItem.IntangibleWriteDownGLAccountName = (SELECT ISNULL(GL.AccountCode,'') + '-' + ISNULL(GL.AccountName,'') FROM dbo.GLAccount GL WITH (NOLOCK) WHERE GL.GLAccountId = @IntangibleWriteDownGLAccountId),

			-- Maintenance / Warranty / Calibration / Certification / Inspection / Verification GLs come from the
			-- Asset Calibration and Maintenance & Warranty tabs (not part of Item Master yet) - kept as they are.
			AssetItem.MaintenanceGLAccountName         = (SELECT ISNULL(GL.AccountCode,'') + '-' + ISNULL(GL.AccountName,'') FROM dbo.GLAccount GL WITH (NOLOCK) WHERE GL.GLAccountId = AssetItem.MaintenanceGLAccountId),

			-- GLAccountId is NOT NULL in Item Master: Acquired GL (Tangible) / Intangible GL (Intangible) / Maintenance GL
			AssetItem.GLAccountId = COALESCE(CASE WHEN @AssetIsTangible = 1 THEN @AcquiredGLAccountId
			                                      WHEN @AssetIsIntangible = 1 THEN @IntangibleGLAccountId END,
			                                 AssetItem.MaintenanceGLAccountId, AssetItem.GLAccountId),
			AssetItem.CurrencyId  = AssetItem.PurchaseCurrencyId, -- Curr (sent as Purchase Currency)
			AssetItem.UpdatedBy   = @UpdatedBy,
			AssetItem.UpdatedDate = GETUTCDATE()
		FROM dbo.ItemMaster AssetItem
		WHERE AssetItem.ItemMasterId = @ItemMasterId;

		EXEC [dbo].[UpdateItemMasterDetail] @ItemMasterId;

		SELECT @ItemMasterId AS ItemMasterId;
	END TRY
	BEGIN CATCH
		DECLARE @ErrorLogID INT, @DatabaseName VARCHAR(100) = DB_NAME(),
		        @AdhocComments VARCHAR(150) = 'USP_SaveItemMasterAssetDetails',
		        @ProcedureParameters VARCHAR(3000) = '@ItemMasterId = ''' + CAST(ISNULL(@ItemMasterId, '') AS VARCHAR(100)),
		        @ApplicationName VARCHAR(100) = 'PAS';
		EXEC spLogException @DatabaseName = @DatabaseName, @AdhocComments = @AdhocComments, @ProcedureParameters = @ProcedureParameters,
		     @ApplicationName = @ApplicationName, @ErrorLogID = @ErrorLogID OUTPUT;
		RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID);
		RETURN (1);
	END CATCH
END
