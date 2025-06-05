/***************************************************************  
 ** File: [USP_GetAircraftMappingDataByFilters]            
 ** Author: Ayushi Patel  
 ** Description: Get Aircraft Mapping Data based on AircraftTypeId, AircraftModelId, DashNumberId and PartNumber filters
 ** Purpose:   
 ** Date:  03-JUN-2025  

 ** Change History             
 **************************************************************             
 ** PR   Date				Author  				Change Description              
 ** --   --------			-------				--------------------------------            
    1    2025-06-03		  Ayushi Patel				Created
 ***************************************************************/ 
CREATE   PROCEDURE [dbo].[USP_GetAircraftMappingDataByFilters]
    @PublicationID BIGINT,
    @PartNumber VARCHAR(100) = NULL,
    @AircraftTypeIdList VARCHAR(MAX) = NULL,  
    @AircraftModelIdList VARCHAR(MAX) = NULL, 
    @DashNumberIdList VARCHAR(MAX) = NULL     
AS
BEGIN
    SET NOCOUNT ON;
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

    BEGIN TRY

		IF OBJECT_ID(N'tempdb..#AircraftTypeIds') IS NOT NULL
		BEGIN
			DROP TABLE #AircraftTypeIds
		END
		IF OBJECT_ID(N'tempdb..#AircraftModelIds') IS NOT NULL
		BEGIN
			DROP TABLE #AircraftModelIds
		END
		IF OBJECT_ID(N'tempdb..#DashNumberIds') IS NOT NULL
		BEGIN
			DROP TABLE #DashNumberIds
		END

        CREATE TABLE #AircraftTypeIds (Id BIGINT);
        CREATE TABLE #AircraftModelIds (Id BIGINT);
        CREATE TABLE #DashNumberIds (Id BIGINT);

        IF @AircraftTypeIdList IS NOT NULL
        BEGIN
            INSERT INTO #AircraftTypeIds (Id)
            SELECT CAST([Value] AS BIGINT)
            FROM STRING_SPLIT(@AircraftTypeIdList, ',');
        END

        IF @AircraftModelIdList IS NOT NULL
        BEGIN
            INSERT INTO #AircraftModelIds (Id)
            SELECT CAST([Value] AS BIGINT)
            FROM STRING_SPLIT(@AircraftModelIdList, ',');
        END

        IF @DashNumberIdList IS NOT NULL
        BEGIN
            INSERT INTO #DashNumberIds (Id)
            SELECT CAST([Value] AS BIGINT)
            FROM STRING_SPLIT(@DashNumberIdList, ',');
        END

        SELECT DISTINCT
            pim.ItemMasterId,
            p.PublicationId,
            imap.AircraftTypeId,
            imap.AircraftModelId,
            imap.DashNumberId,
            imap.DashNumber,
            imap.AircraftType,
            imap.AircraftModel,
            imap.Memo,
            imap.MasterCompanyId,
            ISNULL(imap.IsActive,0) AS IsActive,
            ISNULL(imap.IsDeleted,0) AS IsDeleted,
            im.PartNumber,
            im.PartDescription,
            ISNULL(ma.Name, '') AS ManufacturerName,
            ISNULL(ig.ItemGroupCode, '') AS ItemGroup
        FROM dbo.ItemMasterAircraftMapping imap WITH (NOLOCK)
        INNER JOIN dbo.PublicationItemMasterMapping pim WITH (NOLOCK)
            ON imap.ItemMasterId = pim.ItemMasterId
        INNER JOIN dbo.Publication p WITH (NOLOCK)
            ON pim.PublicationRecordId = p.PublicationRecordId
        INNER JOIN dbo.ItemMaster im WITH (NOLOCK)
            ON pim.ItemMasterId = im.ItemMasterId
        LEFT JOIN dbo.Itemgroup ig WITH (NOLOCK)
            ON im.ItemGroupId = ig.ItemGroupId
        LEFT JOIN dbo.Manufacturer ma WITH (NOLOCK)
            ON im.ManufacturerId = ma.ManufacturerId
        WHERE pim.PublicationRecordId = @PublicationID
            AND ISNULL(pim.IsActive,0) = 1 AND ISNULL(pim.IsDeleted,0) = 0
            AND ISNULL(imap.IsActive,0) = 1 AND ISNULL(imap.IsDeleted,0) = 0
            AND (@PartNumber IS NULL OR im.PartNumber = @PartNumber)
            AND (
                (NOT EXISTS (SELECT 1 FROM #AircraftTypeIds) OR imap.AircraftTypeId IN (SELECT Id FROM #AircraftTypeIds)) AND
                (NOT EXISTS (SELECT 1 FROM #AircraftModelIds) OR imap.AircraftModelId IN (SELECT Id FROM #AircraftModelIds)) AND
                (NOT EXISTS (SELECT 1 FROM #DashNumberIds) OR imap.DashNumberId IN (SELECT Id FROM #DashNumberIds))
            );


    END TRY
    BEGIN CATCH
		SELECT
		ERROR_NUMBER() AS ErrorNumber,
		ERROR_STATE() AS ErrorState,
		ERROR_SEVERITY() AS ErrorSeverity,
		ERROR_PROCEDURE() AS ErrorProcedure,
		ERROR_LINE() AS ErrorLine,
		ERROR_MESSAGE() AS ErrorMessage;
        DECLARE @ErrorLogID INT, 
                @DatabaseName VARCHAR(100) = DB_NAME(),
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
                @AdhocComments VARCHAR(150) = 'USP_GetAircraftMappingDataByFilters',
                @ProcedureParameters VARCHAR(3000) = '',
                @ApplicationName VARCHAR(100) = 'PAS';
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
        EXEC dbo.spLogException 
            @DatabaseName = @DatabaseName,
            @AdhocComments = @AdhocComments,
            @ProcedureParameters = @ProcedureParameters,
            @ApplicationName = @ApplicationName,
            @ErrorLogID = @ErrorLogID OUTPUT;

        RAISERROR ('Unexpected Error Occurred. Inform Support with Error Number: %d', 16, 1, @ErrorLogID);
        RETURN (1);
    END CATCH 
END