/*************************************************************
 ** File:   [USP_GetLeaseEnginePoolOtherReport]
 ** Description: Lease Report (Engine Pool) - "Other" tab. @ViewType : PN = one row per engine (latest lease line), LEASE = one row per lease.
 **              Purpose: Leasing > Reports > Lease Report > Other
 **              The main table is the Lease : LeaseStockline (latest non-deleted lease line of each engine stockline) + LeaseHeader, joined to the Stockline.
 **              Only the columns whose source is known are filled; every other column of the tab is returned as NULL (blank in the grid) until its source is agreed.
 ** Change History
 **************************************************************
 ** PR   Date			Author				Change Description
 ** -----------------------------------------------------------
    1    30/10/2026		Kishor Makwana		[PN-18419] - Created
    2    02/11/2026		Kishor Makwana		[PN-18419] - Server side search : @PageNumber/@PageSize (0 = all rows), @SortColumn/@SortOrder, @Filters (JSON column filters); returns TotalRecords
    
-- @IsActive : 1 = Active lease (Lease Status Active), 0 = Inactive (Lease Status Draft or Closed). LeaseStatusId : 1 Draft, 2 Active, 3 Closed
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
			CAST(NULL AS VARCHAR(200)) AS [EngineType],
			CAST(NULL AS VARCHAR(200)) AS [BringingJobToTs],
			CAST(CASE WHEN LH.[LeaseStatusId] = 2 THEN 1 ELSE 0 END AS BIT) AS [IsActive],
			LSL.[LeaseHeaderId]								AS [LeaseHeaderId]
		INTO #EnginePoolRows
		FROM (
				SELECT LS.[StockLineId], LS.[LeaseHeaderId], LS.[StartDate], LS.[EndDate], LS.[UpdatedDate],
					LS.[LeaseStocklineId],
					ROW_NUMBER() OVER (PARTITION BY LS.[StockLineId] ORDER BY ISNULL(LS.[StartDate], '1900-01-01') DESC, LS.[LeaseStocklineId] DESC) AS [RN]
				FROM [dbo].[LeaseStockline] LS WITH (NOLOCK)
				WHERE LS.[MasterCompanyId] = @MasterCompanyId AND ISNULL(LS.[IsDeleted], 0) = 0
			) LSL
			INNER JOIN [dbo].[LeaseHeader] LH WITH (NOLOCK) ON LH.[LeaseHeaderId] = LSL.[LeaseHeaderId] AND ISNULL(LH.[IsDeleted], 0) = 0
			INNER JOIN [dbo].[Stockline] STK WITH (NOLOCK) ON STK.[StockLineId] = LSL.[StockLineId]
			LEFT JOIN [dbo].[Customer] LCUS WITH (NOLOCK) ON LCUS.[CustomerId] = LH.[CustomerId]
			LEFT JOIN [dbo].[Location] LOC WITH (NOLOCK) ON LOC.[LocationId] = STK.[LocationId]
		WHERE (@ViewType = 'LEASE' OR LSL.[RN] = 1)
			AND STK.[MasterCompanyId] = @MasterCompanyId
			AND ISNULL(STK.[isDeleted], 0) = 0
			AND (CASE WHEN LH.[LeaseStatusId] = 2 THEN 1 ELSE 0 END) = @IsActive;

		IF OBJECT_ID('tempdb..#EnginePoolResult') IS NOT NULL DROP TABLE #EnginePoolResult;

		-- PN View   : one row per part (engine) - its latest lease line
		-- Lease View: one row per lease - the part columns show the value, or 'Multiple' when the parts of the lease have different values (same as the Lease List Summary View)
		SELECT
				CAST(NULL AS BIGINT)							AS [StockLineId],
				MAX(R.[LeaseNumber]) AS [LeaseNumber],
				CASE WHEN COUNT(DISTINCT R.[EngineSn]) > 1 THEN 'Multiple' ELSE MAX(R.[EngineSn]) END AS [EngineSn],
				CASE WHEN COUNT(DISTINCT R.[BaseModel]) > 1 THEN 'Multiple' ELSE MAX(R.[BaseModel]) END AS [BaseModel],
				MAX(R.[EngineType]) AS [EngineType],
				MAX(R.[BringingJobToTs]) AS [BringingJobToTs],
				CAST(MAX(CAST(R.[IsActive] AS INT)) AS BIT)	AS [IsActive]
		INTO #EnginePoolResult
		FROM #EnginePoolRows R
		WHERE @ViewType = 'LEASE'
		GROUP BY R.[LeaseHeaderId]
		UNION ALL
		SELECT
				R.[StockLineId],
				R.[LeaseNumber],
				R.[EngineSn],
				R.[BaseModel],
				R.[EngineType],
				R.[BringingJobToTs],
				R.[IsActive]
		FROM #EnginePoolRows R
		WHERE ISNULL(@ViewType, 'PN') <> 'LEASE';

		DECLARE @Take INT = CASE WHEN ISNULL(@PageSize, 0) <= 0 THEN 2147483647 ELSE @PageSize END;
		DECLARE @Skip INT = CASE WHEN ISNULL(@PageSize, 0) <= 0 THEN 0 ELSE (ISNULL(NULLIF(@PageNumber, 0), 1) - 1) * @PageSize END;
		-- column filters of the grid (JSON : {"engineSn":"text", ...}) - a column contains the text; dates match the usual date formats, amounts the number
		DECLARE @f_LeaseNumber NVARCHAR(400) = NULLIF(REPLACE(REPLACE(REPLACE(LTRIM(RTRIM(JSON_VALUE(@Filters, '$.leaseNumber'))), '[', '[[]'), '%', '[%]'), '_', '[_]'), '');
		DECLARE @f_EngineSn NVARCHAR(400) = NULLIF(REPLACE(REPLACE(REPLACE(LTRIM(RTRIM(JSON_VALUE(@Filters, '$.engineSn'))), '[', '[[]'), '%', '[%]'), '_', '[_]'), '');
		DECLARE @f_BaseModel NVARCHAR(400) = NULLIF(REPLACE(REPLACE(REPLACE(LTRIM(RTRIM(JSON_VALUE(@Filters, '$.baseModel'))), '[', '[[]'), '%', '[%]'), '_', '[_]'), '');
		DECLARE @f_EngineType NVARCHAR(400) = NULLIF(REPLACE(REPLACE(REPLACE(LTRIM(RTRIM(JSON_VALUE(@Filters, '$.engineType'))), '[', '[[]'), '%', '[%]'), '_', '[_]'), '');
		DECLARE @f_BringingJobToTs NVARCHAR(400) = NULLIF(REPLACE(REPLACE(REPLACE(LTRIM(RTRIM(JSON_VALUE(@Filters, '$.bringingJobToTs'))), '[', '[[]'), '%', '[%]'), '_', '[_]'), '');

		SELECT
			R.[StockLineId],
			R.[LeaseNumber],
			R.[EngineSn],
			R.[BaseModel],
			R.[EngineType],
			R.[BringingJobToTs],
			R.[IsActive],
			COUNT(*) OVER () AS [TotalRecords]
		FROM #EnginePoolResult R
		WHERE 1 = 1
			AND (@f_LeaseNumber IS NULL OR R.[LeaseNumber] LIKE '%' + @f_LeaseNumber + '%')
			AND (@f_EngineSn IS NULL OR R.[EngineSn] LIKE '%' + @f_EngineSn + '%')
			AND (@f_BaseModel IS NULL OR R.[BaseModel] LIKE '%' + @f_BaseModel + '%')
			AND (@f_EngineType IS NULL OR R.[EngineType] LIKE '%' + @f_EngineType + '%')
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
			CASE WHEN @SortColumn = 'bringingJobToTs' AND @SortOrder = 'ASC' THEN R.[BringingJobToTs] END ASC,
			CASE WHEN @SortColumn = 'bringingJobToTs' AND @SortOrder = 'DESC' THEN R.[BringingJobToTs] END DESC,
			R.[LeaseNumber] DESC, R.[EngineSn], R.[StockLineId]
		OFFSET @Skip ROWS FETCH NEXT @Take ROWS ONLY;

		DROP TABLE #EnginePoolResult;
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