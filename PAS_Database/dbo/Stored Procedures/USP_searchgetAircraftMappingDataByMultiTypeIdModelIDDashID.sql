/***********************************************************
** File:   [USP_searchgetAircraftMappingDataByMultiTypeIdModelIDDashID]
** Author: Ayushi Patel
** Description: Get Aircraft Mapping Data by AircraftTypeId, AircraftModelId and DashNumberId filters
** Purpose:  
** Date:   2025-06-19

** RETURN VALUE: List of unique aircraft mappings grouped by AircraftTypeId, AircraftModelId, DashNumberId
**************************************************************
** Change History
**************************************************************
** PR   Date			Author			Change Description
** --   --------		-------			--------------------------------
   1   19-JUN-2025    AYUSHI PATEL	    Created

   exec USP_searchgetAircraftMappingDataByMultiTypeIdModelIDDashID 214,57,'247,251',null,1001145
***************************************************************/
CREATE   PROCEDURE [dbo].[USP_searchgetAircraftMappingDataByMultiTypeIdModelIDDashID]
    @AssetId BIGINT,
    @AircraftTypeId VARCHAR(MAX) = NULL,
    @AircraftModelId VARCHAR(MAX) = NULL,
    @DashNumberId VARCHAR(MAX) = NULL,
    @PartNumber VARCHAR(100) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        IF OBJECT_ID(N'tempdb..#AircraftType') IS NOT NULL DROP TABLE #AircraftType;
        IF OBJECT_ID(N'tempdb..#AircraftModel') IS NOT NULL DROP TABLE #AircraftModel;
        IF OBJECT_ID(N'tempdb..#DashNumber') IS NOT NULL DROP TABLE #DashNumber;

        CREATE TABLE #AircraftType (Id BIGINT);
        CREATE TABLE #AircraftModel (Id BIGINT);
        CREATE TABLE #DashNumber (Id BIGINT);

        IF ISNULL(@AircraftTypeId, '') <> ''
        BEGIN
            INSERT INTO #AircraftType (Id)
            SELECT CAST(Value AS BIGINT)
            FROM STRING_SPLIT(@AircraftTypeId, ',')
            WHERE RTRIM(LTRIM(Value)) <> '';
        END

        IF ISNULL(@AircraftModelId, '') <> ''
        BEGIN
            INSERT INTO #AircraftModel (Id)
            SELECT CAST(Value AS BIGINT)
            FROM STRING_SPLIT(@AircraftModelId, ',')
            WHERE RTRIM(LTRIM(Value)) <> '';
        END

        IF ISNULL(@DashNumberId, '') <> ''
        BEGIN
            INSERT INTO #DashNumber (Id)
            SELECT CAST(Value AS BIGINT)
            FROM STRING_SPLIT(@DashNumberId, ',')
            WHERE RTRIM(LTRIM(Value)) <> '';
        END

        ;WITH FilteredData AS (
            SELECT
                ac.ItemMasterId,
                a.AssetId,
                imap.AircraftTypeId,
                imap.AircraftModelId,
                imap.DashNumberId,
                imap.DashNumber,
                imap.AircraftType,
                imap.AircraftModel,
                imap.Memo,
                imap.MasterCompanyId,
                imap.IsActive,
                imap.IsDeleted,
                im.PartNumber,
                im.PartDescription,
                ISNULL(ma.Name, '') AS ManufacturerName,
                ISNULL(ig.ItemGroupCode, '') AS ItemGroup,
                ROW_NUMBER() OVER (
                    PARTITION BY imap.AircraftTypeId, imap.AircraftModelId, imap.DashNumberId
                    ORDER BY imap.ItemMasterAircraftMappingId
                ) AS RowRank
            FROM dbo.ItemMasterAircraftMapping imap WITH (NOLOCK)
            INNER JOIN dbo.AssetCapes ac WITH (NOLOCK) ON imap.ItemMasterId = ac.ItemMasterId
            INNER JOIN dbo.Asset a WITH (NOLOCK) ON ac.AssetRecordId = a.AssetRecordId
            INNER JOIN dbo.ItemMaster im WITH (NOLOCK) ON ac.ItemMasterId = im.ItemMasterId
            LEFT JOIN dbo.Itemgroup ig WITH (NOLOCK) ON im.ItemGroupId = ig.ItemGroupId
            LEFT JOIN dbo.Manufacturer ma WITH (NOLOCK) ON im.ManufacturerId = ma.ManufacturerId
            WHERE ac.AssetRecordId = @AssetId
                AND ISNULL(ac.IsActive,0) = 1 AND ISNULL(ac.IsDeleted,0) = 0
                AND ISNULL(imap.IsActive,0) = 1 AND ISNULL(imap.IsDeleted,0) = 0
                AND (@PartNumber IS NULL OR im.PartNumber = @PartNumber)
                AND (
                    NOT EXISTS (SELECT 1 FROM #AircraftType) OR imap.AircraftTypeId IN (SELECT Id FROM #AircraftType)
                )
                AND (
                    NOT EXISTS (SELECT 1 FROM #AircraftModel) OR imap.AircraftModelId IN (SELECT Id FROM #AircraftModel)
                )
                AND (
                    NOT EXISTS (SELECT 1 FROM #DashNumber) OR imap.DashNumberId IN (SELECT Id FROM #DashNumber)
                )
        )
        SELECT
            ItemMasterId,
            AssetId,
            AircraftTypeId,
            AircraftModelId,
            DashNumberId,
            DashNumber,
            AircraftType,
            AircraftModel,
            Memo,
            MasterCompanyId,
            IsActive,
            IsDeleted,
            PartNumber,
            PartDescription,
            ManufacturerName,
            ItemGroup
        FROM FilteredData
        WHERE RowRank = 1
        ORDER BY AircraftTypeId, AircraftModelId, DashNumberId;

    END TRY
    BEGIN CATCH
        DECLARE @ErrorLogID INT,
                @DatabaseName VARCHAR(100) = DB_NAME(),
                @AdhocComments VARCHAR(150) = 'USP_searchgetAircraftMappingDataByMultiTypeIdModelIDDashID',
                @ProcedureParameters VARCHAR(3000) = '@AssetId = ' + CAST(ISNULL(@AssetId, 0) AS VARCHAR),
                @ApplicationName VARCHAR(100) = 'PAS';

        EXEC spLogException 
            @DatabaseName = @DatabaseName,
            @AdhocComments = @AdhocComments,
            @ProcedureParameters = @ProcedureParameters,
            @ApplicationName = @ApplicationName,
            @ErrorLogID = @ErrorLogID OUTPUT;

        RAISERROR('Unexpected error occurred in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID);
        RETURN (1);
    END CATCH
END