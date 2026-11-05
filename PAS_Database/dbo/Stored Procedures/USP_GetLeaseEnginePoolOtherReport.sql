/*************************************************************
 ** File:   [USP_GetLeaseEnginePoolOtherReport]
 ** Description: Lease Report (Engine Pool) - "Other" tab. One row per engine (latest lease line) - PN View only (the Lease view was removed; @ViewType is kept only so existing callers keep working and is ignored).
 **              Purpose: Leasing > Reports > Lease Report > Other
 **              The main table is the Lease : LeaseStockline (latest non-deleted lease line of each engine stockline) + LeaseHeader, joined to the Stockline.
 **              Only the columns whose source is known are filled; every other column of the tab is returned as NULL (blank in the grid) until its source is agreed.
 ** Change History
 **************************************************************
 ** PR   Date			Author				Change Description
 ** -----------------------------------------------------------
    1    30/10/2026		Kishor Makwana		[PN-18419] - Created
    2    02/11/2026		Kishor Makwana		[PN-18419] - Server side search : @PageNumber/@PageSize (0 = all rows), @SortColumn/@SortOrder, @Filters (JSON column filters); returns TotalRecords
    3    04/11/2026		Kishor Makwana		[PN-17949] - Optimized : PN View only (Lease view and the #EnginePoolResult copy removed, the grid filters/sorts/pages #EnginePoolRows directly), IsActive taken from @IsActive, OPTION (RECOMPILE) on the filtered query
    4    04/11/2026		Kishor Makwana		[PN-17949] - Status (Draft / Active / Closed) column, Engine Type from Stockline.EngineType
    5    05/11/2026		Kishor Makwana		[PN-17949] - Active / Inactive switch now filters on the same Status that is displayed (stockline status, lease header status when the line has none) - Inactive showed Active lines of non-Active leases
    
-- @IsActive : 1 = Active (Status Active), 0 = Inactive (Status Draft or Closed). Status = the stockline's own status (latest LeaseStockline row), the lease header status when the line has none. LeaseStatusId : 1 Draft, 2 Active, 3 Closed
-- EXEC [dbo].[USP_GetLeaseEnginePoolOtherReport] @MasterCompanyId = 1, @IsActive = 1, @ViewType = 'PN'
************************************************************************/
CREATE   PROCEDURE [dbo].[USP_GetLeaseEnginePoolOtherReport]
	@MasterCompanyId INT,
	@IsActive BIT = 1,
	@ViewType VARCHAR(10) = 'PN',
	@PageNumber INT = 1,
	@PageSize INT = 50,
	@SortColumn VARCHAR(100) = NULL,
	@SortOrder VARCHAR(4) = 'ASC',
	@Filters NVARCHAR(MAX) = NULL
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;

	BEGIN TRY
		IF OBJECT_ID('tempdb..#EnginePoolRows') IS NOT NULL DROP TABLE #EnginePoolRows;

		SELECT
			STK.[StockLineId] AS [StockLineId],
			LH.[LeaseNumber] AS [LeaseNumber],
			STK.[EngineSerialNumber] AS [EngineSn],
			STK.[EngineModel] AS [BaseModel],
			STK.[EngineType] AS [EngineType],
			CAST(CASE ISNULL(LSL.[LeaseStatusId], LH.[LeaseStatusId]) WHEN 1 THEN 'Draft' WHEN 2 THEN 'Active' WHEN 3 THEN 'Closed' END AS VARCHAR(20)) AS [Status],
			CAST(NULL AS VARCHAR(200)) AS [BringingJobToTs],
			@IsActive AS [IsActive]
		INTO #EnginePoolRows
		FROM (
				SELECT LS.[StockLineId], LS.[LeaseHeaderId], LS.[LeaseStatusId], LS.[QtyOrder], LS.[StartDate], LS.[EndDate], LS.[UpdatedDate],
					LS.[LeaseStocklineId],
					ROW_NUMBER() OVER (PARTITION BY LS.[StockLineId] ORDER BY ISNULL(LS.[StartDate], '1900-01-01') DESC, LS.[LeaseStocklineId] DESC) AS [RN]
				FROM [dbo].[LeaseStockline] LS WITH (NOLOCK)
				WHERE LS.[MasterCompanyId] = @MasterCompanyId AND ISNULL(LS.[IsDeleted], 0) = 0 AND LS.[StockLineId] IS NOT NULL
			) LSL
			INNER JOIN [dbo].[LeaseHeader] LH WITH (NOLOCK) ON LH.[LeaseHeaderId] = LSL.[LeaseHeaderId] AND ISNULL(LH.[IsDeleted], 0) = 0
			INNER JOIN [dbo].[Stockline] STK WITH (NOLOCK) ON STK.[StockLineId] = LSL.[StockLineId]
			LEFT JOIN [dbo].[Customer] LCUS WITH (NOLOCK) ON LCUS.[CustomerId] = LH.[CustomerId]
			LEFT JOIN [dbo].[Location] LOC WITH (NOLOCK) ON LOC.[LocationId] = STK.[LocationId]
		WHERE LSL.[RN] = 1
			AND STK.[MasterCompanyId] = @MasterCompanyId
			AND ISNULL(STK.[isDeleted], 0) = 0
			AND (CASE WHEN ISNULL(LSL.[LeaseStatusId], LH.[LeaseStatusId]) = 2 THEN 1 ELSE 0 END) = @IsActive;

		DECLARE @Take INT = CASE WHEN ISNULL(@PageSize, 0) <= 0 THEN 2147483647 ELSE @PageSize END;
		DECLARE @Skip INT = CASE WHEN ISNULL(@PageSize, 0) <= 0 THEN 0 ELSE (ISNULL(NULLIF(@PageNumber, 0), 1) - 1) * @PageSize END;
		-- column filters of the grid (JSON : {"engineSn":"text", ...}) - a column contains the text; dates match the usual date formats, amounts the number
		DECLARE @f_LeaseNumber NVARCHAR(400) = NULLIF(REPLACE(REPLACE(REPLACE(LTRIM(RTRIM(JSON_VALUE(@Filters, '$.leaseNumber'))), '[', '[[]'), '%', '[%]'), '_', '[_]'), '');
		DECLARE @f_EngineSn NVARCHAR(400) = NULLIF(REPLACE(REPLACE(REPLACE(LTRIM(RTRIM(JSON_VALUE(@Filters, '$.engineSn'))), '[', '[[]'), '%', '[%]'), '_', '[_]'), '');
		DECLARE @f_BaseModel NVARCHAR(400) = NULLIF(REPLACE(REPLACE(REPLACE(LTRIM(RTRIM(JSON_VALUE(@Filters, '$.baseModel'))), '[', '[[]'), '%', '[%]'), '_', '[_]'), '');
		DECLARE @f_EngineType NVARCHAR(400) = NULLIF(REPLACE(REPLACE(REPLACE(LTRIM(RTRIM(JSON_VALUE(@Filters, '$.engineType'))), '[', '[[]'), '%', '[%]'), '_', '[_]'), '');
		DECLARE @f_Status NVARCHAR(400) = NULLIF(REPLACE(REPLACE(REPLACE(LTRIM(RTRIM(JSON_VALUE(@Filters, '$.status'))), '[', '[[]'), '%', '[%]'), '_', '[_]'), '');
		DECLARE @f_BringingJobToTs NVARCHAR(400) = NULLIF(REPLACE(REPLACE(REPLACE(LTRIM(RTRIM(JSON_VALUE(@Filters, '$.bringingJobToTs'))), '[', '[[]'), '%', '[%]'), '_', '[_]'), '');

		SELECT
			R.[StockLineId],
			R.[LeaseNumber],
			R.[EngineSn],
			R.[BaseModel],
			R.[EngineType],
			R.[Status],
			R.[BringingJobToTs],
			R.[IsActive],
			COUNT(*) OVER () AS [TotalRecords]
		FROM #EnginePoolRows R
		WHERE 1 = 1
			AND (@f_LeaseNumber IS NULL OR R.[LeaseNumber] LIKE '%' + @f_LeaseNumber + '%')
			AND (@f_EngineSn IS NULL OR R.[EngineSn] LIKE '%' + @f_EngineSn + '%')
			AND (@f_BaseModel IS NULL OR R.[BaseModel] LIKE '%' + @f_BaseModel + '%')
			AND (@f_EngineType IS NULL OR R.[EngineType] LIKE '%' + @f_EngineType + '%')
			AND (@f_Status IS NULL OR R.[Status] LIKE '%' + @f_Status + '%')
			AND (@f_BringingJobToTs IS NULL OR R.[BringingJobToTs] LIKE '%' + @f_BringingJobToTs + '%')
		ORDER BY
			CASE WHEN @SortColumn = 'leaseNumber' AND @SortOrder = 'ASC' THEN R.[LeaseNumber] END ASC,
			CASE WHEN @SortColumn = 'leaseNumber' AND @SortOrder = 'DESC' THEN R.[LeaseNumber] END DESC,
			CASE WHEN @SortColumn = 'engineSn' AND @SortOrder = 'ASC' THEN R.[EngineSn] END ASC,
			CASE WHEN @SortColumn = 'engineSn' AND @SortOrder = 'DESC' THEN R.[EngineSn] END DESC,
			CASE WHEN @SortColumn = 'baseModel' AND @SortOrder = 'ASC' THEN R.[BaseModel] END ASC,
			CASE WHEN @SortColumn = 'baseModel' AND @SortOrder = 'DESC' THEN R.[BaseModel] END DESC,
			CASE WHEN @SortColumn = 'engineType' AND @SortOrder = 'ASC' THEN R.[EngineType] END ASC,
			CASE WHEN @SortColumn = 'engineType' AND @SortOrder = 'DESC' THEN R.[EngineType] END DESC,
			CASE WHEN @SortColumn = 'status' AND @SortOrder = 'ASC' THEN R.[Status] END ASC,
			CASE WHEN @SortColumn = 'status' AND @SortOrder = 'DESC' THEN R.[Status] END DESC,
			CASE WHEN @SortColumn = 'bringingJobToTs' AND @SortOrder = 'ASC' THEN R.[BringingJobToTs] END ASC,
			CASE WHEN @SortColumn = 'bringingJobToTs' AND @SortOrder = 'DESC' THEN R.[BringingJobToTs] END DESC,
			R.[LeaseNumber] DESC, R.[EngineSn], R.[StockLineId]
		OFFSET @Skip ROWS FETCH NEXT @Take ROWS ONLY
		OPTION (RECOMPILE); -- optional filters + dynamic sort : a fresh plan for every filter / sort combination

		DROP TABLE #EnginePoolRows;
	END TRY
	BEGIN CATCH
		DECLARE @ErrorLogID INT, @DatabaseName VARCHAR(100) = DB_NAME()

-------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
			, @AdhocComments VARCHAR(150) = 'USP_GetLeaseEnginePoolOtherReport'
			, @ProcedureParameters VARCHAR(3000) = '@MasterCompanyId = ' + ISNULL(CAST(@MasterCompanyId AS VARCHAR(10)), '') + ', @IsActive = ' + ISNULL(CAST(@IsActive AS VARCHAR(1)), '') + ', @ViewType = ' + ISNULL(@ViewType, '')
			, @ApplicationName VARCHAR(100) = 'PAS'
-------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
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