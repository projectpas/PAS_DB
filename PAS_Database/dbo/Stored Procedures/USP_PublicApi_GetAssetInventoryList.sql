
/*************************************************************
 ** File:   [USP_PublicApi_GetAssetInventoryList]
 ** Author: Bhargav Saliya
 ** Description: Asset inventory of the company (PAS Asset Inventory List), oldest first. Only inventory in a
 **              management structure the employee's PAS roles can see (AssetManagementStructureDetails, modules
 **              42 / 43), as dbo.GetAssetInventoryList. Status, cost, accumulated depreciation and net book value
 **              follow the same logic as that procedure.
 ** Purpose: PAS_PUBLIC_API - GET /api/v1/assetinventories
 ** Date:   23/11/2026

 ** RETURN VALUE:
 **************************************************************
 ** Change History
 **************************************************************
 ** PR   Date         Author		Change Description
 ** --   --------     -------		--------------------------------
    1    23/11/2026   Bhargav Saliya    Created

  EXEC [dbo].[USP_PublicApi_GetAssetInventoryList] @MasterCompanyId = 1, @EmployeeId = 2, @PageNumber = 1, @PageSize = 50
************************************************************************/
CREATE   PROCEDURE [dbo].[USP_PublicApi_GetAssetInventoryList]
    @MasterCompanyId INT,
    @EmployeeId      BIGINT,
    @PageNumber      INT,
    @PageSize        INT,
    @AssetId         VARCHAR(100) = NULL,
    @InventoryNumber VARCHAR(100) = NULL,
    @IsActive        BIT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        ;WITH PagedInventory AS
        (
            SELECT AI.[AssetInventoryId], COUNT(1) OVER () AS [TotalRecords]
            FROM [dbo].[AssetInventory] AI WITH (NOLOCK)
            WHERE AI.[MasterCompanyId] = @MasterCompanyId
              AND ISNULL(AI.[IsDeleted], 0) = 0
              AND (@AssetId IS NULL OR AI.[AssetId] = @AssetId)
              AND (@InventoryNumber IS NULL OR AI.[InventoryNumber] = @InventoryNumber)
              AND (@IsActive IS NULL OR ISNULL(AI.[IsActive], 1) = @IsActive)
              AND EXISTS (SELECT 1
                          FROM [dbo].[AssetManagementStructureDetails] MSD WITH (NOLOCK)
                          INNER JOIN [dbo].[RoleManagementStructure] RMS WITH (NOLOCK) ON RMS.[EntityStructureId] = MSD.[EntityMSID]
                          INNER JOIN [dbo].[EmployeeUserRole] EUR WITH (NOLOCK) ON EUR.[RoleId] = RMS.[RoleId] AND EUR.[EmployeeId] = @EmployeeId
                          WHERE MSD.[ModuleID] IN (42, 43) AND MSD.[ReferenceID] = AI.[AssetInventoryId])
            ORDER BY AI.[AssetInventoryId]
            OFFSET (@PageNumber - 1) * @PageSize ROWS
            FETCH NEXT @PageSize ROWS ONLY
        )
        SELECT
            AI.[InventoryNumber],
            AI.[AssetId],
            AI.[Name],
            NULLIF(LTRIM(RTRIM(AI.[Description])), '') AS [Description],
            ALT.[AssetId] AS [AlternateAssetId],
            MF.[Name] AS [Manufacturer],
            NULLIF(LTRIM(RTRIM(A.[ManufacturerPN])), '') AS [ManufacturerPN],
            NULLIF(LTRIM(RTRIM(A.[Model])), '') AS [Model],
            NULLIF(LTRIM(RTRIM(AI.[PartNumber])), '') AS [PartNumber],
            NULLIF(LTRIM(RTRIM(AI.[SerialNo])), '') AS [SerialNumber],
            NULLIF(LTRIM(RTRIM(AI.[StklineNumber])), '') AS [StocklineNumber],
            NULLIF(LTRIM(RTRIM(AI.[ControlNumber])), '') AS [ControlNumber],
            CASE WHEN ISNULL(AI.[IsTangible], 0) = 1 THEN 'Tangible' ELSE 'Intangible' END AS [AssetCategory],
            NULLIF(COALESCE(TCD.[TangibleClassName], TCN.[TangibleClassName], AIT.[AssetIntangibleName]), '') AS [AssetClass],
            CAST(CASE WHEN ISNULL(AI.[IsTangible], 0) = 1 AND ISNULL(AI.[IsDepreciable], 0) = 1 THEN 1
                      WHEN ISNULL(AI.[IsTangible], 0) = 0 AND ISNULL(AI.[IsAmortizable], 0) = 1 THEN 1
                      ELSE 0 END AS BIT) AS [IsDepreciableOrAmortizable],
            NULLIF(LTRIM(RTRIM(AI.[DepreciationMethodName])), '') AS [DepreciationMethod],
            CAST(ISNULL(AI.[CalibrationRequired], 0) AS BIT) AS [CalibrationRequired],
            CASE WHEN ISNULL(AI.[CalibrationRequired], 0) = 1 THEN CV.[VendorName] END AS [CalibrationVendor],
            ST.[Name] AS [AssetStatus],
            COALESCE(INS.[Status], ANS.[Status]) AS [InventoryStatus],
            CASE WHEN ISNULL(AI.[IsActive], 0) = 1 THEN 'Active'
                 WHEN NULLIF(UPPER(COALESCE(INS.[Status], ANS.[Status])), 'UNAVAILABLE') IS NOT NULL THEN COALESCE(INS.[Status], ANS.[Status])
                 ELSE 'Inactive' END AS [StatusOfAsset],
            NULLIF(LTRIM(RTRIM(AI.[StatusNote])), '') AS [StatusNote],
            WO.[WorkOrderNum] AS [CheckedInWorkOrder],
            MS.[LastMSLevel] AS [ManagementStructure],
            NULLIF(LTRIM(RTRIM(AI.[SiteName])), '') AS [Site],
            NULLIF(LTRIM(RTRIM(AI.[Warehouse])), '') AS [Warehouse],
            NULLIF(LTRIM(RTRIM(AI.[Location])), '') AS [Location],
            NULLIF(LTRIM(RTRIM(AI.[ShelfName])), '') AS [Shelf],
            NULLIF(LTRIM(RTRIM(AI.[BinName])), '') AS [Bin],
            AI.[Qty] AS [Quantity],
            UOM.[ShortName] AS [UnitOfMeasure],
            CU.[Code] AS [Currency],
            AI.[UnitCost],
            ISNULL(AI.[UnitCost], 0) + ISNULL(AI.[Freight], 0) + ISNULL(AI.[Insurance], 0) + ISNULL(AI.[Taxes], 0) + ISNULL(AI.[InstallationCost], 0) AS [TotalCost],
            ISNULL(ADH.[AccumlatedDepr], 0) AS [AccumulatedDepreciation],
            ISNULL(ADH.[NetBookValue], ISNULL(AI.[UnitCost], 0) + ISNULL(AI.[Freight], 0) + ISNULL(AI.[Insurance], 0) + ISNULL(AI.[Taxes], 0) + ISNULL(AI.[InstallationCost], 0)) AS [NetBookValue],
            AI.[EntryDate],
            AI.[ReceivedDate],
            CAST(ISNULL(AI.[IsActive], 1) AS BIT) AS [IsActive],
            AI.[CreatedDate],
            AI.[UpdatedDate],
            P.[TotalRecords]
        FROM PagedInventory P
        INNER JOIN [dbo].[AssetInventory] AI WITH (NOLOCK) ON AI.[AssetInventoryId] = P.[AssetInventoryId]
        LEFT JOIN [dbo].[Asset] A WITH (NOLOCK) ON A.[AssetRecordId] = AI.[AssetRecordId]
        LEFT JOIN [dbo].[Asset] ALT WITH (NOLOCK) ON ALT.[AssetRecordId] = AI.[AlternateAssetRecordId]
        LEFT JOIN [dbo].[Manufacturer] MF WITH (NOLOCK) ON MF.[ManufacturerId] = AI.[ManufacturerId]
        LEFT JOIN [dbo].[TangibleClass] TCD WITH (NOLOCK) ON TCD.[TangibleClassId] = AI.[TangibleClassId]
        LEFT JOIN [dbo].[DeprNonDeprTangibleAssets] DND WITH (NOLOCK) ON DND.[DeprNonDeprTangibleAssetsId] = AI.[DeprNonDeprTangibleAssetsId]
        LEFT JOIN [dbo].[TangibleClass] TCN WITH (NOLOCK) ON TCN.[TangibleClassId] = DND.[TangibleClassId]
        LEFT JOIN [dbo].[AssetIntangibleType] AIT WITH (NOLOCK) ON AIT.[AssetIntangibleTypeId] = A.[AssetIntangibleTypeId]
        LEFT JOIN [dbo].[Vendor] CV WITH (NOLOCK) ON CV.[VendorId] = AI.[CalibrationDefaultVendorId]
        LEFT JOIN [dbo].[AssetStatus] ST WITH (NOLOCK) ON ST.[AssetStatusId] = AI.[AssetStatusId]
        LEFT JOIN [dbo].[AssetInventoryStatus] INS WITH (NOLOCK) ON INS.[AssetInventoryStatusId] = AI.[InventoryStatusId]
        LEFT JOIN [dbo].[AssetAvailableStatus] ANS WITH (NOLOCK) ON ANS.[AssetAvailableStatusId] = AI.[InventoryStatusId]
        LEFT JOIN [dbo].[UnitOfMeasure] UOM WITH (NOLOCK) ON UOM.[UnitOfMeasureId] = AI.[UnitOfMeasureId]
        LEFT JOIN [dbo].[Currency] CU WITH (NOLOCK) ON CU.[CurrencyId] = AI.[CurrencyId]
        OUTER APPLY (
            SELECT TOP (1) MSD.[LastMSLevel]
            FROM [dbo].[AssetManagementStructureDetails] MSD WITH (NOLOCK)
            WHERE MSD.[ModuleID] IN (42, 43) AND MSD.[ReferenceID] = AI.[AssetInventoryId]
        ) MS
        OUTER APPLY (
            SELECT TOP (1) H.[AccumlatedDepr], H.[NetBookValue]
            FROM [dbo].[AssetDepreciationHistory] H WITH (NOLOCK)
            WHERE H.[AssetInventoryId] = AI.[AssetInventoryId] AND H.[IsActive] = 1 AND H.[IsDelete] = 0
            ORDER BY H.[ID] DESC
        ) ADH
        OUTER APPLY (   -- work order the asset is checked in to (PAS: "CHECKED IN TO WO" / "Unavailable - In Use")
            SELECT TOP (1) W.[WorkOrderNum]
            FROM [dbo].[CheckInCheckOutWorkOrderAsset] CI WITH (NOLOCK)
            INNER JOIN [dbo].[AssetAvailableStatus] CIS WITH (NOLOCK) ON CIS.[AssetAvailableStatusId] = CI.[InventoryStatusId]
                AND CIS.[Status] IN ('CHECKED IN TO WO', 'Unavailable - In Use')
            INNER JOIN [dbo].[WorkOrder] W WITH (NOLOCK) ON W.[WorkOrderId] = CI.[WorkOrderId]
            WHERE CI.[AssetInventoryId] = AI.[AssetInventoryId]
            ORDER BY CI.[CheckInCheckOutWorkOrderAssetId] DESC
        ) WO
        ORDER BY AI.[AssetInventoryId];
    END TRY
    BEGIN CATCH
        IF @@trancount > 0
            PRINT 'ROLLBACK'
        DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_PublicApi_GetAssetInventoryList'
              , @ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@MasterCompanyId, '') AS VARCHAR(100))
                                                   + '@Parameter2 = ''' + CAST(ISNULL(@EmployeeId, '') AS VARCHAR(100))
                                                   + '@Parameter3 = ''' + CAST(ISNULL(@PageNumber, '') AS VARCHAR(100))
                                                   + '@Parameter4 = ''' + CAST(ISNULL(@PageSize, '') AS VARCHAR(100))
                                                   + '@Parameter5 = ''' + CAST(ISNULL(@AssetId, '') AS VARCHAR(100))
                                                   + '@Parameter6 = ''' + CAST(ISNULL(@InventoryNumber, '') AS VARCHAR(100))
                                                   + '@Parameter7 = ''' + CAST(ISNULL(@IsActive, '') AS VARCHAR(100))
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