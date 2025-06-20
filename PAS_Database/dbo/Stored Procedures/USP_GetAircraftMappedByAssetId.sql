/*************************************************************           
 ** File: [USP_GetAircraftMappedByAssetId]        
 ** Author:   Ayushi Patel
 ** Description: Get Asset Inventory Adjustment Data By Asset Inventory Id    
 ** Purpose:         
 ** Date:   18-06-2025       
          
 ** PARAMETERS: @AssetInventoryId BIGINT
         
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    18-06-2025   Ayushi Patel  Created
     
 EXECUTE [USP_GetAircraftMappedByAssetId] 214
**************************************************************/ 
CREATE   PROCEDURE [dbo].[USP_GetAircraftMappedByAssetId]
    @AssetRecordId BIGINT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        SELECT DISTINCT
            it.DashNumber,
            it.AircraftType,
            it.AircraftModel,
            iM.PartNumber,
            iM.PartDescription,
            ISNULL(ig.ItemGroupCode, '') AS ItemGroup,
            ISNULL(ma.Name, '') AS ManufacturerName,
            it.ATAReferenceId,
            it.ATAReference,
            it.Level1,
            it.Level2,
            it.Level3,
            (
                it.Level1 +
                CASE WHEN ISNULL(it.Level2, '') <> '' THEN '-' + it.Level2 ELSE '' END +
                CASE WHEN ISNULL(it.Level3, '') <> '' THEN '-' + it.Level3 ELSE '' END
            ) AS ATAChapter,
            CASE WHEN it.ATAChapterId > 0 THEN it.ATAChapterId ELSE 0 END AS ATAChapterId
        FROM dbo.AssetCapes ac WITH (NOLOCK)
        INNER JOIN dbo.ItemMasterAircraftMapping it WITH (NOLOCK) ON ac.ItemMasterId = it.ItemMasterId
        INNER JOIN dbo.ItemMaster iM WITH (NOLOCK) ON it.ItemMasterId = iM.ItemMasterId
        LEFT JOIN dbo.ItemGroup ig WITH (NOLOCK) ON iM.ItemGroupId = ig.ItemGroupId
        LEFT JOIN dbo.Manufacturer ma WITH (NOLOCK) ON iM.ManufacturerId = ma.ManufacturerId
        INNER JOIN dbo.Asset a WITH (NOLOCK) ON ac.AssetRecordId = a.AssetRecordId
        WHERE ISNULL(ac.IsDeleted,0) = 0
            AND ISNULL(ac.IsActive,0) = 1
            AND ISNULL(it.IsActive,0) = 1
            AND ISNULL(it.IsDeleted,0) = 0
            AND ISNULL(iM.IsActive,0) = 1
            AND ISNULL(iM.IsDeleted,0) = 0
            AND ac.AssetRecordId = @AssetRecordId
    END TRY
    BEGIN CATCH
        DECLARE @ErrorLogID INT,
                @DatabaseName VARCHAR(100) = DB_NAME(),
                @AdhocComments VARCHAR(150) = 'USP_GetAircraftMappedByAssetId',
                @ProcedureParameters VARCHAR(3000) = '@AssetRecordId = ' + CAST(@AssetRecordId AS VARCHAR),
                @ApplicationName VARCHAR(100) = 'PAS';

        EXEC spLogException 
            @DatabaseName = @DatabaseName,
            @AdhocComments = @AdhocComments,
            @ProcedureParameters = @ProcedureParameters,
            @ApplicationName = @ApplicationName,
            @ErrorLogID = @ErrorLogID OUTPUT;

        RAISERROR('Unexpected Error Occurred in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID);
        RETURN (1);
    END CATCH
END