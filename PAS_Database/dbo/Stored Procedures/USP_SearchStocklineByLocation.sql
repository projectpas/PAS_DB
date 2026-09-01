/*************************************************************
 ** File:   [USP_SearchStocklineByLocation]
 ** Description: Searches Stockline records by one or more Site/Warehouse/Location/Shelf/Bin ids.
                 Each dimension is optional - an empty table-valued parameter means "no filter on that dimension".
                 Supports server-side paging, sorting and per-column filtering.
 ** Date:   08/17/2026
 ** Author:  Nakul

 ** PARAMETERS:

 ** RETURN VALUE:
 **************************************************************
 ** Change History
 **************************************************************
 ** PR   Date         Author		Change Description
 ** --   --------     -------		--------------------------------
    1    08/17/2026  Nakul     Created

-- EXEC USP_SearchStocklineByLocation
************************************************************************/

CREATE     PROCEDURE [dbo].[USP_SearchStocklineByLocation]
	@tbl_SiteIds TVP_BigInt READONLY,
	@tbl_WarehouseIds TVP_BigInt READONLY,
	@tbl_LocationIds TVP_BigInt READONLY,
	@tbl_ShelfIds TVP_BigInt READONLY,
	@tbl_BinIds TVP_BigInt READONLY,
	@MasterCompanyId INT,
	@PageNumber INT = 1,
	@PageSize INT = 20,
	@SortColumn VARCHAR(50) = NULL,
	@SortOrder INT = 1,
	@PartNumber VARCHAR(200) = NULL,
	@PartDescription VARCHAR(200) = NULL,
	@Manufacturer VARCHAR(200) = NULL,
	@Condition VARCHAR(50) = NULL,
	@StockLineNumber VARCHAR(50) = NULL,
	@ControlNumber VARCHAR(50) = NULL,
	@SerialNumber VARCHAR(50) = NULL,
	@QuantityOnHand VARCHAR(50) = NULL,
	@QuantityAvailable VARCHAR(50) = NULL,
	@Site VARCHAR(200) = NULL,
	@Warehouse VARCHAR(200) = NULL,
	@Location VARCHAR(200) = NULL,
	@Shelf VARCHAR(200) = NULL,
	@Bin VARCHAR(200) = NULL
