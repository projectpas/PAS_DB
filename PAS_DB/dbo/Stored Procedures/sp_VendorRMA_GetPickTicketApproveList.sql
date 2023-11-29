/*************************************************************           
 ** File:   [sp_VendorRMA_GetPickTicketApproveList]           
 ** Author:   Amit Ghediya
 ** Description: This stored procedure is used to retrieve pickticket listing data for Vendor RMA
 ** Purpose:         
 ** Date:   

 ** PARAMETERS:
         
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
	1    06/19/2023   Amit Ghediya  Created
	2    07/04/2023   Amit Ghediya  Updated for get RMANum from PArt lavel.
     
-- EXEC [dbo].[sp_VendorRMA_GetPickTicketApproveList] 36
**************************************************************/
CREATE   Procedure [dbo].[sp_VendorRMA_GetPickTicketApproveList]
	@VendorRMAId  bigint
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;

	BEGIN TRY
	BEGIN TRANSACTION
	BEGIN
		;WITH CTE AS (select DISTINCT sop.VendorRMADetailId AS VendorRMADetailId, sop.ItemMasterId, sop.VendorRMAId,imt.PartNumber,imt.PartDescription,
		(SELECT TOP 1 Qty FROM VendorRMADetail WITH(NOLOCK) Where VendorRMADetailId = sop.VendorRMADetailId AND ItemMasterId = sop.ItemMasterId) AS Qty,
		'' AS SerialNumber, 
		(SELECT SUM(QuantityAvailable) FROM StockLine sll WITH(NOLOCK) INNER JOIN VendorRMADetail sp WITH(NOLOCK) ON sll.StockLineId = sp.StockLineId 
		AND sll.ItemMasterId = sop.ItemMasterId Where sp.VendorRMAId = @VendorRMAId) AS QuantityAvailable,
		sop.RMANum AS RMANumber
		,(SELECT SUM(SP.QtyToShip) FROM DBO.RMAPickTicket SP WITH(NOLOCK)
		INNER JOIN VendorRMA S_O WITH(NOLOCK) ON S_O.VendorRMAId = SP.VendorRMAId
		INNER JOIN VendorRMADetail SO_P WITH(NOLOCK) ON SP.VendorRMADetailId = SO_P.VendorRMADetailId
		Where SP.VendorRMAId = @VendorRMAId AND SP.VendorRMADetailId = sop.VendorRMADetailId AND ItemMasterId = sop.ItemMasterId) AS QtyToShip,
		((SELECT TOP 1 Qty FROM VendorRMADetail WITH(NOLOCK) Where VendorRMAId = @VendorRMAId AND ItemMasterId = sop.ItemMasterId) - SUM(ISNULL(sopt.QtyToShip,0))) as QtyToPick,
		'' as [Status], 
		sl.ConditionId, 
		--(SELECT ((SUM(sorpp.QtyToReserve) + SUM(ISNULL(ship_item.QtyShipped, 0))) - SUM(ISNULL(sopt.QtyToShip, 0))) FROM VendorRMADetail sopp WITH(NOLOCK) INNER JOIN SalesOrderReserveParts sorpp WITH(NOLOCK) ON 
		--sopp.SalesOrderId = sorpp.SalesOrderId AND
		--sopp.SalesOrderPartId = sorpp.SalesOrderPartId AND 
		--sopp.ItemMasterId = imt.ItemMasterId AND
		--sopp.SalesOrderId = @VendorRMAId AND sopp.ConditionId = sop.ConditionId
		--LEFT JOIN SOPickTicket sopt WITH(NOLOCK) on sopt.SalesOrderId = sopp.SalesOrderId and sopt.SalesOrderPartId = sopp.SalesOrderPartId
		--LEFT JOIN SalesOrderShipping ship WITH(NOLOCK) on ship.SalesOrderId = sopp.SalesOrderId 
		--LEFT JOIN SalesOrderShippingItem ship_item WITH(NOLOCK) on ship_item.SalesOrderShippingId = ship.SalesOrderShippingId and ship_item.SalesOrderPartId = sopp.SalesOrderPartId
		--) - (SELECT ISNULL(SUM(SOBI.NoofPieces), 0) FROM SalesOrderBillingInvoicing SOB
		--LEFT JOIN SalesOrderBillingInvoicingItem SOBI WITH(NOLOCK) on SOBI.SOBillingInvoicingId = SOB.SOBillingInvoicingId 
		--WHERE SOB.SalesOrderId = @VendorRMAId AND SOBI.ItemMasterId = sop.ItemMasterId AND SOBI.IsVersionIncrease = 0) as ReadyToPick,
		((SELECT TOP 1 Qty FROM VendorRMADetail WITH(NOLOCK) Where VendorRMAId = @VendorRMAId AND ItemMasterId = sop.ItemMasterId) - ((SELECT TOP 1 Qty FROM VendorRMADetail WITH(NOLOCK) Where VendorRMAId = @VendorRMAId AND ItemMasterId = sop.ItemMasterId) - SUM(ISNULL(sopt.QtyToShip,0)))) as ReadyToPick,
		cr.[VendorName] as VendorName,cr.VendorCode,
		
		--ISNULL((SELECT ((SUM(ISNULL(sorpp.QtyToReserve, 0)) + SUM(ISNULL(ship_item.QtyShipped, 0))) - SUM(ISNULL(sopt.QtyToShip, 0))) FROM SalesOrderPart sopp WITH(NOLOCK) 
		--INNER JOIN SalesOrderReserveParts sorpp WITH(NOLOCK) ON sopp.SalesOrderId = sorpp.SalesOrderId AND sopp.SalesOrderId = @VendorRMAId
		--LEFT JOIN SalesOrderShipping ship WITH(NOLOCK) on ship.SalesOrderId = sopp.SalesOrderId 
		--LEFT JOIN SalesOrderShippingItem ship_item WITH(NOLOCK) on ship_item.SalesOrderShippingId = ship.SalesOrderShippingId and ship_item.SalesOrderPartId = sopp.SalesOrderPartId
		--), 0) as TotalReadyToPick
		0 as TotalReadyToPick

		from dbo.VendorRMADetail sop WITH(NOLOCK)
		INNER JOIN ItemMaster imt WITH(NOLOCK) on imt.ItemMasterId = sop.ItemMasterId
		LEFT JOIN StockLine sl WITH(NOLOCK) on sl.StockLineId = sop.StockLineId
		LEFT JOIN VendorRMA so WITH(NOLOCK) on so.VendorRMAId = sop.VendorRMAId
		--LEFT JOIN SalesOrderQuote soq WITH(NOLOCK) on soq.SalesOrderQuoteId = sop.SalesOrderQuoteId
		LEFT JOIN RMAPickTicket sopt WITH(NOLOCK) on sopt.VendorRMAId = sop.VendorRMAId
		--INNER JOIN SalesOrderApproval soapr WITH(NOLOCK) on soapr.SalesOrderId = sop.SalesOrderId and soapr.SalesOrderPartId = sop.SalesOrderPartId	AND soapr.CustomerStatusId = 2
		--INNER JOIN SalesOrderReserveParts sor WITH(NOLOCK) on sor.SalesOrderId = sop.SalesOrderId and sor.SalesOrderPartId = sop.SalesOrderPartId
		LEFT JOIN Vendor cr WITH(NOLOCK) on cr.VendorId = so.VendorId
		where sop.VendorRMAId=@VendorRMAId AND ((sopt.RMAPickTicketId IS NULL) OR sopt.RMAPickTicketId IS NOT NULL)
		group by sop.VendorRMADetailId,sop.VendorRMAId,imt.PartNumber,imt.PartDescription,
		sop.RMANum,sop.ItemMasterId,
		sl.ConditionId, cr.[VendorName],cr.VendorCode, sl.ConditionId
		,sl.isSerialized, imt.ItemMasterId)

		SELECT DISTINCT cte.VendorRMADetailId, CTE.ItemMasterId, cte.VendorRMAId, PartNumber, PartDescription, cte.Qty,
		SerialNumber, QuantityAvailable,
		RMANumber, SUM(cte.QtyToShip) QtyToShip, (cte.Qty - SUM(cte.QtyToShip)) QtyToPick, ConditionId, 
		--(CASE WHEN SUM(ReadyToPick) > (cte.Qty - SUM(cte.QtyToShip)) THEN (cte.Qty - SUM(cte.QtyToShip)) ELSE 
		--CASE WHEN SUM(ReadyToPick) < 0 THEN 0 ELSE SUM(ReadyToPick) END END)
		--AS ReadyToPick, 
		--SUM(cte.QtyToShip) QtyToShip, (cte.Qty - SUM(cte.QtyToShip))
		--(cte.Qty - SUM(cte.QtyToShip)) AS ReadyToPick,
		CASE WHEN SUM(cte.QtyToShip) > 0 THEN (cte.Qty - SUM(cte.QtyToShip)) ELSE cte.Qty END AS ReadyToPick,
		cte.[Status], VendorName, VendorCode 
		,CASE WHEN cte.TotalReadyToPick < 0 THEN 0 ELSE cte.TotalReadyToPick END AS TotalReadyToPick 
		FROM CTE
		LEFT JOIN RMAPickTicket sopt WITH(NOLOCK) ON sopt.VendorRMAId = cte.VendorRMAId AND sopt.VendorRMADetailId = cte.VendorRMADetailId
		GROUP BY cte.VendorRMADetailId, CTE.ItemMasterId, cte.VendorRMAId, PartNumber, PartDescription, cte.Qty,
		SerialNumber, QuantityAvailable, cte.[Status], RMANumber, ConditionId, VendorName, VendorCode,cte.TotalReadyToPick 
	END
	COMMIT  TRANSACTION

	END TRY    
	BEGIN CATCH      
		IF @@trancount > 0
			PRINT 'ROLLBACK'
			ROLLBACK TRAN;
			DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            , @AdhocComments     VARCHAR(150)    = 'sp_VendorRMA_GetPickTicketApproveList' 
            , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@VendorRMAId, '') + ''
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