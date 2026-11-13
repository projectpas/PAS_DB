/*************************************************************
 ** File:   [USP_GetStocklineAssetDepreciableList]
 ** Description: Lease Asset Depreciation - list of the depreciable Stockline assets (Stockline.IsAsset = 1, IsLease = 1, AssetIsDepreciable = 1) for the
 **              Run Process screen (Legal Entity + Accounting Period). One row per stockline with the last depreciation (Accumulated Depr, NBV, last period),
 **              the amount the next run will depreciate, and IsSelectable / NotSelectableReason (already run for the period, fully depreciated,
 **              cost / Asset Life not set, status not Depreciating, depreciation start after the period, converted to inventory).
 **              USAGE BASED (PN-18535) :
 **                Cost                    = Stockline.AssetTotalCost (Purchase Price + Installation Cost ...)
 **                Depreciation per Hr     = Cost / Asset Life                  (Stockline.AssetLife = Asset Life (Mths) of the asset)
 **                Usage Hours of period   = Time usage (Usage Info : LeaseStocklineUsageHistory, UsageType 'T') up to the period end
 **                                          minus the hours already depreciated in the earlier periods
 **                Period Depreciation     = Usage Hours of period x Depreciation per Hr (never more than the Cost still to depreciate)
 **                Accumulated Depr        = running total, NBV = Cost - Accumulated Depr
 ** Parameters: @LegalEntityIds comma separated (empty = all), @PageSize 0 = all rows, @SortColumn (see the CASE list), @GlobalFilter text search.
 **************************************************************
 ** Change History
 **************************************************************
 ** PR   Date            Author          Change Description
 ** --   --------        -------         --------------------------------
    1    11/November/2026 Kishor Makwana  [Lease Asset Depreciation] Created
    2    12/November/2026 Kishor Makwana  [PN-18535] Reworked from straight line (months) to usage based (Cost / Lease Duration Hrs x usage hours). Converted assets are not listed.
 -- EXEC [dbo].[USP_GetStocklineAssetDepreciableList] @MasterCompanyId = 1, @AccountingCalendarId = 1, @LegalEntityIds = NULL, @PageNumber = 1, @PageSize = 50
**************************************************************/
CREATE PROCEDURE [dbo].[USP_GetStocklineAssetDepreciableList]
	@MasterCompanyId      INT,
	@AccountingCalendarId BIGINT,
	@LegalEntityIds       VARCHAR(MAX) = NULL,
	@PageNumber           INT = 1,
	@PageSize             INT = 50,
	@SortColumn           VARCHAR(100) = NULL,
	@SortOrder            VARCHAR(4) = 'ASC',
	@GlobalFilter         NVARCHAR(250) = NULL
