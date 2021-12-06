--EXEC  GetPickTicketPrint_WO 166, 190, 191
CREATE PROCEDURE [dbo].[GetPickTicketPrint_WO]
@WorkOrderId bigint,
@WorkOrderPartId bigint,
@WOPickTicketId bigint
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;
		declare @pickTicketNo varchar(50), @masterCompanyId bigint

		BEGIN TRY
			BEGIN TRANSACTION
				BEGIN
				Select @pickTicketNo =PickTicketNumber, @masterCompanyId = MasterCompanyId FROM DBO.WorkorderPickTicket WITH (NOLOCK) WHERE PickTicketId = @WOPickTicketId
					;WITH cte as(
							SELECT SUM(QtyToShip)as TotalQtyToShip, WOP.WorkOrderId, WOP.WorkOrderMaterialsId 
							FROM DBO.WorkorderPickTicket WOP WITH (NOLOCK)
								JOIN dbo.WorkOrderMaterials WOM WITH (NOLOCK) ON WOP.WorkOrderMaterialsId = WOM.WorkOrderMaterialsId
							WHERE WOP.WorkOrderId=@WorkOrderId 
								AND WOP.MasterCompanyId = @masterCompanyId
								AND PickTicketNumber = @pickTicketNo
								AND WOM.WorkFlowWorkOrderId =@WorkOrderPartId
							GROUP BY WOP.WorkOrderId, WOP.WorkOrderMaterialsId
					)
					SELECT DISTINCT wopt.PickTicketId, wopt.CreatedDate as PickTicketDate, wopt.WorkOrderId, sl.StockLineNumber, wom.Quantity AS Qty, 
						imt.partnumber as PartNumber,imt.PartDescription,wopt.PickTicketNumber,sl.SerialNumber,sl.ControlNumber,sl.IdNumber,
						co.[Description] as ConditionDescription,sl.[Bin] as BinName,
						cte.TotalQtyToShip as QtyShipped,
						sl.[Shelf] as ShelfName, p.Description as PriorityName,
						wo.WorkOrderNum,uom.ShortName as UOM,sl.[Site] as SiteName,sl.[Warehouse] as WarehouseName,sl.[Location] as LocationName,
						sl.QuantityOnHand,sl.QuantityAvailable as QtyAvailable, wom.Memo AS Notes, 
						QtyToShip as QtyToPick,rc.Reference
					FROM dbo.WorkorderPickTicket wopt WITH (NOLOCK)
						INNER JOIN cte on cte.WorkOrderId = wopt.WorkOrderId AND cte.WorkOrderMaterialsId = wopt.WorkOrderMaterialsId
						INNER JOIN dbo.WorkOrderMaterials wom WITH (NOLOCK) on wom.WorkOrderId = wopt.WorkOrderId AND wom.WorkOrderMaterialsId = wopt.WorkOrderMaterialsId AND wom.WorkFlowWorkOrderId = @WorkOrderPartId
						INNER JOIN dbo.WorkOrder wo WITH (NOLOCK) on wo.WorkOrderId = wom.WorkOrderId
						INNER JOIN dbo.WorkOrderPartNumber wop WITH (NOLOCK) on wo.WorkOrderId = wop.WorkOrderId
						INNER JOIN dbo.WorkOrderWorkFlow wowf WITH (NOLOCK) on wowf.WorkOrderPartNoId = wop.ID
						INNER JOIN dbo.ItemMaster imt WITH (NOLOCK) on imt.ItemMasterId = wom.ItemMasterId
						LEFT JOIN dbo.WorkOrderMaterialStockLine wmsl WITH (NOLOCK) ON wmsl.WorkOrderMaterialsId = wom.WorkOrderMaterialsId
						LEFT JOIN dbo.Stockline sl WITH (NOLOCK) on sl.StockLineId = wopt.StockLineId
						LEFT JOIN dbo.Condition co WITH (NOLOCK) on co.ConditionId = sl.ConditionId
						LEFT JOIN dbo.UnitOfMeasure uom WITH (NOLOCK) on uom.UnitOfMeasureId = imt.ConsumeUnitOfMeasureId	
						LEFT JOIN dbo.Priority p WITH (NOLOCK) on p.PriorityId = wop.WorkOrderPriorityId
						LEFT JOIN dbo.ReceivingCustomerWork rc WITH (NOLOCK) on rc.StockLineId = wop.StockLineId
					WHERE  wopt.WorkOrderId=@WorkOrderId 
							AND wopt.MasterCompanyId = @masterCompanyId
							AND wopt.PickTicketNumber = @pickTicketNo
							AND wowf.WorkFlowWorkOrderId = @WorkOrderPartId
				END
			COMMIT  TRANSACTION

		END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
				PRINT 'ROLLBACK'
				ROLLBACK TRAN;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'GetPickTicketPrint_WO' 
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