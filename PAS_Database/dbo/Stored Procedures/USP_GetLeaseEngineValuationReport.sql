/*************************************************************
 ** File:   [USP_GetLeaseEngineValuationReport]
 ** Description: Engine Valuation report of one lease part (engine) - read only.
 **              Result set 1 = the engine : Engine P/N (LeaseStockline.PN), Engine S/N (LeaseStockline.SN), Engine Model and Unit Sales Price (Stockline),
 **              Total Time / Total Cycles (TSN / CSN) and Time / Cycles since overhaul (TSO / CSO) = latest StocklineTimeCycleHistory row of the engine stockline.
 **              Result set 2 = the sub components attached to the engine stockline (Stockline.SubComponentParentStocklineId) : P/N, S/N, Unit Cost
 **              and their own TSN / TSO / CSN / CSO (latest StocklineTimeCycleHistory row).
 **              The report values (price per, remaining, Retail / Wholesale) are calculated by the API (EngineValuationCalculator).
 ** Purpose: Lease Entry > General Info > Actions > Engine Valuation
 ** Change History
 **************************************************************
 ** PR   Date			Author				Change Description
 ** -----------------------------------------------------------
    1    20/11/2026		Kishor Makwana		[PN-18606] - Created

-- EXEC [dbo].[USP_GetLeaseEngineValuationReport] @LeaseStocklineId = 1, @MasterCompanyId = 1
************************************************************************/
CREATE   PROCEDURE [dbo].[USP_GetLeaseEngineValuationReport]
	@LeaseStocklineId BIGINT,
	@MasterCompanyId INT
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;

	BEGIN TRY
		DECLARE @StockLineId BIGINT = (SELECT TOP 1 LS.[StockLineId] FROM [dbo].[LeaseStockline] LS WITH (NOLOCK)
			WHERE LS.[LeaseStocklineId] = @LeaseStocklineId AND LS.[MasterCompanyId] = @MasterCompanyId AND ISNULL(LS.[IsDeleted], 0) = 0);

		-- 1. the engine
		SELECT
			LS.[LeaseStocklineId]							AS [LeaseStocklineId],
			LS.[LeaseHeaderId]								AS [LeaseHeaderId],
			LS.[StockLineId]								AS [StockLineId],
			LS.[PN]											AS [EnginePartNumber],
			LS.[PNDescription]								AS [PartDescription],
			STK.[EngineSerialNumber]							AS [EngineSerialNumber],
			STK.[PartNumber]								AS [StocklinePartNumber],
			STK.[SerialNumber]								AS [StocklineSerialNumber],
			STK.[EngineModel]								AS [EngineModel],
			CAST(ISNULL(STK.[UnitCost], 0) AS DECIMAL(18, 6))	AS [UnitCost],
			TCH.[TotalTSN]									AS [TotalTSN],
			TCH.[TotalTSNMM]								AS [TotalTSNMM],
			TCH.[TotalTSO]									AS [TotalTSO],
			TCH.[TotalTSOMM]								AS [TotalTSOMM],
			TCH.[TotalCSN]									AS [TotalCSN],
			TCH.[TotalCSO]									AS [TotalCSO]
		FROM [dbo].[LeaseStockline] LS WITH (NOLOCK)
			LEFT JOIN [dbo].[Stockline] STK WITH (NOLOCK) ON STK.[StockLineId] = LS.[StockLineId]
			OUTER APPLY (
				SELECT TOP 1 H.[TotalTSN], H.[TotalTSNMM], H.[TotalTSO], H.[TotalTSOMM], H.[TotalCSN], H.[TotalCSO]
				FROM [dbo].[StocklineTimeCycleHistory] H WITH (NOLOCK)
				WHERE H.[StocklineId] = LS.[StockLineId] AND ISNULL(H.[IsDeleted], 0) = 0
				ORDER BY H.[StocklineTimeCycleHistoryId] DESC
			) TCH
		WHERE LS.[LeaseStocklineId] = @LeaseStocklineId AND LS.[MasterCompanyId] = @MasterCompanyId AND ISNULL(LS.[IsDeleted], 0) = 0;

		-- 2. the sub components of the engine
		SELECT
			SUBSL.[StockLineId]								AS [StockLineId],
			SUBSL.[PartNumber]								AS [PartNumber],
			SUBSL.[SerialNumber]							AS [SerialNumber],
			SUBSL.[PNDescription]							AS [PartDescription],
			CAST(ISNULL(SUBSL.[UnitCost], 0) AS DECIMAL(18, 6))	AS [UnitCost],
			TCH.[TotalTSN]									AS [TotalTSN],
			TCH.[TotalTSNMM]								AS [TotalTSNMM],
			TCH.[TotalTSO]									AS [TotalTSO],
			TCH.[TotalTSOMM]								AS [TotalTSOMM],
			TCH.[TotalCSN]									AS [TotalCSN],
			TCH.[TotalCSO]									AS [TotalCSO]
		FROM [dbo].[Stockline] SUBSL WITH (NOLOCK)
			OUTER APPLY (
				SELECT TOP 1 H.[TotalTSN], H.[TotalTSNMM], H.[TotalTSO], H.[TotalTSOMM], H.[TotalCSN], H.[TotalCSO]
				FROM [dbo].[StocklineTimeCycleHistory] H WITH (NOLOCK)
				WHERE H.[StocklineId] = SUBSL.[StockLineId] AND ISNULL(H.[IsDeleted], 0) = 0
				ORDER BY H.[StocklineTimeCycleHistoryId] DESC
			) TCH
		WHERE @StockLineId IS NOT NULL
			AND SUBSL.[SubComponentParentStocklineId] = @StockLineId
			AND ISNULL(SUBSL.[IsSubComponent], 0) = 1
			AND ISNULL(SUBSL.[isDeleted], 0) = 0
		ORDER BY SUBSL.[StockLineId];
	END TRY
	BEGIN CATCH
		DECLARE @ErrorLogID INT, @DatabaseName VARCHAR(100) = DB_NAME()
-------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
			, @AdhocComments VARCHAR(150) = 'USP_GetLeaseEngineValuationReport'
			, @ProcedureParameters VARCHAR(3000) = '@LeaseStocklineId = ' + ISNULL(CAST(@LeaseStocklineId AS VARCHAR(20)), '') + ', @MasterCompanyId = ' + ISNULL(CAST(@MasterCompanyId AS VARCHAR(10)), '')
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