AS
BEGIN
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
	BEGIN TRY
		DECLARE @PeriodName VARCHAR(100), @PeriodTo DATETIME2(7);
		SELECT @PeriodName = Period.PeriodName, @PeriodTo = Period.ToDate
		FROM dbo.AccountingCalendar Period WITH (NOLOCK)
		WHERE Period.AccountingCalendarId = @AccountingCalendarId AND ISNULL(Period.IsDeleted, 0) = 0;

		DECLARE @Take INT = CASE WHEN ISNULL(@PageSize, 0) <= 0 THEN 2147483647 ELSE @PageSize END;
		DECLARE @Skip INT = CASE WHEN ISNULL(@PageSize, 0) <= 0 THEN 0 ELSE (ISNULL(NULLIF(@PageNumber, 0), 1) - 1) * @PageSize END;
		DECLARE @Filter NVARCHAR(250) = NULLIF(LTRIM(RTRIM(REPLACE(REPLACE(REPLACE(ISNULL(@GlobalFilter, ''), '[', '[[]'), '%', '[%]'), '_', '[_]'))), '');

		IF OBJECT_ID(N'tempdb..#DepreciableRows') IS NOT NULL DROP TABLE #DepreciableRows;

		SELECT
			Calc.*,
			CAST(CASE WHEN Calc.[NotSelectableReason] IS NULL THEN 1 ELSE 0 END AS BIT) AS [IsSelectable]
		INTO #DepreciableRows
		FROM (
			SELECT
				Base.*,
				CASE
					WHEN Base.[IsRunForPeriod] = 1 THEN 'Already depreciated for the selected period'
					WHEN Base.[InstalledCost] > 0 AND Base.[LeaseDurationHrs] > 0 AND Base.[Remaining] <= 0 THEN 'Fully depreciated'
					WHEN Base.[InstalledCost] <= 0 THEN 'Asset cost is not set'
					WHEN Base.[LeaseDurationHrs] <= 0 THEN 'Asset Life is not set'
					WHEN UPPER(ISNULL(Base.[AssetStatus], '')) <> 'DEPRECIATING' THEN 'Asset status is not Depreciating'
					WHEN Base.[DepreciationStartDate] IS NOT NULL AND @PeriodTo IS NOT NULL AND Base.[DepreciationStartDate] > @PeriodTo THEN 'Depreciation starts after the selected period'
					ELSE NULL
				END AS [NotSelectableReason]
			FROM (
				SELECT
					STK.[StockLineId],
					STK.[StockLineNumber],
					STK.[SerialNumber],
					STK.[PartNumber],
					STK.[PNDescription]										AS [PartDescription],
					STK.[AssetName],
					STK.[AssetInventoryNumber],
					STK.[AssetStatusId],
					AST.[Name]												AS [AssetStatus],
					STK.[LegalEntityId],
					LE.[Name]												AS [LegalEntityName],
					STK.[ManagementStructureId],
					STK.[Currency],
					ISNULL(STK.[AssetTotalCost], 0)							AS [InstalledCost],
					ISNULL(STK.[AssetLife], 0)								AS [DepreciableLife],
					STK.[DepreciationMethodName]							AS [DepreciationMethod],
					STK.[DepreciationFrequencyName]							AS [DepreciationFrequency],
					COALESCE(STK.[AssetDepreciationStartDate], STK.[ReceivedDate], STK.[EntryDate]) AS [DepreciationStartDate],
					D.[LeaseDurationHrs],
					D.[DepreciationPerHour],
					CAST(ISNULL(U.[UsageToDate], 0) AS DECIMAL(18, 6))		AS [UsageHoursToDate],
					CAST(ISNULL(PU.[BookedHours], 0) AS DECIMAL(18, 6))		AS [BookedHours],
					CAST(CASE WHEN ISNULL(U.[UsageToDate], 0) - ISNULL(PU.[BookedHours], 0) > 0 THEN ISNULL(U.[UsageToDate], 0) - ISNULL(PU.[BookedHours], 0) ELSE 0 END AS DECIMAL(18, 6)) AS [PeriodUsageHours],
					ISNULL(LH.[AccumulatedDepr], 0)							AS [AccumulatedDepr],
					ISNULL(LH.[NetBookValue], ISNULL(STK.[AssetTotalCost], 0)) AS [NetBookValue],
					LH.[DepreciationAmount]									AS [LastDepreciationAmount],
					LH.[LastDeprRunPeriod],
					ISNULL(HC.[NumOfDeprPeriod], 0)							AS [NumOfDeprPeriod],
					ISNULL(HC.[AccountingCalendarIds], '')					AS [AccountingCalendarIds],
					CAST(CASE WHEN EXISTS (SELECT 1 FROM dbo.StocklineAssetDepreciationHistory X WITH (NOLOCK)
					                       WHERE X.[StockLineId] = STK.[StockLineId] AND X.[AccountingCalendarId] = @AccountingCalendarId AND X.[IsDeleted] = 0)
					          THEN 1 ELSE 0 END AS BIT)					AS [IsRunForPeriod],
					ISNULL(STK.[AssetTotalCost], 0)							AS [DepreciableAmount],
					ISNULL(STK.[AssetTotalCost], 0) - ISNULL(LH.[AccumulatedDepr], 0) AS [Remaining],
					-- the amount the next run depreciates : usage hours of the period x depreciation per hour (limited to the cost still to depreciate)
					CAST(CASE WHEN ISNULL(STK.[AssetTotalCost], 0) - ISNULL(LH.[AccumulatedDepr], 0) <= 0 THEN 0
					          WHEN ROUND((CASE WHEN ISNULL(U.[UsageToDate], 0) - ISNULL(PU.[BookedHours], 0) > 0 THEN ISNULL(U.[UsageToDate], 0) - ISNULL(PU.[BookedHours], 0) ELSE 0 END) * D.[DepreciationPerHour], 2)
					               > ISNULL(STK.[AssetTotalCost], 0) - ISNULL(LH.[AccumulatedDepr], 0) THEN ISNULL(STK.[AssetTotalCost], 0) - ISNULL(LH.[AccumulatedDepr], 0)
					          ELSE ROUND((CASE WHEN ISNULL(U.[UsageToDate], 0) - ISNULL(PU.[BookedHours], 0) > 0 THEN ISNULL(U.[UsageToDate], 0) - ISNULL(PU.[BookedHours], 0) ELSE 0 END) * D.[DepreciationPerHour], 2) END AS DECIMAL(18, 6)) AS [DepreciationAmount]
				FROM dbo.Stockline STK WITH (NOLOCK)
					LEFT JOIN dbo.ItemMaster IM WITH (NOLOCK) ON IM.[ItemMasterId] = STK.[ItemMasterId]
					LEFT JOIN dbo.AssetStatus AST WITH (NOLOCK) ON AST.[AssetStatusId] = STK.[AssetStatusId]
					LEFT JOIN dbo.LegalEntity LE WITH (NOLOCK) ON LE.[LegalEntityId] = STK.[LegalEntityId]
					CROSS APPLY (
						SELECT CAST(ISNULL(STK.[AssetLife], 0) AS DECIMAL(18, 2)) AS [LeaseDurationHrs], -- Asset Life (Mths) of the stockline
						       CAST(CASE WHEN ISNULL(STK.[AssetLife], 0) > 0 THEN ISNULL(STK.[AssetTotalCost], 0) / STK.[AssetLife] ELSE 0 END AS DECIMAL(18, 6)) AS [DepreciationPerHour]
					) D
					OUTER APPLY (
						SELECT SUM(ISNULL(UH.[TSNHours], 0) + ISNULL(UH.[TSNMinutes], 0) / 60.0) AS [UsageToDate]
						FROM dbo.LeaseStockline LS WITH (NOLOCK)
							INNER JOIN dbo.LeaseStocklineUsageHistory UH WITH (NOLOCK) ON UH.[LeaseStocklineId] = LS.[LeaseStocklineId]
						WHERE LS.[StockLineId] = STK.[StockLineId] AND UH.[UsageType] = 'T' AND UH.[IsDeleted] = 0 AND UH.[IsActive] = 1
						  AND (@PeriodTo IS NULL OR COALESCE(UH.[ToDate], UH.[EntryDate]) <= @PeriodTo)
					) U
					OUTER APPLY (
						SELECT SUM(ISNULL(B.[UsageHours], 0)) AS [BookedHours]
						FROM dbo.StocklineAssetDepreciationHistory B WITH (NOLOCK)
						WHERE B.[StockLineId] = STK.[StockLineId] AND B.[IsDeleted] = 0
					) PU
					OUTER APPLY (
						SELECT TOP 1 H.[AccumulatedDepr], H.[NetBookValue], H.[DepreciationAmount], H.[LastDeprRunPeriod]
						FROM dbo.StocklineAssetDepreciationHistory H WITH (NOLOCK)
						WHERE H.[StockLineId] = STK.[StockLineId] AND H.[IsDeleted] = 0
						ORDER BY H.[StocklineAssetDepreciationHistoryId] DESC
					) LH
					OUTER APPLY (
						SELECT COUNT(*) AS [NumOfDeprPeriod],
						       STUFF((SELECT ',' + CAST(Y.[AccountingCalendarId] AS VARCHAR(20))
						              FROM dbo.StocklineAssetDepreciationHistory Y WITH (NOLOCK)
						              WHERE Y.[StockLineId] = STK.[StockLineId] AND Y.[IsDeleted] = 0 AND Y.[AccountingCalendarId] IS NOT NULL
						              FOR XML PATH('')), 1, 1, '') AS [AccountingCalendarIds]
						FROM dbo.StocklineAssetDepreciationHistory Z WITH (NOLOCK)
						WHERE Z.[StockLineId] = STK.[StockLineId] AND Z.[IsDeleted] = 0
					) HC
				WHERE STK.[MasterCompanyId] = @MasterCompanyId
					AND ISNULL(STK.[isDeleted], 0) = 0
					AND ISNULL(STK.[IsAsset], 0) = 1
					AND ISNULL(STK.[IsLease], 0) = 1
					AND ISNULL(STK.[AssetIsDepreciable], 0) = 1
					AND STK.[ConvertedToStocklineId] IS NULL
					AND (ISNULL(@LegalEntityIds, '') = '' OR STK.[LegalEntityId] IN (SELECT CAST(LTRIM(RTRIM(value)) AS BIGINT) FROM STRING_SPLIT(@LegalEntityIds, ',') WHERE LTRIM(RTRIM(value)) <> ''))
			) Base
		) Calc
		WHERE (@Filter IS NULL
			OR Calc.[StockLineNumber] LIKE '%' + @Filter + '%' OR Calc.[SerialNumber] LIKE '%' + @Filter + '%' OR Calc.[PartNumber] LIKE '%' + @Filter + '%'
			OR Calc.[AssetName] LIKE '%' + @Filter + '%' OR Calc.[AssetInventoryNumber] LIKE '%' + @Filter + '%' OR Calc.[LegalEntityName] LIKE '%' + @Filter + '%');

		SELECT
			R.[StockLineId], R.[StockLineNumber], R.[SerialNumber], R.[PartNumber], R.[PartDescription], R.[AssetName], R.[AssetInventoryNumber],
			R.[AssetStatusId], R.[AssetStatus], R.[LegalEntityId], R.[LegalEntityName], R.[ManagementStructureId], R.[Currency],
			R.[InstalledCost], R.[DepreciableLife], R.[DepreciationMethod], R.[DepreciationFrequency], R.[DepreciationStartDate],
			R.[LeaseDurationHrs], R.[DepreciationPerHour], R.[UsageHoursToDate], R.[BookedHours], R.[PeriodUsageHours],
			CAST(CASE WHEN R.[LeaseDurationHrs] > 0 THEN R.[LeaseDurationHrs] - R.[BookedHours] END AS DECIMAL(18, 2)) AS [LeaseHoursRemaining],
			R.[DepreciableAmount], R.[AccumulatedDepr], R.[NetBookValue], R.[LastDepreciationAmount], R.[LastDeprRunPeriod], R.[NumOfDeprPeriod],
			R.[AccountingCalendarIds], R.[DepreciationAmount],
			R.[IsRunForPeriod], R.[IsSelectable], R.[NotSelectableReason],
			@AccountingCalendarId AS [AccountingCalendarId], @PeriodName AS [PeriodName],
			COUNT(*) OVER () AS [TotalRecords]
		FROM #DepreciableRows R
		ORDER BY
			CASE WHEN @SortColumn = 'stockLineNumber' AND @SortOrder = 'ASC' THEN R.[StockLineNumber] END ASC,
			CASE WHEN @SortColumn = 'stockLineNumber' AND @SortOrder = 'DESC' THEN R.[StockLineNumber] END DESC,
			CASE WHEN @SortColumn = 'partNumber' AND @SortOrder = 'ASC' THEN R.[PartNumber] END ASC,
			CASE WHEN @SortColumn = 'partNumber' AND @SortOrder = 'DESC' THEN R.[PartNumber] END DESC,
			CASE WHEN @SortColumn = 'assetName' AND @SortOrder = 'ASC' THEN R.[AssetName] END ASC,
			CASE WHEN @SortColumn = 'assetName' AND @SortOrder = 'DESC' THEN R.[AssetName] END DESC,
			CASE WHEN @SortColumn = 'legalEntityName' AND @SortOrder = 'ASC' THEN R.[LegalEntityName] END ASC,
			CASE WHEN @SortColumn = 'legalEntityName' AND @SortOrder = 'DESC' THEN R.[LegalEntityName] END DESC,
			CASE WHEN @SortColumn = 'installedCost' AND @SortOrder = 'ASC' THEN R.[InstalledCost] END ASC,
			CASE WHEN @SortColumn = 'installedCost' AND @SortOrder = 'DESC' THEN R.[InstalledCost] END DESC,
			CASE WHEN @SortColumn = 'netBookValue' AND @SortOrder = 'ASC' THEN R.[NetBookValue] END ASC,
			CASE WHEN @SortColumn = 'netBookValue' AND @SortOrder = 'DESC' THEN R.[NetBookValue] END DESC,
			R.[StockLineId] ASC
		OFFSET @Skip ROWS FETCH NEXT @Take ROWS ONLY;
	END TRY
	BEGIN CATCH
		DECLARE @ErrorLogID INT, @DatabaseName VARCHAR(100) = DB_NAME(),
		        @AdhocComments VARCHAR(150) = 'USP_GetStocklineAssetDepreciableList',
		        @ProcedureParameters VARCHAR(3000) = '@MasterCompanyId = ''' + CAST(ISNULL(@MasterCompanyId, '') AS VARCHAR(100)) + ''', @AccountingCalendarId = ''' + CAST(ISNULL(@AccountingCalendarId, '') AS VARCHAR(100)),
		        @ApplicationName VARCHAR(100) = 'PAS';
		EXEC spLogException @DatabaseName = @DatabaseName, @AdhocComments = @AdhocComments, @ProcedureParameters = @ProcedureParameters,
		     @ApplicationName = @ApplicationName, @ErrorLogID = @ErrorLogID OUTPUT;
		RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID);
		RETURN (1);
	END CATCH
END
