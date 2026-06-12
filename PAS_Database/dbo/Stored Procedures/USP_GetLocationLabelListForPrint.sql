/*********************
** Author:  <Sumit Kumar>
** Create date: <11/06/2026>
** Description: <Get location hierarchy data for Location Label Print grid>
**********************
** Change History
**********************
** PR   Date        Author          Change Description
** --   --------    -------         --------------------------------
** 1    11/06/2026   Sumit Kumar      Created Get Location Label List For Print
**********************/
CREATE PROCEDURE [dbo].[USP_GetLocationLabelListForPrint]
    @MasterCompanyId   INT,
    @EmployeeId        BIGINT = NULL,
    @PageNumber        INT = NULL,
    @PageSize          INT = NULL,
    @SortColumn        VARCHAR(50) = NULL,
    @SortOrder         INT = NULL,
    @PrintLocation     BIT = 0,
    @PrintShelf        BIT = 0,
    @PrintBin          BIT = 0
AS
BEGIN
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
    SET NOCOUNT ON;

    BEGIN TRY
        SET @PageNumber   = ISNULL(@PageNumber, 1);
        SET @PageSize     = ISNULL(@PageSize, 1000000);

        DECLARE @RecordFrom INT = (@PageNumber - 1) * @PageSize;
        DECLARE @SortCol VARCHAR(50) = UPPER(ISNULL(@SortColumn, 'SITENAME'));
        
        SET @SortOrder = ISNULL(@SortOrder, 1);

        ;WITH LocationLabelPrintData AS
        (
            -- Case 1: @PrintBin = 1 (Fetch Bins. Since they must have Shelf and Location, inner joins are used)
            SELECT DISTINCT
                CASE WHEN @PrintLocation = 1 THEN L.LocationId ELSE CAST(NULL AS BIGINT) END AS LocationId,
                CASE WHEN @PrintLocation = 1 THEN L.Name ELSE CAST(NULL AS VARCHAR(50)) END AS LocationName,
                CASE WHEN @PrintShelf = 1 THEN Sh.ShelfId ELSE CAST(NULL AS BIGINT) END AS ShelfId,
                CASE WHEN @PrintShelf = 1 THEN Sh.Name ELSE CAST(NULL AS VARCHAR(50)) END AS ShelfName,
                B.BinId AS BinId,
                B.Name AS BinName,
                W.WarehouseId,
                W.Name AS WarehouseName,
                S.SiteId,
                S.Name AS SiteName,
                S.LegalEntityId,
                ISNULL(LE.Name, '') AS LegalEntityName
            FROM dbo.Bin B WITH (NOLOCK)
            INNER JOIN dbo.Shelf Sh WITH (NOLOCK) ON B.ShelfId = Sh.ShelfId AND Sh.IsDeleted = 0 AND Sh.IsActive = 1
            INNER JOIN dbo.Location L WITH (NOLOCK) ON Sh.LocationId = L.LocationId AND L.IsDeleted = 0 AND L.IsActive = 1
            INNER JOIN dbo.Warehouse W WITH (NOLOCK) ON L.WarehouseId = W.WarehouseId AND W.MasterCompanyId = @MasterCompanyId AND W.IsDeleted = 0 AND W.IsActive = 1
            INNER JOIN dbo.Site S WITH (NOLOCK) ON W.SiteId = S.SiteId AND S.MasterCompanyId = @MasterCompanyId AND S.IsDeleted = 0 AND S.IsActive = 1
            LEFT JOIN dbo.LegalEntity LE WITH (NOLOCK) ON S.LegalEntityId = LE.LegalEntityId
            WHERE @PrintBin = 1
              AND B.MasterCompanyId = @MasterCompanyId
              AND B.IsDeleted = 0
              AND B.IsActive = 1

            UNION ALL

            -- Case 2: @PrintBin = 0 AND @PrintShelf = 1 (Fetch Shelves. Since they must have Location, inner joins are used)
            SELECT DISTINCT
                CASE WHEN @PrintLocation = 1 THEN L.LocationId ELSE CAST(NULL AS BIGINT) END AS LocationId,
                CASE WHEN @PrintLocation = 1 THEN L.Name ELSE CAST(NULL AS VARCHAR(50)) END AS LocationName,
                Sh.ShelfId AS ShelfId,
                Sh.Name AS ShelfName,
                CAST(NULL AS BIGINT) AS BinId,
                CAST(NULL AS VARCHAR(50)) AS BinName,
                W.WarehouseId,
                W.Name AS WarehouseName,
                S.SiteId,
                S.Name AS SiteName,
                S.LegalEntityId,
                ISNULL(LE.Name, '') AS LegalEntityName
            FROM dbo.Shelf Sh WITH (NOLOCK)
            INNER JOIN dbo.Location L WITH (NOLOCK) ON Sh.LocationId = L.LocationId AND L.IsDeleted = 0 AND L.IsActive = 1
            INNER JOIN dbo.Warehouse W WITH (NOLOCK) ON L.WarehouseId = W.WarehouseId AND W.MasterCompanyId = @MasterCompanyId AND W.IsDeleted = 0 AND W.IsActive = 1
            INNER JOIN dbo.Site S WITH (NOLOCK) ON W.SiteId = S.SiteId AND S.MasterCompanyId = @MasterCompanyId AND S.IsDeleted = 0 AND S.IsActive = 1
            LEFT JOIN dbo.LegalEntity LE WITH (NOLOCK) ON S.LegalEntityId = LE.LegalEntityId
            WHERE @PrintBin = 0 AND @PrintShelf = 1
              AND Sh.MasterCompanyId = @MasterCompanyId
              AND Sh.IsDeleted = 0
              AND Sh.IsActive = 1

            UNION ALL

            -- Case 3: @PrintBin = 0 AND @PrintShelf = 0 AND @PrintLocation = 1 (Fetch Locations only)
            SELECT DISTINCT
                L.LocationId AS LocationId,
                L.Name AS LocationName,
                CAST(NULL AS BIGINT) AS ShelfId,
                CAST(NULL AS VARCHAR(50)) AS ShelfName,
                CAST(NULL AS BIGINT) AS BinId,
                CAST(NULL AS VARCHAR(50)) AS BinName,
                W.WarehouseId,
                W.Name AS WarehouseName,
                S.SiteId,
                S.Name AS SiteName,
                S.LegalEntityId,
                ISNULL(LE.Name, '') AS LegalEntityName
            FROM dbo.Location L WITH (NOLOCK)
            INNER JOIN dbo.Warehouse W WITH (NOLOCK) ON L.WarehouseId = W.WarehouseId AND W.MasterCompanyId = @MasterCompanyId AND W.IsDeleted = 0 AND W.IsActive = 1
            INNER JOIN dbo.Site S WITH (NOLOCK) ON W.SiteId = S.SiteId AND S.MasterCompanyId = @MasterCompanyId AND S.IsDeleted = 0 AND S.IsActive = 1
            LEFT JOIN dbo.LegalEntity LE WITH (NOLOCK) ON S.LegalEntityId = LE.LegalEntityId
            WHERE @PrintBin = 0 AND @PrintShelf = 0 AND @PrintLocation = 1
              AND L.MasterCompanyId = @MasterCompanyId
              AND L.IsDeleted = 0
              AND L.IsActive = 1
        )
        SELECT * INTO #TempResults FROM LocationLabelPrintData;

        DECLARE @Count INT;
        SELECT @Count = COUNT(1) FROM #TempResults;

        SELECT
            LocationId,
            LocationName,
            ShelfId,
            ShelfName,
            BinId,
            BinName,
            WarehouseId,
            WarehouseName,
            SiteId,
            SiteName,
            LegalEntityId,
            LegalEntityName,
            @Count AS NumberOfItems
        FROM #TempResults
        ORDER BY
            CASE WHEN (@SortOrder = 1 AND @SortCol = 'SITENAME') THEN SiteName END ASC,
            CASE WHEN (@SortOrder = -1 AND @SortCol = 'SITENAME') THEN SiteName END DESC,
            CASE WHEN (@SortOrder = 1 AND @SortCol = 'WAREHOUSENAME') THEN WarehouseName END ASC,
            CASE WHEN (@SortOrder = -1 AND @SortCol = 'WAREHOUSENAME') THEN WarehouseName END DESC,
            CASE WHEN (@SortOrder = 1 AND @SortCol = 'LOCATIONNAME') THEN LocationName END ASC,
            CASE WHEN (@SortOrder = -1 AND @SortCol = 'LOCATIONNAME') THEN LocationName END DESC,
            CASE WHEN (@SortOrder = 1 AND @SortCol = 'SHELFNAME') THEN ShelfName END ASC,
            CASE WHEN (@SortOrder = -1 AND @SortCol = 'SHELFNAME') THEN ShelfName END DESC,
            CASE WHEN (@SortOrder = 1 AND @SortCol = 'BINNAME') THEN BinName END ASC,
            CASE WHEN (@SortOrder = -1 AND @SortCol = 'BINNAME') THEN BinName END DESC,
            CASE WHEN (@SortOrder = 1 AND @SortCol = 'LEGALENTITYNAME') THEN LegalEntityName END ASC,
            CASE WHEN (@SortOrder = -1 AND @SortCol = 'LEGALENTITYNAME') THEN LegalEntityName END DESC
        OFFSET @RecordFrom ROWS
        FETCH NEXT @PageSize ROWS ONLY;

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRAN;

        DECLARE @ErrorLogID INT,
                @DatabaseName VARCHAR(100) = DB_NAME(),
                @AdhocComments VARCHAR(150) = 'USP_GetLocationLabelListForPrint',
                @ProcedureParameters VARCHAR(3000) =
                    '@MasterCompanyId = ''' + CAST(ISNULL(@MasterCompanyId, 0) AS VARCHAR(20)) + ''', '
                    + '@EmployeeId = ''' + CAST(ISNULL(@EmployeeId, 0) AS VARCHAR(20)) + ''', '
                    + '@PageNumber = ''' + CAST(ISNULL(@PageNumber, 0) AS VARCHAR(20)) + ''', '
                    + '@PageSize = ''' + CAST(ISNULL(@PageSize, 0) AS VARCHAR(20)) + ''', '
                    + '@SortColumn = ''' + ISNULL(@SortColumn, '') + ''', '
                    + '@SortOrder = ''' + CAST(ISNULL(@SortOrder, 0) AS VARCHAR(20)) + ''', '
                    + '@PrintLocation = ''' + CAST(ISNULL(@PrintLocation, 0) AS VARCHAR(5)) + ''', '
                    + '@PrintShelf = ''' + CAST(ISNULL(@PrintShelf, 0) AS VARCHAR(5)) + ''', '
                    + '@PrintBin = ''' + CAST(ISNULL(@PrintBin, 0) AS VARCHAR(5)) + '''',
                @ApplicationName VARCHAR(100) = 'PAS';

        EXEC spLogException
            @DatabaseName = @DatabaseName,
            @AdhocComments = @AdhocComments,
            @ProcedureParameters = @ProcedureParameters,
            @ApplicationName = @ApplicationName,
            @ErrorLogID = @ErrorLogID OUTPUT;

        RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID);
        RETURN (1);
    END CATCH
END
