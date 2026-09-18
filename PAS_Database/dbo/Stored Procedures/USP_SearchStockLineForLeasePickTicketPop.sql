/*************************************************************
 ** File:   [USP_SearchStockLineForLeasePickTicketPop]
 ** Description: Rows shown in the Leasing "Pick Items" popup. Mirrors
 **              dbo.SearchStockLinePickTicketPop (Sales Order).
 **
 **              @LeaseStocklineId = NULL  -> every still-pickable line of the Lease Order
 **                                           ("Create Multiple Pick Tickets")
 **              @LeaseStocklineId > 0     -> just that one line ("Create Pick Ticket" on a row)
 **
 **              QtyToPick is what is still outstanding on the reservation
 **              (LeaseStockline.QtyReserved minus everything already picked), which is the
 **              ceiling the save proc enforces.
 **
 **************************************************************
 ** Change History
 **************************************************************
 ** PR   Date           Author                  Change Description
 ** --   --------       -------                 --------------------------------
    1    16/09/2026     Bhargav Saliya          [PN-17931] Created - Leasing Pick Ticket

exec USP_SearchStockLineForLeasePickTicketPop @LeaseHeaderId=1, @LeaseStocklineId=NULL
************************************************************************/
CREATE PROCEDURE [dbo].[USP_SearchStockLineForLeasePickTicketPop]
	@LeaseHeaderId BIGINT,
	@LeaseStocklineId BIGINT = NULL
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
		)
		SELECT
			LSL.[LeaseStocklineId],
			LSL.[LeaseHeaderId],
			LSL.[StockLineId],
			LSL.[ItemMasterId],
			LSL.[ItemMasterId]             AS PartId,
			LSL.[ConditionId],
			LSL.[PN]                       AS PartNumber,
			LSL.[PNDescription]            AS [Description],
			ISNULL(IG.[Description], '')   AS ItemGroup,
			ISNULL(MF.[Name], '')          AS Manufacturer,
			ISNULL(SMF.[Name], '')         AS StkLineManufacturer,
			ISNULL(CON.[Description], '')  AS ConditionDescription,
			CASE WHEN IM.[IsPma] = 1 AND IM.[IsDER] = 1 THEN 'PMA&DER'
				 WHEN IM.[IsPma] = 1 AND IM.[IsDER] = 0 THEN 'PMA'
				 WHEN IM.[IsPma] = 0 AND IM.[IsDER] = 1 THEN 'DER'
				 ELSE 'OEM'
			END AS StockType,
			ISNULL(SL.[StockLineNumber], LSL.[StocklineNumber]) AS StockLineNumber,
			ISNULL(SL.[SerialNumber], LSL.[SN]) AS SerialNumber,
			ISNULL(SL.[location], '')      AS [location],
			ISNULL(SL.[ControlNumber], '') AS ControlNumber,
			ISNULL(SL.[IdNumber], '')      AS IdNumber,
			ISNULL(SL.[StockUnitOfMeasure], '') AS UOM,
			CAST(ISNULL(SL.[QuantityAvailable], 0) AS DECIMAL(18, 6)) AS QtyAvailable,
			CAST(ISNULL(SL.[QuantityOnHand], 0) AS DECIMAL(18, 6))    AS QtyOnHand,
			CAST(ISNULL(SL.[PurchaseOrderUnitCost], 0) AS DECIMAL(18, 6)) AS unitCost,
			CASE WHEN SL.[TraceableToType] = 1 THEN CUSTR.[Name]
				 WHEN SL.[TraceableToType] = 2 THEN VTR.[VendorName]
				 WHEN SL.[TraceableToType] = 9 THEN LETR.[Name]
				 WHEN SL.[TraceableToType] = 4 THEN CAST(SL.[TraceableTo] AS VARCHAR(50))
				 ELSE ''
			END AS TracableToName,
			SL.[TagDate],
			SL.[TagType],
			SL.[CertifiedBy],
			SL.[CertifiedDate],
			SL.[Memo],
			CAST(ISNULL(LSL.[QtyReserved], 0) AS DECIMAL(18, 6)) AS QtyReserved,
			CAST(ISNULL(P.QtyPicked, 0) AS DECIMAL(18, 6))       AS QtyPicked,
			CAST(CASE WHEN (ISNULL(LSL.[QtyReserved], 0) - ISNULL(P.QtyPicked, 0)) < 0
					  THEN 0
					  ELSE (ISNULL(LSL.[QtyReserved], 0) - ISNULL(P.QtyPicked, 0))
				 END AS DECIMAL(18, 6)) AS QtyToPick,
			LSL.[MasterCompanyId]
		FROM [dbo].[LeaseStockline] LSL WITH (NOLOCK)
		 LEFT JOIN [dbo].[Stockline] SL WITH (NOLOCK)      ON SL.[StockLineId] = LSL.[StockLineId]
		 LEFT JOIN [dbo].[ItemMaster] IM WITH (NOLOCK)     ON IM.[ItemMasterId] = LSL.[ItemMasterId]
		 LEFT JOIN [dbo].[ItemGroup] IG WITH (NOLOCK)      ON IG.[ItemGroupId] = IM.[ItemGroupId]
		 LEFT JOIN [dbo].[Manufacturer] MF WITH (NOLOCK)   ON MF.[ManufacturerId] = IM.[ManufacturerId]
		 LEFT JOIN [dbo].[Manufacturer] SMF WITH (NOLOCK)  ON SMF.[ManufacturerId] = SL.[ManufacturerId]
		 LEFT JOIN [dbo].[Condition] CON WITH (NOLOCK)     ON CON.[ConditionId] = LSL.[ConditionId]
		 LEFT JOIN [dbo].[Customer] CUSTR WITH (NOLOCK)    ON SL.[TraceableTo] = CUSTR.[CustomerId]
		 LEFT JOIN [dbo].[Vendor] VTR WITH (NOLOCK)        ON SL.[TraceableTo] = VTR.[VendorId]
		 LEFT JOIN [dbo].[LegalEntity] LETR WITH (NOLOCK)  ON SL.[TraceableTo] = LETR.[LegalEntityId]
		 LEFT JOIN Picked P                                ON P.[LeaseStocklineId] = LSL.[LeaseStocklineId]
		WHERE LSL.[LeaseHeaderId] = @LeaseHeaderId
		  AND LSL.[IsDeleted]     = 0
		  AND ISNULL(LSL.[QtyReserved], 0) > 0
		  AND (ISNULL(LSL.[QtyReserved], 0) - ISNULL(P.QtyPicked, 0)) > 0
		  AND (@LeaseStocklineId IS NULL OR LSL.[LeaseStocklineId] = @LeaseStocklineId)
		ORDER BY LSL.[LeaseStocklineId];

	END TRY
	BEGIN CATCH
		DECLARE @ErrorLogID INT,
			@DatabaseName VARCHAR(100) = DB_NAME(),
			@AdhocComments VARCHAR(150) = '[USP_SearchStockLineForLeasePickTicketPop]',
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
