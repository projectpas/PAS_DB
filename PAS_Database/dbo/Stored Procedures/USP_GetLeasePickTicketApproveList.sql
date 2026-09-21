/*************************************************************
 ** File:   [USP_GetLeasePickTicketApproveList]
 ** Description: Parent grid of the Leasing "Pick Ticket" tab - one row per reserved
 **              Lease Stock Line, with the picked / remaining roll-up taken from
 **              dbo.LeasePickTicket.
 **
 **              Status is derived, not stored:
 **                  Open                 - nothing picked yet
 **                  Partially Fulfilled  - some, but not all, of the reserved qty is picked
 **                  Fulfilled            - the whole reserved qty is picked
 **
 **************************************************************
 ** Change History
 **************************************************************
 ** PR   Date           Author                  Change Description
 ** --   --------       -------                 --------------------------------
    1    16/09/2026     Bhargav Saliya          [PN-17931] Created - Leasing Pick Ticket

exec USP_GetLeasePickTicketApproveList @LeaseHeaderId=1
************************************************************************/
CREATE   PROCEDURE [dbo].[USP_GetLeasePickTicketApproveList]
	@LeaseHeaderId BIGINT
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;

	BEGIN TRY

		;WITH Picked AS
		(
			SELECT LPT.[LeaseStocklineId],
			       SUM(ISNULL(LPT.[QtyPicked], 0)) AS QtyPicked,
			       COUNT(1)                        AS PickCount
			FROM [dbo].[LeasePickTicket] LPT WITH (NOLOCK)
			WHERE LPT.[LeaseHeaderId] = @LeaseHeaderId
			  AND LPT.[IsDeleted]     = 0
			GROUP BY LPT.[LeaseStocklineId]
		)
		SELECT
			LSL.[LeaseStocklineId],
			LSL.[LeaseHeaderId],
			LSL.[ItemMasterId],
			LSL.[StockLineId],
			LSL.[ConditionId],
			LH.[LeaseNumber],
			LH.[LeaseName],
			ISNULL(CUS.[Name], '')         AS CustomerName,
			ISNULL(CUS.[CustomerCode], '') AS CustomerCode,
			LSL.[PN]                       AS PartNumber,
			LSL.[PNDescription]            AS PartDescription,
			LSL.[SN]                       AS SerialNumber,
			LSL.[StocklineNumber],
			ISNULL(CON.[Description], '')  AS ConditionDescription,
			ISNULL(SL.[StockUnitOfMeasure], '') AS UOM,
			ISNULL(SL.[ControlNumber], '') AS ControlNumber,
			ISNULL(SL.[IdNumber], '')      AS IdNumber,
			CAST(ISNULL(LSL.[QtyOrder], 0) AS DECIMAL(18, 6))    AS QtyOrder,
			CAST(ISNULL(LSL.[QtyReserved], 0) AS DECIMAL(18, 6)) AS QtyReserved,
			CAST(ISNULL(SL.[QuantityAvailable], 0) AS DECIMAL(18, 6)) AS QuantityAvailable,
			CAST(ISNULL(SL.[QuantityOnHand], 0) AS DECIMAL(18, 6))    AS QuantityOnHand,
			CAST(ISNULL(P.QtyPicked, 0) AS DECIMAL(18, 6))            AS QtyPicked,
			-- Remaining / ready to pick can never go below zero even if a reservation was
			-- reduced after the picks were taken.
			CAST(CASE WHEN (ISNULL(LSL.[QtyReserved], 0) - ISNULL(P.QtyPicked, 0)) < 0
					  THEN 0
					  ELSE (ISNULL(LSL.[QtyReserved], 0) - ISNULL(P.QtyPicked, 0))
				 END AS DECIMAL(18, 6)) AS QtyToPick,
			CAST(CASE WHEN (ISNULL(LSL.[QtyReserved], 0) - ISNULL(P.QtyPicked, 0)) < 0
					  THEN 0
					  ELSE (ISNULL(LSL.[QtyReserved], 0) - ISNULL(P.QtyPicked, 0))
				 END AS DECIMAL(18, 6)) AS ReadyToPick,
			CASE WHEN ISNULL(P.QtyPicked, 0) <= 0 THEN 'Open'
				 WHEN ISNULL(P.QtyPicked, 0) >= ISNULL(LSL.[QtyReserved], 0) THEN 'Fulfilled'
				 ELSE 'Partially Fulfilled'
			END AS [Status],
			LSL.[MasterCompanyId]
		FROM [dbo].[LeaseStockline] LSL WITH (NOLOCK)
		INNER JOIN [dbo].[LeaseHeader] LH WITH (NOLOCK) ON LH.[LeaseHeaderId] = LSL.[LeaseHeaderId]
		 LEFT JOIN [dbo].[Customer] CUS WITH (NOLOCK)   ON CUS.[CustomerId] = LH.[CustomerId]
		 LEFT JOIN [dbo].[Stockline] SL WITH (NOLOCK)   ON SL.[StockLineId] = LSL.[StockLineId]
		 LEFT JOIN [dbo].[Condition] CON WITH (NOLOCK)  ON CON.[ConditionId] = LSL.[ConditionId]
		 LEFT JOIN Picked P                             ON P.[LeaseStocklineId] = LSL.[LeaseStocklineId]
		WHERE LSL.[LeaseHeaderId] = @LeaseHeaderId
		  AND LSL.[IsDeleted]     = 0
		  -- Show a line once it has something reserved, and keep showing it after the fact
		  -- if pick tickets already exist against it.
		  AND (ISNULL(LSL.[QtyReserved], 0) > 0 OR P.PickCount > 0)
		ORDER BY LSL.[LeaseStocklineId];

	END TRY
	BEGIN CATCH
		DECLARE @ErrorLogID INT,
			@DatabaseName VARCHAR(100) = DB_NAME(),
			@AdhocComments VARCHAR(150) = '[USP_GetLeasePickTicketApproveList]',
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