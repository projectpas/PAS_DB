/*************************************************************
 ** File:   [USP_GetLeaseStocklineUsageHistoryByLeaseStocklineId]
 ** Description: Returns every past Time/Cycle usage entry for a LeaseStockline.
 **              Each history row already IS the "Periodic" amount (the raw
 **              incremental Hours/Minutes entered that time - see
 **              USP_SaveLeaseStocklineUsage). "Cumulative" is a running SUM of
 **              every increment up to and including that row (in total minutes,
 **              carry-aware once split back into Hours/Minutes client-side),
 **              via a running-total window function ordered chronologically.
 **
 **************************************************************
 ** Change History
 **************************************************************
 ** PR   Date           Author                  Change Description
 ** --   --------       -------                 --------------------------------
    1    15/09/2026     Amit Ghediya            Created
    2    15/09/2026     Amit Ghediya            Reworked for the "increment, not
                                                 absolute reading" model: replaced
                                                 the LAG-based delta (which no
                                                 longer means anything once history
                                                 rows are raw increments) with a
                                                 running SUM() for the Cumulative
                                                 total; the row's own TSNHours/
                                                 TSNMinutes/CSNHours/CSNMinutes are
                                                 now the Periodic value directly

exec USP_GetLeaseStocklineUsageHistoryByLeaseStocklineId @LeaseStocklineId=1
************************************************************************/
CREATE      PROCEDURE [dbo].[USP_GetLeaseStocklineUsageHistoryByLeaseStocklineId]
	@LeaseStocklineId BIGINT
AS
BEGIN
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	BEGIN TRY

		SELECT LeaseStocklineUsageHistoryId, EntryDate, TSNHours, TSNMinutes, CSNHours, CSNMinutes,
			Notes, CreatedBy, CreatedDate,
			SUM(ISNULL(TSNHours,0) * 60 + ISNULL(TSNMinutes,0))
				OVER (ORDER BY EntryDate, LeaseStocklineUsageHistoryId ROWS UNBOUNDED PRECEDING) AS TSNCumulativeMinutes,
			SUM(ISNULL(CSNHours,0) * 60 + ISNULL(CSNMinutes,0))
				OVER (ORDER BY EntryDate, LeaseStocklineUsageHistoryId ROWS UNBOUNDED PRECEDING) AS CSNCumulativeMinutes
		FROM [dbo].[LeaseStocklineUsageHistory] WITH (NOLOCK)
		WHERE LeaseStocklineId = @LeaseStocklineId AND IsDeleted = 0
		ORDER BY EntryDate, LeaseStocklineUsageHistoryId;

	END TRY
	BEGIN CATCH
		DECLARE @ErrorLogID int,
            @DatabaseName varchar(100) = DB_NAME()
            ,@AdhocComments varchar(150) = '[USP_GetLeaseStocklineUsageHistoryByLeaseStocklineId]',
            @ProcedureParameters varchar(3000) = '@LeaseStocklineId = ''' + CAST(ISNULL(@LeaseStocklineId, 0) AS varchar(100)),
            @ApplicationName varchar(100) = 'PAS'
    EXEC spLogException @DatabaseName = @DatabaseName,
                        @AdhocComments = @AdhocComments,
                        @ProcedureParameters = @ProcedureParameters,
                        @ApplicationName = @ApplicationName,
                        @ErrorLogID = @ErrorLogID OUTPUT;
    RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)
    RETURN (1);
	END CATCH
END
