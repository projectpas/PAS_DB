/*************************************************************
 ** File:   [USP_GetLeaseEnginePoolMaintenanceReport]
 ** Description: Lease Report (Engine Pool) - "Maintenance" tab (PN View only). One row per engine (stockline).
 **              Purpose: Leasing > Reports > Lease Report > Maintenance
 **              The main table is the Lease : LeaseStockline (latest non-deleted lease line of each engine stockline) + LeaseHeader, joined to the Stockline.
 **              Only the columns whose source is known are filled; every other column of the tab is returned as NULL (blank in the grid) until its source is agreed.
 ** Change History
 **************************************************************
 ** PR   Date			Author				Change Description
 ** -----------------------------------------------------------
    1    30/10/2026		Kishor Makwana		[PN-18419] - Created
    2    02/11/2026		Kishor Makwana		[PN-18419] - Server side search : @PageNumber/@PageSize (0 = all rows), @SortColumn/@SortOrder, @Filters (JSON column filters); returns TotalRecords
    3    04/11/2026		Kishor Makwana		[PN-17949] - Status column (the part's Lease Status : Draft / Active / Closed); Disposition shows the same status value
    4    05/11/2026		Kishor Makwana		[PN-17949] - Active / Inactive switch now filters on the same Status that is displayed (stockline status, lease header status when the line has none) - Inactive showed Active lines of non-Active leases
    
-- @IsActive : 1 = Active (Status Active), 0 = Inactive (Status Draft or Closed). Status = the stockline's own status (latest LeaseStockline row), the lease header status when the line has none. LeaseStatusId : 1 Draft, 2 Active, 3 Closed
-- EXEC [dbo].[USP_GetLeaseEnginePoolMaintenanceReport] @MasterCompanyId = 1, @IsActive = 1
************************************************************************/
CREATE   PROCEDURE [dbo].[USP_GetLeaseEnginePoolMaintenanceReport]
	@MasterCompanyId INT,
	@IsActive BIT = 1,
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
			LOC.[Name] AS [Location],
			CAST(CASE ISNULL(LSL.[LeaseStatusId], LH.[LeaseStatusId]) WHEN 1 THEN 'Draft' WHEN 2 THEN 'Active' WHEN 3 THEN 'Closed' END AS VARCHAR(20)) AS [Status],
			CAST(CASE ISNULL(LSL.[LeaseStatusId], LH.[LeaseStatusId]) WHEN 1 THEN 'Draft' WHEN 2 THEN 'Active' WHEN 3 THEN 'Closed' END AS VARCHAR(20)) AS [Disposition],
			LCUS.[Name] AS [Lessee],
			CAST(NULL AS VARCHAR(200)) AS [Program],
			HTE.[HoursToNextEvent] AS [HoursToNextEvent],
			HTE.[NextTimedEvent] AS [NextTimedEvent],
			CYC.[CyclesToNextEvent] AS [CyclesToNextEvent],
			CYC.[NextCycledEvent] AS [NextCycledEvent],
			CAST(NULL AS VARCHAR(200)) AS [DataPlate],
			CAST(NULL AS VARCHAR(200)) AS [NtsSwitchInstalled],
			CAST(NULL AS VARCHAR(200)) AS [BetaSwitchInstalled],
			CAST(NULL AS VARCHAR(200)) AS [LastBorescope],
			CAST(NULL AS VARCHAR(200)) AS [LongTermPreserveExpDate],
			CAST(NULL AS DECIMAL(18, 2)) AS [MtxExpAc6310],
			CAST(NULL AS DATETIME2(7)) AS [LogbookScanDate],
			CAST(CASE WHEN ISNULL(LSL.[LeaseStatusId], LH.[LeaseStatusId]) = 2 THEN 1 ELSE 0 END AS BIT) AS [IsActive],
			LSL.[LeaseHeaderId]								AS [LeaseHeaderId]
		INTO #EnginePoolRows
		FROM (
				SELECT LS.[StockLineId], LS.[LeaseHeaderId], LS.[LeaseStatusId], LS.[QtyOrder], LS.[StartDate], LS.[EndDate], LS.[UpdatedDate],
					LS.[LeaseStocklineId],
					ROW_NUMBER() OVER (PARTITION BY LS.[StockLineId] ORDER BY ISNULL(LS.[StartDate], '1900-01-01') DESC, LS.[LeaseStocklineId] DESC) AS [RN]
				FROM [dbo].[LeaseStockline] LS WITH (NOLOCK)
				WHERE LS.[MasterCompanyId] = @MasterCompanyId AND ISNULL(LS.[IsDeleted], 0) = 0
			) LSL
			INNER JOIN [dbo].[LeaseHeader] LH WITH (NOLOCK) ON LH.[LeaseHeaderId] = LSL.[LeaseHeaderId] AND ISNULL(LH.[IsDeleted], 0) = 0
			INNER JOIN [dbo].[Stockline] STK WITH (NOLOCK) ON STK.[StockLineId] = LSL.[StockLineId]
			LEFT JOIN [dbo].[Customer] LCUS WITH (NOLOCK) ON LCUS.[CustomerId] = LH.[CustomerId]
			LEFT JOIN [dbo].[Location] LOC WITH (NOLOCK) ON LOC.[LocationId] = STK.[LocationId]
			OUTER APPLY (
				SELECT TOP 1
					CAST((AMP.[FlightHoursRemainingHours] * 60 + ISNULL(AMP.[FlightHoursRemainingMinutes], 0)) / 60.0 AS DECIMAL(18, 2)) AS [HoursToNextEvent],
					AMP.[MaintenanceType] AS [NextTimedEvent]
				FROM [dbo].[EngineRegistryHeader] ER WITH (NOLOCK)
					INNER JOIN [dbo].[AircraftMaintenanceProgram] AMP WITH (NOLOCK) ON AMP.[EngineRegistryId] = ER.[EngineRegistryId]
				WHERE ER.[StockLineId] = STK.[StockLineId] AND ISNULL(ER.[IsDeleted], 0) = 0
					AND ISNULL(AMP.[IsDeleted], 0) = 0 AND ISNULL(AMP.[IsActive], 1) = 1
					AND (ISNULL(AMP.[FlightHoursLimitHours], 0) > 0 OR ISNULL(AMP.[FlightHoursLimitMinutes], 0) > 0)
					AND AMP.[FlightHoursRemainingHours] IS NOT NULL
				ORDER BY (AMP.[FlightHoursRemainingHours] * 60 + ISNULL(AMP.[FlightHoursRemainingMinutes], 0)) ASC, AMP.[ProgramId]
			) HTE
			OUTER APPLY (
				SELECT TOP 1
					AMP.[CyclesRemaining] AS [CyclesToNextEvent],
					AMP.[MaintenanceType] AS [NextCycledEvent]
				FROM [dbo].[EngineRegistryHeader] ER WITH (NOLOCK)
					INNER JOIN [dbo].[AircraftMaintenanceProgram] AMP WITH (NOLOCK) ON AMP.[EngineRegistryId] = ER.[EngineRegistryId]
				WHERE ER.[StockLineId] = STK.[StockLineId] AND ISNULL(ER.[IsDeleted], 0) = 0
					AND ISNULL(AMP.[IsDeleted], 0) = 0 AND ISNULL(AMP.[IsActive], 1) = 1
					AND ISNULL(AMP.[CyclesLimit], 0) > 0 AND AMP.[CyclesRemaining] IS NOT NULL
				ORDER BY AMP.[CyclesRemaining] ASC, AMP.[ProgramId]
			) CYC
		WHERE LSL.[RN] = 1
			AND STK.[MasterCompanyId] = @MasterCompanyId
			AND ISNULL(STK.[isDeleted], 0) = 0
			AND (CASE WHEN ISNULL(LSL.[LeaseStatusId], LH.[LeaseStatusId]) = 2 THEN 1 ELSE 0 END) = @IsActive;

		IF OBJECT_ID('tempdb..#EnginePoolResult') IS NOT NULL DROP TABLE #EnginePoolResult;

		-- PN View only : one row per part (engine) - its latest lease line
		SELECT
			R.[StockLineId],
			R.[LeaseNumber],
			R.[EngineSn],
			R.[Location],
			R.[Disposition],
			R.[Status],
			R.[Lessee],
			R.[Program],
			R.[HoursToNextEvent],
			R.[NextTimedEvent],
			R.[CyclesToNextEvent],
			R.[NextCycledEvent],
			R.[DataPlate],
			R.[NtsSwitchInstalled],
			R.[BetaSwitchInstalled],
			R.[LastBorescope],
			R.[LongTermPreserveExpDate],
			R.[MtxExpAc6310],
			R.[LogbookScanDate],
			R.[IsActive]
		INTO #EnginePoolResult
		FROM #EnginePoolRows R;

		DECLARE @Take INT = CASE WHEN ISNULL(@PageSize, 0) <= 0 THEN 2147483647 ELSE @PageSize END;
		DECLARE @Skip INT = CASE WHEN ISNULL(@PageSize, 0) <= 0 THEN 0 ELSE (ISNULL(NULLIF(@PageNumber, 0), 1) - 1) * @PageSize END;
		-- column filters of the grid (JSON : {"engineSn":"text", ...}) - a column contains the text; dates match the usual date formats, amounts the number
		DECLARE @f_LeaseNumber NVARCHAR(400) = NULLIF(REPLACE(REPLACE(REPLACE(LTRIM(RTRIM(JSON_VALUE(@Filters, '$.leaseNumber'))), '[', '[[]'), '%', '[%]'), '_', '[_]'), '');
		DECLARE @f_EngineSn NVARCHAR(400) = NULLIF(REPLACE(REPLACE(REPLACE(LTRIM(RTRIM(JSON_VALUE(@Filters, '$.engineSn'))), '[', '[[]'), '%', '[%]'), '_', '[_]'), '');
		DECLARE @f_Location NVARCHAR(400) = NULLIF(REPLACE(REPLACE(REPLACE(LTRIM(RTRIM(JSON_VALUE(@Filters, '$.location'))), '[', '[[]'), '%', '[%]'), '_', '[_]'), '');
		DECLARE @f_Disposition NVARCHAR(400) = NULLIF(REPLACE(REPLACE(REPLACE(LTRIM(RTRIM(JSON_VALUE(@Filters, '$.disposition'))), '[', '[[]'), '%', '[%]'), '_', '[_]'), '');
		DECLARE @f_Status NVARCHAR(400) = NULLIF(REPLACE(REPLACE(REPLACE(LTRIM(RTRIM(JSON_VALUE(@Filters, '$.status'))), '[', '[[]'), '%', '[%]'), '_', '[_]'), '');
		DECLARE @f_Lessee NVARCHAR(400) = NULLIF(REPLACE(REPLACE(REPLACE(LTRIM(RTRIM(JSON_VALUE(@Filters, '$.lessee'))), '[', '[[]'), '%', '[%]'), '_', '[_]'), '');
		DECLARE @f_Program NVARCHAR(400) = NULLIF(REPLACE(REPLACE(REPLACE(LTRIM(RTRIM(JSON_VALUE(@Filters, '$.program'))), '[', '[[]'), '%', '[%]'), '_', '[_]'), '');
		DECLARE @f_HoursToNextEvent NVARCHAR(400) = NULLIF(REPLACE(REPLACE(REPLACE(LTRIM(RTRIM(JSON_VALUE(@Filters, '$.hoursToNextEvent'))), '[', '[[]'), '%', '[%]'), '_', '[_]'), '');
		DECLARE @f_NextTimedEvent NVARCHAR(400) = NULLIF(REPLACE(REPLACE(REPLACE(LTRIM(RTRIM(JSON_VALUE(@Filters, '$.nextTimedEvent'))), '[', '[[]'), '%', '[%]'), '_', '[_]'), '');
		DECLARE @f_CyclesToNextEvent NVARCHAR(400) = NULLIF(REPLACE(REPLACE(REPLACE(LTRIM(RTRIM(JSON_VALUE(@Filters, '$.cyclesToNextEvent'))), '[', '[[]'), '%', '[%]'), '_', '[_]'), '');
		DECLARE @f_NextCycledEvent NVARCHAR(400) = NULLIF(REPLACE(REPLACE(REPLACE(LTRIM(RTRIM(JSON_VALUE(@Filters, '$.nextCycledEvent'))), '[', '[[]'), '%', '[%]'), '_', '[_]'), '');
		DECLARE @f_DataPlate NVARCHAR(400) = NULLIF(REPLACE(REPLACE(REPLACE(LTRIM(RTRIM(JSON_VALUE(@Filters, '$.dataPlate'))), '[', '[[]'), '%', '[%]'), '_', '[_]'), '');
		DECLARE @f_NtsSwitchInstalled NVARCHAR(400) = NULLIF(REPLACE(REPLACE(REPLACE(LTRIM(RTRIM(JSON_VALUE(@Filters, '$.ntsSwitchInstalled'))), '[', '[[]'), '%', '[%]'), '_', '[_]'), '');
		DECLARE @f_BetaSwitchInstalled NVARCHAR(400) = NULLIF(REPLACE(REPLACE(REPLACE(LTRIM(RTRIM(JSON_VALUE(@Filters, '$.betaSwitchInstalled'))), '[', '[[]'), '%', '[%]'), '_', '[_]'), '');
		DECLARE @f_LastBorescope NVARCHAR(400) = NULLIF(REPLACE(REPLACE(REPLACE(LTRIM(RTRIM(JSON_VALUE(@Filters, '$.lastBorescope'))), '[', '[[]'), '%', '[%]'), '_', '[_]'), '');
		DECLARE @f_LongTermPreserveExpDate NVARCHAR(400) = NULLIF(REPLACE(REPLACE(REPLACE(LTRIM(RTRIM(JSON_VALUE(@Filters, '$.longTermPreserveExpDate'))), '[', '[[]'), '%', '[%]'), '_', '[_]'), '');
		DECLARE @f_MtxExpAc6310 NVARCHAR(400) = NULLIF(REPLACE(REPLACE(REPLACE(LTRIM(RTRIM(JSON_VALUE(@Filters, '$.mtxExpAc6310'))), '[', '[[]'), '%', '[%]'), '_', '[_]'), '');
		DECLARE @f_LogbookScanDate NVARCHAR(400) = NULLIF(REPLACE(REPLACE(REPLACE(LTRIM(RTRIM(JSON_VALUE(@Filters, '$.logbookScanDate'))), '[', '[[]'), '%', '[%]'), '_', '[_]'), '');

		SELECT
			R.[StockLineId],
			R.[LeaseNumber],
			R.[EngineSn],
			R.[Location],
			R.[Disposition],
			R.[Status],
			R.[Lessee],
			R.[Program],
			R.[HoursToNextEvent],
			R.[NextTimedEvent],
			R.[CyclesToNextEvent],
			R.[NextCycledEvent],
			R.[DataPlate],
			R.[NtsSwitchInstalled],
			R.[BetaSwitchInstalled],
			R.[LastBorescope],
			R.[LongTermPreserveExpDate],
			R.[MtxExpAc6310],
			R.[LogbookScanDate],
			R.[IsActive],
			COUNT(*) OVER () AS [TotalRecords]
		FROM #EnginePoolResult R
		WHERE 1 = 1
			AND (@f_LeaseNumber IS NULL OR R.[LeaseNumber] LIKE '%' + @f_LeaseNumber + '%')
			AND (@f_EngineSn IS NULL OR R.[EngineSn] LIKE '%' + @f_EngineSn + '%')
			AND (@f_Location IS NULL OR R.[Location] LIKE '%' + @f_Location + '%')
			AND (@f_Disposition IS NULL OR R.[Disposition] LIKE '%' + @f_Disposition + '%')
			AND (@f_Status IS NULL OR R.[Status] LIKE '%' + @f_Status + '%')
			AND (@f_Lessee IS NULL OR R.[Lessee] LIKE '%' + @f_Lessee + '%')
			AND (@f_Program IS NULL OR R.[Program] LIKE '%' + @f_Program + '%')
			AND (@f_HoursToNextEvent IS NULL OR CAST(R.[HoursToNextEvent] AS VARCHAR(50)) LIKE '%' + REPLACE(REPLACE(@f_HoursToNextEvent, ',', ''), '$', '') + '%')
			AND (@f_NextTimedEvent IS NULL OR R.[NextTimedEvent] LIKE '%' + @f_NextTimedEvent + '%')
			AND (@f_CyclesToNextEvent IS NULL OR CAST(R.[CyclesToNextEvent] AS VARCHAR(50)) LIKE '%' + REPLACE(REPLACE(@f_CyclesToNextEvent, ',', ''), '$', '') + '%')
			AND (@f_NextCycledEvent IS NULL OR R.[NextCycledEvent] LIKE '%' + @f_NextCycledEvent + '%')
			AND (@f_DataPlate IS NULL OR R.[DataPlate] LIKE '%' + @f_DataPlate + '%')
			AND (@f_NtsSwitchInstalled IS NULL OR R.[NtsSwitchInstalled] LIKE '%' + @f_NtsSwitchInstalled + '%')
			AND (@f_BetaSwitchInstalled IS NULL OR R.[BetaSwitchInstalled] LIKE '%' + @f_BetaSwitchInstalled + '%')
			AND (@f_LastBorescope IS NULL OR R.[LastBorescope] LIKE '%' + @f_LastBorescope + '%')
			AND (@f_LongTermPreserveExpDate IS NULL OR R.[LongTermPreserveExpDate] LIKE '%' + @f_LongTermPreserveExpDate + '%')
			AND (@f_MtxExpAc6310 IS NULL OR CAST(R.[MtxExpAc6310] AS VARCHAR(50)) LIKE '%' + REPLACE(REPLACE(@f_MtxExpAc6310, ',', ''), '$', '') + '%')
			AND (@f_LogbookScanDate IS NULL OR CONVERT(VARCHAR(10), R.[LogbookScanDate], 101) LIKE '%' + @f_LogbookScanDate + '%' OR CONVERT(VARCHAR(10), R.[LogbookScanDate], 23) LIKE '%' + @f_LogbookScanDate + '%'
				OR CONVERT(VARCHAR(10), R.[LogbookScanDate], 105) LIKE '%' + @f_LogbookScanDate + '%' OR CONVERT(VARCHAR(10), R.[LogbookScanDate], 110) LIKE '%' + @f_LogbookScanDate + '%')
		ORDER BY
			CASE WHEN @SortColumn = 'leaseNumber' AND @SortOrder = 'ASC' THEN R.[LeaseNumber] END ASC,
			CASE WHEN @SortColumn = 'leaseNumber' AND @SortOrder = 'DESC' THEN R.[LeaseNumber] END DESC,
			CASE WHEN @SortColumn = 'engineSn' AND @SortOrder = 'ASC' THEN R.[EngineSn] END ASC,
			CASE WHEN @SortColumn = 'engineSn' AND @SortOrder = 'DESC' THEN R.[EngineSn] END DESC,
			CASE WHEN @SortColumn = 'location' AND @SortOrder = 'ASC' THEN R.[Location] END ASC,
			CASE WHEN @SortColumn = 'location' AND @SortOrder = 'DESC' THEN R.[Location] END DESC,
			CASE WHEN @SortColumn = 'disposition' AND @SortOrder = 'ASC' THEN R.[Disposition] END ASC,
			CASE WHEN @SortColumn = 'disposition' AND @SortOrder = 'DESC' THEN R.[Disposition] END DESC,
			CASE WHEN @SortColumn = 'status' AND @SortOrder = 'ASC' THEN R.[Status] END ASC,
			CASE WHEN @SortColumn = 'status' AND @SortOrder = 'DESC' THEN R.[Status] END DESC,
			CASE WHEN @SortColumn = 'lessee' AND @SortOrder = 'ASC' THEN R.[Lessee] END ASC,
			CASE WHEN @SortColumn = 'lessee' AND @SortOrder = 'DESC' THEN R.[Lessee] END DESC,
			CASE WHEN @SortColumn = 'program' AND @SortOrder = 'ASC' THEN R.[Program] END ASC,
			CASE WHEN @SortColumn = 'program' AND @SortOrder = 'DESC' THEN R.[Program] END DESC,
			CASE WHEN @SortColumn = 'hoursToNextEvent' AND @SortOrder = 'ASC' THEN R.[HoursToNextEvent] END ASC,
			CASE WHEN @SortColumn = 'hoursToNextEvent' AND @SortOrder = 'DESC' THEN R.[HoursToNextEvent] END DESC,
			CASE WHEN @SortColumn = 'nextTimedEvent' AND @SortOrder = 'ASC' THEN R.[NextTimedEvent] END ASC,
			CASE WHEN @SortColumn = 'nextTimedEvent' AND @SortOrder = 'DESC' THEN R.[NextTimedEvent] END DESC,
			CASE WHEN @SortColumn = 'cyclesToNextEvent' AND @SortOrder = 'ASC' THEN R.[CyclesToNextEvent] END ASC,
			CASE WHEN @SortColumn = 'cyclesToNextEvent' AND @SortOrder = 'DESC' THEN R.[CyclesToNextEvent] END DESC,
			CASE WHEN @SortColumn = 'nextCycledEvent' AND @SortOrder = 'ASC' THEN R.[NextCycledEvent] END ASC,
			CASE WHEN @SortColumn = 'nextCycledEvent' AND @SortOrder = 'DESC' THEN R.[NextCycledEvent] END DESC,
			CASE WHEN @SortColumn = 'dataPlate' AND @SortOrder = 'ASC' THEN R.[DataPlate] END ASC,
			CASE WHEN @SortColumn = 'dataPlate' AND @SortOrder = 'DESC' THEN R.[DataPlate] END DESC,
			CASE WHEN @SortColumn = 'ntsSwitchInstalled' AND @SortOrder = 'ASC' THEN R.[NtsSwitchInstalled] END ASC,
			CASE WHEN @SortColumn = 'ntsSwitchInstalled' AND @SortOrder = 'DESC' THEN R.[NtsSwitchInstalled] END DESC,
			CASE WHEN @SortColumn = 'betaSwitchInstalled' AND @SortOrder = 'ASC' THEN R.[BetaSwitchInstalled] END ASC,
			CASE WHEN @SortColumn = 'betaSwitchInstalled' AND @SortOrder = 'DESC' THEN R.[BetaSwitchInstalled] END DESC,
			CASE WHEN @SortColumn = 'lastBorescope' AND @SortOrder = 'ASC' THEN R.[LastBorescope] END ASC,
			CASE WHEN @SortColumn = 'lastBorescope' AND @SortOrder = 'DESC' THEN R.[LastBorescope] END DESC,
			CASE WHEN @SortColumn = 'longTermPreserveExpDate' AND @SortOrder = 'ASC' THEN R.[LongTermPreserveExpDate] END ASC,
			CASE WHEN @SortColumn = 'longTermPreserveExpDate' AND @SortOrder = 'DESC' THEN R.[LongTermPreserveExpDate] END DESC,
			CASE WHEN @SortColumn = 'mtxExpAc6310' AND @SortOrder = 'ASC' THEN R.[MtxExpAc6310] END ASC,
			CASE WHEN @SortColumn = 'mtxExpAc6310' AND @SortOrder = 'DESC' THEN R.[MtxExpAc6310] END DESC,
			CASE WHEN @SortColumn = 'logbookScanDate' AND @SortOrder = 'ASC' THEN R.[LogbookScanDate] END ASC,
			CASE WHEN @SortColumn = 'logbookScanDate' AND @SortOrder = 'DESC' THEN R.[LogbookScanDate] END DESC,
			R.[LeaseNumber] DESC, R.[EngineSn], R.[StockLineId]
		OFFSET @Skip ROWS FETCH NEXT @Take ROWS ONLY;

		DROP TABLE #EnginePoolResult;
		DROP TABLE #EnginePoolRows;
	END TRY
	BEGIN CATCH
		DECLARE @ErrorLogID INT, @DatabaseName VARCHAR(100) = DB_NAME()

-------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
			, @AdhocComments VARCHAR(150) = 'USP_GetLeaseEnginePoolMaintenanceReport'
			, @ProcedureParameters VARCHAR(3000) = '@MasterCompanyId = ' + ISNULL(CAST(@MasterCompanyId AS VARCHAR(10)), '') + ', @IsActive = ' + ISNULL(CAST(@IsActive AS VARCHAR(1)), '')
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