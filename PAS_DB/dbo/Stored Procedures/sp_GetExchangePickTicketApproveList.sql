
CREATE     Procedure [dbo].[sp_GetExchangePickTicketApproveList]
@ExchangeSalesOrderId  bigint
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;
	BEGIN TRY
	BEGIN TRANSACTION
	BEGIN
		;WITH CTE AS (select DISTINCT 0 AS ExchangeSalesOrderPartId, sop.ItemMasterId, sop.ExchangeSalesOrderId,imt.PartNumber,imt.PartDescription,
		(SELECT TOP 1 QtyQuoted FROM ExchangeSalesOrderPart WITH(NOLOCK) Where ExchangeSalesOrderId = @ExchangeSalesOrderId AND ItemMasterId = sop.ItemMasterId AND ConditionId = sop.ConditionId) AS Qty,
		'' AS SerialNumber, 
		(SELECT SUM(QuantityAvailable) FROM StockLine sll WITH(NOLOCK) INNER JOIN SalesOrderPart sp WITH(NOLOCK) ON sll.StockLineId = sp.StockLineId 
		AND sll.ItemMasterId = sop.ItemMasterId Where sp.SalesOrderId = @ExchangeSalesOrderId) AS QuantityAvailable,
		so.ExchangeSalesOrderNumber,soq.ExchangeQuoteNumber 
		,SUM(ISNULL(sopt.QtyToShip,0))as QtyToShip,
		((SELECT TOP 1 QtyQuoted FROM ExchangeSalesOrderPart WITH(NOLOCK) Where ExchangeSalesOrderId = @ExchangeSalesOrderId AND ItemMasterId = sop.ItemMasterId AND ConditionId = sop.ConditionId) - SUM(ISNULL(sopt.QtyToShip,0))) as QtyToPick,
		'' as [Status], 
		sop.ConditionId, 
		(SELECT (SUM(sorpp.QtyToReserve) - SUM(ISNULL(sopt.QtyToShip, 0)))  FROM ExchangeSalesOrderPart sopp WITH(NOLOCK) INNER JOIN ExchangeSalesOrderReserveParts sorpp WITH(NOLOCK) ON 
		sopp.ExchangeSalesOrderId = sorpp.ExchangeSalesOrderId AND
		sopp.ExchangeSalesOrderPartId = sorpp.ExchangeSalesOrderPartId AND 
		sopp.ExchangeSalesOrderId = @ExchangeSalesOrderId AND sopp.ConditionId = sop.ConditionId) as ReadyToPick
		, CASE WHEN ISNULL(SO.IsVendor,0) = 1 THEN (v.VendorName) ELSE cr.[Name] END as CustomerName
		,CASE WHEN ISNULL(SO.IsVendor,0) = 1 THEN  v.VendorCode ELSE cr.CustomerCode END AS CustomerCode
		from dbo.ExchangeSalesOrderPart sop WITH (NOLOCK)
		INNER JOIN ItemMaster imt WITH (NOLOCK) on imt.ItemMasterId = sop.ItemMasterId
		LEFT JOIN StockLine sl WITH (NOLOCK) on sl.StockLineId = sop.StockLineId
		LEFT JOIN ExchangeSalesOrder so  WITH (NOLOCK) on so.ExchangeSalesOrderId = sop.ExchangeSalesOrderId
		LEFT JOIN ExchangeQuote soq WITH (NOLOCK) on soq.ExchangeQuoteId = sop.ExchangeQuoteId
		LEFT JOIN ExchangeSOPickTicket sopt  WITH (NOLOCK) on sopt.ExchangeSalesOrderId = sop.ExchangeSalesOrderId and sopt.ExchangeSalesOrderPartId = sop.ExchangeSalesOrderPartId
		--INNER JOIN SalesOrderApproval soapr on soapr.SalesOrderId = sop.ExchangeSalesOrderId and soapr.SalesOrderPartId = sop.ExchangeSalesOrderPartId
		--			AND soapr.CustomerStatusId = 2
		INNER JOIN ExchangeSalesOrderReserveParts sor WITH(NOLOCK) on sor.ExchangeSalesOrderId = sop.ExchangeSalesOrderId and sor.ExchangeSalesOrderPartId = sop.ExchangeSalesOrderPartId
		LEFT JOIN Customer cr WITH(NOLOCK) on cr.CustomerId = so.CustomerId  AND ISNULL(SO.IsVendor,0) = 0
		LEFT JOIN Vendor v WITH(NOLOCK) on so.CustomerId = v.VendorId AND ISNULL(SO.IsVendor,0) = 1
		where sop.ExchangeSalesOrderId=@ExchangeSalesOrderId AND (sor.QtyToReserve > 0 OR sopt.ExchangeSalesOrderPartId IS NOT NULL)
		group by sop.ExchangeSalesOrderId,imt.PartNumber,imt.PartDescription,
		so.ExchangeSalesOrderNumber,soq.ExchangeQuoteNumber,sop.ItemMasterId,
		sl.ConditionId, cr.[Name],cr.CustomerCode, sop.ConditionId,SO.IsVendor,v.VendorName,v.VendorCode
		,sl.isSerialized)

		SELECT DISTINCT cte.ExchangeSalesOrderPartId, ItemMasterId, cte.ExchangeSalesOrderId, PartNumber, PartDescription, cte.Qty,
		SerialNumber, QuantityAvailable,
		ExchangeSalesOrderNumber, ExchangeQuoteNumber, SUM(cte.QtyToShip) QtyToShip, (cte.Qty - SUM(cte.QtyToShip)) QtyToPick, ConditionId, 
		CASE WHEN SUM(ReadyToPick) > (cte.Qty - SUM(cte.QtyToShip)) THEN (cte.Qty - SUM(cte.QtyToShip)) ELSE 
		CASE WHEN SUM(ReadyToPick) < 0 THEN 0 ELSE SUM(ReadyToPick) END END AS ReadyToPick, cte.[Status],
		CustomerName, CustomerCode FROM CTE
		LEFT JOIN ExchangeSOPickTicket sopt WITH(NOLOCK) ON sopt.ExchangeSalesOrderId = cte.ExchangeSalesOrderId AND sopt.ExchangeSalesOrderPartId = cte.ExchangeSalesOrderPartId
		GROUP BY cte.ExchangeSalesOrderPartId, ItemMasterId, cte.ExchangeSalesOrderId, PartNumber, PartDescription, cte.Qty,
		SerialNumber, QuantityAvailable, cte.[Status],
		ExchangeSalesOrderNumber, ExchangeQuoteNumber, ConditionId, CustomerName, CustomerCode
	END
	COMMIT  TRANSACTION
	END TRY    
	BEGIN CATCH      
		IF @@trancount > 0
			PRINT 'ROLLBACK'
			ROLLBACK TRAN;
			DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            , @AdhocComments     VARCHAR(150)    = 'sp_GetExchangePickTicketApproveList' 
            , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@ExchangeSalesOrderId, '') + ''
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