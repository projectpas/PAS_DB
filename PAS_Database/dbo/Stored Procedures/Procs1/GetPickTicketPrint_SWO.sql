/*************************************************************           
 ** File:   [GetPickTicketPrint_SWO]           
 ** Author:   Hemant Saliya
 ** Description: This SP is used Get Sub WO Pick Ticket Details for pdf   
 ** Purpose:         
 ** Date:   09/20/2021       
          
 ** PARAMETERS:           
@WOPickTicketId BIGINT,
@WorkOrderId BIGINT,
@SubWorkOrderId BIGINT,
@SubWorkOrderPartId BIGINT
         
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author				Change Description            
 ** --   --------     -------				--------------------------------          
    1    08/14/2021   Devendra Shekh		added ReadyToPick to result
    2    08/21/2021   Devendra Shekh		added QtyRemaining to result replacing ReadyToPick
    3    09/20/2021   Hemant Saliya			Created
    4    12/19/2021   Devendra Shekh		changes for kit
    5    12/21/2021   Devendra Shekh		changes for itemmaster join 
    6    16/Mar/2026  Rajesh Gami			Added UOM Changes [PN-15714]  
	7	 18/06/2026   Ayushi				[PN-16911]Skip fn_ConvertUOM call when ToUOM = FromUOM
	8    01/July/2026			 RAJESH GAMI						[PN-17008] - Merge Non Stock Inventory to ItemMaster : Get only Stock Inventory Data Where IsNonStock = 0
	9    09/July/2026			 RAJESH GAMI						[PN-17009] - Merge Non-Stock Inventory to Stockline : Get only Stock Inventory Data Where IsNonStock = 0
 EXEC GetPickTicketPrint_SWO 3797,90,97,58
**************************************************************/ 

