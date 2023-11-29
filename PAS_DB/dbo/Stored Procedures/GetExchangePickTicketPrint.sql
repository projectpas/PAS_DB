/*************************************************************           
 ** File:   [GetExchangePickTicketPrint]           
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
	2    08/16/2023	  Devendra SHekh		changes temptable to result for data
	2    08/18/2023	  Devendra SHekh		commneted ReadyToPick and added QtyRemaining to result
     
-- EXEC [dbo].[GetExchangePickTicketPrint] 107, 101, 76

**************************************************************/
CREATE   PROCEDURE [dbo].[GetExchangePickTicketPrint]  
@ExchangeSalesOrderId bigint,  
@ExchangeSalesOrderPartId bigint,  
@SOPickTicketId bigint  
AS  
BEGIN  
 SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED  
 SET NOCOUNT ON;  
 BEGIN TRY  
 BEGIN TRANSACTION  
 BEGIN  

  ;WITH cte as(  
    select SUM(QtyToShip)as TotalQtyToShip ,ExchangeSalesOrderId, ExchangeSalesOrderPartId from DBO.ExchangeSOPickTicket WITH(NOLOCK) where ExchangeSalesOrderId = @ExchangeSalesOrderId and ExchangeSalesOrderPartId = @ExchangeSalesOrderPartId  
    group by ExchangeSalesOrderId, ExchangeSalesOrderPartId  
  )
  --result as (
  select sopt.SOPickTicketId, sopt.CreatedDate as SOPickTicketDate, sopt.ExchangeSalesOrderId, sl.StockLineNumber, sop.QtyQuoted as Qty,   
  --sopt.QtyToShip as QtyShipped,  
  cte.TotalQtyToShip as QtyShipped,   
  imt.partnumber as PartNumber, imt.PartDescription, sopt.SOPickTicketNumber,  
  sl.SerialNumber, sl.ControlNumber, sl.IdNumber, co.[Description] as ConditionDescription,  
  so.ExchangeSalesOrderNumber, uom.ShortName as UOM, s.[Name] as SiteName, w.[Name] as WarehouseName, l.[Name] as LocationName, sh.[Name] as ShelfName,  
  bn.[Name] as BinName,  
  p.Description as PriorityName,  
  po.PurchaseOrderNumber as PONumber,  
  sl.QuantityOnHand,sl.QuantityAvailable as QtyAvailable,  
  sop.Memo as Notes,  
  --(sop.QtyQuoted - cte.TotalQtyToShip) as QtyToPick   
  QtyToShip as QtyToPick,
  so.CustomerReference,
  --(SELECT (SUM(sorpp.QtyToReserve) - SUM(ISNULL(sopt.QtyToShip, 0)))  FROM ExchangeSalesOrderPart sopp WITH(NOLOCK) INNER JOIN ExchangeSalesOrderReserveParts sorpp WITH(NOLOCK) ON sopp.ExchangeSalesOrderId = sorpp.ExchangeSalesOrderId 
  -- AND sopp.ExchangeSalesOrderPartId = sorpp.ExchangeSalesOrderPartId AND sopp.ItemMasterId = imt.ItemMasterId AND sopp.ExchangeSalesOrderId = @ExchangeSalesOrderId AND sopp.ConditionId = sop.ConditionId
  -- LEFT JOIN ExchangeSOPickTicket sopt WITH(NOLOCK) on sopt.ExchangeSalesOrderId = sopp.ExchangeSalesOrderId and sopt.ExchangeSalesOrderPartId = sopp.ExchangeSalesOrderPartId
  -- LEFT JOIN ExchangeSalesOrderShipping ship WITH(NOLOCK) on ship.ExchangeSalesOrderId = sopp.ExchangeSalesOrderId 
  -- LEFT JOIN ExchangeSalesOrderShippingItem ship_item WITH(NOLOCK) on ship_item.ExchangeSalesOrderShippingId = ship.ExchangeSalesOrderShippingId and ship_item.ExchangeSalesOrderPartId = sopp.ExchangeSalesOrderPartId
  -- ) as ReadyToPick
  sopt.QtyRemaining
  --INTO #tempExchPickTable
  FROM ExchangeSOPickTicket sopt WITH(NOLOCK)  
  INNER JOIN cte  WITH(NOLOCK) on cte.ExchangeSalesOrderId = sopt.ExchangeSalesOrderId AND cte.ExchangeSalesOrderPartId = sopt.ExchangeSalesOrderPartId  
  INNER JOIN ExchangeSalesOrderPart sop WITH(NOLOCK) on sop.ExchangeSalesOrderId = sopt.ExchangeSalesOrderId AND sop.ExchangeSalesOrderPartId = sopt.ExchangeSalesOrderPartId  
  INNER JOIN ExchangeSalesOrder so WITH(NOLOCK) on so.ExchangeSalesOrderId = sop.ExchangeSalesOrderId  
  LEFT JOIN Stockline sl WITH(NOLOCK) on sl.StockLineId = sop.StockLineId  
  INNER JOIN ItemMaster imt WITH(NOLOCK) on imt.ItemMasterId = sop.ItemMasterId  
  LEFT JOIN Condition co WITH(NOLOCK) on co.ConditionId = sop.ConditionId  
  LEFT JOIN UnitOfMeasure uom WITH(NOLOCK) on uom.UnitOfMeasureId = imt.ConsumeUnitOfMeasureId  
  LEFT JOIN [Site] s WITH(NOLOCK) on s.SiteId = sl.SiteId  
  LEFT JOIN Warehouse w WITH(NOLOCK) on w.WarehouseId = sl.WarehouseId  
  LEFT JOIN [Location] l WITH(NOLOCK) on l.LocationId = sl.LocationId  
  LEFT JOIN Shelf sh WITH(NOLOCK) on sh.ShelfId = sl.ShelfId  
  LEFT JOIN Bin bn WITH(NOLOCK) on bn.BinId = sl.BinId  
  LEFT JOIN PurchaseOrder po WITH(NOLOCK) on po.PurchaseOrderId = sl.PurchaseOrderId  
  LEFT JOIN [Priority] p WITH(NOLOCK) ON sop.PriorityId = p.PriorityId
  WHERE sopt.SOPickTicketId = @SOPickTicketId;

	--SELECT DISTINCT cte.SOPickTicketId, cte.SOPickTicketDate, cte.ExchangeSalesOrderId, cte.StockLineNumber,cte.Qty, QtyShipped,PartNumber, PartDescription,
	--	cte.SOPickTicketNumber, cte.SerialNumber, cte.ControlNumber, cte.IdNumber, cte.ConditionDescription, cte.ExchangeSalesOrderNumber, cte.UOM,
	--	cte.SiteName, cte.WarehouseName, cte.LocationName, cte.ShelfName, cte.BinName, cte.PriorityName, cte.PONumber,
	--	cte.QuantityOnHand, cte.QtyAvailable, cte.Notes, cte.QtyToPick, cte.CustomerReference, 
		--CASE WHEN SUM(ReadyToPick) > (cte.Qty - SUM(cte.QtyToPick)) THEN (cte.Qty - SUM(cte.QtyToPick)) ELSE 
		--CASE WHEN SUM(ReadyToPick) < 0 THEN 0 ELSE SUM(ReadyToPick) END END AS ReadyToPick
		--cte.QtyRemaining
		--FROM result cte
		--GROUP BY cte.SOPickTicketId, cte.SOPickTicketDate, cte.ExchangeSalesOrderId, cte.StockLineNumber,cte.Qty,QtyShipped,PartNumber, PartDescription,
		--cte.SOPickTicketNumber, cte.SerialNumber, cte.ControlNumber, cte.IdNumber, cte.ConditionDescription, cte.ExchangeSalesOrderNumber, cte.UOM,
		--cte.SiteName, cte.WarehouseName, cte.LocationName, cte.ShelfName, cte.BinName, cte.PriorityName, cte.PONumber,
		--cte.QuantityOnHand, cte.QtyAvailable, cte.Notes, cte.QtyToPick, cte.CustomerReference
		--,ReadyToPick

 END  
 COMMIT  TRANSACTION  
  
 END TRY      
 BEGIN CATCH        
  IF @@trancount > 0  
   PRINT 'ROLLBACK'  
   ROLLBACK TRAN;  
   DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()   
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------  
            , @AdhocComments     VARCHAR(150)    = 'GetExchangePickTicketPrint'   
            , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@ExchangeSalesOrderId, '') + ''',  
              @Parameter2 = ' + ISNULL(@ExchangeSalesOrderPartId,'') + ',   
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