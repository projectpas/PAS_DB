/*************************************************************           
 ** File:   [USP_GetCapesListByAssetId]         
 ** Author:   Ayushi Patel
 ** Description: Get Cape list by AssetRecordId    
 ** Purpose:         
 ** Date:   17-06-2025       
          
 ** PARAMETERS: @AssetRecordId BIGINT
         
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    02/23/2021   Ayushi Patel  Created
     
 EXECUTE [USP_GetCapesListByAssetId] 214
**************************************************************/ 
CREATE   PROCEDURE [dbo].[USP_GetCapesListByAssetId]
    @AssetRecordId BIGINT
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        SELECT 
            ac.AssetCapesId,
            ac.ItemMasterId,
            im.PartNumber,
            im.PartDescription,
            captype.Description AS captypedescription,
            act.Description AS manufacturer,
            acm.ModelName AS modelname,
            dn.DashNumber AS dashnumber,
            ISNULL(ac.IsActive,0) AS IsActive,
            ac.AircraftTypeId,
            ac.AircraftModelId
        FROM dbo.AssetCapes ac WITH (NOLOCK)
        INNER JOIN dbo.ItemMaster im WITH (NOLOCK) ON ac.ItemMasterId = im.ItemMasterId
        INNER JOIN dbo.CapabilityType captype WITH (NOLOCK) ON ac.CapabilityId = captype.CapabilityTypeId
        INNER JOIN dbo.AircraftType act WITH (NOLOCK) ON ac.AircraftTypeId = act.AircraftTypeId
        LEFT JOIN dbo.AircraftModel acm WITH (NOLOCK) ON ac.AircraftModelId = acm.AircraftModelId
        LEFT JOIN dbo.AircraftDashNumber dn WITH (NOLOCK) ON ac.AircraftDashNumberId = dn.DashNumberId
        WHERE ac.AssetRecordId = @AssetRecordId
          AND ISNULL(ac.IsDeleted,0) = 0
    END TRY
    BEGIN CATCH
        DECLARE @ErrorLogID INT,
                @DatabaseName VARCHAR(100) = DB_NAME(),
                @AdhocComments VARCHAR(150) = 'USP_GetCapesListByAssetId',
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