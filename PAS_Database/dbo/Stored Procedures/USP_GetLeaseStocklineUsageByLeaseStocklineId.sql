/*************************************************************
 ** File:   [USP_GetLeaseStocklineUsageByLeaseStocklineId]
 ** Description: Returns the current/latest Time (TSN) and Cycle (CSN) usage
 **              snapshot for a single LeaseStockline. Returns zero rows if
 **              usage has never been recorded for this stockline yet.
 **
 **************************************************************
 ** Change History
 **************************************************************
 ** PR   Date           Author                  Change Description
 ** --   --------       -------                 --------------------------------
    1    15/09/2026     Amit Ghediya            Created

exec USP_GetLeaseStocklineUsageByLeaseStocklineId @LeaseStocklineId=1
************************************************************************/
CREATE      PROCEDURE [dbo].[USP_GetLeaseStocklineUsageByLeaseStocklineId]
	@LeaseStocklineId BIGINT
AS
BEGIN
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	BEGIN TRY

		SELECT LeaseStocklineId, CurrentTSNHours, CurrentTSNMinutes, CurrentTSNDate,
			CurrentCSNHours, CurrentCSNMinutes, CurrentCSNDate, LatestNotes, UpdatedBy, UpdatedDate
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
