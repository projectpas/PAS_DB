/*************************************************************           
 ** File:   [sp_GetPickTicketApproveList]           
 ** Author:    
 ** Description: This stored procedure is used to retrieve pickticket data for pdf
 ** Purpose:         
 ** Date:   

 ** PARAMETERS:
         
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author				Change Description            
 ** --   --------     -------				--------------------------------          
	1										This stored procedure is used to retrieve pickticket data for pdf
	2    08/14/2023	  Devendra SHekh		added ReadyToPick to result 
	3    08/17/2023	  Devendra SHekh		REMOVED ReadyToPick and added QtyRemaining
	4    09/25/2023	  Devendra SHekh		PICKTICKET issue resolved
	5    11/08/2023   Amit Ghediya          pick ticket issue for multipele part resolved
     
-- -- EXEC [dbo].[GetPickTicketPrint] 503, 747, 290

**************************************************************/
CREATE     PROCEDURE [dbo].[GetPickTicketPrint]
	@SalesOrderId bigint,
	@SalesOrderPartId bigint,
	@SOPickTicketId bigint
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;

	BEGIN TRY
	BEGIN TRANSACTION
	BEGIN
		DECLARE @pickTicketNo VARCHAR(50), @masterCompanyId BIGINT

		SELECT @pickTicketNo = SOPickTicketNumber, @masterCompanyId = MasterCompanyId FROM DBO.SOPickTicket WITH (NOLOCK) WHERE SOPickTicketId = @SOPickTicketId;

		;WITH TResrvePart as (
		SELECT COUNT(SalesOrderReservePartId) as TotalResrvePart, sopp.SalesOrderId,  MIN(QtyRemaining)as MinQty, QtyToShip as NewTotalQtyToShip
			FROM SalesOrderPart sopp WITH(NOLOCK)
			INNER JOIN SalesOrderReserveParts sorpp WITH(NOLOCK) ON sopp.SalesOrderId = sorpp.SalesOrderId AND sopp.SalesOrderPartId = sorpp.SalesOrderPartId   
			LEFT JOIN SOPickTicket sopt WITH(NOLOCK) ON sopt.SalesOrderId = sopp.SalesOrderId and sopt.SalesOrderPartId = sopp.SalesOrderPartId
			WHERE sorpp.SalesOrderId = @SalesOrderId AND SOPickTicketNumber = @pickTicketNo AND sopt.SalesOrderPartId = @SalesOrderPartId
			group by sopp.SalesOrderId,QtyToShip)
		,cte as(
				select SUM(QtyToShip)as TotalQtyToShip, SOPick.SalesOrderId, SOPick.SalesOrderPartId
				FROM DBO.SOPickTicket SOPick WITH(NOLOCK) 
				JOIN dbo.SalesOrderPart SOP WITH (NOLOCK) ON SOP.SalesOrderPartId = SOPick.SalesOrderPartId
				WHERE SOPick.SalesOrderId = @SalesOrderId 
				AND SOPickTicketNumber = @pickTicketNo
				AND SOPick.SalesOrderPartId = @SalesOrderPartId
				GROUP BY SOPick.SalesOrderId, SOPick.SalesOrderPartId
		)
		SELECT sopt.SOPickTicketId, sopt.CreatedDate as SOPickTicketDate, sopt.SalesOrderId, sl.StockLineNumber, 
		sop.Qty, 
		--sopt.QtyToShip as QtyShipped, 
		--cte.TotalQtyToShip as QtyShipped, 
		TResrvePart.NewTotalQtyToShip as QtyToPick, 
		imt.partnumber as PartNumber, imt.PartDescription, sopt.SOPickTicketNumber,
		sl.SerialNumber, sl.ControlNumber, sl.IdNumber, co.[Description] as ConditionDescription,
		so.SalesOrderNumber, uom.ShortName as UOM, s.[Name] as SiteName, w.[Name] as WarehouseName, l.[Name] as LocationName, sh.[Name] as ShelfName,
		bn.[Name] as BinName, p.[Description] as PriorityName, po.PurchaseOrderNumber as PONumber,
		sl.QuantityOnHand, sl.QuantityAvailable as QtyAvailable, sop.Notes, 
		--(sop.QtyRequested - cte.TotalQtyToShip) as QtyToPick 
		--QtyToShip as QtyToPick,
		QtyToShip as QtyShipped,
		--sopt.QtyRemaining
		CASE WHEN MinQty = 0 AND TResrvePart.TotalResrvePart > 1 THEN 0 
		WHEN MinQty > 0 THEN MinQty ELSE sopt.QtyRemaining END AS QtyRemaining
		from SOPickTicket sopt WITH(NOLOCK)
		INNER JOIN cte WITH(NOLOCK) ON cte.SalesOrderId = sopt.SalesOrderId AND cte.SalesOrderPartId = sopt.SalesOrderPartId
		INNER JOIN SalesOrderPart sop WITH(NOLOCK) ON sop.SalesOrderId = sopt.SalesOrderId AND sop.SalesOrderPartId = sopt.SalesOrderPartId
		INNER JOIN SalesOrder so WITH(NOLOCK) ON so.SalesOrderId = sop.SalesOrderId
		LEFT JOIN Stockline sl WITH(NOLOCK) ON sl.StockLineId = sop.StockLineId
		INNER JOIN ItemMaster imt WITH(NOLOCK) ON imt.ItemMasterId = sop.ItemMasterId
		LEFT JOIN Condition co WITH(NOLOCK) ON co.ConditionId = sop.ConditionId
		LEFT JOIN UnitOfMeasure uom WITH(NOLOCK) ON uom.UnitOfMeasureId = imt.ConsumeUnitOfMeasureId
		LEFT JOIN [Site] s WITH(NOLOCK) ON s.SiteId = sl.SiteId
		LEFT JOIN Warehouse w WITH(NOLOCK) ON w.WarehouseId = sl.WarehouseId
		LEFT JOIN [Location] l WITH(NOLOCK) ON l.LocationId = sl.LocationId
		LEFT JOIN Shelf sh WITH(NOLOCK) ON sh.ShelfId = sl.ShelfId
		LEFT JOIN Bin bn WITH(NOLOCK) ON bn.BinId = sl.BinId
		LEFT JOIN [Priority] p WITH(NOLOCK) ON p.PriorityId = sop.PriorityId
		LEFT JOIN PurchaseOrder po WITH(NOLOCK) ON po.PurchaseOrderId = sl.PurchaseOrderId
		LEFT JOIN TResrvePart WITH(NOLOCK) ON TResrvePart.SalesOrderId = sopt.SalesOrderId
		WHERE 
		so.SalesOrderId = @SalesOrderId
		--sopt.SOPickTicketId = @SOPickTicketId;
		AND sopt.SOPickTicketNumber = @pickTicketNo;
	END
	COMMIT  TRANSACTION

	END TRY    
	BEGIN CATCH      
		IF @@trancount > 0
			PRINT 'ROLLBACK'
			ROLLBACK TRAN;
			DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            , @AdhocComments     VARCHAR(150)    = 'GetPickTicketPrint' 
            , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@SalesOrderId, '') + ''',
														@Parameter2 = ' + ISNULL(@SalesOrderPartId,'') + ', 
														@Parameter3 = ' + ISNULL(@SOPickTicketId,'') + ''
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