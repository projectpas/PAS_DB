/*************************************************************           
 ** File:   [GetPickTicketPrint_WO]           
 ** Author:    
 ** Description: This stored procedure is used Get Pick Ticket Details for pdf   
 ** Purpose:         
 ** Date:   
          
 ** PARAMETERS:           
 @WorkOrderId BIGINT   
 @WFWOId BIGINT  
         
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date				 Author				Change Description            
 ** --   --------			 -------			--------------------------------          
    1     
	2    08/11/2023			Devendra Shekh		added readytopick to result
	3    08/11/2023			Devendra Shekh		added qtyremaining to result
	3    09/19/2023			Devendra Shekh		qty issue for pickticket resolved
     
EXEC [GetPickTicketPrint_WO] 3792,3233,721
**************************************************************/ 

CREATE   PROCEDURE [dbo].[GetPickTicketPrint_WO]
	@WorkOrderId bigint,
	@WorkOrderPartId bigint,
	@WOPickTicketId bigint
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;
		declare @pickTicketNo varchar(50), @masterCompanyId bigint, @TotalWMSTK BIGINT

		BEGIN TRY
			BEGIN TRANSACTION
				BEGIN

				Select @pickTicketNo =PickTicketNumber, @masterCompanyId = MasterCompanyId FROM DBO.WorkorderPickTicket WITH (NOLOCK) WHERE PickTicketId = @WOPickTicketId

					;WITH totakWMSTK as( SELECT Count(wmsl.WorkOrderMaterialsId) AS TotalWMSTK,  WOP.WorkOrderId, wopt.WorkOrderMaterialsId
							FROM WorkOrderPartNumber wop WITH(NOLOCK)
							INNER JOIN [dbo].[WorkOrderMaterials] wom WITH(NOLOCK) ON wop.WorkOrderId = wom.WorkOrderId 
							INNER JOIN [dbo].[WorkOrderMaterialStockLine] wmsl WITH(NOLOCK) ON wom.WorkOrderMaterialsId = wmsl.WorkOrderMaterialsId   
							LEFT JOIN [dbo].[WorkorderPickTicket] wopt WITH(NOLOCK) ON wom.WorkOrderId = wopt.WorkOrderId and wom.WorkOrderMaterialsId = wopt.WorkOrderMaterialsId AND wopt.StocklineId = wmsl.StockLineId
							WHERE wom.WorkOrderId = @WorkOrderId AND WOM.WorkFlowWorkOrderId = @WorkOrderPartId
							AND WOP.MasterCompanyId = @masterCompanyId AND WOM.WorkFlowWorkOrderId =@WorkOrderPartId AND wopt.PickTicketNumber = @pickTicketNo
							GROUP BY PickTicketNumber, WOP.WorkOrderId, wopt.WorkOrderMaterialsId
					),
					totakWMSTKit as( SELECT Count(wmsl.WorkOrderMaterialsKitId) AS TotalWMSTK,  WOP.WorkOrderId, wopt.WorkOrderMaterialsId
							FROM WorkOrderPartNumber wop WITH(NOLOCK)
							INNER JOIN [dbo].[WorkOrderMaterialsKit] wom WITH(NOLOCK) ON wop.WorkOrderId = wom.WorkOrderId 
							INNER JOIN [dbo].WorkOrderMaterialStockLineKit wmsl WITH(NOLOCK) ON wom.WorkOrderMaterialsKitId = wmsl.WorkOrderMaterialsKitId   
							LEFT JOIN [dbo].[WorkorderPickTicket] wopt WITH(NOLOCK) ON wom.WorkOrderId = wopt.WorkOrderId and wom.WorkOrderMaterialsKitId = wopt.WorkOrderMaterialsId AND wopt.StocklineId = wmsl.StockLineId
							WHERE wom.WorkOrderId = @WorkOrderId AND WOM.WorkFlowWorkOrderId = @WorkOrderPartId
							AND WOP.MasterCompanyId = @masterCompanyId AND WOM.WorkFlowWorkOrderId =@WorkOrderPartId AND wopt.PickTicketNumber = @pickTicketNo
							GROUP BY PickTicketNumber, WOP.WorkOrderId, wopt.WorkOrderMaterialsId
					),
					cte as(
							SELECT SUM(QtyToShip)as TotalQtyToShip, WOP.WorkOrderId, WOP.WorkOrderMaterialsId , MIN(QtyRemaining)as MinQty
							FROM DBO.WorkorderPickTicket WOP WITH (NOLOCK)
								JOIN dbo.WorkOrderMaterials WOM WITH (NOLOCK) ON WOP.WorkOrderMaterialsId = WOM.WorkOrderMaterialsId
							WHERE WOP.WorkOrderId=@WorkOrderId 
								AND WOP.MasterCompanyId = @masterCompanyId
								AND PickTicketNumber = @pickTicketNo
								AND WOM.WorkFlowWorkOrderId =@WorkOrderPartId
							GROUP BY WOP.WorkOrderId, WOP.WorkOrderMaterialsId
					), cteKit as(
							SELECT SUM(QtyToShip)as TotalQtyToShip, WOP.WorkOrderId, WOP.WorkOrderMaterialsId , MIN(QtyRemaining)as MinQty
							FROM DBO.WorkorderPickTicket WOP WITH (NOLOCK)
								JOIN dbo.WorkOrderMaterialsKit WOM WITH (NOLOCK) ON WOP.WorkOrderMaterialsId = WOM.WorkOrderMaterialsKitId
							WHERE WOP.WorkOrderId=@WorkOrderId 
								AND WOP.MasterCompanyId = @masterCompanyId
								AND PickTicketNumber = @pickTicketNo
								AND WOM.WorkFlowWorkOrderId =@WorkOrderPartId
							GROUP BY WOP.WorkOrderId, WOP.WorkOrderMaterialsId
					)
					SELECT DISTINCT wopt.PickTicketId, wopt.CreatedDate as PickTicketDate, wopt.WorkOrderId, sl.StockLineNumber, wom.Quantity AS Qty, 
						imts.partnumber as PartNumber,imts.PartDescription,wopt.PickTicketNumber,sl.SerialNumber,sl.ControlNumber,sl.IdNumber,
						co.[Description] as ConditionDescription,sl.[Bin] as BinName,
						--cte.TotalQtyToShip as QtyShipped,
						QtyToShip as QtyShipped,
						sl.[Shelf] as ShelfName, p.Description as PriorityName,
						wo.WorkOrderNum,uom.ShortName as UOM,sl.[Site] as SiteName,sl.[Warehouse] as WarehouseName,sl.[Location] as LocationName,
						sl.QuantityOnHand,sl.QuantityAvailable as QtyAvailable, wom.Memo AS Notes, 
						--CASE WHEN (cte.TotalQtyToShip + (wom.Quantity - cte.TotalQtyToShip)) = wom.Quantity THEN cte.TotalQtyToShip ELSE QtyToShip END as QtyToPick
						cte.TotalQtyToShip as QtyToPick
						,rc.Reference,
						--(( ISNULL((Select SUM(ISNULL(wmsl.QtyReserved, 0)) FROM WorkOrderMaterialStockLine wmsl WHERE wom.WorkOrderMaterialsId = wmsl.WorkOrderMaterialsId),0) 
						-- + ISNULL((Select SUM(ISNULL(wmsl.QtyIssued, 0)) FROM WorkOrderMaterialStockLine wmsl WHERE wom.WorkOrderMaterialsId = wmsl.WorkOrderMaterialsId),0)) 
						--- ISNULL((Select SUM(ISNULL(wopt.QtyToShip,0)) 
						----+ ISNULL((Select SUM(ISNULL(wmsl.QtyIssued, 0)) 
						----FROM #WOMStockline wmsl WHERE wom.WorkOrderMaterialsId = wmsl.WorkOrderMaterialsId),0) 
						--FROM dbo.WorkorderPickTicket wopt WITH (NOLOCK) WHERE wopt.WorkOrderMaterialsId = wom.WorkOrderMaterialsId AND ISNULL(wopt.IsKitType, 0) = 0),0))  
						--AS ReadyToPick
						CASE WHEN MinQty = 0 AND totakWMSTK.TotalWMSTK > 1 THEN 0 
						WHEN MinQty > 0 THEN MinQty ELSE wopt.QtyRemaining END AS QtyRemaining,
						MinQty,
						totakWMSTK.TotalWMSTK AS 'TOTALQTY'
					FROM dbo.WorkorderPickTicket wopt WITH (NOLOCK)
						INNER JOIN cte on cte.WorkOrderId = wopt.WorkOrderId AND cte.WorkOrderMaterialsId = wopt.WorkOrderMaterialsId
						INNER JOIN dbo.WorkOrderMaterials wom WITH (NOLOCK) on wom.WorkOrderId = wopt.WorkOrderId AND wom.WorkOrderMaterialsId = wopt.WorkOrderMaterialsId AND wom.WorkFlowWorkOrderId = @WorkOrderPartId
						INNER JOIN dbo.WorkOrder wo WITH (NOLOCK) on wo.WorkOrderId = wom.WorkOrderId
						INNER JOIN dbo.WorkOrderPartNumber wop WITH (NOLOCK) on wo.WorkOrderId = wop.WorkOrderId
						INNER JOIN dbo.WorkOrderWorkFlow wowf WITH (NOLOCK) on wowf.WorkOrderPartNoId = wop.ID
						--INNER JOIN dbo.ItemMaster imt WITH (NOLOCK) on imt.ItemMasterId = wom.ItemMasterId
						LEFT JOIN dbo.WorkOrderMaterialStockLine wmsl WITH (NOLOCK) ON wmsl.WorkOrderMaterialsId = wom.WorkOrderMaterialsId
						LEFT JOIN dbo.Stockline sl WITH (NOLOCK) on sl.StockLineId = wopt.StockLineId
						LEFT JOIN dbo.ItemMaster imts WITH (NOLOCK) on imts.ItemMasterId = sl.ItemMasterId
						LEFT JOIN dbo.Condition co WITH (NOLOCK) on co.ConditionId = sl.ConditionId
						LEFT JOIN dbo.UnitOfMeasure uom WITH (NOLOCK) on uom.UnitOfMeasureId = imts.ConsumeUnitOfMeasureId	
						LEFT JOIN dbo.Priority p WITH (NOLOCK) on p.PriorityId = wop.WorkOrderPriorityId
						LEFT JOIN dbo.ReceivingCustomerWork rc WITH (NOLOCK) on rc.StockLineId = wop.StockLineId
						LEFT JOIN totakWMSTK on totakWMSTK.WorkOrderId = wopt.WorkOrderId AND totakWMSTK.WorkOrderMaterialsId = wopt.WorkOrderMaterialsId
					WHERE  wopt.WorkOrderId=@WorkOrderId 
							AND wopt.MasterCompanyId = @masterCompanyId
							AND wopt.PickTicketNumber = @pickTicketNo
							AND wowf.WorkFlowWorkOrderId = @WorkOrderPartId

					UNION ALL
					
					SELECT DISTINCT wopt.PickTicketId, wopt.CreatedDate as PickTicketDate, wopt.WorkOrderId, sl.StockLineNumber, wom.Quantity AS Qty, 
						imts.partnumber as PartNumber,imts.PartDescription,wopt.PickTicketNumber,sl.SerialNumber,sl.ControlNumber,sl.IdNumber,
						co.[Description] as ConditionDescription,sl.[Bin] as BinName,
						--cteKit.TotalQtyToShip as QtyShipped,
						QtyToShip as QtyShipped,
						sl.[Shelf] as ShelfName, p.Description as PriorityName,
						wo.WorkOrderNum,uom.ShortName as UOM,sl.[Site] as SiteName,sl.[Warehouse] as WarehouseName,sl.[Location] as LocationName,
						sl.QuantityOnHand,sl.QuantityAvailable as QtyAvailable, wom.Memo AS Notes, 
						cteKit.TotalQtyToShip as QtyToPick,
						rc.Reference,
						--(( ISNULL((Select SUM(ISNULL(wmsl.QtyReserved, 0)) FROM WorkOrderMaterialStockLineKit wmsl WHERE wom.WorkOrderMaterialsKitId = wmsl.WorkOrderMaterialsKitId),0) 
						--+ ISNULL((Select SUM(ISNULL(wmsl.QtyIssued, 0)) FROM WorkOrderMaterialStockLineKit wmsl WHERE wom.WorkOrderMaterialsKitId = wmsl.WorkOrderMaterialsKitId),0)) 
						--- ISNULL((Select SUM(ISNULL(wopt.QtyToShip,0)) FROM dbo.WorkorderPickTicket wopt WITH (NOLOCK) WHERE wopt.WorkOrderMaterialsId = wom.WorkOrderMaterialsKitId AND ISNULL(wopt.IsKitType, 0) = 1),0))  
						--AS QtyRemaining
						CASE WHEN MinQty = 0 AND totakWMSTKit.TotalWMSTK > 1 THEN 0 
						WHEN MinQty > 0 THEN MinQty ELSE wopt.QtyRemaining END AS QtyRemaining,
						MinQty,
						totakWMSTKit.TotalWMSTK AS 'TOTALQTY'
					FROM dbo.WorkorderPickTicket wopt WITH (NOLOCK)
						INNER JOIN cteKit on cteKit.WorkOrderId = wopt.WorkOrderId AND cteKit.WorkOrderMaterialsId = wopt.WorkOrderMaterialsId
						INNER JOIN dbo.WorkOrderMaterialsKit wom WITH (NOLOCK) on wom.WorkOrderId = wopt.WorkOrderId AND wom.WorkOrderMaterialsKitId = wopt.WorkOrderMaterialsId AND wom.WorkFlowWorkOrderId = @WorkOrderPartId
						INNER JOIN dbo.WorkOrder wo WITH (NOLOCK) on wo.WorkOrderId = wom.WorkOrderId
						INNER JOIN dbo.WorkOrderPartNumber wop WITH (NOLOCK) on wo.WorkOrderId = wop.WorkOrderId
						INNER JOIN dbo.WorkOrderWorkFlow wowf WITH (NOLOCK) on wowf.WorkOrderPartNoId = wop.ID
						--INNER JOIN dbo.ItemMaster imt WITH (NOLOCK) on imt.ItemMasterId = wom.ItemMasterId
						LEFT JOIN dbo.WorkOrderMaterialStockLineKit wmsl WITH (NOLOCK) ON wmsl.WorkOrderMaterialsKitId = wom.WorkOrderMaterialsKitId
						LEFT JOIN dbo.Stockline sl WITH (NOLOCK) on sl.StockLineId = wopt.StockLineId
						LEFT JOIN dbo.ItemMaster imts WITH (NOLOCK) on imts.ItemMasterId = sl.ItemMasterId
						LEFT JOIN dbo.Condition co WITH (NOLOCK) on co.ConditionId = sl.ConditionId
						LEFT JOIN dbo.UnitOfMeasure uom WITH (NOLOCK) on uom.UnitOfMeasureId = imts.ConsumeUnitOfMeasureId	
						LEFT JOIN dbo.Priority p WITH (NOLOCK) on p.PriorityId = wop.WorkOrderPriorityId
						LEFT JOIN dbo.ReceivingCustomerWork rc WITH (NOLOCK) on rc.StockLineId = wop.StockLineId
						LEFT JOIN totakWMSTKit on totakWMSTKit.WorkOrderId = wopt.WorkOrderId AND totakWMSTKit.WorkOrderMaterialsId = wopt.WorkOrderMaterialsId
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