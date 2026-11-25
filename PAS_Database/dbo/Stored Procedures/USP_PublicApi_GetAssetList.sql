
/*************************************************************
 ** File:   [USP_PublicApi_GetAssetList]
 ** Author: Bhargav Saliya
 ** Description: Assets of the company (PAS Asset List), oldest first. Asset Class, Asset Type, Depreciation Method,
 **              Depr/Amort and Calibration Required follow the same logic as dbo.GetAssetList.
 ** Purpose: PAS_PUBLIC_API - GET /api/v1/assets
 ** Date:   23/11/2026

 ** RETURN VALUE:
 **************************************************************
 ** Change History
 **************************************************************
 ** PR   Date         Author		Change Description
 ** --   --------     -------		--------------------------------
    1    23/11/2026   Bhargav Saliya    Created

  EXEC [dbo].[USP_PublicApi_GetAssetList] @MasterCompanyId = 1, @PageNumber = 1, @PageSize = 50
************************************************************************/
CREATE   PROCEDURE [dbo].[USP_PublicApi_GetAssetList]
    @MasterCompanyId INT,
    @PageNumber      INT,
    @PageSize        INT,
    @AssetId         VARCHAR(100) = NULL,
    @IsActive        BIT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        ;WITH PagedAsset AS
        (
            SELECT A.[AssetRecordId], COUNT(1) OVER () AS [TotalRecords]
            FROM [dbo].[Asset] A WITH (NOLOCK)
            WHERE A.[MasterCompanyId] = @MasterCompanyId
              AND ISNULL(A.[IsDeleted], 0) = 0
              AND (@AssetId IS NULL OR A.[AssetId] = @AssetId)
              AND (@IsActive IS NULL OR ISNULL(A.[IsActive], 1) = @IsActive)
            ORDER BY A.[AssetRecordId]
            OFFSET (@PageNumber - 1) * @PageSize ROWS
            FETCH NEXT @PageSize ROWS ONLY
        )
        SELECT
            A.[AssetRecordId],   -- used by the API to attach the capabilities; not returned to clients
            A.[AssetId],
            A.[Name],
            NULLIF(LTRIM(RTRIM(A.[Description])), '') AS [Description],
            ALT.[AssetId] AS [AlternateAssetId],
            MF.[Name] AS [Manufacturer],
            NULLIF(LTRIM(RTRIM(A.[ManufacturerPN])), '') AS [ManufacturerPN],
            NULLIF(LTRIM(RTRIM(A.[Model])), '') AS [Model],
            CAST(ISNULL(A.[IsSerialized], 0) AS BIT) AS [IsSerialized],
            CASE WHEN ISNULL(A.[IsIntangible], 0) = 1 THEN 'Intangible' ELSE 'Tangible' END AS [AssetCategory],
            NULLIF(CASE WHEN ISNULL(A.[IsIntangible], 0) = 1 THEN AIT.[AssetIntangibleName]
                        ELSE COALESCE(TCD.[TangibleClassName], TCN.[TangibleClassName], TCA.[TangibleClassName]) END, '') AS [AssetClass],
            AAT.[AssetAttributeTypeName] AS [AssetType],
            ADM.[AssetDepreciationMethodName] AS [DepreciationMethod],
            CAST(CASE WHEN ISNULL(A.[IsTangible], 0) = 1 AND ISNULL(A.[IsDepreciable], 0) = 1 THEN 1
                      WHEN ISNULL(A.[IsTangible], 0) = 0 AND ISNULL(A.[IsAmortizable], 0) = 1 THEN 1
                      ELSE 0 END AS BIT) AS [IsDepreciableOrAmortizable],
            CAST(ISNULL(CAL.[CalibrationRequired], 0) AS BIT) AS [CalibrationRequired],
            UOM.[ShortName] AS [UnitOfMeasure],
            CU.[Code] AS [Currency],
            A.[UnitCost],
            A.[ManufacturedDate],
            A.[ExpirationDate],
            A.[EntryDate],
            CAST(ISNULL(A.[IsActive], 1) AS BIT) AS [IsActive],
            A.[CreatedDate],
            A.[UpdatedDate],
            P.[TotalRecords]
        FROM PagedAsset P
        INNER JOIN [dbo].[Asset] A WITH (NOLOCK) ON A.[AssetRecordId] = P.[AssetRecordId]
        LEFT JOIN [dbo].[Asset] ALT WITH (NOLOCK) ON ALT.[AssetRecordId] = A.[AlternateAssetRecordId]
        LEFT JOIN [dbo].[Manufacturer] MF WITH (NOLOCK) ON MF.[ManufacturerId] = A.[ManufacturerId]
        LEFT JOIN [dbo].[AssetAttributeType] AAT WITH (NOLOCK) ON AAT.[AssetAttributeTypeId] = A.[AssetAttributeTypeId]
        LEFT JOIN [dbo].[AssetDepreciationMethod] ADM WITH (NOLOCK) ON ADM.[AssetDepreciationMethodId] = AAT.[DepreciationMethod]
        LEFT JOIN [dbo].[TangibleClass] TCD WITH (NOLOCK) ON TCD.[TangibleClassId] = A.[TangibleClassId]
        LEFT JOIN [dbo].[DeprNonDeprTangibleAssets] DND WITH (NOLOCK) ON DND.[DeprNonDeprTangibleAssetsId] = A.[DeprNonDeprTangibleAssetsId]
        LEFT JOIN [dbo].[TangibleClass] TCN WITH (NOLOCK) ON TCN.[TangibleClassId] = DND.[TangibleClassId]
        LEFT JOIN [dbo].[TangibleClass] TCA WITH (NOLOCK) ON TCA.[TangibleClassId] = AAT.[TangibleClassId]
        LEFT JOIN [dbo].[AssetIntangibleType] AIT WITH (NOLOCK) ON AIT.[AssetIntangibleTypeId] = A.[AssetIntangibleTypeId]
        LEFT JOIN [dbo].[UnitOfMeasure] UOM WITH (NOLOCK) ON UOM.[UnitOfMeasureId] = A.[UnitOfMeasureId]
        LEFT JOIN [dbo].[Currency] CU WITH (NOLOCK) ON CU.[CurrencyId] = A.[CurrencyId]
        OUTER APPLY (
            SELECT TOP (1) AC.[CalibrationRequired]
            FROM [dbo].[AssetCalibration] AC WITH (NOLOCK)
            WHERE AC.[AssetRecordId] = A.[AssetRecordId]
        ) CAL
        ORDER BY A.[AssetRecordId];
    END TRY
    BEGIN CATCH
        IF @@trancount > 0
            PRINT 'ROLLBACK'
        DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_PublicApi_GetAssetList'
              , @ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@MasterCompanyId, '') AS VARCHAR(100))
                                                   + '@Parameter2 = ''' + CAST(ISNULL(@PageNumber, '') AS VARCHAR(100))
                                                   + '@Parameter3 = ''' + CAST(ISNULL(@PageSize, '') AS VARCHAR(100))
                                                   + '@Parameter4 = ''' + CAST(ISNULL(@AssetId, '') AS VARCHAR(100))
                                                   + '@Parameter5 = ''' + CAST(ISNULL(@IsActive, '') AS VARCHAR(100))
              , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
              exec spLogException
                       @DatabaseName           = @DatabaseName
                     , @AdhocComments          = @AdhocComments
                     , @ProcedureParameters = @ProcedureParameters
                     , @ApplicationName        =  @ApplicationName
                     , @ErrorLogID                    = @ErrorLogID OUTPUT ;
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
              RETURN(1);
    END CATCH
END