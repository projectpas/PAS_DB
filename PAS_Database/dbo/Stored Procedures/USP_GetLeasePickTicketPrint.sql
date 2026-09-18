/*************************************************************
 ** File:   [USP_GetLeasePickTicketPrint]
 ** Description: Line rows of the Lease Pick Ticket PDF. Mirrors dbo.GetPickTicketPrint
 **              (Sales Order): every line saved under the SAME pick ticket number prints on
 **              one document, so the proc resolves the number from @LeasePickTicketId and
 **              then returns all of that number's rows.
 **
 **************************************************************
 ** Change History
 **************************************************************
 ** PR   Date           Author                  Change Description
 ** --   --------       -------                 --------------------------------
    1    16/09/2026     Bhargav Saliya          [PN-17931] Created - Leasing Pick Ticket

exec USP_GetLeasePickTicketPrint @LeaseHeaderId=1, @LeasePickTicketId=1
************************************************************************/
CREATE PROCEDURE [dbo].[USP_GetLeasePickTicketPrint]
	@LeaseHeaderId BIGINT,
	@LeasePickTicketId BIGINT
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;

	BEGIN TRY

		DECLARE @PickTicketNo VARCHAR(50);

		SELECT @PickTicketNo = [LeasePickTicketNumber]
		FROM [dbo].[LeasePickTicket] WITH (NOLOCK)
		WHERE [LeasePickTicketId] = @LeasePickTicketId;

		SELECT
			LPT.[LeasePickTicketId],
			LPT.[LeasePickTicketNumber],
			LPT.[CreatedDate]              AS LeasePickTicketDate,
			LPT.[LeaseHeaderId],
			LPT.[LeaseStocklineId],
			LH.[LeaseNumber],
			LSL.[PN]                       AS PartNumber,
			LSL.[PNDescription]            AS PartDescription,
			ISNULL(SL.[StockLineNumber], LSL.[StocklineNumber]) AS StockLineNumber,
			ISNULL(SL.[SerialNumber], LSL.[SN]) AS SerialNumber,
			ISNULL(SL.[ControlNumber], '') AS ControlNumber,
			ISNULL(SL.[IdNumber], '')      AS IdNumber,
			ISNULL(CON.[Description], '')  AS ConditionDescription,
			ISNULL(UOM.[ShortName], '')    AS UOM,
			ISNULL(ST.[Name], '')          AS SiteName,
			ISNULL(WH.[Name], '')          AS WarehouseName,
			ISNULL(LOC.[Name], '')         AS LocationName,
			ISNULL(SH.[Name], '')          AS ShelfName,
			ISNULL(BN.[Name], '')          AS BinName,
			ISNULL(PO.[PurchaseOrderNumber], '') AS PONumber,
			CAST(ISNULL(LSL.[QtyOrder], 0) AS DECIMAL(18, 6))         AS Qty,
			CAST(ISNULL(LPT.[QtyReserved], 0) AS DECIMAL(18, 6))      AS QtyReserved,
			CAST(ISNULL(LPT.[QtyPicked], 0) AS DECIMAL(18, 6))        AS QtyToPick,
			CAST(ISNULL(LPT.[QtyPicked], 0) AS DECIMAL(18, 6))        AS QtyPicked,
			CAST(ISNULL(LPT.[QtyRemaining], 0) AS DECIMAL(18, 6))     AS QtyRemaining,
			CAST(ISNULL(SL.[QuantityOnHand], 0) AS DECIMAL(18, 6))    AS QuantityOnHand,
			CAST(ISNULL(SL.[QuantityAvailable], 0) AS DECIMAL(18, 6)) AS QtyAvailable,
			ISNULL(LSL.[Notes], '')        AS Notes,
			LPT.[MasterCompanyId]
		FROM [dbo].[LeasePickTicket] LPT WITH (NOLOCK)
		INNER JOIN [dbo].[LeaseHeader] LH WITH (NOLOCK)      ON LH.[LeaseHeaderId] = LPT.[LeaseHeaderId]
		INNER JOIN [dbo].[LeaseStockline] LSL WITH (NOLOCK)  ON LSL.[LeaseStocklineId] = LPT.[LeaseStocklineId]
		 LEFT JOIN [dbo].[Stockline] SL WITH (NOLOCK)        ON SL.[StockLineId] = LPT.[StockLineId]
		 LEFT JOIN [dbo].[ItemMaster] IM WITH (NOLOCK)       ON IM.[ItemMasterId] = LSL.[ItemMasterId]
		 LEFT JOIN [dbo].[Condition] CON WITH (NOLOCK)       ON CON.[ConditionId] = LSL.[ConditionId]
		 LEFT JOIN [dbo].[UnitOfMeasure] UOM WITH (NOLOCK)   ON UOM.[UnitOfMeasureId] = IM.[StockUnitOfMeasureId]
		 LEFT JOIN [dbo].[Site] ST WITH (NOLOCK)             ON ST.[SiteId] = SL.[SiteId]
		 LEFT JOIN [dbo].[Warehouse] WH WITH (NOLOCK)        ON WH.[WarehouseId] = SL.[WarehouseId]
		 LEFT JOIN [dbo].[Location] LOC WITH (NOLOCK)        ON LOC.[LocationId] = SL.[LocationId]
		 LEFT JOIN [dbo].[Shelf] SH WITH (NOLOCK)            ON SH.[ShelfId] = SL.[ShelfId]
		 LEFT JOIN [dbo].[Bin] BN WITH (NOLOCK)              ON BN.[BinId] = SL.[BinId]
		 LEFT JOIN [dbo].[PurchaseOrder] PO WITH (NOLOCK)    ON PO.[PurchaseOrderId] = SL.[PurchaseOrderId]
		WHERE LPT.[LeaseHeaderId]        = @LeaseHeaderId
		  AND LPT.[LeasePickTicketNumber] = @PickTicketNo
		  AND LPT.[IsDeleted]            = 0
		ORDER BY LPT.[LeasePickTicketId];

	END TRY
	BEGIN CATCH
		DECLARE @ErrorLogID INT,
			@DatabaseName VARCHAR(100) = DB_NAME(),
			@AdhocComments VARCHAR(150) = '[USP_GetLeasePickTicketPrint]',
			@ProcedureParameters VARCHAR(3000) = '@LeaseHeaderId = ''' + CAST(ISNULL(@LeaseHeaderId, 0) AS VARCHAR(100))
											   + ''', @LeasePickTicketId = ''' + CAST(ISNULL(@LeasePickTicketId, 0) AS VARCHAR(100)),
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
