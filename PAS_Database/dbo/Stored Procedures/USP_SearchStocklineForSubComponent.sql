
/*************************************************************
 ** File:   [USP_SearchStocklineForSubComponent]
 ** Description: Lists the stocklines that can be added as a sub-component of @ParentStocklineId.
                 A stockline is eligible when it is an active, non-deleted, stock (not non-stock)
                 parent row (IsParent = 1) with QuantityAvailable > 0, is not already linked to any
                 parent, is not the parent itself and does not have sub-components of its own.
                 Supports server-side paging, sorting and per-column filtering.
 ** Date:   10/15/2026
 ** Author:  Kishor Makwana

 ** PARAMETERS:

 ** RETURN VALUE:
 **************************************************************
 ** Change History
 **************************************************************
 ** PR   Date         Author		Change Description
 ** --   --------     -------		--------------------------------
    1    10/15/2026  Kishor Makwana     [PN-18321] Created
    2    23/OCT/2026  Kishor Makwana    [PN-18118] Stockline installed on an aircraft / engine is not listed

-- EXEC USP_SearchStocklineForSubComponent
************************************************************************/
CREATE   PROCEDURE [dbo].[USP_SearchStocklineForSubComponent]
	@ParentStocklineId BIGINT,
	@tbl_ExcludeIds TVP_BigInt READONLY,
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
	@Location VARCHAR(200) = NULL
AS
BEGIN
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

	BEGIN TRY
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
				ISNULL(s.[isSerialized], 0) AS [IsSerialized],
				ISNULL(s.[QuantityOnHand], 0) AS [QuantityOnHand],
				ISNULL(s.[QuantityAvailable], 0) AS [QuantityAvailable],
				s.[Site],
				s.[Warehouse],
				s.[Location]
			FROM [dbo].[Stockline] s WITH (NOLOCK)
			WHERE s.[MasterCompanyId] = @MasterCompanyId
				AND s.[IsParent] = 1
				AND ISNULL(s.[isDeleted], 0) = 0
				AND ISNULL(s.[isActive], 1) = 1
				AND ISNULL(s.[IsNonStock], 0) = 0
				AND ROUND(ISNULL(s.[QuantityAvailable], 0), 2) > 0
				AND s.[SubComponentParentStocklineId] IS NULL
				AND ISNULL(s.[AircraftInstalledPartDetailsId], 0) = 0
				AND s.[StockLineId] <> @ParentStocklineId
				AND NOT EXISTS (SELECT 1 FROM [dbo].[Stockline] c WITH (NOLOCK) WHERE c.[SubComponentParentStocklineId] = s.[StockLineId])
				AND NOT EXISTS (SELECT 1 FROM @tbl_ExcludeIds ex WHERE ex.[Value] = s.[StockLineId])
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
		),
		ResultCount AS (
			SELECT COUNT(StockLineId) AS NumberOfItems FROM FinalResult
		)
		SELECT
			StockLineId, PartNumber, PartDescription, StockLineNumber, ControlNumber, IdNumber, Manufacturer,
			Condition, SerialNumber, IsSerialized, QuantityOnHand, QuantityAvailable, Site, Warehouse, Location,
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
			CASE WHEN (@SortOrder = -1 AND @SortColumn = 'StockLineId') THEN StockLineId END DESC

			OFFSET @RecordFrom ROWS
			FETCH NEXT @PageSize ROWS ONLY;
	END TRY
	BEGIN CATCH
		DECLARE @ErrorLogID INT, @DatabaseName VARCHAR(100) = DB_NAME()
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
			, @AdhocComments VARCHAR(150) = 'USP_SearchStocklineForSubComponent'
			, @ProcedureParameters VARCHAR(3000) = '@ParentStocklineId = ''' + CONVERT(VARCHAR(20), ISNULL(@ParentStocklineId, 0)) + ''', @MasterCompanyId = ''' + CONVERT(VARCHAR(20), ISNULL(@MasterCompanyId, 0)) + ''''
			, @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
		EXEC spLogException
			  @DatabaseName = @DatabaseName
			, @AdhocComments = @AdhocComments
			, @ProcedureParameters = @ProcedureParameters
			, @ApplicationName = @ApplicationName
			, @ErrorLogID = @ErrorLogID OUTPUT;
		RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)
		RETURN(1);
	END CATCH
END