CREATE Procedure [dbo].[sp_GetPickTicketApproveList]
	@SalesOrderId  bigint
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;

	BEGIN TRY
	BEGIN TRANSACTION
	BEGIN
		;WITH CTE AS (select DISTINCT 0 AS SalesOrderPartId, sop.ItemMasterId, sop.SalesOrderId,imt.PartNumber,imt.PartDescription,
		(SELECT TOP 1 QtyRequested FROM SalesOrderPart WITH(NOLOCK) Where SalesOrderId = @SalesOrderId AND ItemMasterId = sop.ItemMasterId AND ConditionId = sop.ConditionId) AS Qty,
		'' AS SerialNumber, 
		(SELECT SUM(QuantityAvailable) FROM StockLine sll WITH(NOLOCK) INNER JOIN SalesOrderPart sp WITH(NOLOCK) ON sll.StockLineId = sp.StockLineId 
		AND sll.ItemMasterId = sop.ItemMasterId Where sp.SalesOrderId = @SalesOrderId) AS QuantityAvailable,
		so.SalesOrderNumber,soq.SalesOrderQuoteNumber 
		--,SUM(ISNULL(sopt.QtyToShip,0))as QtyToShip,
		,(SELECT SUM(SP.QtyToShip) FROM DBO.SOPickTicket SP WITH(NOLOCK)
		INNER JOIN SalesOrder S_O WITH(NOLOCK) ON S_O.SalesOrderId = SP.SalesOrderId
		INNER JOIN SalesOrderPart SO_P WITH(NOLOCK) ON SP.SalesOrderPartId = SO_P.SalesOrderPartId
		Where SP.SalesOrderId = @SalesOrderId AND ItemMasterId = sop.ItemMasterId AND ConditionId = sop.ConditionId) AS QtyToShip,
		((SELECT TOP 1 QtyRequested FROM SalesOrderPart WITH(NOLOCK) Where SalesOrderId = @SalesOrderId AND ItemMasterId = sop.ItemMasterId AND ConditionId = sop.ConditionId) - SUM(ISNULL(sopt.QtyToShip,0))) as QtyToPick,
		'' as [Status], 
		sop.ConditionId, 
		(SELECT (SUM(sorpp.QtyToReserve) - SUM(ISNULL(sopt.QtyToShip, 0))) FROM SalesOrderPart sopp WITH(NOLOCK) INNER JOIN SalesOrderReserveParts sorpp WITH(NOLOCK) ON 
		sopp.SalesOrderId = sorpp.SalesOrderId AND
		sopp.SalesOrderPartId = sorpp.SalesOrderPartId AND 
		sopp.ItemMasterId = imt.ItemMasterId AND
		sopp.SalesOrderId = @SalesOrderId AND sopp.ConditionId = sop.ConditionId
		LEFT JOIN SOPickTicket sopt WITH(NOLOCK) on sopt.SalesOrderId = sopp.SalesOrderId and sopt.SalesOrderPartId = sopp.SalesOrderPartId) as ReadyToPick,
		cr.[Name] as CustomerName,cr.CustomerCode,
		
		ISNULL((SELECT (SUM(ISNULL(sorpp.QtyToReserve, 0)) - SUM(ISNULL(sopt.QtyToShip, 0))) FROM SalesOrderPart sopp WITH(NOLOCK) 
		INNER JOIN SalesOrderReserveParts sorpp WITH(NOLOCK) ON 
		sopp.SalesOrderId = sorpp.SalesOrderId AND
		sopp.SalesOrderId = @SalesOrderId), 0) as TotalReadyToPick

		from dbo.SalesOrderPart sop WITH(NOLOCK)
		INNER JOIN ItemMaster imt WITH(NOLOCK) on imt.ItemMasterId = sop.ItemMasterId
		LEFT JOIN StockLine sl WITH(NOLOCK) on sl.StockLineId = sop.StockLineId
		LEFT JOIN SalesOrder so WITH(NOLOCK) on so.SalesOrderId = sop.SalesOrderId
		LEFT JOIN SalesOrderQuote soq WITH(NOLOCK) on soq.SalesOrderQuoteId = sop.SalesOrderQuoteId
		LEFT JOIN SOPickTicket sopt WITH(NOLOCK) on sopt.SalesOrderId = sop.SalesOrderId
		INNER JOIN SalesOrderApproval soapr WITH(NOLOCK) on soapr.SalesOrderId = sop.SalesOrderId and soapr.SalesOrderPartId = sop.SalesOrderPartId
					AND soapr.CustomerStatusId = 2
		INNER JOIN SalesOrderReserveParts sor WITH(NOLOCK) on sor.SalesOrderId = sop.SalesOrderId and sor.SalesOrderPartId = sop.SalesOrderPartId
		LEFT JOIN Customer cr WITH(NOLOCK) on cr.CustomerId = so.CustomerId
		where sop.SalesOrderId=@SalesOrderId AND (sor.QtyToReserve > 0)-- OR sopt.SalesOrderPartId IS NOT NULL)
		group by sop.SalesOrderId,imt.PartNumber,imt.PartDescription,
		so.SalesOrderNumber,soq.SalesOrderQuoteNumber,sop.ItemMasterId,
		sl.ConditionId, cr.[Name],cr.CustomerCode, sop.ConditionId
		,sl.isSerialized, imt.ItemMasterId)

		SELECT DISTINCT cte.SalesOrderPartId, ItemMasterId, cte.SalesOrderId, PartNumber, PartDescription, cte.Qty,
		SerialNumber, QuantityAvailable,
		SalesOrderNumber, SalesOrderQuoteNumber, SUM(cte.QtyToShip) QtyToShip, (cte.Qty - SUM(cte.QtyToShip)) QtyToPick, ConditionId, 
		CASE WHEN SUM(ReadyToPick) > (cte.Qty - SUM(cte.QtyToShip)) THEN (cte.Qty - SUM(cte.QtyToShip)) ELSE 
		CASE WHEN SUM(ReadyToPick) < 0 THEN 0 ELSE SUM(ReadyToPick) END END AS ReadyToPick, cte.[Status],
		CustomerName, CustomerCode 
		,cte.TotalReadyToPick FROM CTE
		LEFT JOIN SOPickTicket sopt WITH(NOLOCK) ON sopt.SalesOrderId = cte.SalesOrderId AND sopt.SalesOrderPartId = cte.SalesOrderPartId
		GROUP BY cte.SalesOrderPartId, ItemMasterId, cte.SalesOrderId, PartNumber, PartDescription, cte.Qty,
		SerialNumber, QuantityAvailable, cte.[Status],
		SalesOrderNumber, SalesOrderQuoteNumber, ConditionId, CustomerName, CustomerCode,cte.TotalReadyToPick 
	END
	COMMIT  TRANSACTION

	END TRY    
	BEGIN CATCH      
		IF @@trancount > 0
			PRINT 'ROLLBACK'
			ROLLBACK TRAN;
			DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            , @AdhocComments     VARCHAR(150)    = 'sp_GetPickTicketApproveList' 
            , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@SalesOrderId, '') + ''
            , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
            exec spLogException 
                    @DatabaseName           = @DatabaseName
                    , @AdhocComments          = @AdhocComments
                    , @ProcedureParameters = @ProcedureParameters
                    , @ApplicationName        =  @ApplicationName
                    , @ErrorLogID                    = @ErrorLogID OUTPUT ;
            RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
            RETURN(1);
	END CATCH
END