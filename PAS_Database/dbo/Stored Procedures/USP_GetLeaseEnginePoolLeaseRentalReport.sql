/*************************************************************
 ** File:   [USP_GetLeaseEnginePoolLeaseRentalReport]
 ** Description: Lease Report (Engine Pool) - "Lease/Rental" tab. One row per engine (stockline) - PN View only (the Lease / Summary view was removed; @ViewType is kept
 **              only so existing callers keep working and is ignored).
 **              The main table is the Lease : LeaseStockline (latest non-deleted lease line of each engine stockline) + LeaseHeader, joined to the Stockline.
 **              Only the columns whose source is known are filled; every other column of the tab is returned as NULL (blank in the grid) until its source is agreed.
 ** Change History
 **************************************************************
 ** PR   Date			Author				Change Description
 ** -----------------------------------------------------------
    1    30/10/2026		Kishor Makwana		[PN-18419] - Created
    2    02/11/2026		Kishor Makwana		[PN-18419] - Server side search : @PageNumber/@PageSize (0 = all rows), @SortColumn/@SortOrder, @Filters (JSON column filters); returns TotalRecords
    3    04/11/2026		Kishor Makwana		[PN-17949] - Optimized : PN View only (Lease/Summary view and the #EnginePoolResult copy removed, the grid filters/sorts/pages #EnginePoolRows directly), IsActive taken from @IsActive, OPTION (RECOMPILE) on the filtered query
    4    04/11/2026		Kishor Makwana		[PN-17949] - Status (Draft / Active / Closed), Engine Type (Stockline.EngineType), Owner and Capitalized Cost (PO Cost + RO Cost x lease qty, same as the Lease Summary) columns; Disposition shows the same status value
    5    05/11/2026		Kishor Makwana		[PN-17949] - Active / Inactive switch now filters on the same Status that is displayed (stockline status, lease header status when the line has none) - Inactive showed Active lines of non-Active leases
    
-- @IsActive : 1 = Active (Status Active), 0 = Inactive (Status Draft or Closed). Status = the stockline's own status (latest LeaseStockline row), the lease header status when the line has none. LeaseStatusId : 1 Draft, 2 Active, 3 Closed
-- EXEC [dbo].[USP_GetLeaseEnginePoolLeaseRentalReport] @MasterCompanyId = 1, @IsActive = 1, @ViewType = 'PN'
************************************************************************/
CREATE   PROCEDURE [dbo].[USP_GetLeaseEnginePoolLeaseRentalReport]
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
			STK.[StockLineId]								AS [StockLineId],
			LH.[LeaseNumber]								AS [LeaseNumber],
			STK.[EngineSerialNumber]								AS [EngineSn],
			STK.[EngineModel]						AS [BaseModel],
			STK.[EngineType] AS [EngineType],
			LOC.[Name]										AS [Location],
			CAST(CASE ISNULL(LSL.[LeaseStatusId], LH.[LeaseStatusId]) WHEN 1 THEN 'Draft' WHEN 2 THEN 'Active' WHEN 3 THEN 'Closed' END AS VARCHAR(20)) AS [Status],
			CAST(CASE ISNULL(LSL.[LeaseStatusId], LH.[LeaseStatusId]) WHEN 1 THEN 'Draft' WHEN 2 THEN 'Active' WHEN 3 THEN 'Closed' END AS VARCHAR(20)) AS [Disposition],
			LCUS.[Name]										AS [Lessee],
			CASE WHEN STK.[OwnerType] = 1 THEN CUS.[Name]
				 WHEN STK.[OwnerType] = 2 THEN VEN.[VendorName]
				 WHEN STK.[OwnerType] = 9 THEN LE.[Name]
				 ELSE STK.[OwnerName] END	AS [Owner],
			LT.[LeaseType]									AS [LeaseType],
			LSL.[StartDate]									AS [RentalDate],
			LSL.[EndDate]									AS [RentalExpiration],
			CAST(NULL AS DATETIME2(7))						AS [CoiExpiration],
			LSL.[UpdatedDate]								AS [DateUpdated],
			CAST(NULL AS DECIMAL(18, 2))					AS [RentalIncome],
			CAST(NULL AS DECIMAL(18, 2))					AS [MtxExpAc6310],
			CAST((ISNULL(STK.[PurchaseOrderUnitCost], 0) + ISNULL(STK.[RepairOrderUnitCost], 0)) * ISNULL(LSL.[QtyOrder], 1) AS DECIMAL(18, 2))	AS [CapitalizedCost],
			CAST(NULL AS DECIMAL(18, 2))					AS [Roi],
			@IsActive										AS [IsActive]
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
			LEFT JOIN [dbo].[LeaseType] LT WITH (NOLOCK) ON LT.[LeaseTypeId] = LH.[LeaseTypeId]
			LEFT JOIN [dbo].[Location] LOC WITH (NOLOCK) ON LOC.[LocationId] = STK.[LocationId]
			LEFT JOIN [dbo].[Customer] CUS WITH (NOLOCK) ON STK.[OwnerType] = 1 AND CUS.[CustomerId] = STK.[Owner]
			LEFT JOIN [dbo].[Vendor] VEN WITH (NOLOCK) ON STK.[OwnerType] = 2 AND VEN.[VendorId] = STK.[Owner]
			LEFT JOIN [dbo].[LegalEntity] LE WITH (NOLOCK) ON STK.[OwnerType] = 9 AND LE.[LegalEntityId] = STK.[Owner]
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
		DECLARE @f_Location NVARCHAR(400) = NULLIF(REPLACE(REPLACE(REPLACE(LTRIM(RTRIM(JSON_VALUE(@Filters, '$.location'))), '[', '[[]'), '%', '[%]'), '_', '[_]'), '');
		DECLARE @f_Disposition NVARCHAR(400) = NULLIF(REPLACE(REPLACE(REPLACE(LTRIM(RTRIM(JSON_VALUE(@Filters, '$.disposition'))), '[', '[[]'), '%', '[%]'), '_', '[_]'), '');
		DECLARE @f_Status NVARCHAR(400) = NULLIF(REPLACE(REPLACE(REPLACE(LTRIM(RTRIM(JSON_VALUE(@Filters, '$.status'))), '[', '[[]'), '%', '[%]'), '_', '[_]'), '');
		DECLARE @f_Lessee NVARCHAR(400) = NULLIF(REPLACE(REPLACE(REPLACE(LTRIM(RTRIM(JSON_VALUE(@Filters, '$.lessee'))), '[', '[[]'), '%', '[%]'), '_', '[_]'), '');
		DECLARE @f_Owner NVARCHAR(400) = NULLIF(REPLACE(REPLACE(REPLACE(LTRIM(RTRIM(JSON_VALUE(@Filters, '$.owner'))), '[', '[[]'), '%', '[%]'), '_', '[_]'), '');
		DECLARE @f_LeaseType NVARCHAR(400) = NULLIF(REPLACE(REPLACE(REPLACE(LTRIM(RTRIM(JSON_VALUE(@Filters, '$.leaseType'))), '[', '[[]'), '%', '[%]'), '_', '[_]'), '');
		DECLARE @f_RentalDate NVARCHAR(400) = NULLIF(REPLACE(REPLACE(REPLACE(LTRIM(RTRIM(JSON_VALUE(@Filters, '$.rentalDate'))), '[', '[[]'), '%', '[%]'), '_', '[_]'), '');
		DECLARE @f_RentalExpiration NVARCHAR(400) = NULLIF(REPLACE(REPLACE(REPLACE(LTRIM(RTRIM(JSON_VALUE(@Filters, '$.rentalExpiration'))), '[', '[[]'), '%', '[%]'), '_', '[_]'), '');
		DECLARE @f_CoiExpiration NVARCHAR(400) = NULLIF(REPLACE(REPLACE(REPLACE(LTRIM(RTRIM(JSON_VALUE(@Filters, '$.coiExpiration'))), '[', '[[]'), '%', '[%]'), '_', '[_]'), '');
		DECLARE @f_DateUpdated NVARCHAR(400) = NULLIF(REPLACE(REPLACE(REPLACE(LTRIM(RTRIM(JSON_VALUE(@Filters, '$.dateUpdated'))), '[', '[[]'), '%', '[%]'), '_', '[_]'), '');
		DECLARE @f_RentalIncome NVARCHAR(400) = NULLIF(REPLACE(REPLACE(REPLACE(LTRIM(RTRIM(JSON_VALUE(@Filters, '$.rentalIncome'))), '[', '[[]'), '%', '[%]'), '_', '[_]'), '');
		DECLARE @f_MtxExpAc6310 NVARCHAR(400) = NULLIF(REPLACE(REPLACE(REPLACE(LTRIM(RTRIM(JSON_VALUE(@Filters, '$.mtxExpAc6310'))), '[', '[[]'), '%', '[%]'), '_', '[_]'), '');
		DECLARE @f_CapitalizedCost NVARCHAR(400) = NULLIF(REPLACE(REPLACE(REPLACE(LTRIM(RTRIM(JSON_VALUE(@Filters, '$.capitalizedCost'))), '[', '[[]'), '%', '[%]'), '_', '[_]'), '');
		DECLARE @f_Roi NVARCHAR(400) = NULLIF(REPLACE(REPLACE(REPLACE(LTRIM(RTRIM(JSON_VALUE(@Filters, '$.roi'))), '[', '[[]'), '%', '[%]'), '_', '[_]'), '');

		SELECT
			R.[StockLineId],
			R.[LeaseNumber],
			R.[EngineSn],
			R.[BaseModel],
			R.[EngineType],
			R.[Location],
			R.[Disposition],
			R.[Status],
			R.[Lessee],
			R.[Owner],
			R.[LeaseType],
			R.[RentalDate],
			R.[RentalExpiration],
			R.[CoiExpiration],
			R.[DateUpdated],
			R.[RentalIncome],
			R.[MtxExpAc6310],
			R.[CapitalizedCost],
			R.[Roi],
			R.[IsActive],
			COUNT(*) OVER () AS [TotalRecords]
		FROM #EnginePoolRows R
		WHERE 1 = 1
			AND (@f_LeaseNumber IS NULL OR R.[LeaseNumber] LIKE '%' + @f_LeaseNumber + '%')
			AND (@f_EngineSn IS NULL OR R.[EngineSn] LIKE '%' + @f_EngineSn + '%')
			AND (@f_BaseModel IS NULL OR R.[BaseModel] LIKE '%' + @f_BaseModel + '%')
			AND (@f_EngineType IS NULL OR R.[EngineType] LIKE '%' + @f_EngineType + '%')
			AND (@f_Location IS NULL OR R.[Location] LIKE '%' + @f_Location + '%')
			AND (@f_Disposition IS NULL OR R.[Disposition] LIKE '%' + @f_Disposition + '%')
			AND (@f_Status IS NULL OR R.[Status] LIKE '%' + @f_Status + '%')
			AND (@f_Lessee IS NULL OR R.[Lessee] LIKE '%' + @f_Lessee + '%')
			AND (@f_Owner IS NULL OR R.[Owner] LIKE '%' + @f_Owner + '%')
			AND (@f_LeaseType IS NULL OR R.[LeaseType] LIKE '%' + @f_LeaseType + '%')
			AND (@f_RentalDate IS NULL OR CONVERT(VARCHAR(10), R.[RentalDate], 101) LIKE '%' + @f_RentalDate + '%' OR CONVERT(VARCHAR(10), R.[RentalDate], 23) LIKE '%' + @f_RentalDate + '%'
				OR CONVERT(VARCHAR(10), R.[RentalDate], 105) LIKE '%' + @f_RentalDate + '%' OR CONVERT(VARCHAR(10), R.[RentalDate], 110) LIKE '%' + @f_RentalDate + '%')
			AND (@f_RentalExpiration IS NULL OR CONVERT(VARCHAR(10), R.[RentalExpiration], 101) LIKE '%' + @f_RentalExpiration + '%' OR CONVERT(VARCHAR(10), R.[RentalExpiration], 23) LIKE '%' + @f_RentalExpiration + '%'
				OR CONVERT(VARCHAR(10), R.[RentalExpiration], 105) LIKE '%' + @f_RentalExpiration + '%' OR CONVERT(VARCHAR(10), R.[RentalExpiration], 110) LIKE '%' + @f_RentalExpiration + '%')
			AND (@f_CoiExpiration IS NULL OR CONVERT(VARCHAR(10), R.[CoiExpiration], 101) LIKE '%' + @f_CoiExpiration + '%' OR CONVERT(VARCHAR(10), R.[CoiExpiration], 23) LIKE '%' + @f_CoiExpiration + '%'
				OR CONVERT(VARCHAR(10), R.[CoiExpiration], 105) LIKE '%' + @f_CoiExpiration + '%' OR CONVERT(VARCHAR(10), R.[CoiExpiration], 110) LIKE '%' + @f_CoiExpiration + '%')
			AND (@f_DateUpdated IS NULL OR CONVERT(VARCHAR(10), R.[DateUpdated], 101) LIKE '%' + @f_DateUpdated + '%' OR CONVERT(VARCHAR(10), R.[DateUpdated], 23) LIKE '%' + @f_DateUpdated + '%'
				OR CONVERT(VARCHAR(10), R.[DateUpdated], 105) LIKE '%' + @f_DateUpdated + '%' OR CONVERT(VARCHAR(10), R.[DateUpdated], 110) LIKE '%' + @f_DateUpdated + '%')
			AND (@f_RentalIncome IS NULL OR CAST(R.[RentalIncome] AS VARCHAR(50)) LIKE '%' + REPLACE(REPLACE(@f_RentalIncome, ',', ''), '$', '') + '%')
			AND (@f_MtxExpAc6310 IS NULL OR CAST(R.[MtxExpAc6310] AS VARCHAR(50)) LIKE '%' + REPLACE(REPLACE(@f_MtxExpAc6310, ',', ''), '$', '') + '%')
			AND (@f_CapitalizedCost IS NULL OR CAST(R.[CapitalizedCost] AS VARCHAR(50)) LIKE '%' + REPLACE(REPLACE(@f_CapitalizedCost, ',', ''), '$', '') + '%')
			AND (@f_Roi IS NULL OR CAST(R.[Roi] AS VARCHAR(50)) LIKE '%' + REPLACE(REPLACE(@f_Roi, ',', ''), '$', '') + '%')
		ORDER BY
			CASE WHEN @SortColumn = 'leaseNumber' AND @SortOrder = 'ASC' THEN R.[LeaseNumber] END ASC,
			CASE WHEN @SortColumn = 'leaseNumber' AND @SortOrder = 'DESC' THEN R.[LeaseNumber] END DESC,
			CASE WHEN @SortColumn = 'engineSn' AND @SortOrder = 'ASC' THEN R.[EngineSn] END ASC,
			CASE WHEN @SortColumn = 'engineSn' AND @SortOrder = 'DESC' THEN R.[EngineSn] END DESC,
			CASE WHEN @SortColumn = 'baseModel' AND @SortOrder = 'ASC' THEN R.[BaseModel] END ASC,
			CASE WHEN @SortColumn = 'baseModel' AND @SortOrder = 'DESC' THEN R.[BaseModel] END DESC,
			CASE WHEN @SortColumn = 'engineType' AND @SortOrder = 'ASC' THEN R.[EngineType] END ASC,
			CASE WHEN @SortColumn = 'engineType' AND @SortOrder = 'DESC' THEN R.[EngineType] END DESC,
			CASE WHEN @SortColumn = 'location' AND @SortOrder = 'ASC' THEN R.[Location] END ASC,
			CASE WHEN @SortColumn = 'location' AND @SortOrder = 'DESC' THEN R.[Location] END DESC,
			CASE WHEN @SortColumn = 'disposition' AND @SortOrder = 'ASC' THEN R.[Disposition] END ASC,
			CASE WHEN @SortColumn = 'disposition' AND @SortOrder = 'DESC' THEN R.[Disposition] END DESC,
			CASE WHEN @SortColumn = 'status' AND @SortOrder = 'ASC' THEN R.[Status] END ASC,
			CASE WHEN @SortColumn = 'status' AND @SortOrder = 'DESC' THEN R.[Status] END DESC,
			CASE WHEN @SortColumn = 'lessee' AND @SortOrder = 'ASC' THEN R.[Lessee] END ASC,
			CASE WHEN @SortColumn = 'lessee' AND @SortOrder = 'DESC' THEN R.[Lessee] END DESC,
			CASE WHEN @SortColumn = 'owner' AND @SortOrder = 'ASC' THEN R.[Owner] END ASC,
			CASE WHEN @SortColumn = 'owner' AND @SortOrder = 'DESC' THEN R.[Owner] END DESC,
			CASE WHEN @SortColumn = 'leaseType' AND @SortOrder = 'ASC' THEN R.[LeaseType] END ASC,
			CASE WHEN @SortColumn = 'leaseType' AND @SortOrder = 'DESC' THEN R.[LeaseType] END DESC,
			CASE WHEN @SortColumn = 'rentalDate' AND @SortOrder = 'ASC' THEN R.[RentalDate] END ASC,
			CASE WHEN @SortColumn = 'rentalDate' AND @SortOrder = 'DESC' THEN R.[RentalDate] END DESC,
			CASE WHEN @SortColumn = 'rentalExpiration' AND @SortOrder = 'ASC' THEN R.[RentalExpiration] END ASC,
			CASE WHEN @SortColumn = 'rentalExpiration' AND @SortOrder = 'DESC' THEN R.[RentalExpiration] END DESC,
			CASE WHEN @SortColumn = 'coiExpiration' AND @SortOrder = 'ASC' THEN R.[CoiExpiration] END ASC,
			CASE WHEN @SortColumn = 'coiExpiration' AND @SortOrder = 'DESC' THEN R.[CoiExpiration] END DESC,
			CASE WHEN @SortColumn = 'dateUpdated' AND @SortOrder = 'ASC' THEN R.[DateUpdated] END ASC,
			CASE WHEN @SortColumn = 'dateUpdated' AND @SortOrder = 'DESC' THEN R.[DateUpdated] END DESC,
			CASE WHEN @SortColumn = 'rentalIncome' AND @SortOrder = 'ASC' THEN R.[RentalIncome] END ASC,
			CASE WHEN @SortColumn = 'rentalIncome' AND @SortOrder = 'DESC' THEN R.[RentalIncome] END DESC,
			CASE WHEN @SortColumn = 'mtxExpAc6310' AND @SortOrder = 'ASC' THEN R.[MtxExpAc6310] END ASC,
			CASE WHEN @SortColumn = 'mtxExpAc6310' AND @SortOrder = 'DESC' THEN R.[MtxExpAc6310] END DESC,
			CASE WHEN @SortColumn = 'capitalizedCost' AND @SortOrder = 'ASC' THEN R.[CapitalizedCost] END ASC,
			CASE WHEN @SortColumn = 'capitalizedCost' AND @SortOrder = 'DESC' THEN R.[CapitalizedCost] END DESC,
			CASE WHEN @SortColumn = 'roi' AND @SortOrder = 'ASC' THEN R.[Roi] END ASC,
			CASE WHEN @SortColumn = 'roi' AND @SortOrder = 'DESC' THEN R.[Roi] END DESC,
			R.[LeaseNumber] DESC, R.[EngineSn], R.[StockLineId]
		OFFSET @Skip ROWS FETCH NEXT @Take ROWS ONLY
		OPTION (RECOMPILE); -- optional filters + dynamic sort : a fresh plan for every filter / sort combination

		DROP TABLE #EnginePoolRows;
	END TRY
	BEGIN CATCH
		DECLARE @ErrorLogID INT, @DatabaseName VARCHAR(100) = DB_NAME()

-------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
			, @AdhocComments VARCHAR(150) = 'USP_GetLeaseEnginePoolLeaseRentalReport'
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