


CREATE PROCEDURE [dbo].[GetPickTicketPrint_SWO]
@WOPickTicketId BIGINT,
@WorkOrderId BIGINT,
@SubWorkOrderId BIGINT,
@SubWorkOrderPartId BIGINT
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;
			declare @pickTicketNo varchar(50), @masterCompanyId bigint
		BEGIN TRY
			BEGIN TRANSACTION
				BEGIN
				Select @pickTicketNo =PickTicketNumber, @masterCompanyId = MasterCompanyId from DBO.SubWorkorderPickTicket WITH (NOLOCK) where PickTicketId = @WOPickTicketId

					;WITH cte as(
							SELECT SUM(QtyToShip)as TotalQtyToShip, WorkOrderId, SubWorkOrderMaterialsId 
							FROM DBO.SubWorkorderPickTicket WITH (NOLOCK)
							WHERE WorkOrderId = @WorkOrderId 
								AND SubWorkorderId = @SubWorkOrderId 
								and PickTicketNumber = @pickTicketNo
								and MasterCompanyId = @masterCompanyId
							--AND SubWorkorderPartNoId = @SubWorkOrderPartId
							GROUP BY WorkOrderId, SubWorkOrderMaterialsId
					)
					SELECT DISTINCT wopt.PickTicketId, wopt.CreatedDate as PickTicketDate, wopt.WorkOrderId, swo.SubWorkOrderId, sl.StockLineNumber, wom.Quantity AS Qty, 
						imt.partnumber as PartNumber,imt.PartDescription,wopt.PickTicketNumber,sl.SerialNumber,sl.ControlNumber,sl.IdNumber,
						co.[Description] as ConditionDescription,sl.[Bin] as BinName,
						--wopt.QtyToShip as QtyShipped,
						cte.TotalQtyToShip as QtyShipped,
						sl.[Shelf] as ShelfName, p.Description as PriorityName,
						wo.WorkOrderNum, swo.SubWorkOrderNo, uom.ShortName as UOM,sl.[Site] as SiteName,sl.[Warehouse] as WarehouseName,sl.[Location] as LocationName,
						sl.QuantityOnHand,sl.QuantityAvailable as QtyAvailable, wom.Memo AS Notes, 
						--(wom.Quantity - cte.TotalQtyToShip) as QtyToPick
							QtyToShip as QtyToPick 
					FROM dbo.SubWorkorderPickTicket wopt WITH (NOLOCK)
						INNER JOIN cte on cte.WorkOrderId = wopt.WorkOrderId AND cte.SubWorkOrderMaterialsId = wopt.SubWorkOrderMaterialsId
						INNER JOIN dbo.SubWorkOrderMaterials wom WITH (NOLOCK) on wom.WorkOrderId = wopt.WorkOrderId AND wom.SubWorkOrderId = wopt.SubWorkorderId AND wom.SubWorkOrderMaterialsId = wopt.SubWorkOrderMaterialsId
						INNER JOIN dbo.WorkOrder wo WITH (NOLOCK) on wo.WorkOrderId = wom.WorkOrderId
						INNER JOIN dbo.SubWorkOrder swo WITH (NOLOCK) on swo.SubWorkOrderId = wopt.SubWorkOrderId
						INNER JOIN dbo.SubWorkOrderPartNumber wop WITH (NOLOCK) on wo.WorkOrderId = wop.WorkOrderId AND wom.SubWorkOrderId = wopt.SubWorkorderId
						INNER JOIN dbo.ItemMaster imt WITH (NOLOCK) on imt.ItemMasterId = wom.ItemMasterId
						LEFT JOIN dbo.SubWorkOrderMaterialStockLine wmsl WITH (NOLOCK) ON wmsl.SubWorkOrderMaterialsId = wom.SubWorkOrderMaterialsId
						LEFT JOIN dbo.Stockline sl WITH (NOLOCK) on sl.StockLineId = wopt.StockLineId
						LEFT JOIN dbo.Condition co WITH (NOLOCK) on co.ConditionId = wom.ConditionCodeId
						LEFT JOIN dbo.UnitOfMeasure uom WITH (NOLOCK) on uom.UnitOfMeasureId = imt.ConsumeUnitOfMeasureId	
						LEFT JOIN dbo.Priority p WITH (NOLOCK) on p.PriorityId = wop.SubWorkOrderPriorityId
					WHERE  wopt.SubWorkorderId=@SubWorkOrderId 
							and wopt.MasterCompanyId = @masterCompanyId
							and wopt.PickTicketNumber = @pickTicketNo
					--wopt.PickTicketId = @WOPickTicketId;
				END
			COMMIT  TRANSACTION

		END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
				PRINT 'ROLLBACK'
				ROLLBACK TRAN;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'GetPickTicketPrint_SWO' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@WorkOrderId, '') + ''',
													   @Parameter2 = ' + ISNULL(@SubWorkOrderId ,'') +'''
													   @Parameter3 = ' + ISNULL(@SubWorkOrderPartId ,'') +'''
													   @Parameter4 = ' + ISNULL(CAST(@WOPickTicketId AS varchar(10)) ,'') +''
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