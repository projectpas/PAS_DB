Create   PROCEDURE [dbo].[GetPickTicketPrint_WO_MainPart]
@WorkOrderId bigint,
@WorkOrderPartId bigint,
@WOPickTicketId bigint
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;

		BEGIN TRY
			BEGIN TRANSACTION
				BEGIN
					;WITH cte as(
						select SUM(QtyToShip) AS TotalQtyToShip, WorkOrderId, WorkFlowWorkOrderId from DBO.WOPickTicket WITH (NOLOCK)
						where WorkOrderId = @WorkOrderId and WorkFlowWorkOrderId = @WorkOrderPartId
						group by WorkOrderId, WorkFlowWorkOrderId
					)
					select wopt.PickTicketId, wopt.CreatedDate as PickTicketDate, wopt.WorkOrderId, sl.StockLineNumber, wop.Quantity AS Qty, wopt.QtyToShip as QtyShipped,
					CASE WHEN ISNULL(wop.RevisedItemmasterid, 0) > 0 THEN wop.RevisedPartNumber ELSE imt.PartNumber END as 'PartNumber',
				    CASE WHEN ISNULL(wop.RevisedItemmasterid, 0) > 0 THEN wop.RevisedPartDescription ELSE imt.PartDescription END as 'PartDescription', 
					wopt.PickTicketNumber,
					sl.SerialNumber,sl.ControlNumber,sl.IdNumber,co.[Description] as ConditionDescription,
					so.WorkOrderNum,
					CASE WHEN ISNULL(wop.RevisedItemmasterid, 0) > 0 THEN uomR.ShortName ELSE uom.ShortName END as 'UOM',
					s.[Name] as SiteName,w.[Name] as WarehouseName,l.[Name] as LocationName,sh.[Name] as ShelfName, p.Description as PriorityName,
					bn.[Name] as BinName,
					po.PurchaseOrderNumber as PONumber,
					sl.QuantityOnHand,sl.QuantityAvailable as QtyAvailable, wowf.Memo AS Notes,
					--(wop.Quantity - cte.TotalQtyToShip) as QtyToPick
					QtyToShip as QtyToPick,wop.CustomerReference as Reference
					from WOPickTicket wopt WITH (NOLOCK)
					INNER JOIN cte on cte.WorkOrderId = wopt.WorkOrderId AND cte.WorkFlowWorkOrderId = wopt.WorkFlowWorkOrderId
					INNER JOIN DBO.WorkOrderWorkFlow wowf WITH (NOLOCK) on wopt.WorkFlowWorkOrderId = wowf.WorkOrderPartNoId
					INNER JOIN WorkOrderPartNumber wop WITH (NOLOCK) on wop.WorkOrderId = wopt.WorkorderId and wowf.WorkOrderPartNoId = wop.ID
					INNER JOIN WorkOrder so WITH (NOLOCK) on so.WorkOrderId = wop.WorkOrderId
					LEFT JOIN Stockline sl WITH (NOLOCK) on sl.StockLineId = wop.StockLineId
					INNER JOIN ItemMaster imt WITH (NOLOCK) on imt.ItemMasterId = wop.ItemMasterId
					LEFT JOIN ItemMaster imtR WITH (NOLOCK) on imtR.ItemMasterId = wop.RevisedItemmasterid
					LEFT JOIN Condition co WITH (NOLOCK) on co.ConditionId = sl.ConditionId
					LEFT JOIN UnitOfMeasure uom WITH (NOLOCK) on uom.UnitOfMeasureId = imt.ConsumeUnitOfMeasureId
					LEFT JOIN UnitOfMeasure uomR WITH (NOLOCK) on uomR.UnitOfMeasureId = imtR.ConsumeUnitOfMeasureId
					LEFT JOIN [Site] s WITH (NOLOCK) on s.SiteId = sl.SiteId
					LEFT JOIN Warehouse w WITH (NOLOCK) on w.WarehouseId = sl.WarehouseId
					LEFT JOIN [Location] l WITH (NOLOCK) on l.LocationId = sl.LocationId
					LEFT JOIN Shelf sh WITH (NOLOCK) on sh.ShelfId = sl.ShelfId
					LEFT JOIN Bin bn WITH (NOLOCK) on bn.BinId = sl.BinId
					LEFT JOIN PurchaseOrder po WITH (NOLOCK) on po.PurchaseOrderId = sl.PurchaseOrderId
					LEFT JOIN dbo.Priority p WITH (NOLOCK) on p.PriorityId = wop.WorkOrderPriorityId
					WHERE wopt.PickTicketId = @WOPickTicketId;
				END
			COMMIT  TRANSACTION

		END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
				PRINT 'ROLLBACK'
				ROLLBACK TRAN;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'GetPickTicketPrint_WO_MainPart' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@WorkOrderId, '') + ''',
													   @Parameter2 = ' + ISNULL(@WorkOrderPartId ,'') +'''
													   @Parameter3 = ' + ISNULL(CAST(@WOPickTicketId AS varchar(10)) ,'') +''
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