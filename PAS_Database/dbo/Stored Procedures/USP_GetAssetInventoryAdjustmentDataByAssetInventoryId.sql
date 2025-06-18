/*************************************************************           
 ** File:  [USP_GetAssetInventoryAdjustmentDataByAssetInventoryId]         
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
     
 EXECUTE [USP_GetAssetInventoryAdjustmentDataByAssetInventoryId] 517
**************************************************************/ 
CREATE   PROCEDURE [dbo].[USP_GetAssetInventoryAdjustmentDataByAssetInventoryId]
    @AssetInventoryId BIGINT
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        DECLARE @AssetIdTypeId INT;

        SELECT @AssetIdTypeId = AssetInventoryAdjustmentDataTypeId
        FROM dbo.AssetInventoryAdjustmentDataType WITH (NOLOCK)
        WHERE Description = 'Asset ID';

        SELECT DISTINCT
            a.AssetInventoryAdjustmentId,
            a.AssetInventoryAdjustmentDataTypeId,
            d.Description AS AdjustmentDataType,
            a.AssetInventoryId,
            CASE 
                WHEN a.AssetInventoryAdjustmentDataTypeId = @AssetIdTypeId
                     THEN CAST(af.AssetId AS NVARCHAR(MAX))
                ELSE a.ChangedFrom
            END AS ChangedFrom,
            CASE 
                WHEN a.AssetInventoryAdjustmentDataTypeId = @AssetIdTypeId
                     THEN CAST(at.AssetId AS NVARCHAR(MAX))
                ELSE a.ChangedTo
            END AS ChangedTo,
            a.AdjustmentReason,
            a.AdjustmentMemo,
            a.CreatedDate,
            a.CreatedBy,
            a.UpdatedDate,
            a.UpdatedBy
        FROM dbo.AssetInventoryAdjustment a WITH (NOLOCK)
        INNER JOIN dbo.AssetInventoryAdjustmentDataType d WITH (NOLOCK)
            ON a.AssetInventoryAdjustmentDataTypeId = d.AssetInventoryAdjustmentDataTypeId
        LEFT JOIN dbo.Asset af WITH (NOLOCK)
            ON a.AssetInventoryAdjustmentDataTypeId = @AssetIdTypeId 
               AND TRY_CAST(a.ChangedFrom AS BIGINT) = af.AssetRecordId
        LEFT JOIN dbo.Asset at WITH (NOLOCK)
            ON a.AssetInventoryAdjustmentDataTypeId = @AssetIdTypeId 
               AND TRY_CAST(a.ChangedTo AS BIGINT) = at.AssetRecordId
        WHERE a.AssetInventoryId = @AssetInventoryId
          AND a.IsDeleted = 0
        ORDER BY a.CreatedDate DESC;
    END TRY

     BEGIN CATCH
        DECLARE @ErrorLogID INT,
                @DatabaseName VARCHAR(100) = DB_NAME(),
                @AdhocComments VARCHAR(150) = 'USP_GetAssetInventoryAdjustmentDataByAssetInventoryId',
                @ProcedureParameters VARCHAR(3000) = '@AssetInventoryId = ' + CAST(@AssetInventoryId AS VARCHAR),
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