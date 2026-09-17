/*************************************************************
 ** File:   [USP_GetLeaseStocklineUsageHistoryByLeaseStocklineId]
 ** Description: Returns every past Time and/or Cycle usage entry for a
 **              LeaseStockline, oldest first. TSNHours/TSNMinutes/CSN are
 **              that entry's own periodic reading as entered; Cumulative is
 **              a RUNNING SUM of that type's readings in chronological order
 **              (e.g. 25, 35, 45 entered in that order shows Cumulative
 **              25, 60, 105) - PARTITION BY UsageType so Time and Cycle
 **              accumulate independently. This is purely a reporting/history
 **              total - it is unrelated to LeaseStocklineUsage.CurrentTSN*
 **              CurrentCSN (the "Last Reported" snapshot used for the
 **              must-be-greater-than-last-reading validation in
 **              USP_SaveLeaseStocklineUsage), which stays the latest
 **              absolute reading, not a sum. Pass @UsageType to get only
 **              that type's rows, or leave it NULL to get both.
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
    3    16/09/2026     Kishor Makwana        [PN-17933] Re-added the running SUM() window function per updated requirement - the History display's Cumulative column needs a true running total across all past entries in chronological order (25, 60, 105), for both Time and Cycle. This is independent of the "Current"/"Last Reported" snapshot on LeaseStocklineUsage, which is unaffected and stays the latest absolute reading

exec USP_GetLeaseStocklineUsageHistoryByLeaseStocklineId @LeaseStocklineId=1
exec USP_GetLeaseStocklineUsageHistoryByLeaseStocklineId @LeaseStocklineId=1, @UsageType='T'
************************************************************************/
CREATE       PROCEDURE [dbo].[USP_GetLeaseStocklineUsageHistoryByLeaseStocklineId]
	@LeaseStocklineId BIGINT,
	@UsageType CHAR(1) = NULL
AS
BEGIN
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	BEGIN TRY

		SELECT LeaseStocklineUsageHistoryId, UsageType, EntryDate, FromDate, ToDate, TSNHours, TSNMinutes, CSN,
			Notes, CreatedBy, CreatedDate,
			SUM(ISNULL(TSNHours,0) * 60 + ISNULL(TSNMinutes,0)) OVER (
				PARTITION BY UsageType ORDER BY LeaseStocklineUsageHistoryId
				ROWS UNBOUNDED PRECEDING) AS TSNCumulativeMinutes,
			SUM(ISNULL(CSN,0)) OVER (
				PARTITION BY UsageType ORDER BY LeaseStocklineUsageHistoryId
				ROWS UNBOUNDED PRECEDING) AS CSNCumulative
		FROM [dbo].[LeaseStocklineUsageHistory] WITH (NOLOCK)
		WHERE LeaseStocklineId = @LeaseStocklineId AND IsDeleted = 0
		  AND (@UsageType IS NULL OR UsageType = @UsageType)
		ORDER BY UsageType, LeaseStocklineUsageHistoryId;

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