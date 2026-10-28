/*************************************************************
 ** File:   [USP_GetLeaseReportFilters]
 ** Description: Lease -> Reports tab: filter data. One row per PN of the lease (for the PN dropdown); every row also carries the default
 **              From / To Invoice Date (From = first lease part start date, or the lease created date; To = today).
 ** PARAMETERS: @LeaseHeaderId BIGINT
 **************************************************************
 ** Change History
 **************************************************************
 ** PR   Date           Author                  Change Description
 ** --   --------       -------                 --------------------------------
    1    27/10/2026     Kishor Makwana          [Lease Reports] Created

EXEC USP_GetLeaseReportFilters @LeaseHeaderId = 22
************************************************************************/
CREATE   PROCEDURE [dbo].[USP_GetLeaseReportFilters]
	@LeaseHeaderId BIGINT
AS
BEGIN
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	BEGIN TRY

		DECLARE @FromDate DATE, @ToDate DATE = CAST(GETUTCDATE() AS DATE);

		SELECT @FromDate = MIN(CAST(LSL.[StartDate] AS DATE))
		FROM [dbo].[LeaseStockline] LSL WITH (NOLOCK)
		WHERE LSL.[LeaseHeaderId] = @LeaseHeaderId AND LSL.[IsDeleted] = 0;

		IF (@FromDate IS NULL)
			SELECT @FromDate = CAST(LH.[CreatedDate] AS DATE) FROM [dbo].[LeaseHeader] LH WITH (NOLOCK) WHERE LH.[LeaseHeaderId] = @LeaseHeaderId;

		SELECT LSL.[PN] AS PartNumber, @FromDate AS DefaultFromDate, @ToDate AS DefaultToDate
		FROM [dbo].[LeaseStockline] LSL WITH (NOLOCK)
		WHERE LSL.[LeaseHeaderId] = @LeaseHeaderId AND LSL.[IsDeleted] = 0 AND LSL.[PN] IS NOT NULL
		GROUP BY LSL.[PN]
		ORDER BY LSL.[PN];

	END TRY
	BEGIN CATCH
		DECLARE @ErrorLogID INT, @DatabaseName VARCHAR(100) = DB_NAME()
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
			, @AdhocComments VARCHAR(150) = 'USP_GetLeaseReportFilters'
			, @ProcedureParameters VARCHAR(3000) = '@LeaseHeaderId = ''' + CAST(ISNULL(@LeaseHeaderId, 0) AS VARCHAR(100)) + ''''
			, @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
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