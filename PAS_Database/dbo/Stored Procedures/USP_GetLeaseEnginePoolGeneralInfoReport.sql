/*************************************************************
 ** File:   [USP_GetLeaseEnginePoolGeneralInfoReport]
 ** Description: Lease Report (Engine Pool) - "General Info" tab. One row per engine (stockline) - PN View only (the Lease / Summary view was removed; @ViewType is kept
 **              only so existing callers keep working and is ignored).
 **              The main table is the Lease : LeaseStockline (latest non-deleted lease line of each engine stockline) + LeaseHeader, joined to the Stockline.
 **              Only the columns whose source is known are filled; every other column of the tab is returned
 **              as NULL (blank in the grid) until its source is agreed.
 ** Purpose: Leasing > Reports > Lease Report > General Info 
 ** Change History
 **************************************************************
 ** PR   Date			Author				Change Description
 ** -----------------------------------------------------------
    1    30/10/2026		Kishor Makwana		[PN-18419] - Created    
    2    02/11/2026		Kishor Makwana		[PN-18419] - Server side search : @PageNumber/@PageSize (0 = all rows), @SortColumn/@SortOrder, @Filters (JSON column filters); returns TotalRecords
    3    04/11/2026		Kishor Makwana		[PN-17949] - PO # (Stockline.PurchaseOrderNumber) column added as PONumber (filter / sort key poNumber)
    4    04/11/2026		Kishor Makwana		[PN-17949] - Optimized : PN View only (Lease/Summary view and the #EnginePoolResult copy removed, the grid filters/sorts/pages #EnginePoolRows directly), IsActive taken from @IsActive, OPTION (RECOMPILE) on the filtered query
    5    04/11/2026		Kishor Makwana		[PN-17949] - Returns Stockline.PurchaseOrderId as PurchaseOrderId (the PO # column opens the PO in a new tab)
    6    04/11/2026		Kishor Makwana		[PN-17949] - Status column (the part's Lease Status : Draft / Active / Closed, falls back to the Lease Header status), Engine Type from Stockline.EngineType; Disposition shows the same status value
    
-- @IsActive : 1 = Active lease (Lease Status Active), 0 = Inactive (Lease Status Draft or Closed). LeaseStatusId : 1 Draft, 2 Active, 3 Closed
-- EXEC [dbo].[USP_GetLeaseEnginePoolGeneralInfoReport] @MasterCompanyId = 1, @IsActive = 1, @ViewType = 'PN'
************************************************************************/
CREATE   PROCEDURE [dbo].[USP_GetLeaseEnginePoolGeneralInfoReport]
	@MasterCompanyId INT,
	@IsActive BIT = 1,
	@ViewType VARCHAR(10) = 'PN',
	@AsOfDate DATETIME2(7) = NULL,
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
		-- NBV is calculated as of the report run date (not used yet: the NBV column is the stockline unit cost for now)
		SET @AsOfDate = ISNULL(@AsOfDate, GETUTCDATE());

		IF OBJECT_ID('tempdb..#EnginePoolRows') IS NOT NULL DROP TABLE #EnginePoolRows;

		SELECT
			STK.[StockLineId]								AS [StockLineId],
			LH.[LeaseNumber]								AS [LeaseNumber],
			STK.[EngineSerialNumber]								AS [EngineSn],
			STK.[EngineModel]						AS [BaseModel],
			STK.[EngineType] AS [EngineType],
			CASE WHEN STK.[OwnerType] = 1 THEN CUS.[Name]
				 WHEN STK.[OwnerType] = 2 THEN VEN.[VendorName]
				 WHEN STK.[OwnerType] = 9 THEN LE.[Name]
				 ELSE STK.[OwnerName] END					AS [Owner],
			LOC.[Name]										AS [Location],
			CAST(CASE ISNULL(LSL.[LeaseStatusId], LH.[LeaseStatusId]) WHEN 1 THEN 'Draft' WHEN 2 THEN 'Active' WHEN 3 THEN 'Closed' END AS VARCHAR(20)) AS [Status],
			CAST(CASE ISNULL(LSL.[LeaseStatusId], LH.[LeaseStatusId]) WHEN 1 THEN 'Draft' WHEN 2 THEN 'Active' WHEN 3 THEN 'Closed' END AS VARCHAR(20)) AS [Disposition],
			LCUS.[Name]										AS [Lessee],
			CAST(NULL AS VARCHAR(200))						AS [SpecSheet],
			STK.[TagDate]									AS [TraceDate],
			CAST(NULL AS DECIMAL(18, 2))					AS [RetailValue],
			CAST(NULL AS DECIMAL(18, 2))					AS [WholesaleValue],
			CAST(NULL AS DECIMAL(18, 2))					AS [WholesaleValueIncluded],
			CAST(NULL AS DECIMAL(18, 2))					AS [WholesaleValueExcluded],
			CAST(NULL AS DECIMAL(18, 2))					AS [WholesaleValueDoubtful],
			COALESCE(NULLIF(LTRIM(RTRIM(LSL.[Notes])), ''), NULLIF(LTRIM(RTRIM(LH.[Memo])), ''), NULLIF(LTRIM(RTRIM(LH.[Notes])), ''))	AS [Remarks],
			PO.[OpenDate]									AS [PurchaseDate],
			STK.[PurchaseOrderUnitCost]						AS [PurchasePrice],
			STK.[UnitCost]									AS [Nbv],
			CAST(NULL AS VARCHAR(200))						AS [LongTermPreserveExpDate],
			LSL.[UpdatedDate]								AS [DateUpdated],
			CAST(NULL AS VARCHAR(200))						AS [Lienholder],
			PO.[VendorName]									AS [Vendor],
			STK.[PurchaseOrderNumber]									AS [PONumber],
			STK.[PurchaseOrderId]										AS [PurchaseOrderId],
			TCH.[TotalTSN]									AS [TsnAtPurchase],
			TCH.[TotalCSN]									AS [CsnAtPurchase],
			CAST(NULL AS DECIMAL(18, 6))					AS [TsoCamAtPurchase],
			@IsActive										AS [IsActive]
		INTO #EnginePoolRows
		FROM (
				SELECT LS.[StockLineId], LS.[LeaseHeaderId], LS.[LeaseStatusId], LS.[QtyOrder], LS.[Notes], LS.[UpdatedDate],
					LS.[LeaseStocklineId],
					ROW_NUMBER() OVER (PARTITION BY LS.[StockLineId] ORDER BY ISNULL(LS.[StartDate], '1900-01-01') DESC, LS.[LeaseStocklineId] DESC) AS [RN]
				FROM [dbo].[LeaseStockline] LS WITH (NOLOCK)
				WHERE LS.[MasterCompanyId] = @MasterCompanyId AND ISNULL(LS.[IsDeleted], 0) = 0 AND LS.[StockLineId] IS NOT NULL
			) LSL
			INNER JOIN [dbo].[LeaseHeader] LH WITH (NOLOCK) ON LH.[LeaseHeaderId] = LSL.[LeaseHeaderId] AND ISNULL(LH.[IsDeleted], 0) = 0
			INNER JOIN [dbo].[Stockline] STK WITH (NOLOCK) ON STK.[StockLineId] = LSL.[StockLineId]
			LEFT JOIN [dbo].[Customer] LCUS WITH (NOLOCK) ON LCUS.[CustomerId] = LH.[CustomerId]
			LEFT JOIN [dbo].[Location] LOC WITH (NOLOCK) ON LOC.[LocationId] = STK.[LocationId]
			LEFT JOIN [dbo].[PurchaseOrder] PO WITH (NOLOCK) ON PO.[PurchaseOrderId] = STK.[PurchaseOrderId]
			LEFT JOIN [dbo].[Customer] CUS WITH (NOLOCK) ON STK.[OwnerType] = 1 AND CUS.[CustomerId] = STK.[Owner]
			LEFT JOIN [dbo].[Vendor] VEN WITH (NOLOCK) ON STK.[OwnerType] = 2 AND VEN.[VendorId] = STK.[Owner]
			LEFT JOIN [dbo].[LegalEntity] LE WITH (NOLOCK) ON STK.[OwnerType] = 9 AND LE.[LegalEntityId] = STK.[Owner]
			OUTER APPLY (
				SELECT TOP 1 H.[TotalTSN], H.[TotalCSN]
				FROM [dbo].[StocklineTimeCycleHistory] H WITH (NOLOCK)
				WHERE H.[StocklineId] = STK.[StockLineId] AND ISNULL(H.[IsDeleted], 0) = 0
				ORDER BY H.[StocklineTimeCycleHistoryId] ASC
			) TCH
		WHERE LSL.[RN] = 1
			AND STK.[MasterCompanyId] = @MasterCompanyId
			AND ISNULL(STK.[isDeleted], 0) = 0
			AND (CASE WHEN LH.[LeaseStatusId] = 2 THEN 1 ELSE 0 END) = @IsActive;

		DECLARE @Take INT = CASE WHEN ISNULL(@PageSize, 0) <= 0 THEN 2147483647 ELSE @PageSize END;
		DECLARE @Skip INT = CASE WHEN ISNULL(@PageSize, 0) <= 0 THEN 0 ELSE (ISNULL(NULLIF(@PageNumber, 0), 1) - 1) * @PageSize END;
		-- column filters of the grid (JSON : {"engineSn":"text", ...}) - a column contains the text; dates match the usual date formats, amounts the number
		DECLARE @f_LeaseNumber NVARCHAR(400) = NULLIF(REPLACE(REPLACE(REPLACE(LTRIM(RTRIM(JSON_VALUE(@Filters, '$.leaseNumber'))), '[', '[[]'), '%', '[%]'), '_', '[_]'), '');
		DECLARE @f_EngineSn NVARCHAR(400) = NULLIF(REPLACE(REPLACE(REPLACE(LTRIM(RTRIM(JSON_VALUE(@Filters, '$.engineSn'))), '[', '[[]'), '%', '[%]'), '_', '[_]'), '');
		DECLARE @f_BaseModel NVARCHAR(400) = NULLIF(REPLACE(REPLACE(REPLACE(LTRIM(RTRIM(JSON_VALUE(@Filters, '$.baseModel'))), '[', '[[]'), '%', '[%]'), '_', '[_]'), '');
		DECLARE @f_EngineType NVARCHAR(400) = NULLIF(REPLACE(REPLACE(REPLACE(LTRIM(RTRIM(JSON_VALUE(@Filters, '$.engineType'))), '[', '[[]'), '%', '[%]'), '_', '[_]'), '');
		DECLARE @f_Owner NVARCHAR(400) = NULLIF(REPLACE(REPLACE(REPLACE(LTRIM(RTRIM(JSON_VALUE(@Filters, '$.owner'))), '[', '[[]'), '%', '[%]'), '_', '[_]'), '');
		DECLARE @f_Location NVARCHAR(400) = NULLIF(REPLACE(REPLACE(REPLACE(LTRIM(RTRIM(JSON_VALUE(@Filters, '$.location'))), '[', '[[]'), '%', '[%]'), '_', '[_]'), '');
		DECLARE @f_Disposition NVARCHAR(400) = NULLIF(REPLACE(REPLACE(REPLACE(LTRIM(RTRIM(JSON_VALUE(@Filters, '$.disposition'))), '[', '[[]'), '%', '[%]'), '_', '[_]'), '');
		DECLARE @f_Status NVARCHAR(400) = NULLIF(REPLACE(REPLACE(REPLACE(LTRIM(RTRIM(JSON_VALUE(@Filters, '$.status'))), '[', '[[]'), '%', '[%]'), '_', '[_]'), '');
		DECLARE @f_Lessee NVARCHAR(400) = NULLIF(REPLACE(REPLACE(REPLACE(LTRIM(RTRIM(JSON_VALUE(@Filters, '$.lessee'))), '[', '[[]'), '%', '[%]'), '_', '[_]'), '');
		DECLARE @f_SpecSheet NVARCHAR(400) = NULLIF(REPLACE(REPLACE(REPLACE(LTRIM(RTRIM(JSON_VALUE(@Filters, '$.specSheet'))), '[', '[[]'), '%', '[%]'), '_', '[_]'), '');
		DECLARE @f_TraceDate NVARCHAR(400) = NULLIF(REPLACE(REPLACE(REPLACE(LTRIM(RTRIM(JSON_VALUE(@Filters, '$.traceDate'))), '[', '[[]'), '%', '[%]'), '_', '[_]'), '');
		DECLARE @f_RetailValue NVARCHAR(400) = NULLIF(REPLACE(REPLACE(REPLACE(LTRIM(RTRIM(JSON_VALUE(@Filters, '$.retailValue'))), '[', '[[]'), '%', '[%]'), '_', '[_]'), '');
		DECLARE @f_WholesaleValue NVARCHAR(400) = NULLIF(REPLACE(REPLACE(REPLACE(LTRIM(RTRIM(JSON_VALUE(@Filters, '$.wholesaleValue'))), '[', '[[]'), '%', '[%]'), '_', '[_]'), '');
		DECLARE @f_WholesaleValueIncluded NVARCHAR(400) = NULLIF(REPLACE(REPLACE(REPLACE(LTRIM(RTRIM(JSON_VALUE(@Filters, '$.wholesaleValueIncluded'))), '[', '[[]'), '%', '[%]'), '_', '[_]'), '');
		DECLARE @f_WholesaleValueExcluded NVARCHAR(400) = NULLIF(REPLACE(REPLACE(REPLACE(LTRIM(RTRIM(JSON_VALUE(@Filters, '$.wholesaleValueExcluded'))), '[', '[[]'), '%', '[%]'), '_', '[_]'), '');
		DECLARE @f_WholesaleValueDoubtful NVARCHAR(400) = NULLIF(REPLACE(REPLACE(REPLACE(LTRIM(RTRIM(JSON_VALUE(@Filters, '$.wholesaleValueDoubtful'))), '[', '[[]'), '%', '[%]'), '_', '[_]'), '');
		DECLARE @f_Remarks NVARCHAR(400) = NULLIF(REPLACE(REPLACE(REPLACE(LTRIM(RTRIM(JSON_VALUE(@Filters, '$.remarks'))), '[', '[[]'), '%', '[%]'), '_', '[_]'), '');
		DECLARE @f_PurchaseDate NVARCHAR(400) = NULLIF(REPLACE(REPLACE(REPLACE(LTRIM(RTRIM(JSON_VALUE(@Filters, '$.purchaseDate'))), '[', '[[]'), '%', '[%]'), '_', '[_]'), '');
		DECLARE @f_PurchasePrice NVARCHAR(400) = NULLIF(REPLACE(REPLACE(REPLACE(LTRIM(RTRIM(JSON_VALUE(@Filters, '$.purchasePrice'))), '[', '[[]'), '%', '[%]'), '_', '[_]'), '');
		DECLARE @f_Nbv NVARCHAR(400) = NULLIF(REPLACE(REPLACE(REPLACE(LTRIM(RTRIM(JSON_VALUE(@Filters, '$.nbv'))), '[', '[[]'), '%', '[%]'), '_', '[_]'), '');
		DECLARE @f_LongTermPreserveExpDate NVARCHAR(400) = NULLIF(REPLACE(REPLACE(REPLACE(LTRIM(RTRIM(JSON_VALUE(@Filters, '$.longTermPreserveExpDate'))), '[', '[[]'), '%', '[%]'), '_', '[_]'), '');
		DECLARE @f_DateUpdated NVARCHAR(400) = NULLIF(REPLACE(REPLACE(REPLACE(LTRIM(RTRIM(JSON_VALUE(@Filters, '$.dateUpdated'))), '[', '[[]'), '%', '[%]'), '_', '[_]'), '');
		DECLARE @f_Lienholder NVARCHAR(400) = NULLIF(REPLACE(REPLACE(REPLACE(LTRIM(RTRIM(JSON_VALUE(@Filters, '$.lienholder'))), '[', '[[]'), '%', '[%]'), '_', '[_]'), '');
		DECLARE @f_Vendor NVARCHAR(400) = NULLIF(REPLACE(REPLACE(REPLACE(LTRIM(RTRIM(JSON_VALUE(@Filters, '$.vendor'))), '[', '[[]'), '%', '[%]'), '_', '[_]'), '');
		DECLARE @f_PONumber NVARCHAR(400) = NULLIF(REPLACE(REPLACE(REPLACE(LTRIM(RTRIM(JSON_VALUE(@Filters, '$.poNumber'))), '[', '[[]'), '%', '[%]'), '_', '[_]'), '');
		DECLARE @f_TsnAtPurchase NVARCHAR(400) = NULLIF(REPLACE(REPLACE(REPLACE(LTRIM(RTRIM(JSON_VALUE(@Filters, '$.tsnAtPurchase'))), '[', '[[]'), '%', '[%]'), '_', '[_]'), '');
		DECLARE @f_CsnAtPurchase NVARCHAR(400) = NULLIF(REPLACE(REPLACE(REPLACE(LTRIM(RTRIM(JSON_VALUE(@Filters, '$.csnAtPurchase'))), '[', '[[]'), '%', '[%]'), '_', '[_]'), '');
		DECLARE @f_TsoCamAtPurchase NVARCHAR(400) = NULLIF(REPLACE(REPLACE(REPLACE(LTRIM(RTRIM(JSON_VALUE(@Filters, '$.tsoCamAtPurchase'))), '[', '[[]'), '%', '[%]'), '_', '[_]'), '');

		SELECT
			R.[StockLineId],
			R.[LeaseNumber],
			R.[EngineSn],
			R.[BaseModel],
			R.[EngineType],
			R.[Owner],
			R.[Location],
			R.[Disposition],
			R.[Status],
			R.[Lessee],
			R.[SpecSheet],
			R.[TraceDate],
			R.[RetailValue],
			R.[WholesaleValue],
			R.[WholesaleValueIncluded],
			R.[WholesaleValueExcluded],
			R.[WholesaleValueDoubtful],
			R.[Remarks],
			R.[PurchaseDate],
			R.[PurchasePrice],
			R.[Nbv],
			R.[LongTermPreserveExpDate],
			R.[DateUpdated],
			R.[Lienholder],
			R.[Vendor],
			R.[PONumber],
			R.[PurchaseOrderId],
			R.[TsnAtPurchase],
			R.[CsnAtPurchase],
			R.[TsoCamAtPurchase],
			R.[IsActive],
			COUNT(*) OVER () AS [TotalRecords]
		FROM #EnginePoolRows R
		WHERE 1 = 1
			AND (@f_LeaseNumber IS NULL OR R.[LeaseNumber] LIKE '%' + @f_LeaseNumber + '%')
			AND (@f_EngineSn IS NULL OR R.[EngineSn] LIKE '%' + @f_EngineSn + '%')
			AND (@f_BaseModel IS NULL OR R.[BaseModel] LIKE '%' + @f_BaseModel + '%')
			AND (@f_EngineType IS NULL OR R.[EngineType] LIKE '%' + @f_EngineType + '%')
			AND (@f_Owner IS NULL OR R.[Owner] LIKE '%' + @f_Owner + '%')
			AND (@f_Location IS NULL OR R.[Location] LIKE '%' + @f_Location + '%')
			AND (@f_Disposition IS NULL OR R.[Disposition] LIKE '%' + @f_Disposition + '%')
			AND (@f_Status IS NULL OR R.[Status] LIKE '%' + @f_Status + '%')
			AND (@f_Lessee IS NULL OR R.[Lessee] LIKE '%' + @f_Lessee + '%')
			AND (@f_SpecSheet IS NULL OR R.[SpecSheet] LIKE '%' + @f_SpecSheet + '%')
			AND (@f_TraceDate IS NULL OR CONVERT(VARCHAR(10), R.[TraceDate], 101) LIKE '%' + @f_TraceDate + '%' OR CONVERT(VARCHAR(10), R.[TraceDate], 23) LIKE '%' + @f_TraceDate + '%'
				OR CONVERT(VARCHAR(10), R.[TraceDate], 105) LIKE '%' + @f_TraceDate + '%' OR CONVERT(VARCHAR(10), R.[TraceDate], 110) LIKE '%' + @f_TraceDate + '%')
			AND (@f_RetailValue IS NULL OR CAST(R.[RetailValue] AS VARCHAR(50)) LIKE '%' + REPLACE(REPLACE(@f_RetailValue, ',', ''), '$', '') + '%')
			AND (@f_WholesaleValue IS NULL OR CAST(R.[WholesaleValue] AS VARCHAR(50)) LIKE '%' + REPLACE(REPLACE(@f_WholesaleValue, ',', ''), '$', '') + '%')
			AND (@f_WholesaleValueIncluded IS NULL OR CAST(R.[WholesaleValueIncluded] AS VARCHAR(50)) LIKE '%' + REPLACE(REPLACE(@f_WholesaleValueIncluded, ',', ''), '$', '') + '%')
			AND (@f_WholesaleValueExcluded IS NULL OR CAST(R.[WholesaleValueExcluded] AS VARCHAR(50)) LIKE '%' + REPLACE(REPLACE(@f_WholesaleValueExcluded, ',', ''), '$', '') + '%')
			AND (@f_WholesaleValueDoubtful IS NULL OR CAST(R.[WholesaleValueDoubtful] AS VARCHAR(50)) LIKE '%' + REPLACE(REPLACE(@f_WholesaleValueDoubtful, ',', ''), '$', '') + '%')
			AND (@f_Remarks IS NULL OR R.[Remarks] LIKE '%' + @f_Remarks + '%')
			AND (@f_PurchaseDate IS NULL OR CONVERT(VARCHAR(10), R.[PurchaseDate], 101) LIKE '%' + @f_PurchaseDate + '%' OR CONVERT(VARCHAR(10), R.[PurchaseDate], 23) LIKE '%' + @f_PurchaseDate + '%'
				OR CONVERT(VARCHAR(10), R.[PurchaseDate], 105) LIKE '%' + @f_PurchaseDate + '%' OR CONVERT(VARCHAR(10), R.[PurchaseDate], 110) LIKE '%' + @f_PurchaseDate + '%')
			AND (@f_PurchasePrice IS NULL OR CAST(R.[PurchasePrice] AS VARCHAR(50)) LIKE '%' + REPLACE(REPLACE(@f_PurchasePrice, ',', ''), '$', '') + '%')
			AND (@f_Nbv IS NULL OR CAST(R.[Nbv] AS VARCHAR(50)) LIKE '%' + REPLACE(REPLACE(@f_Nbv, ',', ''), '$', '') + '%')
			AND (@f_LongTermPreserveExpDate IS NULL OR R.[LongTermPreserveExpDate] LIKE '%' + @f_LongTermPreserveExpDate + '%')
			AND (@f_DateUpdated IS NULL OR CONVERT(VARCHAR(10), R.[DateUpdated], 101) LIKE '%' + @f_DateUpdated + '%' OR CONVERT(VARCHAR(10), R.[DateUpdated], 23) LIKE '%' + @f_DateUpdated + '%'
				OR CONVERT(VARCHAR(10), R.[DateUpdated], 105) LIKE '%' + @f_DateUpdated + '%' OR CONVERT(VARCHAR(10), R.[DateUpdated], 110) LIKE '%' + @f_DateUpdated + '%')
			AND (@f_Lienholder IS NULL OR R.[Lienholder] LIKE '%' + @f_Lienholder + '%')
			AND (@f_Vendor IS NULL OR R.[Vendor] LIKE '%' + @f_Vendor + '%')
			AND (@f_PONumber IS NULL OR R.[PONumber] LIKE '%' + @f_PONumber + '%')
			AND (@f_TsnAtPurchase IS NULL OR CAST(R.[TsnAtPurchase] AS VARCHAR(50)) LIKE '%' + REPLACE(REPLACE(@f_TsnAtPurchase, ',', ''), '$', '') + '%')
			AND (@f_CsnAtPurchase IS NULL OR CAST(R.[CsnAtPurchase] AS VARCHAR(50)) LIKE '%' + REPLACE(REPLACE(@f_CsnAtPurchase, ',', ''), '$', '') + '%')
			AND (@f_TsoCamAtPurchase IS NULL OR CAST(R.[TsoCamAtPurchase] AS VARCHAR(50)) LIKE '%' + REPLACE(REPLACE(@f_TsoCamAtPurchase, ',', ''), '$', '') + '%')
		ORDER BY
			CASE WHEN @SortColumn = 'leaseNumber' AND @SortOrder = 'ASC' THEN R.[LeaseNumber] END ASC,
			CASE WHEN @SortColumn = 'leaseNumber' AND @SortOrder = 'DESC' THEN R.[LeaseNumber] END DESC,
			CASE WHEN @SortColumn = 'engineSn' AND @SortOrder = 'ASC' THEN R.[EngineSn] END ASC,
			CASE WHEN @SortColumn = 'engineSn' AND @SortOrder = 'DESC' THEN R.[EngineSn] END DESC,
			CASE WHEN @SortColumn = 'baseModel' AND @SortOrder = 'ASC' THEN R.[BaseModel] END ASC,
			CASE WHEN @SortColumn = 'baseModel' AND @SortOrder = 'DESC' THEN R.[BaseModel] END DESC,
			CASE WHEN @SortColumn = 'engineType' AND @SortOrder = 'ASC' THEN R.[EngineType] END ASC,
			CASE WHEN @SortColumn = 'engineType' AND @SortOrder = 'DESC' THEN R.[EngineType] END DESC,
			CASE WHEN @SortColumn = 'owner' AND @SortOrder = 'ASC' THEN R.[Owner] END ASC,
			CASE WHEN @SortColumn = 'owner' AND @SortOrder = 'DESC' THEN R.[Owner] END DESC,
			CASE WHEN @SortColumn = 'location' AND @SortOrder = 'ASC' THEN R.[Location] END ASC,
			CASE WHEN @SortColumn = 'location' AND @SortOrder = 'DESC' THEN R.[Location] END DESC,
			CASE WHEN @SortColumn = 'disposition' AND @SortOrder = 'ASC' THEN R.[Disposition] END ASC,
			CASE WHEN @SortColumn = 'disposition' AND @SortOrder = 'DESC' THEN R.[Disposition] END DESC,
			CASE WHEN @SortColumn = 'status' AND @SortOrder = 'ASC' THEN R.[Status] END ASC,
			CASE WHEN @SortColumn = 'status' AND @SortOrder = 'DESC' THEN R.[Status] END DESC,
			CASE WHEN @SortColumn = 'lessee' AND @SortOrder = 'ASC' THEN R.[Lessee] END ASC,
			CASE WHEN @SortColumn = 'lessee' AND @SortOrder = 'DESC' THEN R.[Lessee] END DESC,
			CASE WHEN @SortColumn = 'specSheet' AND @SortOrder = 'ASC' THEN R.[SpecSheet] END ASC,
			CASE WHEN @SortColumn = 'specSheet' AND @SortOrder = 'DESC' THEN R.[SpecSheet] END DESC,
			CASE WHEN @SortColumn = 'traceDate' AND @SortOrder = 'ASC' THEN R.[TraceDate] END ASC,
			CASE WHEN @SortColumn = 'traceDate' AND @SortOrder = 'DESC' THEN R.[TraceDate] END DESC,
			CASE WHEN @SortColumn = 'retailValue' AND @SortOrder = 'ASC' THEN R.[RetailValue] END ASC,
			CASE WHEN @SortColumn = 'retailValue' AND @SortOrder = 'DESC' THEN R.[RetailValue] END DESC,
			CASE WHEN @SortColumn = 'wholesaleValue' AND @SortOrder = 'ASC' THEN R.[WholesaleValue] END ASC,
			CASE WHEN @SortColumn = 'wholesaleValue' AND @SortOrder = 'DESC' THEN R.[WholesaleValue] END DESC,
			CASE WHEN @SortColumn = 'wholesaleValueIncluded' AND @SortOrder = 'ASC' THEN R.[WholesaleValueIncluded] END ASC,
			CASE WHEN @SortColumn = 'wholesaleValueIncluded' AND @SortOrder = 'DESC' THEN R.[WholesaleValueIncluded] END DESC,
			CASE WHEN @SortColumn = 'wholesaleValueExcluded' AND @SortOrder = 'ASC' THEN R.[WholesaleValueExcluded] END ASC,
			CASE WHEN @SortColumn = 'wholesaleValueExcluded' AND @SortOrder = 'DESC' THEN R.[WholesaleValueExcluded] END DESC,
			CASE WHEN @SortColumn = 'wholesaleValueDoubtful' AND @SortOrder = 'ASC' THEN R.[WholesaleValueDoubtful] END ASC,
			CASE WHEN @SortColumn = 'wholesaleValueDoubtful' AND @SortOrder = 'DESC' THEN R.[WholesaleValueDoubtful] END DESC,
			CASE WHEN @SortColumn = 'remarks' AND @SortOrder = 'ASC' THEN R.[Remarks] END ASC,
			CASE WHEN @SortColumn = 'remarks' AND @SortOrder = 'DESC' THEN R.[Remarks] END DESC,
			CASE WHEN @SortColumn = 'purchaseDate' AND @SortOrder = 'ASC' THEN R.[PurchaseDate] END ASC,
			CASE WHEN @SortColumn = 'purchaseDate' AND @SortOrder = 'DESC' THEN R.[PurchaseDate] END DESC,
			CASE WHEN @SortColumn = 'purchasePrice' AND @SortOrder = 'ASC' THEN R.[PurchasePrice] END ASC,
			CASE WHEN @SortColumn = 'purchasePrice' AND @SortOrder = 'DESC' THEN R.[PurchasePrice] END DESC,
			CASE WHEN @SortColumn = 'nbv' AND @SortOrder = 'ASC' THEN R.[Nbv] END ASC,
			CASE WHEN @SortColumn = 'nbv' AND @SortOrder = 'DESC' THEN R.[Nbv] END DESC,
			CASE WHEN @SortColumn = 'longTermPreserveExpDate' AND @SortOrder = 'ASC' THEN R.[LongTermPreserveExpDate] END ASC,
			CASE WHEN @SortColumn = 'longTermPreserveExpDate' AND @SortOrder = 'DESC' THEN R.[LongTermPreserveExpDate] END DESC,
			CASE WHEN @SortColumn = 'dateUpdated' AND @SortOrder = 'ASC' THEN R.[DateUpdated] END ASC,
			CASE WHEN @SortColumn = 'dateUpdated' AND @SortOrder = 'DESC' THEN R.[DateUpdated] END DESC,
			CASE WHEN @SortColumn = 'lienholder' AND @SortOrder = 'ASC' THEN R.[Lienholder] END ASC,
			CASE WHEN @SortColumn = 'lienholder' AND @SortOrder = 'DESC' THEN R.[Lienholder] END DESC,
			CASE WHEN @SortColumn = 'vendor' AND @SortOrder = 'ASC' THEN R.[Vendor] END ASC,
			CASE WHEN @SortColumn = 'poNumber' AND @SortOrder = 'ASC' THEN R.[PONumber] END ASC,
			CASE WHEN @SortColumn = 'vendor' AND @SortOrder = 'DESC' THEN R.[Vendor] END DESC,
			CASE WHEN @SortColumn = 'poNumber' AND @SortOrder = 'DESC' THEN R.[PONumber] END DESC,
			CASE WHEN @SortColumn = 'tsnAtPurchase' AND @SortOrder = 'ASC' THEN R.[TsnAtPurchase] END ASC,
			CASE WHEN @SortColumn = 'tsnAtPurchase' AND @SortOrder = 'DESC' THEN R.[TsnAtPurchase] END DESC,
			CASE WHEN @SortColumn = 'csnAtPurchase' AND @SortOrder = 'ASC' THEN R.[CsnAtPurchase] END ASC,
			CASE WHEN @SortColumn = 'csnAtPurchase' AND @SortOrder = 'DESC' THEN R.[CsnAtPurchase] END DESC,
			CASE WHEN @SortColumn = 'tsoCamAtPurchase' AND @SortOrder = 'ASC' THEN R.[TsoCamAtPurchase] END ASC,
			CASE WHEN @SortColumn = 'tsoCamAtPurchase' AND @SortOrder = 'DESC' THEN R.[TsoCamAtPurchase] END DESC,
			R.[LeaseNumber] DESC, R.[EngineSn], R.[StockLineId]
		OFFSET @Skip ROWS FETCH NEXT @Take ROWS ONLY
		OPTION (RECOMPILE); -- optional filters + dynamic sort : a fresh plan for every filter / sort combination

		DROP TABLE #EnginePoolRows;
	END TRY
	BEGIN CATCH
		DECLARE @ErrorLogID INT, @DatabaseName VARCHAR(100) = DB_NAME()

-------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
			, @AdhocComments VARCHAR(150) = 'USP_GetLeaseEnginePoolGeneralInfoReport'
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