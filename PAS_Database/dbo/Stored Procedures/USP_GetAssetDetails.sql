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

	exec [USP_GetAssetDetails] 214
*************************************************************/
CREATE   PROCEDURE USP_GetAssetDetails
    @AssetRecordId BIGINT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        DECLARE @IsIntangible BIT;
		DECLARE @AssetInTangibleModuleId INT = (SELECT TOP 1 ManagementStructureModuleId FROM DBO.ManagementStructureModule WITH(NOLOCK) WHERE ModuleName = 'AssetInTangible');
		DECLARE @AssetTangibleModuleId INT = (SELECT TOP 1 ManagementStructureModuleId FROM DBO.ManagementStructureModule WITH(NOLOCK) WHERE ModuleName = 'AssetTangible');
		     
        SELECT @IsIntangible = IsIntangible
        FROM Asset
        WHERE AssetRecordId = @AssetRecordId;

        IF @IsIntangible = 1
        BEGIN
            SELECT 
                @IsIntangible AS IsIntangible,
                a.AssetId,
                a.AssetRecordId,
                ISNULL((SELECT TOP 1 AssetId FROM Asset WHERE AssetRecordId = a.AlternateAssetRecordId), '') AS AlternateAssetName,
                a.AlternateAssetRecordId,
                a.AssetAcquisitionTypeId,
                a.AssetIntangibleTypeId,
                a.CreatedBy,
                a.CreatedDate,
                a.Description,
                a.EntryDate,
                ISNULL(a.IsActive,0) AS IsActive,
                ISNULL(a.IsDeleted,0) AS IsDeleted,
                ISNULL(a.IsTangible,0) AS IsTangible,
                ISNULL(a.IsIntangible,0) AS IsIntangible,
                a.ManagementStructureId AS ManagementStructureId,
                a.MasterCompanyId,
                a.MasterPartId,
                a.Name,
                ISNULL(a.IsDepreciable,0) AS IsDepreciable,
                ISNULL(a.IsNonDepreciable,0) AS IsNonDepreciable,
                ISNULL(a.IsAmortizable,0) AS IsAmortizable,
                ISNULL(a.IsNonAmortizable,0) AS IsNonAmortizable,
                a.UpdatedBy, 
                a.UpdatedDate,
                a.ControlNumber,
                ISNULL(msd.EntityMSID, 0) AS EntityStructureId,
                ISNULL(msd.LastMSLevel, '') AS LastMSLevel,
                ISNULL(msd.AllMSlevels, '') AS AllMSlevels,
                a.UnitOfMeasureId,
                ISNULL((SELECT TOP 1 ShortName FROM DBO.UnitOfMeasure WITH (NOLOCK) WHERE UnitOfMeasureId = a.UnitOfMeasureId), '') AS UnitOfMeasureName,
                a.ManufacturerPN,
                ISNULL((SELECT TOP 1 AssetIntangibleName FROM DBO.AssetIntangibleType WITH (NOLOCK) WHERE AssetIntangibleTypeId = aia.AssetIntangibleTypeId), '') AS AssetAttributeType,
                ISNULL((SELECT TOP 1 AssetDepreciationMethodName FROM DBO.AssetDepreciationMethod WITH (NOLOCK) WHERE AssetDepreciationMethodId = aia.AssetDepreciationMethodId), '') AS DepreciationMethod,
                aia.IntangibleLifeYears AS AssetLife,
                CASE 
                    WHEN aia.AssetAmortizationIntervalId = CAST(1 AS INT) THEN 'Monthly'
                    ELSE 'Yearly'
                END AS DeprFrequency,
                ISNULL((SELECT TOP 1 AccountCode + '-' + AccountName FROM DBO.GLAccount WITH (NOLOCK) WHERE GLAccountId = aia.IntangibleGLAccountId), '') AS GLAccount,
                aia.IntangibleGLAccountId AS GLAccountId,
                ISNULL((SELECT TOP 1 AccountCode + '-' + AccountName FROM DBO.GLAccount WITH (NOLOCK) WHERE GLAccountId = aia.AmortExpenseGLAccountId), '') AS DeprExpenseGL,
                ISNULL((SELECT TOP 1 AccountCode + '-' + AccountName FROM DBO.GLAccount WITH (NOLOCK) WHERE GLAccountId = aia.AccAmortDeprGLAccountId), '') AS ADDeprGL,
                ISNULL((SELECT TOP 1 AccountCode + '-' + AccountName FROM DBO.GLAccount WITH (NOLOCK) WHERE GLAccountId = aia.IntangibleGLAccountId), '') AS SaleGL,
                ISNULL((SELECT TOP 1 AccountCode + '-' + AccountName FROM DBO.GLAccount WITH (NOLOCK) WHERE GLAccountId = aia.IntangibleWriteDownGLAccountId), '') AS WriteDownGL,
                ISNULL((SELECT TOP 1 AccountCode + '-' + AccountName FROM DBO.GLAccount WITH (NOLOCK) WHERE GLAccountId = aia.IntangibleWriteOffGLAccountId), '') AS WriteOffGL,
                a.AssetAttributeTypeId
            FROM 
                DBO.Asset a WITH (NOLOCK)
            LEFT JOIN 
                DBO.AssetIntangibleAttributeType aia WITH (NOLOCK) ON a.AssetIntangibleTypeId = aia.AssetIntangibleTypeId
            LEFT JOIN 
                DBO.AssetManagementStructureDetails msd WITH (NOLOCK) ON a.AssetRecordId = msd.ReferenceID AND msd.ModuleID = @AssetInTangibleModuleId -- AssetInTangible
            WHERE 
                a.AssetRecordId = @AssetRecordId;
        END
        ELSE
        BEGIN
            SELECT 
                0 AS IsIntangible,
                a.AssetId,
                a.AssetRecordId,
                ISNULL((SELECT TOP 1 AssetId FROM Asset WHERE AssetRecordId = a.AlternateAssetRecordId), '') AS AlternateAssetName,
                a.AlternateAssetRecordId,
                a.AssetAcquisitionTypeId,
                ac.Name AS AssetAquisitionType,
                a.AssetIntangibleTypeId,
                a.AssetMaintenanceContractFile,
                a.AssetMaintenanceContractFileExt,
                a.AssetMaintenanceIsContract,
                ISNULL((SELECT TOP 1 AssetId FROM Asset WHERE AssetRecordId = a.AssetParentRecordId), '') AS assetParentName,
                a.AssetParentRecordId,
                aat.AssetAttributeTypeName AS AssetType,
                a.TangibleClassId,
                a.AssetLocationId,
                ISNULL((SELECT TOP 1 Name FROM Location WHERE LocationId = a.AssetLocationId), '') AS AssetLocationName,
                a.SiteId,
                ISNULL((SELECT TOP 1 Name FROM Site WHERE SiteId = a.SiteId), '') AS SiteName,
                a.WarehouseId,
                ISNULL((SELECT TOP 1 Name FROM Warehouse WHERE WarehouseId = a.WarehouseId), '') AS WarehouseName,
                a.ShelfId,
                ISNULL((SELECT TOP 1 Name FROM Shelf WHERE ShelfId = a.ShelfId), '') AS ShelfName,
                a.BinId,
                ISNULL((SELECT TOP 1 Name FROM Bin WHERE BinId = a.BinId), '') AS BinName,
                a.CreatedBy,
                a.CreatedDate,
                cur.Code AS Currency,
                a.CurrencyId,
                a.Description,
                a.EntryDate,
                a.ExpirationDate,
                ISNULL(a.IsActive,0) AS IsActive,
                ISNULL(a.IsDeleted,0) AS IsDeleted,
                ISNULL(a.IsTangible,0) AS IsTangible,
                ISNULL(a.IsIntangible,0) AS IsIntangible,
                ISNULL(a.IsSerialized,0) AS IsSerialized,
                a.ManagementStructureId AS ManagementStructureId,
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
                ISNULL(a.IsDepreciable,0) AS IsDepreciable,
                ISNULL(a.IsNonDepreciable,0) AS IsNonDepreciable,
                ISNULL(a.IsAmortizable,0) AS IsAmortizable,
                ISNULL(a.IsNonAmortizable,0) AS IsNonAmortizable,
                a.UnitOfMeasureId,
                ISNULL((SELECT TOP 1 ShortName FROM UnitOfMeasure WHERE UnitOfMeasureId = a.UnitOfMeasureId), '') AS UnitOfMeasureName,
                a.UpdatedBy,
                a.UpdatedDate,
                a.ControlNumber,
                aat.ResidualPercentage,
                ISNULL(msd.EntityMSID, 0) AS EntityStructureId,
                ISNULL(msd.LastMSLevel, '') AS LastMSLevel,
                ISNULL(msd.AllMSlevels, '') AS AllMSlevels,
                a.ManufacturerPN,
                aat.AssetAttributeTypeName AS AssetAttributeType,
                ISNULL((SELECT TOP 1 AssetDepreciationMethodName FROM DBO.AssetDepreciationMethod WITH (NOLOCK) WHERE AssetDepreciationMethodId = aat.DepreciationMethod), '') AS DepreciationMethod,
                per.PercentValue AS ResidualPer,
                aat.AssetLife AS AssetLife,
                ISNULL((SELECT TOP 1 Name FROM DBO.AssetDepreciationFrequency WITH (NOLOCK) WHERE AssetDepreciationFrequencyId = aat.DepreciationFrequencyId), '') AS DeprFrequency,
                ISNULL((SELECT TOP 1 AccountCode + '-' + AccountName FROM DBO.GLAccount WITH (NOLOCK) WHERE GLAccountId = aat.AcquiredGLAccountId), '') AS GLAccount,
                aat.AcquiredGLAccountId AS GLAccountId,
                ISNULL((SELECT TOP 1 AccountCode + '-' + AccountName FROM DBO.GLAccount WITH (NOLOCK) WHERE GLAccountId = aat.AcquiredGLAccountId), '') AS AcquiredGL,
                ISNULL((SELECT TOP 1 AccountCode + '-' + AccountName FROM DBO.GLAccount WITH (NOLOCK) WHERE GLAccountId = aat.DeprExpenseGLAccountId), '') AS DeprExpenseGL,
                ISNULL((SELECT TOP 1 AccountCode + '-' + AccountName FROM DBO.GLAccount WITH (NOLOCK) WHERE GLAccountId = aat.AdDepsGLAccountId), '') AS ADDeprGL,
                ISNULL((SELECT TOP 1 AccountCode + '-' + AccountName FROM DBO.GLAccount WITH (NOLOCK) WHERE GLAccountId = aat.AssetSale), '') AS SaleGL,
                ISNULL((SELECT TOP 1 AccountCode + '-' + AccountName FROM DBO.GLAccount WITH (NOLOCK) WHERE GLAccountId = aat.AssetWriteDown), '') AS WriteDownGL,
                ISNULL((SELECT TOP 1 AccountCode + '-' + AccountName FROM DBO.GLAccount WITH (NOLOCK) WHERE GLAccountId = aat.AssetWriteOff), '') AS WriteOffGL,
                a.AssetAttributeTypeId
            FROM 
                DBO.Asset a WITH (NOLOCK)
            LEFT JOIN 
                DBO.AssetAcquisitionType ac WITH (NOLOCK) ON a.AssetAcquisitionTypeId = ac.AssetAcquisitionTypeId
            LEFT JOIN 
                DBO.AssetAttributeType aat WITH (NOLOCK) ON a.AssetAttributeTypeId = aat.AssetAttributeTypeId
            LEFT JOIN 
                DBO.Manufacturer mg WITH (NOLOCK) ON a.ManufacturerId = mg.ManufacturerId
            LEFT JOIN 
                DBO.Currency cur WITH (NOLOCK) ON a.CurrencyId = cur.CurrencyId
            LEFT JOIN 
                DBO.TangibleClass astp WITH (NOLOCK) ON a.TangibleClassId = astp.TangibleClassId
            LEFT JOIN 
                DBO.[Percent] per WITH (NOLOCK) ON aat.ResidualPercentage = per.PercentId
            LEFT JOIN 
                DBO.AssetManagementStructureDetails msd WITH (NOLOCK) ON a.AssetRecordId = msd.ReferenceID AND msd.ModuleID = @AssetTangibleModuleId -- AssetTangible
            WHERE 
                a.AssetRecordId = @AssetRecordId;
        END
    END TRY
    BEGIN CATCH      
        DECLARE @ErrorLogID INT
            ,@DatabaseName VARCHAR(100) = db_name()
            ,@AdhocComments VARCHAR(150) = 'USP_GetAssetDetails'
            ,@ProcedureParameters VARCHAR(3000) = '@Parameter1 = '', '
            ,@ApplicationName VARCHAR(100) = 'PAS'
        
        EXEC spLogException @DatabaseName = @DatabaseName
            ,@AdhocComments = @AdhocComments
            ,@ProcedureParameters = @ProcedureParameters
            ,@ApplicationName = @ApplicationName
            ,@ErrorLogID = @ErrorLogID OUTPUT;

        RAISERROR ('Unexpected Error Occurred in the database. Please let the support team know of the error number : %d',16,1,@ErrorLogID)
        RETURN (1);           
    END CATCH
END