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
            SELECT DISTINCT
                CASE WHEN @PrintLocation = 1 THEN L.LocationId END AS LocationId,
                CASE WHEN @PrintLocation = 1 THEN L.Name END AS LocationName,

                CASE WHEN @PrintShelf = 1 THEN Sh.ShelfId END AS ShelfId,
                CASE WHEN @PrintShelf = 1 THEN Sh.Name END AS ShelfName,

                CASE WHEN @PrintBin = 1 THEN B.BinId END AS BinId,
                CASE WHEN @PrintBin = 1 THEN B.Name END AS BinName,

                W.WarehouseId,
                W.Name AS WarehouseName,
                S.SiteId,
                S.Name AS SiteName,
                S.LegalEntityId,
                ISNULL(LE.Name,'') AS LegalEntityName
            FROM dbo.Location L WITH(NOLOCK) INNER JOIN dbo.Warehouse W WITH(NOLOCK) ON L.WarehouseId = W.WarehouseId
            INNER JOIN dbo.Site S WITH(NOLOCK) ON W.SiteId = S.SiteId
            LEFT JOIN dbo.Shelf Sh WITH(NOLOCK) ON Sh.LocationId = L.LocationId AND Sh.IsDeleted = 0 AND Sh.IsActive = 1
            LEFT JOIN dbo.Bin B WITH(NOLOCK) ON B.ShelfId = Sh.ShelfId AND B.IsDeleted = 0 AND B.IsActive = 1
            LEFT JOIN dbo.LegalEntity LE WITH(NOLOCK) ON S.LegalEntityId = LE.LegalEntityId
            WHERE
                L.MasterCompanyId = @MasterCompanyId
                AND L.IsDeleted = 0
                AND L.IsActive = 1
                AND W.MasterCompanyId = @MasterCompanyId
                AND W.IsDeleted = 0
                AND W.IsActive = 1
                AND S.MasterCompanyId = @MasterCompanyId
                AND S.IsDeleted = 0
                AND S.IsActive = 1

                AND (
                        (@PrintBin = 1 AND B.BinId IS NOT NULL)
                    OR (@PrintBin = 0 AND @PrintShelf = 1 AND Sh.ShelfId IS NOT NULL)
                    OR (@PrintBin = 0 AND @PrintShelf = 0 AND @PrintLocation = 1)
                    )
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