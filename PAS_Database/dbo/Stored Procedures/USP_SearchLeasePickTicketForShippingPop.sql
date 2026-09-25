CREATE   PROCEDURE [dbo].[USP_SearchLeasePickTicketForShippingPop]
	@LeaseHeaderId BIGINT,
	@LeaseStocklineId BIGINT = NULL
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;

	BEGIN TRY

		;WITH Shipped AS
		(
			SELECT LSI.[LeasePickTicketId],
			       SUM(ISNULL(LSI.[QtyShipped], 0)) AS QtyShipped
			FROM [dbo].[LeaseShippingItem] LSI WITH (NOLOCK)
			INNER JOIN [dbo].[LeaseShipping] LS WITH (NOLOCK) ON LS.[LeaseShippingId] = LSI.[LeaseShippingId]
			WHERE LS.[LeaseHeaderId] = @LeaseHeaderId
			  AND LSI.[IsDeleted]    = 0
			  AND LS.[IsDeleted]     = 0
			GROUP BY LSI.[LeasePickTicketId]
		)
		SELECT
			LPT.[LeasePickTicketId],
			LPT.[LeasePickTicketNumber],
			LPT.[LeaseHeaderId],
			LPT.[LeaseStocklineId],
			LPT.[StockLineId],
			LSL.[PN]             AS PartNumber,
			LSL.[PNDescription]  AS PartDescription,
			ISNULL(SL.[SerialNumber], '')    AS SerialNumber,
			ISNULL(SL.[StockLineNumber], '') AS StockLineNumber,
			CAST(ISNULL(LPT.[QtyPicked], 0) AS DECIMAL(18, 6))  AS QtyPicked,
			CAST(ISNULL(SH.QtyShipped, 0) AS DECIMAL(18, 6))    AS QtyShipped,
			CAST(CASE WHEN (ISNULL(LPT.[QtyPicked], 0) - ISNULL(SH.QtyShipped, 0)) < 0
					  THEN 0
					  ELSE (ISNULL(LPT.[QtyPicked], 0) - ISNULL(SH.QtyShipped, 0))
				 END AS DECIMAL(18, 6)) AS QtyRemaining,
			LPT.[MasterCompanyId]
		FROM [dbo].[LeasePickTicket] LPT WITH (NOLOCK)
		 LEFT JOIN [dbo].[LeaseStockline] LSL WITH (NOLOCK) ON LSL.[LeaseStocklineId] = LPT.[LeaseStocklineId]
		 LEFT JOIN [dbo].[Stockline] SL WITH (NOLOCK)       ON SL.[StockLineId] = LPT.[StockLineId]
		 LEFT JOIN Shipped SH                                ON SH.[LeasePickTicketId] = LPT.[LeasePickTicketId]
		WHERE LPT.[LeaseHeaderId]    = @LeaseHeaderId
		  AND LPT.[IsDeleted]        = 0
		  AND (@LeaseStocklineId IS NULL OR LPT.[LeaseStocklineId] = @LeaseStocklineId)
		  AND (ISNULL(LPT.[QtyPicked], 0) - ISNULL(SH.QtyShipped, 0)) > 0
		ORDER BY LPT.[LeasePickTicketId];

	END TRY
	BEGIN CATCH
		DECLARE @ErrorLogID INT,
			@DatabaseName VARCHAR(100) = DB_NAME(),
			@AdhocComments VARCHAR(150) = '[USP_SearchLeasePickTicketForShippingPop]',
			@ProcedureParameters VARCHAR(3000) = '@LeaseHeaderId = ''' + CAST(ISNULL(@LeaseHeaderId, 0) AS VARCHAR(100))
											   + ''', @LeaseStocklineId = ''' + CAST(ISNULL(@LeaseStocklineId, 0) AS VARCHAR(100)),
			@ApplicationName VARCHAR(100) = 'PAS'
		EXEC spLogException @DatabaseName = @DatabaseName,
							@AdhocComments = @AdhocComments,
							@ProcedureParameters = @ProcedureParameters,
							@ApplicationName = @ApplicationName,
							@ErrorLogID = @ErrorLogID OUTPUT;
		RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)
		RETURN (1);
	END CATCH
END