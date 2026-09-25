
/***************************************************************  
 ** File:  [USP_GetLeaseShippingChildList]            
 ** Author:   Moin Bloch
 ** Description: Get Lease Shipping child list - pending and shipped pick ticket lines for a stock line
 ** Date:  25-Sep-2026
 ** Change History             
 *******************************************************************************************             
 ** PR   Date				Author  				Change Description              
 ** --   --------			-------				--------------------------------            
    1    21-Sep-2026		Moin Bloch			Created
	
*******************************************************************************************/
CREATE   PROCEDURE [dbo].[USP_GetLeaseShippingChildList]
	@LeaseHeaderId BIGINT,
	@LeaseStocklineId BIGINT
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;

	BEGIN TRY

		;WITH ShippedTotal AS
		(
			SELECT LSI.[LeasePickTicketId], SUM(ISNULL(LSI.[QtyShipped], 0)) AS QtyShipped
			FROM [dbo].[LeaseShippingItem] LSI WITH (NOLOCK)
			INNER JOIN [dbo].[LeaseShipping] LS WITH (NOLOCK) ON LS.[LeaseShippingId] = LSI.[LeaseShippingId]
			WHERE LS.[LeaseHeaderId] = @LeaseHeaderId AND LSI.[IsDeleted] = 0 AND LS.[IsDeleted] = 0
			GROUP BY LSI.[LeasePickTicketId]
		)
		-- Part A: shipment lines already recorded against this stockline's pick ticket(s).
		SELECT
			LS.[LeaseShippingId],
			LSI.[LeaseShippingItemId],
			LS.[LeaseShippingNum] AS LeaseShippingNumber,
			LPT.[LeaseHeaderId],
			LPT.[LeaseStocklineId],
			LPT.[LeasePickTicketId],
			LPT.[LeasePickTicketNumber],
			LS.[ShipDate],
			ISNULL(SV.[Name], '')        AS ShipViaName,
			ISNULL(LS.[TrackingNum], '') AS TrackingNum,
			ISNULL(LS.[AirwayBill], '')  AS AirwayBill,
			ISNULL(LS.[ShipToName], '')  AS ShipToName,
			ISNULL(SS.[Status], '')      AS [Status],
			ISNULL(LSL.[PN], '')            AS PartNumber,
			ISNULL(LSL.[PNDescription], '') AS PartDescription,
			ISNULL(LSL.[SN], '')            AS SerialNumber,
			ISNULL(LSL.[StocklineNumber], '') AS StockLineNumber,
			CAST(ISNULL(LPT.[QtyPicked], 0) AS DECIMAL(18, 6))  AS QtyPicked,
			CAST(ISNULL(LSI.[QtyShipped], 0) AS DECIMAL(18, 6)) AS QtyShipped,
			CAST(0 AS DECIMAL(18, 6)) AS QtyToShip,
			LS.[MasterCompanyId],
			LCI.[CustomsValue],
			LCI.[CommodityCode]
		FROM [dbo].[LeaseShippingItem] LSI WITH (NOLOCK)
		INNER JOIN [dbo].[LeaseShipping] LS WITH (NOLOCK)    ON LS.[LeaseShippingId] = LSI.[LeaseShippingId]
		INNER JOIN [dbo].[LeasePickTicket] LPT WITH (NOLOCK) ON LPT.[LeasePickTicketId] = LSI.[LeasePickTicketId]
		 LEFT JOIN [dbo].[LeaseStockline] LSL WITH (NOLOCK) ON LSL.[LeaseStocklineId] = LPT.[LeaseStocklineId]
		 LEFT JOIN [dbo].[ShippingVia] SV WITH (NOLOCK)     ON SV.[ShippingViaId] = LS.[ShipViaId]
		 LEFT JOIN [dbo].[ShippingStatus] SS WITH (NOLOCK)  ON SS.[ShippingStatusId] = LS.[LeaseShippingStatusId]
		 LEFT JOIN [dbo].[LeaseCustomsInfo] LCI WITH (NOLOCK) ON LCI.[LeaseShippingId] = LS.[LeaseShippingId]
		WHERE LS.[LeaseHeaderId]      = @LeaseHeaderId
		  AND LPT.[LeaseStocklineId]  = @LeaseStocklineId
		  AND LSI.[IsDeleted] = 0 AND LS.[IsDeleted] = 0

		UNION ALL

		-- Part B: one pending row per Pick Ticket line that still has Qty left to ship - blank
		-- ship-date/shipping-num/AWB until an actual shipment exists, mirroring
		-- app-work-order-shipping's sp_GetWOShippingChildList (LEFT JOIN from WOPickTicket).
		SELECT
			0 AS LeaseShippingId,
			0 AS LeaseShippingItemId,
			'' AS LeaseShippingNumber,
			LPT.[LeaseHeaderId],
			LPT.[LeaseStocklineId],
			LPT.[LeasePickTicketId],
			LPT.[LeasePickTicketNumber],
			NULL AS ShipDate,
			'' AS ShipViaName,
			'' AS TrackingNum,
			'' AS AirwayBill,
			'' AS ShipToName,
			'' AS [Status],
			ISNULL(LSL.[PN], '')            AS PartNumber,
			ISNULL(LSL.[PNDescription], '') AS PartDescription,
			ISNULL(LSL.[SN], '')            AS SerialNumber,
			ISNULL(LSL.[StocklineNumber], '') AS StockLineNumber,
			CAST(ISNULL(LPT.[QtyPicked], 0) AS DECIMAL(18, 6)) AS QtyPicked,
			CAST(0 AS DECIMAL(18, 6)) AS QtyShipped,
			CAST((ISNULL(LPT.[QtyPicked], 0) - ISNULL(ST.QtyShipped, 0)) AS DECIMAL(18, 6)) AS QtyToShip,
			LPT.[MasterCompanyId],
			CAST(NULL AS DECIMAL(20, 2)) AS CustomsValue,
			CAST(NULL AS VARCHAR(100)) AS CommodityCode
		FROM [dbo].[LeasePickTicket] LPT WITH (NOLOCK)
		 LEFT JOIN [dbo].[LeaseStockline] LSL WITH (NOLOCK) ON LSL.[LeaseStocklineId] = LPT.[LeaseStocklineId]
		 LEFT JOIN ShippedTotal ST ON ST.[LeasePickTicketId] = LPT.[LeasePickTicketId]
		WHERE LPT.[LeaseHeaderId]     = @LeaseHeaderId
		  AND LPT.[LeaseStocklineId]  = @LeaseStocklineId
		  AND LPT.[IsDeleted] = 0
		  AND (ISNULL(LPT.[QtyPicked], 0) - ISNULL(ST.QtyShipped, 0)) > 0

		ORDER BY 1, 8 DESC;

	END TRY
	BEGIN CATCH
		DECLARE @ErrorLogID INT,
			@DatabaseName VARCHAR(100) = DB_NAME(),
			@AdhocComments VARCHAR(150) = '[USP_GetLeaseShippingChildList]',
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