/*************************************************************
 ** File:   [USP_GetLeasePickTicketForEdit]
 ** Description: Single row behind the Leasing "Pick Items" popup when an existing, not yet
 **              confirmed pick is edited. Mirrors dbo.GetPickTicketForEdit (Sales Order).
 **
 **              QtyToPick is the ceiling the user may type: what is still outstanding on the
 **              reservation PLUS the quantity this row already holds (because saving replaces
 **              that row's quantity rather than adding to it).
 **
 **************************************************************
 ** Change History
 **************************************************************
 ** PR   Date           Author                  Change Description
 ** --   --------       -------                 --------------------------------
    1    16/09/2026     Bhargav Saliya          [PN-17931] Created - Leasing Pick Ticket

exec USP_GetLeasePickTicketForEdit @LeasePickTicketId=1
************************************************************************/
CREATE PROCEDURE [dbo].[USP_GetLeasePickTicketForEdit]
	@LeasePickTicketId BIGINT
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;

	BEGIN TRY

		;WITH OtherPicked AS
		(
			SELECT LPT.[LeaseStocklineId],
			       SUM(ISNULL(LPT.[QtyPicked], 0)) AS QtyPicked
			FROM [dbo].[LeasePickTicket] LPT WITH (NOLOCK)
			WHERE LPT.[IsDeleted]         = 0
			  AND LPT.[LeasePickTicketId] <> @LeasePickTicketId
			  AND LPT.[LeaseStocklineId] IN (SELECT [LeaseStocklineId] FROM [dbo].[LeasePickTicket] WITH (NOLOCK) WHERE [LeasePickTicketId] = @LeasePickTicketId)
			GROUP BY LPT.[LeaseStocklineId]
		)
		SELECT
			LPT.[LeasePickTicketId],
			LPT.[LeasePickTicketNumber],
			LPT.[LeaseHeaderId],
			LPT.[LeaseStocklineId],
			LPT.[StockLineId],
			LSL.[ItemMasterId],
			LSL.[ItemMasterId]             AS PartId,
			LSL.[ConditionId],
			LSL.[PN]                       AS PartNumber,
			LSL.[PNDescription]            AS [Description],
			ISNULL(CON.[Description], '')  AS ConditionDescription,
			ISNULL(SMF.[Name], '')         AS StkLineManufacturer,
			CASE WHEN IM.[IsPma] = 1 AND IM.[IsDER] = 1 THEN 'PMA&DER'
				 WHEN IM.[IsPma] = 1 AND IM.[IsDER] = 0 THEN 'PMA'
				 WHEN IM.[IsPma] = 0 AND IM.[IsDER] = 1 THEN 'DER'
				 ELSE 'OEM'
			END AS StockType,
			ISNULL(SL.[StockLineNumber], LSL.[StocklineNumber]) AS StockLineNumber,
			ISNULL(SL.[SerialNumber], LSL.[SN]) AS SerialNumber,
			ISNULL(SL.[Location], '')      AS [location],
			ISNULL(SL.[ControlNumber], '') AS ControlNumber,
			ISNULL(SL.[IdNumber], '')      AS IdNumber,
			CAST(ISNULL(SL.[QuantityAvailable], 0) AS DECIMAL(18, 6)) AS QtyAvailable,
			CAST(ISNULL(SL.[QuantityOnHand], 0) AS DECIMAL(18, 6))    AS QtyOnHand,
			CASE WHEN SL.[TraceableToType] = 1 THEN CUSTR.[Name]
				 WHEN SL.[TraceableToType] = 2 THEN VTR.[VendorName]
				 WHEN SL.[TraceableToType] = 9 THEN LETR.[Name]
				 WHEN SL.[TraceableToType] = 4 THEN CAST(SL.[TraceableTo] AS VARCHAR(50))
				 ELSE ''
			END AS TracableToName,
			CAST(ISNULL(LSL.[QtyReserved], 0) AS DECIMAL(18, 6)) AS QtyReserved,
			CAST(ISNULL(LPT.[QtyPicked], 0) AS DECIMAL(18, 6))   AS QtyPicked,
			CAST(CASE WHEN (ISNULL(LSL.[QtyReserved], 0) - ISNULL(OP.QtyPicked, 0)) < 0
					  THEN 0
					  ELSE (ISNULL(LSL.[QtyReserved], 0) - ISNULL(OP.QtyPicked, 0))
				 END AS DECIMAL(18, 6)) AS QtyToPick,
			ISNULL(LPT.[IsConfirmed], 0) AS IsConfirmed,
			LPT.[MasterCompanyId]
		FROM [dbo].[LeasePickTicket] LPT WITH (NOLOCK)
		INNER JOIN [dbo].[LeaseStockline] LSL WITH (NOLOCK) ON LSL.[LeaseStocklineId] = LPT.[LeaseStocklineId]
		 LEFT JOIN [dbo].[Stockline] SL WITH (NOLOCK)       ON SL.[StockLineId] = LPT.[StockLineId]
		 LEFT JOIN [dbo].[ItemMaster] IM WITH (NOLOCK)      ON IM.[ItemMasterId] = LSL.[ItemMasterId]
		 LEFT JOIN [dbo].[Manufacturer] SMF WITH (NOLOCK)   ON SMF.[ManufacturerId] = SL.[ManufacturerId]
		 LEFT JOIN [dbo].[Condition] CON WITH (NOLOCK)      ON CON.[ConditionId] = LSL.[ConditionId]
		 LEFT JOIN [dbo].[Customer] CUSTR WITH (NOLOCK)     ON SL.[TraceableTo] = CUSTR.[CustomerId]
		 LEFT JOIN [dbo].[Vendor] VTR WITH (NOLOCK)         ON SL.[TraceableTo] = VTR.[VendorId]
		 LEFT JOIN [dbo].[LegalEntity] LETR WITH (NOLOCK)   ON SL.[TraceableTo] = LETR.[LegalEntityId]
		 LEFT JOIN OtherPicked OP                           ON OP.[LeaseStocklineId] = LPT.[LeaseStocklineId]
		WHERE LPT.[LeasePickTicketId] = @LeasePickTicketId
		  AND LPT.[IsDeleted]         = 0;

	END TRY
	BEGIN CATCH
		DECLARE @ErrorLogID INT,
			@DatabaseName VARCHAR(100) = DB_NAME(),
			@AdhocComments VARCHAR(150) = '[USP_GetLeasePickTicketForEdit]',
			@ProcedureParameters VARCHAR(3000) = '@LeasePickTicketId = ''' + CAST(ISNULL(@LeasePickTicketId, 0) AS VARCHAR(100)),
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
