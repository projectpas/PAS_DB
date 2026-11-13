/*************************************************************
 ** File:   [USP_GetLeaseEnginePoolValuationReport]
 ** Description: Lease Report (Engine Pool) - "Valuation" tab. One row per engine (stockline) - same rows, same Status and same NBV as the General Info tab.
 **              The valuation columns (Purchase Date, PO Num, Purchase Price, NBV, Retail Value, Wholesale Value, Remarks, Date Updated) moved here from General Info.
 **              Retail Value / Wholesale Value have no source yet (NULL, as on General Info). Wholesale Value Included / Excluded / Doubtful are not used.
 **              Status is multi-select : @IncludeActive = 1 -> Active (status Active), @IncludeInactive = 1 -> Inactive (status Draft or Closed), both = all.
 ** Purpose: Leasing > Reports > Lease Report > Valuation
 ** Change History
 **************************************************************
 ** PR   Date			Author				Change Description
 ** -----------------------------------------------------------
    1    13/11/2026		Kishor Makwana		[PN-18534] - Created

-- EXEC [dbo].[USP_GetLeaseEnginePoolValuationReport] @MasterCompanyId = 1, @IncludeActive = 1, @IncludeInactive = 1
************************************************************************/
CREATE   PROCEDURE [dbo].[USP_GetLeaseEnginePoolValuationReport]
	@MasterCompanyId INT,
	@IncludeActive BIT = 1,
	@IncludeInactive BIT = 0,
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
		IF OBJECT_ID('tempdb..#ValuationRows') IS NOT NULL DROP TABLE #ValuationRows;

		SELECT
			STK.[StockLineId]								AS [StockLineId],
			LH.[LeaseNumber]								AS [LeaseNumber],
			STK.[EngineSerialNumber]						AS [EngineSn],
			STK.[EngineModel]								AS [BaseModel],
			STK.[EngineType]								AS [EngineType],
			LCUS.[Name]										AS [Lessee],
			LT.[LeaseType]									AS [LeaseType],
			CASE WHEN STK.[OwnerType] = 1 THEN CUS.[Name]
				 WHEN STK.[OwnerType] = 2 THEN VEN.[VendorName]
				 WHEN STK.[OwnerType] = 9 THEN LE.[Name]
				 ELSE STK.[OwnerName] END					AS [Owner],
			LOC.[Name]										AS [Location],
			CAST(CASE ISNULL(LSL.[LeaseStatusId], LH.[LeaseStatusId]) WHEN 1 THEN 'Draft' WHEN 2 THEN 'Active' WHEN 3 THEN 'Closed' END AS VARCHAR(20)) AS [Status],
			PO.[OpenDate]									AS [PurchaseDate],
			STK.[PurchaseOrderNumber]						AS [PONumber],
			STK.[PurchaseOrderId]							AS [PurchaseOrderId],
			PO.[StatusId]									AS [PurchaseOrderStatusId],
			PO.[VendorId]									AS [PurchaseOrderVendorId],
			STK.[PurchaseOrderUnitCost]						AS [PurchasePrice],
			STK.[UnitCost]									AS [Nbv],
			CAST(NULL AS DECIMAL(18, 2))					AS [RetailValue],
			CAST(NULL AS DECIMAL(18, 2))					AS [WholesaleValue],
			COALESCE(NULLIF(LTRIM(RTRIM(LSL.[Notes])), ''), NULLIF(LTRIM(RTRIM(LH.[Memo])), ''), NULLIF(LTRIM(RTRIM(LH.[Notes])), ''))	AS [Remarks],
			LSL.[UpdatedDate]								AS [DateUpdated]
		INTO #ValuationRows
		FROM (
				SELECT LS.[StockLineId], LS.[LeaseHeaderId], LS.[LeaseStatusId], LS.[Notes], LS.[UpdatedDate], LS.[LeaseStocklineId],
					ROW_NUMBER() OVER (PARTITION BY LS.[StockLineId] ORDER BY ISNULL(LS.[StartDate], '1900-01-01') DESC, LS.[LeaseStocklineId] DESC) AS [RN]
				FROM [dbo].[LeaseStockline] LS WITH (NOLOCK)
				WHERE LS.[MasterCompanyId] = @MasterCompanyId AND ISNULL(LS.[IsDeleted], 0) = 0 AND LS.[StockLineId] IS NOT NULL
			) LSL
			INNER JOIN [dbo].[LeaseHeader] LH WITH (NOLOCK) ON LH.[LeaseHeaderId] = LSL.[LeaseHeaderId] AND ISNULL(LH.[IsDeleted], 0) = 0
			INNER JOIN [dbo].[Stockline] STK WITH (NOLOCK) ON STK.[StockLineId] = LSL.[StockLineId]
			LEFT JOIN [dbo].[Customer] LCUS WITH (NOLOCK) ON LCUS.[CustomerId] = LH.[CustomerId]
			LEFT JOIN [dbo].[LeaseType] LT WITH (NOLOCK) ON LT.[LeaseTypeId] = LH.[LeaseTypeId]
			LEFT JOIN [dbo].[Location] LOC WITH (NOLOCK) ON LOC.[LocationId] = STK.[LocationId]
			LEFT JOIN [dbo].[PurchaseOrder] PO WITH (NOLOCK) ON PO.[PurchaseOrderId] = STK.[PurchaseOrderId]
			LEFT JOIN [dbo].[Customer] CUS WITH (NOLOCK) ON STK.[OwnerType] = 1 AND CUS.[CustomerId] = STK.[Owner]
			LEFT JOIN [dbo].[Vendor] VEN WITH (NOLOCK) ON STK.[OwnerType] = 2 AND VEN.[VendorId] = STK.[Owner]
			LEFT JOIN [dbo].[LegalEntity] LE WITH (NOLOCK) ON STK.[OwnerType] = 9 AND LE.[LegalEntityId] = STK.[Owner]
		WHERE LSL.[RN] = 1
			AND STK.[MasterCompanyId] = @MasterCompanyId
			AND ISNULL(STK.[isDeleted], 0) = 0
			AND (
				(@IncludeActive = 1 AND ISNULL(LSL.[LeaseStatusId], LH.[LeaseStatusId]) = 2)
				OR (@IncludeInactive = 1 AND ISNULL(LSL.[LeaseStatusId], LH.[LeaseStatusId]) <> 2)
			);

		DECLARE @Take INT = CASE WHEN ISNULL(@PageSize, 0) <= 0 THEN 2147483647 ELSE @PageSize END;
		DECLARE @Skip INT = CASE WHEN ISNULL(@PageSize, 0) <= 0 THEN 0 ELSE (ISNULL(NULLIF(@PageNumber, 0), 1) - 1) * @PageSize END;
		-- column filters of the grid (JSON : {"engineSn":"text", ...}) - a column contains the text; dates match the usual date formats, amounts the number
		DECLARE @f_LeaseNumber NVARCHAR(400) = NULLIF(REPLACE(REPLACE(REPLACE(LTRIM(RTRIM(JSON_VALUE(@Filters, '$.leaseNumber'))), '[', '[[]'), '%', '[%]'), '_', '[_]'), '');
		DECLARE @f_EngineSn NVARCHAR(400) = NULLIF(REPLACE(REPLACE(REPLACE(LTRIM(RTRIM(JSON_VALUE(@Filters, '$.engineSn'))), '[', '[[]'), '%', '[%]'), '_', '[_]'), '');
		DECLARE @f_BaseModel NVARCHAR(400) = NULLIF(REPLACE(REPLACE(REPLACE(LTRIM(RTRIM(JSON_VALUE(@Filters, '$.baseModel'))), '[', '[[]'), '%', '[%]'), '_', '[_]'), '');
		DECLARE @f_EngineType NVARCHAR(400) = NULLIF(REPLACE(REPLACE(REPLACE(LTRIM(RTRIM(JSON_VALUE(@Filters, '$.engineType'))), '[', '[[]'), '%', '[%]'), '_', '[_]'), '');
		DECLARE @f_Lessee NVARCHAR(400) = NULLIF(REPLACE(REPLACE(REPLACE(LTRIM(RTRIM(JSON_VALUE(@Filters, '$.lessee'))), '[', '[[]'), '%', '[%]'), '_', '[_]'), '');
		DECLARE @f_LeaseType NVARCHAR(400) = NULLIF(REPLACE(REPLACE(REPLACE(LTRIM(RTRIM(JSON_VALUE(@Filters, '$.leaseType'))), '[', '[[]'), '%', '[%]'), '_', '[_]'), '');
		DECLARE @f_Owner NVARCHAR(400) = NULLIF(REPLACE(REPLACE(REPLACE(LTRIM(RTRIM(JSON_VALUE(@Filters, '$.owner'))), '[', '[[]'), '%', '[%]'), '_', '[_]'), '');
		DECLARE @f_Location NVARCHAR(400) = NULLIF(REPLACE(REPLACE(REPLACE(LTRIM(RTRIM(JSON_VALUE(@Filters, '$.location'))), '[', '[[]'), '%', '[%]'), '_', '[_]'), '');
		DECLARE @f_Status NVARCHAR(400) = NULLIF(REPLACE(REPLACE(REPLACE(LTRIM(RTRIM(JSON_VALUE(@Filters, '$.status'))), '[', '[[]'), '%', '[%]'), '_', '[_]'), '');
		DECLARE @f_PurchaseDate NVARCHAR(400) = NULLIF(REPLACE(REPLACE(REPLACE(LTRIM(RTRIM(JSON_VALUE(@Filters, '$.purchaseDate'))), '[', '[[]'), '%', '[%]'), '_', '[_]'), '');
		DECLARE @f_PONumber NVARCHAR(400) = NULLIF(REPLACE(REPLACE(REPLACE(LTRIM(RTRIM(JSON_VALUE(@Filters, '$.poNumber'))), '[', '[[]'), '%', '[%]'), '_', '[_]'), '');
		DECLARE @f_PurchasePrice NVARCHAR(400) = NULLIF(REPLACE(REPLACE(REPLACE(LTRIM(RTRIM(JSON_VALUE(@Filters, '$.purchasePrice'))), '[', '[[]'), '%', '[%]'), '_', '[_]'), '');
		DECLARE @f_Nbv NVARCHAR(400) = NULLIF(REPLACE(REPLACE(REPLACE(LTRIM(RTRIM(JSON_VALUE(@Filters, '$.nbv'))), '[', '[[]'), '%', '[%]'), '_', '[_]'), '');
		DECLARE @f_RetailValue NVARCHAR(400) = NULLIF(REPLACE(REPLACE(REPLACE(LTRIM(RTRIM(JSON_VALUE(@Filters, '$.retailValue'))), '[', '[[]'), '%', '[%]'), '_', '[_]'), '');
		DECLARE @f_WholesaleValue NVARCHAR(400) = NULLIF(REPLACE(REPLACE(REPLACE(LTRIM(RTRIM(JSON_VALUE(@Filters, '$.wholesaleValue'))), '[', '[[]'), '%', '[%]'), '_', '[_]'), '');
		DECLARE @f_Remarks NVARCHAR(400) = NULLIF(REPLACE(REPLACE(REPLACE(LTRIM(RTRIM(JSON_VALUE(@Filters, '$.remarks'))), '[', '[[]'), '%', '[%]'), '_', '[_]'), '');
		DECLARE @f_DateUpdated NVARCHAR(400) = NULLIF(REPLACE(REPLACE(REPLACE(LTRIM(RTRIM(JSON_VALUE(@Filters, '$.dateUpdated'))), '[', '[[]'), '%', '[%]'), '_', '[_]'), '');

		SELECT
			R.[StockLineId],
			R.[LeaseNumber],
			R.[EngineSn],
			R.[BaseModel],
			R.[EngineType],
			R.[Lessee],
			R.[LeaseType],
			R.[Owner],
			R.[Location],
			R.[Status],
			R.[PurchaseDate],
			R.[PONumber],
			R.[PurchasePrice],
			R.[Nbv],
			R.[RetailValue],
			R.[WholesaleValue],
			R.[Remarks],
			R.[DateUpdated],
			R.[PurchaseOrderId],
			R.[PurchaseOrderStatusId],
			R.[PurchaseOrderVendorId],
			COUNT(*) OVER () AS [TotalRecords]
		FROM #ValuationRows R
		WHERE 1 = 1
			AND (@f_LeaseNumber IS NULL OR R.[LeaseNumber] LIKE '%' + @f_LeaseNumber + '%')
			AND (@f_EngineSn IS NULL OR R.[EngineSn] LIKE '%' + @f_EngineSn + '%')
			AND (@f_BaseModel IS NULL OR R.[BaseModel] LIKE '%' + @f_BaseModel + '%')
			AND (@f_EngineType IS NULL OR R.[EngineType] LIKE '%' + @f_EngineType + '%')
			AND (@f_Lessee IS NULL OR R.[Lessee] LIKE '%' + @f_Lessee + '%')
			AND (@f_LeaseType IS NULL OR R.[LeaseType] LIKE '%' + @f_LeaseType + '%')
			AND (@f_Owner IS NULL OR R.[Owner] LIKE '%' + @f_Owner + '%')
			AND (@f_Location IS NULL OR R.[Location] LIKE '%' + @f_Location + '%')
			AND (@f_Status IS NULL OR R.[Status] LIKE '%' + @f_Status + '%')
			AND (@f_PurchaseDate IS NULL OR CONVERT(VARCHAR(10), R.[PurchaseDate], 101) LIKE '%' + @f_PurchaseDate + '%' OR CONVERT(VARCHAR(10), R.[PurchaseDate], 23) LIKE '%' + @f_PurchaseDate + '%'
				OR CONVERT(VARCHAR(10), R.[PurchaseDate], 105) LIKE '%' + @f_PurchaseDate + '%' OR CONVERT(VARCHAR(10), R.[PurchaseDate], 110) LIKE '%' + @f_PurchaseDate + '%')
			AND (@f_PONumber IS NULL OR R.[PONumber] LIKE '%' + @f_PONumber + '%')
			AND (@f_PurchasePrice IS NULL OR CAST(R.[PurchasePrice] AS VARCHAR(50)) LIKE '%' + REPLACE(REPLACE(@f_PurchasePrice, ',', ''), '$', '') + '%')
			AND (@f_Nbv IS NULL OR CAST(R.[Nbv] AS VARCHAR(50)) LIKE '%' + REPLACE(REPLACE(@f_Nbv, ',', ''), '$', '') + '%')
			AND (@f_RetailValue IS NULL OR CAST(R.[RetailValue] AS VARCHAR(50)) LIKE '%' + REPLACE(REPLACE(@f_RetailValue, ',', ''), '$', '') + '%')
			AND (@f_WholesaleValue IS NULL OR CAST(R.[WholesaleValue] AS VARCHAR(50)) LIKE '%' + REPLACE(REPLACE(@f_WholesaleValue, ',', ''), '$', '') + '%')
			AND (@f_Remarks IS NULL OR R.[Remarks] LIKE '%' + @f_Remarks + '%')
			AND (@f_DateUpdated IS NULL OR CONVERT(VARCHAR(10), R.[DateUpdated], 101) LIKE '%' + @f_DateUpdated + '%' OR CONVERT(VARCHAR(10), R.[DateUpdated], 23) LIKE '%' + @f_DateUpdated + '%'
				OR CONVERT(VARCHAR(10), R.[DateUpdated], 105) LIKE '%' + @f_DateUpdated + '%' OR CONVERT(VARCHAR(10), R.[DateUpdated], 110) LIKE '%' + @f_DateUpdated + '%')
		ORDER BY
			CASE WHEN @SortColumn = 'leaseNumber' AND @SortOrder = 'ASC' THEN R.[LeaseNumber] END ASC,
			CASE WHEN @SortColumn = 'leaseNumber' AND @SortOrder = 'DESC' THEN R.[LeaseNumber] END DESC,
			CASE WHEN @SortColumn = 'engineSn' AND @SortOrder = 'ASC' THEN R.[EngineSn] END ASC,
			CASE WHEN @SortColumn = 'engineSn' AND @SortOrder = 'DESC' THEN R.[EngineSn] END DESC,
			CASE WHEN @SortColumn = 'baseModel' AND @SortOrder = 'ASC' THEN R.[BaseModel] END ASC,
			CASE WHEN @SortColumn = 'baseModel' AND @SortOrder = 'DESC' THEN R.[BaseModel] END DESC,
			CASE WHEN @SortColumn = 'engineType' AND @SortOrder = 'ASC' THEN R.[EngineType] END ASC,
			CASE WHEN @SortColumn = 'engineType' AND @SortOrder = 'DESC' THEN R.[EngineType] END DESC,
			CASE WHEN @SortColumn = 'lessee' AND @SortOrder = 'ASC' THEN R.[Lessee] END ASC,
			CASE WHEN @SortColumn = 'lessee' AND @SortOrder = 'DESC' THEN R.[Lessee] END DESC,
			CASE WHEN @SortColumn = 'leaseType' AND @SortOrder = 'ASC' THEN R.[LeaseType] END ASC,
			CASE WHEN @SortColumn = 'leaseType' AND @SortOrder = 'DESC' THEN R.[LeaseType] END DESC,
			CASE WHEN @SortColumn = 'owner' AND @SortOrder = 'ASC' THEN R.[Owner] END ASC,
			CASE WHEN @SortColumn = 'owner' AND @SortOrder = 'DESC' THEN R.[Owner] END DESC,
			CASE WHEN @SortColumn = 'location' AND @SortOrder = 'ASC' THEN R.[Location] END ASC,
			CASE WHEN @SortColumn = 'location' AND @SortOrder = 'DESC' THEN R.[Location] END DESC,
			CASE WHEN @SortColumn = 'status' AND @SortOrder = 'ASC' THEN R.[Status] END ASC,
			CASE WHEN @SortColumn = 'status' AND @SortOrder = 'DESC' THEN R.[Status] END DESC,
			CASE WHEN @SortColumn = 'purchaseDate' AND @SortOrder = 'ASC' THEN R.[PurchaseDate] END ASC,
			CASE WHEN @SortColumn = 'purchaseDate' AND @SortOrder = 'DESC' THEN R.[PurchaseDate] END DESC,
			CASE WHEN @SortColumn = 'poNumber' AND @SortOrder = 'ASC' THEN R.[PONumber] END ASC,
			CASE WHEN @SortColumn = 'poNumber' AND @SortOrder = 'DESC' THEN R.[PONumber] END DESC,
			CASE WHEN @SortColumn = 'purchasePrice' AND @SortOrder = 'ASC' THEN R.[PurchasePrice] END ASC,
			CASE WHEN @SortColumn = 'purchasePrice' AND @SortOrder = 'DESC' THEN R.[PurchasePrice] END DESC,
			CASE WHEN @SortColumn = 'nbv' AND @SortOrder = 'ASC' THEN R.[Nbv] END ASC,
			CASE WHEN @SortColumn = 'nbv' AND @SortOrder = 'DESC' THEN R.[Nbv] END DESC,
			CASE WHEN @SortColumn = 'retailValue' AND @SortOrder = 'ASC' THEN R.[RetailValue] END ASC,
			CASE WHEN @SortColumn = 'retailValue' AND @SortOrder = 'DESC' THEN R.[RetailValue] END DESC,
			CASE WHEN @SortColumn = 'wholesaleValue' AND @SortOrder = 'ASC' THEN R.[WholesaleValue] END ASC,
			CASE WHEN @SortColumn = 'wholesaleValue' AND @SortOrder = 'DESC' THEN R.[WholesaleValue] END DESC,
			CASE WHEN @SortColumn = 'remarks' AND @SortOrder = 'ASC' THEN R.[Remarks] END ASC,
			CASE WHEN @SortColumn = 'remarks' AND @SortOrder = 'DESC' THEN R.[Remarks] END DESC,
			CASE WHEN @SortColumn = 'dateUpdated' AND @SortOrder = 'ASC' THEN R.[DateUpdated] END ASC,
			CASE WHEN @SortColumn = 'dateUpdated' AND @SortOrder = 'DESC' THEN R.[DateUpdated] END DESC,
			R.[LeaseNumber] DESC, R.[EngineSn], R.[StockLineId]
		OFFSET @Skip ROWS FETCH NEXT @Take ROWS ONLY
		OPTION (RECOMPILE); -- optional filters + dynamic sort : a fresh plan for every filter / sort combination

		DROP TABLE #ValuationRows;
	END TRY
	BEGIN CATCH
		DECLARE @ErrorLogID INT, @DatabaseName VARCHAR(100) = DB_NAME()

-------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
			, @AdhocComments VARCHAR(150) = 'USP_GetLeaseEnginePoolValuationReport'
			, @ProcedureParameters VARCHAR(3000) = '@MasterCompanyId = ' + ISNULL(CAST(@MasterCompanyId AS VARCHAR(10)), '') + ', @IncludeActive = ' + ISNULL(CAST(@IncludeActive AS VARCHAR(1)), '') + ', @IncludeInactive = ' + ISNULL(CAST(@IncludeInactive AS VARCHAR(1)), '')
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