CREATE   PROCEDURE [dbo].[GetPickTicketPrint_SWO]
@WOPickTicketId BIGINT,
@WorkOrderId BIGINT,
@SubWorkOrderId BIGINT,
@SubWorkOrderPartId BIGINT
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;
			declare @pickTicketNo varchar(50), @masterCompanyId bigint, @TotalWMSTK bigint;
		BEGIN TRY
			BEGIN TRANSACTION
				BEGIN
				Select @pickTicketNo =PickTicketNumber, @masterCompanyId = MasterCompanyId from DBO.SubWorkorderPickTicket WITH (NOLOCK) where PickTicketId = @WOPickTicketId

				--SELECT WOMS.* INTO #WOMStockline FROM dbo.SubWorkOrderMaterialStockLine WOMS WITH (NOLOCK) JOIN dbo.SubWorkOrderMaterials WOM WITH (NOLOCK) ON WOMS.SubWorkOrderMaterialsId = WOM.SubWorkOrderMaterialsId
				--WHERE WOM.WorkOrderId = @WorkOrderId AND WOM.SubWorkOrderId = @SubWorkOrderId AND WOM.SubWOPartNoId = @SubWorkOrderPartId

				--SELECT @TotalWMSTK = Count(wmsl.SubWorkOrderMaterialsId) 
				--FROM [dbo].[SubWorkOrderMaterials] wom WITH(NOLOCK) 
				--INNER JOIN [dbo].[SubWorkOrderMaterialStockLine] wmsl WITH(NOLOCK) ON wom.SubWorkOrderMaterialsId = wmsl.SubWorkOrderMaterialsId      
				--LEFT JOIN [DBO].[SubWorkorderPickTicket] wopt WITH(NOLOCK) ON   wom.WorkOrderId = wopt.WorkOrderId AND wom.SubWorkOrderId = wopt.SubWorkorderId AND wom.SubWorkOrderMaterialsId = wopt.SubWorkOrderMaterialsId
				--WHERE WOM.WorkOrderId = @WorkOrderId AND WOM.SubWorkOrderId = @SubWorkOrderId AND WOM.SubWOPartNoId = @SubWorkOrderPartId GROUP BY PickTicketNumber

					;WITH totakWMSTK as( SELECT Count(wmsl.SubWorkOrderMaterialsId) AS TotalWMSTK,  WOP.WorkOrderId, wopt.SubWorkOrderMaterialsId
						FROM [dbo].SubWorkOrderPartNumber wop WITH(NOLOCK)
						INNER JOIN [dbo].[SubWorkOrderMaterials] wom WITH(NOLOCK) ON wop.WorkOrderId = wom.WorkOrderId 
						INNER JOIN [dbo].[SubWorkOrderMaterialStockLine] wmsl WITH(NOLOCK) ON wom.SubWorkOrderMaterialsId = wmsl.SubWorkOrderMaterialsId   
						LEFT JOIN [dbo].[SubWorkorderPickTicket] wopt WITH(NOLOCK) ON wom.WorkOrderId = wopt.WorkOrderId and wom.SubWorkOrderMaterialsId = wopt.SubWorkOrderMaterialsId AND wopt.StocklineId = wmsl.StockLineId
						WHERE wom.WorkOrderId = @WorkOrderId AND WOM.SubWOPartNoId = @SubWorkOrderPartId
						AND WOP.MasterCompanyId = @masterCompanyId AND wopt.PickTicketNumber = @pickTicketNo
						GROUP BY PickTicketNumber, WOP.WorkOrderId, wopt.SubWorkOrderMaterialsId
					), 
					totakWMSTKit as( SELECT Count(wmsl.SubWorkOrderMaterialsKitId) AS TotalWMSTK,  WOP.WorkOrderId, wopt.SubWorkOrderMaterialsId
							FROM [dbo].SubWorkOrderPartNumber wop WITH(NOLOCK)
							INNER JOIN [dbo].[SubWorkOrderMaterialsKit] wom WITH(NOLOCK) ON wop.WorkOrderId = wom.WorkOrderId 
							INNER JOIN [dbo].SubWorkOrderMaterialStockLineKit wmsl WITH(NOLOCK) ON wom.SubWorkOrderMaterialsKitId = wmsl.SubWorkOrderMaterialsKitId   
							LEFT JOIN [dbo].[SubWorkorderPickTicket] wopt WITH(NOLOCK) ON wom.WorkOrderId = wopt.WorkOrderId and wom.SubWorkOrderMaterialsKitId = wopt.SubWorkOrderMaterialsId AND wopt.StocklineId = wmsl.StockLineId
							WHERE wom.WorkOrderId = @WorkOrderId AND WOM.SubWOPartNoId = @SubWorkOrderPartId
							AND WOP.MasterCompanyId = @masterCompanyId AND wopt.PickTicketNumber = @pickTicketNo
							GROUP BY PickTicketNumber, WOP.WorkOrderId, wopt.SubWorkOrderMaterialsId
					),
					cte as(
							SELECT SUM(QtyToShip)as TotalQtyToShip, WOP.WorkOrderId, WOP.SubWorkOrderMaterialsId , MIN(QtyRemaining)as MinQty
							FROM DBO.SubWorkorderPickTicket WOP WITH (NOLOCK)
							JOIN dbo.SubWorkOrderMaterials WOM WITH (NOLOCK) ON WOP.SubWorkOrderMaterialsId = WOM.SubWorkOrderMaterialsId
							WHERE WOP.WorkOrderId = @WorkOrderId 
								AND WOP.SubWorkorderId = @SubWorkOrderId 
								and PickTicketNumber = @pickTicketNo
								and WOP.MasterCompanyId = @masterCompanyId
								AND SubWorkorderPartNoId = @SubWorkOrderPartId
							GROUP BY WOP.WorkOrderId, WOP.SubWorkOrderMaterialsId
					)
					, cteKit as(
							SELECT SUM(QtyToShip)as TotalQtyToShip, WOP.WorkOrderId, WOP.SubWorkOrderMaterialsId , MIN(QtyRemaining)as MinQty
							FROM DBO.SubWorkorderPickTicket WOP WITH (NOLOCK)
								JOIN dbo.SubWorkOrderMaterialsKit WOM WITH (NOLOCK) ON WOP.SubWorkOrderMaterialsId = WOM.SubWorkOrderMaterialsKitId
							WHERE WOP.WorkOrderId=@WorkOrderId 
								AND WOP.SubWorkorderId = @SubWorkOrderId 
								AND WOP.MasterCompanyId = @masterCompanyId
								AND PickTicketNumber = @pickTicketNo
								AND SubWorkorderPartNoId = @SubWorkOrderPartId
							GROUP BY WOP.WorkOrderId, WOP.SubWorkOrderMaterialsId
					)
					SELECT DISTINCT wopt.PickTicketId, wopt.CreatedDate as PickTicketDate, wopt.WorkOrderId, swo.SubWorkOrderId, sl.StockLineNumber, 
						(CASE WHEN ISNULL(uomStock.ShortName,'') = ISNULL(uomConsume.ShortName,'') THEN wom.Quantity ELSE dbo.fn_ConvertUOM(wom.Quantity,uomStock.ShortName,uomConsume.ShortName,0,@masterCompanyId) END) AS Qty, 
						imts.partnumber as PartNumber,imts.PartDescription,wopt.PickTicketNumber,sl.SerialNumber,sl.ControlNumber,sl.IdNumber,
						co.[Description] as ConditionDescription,sl.[Bin] as BinName,
						--wopt.QtyToShip as QtyShipped,
						--cte.TotalQtyToShip as QtyShipped,
						(CASE WHEN ISNULL(uomStock.ShortName,'') = ISNULL(uomConsume.ShortName,'') THEN QtyToShip ELSE dbo.fn_ConvertUOM(QtyToShip,uomStock.ShortName,uomConsume.ShortName,0,@masterCompanyId) END) AS QtyShipped,
						sl.[Shelf] as ShelfName, p.Description as PriorityName,
						wo.WorkOrderNum, swo.SubWorkOrderNo, uomConsume.ShortName as UOM,sl.[Site] as SiteName,sl.[Warehouse] as WarehouseName,sl.[Location] as LocationName,
						(CASE WHEN ISNULL(uomStock.ShortName,'') = ISNULL(uomConsume.ShortName,'') THEN sl.QuantityOnHand ELSE dbo.fn_ConvertUOM(sl.QuantityOnHand,uomStock.ShortName,uomConsume.ShortName,0,@masterCompanyId) END) AS QuantityOnHand,
						(CASE WHEN ISNULL(uomStock.ShortName,'') = ISNULL(uomConsume.ShortName,'') THEN sl.QuantityAvailable ELSE dbo.fn_ConvertUOM(sl.QuantityAvailable,uomStock.ShortName,uomConsume.ShortName,0,@masterCompanyId) END) AS QtyAvailable,
						wom.Memo AS Notes, 
						--(wom.Quantity - cte.TotalQtyToShip) as QtyToPick
						--QtyToShip as QtyToPick,
						(CASE WHEN ISNULL(uomStock.ShortName,'') = ISNULL(uomConsume.ShortName,'') THEN cte.TotalQtyToShip ELSE dbo.fn_ConvertUOM(cte.TotalQtyToShip,uomStock.ShortName,uomConsume.ShortName,0,@masterCompanyId) END) AS QtyToPick,
						--(( ISNULL((Select SUM(ISNULL(wmsl.QtyReserved, 0)) FROM #WOMStockline wmsl WHERE wom.SubWorkOrderMaterialsId = wmsl.SubWorkOrderMaterialsId),0) 
						--+ ISNULL((Select SUM(ISNULL(wmsl.QtyIssued, 0)) FROM #WOMStockline wmsl WHERE wom.SubWorkOrderMaterialsId = wmsl.SubWorkOrderMaterialsId),0)) 
						--- ISNULL((Select SUM(ISNULL(wopt.QtyToShip,0)) FROM dbo.SubWorkorderPickTicket wopt WITH (NOLOCK) WHERE wopt.SubWorkOrderMaterialsId = wom.SubWorkOrderMaterialsId),0))  
						--AS ReadyToPick
						--CASE WHEN MinQty = 0 AND @TotalWMSTK > 1 THEN 0 
						--WHEN MinQty > 0 THEN MinQty ELSE wopt.QtyRemaining END AS QtyRemaining	
						CASE WHEN MinQty = 0 AND totakWMSTK.TotalWMSTK > 1 THEN 0
							 WHEN MinQty > 0 THEN (CASE WHEN ISNULL(uomStock.ShortName,'') = ISNULL(uomConsume.ShortName,'') THEN MinQty ELSE dbo.fn_ConvertUOM(MinQty,uomStock.ShortName,uomConsume.ShortName,0,@masterCompanyId) END)
							 ELSE (CASE WHEN ISNULL(uomStock.ShortName,'') = ISNULL(uomConsume.ShortName,'') THEN wopt.QtyRemaining ELSE dbo.fn_ConvertUOM(wopt.QtyRemaining,uomStock.ShortName,uomConsume.ShortName,0,@masterCompanyId) END)
						END AS QtyRemaining,

						(CASE WHEN ISNULL(uomStock.ShortName,'') = ISNULL(uomConsume.ShortName,'') THEN MinQty ELSE dbo.fn_ConvertUOM(MinQty,uomStock.ShortName,uomConsume.ShortName,0,@masterCompanyId) END) AS MinQty

					FROM dbo.SubWorkorderPickTicket wopt WITH (NOLOCK)
						INNER JOIN cte on cte.WorkOrderId = wopt.WorkOrderId AND cte.SubWorkOrderMaterialsId = wopt.SubWorkOrderMaterialsId
						INNER JOIN dbo.SubWorkOrderMaterials wom WITH (NOLOCK) on wom.WorkOrderId = wopt.WorkOrderId AND wom.SubWorkOrderId = wopt.SubWorkorderId AND wom.SubWorkOrderMaterialsId = wopt.SubWorkOrderMaterialsId
						INNER JOIN dbo.WorkOrder wo WITH (NOLOCK) on wo.WorkOrderId = wom.WorkOrderId
						INNER JOIN dbo.SubWorkOrder swo WITH (NOLOCK) on swo.SubWorkOrderId = wopt.SubWorkOrderId
						INNER JOIN dbo.SubWorkOrderPartNumber wop WITH (NOLOCK) on wo.WorkOrderId = wop.WorkOrderId AND wom.SubWorkOrderId = wopt.SubWorkorderId
						--INNER JOIN dbo.ItemMaster imt WITH (NOLOCK) on imt.ItemMasterId = wom.ItemMasterId
						LEFT JOIN dbo.SubWorkOrderMaterialStockLine wmsl WITH (NOLOCK) ON wmsl.SubWorkOrderMaterialsId = wom.SubWorkOrderMaterialsId
						LEFT JOIN dbo.Stockline sl WITH (NOLOCK) on sl.StockLineId = wopt.StockLineId AND ISNULL(sl.IsNonStock,0) = 0
						LEFT JOIN dbo.ItemMaster imts WITH (NOLOCK) on imts.ItemMasterId = sl.ItemMasterId
						 AND ISNULL(imts.IsNonStock,0) = 0
						LEFT JOIN dbo.Condition co WITH (NOLOCK) on co.ConditionId = wom.ConditionCodeId
						LEFT JOIN dbo.UnitOfMeasure uom WITH (NOLOCK) on uom.UnitOfMeasureId = imts.ConsumeUnitOfMeasureId
						LEFT JOIN dbo.UnitOfMeasure uomStock WITH (NOLOCK) on uomStock.UnitOfMeasureId = sl.StockUnitOfMeasureId
						LEFT JOIN dbo.UnitOfMeasure uomConsume WITH (NOLOCK) on uomConsume.UnitOfMeasureId = sl.ConsumeUnitOfMeasureId
						LEFT JOIN dbo.Priority p WITH (NOLOCK) on p.PriorityId = wop.SubWorkOrderPriorityId
						LEFT JOIN totakWMSTK on totakWMSTK.WorkOrderId = wopt.WorkOrderId AND totakWMSTK.SubWorkOrderMaterialsId = wopt.SubWorkOrderMaterialsId
					WHERE  wopt.SubWorkorderId=@SubWorkOrderId 
							and wopt.MasterCompanyId = @masterCompanyId
							and wopt.PickTicketNumber = @pickTicketNo
					--wopt.PickTicketId = @WOPickTicketId;

					UNION ALL
					
					SELECT DISTINCT wopt.PickTicketId, wopt.CreatedDate as PickTicketDate, wopt.WorkOrderId, swo.SubWorkOrderId, sl.StockLineNumber, 
						(CASE WHEN ISNULL(uomStock.ShortName,'') = ISNULL(uomConsume.ShortName,'') THEN wom.Quantity ELSE dbo.fn_ConvertUOM(wom.Quantity,uomStock.ShortName,uomConsume.ShortName,0,@masterCompanyId) END) AS Qty, 
						imts.partnumber as PartNumber,imts.PartDescription,wopt.PickTicketNumber,sl.SerialNumber,sl.ControlNumber,sl.IdNumber,
						co.[Description] as ConditionDescription,sl.[Bin] as BinName,
						(CASE WHEN ISNULL(uomStock.ShortName,'') = ISNULL(uomConsume.ShortName,'') THEN QtyToShip ELSE dbo.fn_ConvertUOM(QtyToShip,uomStock.ShortName,uomConsume.ShortName,0,@masterCompanyId) END) AS QtyShipped,
						sl.[Shelf] as ShelfName, p.Description as PriorityName,
						wo.WorkOrderNum, swo.SubWorkOrderNo,uomConsume.ShortName as UOM,sl.[Site] as SiteName,sl.[Warehouse] as WarehouseName,sl.[Location] as LocationName,
						(CASE WHEN ISNULL(uomStock.ShortName,'') = ISNULL(uomConsume.ShortName,'') THEN sl.QuantityOnHand ELSE dbo.fn_ConvertUOM(sl.QuantityOnHand,uomStock.ShortName,uomConsume.ShortName,0,@masterCompanyId) END) AS QuantityOnHand,
						(CASE WHEN ISNULL(uomStock.ShortName,'') = ISNULL(uomConsume.ShortName,'') THEN sl.QuantityAvailable ELSE dbo.fn_ConvertUOM(sl.QuantityAvailable,uomStock.ShortName,uomConsume.ShortName,0,@masterCompanyId) END) AS QtyAvailable,
						wom.Memo AS Notes, 
						(CASE WHEN ISNULL(uomStock.ShortName,'') = ISNULL(uomConsume.ShortName,'') THEN cteKit.TotalQtyToShip ELSE dbo.fn_ConvertUOM(cteKit.TotalQtyToShip,uomStock.ShortName,uomConsume.ShortName,0,@masterCompanyId) END) AS QtyToPick,
						--rc.Reference,
						CASE WHEN MinQty = 0 AND totakWMSTKit.TotalWMSTK > 1 THEN 0
							 WHEN MinQty > 0 THEN (CASE WHEN ISNULL(uomStock.ShortName,'') = ISNULL(uomConsume.ShortName,'') THEN MinQty ELSE dbo.fn_ConvertUOM(MinQty,uomStock.ShortName,uomConsume.ShortName,0,@masterCompanyId) END)
							 ELSE (CASE WHEN ISNULL(uomStock.ShortName,'') = ISNULL(uomConsume.ShortName,'') THEN wopt.QtyRemaining ELSE dbo.fn_ConvertUOM(wopt.QtyRemaining,uomStock.ShortName,uomConsume.ShortName,0,@masterCompanyId) END)
						END AS QtyRemaining,
						(CASE WHEN ISNULL(uomStock.ShortName,'') = ISNULL(uomConsume.ShortName,'') THEN MinQty ELSE dbo.fn_ConvertUOM(MinQty,uomStock.ShortName,uomConsume.ShortName,0,@masterCompanyId) END) AS MinQty
					FROM dbo.SubWorkorderPickTicket wopt WITH (NOLOCK)
						INNER JOIN cteKit on cteKit.WorkOrderId = wopt.WorkOrderId AND cteKit.SubWorkOrderMaterialsId = wopt.SubWorkOrderMaterialsId
						INNER JOIN dbo.SubWorkOrderMaterialsKit wom WITH (NOLOCK) on wom.WorkOrderId = wopt.WorkOrderId AND wom.SubWorkOrderId = wopt.SubWorkorderId AND wom.SubWorkOrderMaterialsKitId = wopt.SubWorkOrderMaterialsId
						INNER JOIN dbo.WorkOrder wo WITH (NOLOCK) on wo.WorkOrderId = wom.WorkOrderId
						INNER JOIN dbo.SubWorkOrder swo WITH (NOLOCK) on swo.SubWorkOrderId = wopt.SubWorkOrderId
						INNER JOIN dbo.SubWorkOrderPartNumber wop WITH (NOLOCK) on wo.WorkOrderId = wop.WorkOrderId AND wom.SubWorkOrderId = wopt.SubWorkorderId
						--INNER JOIN dbo.ItemMaster imt WITH (NOLOCK) on imt.ItemMasterId = wom.ItemMasterId
						LEFT JOIN dbo.SubWorkOrderMaterialStockLineKit wmsl WITH (NOLOCK) ON wmsl.SubWorkOrderMaterialsKitId = wom.SubWorkOrderMaterialsKitId
						LEFT JOIN dbo.Stockline sl WITH (NOLOCK) on sl.StockLineId = wopt.StockLineId AND ISNULL(sl.IsNonStock,0) = 0
						LEFT JOIN dbo.ItemMaster imts WITH (NOLOCK) on imts.ItemMasterId = sl.ItemMasterId
						 AND ISNULL(imts.IsNonStock,0) = 0
						LEFT JOIN dbo.Condition co WITH (NOLOCK) on co.ConditionId = wom.ConditionCodeId
						LEFT JOIN dbo.UnitOfMeasure uom WITH (NOLOCK) on uom.UnitOfMeasureId = imts.ConsumeUnitOfMeasureId
						LEFT JOIN dbo.UnitOfMeasure uomStock WITH (NOLOCK) on uomStock.UnitOfMeasureId = sl.StockUnitOfMeasureId
						LEFT JOIN dbo.UnitOfMeasure uomConsume WITH (NOLOCK) on uomConsume.UnitOfMeasureId = sl.ConsumeUnitOfMeasureId
						LEFT JOIN dbo.Priority p WITH (NOLOCK) on p.PriorityId = wop.SubWorkOrderPriorityId
						LEFT JOIN totakWMSTKit on totakWMSTKit.WorkOrderId = wopt.WorkOrderId AND totakWMSTKit.SubWorkOrderMaterialsId = wopt.SubWorkOrderMaterialsId
					WHERE  wopt.SubWorkorderId=@SubWorkOrderId 
							and wopt.MasterCompanyId = @masterCompanyId
							and wopt.PickTicketNumber = @pickTicketNo
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