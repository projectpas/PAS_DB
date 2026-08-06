/*************************************************************           
 ** File:   [sp_GetPickTicketApproveList_New]           
 ** Author:   Hemant Saliya
 ** Description: This stored procedure is used Get Pick Ticket Details    
 ** Purpose:         
 ** Date:   02/22/2021        
          
 ** PARAMETERS:           
 @WorkOrderId BIGINT   
 @WFWOId BIGINT  
         
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author				Change Description            
 ** --   --------     -------				--------------------------------          
    1    02/22/2021   Hemant Saliya			Created
	2    06/07/2021   Hemant Saliya			Updated SP for Get Proper Data
	3    06/07/2021   Hemant Saliya			Updated For Update WO Work Flow ID
	4    08/11/2023	  Devendra Shekh		changes for ReadyToPick
	5    10/05/2023   Hemant Saliya			Condition Group Changes
  	6    25/Feb/2026  Rajesh Gami			Modify the SP for UOM Changes (Added CTE and accordingly change)-  PN-14832
	7	 18/06/2026	  Ayushi				[PN-16911]Skip fn_ConvertUOM call when ToUOM = FromUOM
	8    01/July/2026			 RAJESH GAMI						[PN-17008] - Merge Non Stock Inventory to ItemMaster : Get only Stock Inventory Data Where IsNonStock = 0
	9    09/July/2026			 RAJESH GAMI						[PN-17009] - Merge Non-Stock Inventory to Stockline : Get only Stock Inventory Data Where IsNonStock = 0
 EXECUTE GetWOMaterialsPickTicketApproveList 3555, 3019
**************************************************************/ 
CREATE   PROCEDURE [dbo].[GetWOMaterialsPickTicketApproveList]
@workOrderId BIGINT,
@workflowWorkOrderId BIGINT
AS
BEGIN
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
SET NOCOUNT ON    

	BEGIN TRY
		BEGIN TRANSACTION
			BEGIN 
				SELECT WOMS.* INTO #WOMStockline FROM dbo.WorkOrderMaterialStockLine WOMS WITH (NOLOCK) JOIN dbo.WorkOrderMaterials WOM WITH (NOLOCK) ON WOMS.WorkOrderMaterialsId = WOM.WorkOrderMaterialsId WHERE WOM.WorkOrderId = @workOrderId AND WOM.WorkFlowWorkOrderId = @workflowWorkOrderId
				SELECT WOMS.* INTO #WOMStocklineKIT FROM dbo.WorkOrderMaterialStockLineKit WOMS WITH (NOLOCK) JOIN dbo.WorkOrderMaterialsKit WOM WITH (NOLOCK) ON WOMS.WorkOrderMaterialsKitId = WOM.WorkOrderMaterialsKitId WHERE WOM.WorkOrderId = @workOrderId AND WOM.WorkFlowWorkOrderId = @workflowWorkOrderId

			;WITH tmpCTE as(
				SELECT 
					wom.WorkOrderMaterialsId as OrderPartId, 
					wom.WorkOrderId as referenceId, 
					imt.PartNumber, 
					imt.PartDescription,
					imt.ManufacturerName as Manufacturer,
					wom.Quantity as Qty,
					wo.WorkOrderNum as OrderNumber, 
					''  as OrderQuoteNumber,
					wom.ItemMasterId, 
					wom.ConditionCodeId AS ConditionId,
					cr.[Name] as CustomerName, 
					cr.CustomerCode,
					(SELECT SUM(ISNULL(sl.QuantityAvailable, 0)) FROM #WOMStockline wmsl JOIN dbo.StockLine sl WITH (NOLOCK) ON wmsl.StockLineId = sl.StockLineId WHERE wom.WorkOrderMaterialsId = wmsl.WorkOrderMaterialsId AND ISNULL(sl.IsNonStock,0) = 0) AS QuantityAvailable,
					CASE WHEN ISNULL((Select SUM(ISNULL(wopt.QtyToShip,0)) FROM dbo.WorkorderPickTicket wopt WITH (NOLOCK) WHERE wopt.WorkOrderMaterialsId = wom.WorkOrderMaterialsId AND ISNULL(wopt.IsKitType, 0) = 0), 0) = 0 THEN ISNULL(wom.Quantity, 0) ELSE
					(SELECT SUM(ISNULL(wopt.QtyToShip,0)) FROM dbo.WorkorderPickTicket wopt WITH (NOLOCK) WHERE wopt.WorkOrderMaterialsId = wom.WorkOrderMaterialsId AND ISNULL(wopt.IsKitType, 0) = 0) END AS QtyToShip,

					(ISNULL(wom.Quantity, 0) - ISNULL((Select SUM(ISNULL(wopt.QtyToShip,0)) FROM dbo.WorkorderPickTicket wopt WITH (NOLOCK) WHERE wopt.WorkOrderMaterialsId = wom.WorkOrderMaterialsId AND ISNULL(wopt.IsKitType, 0) = 0), 0)) AS QtyToPick,

					CASE WHEN ISNULL(wom.Quantity, 0) = ISNULL((Select SUM(ISNULL(wopt.QtyToShip,0)) FROM dbo.WorkorderPickTicket wopt WITH (NOLOCK) WHERE wopt.WorkOrderMaterialsId = wom.WorkOrderMaterialsId AND ISNULL(wopt.IsKitType, 0) = 0), 0) THEN 'Fulfilled'
					ELSE 'Fullfillng' END as [Status],

					(( ISNULL((Select SUM(ISNULL(wmsl.QtyReserved, 0)) FROM #WOMStockline wmsl WHERE wom.WorkOrderMaterialsId = wmsl.WorkOrderMaterialsId),0) 
					 + ISNULL((Select SUM(ISNULL(wmsl.QtyIssued, 0)) FROM #WOMStockline wmsl WHERE wom.WorkOrderMaterialsId = wmsl.WorkOrderMaterialsId),0)) 
					- ISNULL((Select SUM(ISNULL(wopt.QtyToShip,0)) 
					FROM dbo.WorkorderPickTicket wopt WITH (NOLOCK) WHERE wopt.WorkOrderMaterialsId = wom.WorkOrderMaterialsId AND ISNULL(wopt.IsKitType, 0) = 0),0))  
					AS ReadyToPick,
					0 AS IsKitType,
					(SELECT TOP 1 wmSL.StockLineId FROM #WOMStockline wmSL WHERE wmSL.WorkOrderMaterialsId = wom.WorkOrderMaterialsId) as StockLineId
				FROM dbo.WorkOrderMaterials wom WITH (NOLOCK)
					INNER JOIN dbo.ItemMaster imt WITH (NOLOCK) on imt.ItemMasterId = wom.ItemMasterId
					INNER JOIN dbo.WorkOrder wo WITH (NOLOCK) on wo.WorkOrderId = wom.WorkOrderId
					INNER JOIN dbo.Customer cr WITH (NOLOCK) on cr.CustomerId = wo.CustomerId
				WHERE wom.WorkOrderId=@workOrderId AND wom.WorkFlowWorkOrderId = @workflowWorkOrderId AND (ISNULL(wom.QuantityReserved,0) + ISNULL(wom.QuantityIssued,0)) > 0  

				 AND ISNULL(imt.IsNonStock,0) = 0
				UNION ALL
				
				SELECT 
					wom.WorkOrderMaterialsKitId as OrderPartId, 
					wom.WorkOrderId as referenceId, 
					imt.PartNumber, 
					imt.PartDescription,
					imt.ManufacturerName as Manufacturer,
					wom.Quantity as Qty,
					wo.WorkOrderNum as OrderNumber, 
					''  as OrderQuoteNumber,
					wom.ItemMasterId, 
					wom.ConditionCodeId AS ConditionId,
					cr.[Name] as CustomerName, 
					cr.CustomerCode,
					(SELECT SUM(ISNULL(sl.QuantityAvailable, 0)) FROM #WOMStocklineKIT wmsl JOIN dbo.StockLine sl WITH (NOLOCK) ON wmsl.StockLineId = sl.StockLineId WHERE wom.WorkOrderMaterialsKitId = wmsl.WorkOrderMaterialsKitId AND ISNULL(sl.IsNonStock,0) = 0) AS QuantityAvailable,
					CASE WHEN ISNULL((Select SUM(ISNULL(wopt.QtyToShip,0)) FROM dbo.WorkorderPickTicket wopt WITH (NOLOCK) WHERE wopt.WorkOrderMaterialsId = wom.WorkOrderMaterialsKitId AND ISNULL(wopt.IsKitType, 0) = 1), 0) = 0 THEN ISNULL(wom.Quantity, 0) ELSE
					(SELECT SUM(ISNULL(wopt.QtyToShip,0)) FROM dbo.WorkorderPickTicket wopt WITH (NOLOCK) WHERE wopt.WorkOrderMaterialsId = wom.WorkOrderMaterialsKitId AND ISNULL(wopt.IsKitType, 0) = 1) END AS QtyToShip,

					(ISNULL(wom.Quantity, 0) - ISNULL((Select SUM(ISNULL(wopt.QtyToShip,0)) FROM dbo.WorkorderPickTicket wopt WITH (NOLOCK) WHERE wopt.WorkOrderMaterialsId = wom.WorkOrderMaterialsKitId AND ISNULL(wopt.IsKitType, 0) = 1), 0)) AS QtyToPick,

					CASE WHEN ISNULL(wom.Quantity, 0) = ISNULL((Select SUM(ISNULL(wopt.QtyToShip,0)) FROM dbo.WorkorderPickTicket wopt WITH (NOLOCK) WHERE wopt.WorkOrderMaterialsId = wom.WorkOrderMaterialsKitId AND ISNULL(wopt.IsKitType, 0) = 1), 0) THEN 'Fulfilled'
					ELSE 'Fullfillng' END as [Status],

					(( ISNULL((Select SUM(ISNULL(wmsl.QtyReserved, 0)) FROM #WOMStocklineKIT wmsl WHERE wom.WorkOrderMaterialsKitId = wmsl.WorkOrderMaterialsKitId),0) 
					+ ISNULL((Select SUM(ISNULL(wmsl.QtyIssued, 0)) FROM #WOMStocklineKIT wmsl WHERE wom.WorkOrderMaterialsKitId = wmsl.WorkOrderMaterialsKitId),0)) 
					- ISNULL((Select SUM(ISNULL(wopt.QtyToShip,0)) FROM dbo.WorkorderPickTicket wopt WITH (NOLOCK) WHERE wopt.WorkOrderMaterialsId = wom.WorkOrderMaterialsKitId AND ISNULL(wopt.IsKitType, 0) = 1),0))  
					AS ReadyToPick,
					1 AS IsKitType,
					(SELECT TOP 1 wmSL.StockLineId FROM #WOMStocklineKIT wmSL WHERE wmSL.WorkOrderMaterialsKitId = wom.WorkOrderMaterialsKitId) as StockLineId
				FROM dbo.WorkOrderMaterialsKit wom WITH (NOLOCK)
					INNER JOIN dbo.ItemMaster imt WITH (NOLOCK) on imt.ItemMasterId = wom.ItemMasterId
					INNER JOIN dbo.WorkOrder wo WITH (NOLOCK) on wo.WorkOrderId = wom.WorkOrderId
					INNER JOIN dbo.Customer cr WITH (NOLOCK) on cr.CustomerId = wo.CustomerId
				WHERE wom.WorkOrderId=@workOrderId AND wom.WorkFlowWorkOrderId = @workflowWorkOrderId AND (ISNULL(wom.QuantityReserved,0) + ISNULL(wom.QuantityIssued,0)) > 0
				AND ISNULL(imt.IsNonStock,0) = 0

				)
				SELECT 
					cte.OrderPartId,
					cte.referenceId,
					cte.PartNumber,
					cte.PartDescription,
					cte.Manufacturer,
					CASE WHEN SL.StockLineId > 0 THEN (CASE WHEN ISNULL(uomStock.ShortName,'') = ISNULL(uomConsume.ShortName,'') THEN Qty ELSE dbo.fn_ConvertUOM(Qty,uomStock.ShortName,uomConsume.ShortName,0,SL.MasterCompanyId) END) ELSE cte.Qty END AS Qty,
					cte.OrderNumber,
					OrderQuoteNumber,
					cte.ItemMasterId,
					cte.ConditionId,
					cte.CustomerName,
					cte.CustomerCode,
					CASE WHEN SL.StockLineId > 0 THEN (CASE WHEN ISNULL(uomStock.ShortName,'') = ISNULL(uomConsume.ShortName,'') THEN cte.QuantityAvailable ELSE dbo.fn_ConvertUOM(cte.QuantityAvailable,uomStock.ShortName,uomConsume.ShortName,0,SL.MasterCompanyId) END) ELSE cte.QuantityAvailable END AS QuantityAvailable,
					CASE WHEN SL.StockLineId > 0 THEN (CASE WHEN ISNULL(uomStock.ShortName,'') = ISNULL(uomConsume.ShortName,'') THEN cte.QtyToShip ELSE dbo.fn_ConvertUOM(cte.QtyToShip,uomStock.ShortName,uomConsume.ShortName,0,SL.MasterCompanyId) END) ELSE cte.QtyToShip END AS QtyToShip,
					CASE WHEN SL.StockLineId > 0 THEN (CASE WHEN ISNULL(uomStock.ShortName,'') = ISNULL(uomConsume.ShortName,'') THEN cte.QtyToPick ELSE dbo.fn_ConvertUOM(cte.QtyToPick,uomStock.ShortName,uomConsume.ShortName,0,SL.MasterCompanyId) END) ELSE cte.QtyToPick END AS QtyToPick,
					cte.Status,
					CASE WHEN SL.StockLineId > 0 THEN (CASE WHEN ISNULL(uomStock.ShortName,'') = ISNULL(uomConsume.ShortName,'') THEN cte.ReadyToPick ELSE dbo.fn_ConvertUOM(cte.ReadyToPick,uomStock.ShortName,uomConsume.ShortName,0,SL.MasterCompanyId) END) ELSE cte.QtyToPick END AS ReadyToPick,
					cte.IsKitType,
					cte.StockLineId
				FROM tmpCTE cte
				LEFT JOIN dbo.Stockline SL
				LEFT JOIN [dbo].[UnitOfMeasure] uomStock WITH(NOLOCK) ON uomStock.UnitOfMeasureId = SL.StockUnitOfMeasureId
				LEFT JOIN [dbo].[UnitOfMeasure] uomConsume WITH(NOLOCK) ON uomConsume.UnitOfMeasureId = SL.ConsumeUnitOfMeasureId
					ON cte.StockLineId = SL.StockLineId;
			END
		COMMIT  TRANSACTION

		END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
				PRINT 'ROLLBACK'
				ROLLBACK TRAN;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'sp_GetPickTicketApproveList_New' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@workOrderId, '') + ''',
													   @Parameter2 = ' + ISNULL(@workflowWorkOrderId ,'') +''
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