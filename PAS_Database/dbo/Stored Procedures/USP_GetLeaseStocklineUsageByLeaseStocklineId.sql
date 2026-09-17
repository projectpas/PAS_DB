/*************************************************************
 ** File:   [USP_GetLeaseStocklineUsageByLeaseStocklineId]
 ** Description: Returns the current/latest Time (TSN) and Cycle (CSN) usage
 **              snapshot for a single LeaseStockline - one row holding both
 **              the Time snapshot (Hours/Minutes, its own From/To reporting
 **              period, its own latest note) and the Cycle snapshot (a single
 **              CSN count, its own From/To period, its own latest note) side
 **              by side, since the two are tracked and saved independently.
 **              Returns zero rows if usage has never been recorded for this
 **              stockline yet.
 **
 **************************************************************
 ** Change History
 **************************************************************
 ** PR   Date           Author                  Change Description
 ** --   --------       -------                 --------------------------------
    1    15/09/2026     Amit Ghediya            Created
    2    16/09/2026     Kishor Makwana          [PN-17933] Time and Cycle are now fully independent: added CurrentTSNFromDate/ToDate and CurrentCSNFromDate/ToDate; replaced CurrentCSNHours/CurrentCSNMinutes with a single CurrentCSN; split LatestNotes into LatestTimeNotes/ LatestCycleNotes

exec USP_GetLeaseStocklineUsageByLeaseStocklineId @LeaseStocklineId=1
************************************************************************/
CREATE       PROCEDURE [dbo].[USP_GetLeaseStocklineUsageByLeaseStocklineId]
	@LeaseStocklineId BIGINT
AS
BEGIN
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	BEGIN TRY

		SELECT LeaseStocklineId,
			CurrentTSNHours, CurrentTSNMinutes, CurrentTSNFromDate, CurrentTSNToDate, CurrentTSNDate, LatestTimeNotes,
			CurrentCSN, CurrentCSNFromDate, CurrentCSNToDate, CurrentCSNDate, LatestCycleNotes,
			UpdatedBy, UpdatedDate
		FROM [dbo].[LeaseStocklineUsage] WITH (NOLOCK)
		WHERE LeaseStocklineId = @LeaseStocklineId AND IsDeleted = 0;

	END TRY
	BEGIN CATCH
		DECLARE @ErrorLogID int,
            @DatabaseName varchar(100) = DB_NAME()
            ,@AdhocComments varchar(150) = '[USP_GetLeaseStocklineUsageByLeaseStocklineId]',
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