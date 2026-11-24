/*************************************************************
 ** File:   [USP_GetStocklineSubComponentList]
 ** Description: Returns the parent stockline header (result set 1) and the stocklines linked to it as sub-components (result set 2).
 ** Date:   10/14/2026
 ** Author:  Kishor Makwana

 ** PARAMETERS:
	@ParentStocklineId  - stockline the sub-components are attached to
	@MasterCompanyId    - master company

 ** RETURN VALUE:
 **************************************************************
 ** Change History
 **************************************************************
 ** PR   Date         Author		Change Description
 ** --   --------     -------		--------------------------------
    1    10/14/2026  Kishor Makwana     [PN-18321] Created 
    2    19/NOV/2026  Kishor Makwana    [PN-18604] UnitCost added to the sub-component list
    3    19/NOV/2026  Kishor Makwana    [PN-18604] Paging / sort / column filters (@PageNumber); result set 3 = every linked stockline + qty (used by Save)

-- EXEC [dbo].[USP_GetStocklineSubComponentList] @ParentStocklineId = 1, @MasterCompanyId = 1
************************************************************************/
CREATE   PROCEDURE [dbo].[USP_GetStocklineSubComponentList]
	@ParentStocklineId BIGINT,
	@MasterCompanyId INT,
	-- [PN-18604] paging / sort / column filters of the linked sub-components (like USP_GetLeasePostedInvoiceListByLeaseHeaderId).
	-- @PageNumber NULL = no paging : all linked rows are returned (callers that only need the parent / the full list).
	@PageNumber INT = NULL,
	@PageSize INT = 20,
	@SortColumn VARCHAR(50) = NULL,
	@SortOrder INT = NULL,
	@PartNumber VARCHAR(200) = NULL,
	@PartDescription VARCHAR(500) = NULL,
	@Manufacturer VARCHAR(200) = NULL,
	@Condition VARCHAR(100) = NULL,
	@StockLineNumber VARCHAR(100) = NULL,
	@ControlNumber VARCHAR(100) = NULL,
	@SerialNumber VARCHAR(200) = NULL,
	@QuantityOnHand VARCHAR(50) = NULL,
	@QuantityAvailable VARCHAR(50) = NULL,
	@UnitCost VARCHAR(50) = NULL,
	@Qty VARCHAR(50) = NULL