AS
BEGIN

 SET NOCOUNT ON;

  BEGIN TRY
    BEGIN
		DECLARE @RecordFrom INT;
		SET @RecordFrom = (@PageNumber - 1) * @PageSize;

		IF @SortColumn IS NULL OR @SortColumn = ''
		BEGIN
			SET @SortColumn = 'StockLineId';
			SET @SortOrder = -1;
		END

		;WITH Result AS (
			SELECT
				s.[StockLineId],
				s.[PartNumber],
				s.[PNDescription] AS [PartDescription],
				s.[StockLineNumber],
				s.[ControlNumber],
				s.[IdNumber],
				s.[Manufacturer],
				s.[Condition],
				s.[SerialNumber],
				s.[QuantityOnHand],
				s.[QuantityAvailable],
				s.[Site],
				s.[Warehouse],
				s.[Location],
				s.[Shelf],
				s.[Bin]
			FROM dbo.Stockline s WITH (NOLOCK)
			WHERE s.MasterCompanyId = @MasterCompanyId
				AND (NOT EXISTS (SELECT 1 FROM @tbl_SiteIds) OR s.SiteId IN (SELECT [Value] FROM @tbl_SiteIds))
				AND (NOT EXISTS (SELECT 1 FROM @tbl_WarehouseIds) OR s.WarehouseId IN (SELECT [Value] FROM @tbl_WarehouseIds))
				AND (NOT EXISTS (SELECT 1 FROM @tbl_LocationIds) OR s.LocationId IN (SELECT [Value] FROM @tbl_LocationIds))
				AND (NOT EXISTS (SELECT 1 FROM @tbl_ShelfIds) OR s.ShelfId IN (SELECT [Value] FROM @tbl_ShelfIds))
				AND (NOT EXISTS (SELECT 1 FROM @tbl_BinIds) OR s.BinId IN (SELECT [Value] FROM @tbl_BinIds))
				AND s.QuantityOnHand > 0
		),
		FinalResult AS (
			SELECT * FROM Result rs
			WHERE
				(ISNULL(@PartNumber, '') = '' OR rs.PartNumber LIKE '%' + @PartNumber + '%')
				AND (ISNULL(@PartDescription, '') = '' OR rs.PartDescription LIKE '%' + @PartDescription + '%')
				AND (ISNULL(@Manufacturer, '') = '' OR rs.Manufacturer LIKE '%' + @Manufacturer + '%')
				AND (ISNULL(@Condition, '') = '' OR rs.Condition LIKE '%' + @Condition + '%')
				AND (ISNULL(@StockLineNumber, '') = '' OR rs.StockLineNumber LIKE '%' + @StockLineNumber + '%')
				AND (ISNULL(@ControlNumber, '') = '' OR rs.ControlNumber LIKE '%' + @ControlNumber + '%')
				AND (ISNULL(@SerialNumber, '') = '' OR rs.SerialNumber LIKE '%' + @SerialNumber + '%')
				AND (ISNULL(@QuantityOnHand, '') = '' OR CAST(rs.QuantityOnHand AS VARCHAR(50)) LIKE '%' + @QuantityOnHand + '%')
				AND (ISNULL(@QuantityAvailable, '') = '' OR CAST(rs.QuantityAvailable AS VARCHAR(50)) LIKE '%' + @QuantityAvailable + '%')
				AND (ISNULL(@Site, '') = '' OR rs.Site LIKE '%' + @Site + '%')
				AND (ISNULL(@Warehouse, '') = '' OR rs.Warehouse LIKE '%' + @Warehouse + '%')
				AND (ISNULL(@Location, '') = '' OR rs.Location LIKE '%' + @Location + '%')
				AND (ISNULL(@Shelf, '') = '' OR rs.Shelf LIKE '%' + @Shelf + '%')
				AND (ISNULL(@Bin, '') = '' OR rs.Bin LIKE '%' + @Bin + '%')
		),
		ResultCount AS (
			SELECT COUNT(StockLineId) AS NumberOfItems FROM FinalResult
		)
		SELECT
			StockLineId, PartNumber, PartDescription, StockLineNumber, ControlNumber, IdNumber, Manufacturer,
			Condition, SerialNumber, QuantityOnHand, QuantityAvailable, Site, Warehouse, Location, Shelf, Bin,
			NumberOfItems
		FROM FinalResult, ResultCount
		ORDER BY
			CASE WHEN (@SortOrder = 1 AND @SortColumn = 'partNumber') THEN PartNumber END ASC,
			CASE WHEN (@SortOrder = 1 AND @SortColumn = 'partDescription') THEN PartDescription END ASC,
			CASE WHEN (@SortOrder = 1 AND @SortColumn = 'manufacturer') THEN Manufacturer END ASC,
			CASE WHEN (@SortOrder = 1 AND @SortColumn = 'condition') THEN Condition END ASC,
			CASE WHEN (@SortOrder = 1 AND @SortColumn = 'stockLineNumber') THEN StockLineNumber END ASC,
			CASE WHEN (@SortOrder = 1 AND @SortColumn = 'controlNumber') THEN ControlNumber END ASC,
			CASE WHEN (@SortOrder = 1 AND @SortColumn = 'serialNumber') THEN SerialNumber END ASC,
			CASE WHEN (@SortOrder = 1 AND @SortColumn = 'quantityOnHand') THEN QuantityOnHand END ASC,
			CASE WHEN (@SortOrder = 1 AND @SortColumn = 'quantityAvailable') THEN QuantityAvailable END ASC,
			CASE WHEN (@SortOrder = 1 AND @SortColumn = 'site') THEN Site END ASC,
			CASE WHEN (@SortOrder = 1 AND @SortColumn = 'warehouse') THEN Warehouse END ASC,
			CASE WHEN (@SortOrder = 1 AND @SortColumn = 'location') THEN Location END ASC,
			CASE WHEN (@SortOrder = 1 AND @SortColumn = 'shelf') THEN Shelf END ASC,
			CASE WHEN (@SortOrder = 1 AND @SortColumn = 'bin') THEN Bin END ASC,
			CASE WHEN (@SortOrder = 1 AND @SortColumn = 'StockLineId') THEN StockLineId END ASC,

			CASE WHEN (@SortOrder = -1 AND @SortColumn = 'partNumber') THEN PartNumber END DESC,
			CASE WHEN (@SortOrder = -1 AND @SortColumn = 'partDescription') THEN PartDescription END DESC,
			CASE WHEN (@SortOrder = -1 AND @SortColumn = 'manufacturer') THEN Manufacturer END DESC,
			CASE WHEN (@SortOrder = -1 AND @SortColumn = 'condition') THEN Condition END DESC,
			CASE WHEN (@SortOrder = -1 AND @SortColumn = 'stockLineNumber') THEN StockLineNumber END DESC,
			CASE WHEN (@SortOrder = -1 AND @SortColumn = 'controlNumber') THEN ControlNumber END DESC,
			CASE WHEN (@SortOrder = -1 AND @SortColumn = 'serialNumber') THEN SerialNumber END DESC,
			CASE WHEN (@SortOrder = -1 AND @SortColumn = 'quantityOnHand') THEN QuantityOnHand END DESC,
			CASE WHEN (@SortOrder = -1 AND @SortColumn = 'quantityAvailable') THEN QuantityAvailable END DESC,
			CASE WHEN (@SortOrder = -1 AND @SortColumn = 'site') THEN Site END DESC,
			CASE WHEN (@SortOrder = -1 AND @SortColumn = 'warehouse') THEN Warehouse END DESC,
			CASE WHEN (@SortOrder = -1 AND @SortColumn = 'location') THEN Location END DESC,
			CASE WHEN (@SortOrder = -1 AND @SortColumn = 'shelf') THEN Shelf END DESC,
			CASE WHEN (@SortOrder = -1 AND @SortColumn = 'bin') THEN Bin END DESC,
			CASE WHEN (@SortOrder = -1 AND @SortColumn = 'StockLineId') THEN StockLineId END DESC

			OFFSET @RecordFrom ROWS
			FETCH NEXT @PageSize ROWS ONLY;
    END
  END TRY
  BEGIN CATCH
                 DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_SearchStocklineByLocation'
              , @ProcedureParameters VARCHAR(3000)  = '@MasterCompanyId = ''' + CONVERT(VARCHAR(20), @MasterCompanyId) + ''''
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