
/***************************************************************
 ** File:  [USP_GetLeaseShippingParentList]
 ** Author:   Moin Bloch
 ** Description: Get Lease Shipping parent grid list - one row per Lease Stock Line with picked/shipped/remaining qty
 ** Date:  25-Sep-2026
 ** Change History
 *******************************************************************************************
 ** PR   Date				Author  				Change Description
 ** --   --------			-------				--------------------------------
    1    21-Sep-2026		Moin Bloch			Created

*******************************************************************************************/
CREATE   PROCEDURE [dbo].[USP_GetLeaseShippingParentList]
	@LeaseHeaderId BIGINT
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;

	BEGIN TRY

		;WITH Picked AS
		(
			SELECT LPT.[LeaseStocklineId],
			       SUM(ISNULL(LPT.[QtyPicked], 0)) AS QtyPicked
			FROM [dbo].[LeasePickTicket] LPT WITH (NOLOCK)
			WHERE LPT.[LeaseHeaderId] = @LeaseHeaderId
			  AND LPT.[IsDeleted]     = 0
			GROUP BY LPT.[LeaseStocklineId]
		),
		Shipped AS
		(
			SELECT LSI.[LeaseStocklineId],
			       SUM(ISNULL(LSI.[QtyShipped], 0)) AS QtyShipped
			FROM [dbo].[LeaseShippingItem] LSI WITH (NOLOCK)
			INNER JOIN [dbo].[LeaseShipping] LS WITH (NOLOCK) ON LS.[LeaseShippingId] = LSI.[LeaseShippingId]
			WHERE LS.[LeaseHeaderId] = @LeaseHeaderId
			  AND LSI.[IsDeleted]    = 0
			  AND LS.[IsDeleted]     = 0
			GROUP BY LSI.[LeaseStocklineId]
		)
		SELECT
			LSL.[LeaseStocklineId],
			LSL.[LeaseHeaderId],
			LH.[LeaseNumber],
			ISNULL(CUS.[Name], '')         AS CustomerName,
			ISNULL(CUS.[CustomerCode], '') AS CustomerCode,
			LSL.[PN]                       AS PartNumber,
			LSL.[PNDescription]            AS PartDescription,
			LSL.[SN]                       AS SerialNumber,
			LSL.[StocklineNumber],
			CAST(ISNULL(P.QtyPicked, 0) AS DECIMAL(18, 6))   AS QtyPicked,
			CAST(ISNULL(S.QtyShipped, 0) AS DECIMAL(18, 6))  AS QtyShipped,
			CAST(CASE WHEN (ISNULL(P.QtyPicked, 0) - ISNULL(S.QtyShipped, 0)) < 0
					  THEN 0
					  ELSE (ISNULL(P.QtyPicked, 0) - ISNULL(S.QtyShipped, 0))
				 END AS DECIMAL(18, 6)) AS QtyRemaining,
			CASE WHEN ISNULL(S.QtyShipped, 0) <= 0 THEN 'Open'
				 WHEN ISNULL(S.QtyShipped, 0) >= ISNULL(P.QtyPicked, 0) THEN 'Shipped'
				 ELSE 'Partially Shipped'
			END AS [Status],
			LSL.[MasterCompanyId]
		FROM [dbo].[LeaseStockline] LSL WITH (NOLOCK)
		INNER JOIN [dbo].[LeaseHeader] LH WITH (NOLOCK) ON LH.[LeaseHeaderId] = LSL.[LeaseHeaderId]
		 LEFT JOIN [dbo].[Customer] CUS WITH (NOLOCK)   ON CUS.[CustomerId] = LH.[CustomerId]
		 INNER JOIN Picked P                            ON P.[LeaseStocklineId] = LSL.[LeaseStocklineId]
		 LEFT JOIN Shipped S                            ON S.[LeaseStocklineId] = LSL.[LeaseStocklineId]
		WHERE LSL.[LeaseHeaderId] = @LeaseHeaderId
		  AND LSL.[IsDeleted]     = 0
		  AND ISNULL(P.QtyPicked, 0) > 0
		ORDER BY LSL.[LeaseStocklineId];

	END TRY
	BEGIN CATCH
		DECLARE @ErrorLogID INT,
			@DatabaseName VARCHAR(100) = DB_NAME(),
			@AdhocComments VARCHAR(150) = '[USP_GetLeaseShippingParentList]',
			@ProcedureParameters VARCHAR(3000) = '@LeaseHeaderId = ''' + CAST(ISNULL(@LeaseHeaderId, 0) AS VARCHAR(100)),
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