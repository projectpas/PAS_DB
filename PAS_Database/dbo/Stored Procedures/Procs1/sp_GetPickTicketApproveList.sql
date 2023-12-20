/*************************************************************           
 ** File:   [sp_GetPickTicketApproveList]           
 ** Author:   Vishal Suthar
 ** Description: This stored procedure is used to retrieve pickticket listing data
 ** Purpose:         
 ** Date:   

 ** PARAMETERS:
         
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
	1    06/15/2023   Vishal Suthar Updated the SP to handle invoice before shipping and versioning
	2    06/21/2023   Vishal Suthar Updated the SP to include pick ticket even after invoice is created directly
     
-- EXEC [dbo].[sp_GetPickTicketApproveList] 478
**************************************************************/
CREATE   Procedure [dbo].[sp_GetPickTicketApproveList]
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
		,(SELECT SUM(SP.QtyToShip) FROM DBO.SOPickTicket SP WITH(NOLOCK)
		INNER JOIN SalesOrder S_O WITH(NOLOCK) ON S_O.SalesOrderId = SP.SalesOrderId
		INNER JOIN SalesOrderPart SO_P WITH(NOLOCK) ON SP.SalesOrderPartId = SO_P.SalesOrderPartId
		Where SP.SalesOrderId = @SalesOrderId AND ItemMasterId = sop.ItemMasterId AND ConditionId = sop.ConditionId) AS QtyToShip,
		((SELECT TOP 1 QtyRequested FROM SalesOrderPart WITH(NOLOCK) Where SalesOrderId = @SalesOrderId AND ItemMasterId = sop.ItemMasterId AND ConditionId = sop.ConditionId) - SUM(ISNULL(sopt.QtyToShip,0))) as QtyToPick,
		'' as [Status], 
		sop.ConditionId, 
		(SELECT ((SUM(sorpp.QtyToReserve) + SUM(ISNULL(ship_item.QtyShipped, 0))) - SUM(ISNULL(sopt.QtyToShip, 0))) FROM SalesOrderPart sopp WITH(NOLOCK) INNER JOIN SalesOrderReserveParts sorpp WITH(NOLOCK) ON 
		sopp.SalesOrderId = sorpp.SalesOrderId AND
		sopp.SalesOrderPartId = sorpp.SalesOrderPartId AND 
		sopp.ItemMasterId = imt.ItemMasterId AND
		sopp.SalesOrderId = @SalesOrderId AND sopp.ConditionId = sop.ConditionId
		LEFT JOIN SOPickTicket sopt WITH(NOLOCK) on sopt.SalesOrderId = sopp.SalesOrderId and sopt.SalesOrderPartId = sopp.SalesOrderPartId
		LEFT JOIN SalesOrderShipping ship WITH(NOLOCK) on ship.SalesOrderId = sopp.SalesOrderId 
		LEFT JOIN SalesOrderShippingItem ship_item WITH(NOLOCK) on ship_item.SalesOrderShippingId = ship.SalesOrderShippingId and ship_item.SalesOrderPartId = sopp.SalesOrderPartId
		) 
		--- (SELECT ISNULL(SUM(SOBI.NoofPieces), 0) FROM SalesOrderBillingInvoicing SOB
		--LEFT JOIN SalesOrderBillingInvoicingItem SOBI WITH(NOLOCK) on SOBI.SOBillingInvoicingId = SOB.SOBillingInvoicingId 
		--WHERE SOB.SalesOrderId = @SalesOrderId AND SOBI.ItemMasterId = sop.ItemMasterId AND SOBI.IsVersionIncrease = 0) 
		as ReadyToPick,
		cr.[Name] as CustomerName,cr.CustomerCode,
		
		ISNULL((SELECT ((SUM(ISNULL(sorpp.QtyToReserve, 0)) + SUM(ISNULL(ship_item.QtyShipped, 0))) - SUM(ISNULL(sopt.QtyToShip, 0))) FROM SalesOrderPart sopp WITH(NOLOCK) 
		INNER JOIN SalesOrderReserveParts sorpp WITH(NOLOCK) ON sopp.SalesOrderId = sorpp.SalesOrderId AND sopp.SalesOrderId = @SalesOrderId
		LEFT JOIN SalesOrderShipping ship WITH(NOLOCK) on ship.SalesOrderId = sopp.SalesOrderId 
		LEFT JOIN SalesOrderShippingItem ship_item WITH(NOLOCK) on ship_item.SalesOrderShippingId = ship.SalesOrderShippingId and ship_item.SalesOrderPartId = sopp.SalesOrderPartId
		), 0) as TotalReadyToPick

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
		where sop.SalesOrderId=@SalesOrderId AND ((sopt.SOPickTicketId IS NULL AND sor.QtyToReserve > 0) OR sopt.SOPickTicketId IS NOT NULL)
		group by sop.SalesOrderId,imt.PartNumber,imt.PartDescription,
		so.SalesOrderNumber,soq.SalesOrderQuoteNumber,sop.ItemMasterId,
		sl.ConditionId, cr.[Name],cr.CustomerCode, sop.ConditionId
		,sl.isSerialized, imt.ItemMasterId)

		SELECT DISTINCT cte.SalesOrderPartId, CTE.ItemMasterId, cte.SalesOrderId, PartNumber, PartDescription, cte.Qty,
		SerialNumber, QuantityAvailable,
		SalesOrderNumber, SalesOrderQuoteNumber, SUM(cte.QtyToShip) QtyToShip, (cte.Qty - SUM(cte.QtyToShip)) QtyToPick, ConditionId, 
		(CASE WHEN SUM(ReadyToPick) > (cte.Qty - SUM(cte.QtyToShip)) THEN (cte.Qty - SUM(cte.QtyToShip)) ELSE 
		CASE WHEN SUM(ReadyToPick) < 0 THEN 0 ELSE SUM(ReadyToPick) END END)
		AS ReadyToPick, 
		cte.[Status], CustomerName, CustomerCode 
		,CASE WHEN cte.TotalReadyToPick < 0 THEN 0 ELSE cte.TotalReadyToPick END AS TotalReadyToPick 
		FROM CTE
		LEFT JOIN SOPickTicket sopt WITH(NOLOCK) ON sopt.SalesOrderId = cte.SalesOrderId AND sopt.SalesOrderPartId = cte.SalesOrderPartId
		GROUP BY cte.SalesOrderPartId, CTE.ItemMasterId, cte.SalesOrderId, PartNumber, PartDescription, cte.Qty,
		SerialNumber, QuantityAvailable, cte.[Status], SalesOrderNumber, SalesOrderQuoteNumber, ConditionId, CustomerName, CustomerCode,cte.TotalReadyToPick 
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