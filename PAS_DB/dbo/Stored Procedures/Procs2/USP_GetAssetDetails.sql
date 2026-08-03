/***************************************************************
 ** File:  [USP_GetAssetDetails]
 ** Author: Ayushi Patel
 ** Description: Get Asset Details
 ** Purpose:
 ** Date:  11-Jun-2025

 ** Change History
 **************************************************************
 ** PR   Date				Author  				Change Description
 ** --   --------			-------				--------------------------------
    1    2025-06-11		  Ayushi Patel				Created
    2    2026-07-22		  Vishal Suthar				Branch GL account resolution on Asset.AssetClassSource so
    3    2026-07-29		  Abhishek Jirawala			Asset.AssetAttributeTypeId now always stores an AssetAttributeTypeId
	                                                (never a DeprNonDeprTangibleAssetsId); joined dnd (DeprNonDeprTangibleAssets)
	                                                by its AssetAttributeTypeId FK instead of its own PK, and sourced the
	                                                Asset Class name from the joined AssetAttributeType row since
	                                                DeprNonDeprTangibleAssets.AssetAttributeTypeName was removed.

	exec [USP_GetAssetDetails] 226
*************************************************************/
CREATE   PROCEDURE [dbo].[USP_GetAssetDetails]
    @AssetRecordId BIGINT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        DECLARE @IsIntangible BIT;
        DECLARE @AssetClassSource VARCHAR(100);
        DECLARE @AssetInTangibleModuleId INT = (SELECT TOP 1 ManagementStructureModuleId FROM DBO.ManagementStructureModule WITH(NOLOCK) WHERE ModuleName = 'AssetInTangible');
        DECLARE @AssetTangibleModuleId INT = (SELECT TOP 1 ManagementStructureModuleId FROM DBO.ManagementStructureModule WITH(NOLOCK) WHERE ModuleName = 'AssetTangible');

        SELECT @IsIntangible = IsIntangible,
               @AssetClassSource = AssetClassSource
        FROM Asset
        WHERE AssetRecordId = @AssetRecordId;

        IF @IsIntangible = 1
        BEGIN
            SELECT
                1 AS IsIntangible,
                a.AssetId,
                a.AssetRecordId,
                alt.AssetId AS AlternateAssetName,
                a.AlternateAssetRecordId,
                a.AssetAcquisitionTypeId,
                a.AssetIntangibleTypeId,
                a.CreatedBy,
                a.CreatedDate,
                a.Description,
                a.EntryDate,
                ISNULL(a.IsActive, 0) AS IsActive,
                ISNULL(a.IsDeleted, 0) AS IsDeleted,
                ISNULL(a.IsTangible, 0) AS IsTangible,
                ISNULL(a.IsIntangible, 0) AS IsIntangible,
                a.ManagementStructureId,
                a.MasterCompanyId,
                a.MasterPartId,
                a.Name,
                ISNULL(a.IsDepreciable, 0) AS IsDepreciable,
                ISNULL(a.IsNonDepreciable, 0) AS IsNonDepreciable,
                ISNULL(a.IsAmortizable, 0) AS IsAmortizable,
                ISNULL(a.IsNonAmortizable, 0) AS IsNonAmortizable,
                a.UpdatedBy,
                a.UpdatedDate,
                a.ControlNumber,
                ISNULL(msd.EntityMSID, 0) AS EntityStructureId,
                ISNULL(msd.LastMSLevel, '') AS LastMSLevel,
                ISNULL(msd.AllMSlevels, '') AS AllMSlevels,
                a.UnitOfMeasureId,
                ISNULL(uom.ShortName, '') AS UnitOfMeasureName,
                a.ManufacturerPN,
                ISNULL(aiat.AssetIntangibleName, '') AS AssetAttributeType,
                ISNULL(adm.AssetDepreciationMethodName, '') AS DepreciationMethod,
                aia.IntangibleLifeYears AS AssetLife,
                CASE
                    WHEN aia.AssetAmortizationIntervalId = 1 THEN 'Monthly'
                    ELSE 'Yearly'
                END AS DeprFrequency,
                ISNULL(gl1.AccountCode + '-' + gl1.AccountName, '') AS GLAccount,
                aia.IntangibleGLAccountId AS GLAccountId,
                ISNULL(gl2.AccountCode + '-' + gl2.AccountName, '') AS DeprExpenseGL,
                ISNULL(gl3.AccountCode + '-' + gl3.AccountName, '') AS ADDeprGL,
                ISNULL(gl4.AccountCode + '-' + gl4.AccountName, '') AS SaleGL,
                ISNULL(gl5.AccountCode + '-' + gl5.AccountName, '') AS WriteDownGL,
                ISNULL(gl6.AccountCode + '-' + gl6.AccountName, '') AS WriteOffGL,
                a.AssetAttributeTypeId
            FROM DBO.Asset a WITH (NOLOCK)
            LEFT JOIN DBO.Asset alt WITH (NOLOCK) ON a.AlternateAssetRecordId = alt.AssetRecordId
            LEFT JOIN DBO.AssetIntangibleAttributeType aia WITH (NOLOCK) ON a.AssetIntangibleTypeId = aia.AssetIntangibleTypeId
            LEFT JOIN DBO.AssetIntangibleType aiat WITH (NOLOCK) ON a.AssetIntangibleTypeId = aiat.AssetIntangibleTypeId
            LEFT JOIN DBO.AssetDepreciationMethod adm WITH (NOLOCK) ON aia.AssetDepreciationMethodId = adm.AssetDepreciationMethodId
            LEFT JOIN DBO.UnitOfMeasure uom WITH (NOLOCK) ON a.UnitOfMeasureId = uom.UnitOfMeasureId
            LEFT JOIN DBO.GLAccount gl1 WITH (NOLOCK) ON aia.IntangibleGLAccountId = gl1.GLAccountId
            LEFT JOIN DBO.GLAccount gl2 WITH (NOLOCK) ON aia.AmortExpenseGLAccountId = gl2.GLAccountId
            LEFT JOIN DBO.GLAccount gl3 WITH (NOLOCK) ON aia.AccAmortDeprGLAccountId = gl3.GLAccountId
            LEFT JOIN DBO.GLAccount gl4 WITH (NOLOCK) ON aia.IntangibleGLAccountId = gl4.GLAccountId
            LEFT JOIN DBO.GLAccount gl5 WITH (NOLOCK) ON aia.IntangibleWriteDownGLAccountId = gl5.GLAccountId
            LEFT JOIN DBO.GLAccount gl6 WITH (NOLOCK) ON aia.IntangibleWriteOffGLAccountId = gl6.GLAccountId
            LEFT JOIN DBO.AssetManagementStructureDetails msd WITH (NOLOCK) ON a.AssetRecordId = msd.ReferenceID AND msd.ModuleID = @AssetInTangibleModuleId
            WHERE a.AssetRecordId = @AssetRecordId;
        END
        ELSE
        BEGIN
            IF ISNULL(@AssetClassSource, '') = 'DeprNonDeprTangibleAssets'
            BEGIN
                SELECT
                    0 AS IsIntangible,
                    a.AssetId,
                    a.AssetRecordId,
                    alt.AssetId AS AlternateAssetName,
                    a.AlternateAssetRecordId,
                    a.AssetAcquisitionTypeId,
                    ac.Name AS AssetAquisitionType,
                    a.AssetIntangibleTypeId,
                    a.AssetMaintenanceContractFile,
                    a.AssetMaintenanceContractFileExt,
                    a.AssetMaintenanceIsContract,
                    parent.AssetId AS assetParentName,
                    a.AssetParentRecordId,
                    aat.AssetAttributeTypeName AS AssetType,
                    a.TangibleClassId,
                    a.AssetLocationId,
                    loc.Name AS AssetLocationName,
                    a.SiteId,
                    st.Name AS SiteName,
                    a.WarehouseId,
                    wh.Name AS WarehouseName,
                    a.ShelfId,
                    sh.Name AS ShelfName,
                    a.BinId,
                    bn.Name AS BinName,
                    a.CreatedBy,
                    a.CreatedDate,
                    cur.Code AS Currency,
                    a.CurrencyId,
                    a.Description,
                    a.EntryDate,
                    a.ExpirationDate,
                    ISNULL(a.IsActive, 0) AS IsActive,
                    ISNULL(a.IsDeleted, 0) AS IsDeleted,
                    ISNULL(a.IsTangible, 0) AS IsTangible,
                    ISNULL(a.IsIntangible, 0) AS IsIntangible,
                    ISNULL(a.IsSerialized, 0) AS IsSerialized,
                    a.ManagementStructureId,
                    a.ManufacturedDate,
                    a.ManufacturerId,
                    mg.Name AS Manufacturer,
                    a.MasterCompanyId,
                    a.MasterPartId,
                    a.Memo,
                    a.Model,
                    a.Name,
                    a.UnexpiredTime,
                    a.UnitCost,
                    ISNULL(a.IsDepreciable, 0) AS IsDepreciable,
                    ISNULL(a.IsNonDepreciable, 0) AS IsNonDepreciable,
                    ISNULL(a.IsAmortizable, 0) AS IsAmortizable,
                    ISNULL(a.IsNonAmortizable, 0) AS IsNonAmortizable,
                    a.UnitOfMeasureId,
                    uom.ShortName AS UnitOfMeasureName,
                    a.UpdatedBy,
                    a.UpdatedDate,
                    a.ControlNumber,
                    CAST(NULL AS DECIMAL(18,2)) AS ResidualPercentage,
                    ISNULL(msd.EntityMSID, 0) AS EntityStructureId,
                    ISNULL(msd.LastMSLevel, '') AS LastMSLevel,
                    ISNULL(msd.AllMSlevels, '') AS AllMSlevels,
                    a.ManufacturerPN,
                    aat.AssetAttributeTypeName AS AssetAttributeType,
                    ISNULL(dm.AssetDepreciationMethodName, '') AS DepreciationMethod,
                    CAST(NULL AS DECIMAL(18,2)) AS ResidualPer,
                    CAST(NULL AS INT) AS AssetLife,
                    '' AS DeprFrequency,
                    ISNULL(gl1.AccountCode + '-' + gl1.AccountName, '') AS GLAccount,
                    dnd.AcquiredGLAccountId AS GLAccountId,
                    ISNULL(gl2.AccountCode + '-' + gl2.AccountName, '') AS AcquiredGL,
                    ISNULL(gl3.AccountCode + '-' + gl3.AccountName, '') AS DeprExpenseGL,
                    ISNULL(gl4.AccountCode + '-' + gl4.AccountName, '') AS ADDeprGL,
                    ISNULL(gl5.AccountCode + '-' + gl5.AccountName, '') AS SaleGL,
                    ISNULL(gl6.AccountCode + '-' + gl6.AccountName, '') AS WriteDownGL,
                    ISNULL(gl7.AccountCode + '-' + gl7.AccountName, '') AS WriteOffGL,
                    ISNULL(gl8.AccountCode + '-' + gl8.AccountName, '') AS CalibratedGL,
                    a.AssetAttributeTypeId
                FROM DBO.Asset a WITH (NOLOCK)
                LEFT JOIN DBO.Asset alt WITH (NOLOCK) ON a.AlternateAssetRecordId = alt.AssetRecordId
                LEFT JOIN DBO.Asset parent WITH (NOLOCK) ON a.AssetParentRecordId = parent.AssetRecordId
                LEFT JOIN DBO.AssetAcquisitionType ac WITH (NOLOCK) ON a.AssetAcquisitionTypeId = ac.AssetAcquisitionTypeId
                LEFT JOIN DBO.DeprNonDeprTangibleAssets dnd WITH (NOLOCK) ON a.AssetAttributeTypeId = dnd.AssetAttributeTypeId
                LEFT JOIN DBO.AssetAttributeType aat WITH (NOLOCK) ON a.AssetAttributeTypeId = aat.AssetAttributeTypeId
                LEFT JOIN DBO.Manufacturer mg WITH (NOLOCK) ON a.ManufacturerId = mg.ManufacturerId
                LEFT JOIN DBO.Currency cur WITH (NOLOCK) ON a.CurrencyId = cur.CurrencyId
                LEFT JOIN DBO.UnitOfMeasure uom WITH (NOLOCK) ON a.UnitOfMeasureId = uom.UnitOfMeasureId
                LEFT JOIN DBO.Location loc WITH (NOLOCK) ON a.AssetLocationId = loc.LocationId
                LEFT JOIN DBO.Site st WITH (NOLOCK) ON a.SiteId = st.SiteId
                LEFT JOIN DBO.Warehouse wh WITH (NOLOCK) ON a.WarehouseId = wh.WarehouseId
                LEFT JOIN DBO.Shelf sh WITH (NOLOCK) ON a.ShelfId = sh.ShelfId
                LEFT JOIN DBO.Bin bn WITH (NOLOCK) ON a.BinId = bn.BinId
                LEFT JOIN DBO.AssetDepreciationMethod dm WITH (NOLOCK) ON dnd.AssetDeprMethodId = dm.AssetDepreciationMethodId
                LEFT JOIN DBO.GLAccount gl1 WITH (NOLOCK) ON dnd.AcquiredGLAccountId = gl1.GLAccountId
                LEFT JOIN DBO.GLAccount gl2 WITH (NOLOCK) ON dnd.AcquiredGLAccountId = gl2.GLAccountId
                LEFT JOIN DBO.GLAccount gl3 WITH (NOLOCK) ON dnd.DeprExpenseGLAccountId = gl3.GLAccountId
                LEFT JOIN DBO.GLAccount gl4 WITH (NOLOCK) ON dnd.AccumDeprGLAccountId = gl4.GLAccountId
                LEFT JOIN DBO.GLAccount gl5 WITH (NOLOCK) ON dnd.AssetSaleGLAccountId = gl5.GLAccountId
                LEFT JOIN DBO.GLAccount gl6 WITH (NOLOCK) ON dnd.AssetWriteDownGLAccountId = gl6.GLAccountId
                LEFT JOIN DBO.GLAccount gl7 WITH (NOLOCK) ON dnd.AssetWriteOffGLAccountId = gl7.GLAccountId
                LEFT JOIN DBO.GLAccount gl8 WITH (NOLOCK) ON dnd.CalibratedGLAccountId = gl8.GLAccountId
                LEFT JOIN DBO.AssetManagementStructureDetails msd WITH (NOLOCK) ON a.AssetRecordId = msd.ReferenceID AND msd.ModuleID = @AssetTangibleModuleId
                WHERE a.AssetRecordId = @AssetRecordId;
            END
            ELSE
            BEGIN
                SELECT
                    0 AS IsIntangible,
                    a.AssetId,
                    a.AssetRecordId,
                    alt.AssetId AS AlternateAssetName,
                    a.AlternateAssetRecordId,
                    a.AssetAcquisitionTypeId,
                    ac.Name AS AssetAquisitionType,
                    a.AssetIntangibleTypeId,
                    a.AssetMaintenanceContractFile,
                    a.AssetMaintenanceContractFileExt,
                    a.AssetMaintenanceIsContract,
                    parent.AssetId AS assetParentName,
                    a.AssetParentRecordId,
                    aat.AssetAttributeTypeName AS AssetType,
                    a.TangibleClassId,
                    a.AssetLocationId,
                    loc.Name AS AssetLocationName,
                    a.SiteId,
                    st.Name AS SiteName,
                    a.WarehouseId,
                    wh.Name AS WarehouseName,
                    a.ShelfId,
                    sh.Name AS ShelfName,
                    a.BinId,
                    bn.Name AS BinName,
                    a.CreatedBy,
                    a.CreatedDate,
                    cur.Code AS Currency,
                    a.CurrencyId,
                    a.Description,
                    a.EntryDate,
                    a.ExpirationDate,
                    ISNULL(a.IsActive, 0) AS IsActive,
                    ISNULL(a.IsDeleted, 0) AS IsDeleted,
                    ISNULL(a.IsTangible, 0) AS IsTangible,
                    ISNULL(a.IsIntangible, 0) AS IsIntangible,
                    ISNULL(a.IsSerialized, 0) AS IsSerialized,
                    a.ManagementStructureId,
                    a.ManufacturedDate,
                    a.ManufacturerId,
                    mg.Name AS Manufacturer,
                    a.MasterCompanyId,
                    a.MasterPartId,
                    a.Memo,
                    a.Model,
                    a.Name,
                    a.UnexpiredTime,
                    a.UnitCost,
                    ISNULL(a.IsDepreciable, 0) AS IsDepreciable,
                    ISNULL(a.IsNonDepreciable, 0) AS IsNonDepreciable,
                    ISNULL(a.IsAmortizable, 0) AS IsAmortizable,
                    ISNULL(a.IsNonAmortizable, 0) AS IsNonAmortizable,
                    a.UnitOfMeasureId,
                    uom.ShortName AS UnitOfMeasureName,
                    a.UpdatedBy,
                    a.UpdatedDate,
                    a.ControlNumber,
                    aat.ResidualPercentage,
                    ISNULL(msd.EntityMSID, 0) AS EntityStructureId,
                    ISNULL(msd.LastMSLevel, '') AS LastMSLevel,
                    ISNULL(msd.AllMSlevels, '') AS AllMSlevels,
                    a.ManufacturerPN,
                    aat.AssetAttributeTypeName AS AssetAttributeType,
                    adm.AssetDepreciationMethodName AS DepreciationMethod,
                    per.PercentValue AS ResidualPer,
                    aat.AssetLife,
                    df.Name AS DeprFrequency,
                    ISNULL(gl1.AccountCode + '-' + gl1.AccountName, '') AS GLAccount,
                    aat.AcquiredGLAccountId AS GLAccountId,
                    ISNULL(gl2.AccountCode + '-' + gl2.AccountName, '') AS AcquiredGL,
                    ISNULL(gl3.AccountCode + '-' + gl3.AccountName, '') AS DeprExpenseGL,
                    ISNULL(gl4.AccountCode + '-' + gl4.AccountName, '') AS ADDeprGL,
                    ISNULL(gl5.AccountCode + '-' + gl5.AccountName, '') AS SaleGL,
                    ISNULL(gl6.AccountCode + '-' + gl6.AccountName, '') AS WriteDownGL,
                    ISNULL(gl7.AccountCode + '-' + gl7.AccountName, '') AS WriteOffGL,
                    '' AS CalibratedGL,
                    a.AssetAttributeTypeId
                FROM DBO.Asset a WITH (NOLOCK)
                LEFT JOIN DBO.Asset alt WITH (NOLOCK) ON a.AlternateAssetRecordId = alt.AssetRecordId
                LEFT JOIN DBO.Asset parent WITH (NOLOCK) ON a.AssetParentRecordId = parent.AssetRecordId
                LEFT JOIN DBO.AssetAcquisitionType ac WITH (NOLOCK) ON a.AssetAcquisitionTypeId = ac.AssetAcquisitionTypeId
                LEFT JOIN DBO.AssetAttributeType aat WITH (NOLOCK) ON a.AssetAttributeTypeId = aat.AssetAttributeTypeId
                LEFT JOIN DBO.Manufacturer mg WITH (NOLOCK) ON a.ManufacturerId = mg.ManufacturerId
                LEFT JOIN DBO.Currency cur WITH (NOLOCK) ON a.CurrencyId = cur.CurrencyId
                LEFT JOIN DBO.UnitOfMeasure uom WITH (NOLOCK) ON a.UnitOfMeasureId = uom.UnitOfMeasureId
                LEFT JOIN DBO.Location loc WITH (NOLOCK) ON a.AssetLocationId = loc.LocationId
                LEFT JOIN DBO.Site st WITH (NOLOCK) ON a.SiteId = st.SiteId
                LEFT JOIN DBO.Warehouse wh WITH (NOLOCK) ON a.WarehouseId = wh.WarehouseId
                LEFT JOIN DBO.Shelf sh WITH (NOLOCK) ON a.ShelfId = sh.ShelfId
                LEFT JOIN DBO.Bin bn WITH (NOLOCK) ON a.BinId = bn.BinId
                LEFT JOIN DBO.AssetDepreciationMethod adm WITH (NOLOCK) ON aat.DepreciationMethod = adm.AssetDepreciationMethodId
                LEFT JOIN DBO.[Percent] per WITH (NOLOCK) ON aat.ResidualPercentage = per.PercentId
                LEFT JOIN DBO.AssetDepreciationFrequency df WITH (NOLOCK) ON aat.DepreciationFrequencyId = df.AssetDepreciationFrequencyId
                LEFT JOIN DBO.GLAccount gl1 WITH (NOLOCK) ON aat.AcquiredGLAccountId = gl1.GLAccountId
                LEFT JOIN DBO.GLAccount gl2 WITH (NOLOCK) ON aat.AcquiredGLAccountId = gl2.GLAccountId
                LEFT JOIN DBO.GLAccount gl3 WITH (NOLOCK) ON aat.DeprExpenseGLAccountId = gl3.GLAccountId
                LEFT JOIN DBO.GLAccount gl4 WITH (NOLOCK) ON aat.AdDepsGLAccountId = gl4.GLAccountId
                LEFT JOIN DBO.GLAccount gl5 WITH (NOLOCK) ON aat.AssetSale = gl5.GLAccountId
                LEFT JOIN DBO.GLAccount gl6 WITH (NOLOCK) ON aat.AssetWriteDown = gl6.GLAccountId
                LEFT JOIN DBO.GLAccount gl7 WITH (NOLOCK) ON aat.AssetWriteOff = gl7.GLAccountId
                LEFT JOIN DBO.AssetManagementStructureDetails msd WITH (NOLOCK) ON a.AssetRecordId = msd.ReferenceID AND msd.ModuleID = @AssetTangibleModuleId
                WHERE a.AssetRecordId = @AssetRecordId;
            END
        END
    END TRY
    BEGIN CATCH
        DECLARE @ErrorLogID INT,
                @DatabaseName VARCHAR(100) = DB_NAME(),
                @AdhocComments VARCHAR(150) = 'USP_GetAssetDetails',
                @ProcedureParameters VARCHAR(3000) = '@AssetRecordId = ' + CAST(@AssetRecordId AS VARCHAR),
                @ApplicationName VARCHAR(100) = 'PAS';

        EXEC spLogException @DatabaseName = @DatabaseName,
                            @AdhocComments = @AdhocComments,
                            @ProcedureParameters = @ProcedureParameters,
                            @ApplicationName = @ApplicationName,
                            @ErrorLogID = @ErrorLogID OUTPUT;

        RAISERROR ('Unexpected Error Occurred in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID);
        RETURN (1);
    END CATCH
END