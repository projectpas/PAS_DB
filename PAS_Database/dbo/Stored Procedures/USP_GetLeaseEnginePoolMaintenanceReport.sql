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

-- EXEC [dbo].[USP_GetLeaseEnginePoolMaintenanceReport] @MasterCompanyId = 1, @IsActive = 1
************************************************************************/
CREATE PROCEDURE [dbo].[USP_GetLeaseEnginePoolMaintenanceReport]
	@MasterCompanyId INT,
	@IsActive BIT = 1,
	@ItemGroup VARCHAR(256) = NULL
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;

	BEGIN TRY
		IF OBJECT_ID('tempdb..#EnginePoolRows') IS NOT NULL DROP TABLE #EnginePoolRows;

		SELECT
			STK.[StockLineId] AS [StockLineId],
			LH.[LeaseNumber] AS [LeaseNumber],
			STK.[PartNumber] AS [EngineSn],
			LOC.[Name] AS [Location],
			CAST(NULL AS VARCHAR(200)) AS [Disposition],
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
			STK.[isActive] AS [IsActive],
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
			AND ISNULL(STK.[isActive], 0) = @IsActive
			AND (@ItemGroup IS NULL OR STK.[itemGroup] = @ItemGroup);

		-- PN View only : one row per part (engine) - its latest lease line
		SELECT
			R.[StockLineId],
			R.[LeaseNumber],
			R.[EngineSn],
			R.[Location],
			R.[Disposition],
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
		FROM #EnginePoolRows R
		ORDER BY R.[EngineSn], R.[StockLineId];

		DROP TABLE #EnginePoolRows;
	END TRY
	BEGIN CATCH
		DECLARE @ErrorLogID INT, @DatabaseName VARCHAR(100) = DB_NAME()

-------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
			, @AdhocComments VARCHAR(150) = 'USP_GetLeaseEnginePoolMaintenanceReport'
			, @ProcedureParameters VARCHAR(3000) = '@MasterCompanyId = ' + ISNULL(CAST(@MasterCompanyId AS VARCHAR(10)), '') + ', @IsActive = ' + ISNULL(CAST(@IsActive AS VARCHAR(1)), '') + ', @ItemGroup = ' + ISNULL(@ItemGroup, '')
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