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
 ** PR   Date         Author			Change Description            
 ** --   --------     -------			--------------------------------          
	1    06/15/2023   Vishal Suthar		Updated the SP to handle invoice before shipping and versioning
	2    06/21/2023   Vishal Suthar		Updated the SP to include pick ticket even after invoice is created directly
	3    10/15/2024   Vishal Suthar		Modified SP to get Pick ticket list from new SO Part tables
	4    11/12/2024   Vishal Suthar		Modified to fix the Qty Available
	5    03/13/2025   Vishal Suthar		Fixed issue with higher ReadyToPick
	6    05/20/2025   Vishal Suthar		Fixed issue with readytopick which is populating wrong when qdjusted the qty
	7    08/07/2025   Vishal Suthar		Added a check for approval of the part before generating pick ticket
	8    26/12/2025   Amit Ghediya		Update condition for ReadyToPick
	9    01/July/2026			 RAJESH GAMI						[PN-17008] - Merge Non Stock Inventory to ItemMaster : Get only Stock Inventory Data Where IsNonStock = 0
     
-- EXEC [dbo].[sp_GetPickTicketApproveList] 851
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
		(SELECT TOP 1 QtyRequested FROM DBO.SalesOrderPartV1 WITH(NOLOCK) 
			Where SalesOrderId = @SalesOrderId AND ItemMasterId = sop.ItemMasterId AND ConditionId = sop.ConditionId) AS Qty,
		'' AS SerialNumber, 
		(SELECT SUM(QuantityAvailable) FROM DBO.StockLine sll WITH(NOLOCK) 
		Where sll.ItemMasterId = sop.ItemMasterId AND sll.ConditionId = sop.ConditionId) AS QuantityAvailable,
		so.SalesOrderNumber,soq.SalesOrderQuoteNumber,
		(SELECT SUM(SP.QtyToShip) FROM DBO.SOPickTicket SP WITH(NOLOCK)
		INNER JOIN DBO.SalesOrder S_O WITH(NOLOCK) ON S_O.SalesOrderId = SP.SalesOrderId
		INNER JOIN DBO.SalesOrderPartV1 SO_P WITH(NOLOCK) ON SP.SalesOrderPartId = SO_P.SalesOrderPartId
		Where SP.SalesOrderId = @SalesOrderId AND ItemMasterId = sop.ItemMasterId AND ConditionId = sop.ConditionId) AS QtyToShip,
		((SELECT TOP 1 QtyRequested FROM DBO.SalesOrderPartV1 WITH(NOLOCK) Where SalesOrderId = @SalesOrderId AND ItemMasterId = sop.ItemMasterId AND ConditionId = sop.ConditionId) - SUM(ISNULL(sopt.QtyToShip,0))) as QtyToPick,
		'' as [Status], 
		sop.ConditionId, 
		(SELECT ((ISNULL(SUM(agg.QtyReserved), 0) 
			-- - ISNULL(SUM(ship.QtyShipped), 0) 
			+ ISNULL(SUM(ship.QtyShipped), 0))
			- ISNULL(SUM(sopt.QtyToShip), 0)
		) AS ReadyToPick
		FROM 
		(
			SELECT sopp.SalesOrderPartId, SUM(sos.QtyReserved) AS QtyReserved
			FROM DBO.SalesOrderPartV1 sopp WITH(NOLOCK) 
			INNER JOIN DBO.SalesOrderStocklineV1 sos WITH(NOLOCK) ON sos.SalesOrderPartId = sopp.SalesOrderPartId
			WHERE sopp.SalesOrderId = @SalesOrderId AND sopp.ItemMasterId = sop.ItemMasterId AND sopp.ConditionId = sop.ConditionId
			GROUP BY sopp.SalesOrderPartId
		) agg
		LEFT JOIN 
		(
			SELECT ship_item.SalesOrderPartId, SUM(ship_item.QtyShipped) AS QtyShipped
			FROM DBO.SalesOrderShippingItem ship_item WITH(NOLOCK) 
			INNER JOIN DBO.SalesOrderShipping ship WITH(NOLOCK) ON ship.SalesOrderShippingId = ship_item.SalesOrderShippingId
			WHERE ship.SalesOrderId = @SalesOrderId
			GROUP BY ship_item.SalesOrderPartId
		) ship ON ship.SalesOrderPartId = agg.SalesOrderPartId
		LEFT JOIN 
		(
			SELECT sopps.SalesOrderPartId, SUM(sopt.QtyToShip) AS QtyToShip
			FROM DBO.SOPickTicket sopt WITH(NOLOCK)
			INNER JOIN DBO.SalesOrderStocklineV1 sopps WITH(NOLOCK) ON sopps.SalesOrderStocklineId = sopt.SalesOrderPartStocklineId
			WHERE sopt.SalesOrderId = @SalesOrderId
			GROUP BY sopps.SalesOrderPartId
		) sopt ON sopt.SalesOrderPartId = agg.SalesOrderPartId)
		as ReadyToPick,
		cr.[Name] as CustomerName,cr.CustomerCode,
		ISNULL((
		SELECT ((SUM(agg.QtyReserved) + SUM(ISNULL(ship.QtyShipped, 0))) - SUM(ISNULL(sopt.QtyToShip, 0))) AS TotalReadyToPick
			FROM 
			(
				SELECT sopp.SalesOrderPartId, SUM(sos.QtyReserved) AS QtyReserved
				FROM DBO.SalesOrderPartV1 sopp WITH(NOLOCK)
				LEFT JOIN DBO.SalesOrderStocklineV1 sos WITH(NOLOCK) ON sos.SalesOrderPartId = sopp.SalesOrderPartId
				WHERE sopp.SalesOrderId = @SalesOrderId AND sopp.ItemMasterId = sop.ItemMasterId AND sopp.ConditionId = sop.ConditionId
				GROUP BY sopp.SalesOrderPartId
			) agg
			LEFT JOIN 
			(
				SELECT ship_item.SalesOrderPartId, SUM(ship_item.QtyShipped) AS QtyShipped
				FROM DBO.SalesOrderShippingItem ship_item WITH(NOLOCK) 
				INNER JOIN DBO.SalesOrderShipping ship WITH(NOLOCK) ON ship.SalesOrderShippingId = ship_item.SalesOrderShippingId
				WHERE ship.SalesOrderId = @SalesOrderId
				GROUP BY ship_item.SalesOrderPartId
			) ship ON ship.SalesOrderPartId = agg.SalesOrderPartId
			LEFT JOIN 
			(
				SELECT sopt.SalesOrderPartStocklineId, SUM(sopt.QtyToShip) AS QtyToShip
				FROM DBO.SOPickTicket sopt WITH(NOLOCK)
				WHERE sopt.SalesOrderId = @SalesOrderId
				GROUP BY sopt.SalesOrderPartStocklineId
			) sopt ON sopt.SalesOrderPartStocklineId = agg.SalesOrderPartId
		), 0) AS TotalReadyToPick

		from dbo.SalesOrderPartV1 sop WITH(NOLOCK)
		LEFT JOIN DBO.SalesOrderStockLineV1 stk WITH(NOLOCK) on stk.SalesOrderPartId = sop.SalesOrderPartId
		INNER JOIN DBO.ItemMaster imt WITH(NOLOCK) on imt.ItemMasterId = sop.ItemMasterId
		LEFT JOIN DBO.StockLine sl WITH(NOLOCK) on sl.StockLineId = stk.StockLineId
		LEFT JOIN DBO.SalesOrder so WITH(NOLOCK) on so.SalesOrderId = sop.SalesOrderId
		LEFT JOIN DBO.SalesOrderQuote soq WITH(NOLOCK) on soq.SalesOrderQuoteId = so.SalesOrderQuoteId
		LEFT JOIN DBO.SOPickTicket sopt WITH(NOLOCK) on sopt.SalesOrderId = sop.SalesOrderId
		LEFT JOIN DBO.Customer cr WITH(NOLOCK) on cr.CustomerId = so.CustomerId
		where sop.SalesOrderId=@SalesOrderId AND ((sopt.SOPickTicketId IS NULL AND sop.QtyReserved > 0) OR sopt.SOPickTicketId IS NOT NULL)
		AND EXISTS (
        SELECT 1
        FROM DBO.SalesOrderApproval sao WITH(NOLOCK)
        WHERE sao.SalesOrderId = sop.SalesOrderId
          AND sao.SalesOrderPartId = sop.SalesOrderPartId
          AND sao.ApprovalActionId = 5
        )
		 AND ISNULL(imt.IsNonStock,0) = 0 group by sop.SalesOrderId,imt.PartNumber,imt.PartDescription,
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
		,CASE WHEN SUM(cte.TotalReadyToPick) < 0 THEN 0 ELSE SUM(cte.TotalReadyToPick) END AS TotalReadyToPick 
		FROM CTE
		LEFT JOIN SOPickTicket sopt WITH(NOLOCK) ON sopt.SalesOrderId = cte.SalesOrderId AND sopt.SalesOrderPartId = cte.SalesOrderPartId
		GROUP BY cte.SalesOrderPartId, CTE.ItemMasterId, cte.SalesOrderId, PartNumber, PartDescription, cte.Qty,
		SerialNumber, QuantityAvailable, cte.[Status], SalesOrderNumber, SalesOrderQuoteNumber, ConditionId, CustomerName, CustomerCode--,cte.TotalReadyToPick 
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