--- EXEC sp_UpdatePurchaseOrderDetail 214  
CREATE    Procedure [dbo].[sp_UpdatePOPartReferenceDetail]  
 @PurchaseOrderPartId  bigint  
AS  
BEGIN  
 SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED  
 SET NOCOUNT ON    
 BEGIN TRY  
 BEGIN TRAN  
   
  
  UPDATE dbo.WorkOrderMaterials  
  SET   
  QtyOnOrder = POP.QuantityOrdered, QtyOnBkOrder = POP.QuantityBackOrdered, PONum = P.PurchaseOrderNumber ,POId = pop.PurchaseOrderId ,PONextDlvrDate = pop.EstDeliveryDate  
  from dbo.PurchaseOrderPart POP  
   JOIN dbo.PurchaseOrderPartReference PP ON PP.PurchaseOrderId = POP.PurchaseOrderId AND PP.PurchaseOrderPartId =  @PurchaseOrderPartId
  INNER JOIN dbo.WorkOrderMaterials WOM ON WOM.WorkOrderId = PP.ReferenceId and WOM.ConditionCodeId = POP.ConditionId and wom.ItemMasterId = pop.ItemMasterId  
  JOIN dbo.PurchaseOrder P ON P.PurchaseOrderId = POP.PurchaseOrderId  
  where POP.PurchaseOrderPartRecordId = @PurchaseOrderPartId  AND POP.isParent = 1 AND PP.ModuleId = 1 and ISNULL(POP.SubWorkOrderId,0)  = 0  AND PP.PurchaseOrderPartId =  @PurchaseOrderPartId
  
  --UPDATE dbo.WorkOrderMaterialsKit  
  --SET   
  --QtyOnOrder = POP.QuantityOrdered, QtyOnBkOrder = POP.QuantityBackOrdered, PONum = P.PurchaseOrderNumber, POId = pop.PurchaseOrderId, PONextDlvrDate = pop.EstDeliveryDate  
  --from dbo.PurchaseOrderPart POP 
  -- JOIN dbo.PurchaseOrderPartReference PP ON PP.PurchaseOrderId = POP.PurchaseOrderId AND PP.PurchaseOrderPartId =  @PurchaseOrderPartId
  --INNER JOIN dbo.WorkOrderMaterialsKit WOM ON WOM.WorkOrderId = POP.WorkOrderId and WOM.ConditionCodeId = POP.ConditionId and wom.ItemMasterId = pop.ItemMasterId  
  --JOIN dbo.PurchaseOrder P ON P.PurchaseOrderId = POP.PurchaseOrderId  
  --where POP.PurchaseOrderId = @PurchaseOrderPartId  AND POP.isParent = 1 AND POP.WorkOrderId > 0 and ISNULL(POP.SubWorkOrderId,0)  = 0  AND PP.PurchaseOrderPartId =  @PurchaseOrderPartId
  
  UPDATE dbo.SubWorkOrderMaterials  
  SET   
  QtyOnOrder = POP.QuantityOrdered, QtyOnBkOrder = POP.QuantityBackOrdered, PONum = P.PurchaseOrderNumber ,POId = pop.PurchaseOrderId ,PONextDlvrDate = pop.NeedByDate  
  from dbo.PurchaseOrderPart POP 
  JOIN dbo.PurchaseOrderPartReference PP ON PP.PurchaseOrderId = POP.PurchaseOrderId AND PP.PurchaseOrderPartId =  @PurchaseOrderPartId
  INNER JOIN dbo.SubWorkOrderMaterials WOM ON WOM.SubWorkOrderId = PP.ReferenceId and WOM.ConditionCodeId = POP.ConditionId and wom.ItemMasterId = pop.ItemMasterId  
  JOIN dbo.PurchaseOrder P ON P.PurchaseOrderId = POP.PurchaseOrderId  
  where POP.PurchaseOrderPartRecordId = @PurchaseOrderPartId  AND POP.isParent = 1 AND PP.ModuleId = 5    AND PP.PurchaseOrderPartId =  @PurchaseOrderPartId
  
  UPDATE dbo.SalesOrderPart  
  SET   
  --Qty = POP.QuantityOrdered,   
  PONumber = P.PurchaseOrderNumber, POId = pop.PurchaseOrderId, PONextDlvrDate = pop.NeedByDate  
  from dbo.PurchaseOrderPart POP  
  JOIN dbo.PurchaseOrderPartReference PP ON PP.PurchaseOrderId = POP.PurchaseOrderId AND PP.PurchaseOrderPartId =  @PurchaseOrderPartId
  INNER JOIN dbo.SalesOrderPart SOP ON SOP.SalesOrderId = PP.ReferenceId and SOP.ConditionId = POP.ConditionId and SOP.ItemMasterId = POP.ItemMasterId  
  JOIN dbo.PurchaseOrder P ON P.PurchaseOrderId = POP.PurchaseOrderId  
  where POP.PurchaseOrderPartRecordId = @PurchaseOrderPartId  AND POP.isParent = 1 AND PP.ModuleId = 3   AND PP.PurchaseOrderPartId =  @PurchaseOrderPartId
  
  UPDATE dbo.ExchangeSalesOrderPart  
  SET   
  --Qty = POP.QuantityOrdered,   
  PONumber = P.PurchaseOrderNumber, POId = pop.PurchaseOrderId, PONextDlvrDate = pop.NeedByDate  
  from dbo.PurchaseOrderPart POP  
  JOIN dbo.PurchaseOrderPartReference PP ON PP.PurchaseOrderId = POP.PurchaseOrderId AND PP.PurchaseOrderPartId =  @PurchaseOrderPartId
  INNER JOIN dbo.ExchangeSalesOrderPart SOP ON SOP.ExchangeSalesOrderId = PP.ReferenceId and SOP.ConditionId = POP.ConditionId and SOP.ItemMasterId = POP.ItemMasterId  
  JOIN dbo.PurchaseOrder P ON P.PurchaseOrderId = POP.PurchaseOrderId  
  where POP.PurchaseOrderPartRecordId = @PurchaseOrderPartId  AND POP.isParent = 1 AND PP.ModuleId = 4   AND PP.PurchaseOrderPartId =  @PurchaseOrderPartId
  
  SELECT  
  PurchaseOrderNumber as value  
  FROM dbo.PurchaseOrderPart PP WITH (NOLOCK)
  LEFT JOIN DBO.PurchaseOrder PO WITH (NOLOCK) ON PO.PurchaseOrderId = PP.PurchaseOrderId
  WHERE PP.PurchaseOrderPartRecordId = @PurchaseOrderPartId   
  
 COMMIT  TRANSACTION  
 END TRY      
 BEGIN CATCH        
  IF @@trancount > 0  
   PRINT 'ROLLBACK'  
   ROLLBACK TRAN;  
   DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()   
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------  
            , @AdhocComments     VARCHAR(150)    = 'sp_UpdatePurchaseOrderDetail'   
            , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@PurchaseOrderPartId, '') + ''  
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