AS
BEGIN
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

	BEGIN TRY
		-- Result set 1 : parent header (shown read-only in the popup)
		SELECT
			s.[StockLineId],
			s.[PartNumber],
			s.[PNDescription] AS [PartDescription],
			s.[SerialNumber],
			s.[Manufacturer],
			s.[Condition],
			s.[StockLineNumber],
			s.[ControlNumber],
			ISNULL(s.[SubComponentParentStocklineId], 0) AS [SubComponentParentStocklineId]
		FROM [dbo].[Stockline] s WITH (NOLOCK)
		WHERE s.[StockLineId] = @ParentStocklineId
		  AND s.[MasterCompanyId] = @MasterCompanyId;

		IF (@PageNumber IS NULL)
		BEGIN
			-- Result set 2 : linked sub-components (all rows, no paging)
			SELECT
				s.[StockLineId],
				s.[PartNumber],
				s.[PNDescription] AS [PartDescription],
				s.[StockLineNumber],
				s.[ControlNumber],
				s.[IdNumber],
				s.[SerialNumber],
				s.[Manufacturer],
				s.[Condition],
				ISNULL(s.[isSerialized], 0) AS [IsSerialized],
				ISNULL(s.[QuantityOnHand], 0) AS [QuantityOnHand],
				ISNULL(s.[QuantityAvailable], 0) AS [QuantityAvailable],
				ISNULL(s.[QuantityReserved], 0) AS [QuantityReserved],
				CAST(ISNULL(s.[UnitCost], 0) AS DECIMAL(18, 2)) AS [UnitCost],
				ISNULL(s.[SubComponentQty], 0) AS [Qty],
				ISNULL(s.[QuantityAvailable], 0) AS [MaxQty],
				s.[Site],
				s.[Warehouse],
				s.[Location]
			FROM [dbo].[Stockline] s WITH (NOLOCK)
			WHERE s.[SubComponentParentStocklineId] = @ParentStocklineId
			  AND s.[MasterCompanyId] = @MasterCompanyId
			  AND ISNULL(s.[isDeleted], 0) = 0
			ORDER BY s.[PartNumber], s.[StockLineNumber];
		END
		ELSE
		BEGIN
			DECLARE @RecordFrom INT;
			SET @PageSize = ISNULL(NULLIF(@PageSize, 0), 20);
			SET @PageNumber = CASE WHEN ISNULL(@PageNumber, 1) < 1 THEN 1 ELSE @PageNumber END;
			SET @RecordFrom = (@PageNumber - 1) * @PageSize;
			SET @SortColumn = UPPER(ISNULL(@SortColumn, ''));
			SET @SortOrder = ISNULL(@SortOrder, 1);

			SET @PartNumber = NULLIF(LTRIM(RTRIM(@PartNumber)), '');
			SET @PartDescription = NULLIF(LTRIM(RTRIM(@PartDescription)), '');
			SET @Manufacturer = NULLIF(LTRIM(RTRIM(@Manufacturer)), '');
			SET @Condition = NULLIF(LTRIM(RTRIM(@Condition)), '');
			SET @StockLineNumber = NULLIF(LTRIM(RTRIM(@StockLineNumber)), '');
			SET @ControlNumber = NULLIF(LTRIM(RTRIM(@ControlNumber)), '');
			SET @SerialNumber = NULLIF(LTRIM(RTRIM(@SerialNumber)), '');
			SET @QuantityOnHand = NULLIF(LTRIM(RTRIM(@QuantityOnHand)), '');
			SET @QuantityAvailable = NULLIF(LTRIM(RTRIM(@QuantityAvailable)), '');
			SET @UnitCost = NULLIF(REPLACE(LTRIM(RTRIM(@UnitCost)), ',', ''), '');
			SET @Qty = NULLIF(LTRIM(RTRIM(@Qty)), '');

			-- Result set 2 : ONE PAGE of the linked sub-components (filtered + sorted), NumberOfItems = filtered total
			;WITH Linked AS (
				SELECT
					s.[StockLineId],
					s.[PartNumber],
					s.[PNDescription] AS [PartDescription],
					s.[StockLineNumber],
					s.[ControlNumber],
					s.[IdNumber],
					s.[SerialNumber],
					s.[Manufacturer],
					s.[Condition],
					ISNULL(s.[isSerialized], 0) AS [IsSerialized],
					ISNULL(s.[QuantityOnHand], 0) AS [QuantityOnHand],
					ISNULL(s.[QuantityAvailable], 0) AS [QuantityAvailable],
					ISNULL(s.[QuantityReserved], 0) AS [QuantityReserved],
					CAST(ISNULL(s.[UnitCost], 0) AS DECIMAL(18, 2)) AS [UnitCost],
					ISNULL(s.[SubComponentQty], 0) AS [Qty],
					ISNULL(s.[QuantityAvailable], 0) AS [MaxQty],
					s.[Site],
					s.[Warehouse],
					s.[Location]
				FROM [dbo].[Stockline] s WITH (NOLOCK)
				WHERE s.[SubComponentParentStocklineId] = @ParentStocklineId
				  AND s.[MasterCompanyId] = @MasterCompanyId
				  AND ISNULL(s.[isDeleted], 0) = 0
			)
			SELECT L.*, COUNT(*) OVER () AS NumberOfItems
			FROM Linked L
			WHERE (@PartNumber IS NULL OR L.PartNumber LIKE '%' + @PartNumber + '%' OR dbo.fn_NormalizePartNumber(L.PartNumber) LIKE '%' + dbo.fn_NormalizePartNumber(@PartNumber) + '%')
			  AND (@PartDescription IS NULL OR L.PartDescription LIKE '%' + @PartDescription + '%')
			  AND (@Manufacturer IS NULL OR L.Manufacturer LIKE '%' + @Manufacturer + '%')
			  AND (@Condition IS NULL OR L.Condition LIKE '%' + @Condition + '%')
			  AND (@StockLineNumber IS NULL OR L.StockLineNumber LIKE '%' + @StockLineNumber + '%')
			  AND (@ControlNumber IS NULL OR L.ControlNumber LIKE '%' + @ControlNumber + '%')
			  AND (@SerialNumber IS NULL OR L.SerialNumber LIKE '%' + @SerialNumber + '%')
			  AND (@QuantityOnHand IS NULL OR CAST(L.QuantityOnHand AS VARCHAR(50)) LIKE '%' + @QuantityOnHand + '%')
			  AND (@QuantityAvailable IS NULL OR CAST(L.QuantityAvailable AS VARCHAR(50)) LIKE '%' + @QuantityAvailable + '%')
			  AND (@UnitCost IS NULL OR CAST(L.UnitCost AS VARCHAR(50)) LIKE '%' + @UnitCost + '%')
			  AND (@Qty IS NULL OR CAST(L.Qty AS VARCHAR(50)) LIKE '%' + @Qty + '%')
			ORDER BY
				CASE WHEN (@SortOrder = 1 AND @SortColumn = 'PARTNUMBER') THEN L.PartNumber END ASC,
				CASE WHEN (@SortOrder = -1 AND @SortColumn = 'PARTNUMBER') THEN L.PartNumber END DESC,
				CASE WHEN (@SortOrder = 1 AND @SortColumn = 'PARTDESCRIPTION') THEN L.PartDescription END ASC,
				CASE WHEN (@SortOrder = -1 AND @SortColumn = 'PARTDESCRIPTION') THEN L.PartDescription END DESC,
				CASE WHEN (@SortOrder = 1 AND @SortColumn = 'MANUFACTURER') THEN L.Manufacturer END ASC,
				CASE WHEN (@SortOrder = -1 AND @SortColumn = 'MANUFACTURER') THEN L.Manufacturer END DESC,
				CASE WHEN (@SortOrder = 1 AND @SortColumn = 'CONDITION') THEN L.Condition END ASC,
				CASE WHEN (@SortOrder = -1 AND @SortColumn = 'CONDITION') THEN L.Condition END DESC,
				CASE WHEN (@SortOrder = 1 AND @SortColumn = 'STOCKLINENUMBER') THEN L.StockLineNumber END ASC,
				CASE WHEN (@SortOrder = -1 AND @SortColumn = 'STOCKLINENUMBER') THEN L.StockLineNumber END DESC,
				CASE WHEN (@SortOrder = 1 AND @SortColumn = 'CONTROLNUMBER') THEN L.ControlNumber END ASC,
				CASE WHEN (@SortOrder = -1 AND @SortColumn = 'CONTROLNUMBER') THEN L.ControlNumber END DESC,
				CASE WHEN (@SortOrder = 1 AND @SortColumn = 'SERIALNUMBER') THEN L.SerialNumber END ASC,
				CASE WHEN (@SortOrder = -1 AND @SortColumn = 'SERIALNUMBER') THEN L.SerialNumber END DESC,
				CASE WHEN (@SortOrder = 1 AND @SortColumn = 'QUANTITYONHAND') THEN L.QuantityOnHand END ASC,
				CASE WHEN (@SortOrder = -1 AND @SortColumn = 'QUANTITYONHAND') THEN L.QuantityOnHand END DESC,
				CASE WHEN (@SortOrder = 1 AND @SortColumn = 'QUANTITYAVAILABLE') THEN L.QuantityAvailable END ASC,
				CASE WHEN (@SortOrder = -1 AND @SortColumn = 'QUANTITYAVAILABLE') THEN L.QuantityAvailable END DESC,
				CASE WHEN (@SortOrder = 1 AND @SortColumn = 'UNITCOST') THEN L.UnitCost END ASC,
				CASE WHEN (@SortOrder = -1 AND @SortColumn = 'UNITCOST') THEN L.UnitCost END DESC,
				CASE WHEN (@SortOrder = 1 AND @SortColumn = 'QTY') THEN L.Qty END ASC,
				CASE WHEN (@SortOrder = -1 AND @SortColumn = 'QTY') THEN L.Qty END DESC,
				-- deterministic default / tie-breaker : stable paging
				L.PartNumber, L.StockLineNumber, L.StockLineId
			OFFSET @RecordFrom ROWS
			FETCH NEXT @PageSize ROWS ONLY
			OPTION (RECOMPILE);

			-- Result set 3 : EVERY linked stockline with its qty (not only this page) - Save sends the complete list, so rows of other pages are kept
			SELECT s.[StockLineId], ISNULL(s.[SubComponentQty], 0) AS [Qty]
			FROM [dbo].[Stockline] s WITH (NOLOCK)
			WHERE s.[SubComponentParentStocklineId] = @ParentStocklineId
			  AND s.[MasterCompanyId] = @MasterCompanyId
			  AND ISNULL(s.[isDeleted], 0) = 0;
		END
	END TRY
	BEGIN CATCH
		DECLARE @ErrorLogID INT, @DatabaseName VARCHAR(100) = DB_NAME()
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
			, @AdhocComments VARCHAR(150) = 'USP_GetStocklineSubComponentList'
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
