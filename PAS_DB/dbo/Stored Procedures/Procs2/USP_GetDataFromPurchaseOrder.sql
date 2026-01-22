/*************************************************************               
 ** File:   [USP_GetDataFromPurchaseOrder]               
 ** Author:   Vishal Suthar    
 ** Description: This SP is Used to get PO Part Reference based on Purchase Order Id        
 ** Purpose:             
 ** Date:   09/15/2023            
              
 ** RETURN VALUE:               
      
 **************************************************************               
  ** Change History               
 **************************************************************               
 ** PR   Date         Author   Change Description                
 ** --   --------     -------   --------------------------------              
    1    04/05/2023   Vishal Suthar  Created    
         
 EXECUTE USP_GetDataFromPurchaseOrder 1863  
**************************************************************/     
CREATE    PROCEDURE [dbo].[USP_GetDataFromPurchaseOrder]  
 @PurchaseOrderId BIGINT  
AS  
BEGIN  
 SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED  
 SET NOCOUNT ON;  
  BEGIN TRY  
  BEGIN TRANSACTION  
   BEGIN   
   DECLARE @CloseSOStatusId int = (SELECT TOP 1 ID FROM DBO.MasterSalesOrderStatus where Name ='Closed' AND IsActive = 1 AND IsDeleted = 0);
   ;WITH Result AS (  
    SELECT DISTINCT POR.ReferenceId as RefId,PurchaseOrderPartReferenceId,POR.ModuleId, POR.Qty AS Qty,  
    --ISNULL((CASE WHEN POR.ModuleId = 1 THEN (SELECT SUM(Stk.QuantityReserved) FROM DBO.Stockline Stk WITH (NOLOCK)   
    --      LEFT JOIN DBO.WorkOrderMaterials WOM ON WOM.WorkOrderMaterialsId = Stk.WorkOrderMaterialsId  
    --      WHERE WOM.WorkOrderId = POR.ReferenceId AND (Stk.PurchaseOrderPartRecordId = POP.PurchaseOrderPartRecordId OR PurchaseOrderPartRecordId IN (SELECT PurchaseOrderPartRecordId FROM [PurchaseOrderPart] WHERE ParentId = POP.PurchaseOrderPartRecordId)))   
    --  WHEN POR.ModuleId = 3 THEN (SELECT SUM(Stk.QuantityReserved) FROM DBO.Stockline Stk WITH (NOLOCK)   
    --      LEFT JOIN DBO.SalesOrderPart SOP ON SOP.SalesOrderPartId = Stk.SalesOrderPartId   
    --      WHERE SOP.SalesOrderId = POR.ReferenceId AND (Stk.PurchaseOrderPartRecordId = POP.PurchaseOrderPartRecordId OR PurchaseOrderPartRecordId IN (SELECT PurchaseOrderPartRecordId FROM [PurchaseOrderPart] WHERE ParentId = POP.PurchaseOrderPartRecordId)))   
    -- ELSE 0   
    --END), 0) AS QtyReserved,  
    ISNULL(POR.ReservedQty, 0) AS QtyReserved,  
    (SELECT SUM(Quantity) FROM Stockline WHERE PurchaseOrderId = @PurchaseOrderId AND (PurchaseOrderPartRecordId = POP.PurchaseOrderPartRecordId OR PurchaseOrderPartRecordId IN (SELECT PurchaseOrderPartRecordId FROM [PurchaseOrderPart] WHERE ParentId = POP.PurchaseOrderPartRecordId))) AS QtyReceived,  
    --WHERE PurchaseOrderId = @PurchaseOrderId AND PurchaseOrderPartRecordId = POP.PurchaseOrderPartRecordId) AS QtyReceived,  
    --((SELECT SUM(Quantity) FROM Stockline WHERE PurchaseOrderId = @PurchaseOrderId AND (PurchaseOrderPartRecordId = POP.PurchaseOrderPartRecordId OR PurchaseOrderPartRecordId IN (SELECT PurchaseOrderPartRecordId FROM [PurchaseOrderPart] WHERE ParentId = POP.PurchaseOrderPartRecordId))) -   
    --ISNULL((CASE WHEN POR.ModuleId = 1 THEN (SELECT SUM(Stk.QuantityReserved) FROM DBO.Stockline Stk WITH (NOLOCK)   
    --      LEFT JOIN DBO.WorkOrderMaterials WOM ON WOM.WorkOrderMaterialsId = Stk.WorkOrderMaterialsId  
    --      WHERE WOM.WorkOrderId = POR.ReferenceId AND (Stk.PurchaseOrderPartRecordId = POP.PurchaseOrderPartRecordId OR PurchaseOrderPartRecordId IN (SELECT PurchaseOrderPartRecordId FROM [PurchaseOrderPart] WHERE ParentId = POP.PurchaseOrderPartRecordId)))   
    --  WHEN POR.ModuleId = 3 THEN (SELECT SUM(Stk.QuantityReserved) FROM DBO.Stockline Stk WITH (NOLOCK)   
    --      LEFT JOIN DBO.SalesOrderPart SOP ON SOP.SalesOrderPartId = Stk.SalesOrderPartId   
    --      WHERE SOP.SalesOrderId = POR.ReferenceId AND (Stk.PurchaseOrderPartRecordId = POP.PurchaseOrderPartRecordId OR PurchaseOrderPartRecordId IN (SELECT PurchaseOrderPartRecordId FROM [PurchaseOrderPart] WHERE ParentId = POP.PurchaseOrderPartRecordId)))   
    -- ELSE 0   
    --END), 0)) AS QtyToBeReserved,  
    POP.PartNumber, POR.PurchaseOrderId, POR.PurchaseOrderPartId,
    CASE WHEN POR.ModuleId = 1 THEN 'Work Order'  
     WHEN POR.ModuleId = 2 THEN 'Repair Order'  
     WHEN POR.ModuleId = 3 THEN 'Sales Order'  
     WHEN POR.ModuleId = 4 THEN 'Exchange'  
     WHEN POR.ModuleId = 5 THEN 'Sub Work Order'  
     WHEN POR.ModuleId = 6 THEN 'Lot' ELSE NULL END AS ModuleName,  
    CASE WHEN POR.ModuleId = 1 THEN wo.WorkOrderNum   
     WHEN POR.ModuleId = 2 THEN ro.RepairOrderNumber  
     WHEN POR.ModuleId = 3 THEN so.SalesOrderNumber  
     WHEN POR.ModuleId = 4 THEN eso.ExchangeSalesOrderNumber   
     WHEN POR.ModuleId = 5 THEN sw.SubWorkOrderNo   
     WHEN POR.ModuleId = 6 THEN l.LotNumber ELSE  NULL END AS ReferenceId,  
    POR.RequestedQty  ,  SO.StatusId,SO.SalesOrderId
    FROM [PurchaseOrderPartReference] POR WITH (NOLOCK)   
    INNER JOIN [DBO].[PurchaseOrderPart] POP WITH (NOLOCK) ON POP.PurchaseOrderPartRecordId = POR.PurchaseOrderPartId  
    LEFT JOIN [DBO].[WorkOrder] wo WITH (NOLOCK) ON wo.WorkOrderId = POR.ReferenceId  
    LEFT JOIN [DBO].[RepairOrder] ro WITH (NOLOCK) ON ro.RepairOrderId = POR.ReferenceId  
    LEFT JOIN [DBO].[SalesOrder] so WITH (NOLOCK) ON so.SalesOrderId = POR.ReferenceId AND SO.StatusId != @CloseSOStatusId
    LEFT JOIN [DBO].[ExchangeSalesOrder] eso WITH (NOLOCK) ON eso.ExchangeSalesOrderId = POR.ReferenceId  
    LEFT JOIN [DBO].[Lot] l WITH (NOLOCK) ON l.LotId = POR.ReferenceId  
    LEFT JOIN [DBO].[SubWorkOrder] sw WITH (NOLOCK) ON sw.SubWorkOrderId = POR.ReferenceId  
    WHERE POR.PurchaseOrderId = @PurchaseOrderId  AND ISNULL(so.SalesOrderId,0) = (CASE WHEN POR.ModuleId = 3 AND ISNULL(so.SalesOrderId,0) = 0 THEN 1 ELSE ISNULL(so.SalesOrderId,0) END)
    AND ISNULL(POR.IssuedQty, 0) = 0)  
   SELECT *, (SELECT SUM(QTY) FROM Result) AS TotalQty INTO #TempTblPOPart FROM  Result   
     
   SELECT RefId, PurchaseOrderPartReferenceId, ModuleId, Qty, QtyReserved, QtyReceived, CASE WHEN QtyReceived > Qty THEN (Qty - QtyReserved) ELSE (QtyReceived - QtyReserved) END AS QtyToBeReserved, PartNumber, PurchaseOrderId, PurchaseOrderPartId,   
   ModuleName, ReferenceId, RequestedQty, TotalQty   ,StatusId,SalesOrderId
   FROM #TempTblPOPart;  
     
   END  
  COMMIT  TRANSACTION  
 END TRY      
 BEGIN CATCH        
  IF @@trancount > 0  
   ROLLBACK TRAN;  
   DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()   
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------  
            , @AdhocComments     VARCHAR(150)    = 'USP_GetDataFromPurchaseOrder'   
            , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@PurchaseOrderId, '') + ''  
            , @ApplicationName VARCHAR(100) = 'PAS'  
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------  
            exec spLogException   
                    @DatabaseName   = @DatabaseName  
                    , @AdhocComments   = @AdhocComments  
                    , @ProcedureParameters  = @ProcedureParameters  
                    , @ApplicationName         = @ApplicationName  
                    , @ErrorLogID              = @ErrorLogID OUTPUT ;  
            RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)  
            RETURN(1);  
 END CATCH  
END