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
	4    09/19/2023			Devendra Shekh		qty issue for pickticket resolved
	5    26/Feb/2026		Rajesh Gami			Added UOM Changes - PN-14832   
	6	 18/06/2026			Ayushi				[PN-16911]Skip fn_ConvertUOM call when ToUOM = FromUOM
	7    01/July/2026			 RAJESH GAMI						[PN-17008] - Merge Non Stock Inventory to ItemMaster : Get only Stock Inventory Data Where IsNonStock = 0
	8    09/July/2026			 RAJESH GAMI						[PN-17009] - Merge Non-Stock Inventory to Stockline : Get only Stock Inventory Data Where IsNonStock = 0
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
					SELECT DISTINCT wopt.PickTicketId, wopt.CreatedDate as PickTicketDate, wopt.WorkOrderId, sl.StockLineNumber, 
						(CASE WHEN ISNULL(uomStock.ShortName,'') = ISNULL(uomConsume.ShortName,'') THEN wom.Quantity ELSE dbo.fn_ConvertUOM(wom.Quantity,uomStock.ShortName,uomConsume.ShortName,0,@masterCompanyId) END) AS Qty,
						imts.partnumber AS PartNumber,imts.PartDescription,wopt.PickTicketNumber,sl.SerialNumber,sl.ControlNumber,sl.IdNumber,
						co.[Description] AS ConditionDescription,sl.[Bin] AS BinName,
						--cte.TotalQtyToShip as QtyShipped,
						(CASE WHEN ISNULL(uomStock.ShortName,'') = ISNULL(uomConsume.ShortName,'') THEN QtyToShip ELSE dbo.fn_ConvertUOM(QtyToShip,uomStock.ShortName,uomConsume.ShortName,0,@masterCompanyId) END) AS QtyShipped,
						sl.[Shelf] AS ShelfName,p.Description AS PriorityName,
						wo.WorkOrderNum,uom.ShortName AS UOM,sl.[Site] AS SiteName,sl.[Warehouse] AS WarehouseName,sl.[Location] AS LocationName,
						(CASE WHEN ISNULL(uomStock.ShortName,'') = ISNULL(uomConsume.ShortName,'') THEN sl.QuantityOnHand ELSE dbo.fn_ConvertUOM(sl.QuantityOnHand,uomStock.ShortName,uomConsume.ShortName,0,@masterCompanyId) END) AS QuantityOnHand,
						(CASE WHEN ISNULL(uomStock.ShortName,'') = ISNULL(uomConsume.ShortName,'') THEN sl.QuantityAvailable ELSE dbo.fn_ConvertUOM(sl.QuantityAvailable,uomStock.ShortName,uomConsume.ShortName,0,@masterCompanyId) END) AS QtyAvailable,
						wom.Memo AS Notes,
						--CASE WHEN (cte.TotalQtyToShip + (wom.Quantity - cte.TotalQtyToShip)) = wom.Quantity THEN cte.TotalQtyToShip ELSE QtyToShip END as QtyToPick
						(CASE WHEN ISNULL(uomStock.ShortName,'') = ISNULL(uomConsume.ShortName,'') THEN cte.TotalQtyToShip ELSE dbo.fn_ConvertUOM(cte.TotalQtyToShip,uomStock.ShortName,uomConsume.ShortName,0,@masterCompanyId) END) AS QtyToPick
						,rc.Reference,
						--(( ISNULL((Select SUM(ISNULL(wmsl.QtyReserved, 0)) FROM WorkOrderMaterialStockLine wmsl WHERE wom.WorkOrderMaterialsId = wmsl.WorkOrderMaterialsId),0) 
						-- + ISNULL((Select SUM(ISNULL(wmsl.QtyIssued, 0)) FROM WorkOrderMaterialStockLine wmsl WHERE wom.WorkOrderMaterialsId = wmsl.WorkOrderMaterialsId),0)) 
						--- ISNULL((Select SUM(ISNULL(wopt.QtyToShip,0)) 
						----+ ISNULL((Select SUM(ISNULL(wmsl.QtyIssued, 0)) 
						----FROM #WOMStockline wmsl WHERE wom.WorkOrderMaterialsId = wmsl.WorkOrderMaterialsId),0) 
						--FROM dbo.WorkorderPickTicket wopt WITH (NOLOCK) WHERE wopt.WorkOrderMaterialsId = wom.WorkOrderMaterialsId AND ISNULL(wopt.IsKitType, 0) = 0),0))  
						--AS ReadyToPick
						CASE WHEN MinQty = 0 AND totakWMSTK.TotalWMSTK > 1 THEN 0 WHEN MinQty > 0 THEN (CASE WHEN ISNULL(uomStock.ShortName,'') = ISNULL(uomConsume.ShortName,'') THEN MinQty ELSE dbo.fn_ConvertUOM(MinQty,uomStock.ShortName,uomConsume.ShortName,0,@masterCompanyId) END) ELSE (CASE WHEN ISNULL(uomStock.ShortName,'') = ISNULL(uomConsume.ShortName,'') THEN wopt.QtyRemaining ELSE dbo.fn_ConvertUOM(wopt.QtyRemaining,uomStock.ShortName,uomConsume.ShortName,0,@masterCompanyId) END) END AS QtyRemaining,
						(CASE WHEN ISNULL(uomStock.ShortName,'') = ISNULL(uomConsume.ShortName,'') THEN MinQty ELSE dbo.fn_ConvertUOM(MinQty,uomStock.ShortName,uomConsume.ShortName,0,@masterCompanyId) END) AS MinQty,
						totakWMSTK.TotalWMSTK AS TOTALQTY
					FROM dbo.WorkorderPickTicket wopt WITH (NOLOCK)
						INNER JOIN cte on cte.WorkOrderId = wopt.WorkOrderId AND cte.WorkOrderMaterialsId = wopt.WorkOrderMaterialsId
						INNER JOIN dbo.WorkOrderMaterials wom WITH (NOLOCK) on wom.WorkOrderId = wopt.WorkOrderId AND wom.WorkOrderMaterialsId = wopt.WorkOrderMaterialsId AND wom.WorkFlowWorkOrderId = @WorkOrderPartId
						INNER JOIN dbo.WorkOrder wo WITH (NOLOCK) on wo.WorkOrderId = wom.WorkOrderId
						INNER JOIN dbo.WorkOrderPartNumber wop WITH (NOLOCK) on wo.WorkOrderId = wop.WorkOrderId
						INNER JOIN dbo.WorkOrderWorkFlow wowf WITH (NOLOCK) on wowf.WorkOrderPartNoId = wop.ID
						--INNER JOIN dbo.ItemMaster imt WITH (NOLOCK) on imt.ItemMasterId = wom.ItemMasterId
						LEFT JOIN dbo.WorkOrderMaterialStockLine wmsl WITH (NOLOCK) ON wmsl.WorkOrderMaterialsId = wom.WorkOrderMaterialsId
						LEFT JOIN dbo.Stockline sl WITH (NOLOCK) on sl.StockLineId = wopt.StockLineId AND ISNULL(sl.IsNonStock,0) = 0
						LEFT JOIN dbo.ItemMaster imts WITH (NOLOCK) on imts.ItemMasterId = sl.ItemMasterId
						 AND ISNULL(imts.IsNonStock,0) = 0
						LEFT JOIN dbo.Condition co WITH (NOLOCK) on co.ConditionId = sl.ConditionId
						LEFT JOIN dbo.UnitOfMeasure uom WITH (NOLOCK) on uom.UnitOfMeasureId = imts.ConsumeUnitOfMeasureId
						LEFT JOIN dbo.UnitOfMeasure uomStock WITH (NOLOCK) on uomStock.UnitOfMeasureId = sl.StockUnitOfMeasureId
						LEFT JOIN dbo.UnitOfMeasure uomConsume WITH (NOLOCK) on uomConsume.UnitOfMeasureId = sl.ConsumeUnitOfMeasureId
						LEFT JOIN dbo.Priority p WITH (NOLOCK) on p.PriorityId = wop.WorkOrderPriorityId
						LEFT JOIN dbo.ReceivingCustomerWork rc WITH (NOLOCK) on rc.StockLineId = wop.StockLineId
						LEFT JOIN totakWMSTK on totakWMSTK.WorkOrderId = wopt.WorkOrderId AND totakWMSTK.WorkOrderMaterialsId = wopt.WorkOrderMaterialsId
					WHERE  wopt.WorkOrderId=@WorkOrderId 
							AND wopt.MasterCompanyId = @masterCompanyId
							AND wopt.PickTicketNumber = @pickTicketNo
							AND wowf.WorkFlowWorkOrderId = @WorkOrderPartId

					UNION ALL
					
					SELECT DISTINCT wopt.PickTicketId, wopt.CreatedDate AS PickTicketDate, wopt.WorkOrderId, sl.StockLineNumber,
					(CASE WHEN ISNULL(uomStock.ShortName,'') = ISNULL(uomConsume.ShortName,'') THEN wom.Quantity ELSE dbo.fn_ConvertUOM(wom.Quantity,uomStock.ShortName,uomConsume.ShortName,0,@masterCompanyId) END) AS Qty,
					imts.partnumber AS PartNumber,imts.PartDescription,wopt.PickTicketNumber,sl.SerialNumber,sl.ControlNumber,sl.IdNumber,
					co.[Description] AS ConditionDescription,sl.[Bin] AS BinName,
					--cteKit.TotalQtyToShip as QtyShipped,
					(CASE WHEN ISNULL(uomStock.ShortName,'') = ISNULL(uomConsume.ShortName,'') THEN QtyToShip ELSE dbo.fn_ConvertUOM(QtyToShip,uomStock.ShortName,uomConsume.ShortName,0,@masterCompanyId) END) AS QtyShipped,
					sl.[Shelf] AS ShelfName,p.Description AS PriorityName,
					wo.WorkOrderNum,uom.ShortName AS UOM,sl.[Site] AS SiteName,sl.[Warehouse] AS WarehouseName,sl.[Location] AS LocationName,
					(CASE WHEN ISNULL(uomStock.ShortName,'') = ISNULL(uomConsume.ShortName,'') THEN sl.QuantityOnHand ELSE dbo.fn_ConvertUOM(sl.QuantityOnHand,uomStock.ShortName,uomConsume.ShortName,0,@masterCompanyId) END) AS QuantityOnHand,
					(CASE WHEN ISNULL(uomStock.ShortName,'') = ISNULL(uomConsume.ShortName,'') THEN sl.QuantityAvailable ELSE dbo.fn_ConvertUOM(sl.QuantityAvailable,uomStock.ShortName,uomConsume.ShortName,0,@masterCompanyId) END) AS QtyAvailable,
					wom.Memo AS Notes,
					(CASE WHEN ISNULL(uomStock.ShortName,'') = ISNULL(uomConsume.ShortName,'') THEN cteKit.TotalQtyToShip ELSE dbo.fn_ConvertUOM(cteKit.TotalQtyToShip,uomStock.ShortName,uomConsume.ShortName,0,@masterCompanyId) END) AS QtyToPick,
					rc.Reference,
					CASE WHEN MinQty = 0 AND totakWMSTKit.TotalWMSTK > 1 THEN 0 WHEN MinQty > 0 THEN (CASE WHEN ISNULL(uomStock.ShortName,'') = ISNULL(uomConsume.ShortName,'') THEN MinQty ELSE dbo.fn_ConvertUOM(MinQty,uomStock.ShortName,uomConsume.ShortName,0,@masterCompanyId) END) ELSE (CASE WHEN ISNULL(uomStock.ShortName,'') = ISNULL(uomConsume.ShortName,'') THEN wopt.QtyRemaining ELSE dbo.fn_ConvertUOM(wopt.QtyRemaining,uomStock.ShortName,uomConsume.ShortName,0,@masterCompanyId) END) END AS QtyRemaining,
					(CASE WHEN ISNULL(uomStock.ShortName,'') = ISNULL(uomConsume.ShortName,'') THEN MinQty ELSE dbo.fn_ConvertUOM(MinQty,uomStock.ShortName,uomConsume.ShortName,0,@masterCompanyId) END) AS MinQty,
					totakWMSTKit.TotalWMSTK AS TOTALQTY
					FROM dbo.WorkorderPickTicket wopt WITH (NOLOCK)
						INNER JOIN cteKit on cteKit.WorkOrderId = wopt.WorkOrderId AND cteKit.WorkOrderMaterialsId = wopt.WorkOrderMaterialsId
						INNER JOIN dbo.WorkOrderMaterialsKit wom WITH (NOLOCK) on wom.WorkOrderId = wopt.WorkOrderId AND wom.WorkOrderMaterialsKitId = wopt.WorkOrderMaterialsId AND wom.WorkFlowWorkOrderId = @WorkOrderPartId
						INNER JOIN dbo.WorkOrder wo WITH (NOLOCK) on wo.WorkOrderId = wom.WorkOrderId
						INNER JOIN dbo.WorkOrderPartNumber wop WITH (NOLOCK) on wo.WorkOrderId = wop.WorkOrderId
						INNER JOIN dbo.WorkOrderWorkFlow wowf WITH (NOLOCK) on wowf.WorkOrderPartNoId = wop.ID
						--INNER JOIN dbo.ItemMaster imt WITH (NOLOCK) on imt.ItemMasterId = wom.ItemMasterId
						LEFT JOIN dbo.WorkOrderMaterialStockLineKit wmsl WITH (NOLOCK) ON wmsl.WorkOrderMaterialsKitId = wom.WorkOrderMaterialsKitId
						LEFT JOIN dbo.Stockline sl WITH (NOLOCK) on sl.StockLineId = wopt.StockLineId AND ISNULL(sl.IsNonStock,0) = 0
						LEFT JOIN dbo.ItemMaster imts WITH (NOLOCK) on imts.ItemMasterId = sl.ItemMasterId
						 AND ISNULL(imts.IsNonStock,0) = 0
						LEFT JOIN dbo.Condition co WITH (NOLOCK) on co.ConditionId = sl.ConditionId
						LEFT JOIN dbo.UnitOfMeasure uom WITH (NOLOCK) on uom.UnitOfMeasureId = imts.ConsumeUnitOfMeasureId
						LEFT JOIN dbo.UnitOfMeasure uomStock WITH (NOLOCK) on uomStock.UnitOfMeasureId = sl.StockUnitOfMeasureId
						LEFT JOIN dbo.UnitOfMeasure uomConsume WITH (NOLOCK) on uomConsume.UnitOfMeasureId = sl.ConsumeUnitOfMeasureId
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