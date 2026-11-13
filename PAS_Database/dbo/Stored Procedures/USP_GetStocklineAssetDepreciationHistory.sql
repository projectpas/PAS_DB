/*************************************************************
 ** File:   [USP_GetStocklineAssetDepreciationHistory]
 ** Description: Stockline List > Asset > Actions > Asset Depreciation History popup. The depreciation runs of a leased asset stockline
 **              (StocklineAssetDepreciationHistory), oldest first. Columns of the popup : Depreciation Date, Depreciation Period Num, Depreciation Period,
 **              Depreciation Amount, Cumulative Depreciation, Net Book Value, Net Book Value After Depr, Created By, Created Date
 **              (+ Usage Hours and Depreciation per Hr of the usage based depreciation, PN-18535).
 **************************************************************
 ** Change History
 **************************************************************
 ** PR   Date            Author          Change Description
 ** --   --------        -------         --------------------------------
    1    12/November/2026 Kishor Makwana  [PN-18535] Created
 -- EXEC [dbo].[USP_GetStocklineAssetDepreciationHistory] @StockLineId = 1, @MasterCompanyId = 1
**************************************************************/
CREATE PROCEDURE [dbo].[USP_GetStocklineAssetDepreciationHistory]
	@StockLineId     BIGINT,
	@MasterCompanyId INT
AS
BEGIN
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
	BEGIN TRY
		SELECT
			H.[StocklineAssetDepreciationHistoryId],
			H.[StockLineId],
			H.[CreatedDate]											AS [DepreciationDate],
			CAST(ROW_NUMBER() OVER (ORDER BY H.[StocklineAssetDepreciationHistoryId]) AS INT) AS [DepreciationPeriodNum],
			H.[LastDeprRunPeriod]									AS [DepreciationPeriod],
			H.[DepreciationAmount],
			H.[AccumulatedDepr]										AS [CumulativeDepreciation],
			H.[NetBookValue],
			H.[NBVAfterDepreciation]								AS [NetBookValueAfterDepr],
			H.[UsageHours],
			H.[DepreciationPerHour],
			H.[LeaseDurationHrs],
			H.[CreatedBy],
			H.[CreatedDate]
		FROM dbo.StocklineAssetDepreciationHistory H WITH (NOLOCK)
		WHERE H.[StockLineId] = @StockLineId AND H.[MasterCompanyId] = @MasterCompanyId AND H.[IsDeleted] = 0
		ORDER BY H.[StocklineAssetDepreciationHistoryId] ASC;
	END TRY
	BEGIN CATCH
		DECLARE @ErrorLogID INT, @DatabaseName VARCHAR(100) = DB_NAME(),
		        @AdhocComments VARCHAR(150) = 'USP_GetStocklineAssetDepreciationHistory',
		        @ProcedureParameters VARCHAR(3000) = '@StockLineId = ''' + CAST(ISNULL(@StockLineId, '') AS VARCHAR(100)),
		        @ApplicationName VARCHAR(100) = 'PAS';
		EXEC spLogException @DatabaseName = @DatabaseName, @AdhocComments = @AdhocComments, @ProcedureParameters = @ProcedureParameters,
		     @ApplicationName = @ApplicationName, @ErrorLogID = @ErrorLogID OUTPUT;
		RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID);
		RETURN (1);
	END CATCH
END
