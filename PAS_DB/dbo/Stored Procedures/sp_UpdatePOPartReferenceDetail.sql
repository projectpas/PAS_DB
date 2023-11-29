/*************************************************************           
 ** File:   [sp_UpdatePOPartReferenceDetail]           
 ** Author:   -
 ** Description: This stored procedure is used to update different module data based on purchase order part reference
 ** Purpose:         
 ** Date:   10/19/2023        
          
 ** PARAMETERS:           
 @PurchaseOrderId BIGINT
         
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author			Change Description            
 ** --   --------     -------			--------------------------------          
    1    10/19/2023   Vishal Suthar		Added history
	
 EXEC sp_UpdatePOPartReferenceDetail 214  
**************************************************************/
CREATE   PROCEDURE [dbo].[sp_UpdatePOPartReferenceDetail]  
 @PurchaseOrderPartId  bigint  
AS  
BEGIN  
 SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED  
 SET NOCOUNT ON    
 BEGIN TRY  
 BEGIN TRAN
	UPDATE dbo.WorkOrderMaterials  
	SET   
	QtyOnOrder = POP.QuantityOrdered, QtyOnBkOrder = CASE WHEN (ISNULL(WOM.Quantity, 0) - (ISNULL(WOM.QuantityReserved, 0) + ISNULL(WOM.QuantityIssued, 0))) < ISNULL(PP.Qty, 0)
		THEN (ISNULL(WOM.Quantity, 0) - (ISNULL(WOM.QuantityReserved, 0) + ISNULL(WOM.QuantityIssued, 0))) 
		ELSE ISNULL(PP.Qty, 0)
	END, 
	PONum = P.PurchaseOrderNumber ,POId = pop.PurchaseOrderId ,PONextDlvrDate = pop.EstDeliveryDate  
	from dbo.PurchaseOrderPart POP WITH (NOLOCK) 
	LEFT JOIN dbo.PurchaseOrderPartReference PP WITH (NOLOCK) ON PP.PurchaseOrderId = POP.PurchaseOrderId AND PP.PurchaseOrderPartId =  @PurchaseOrderPartId
	INNER JOIN dbo.WorkOrderMaterials WOM WITH (NOLOCK) ON WOM.WorkOrderId = PP.ReferenceId and WOM.ConditionCodeId = POP.ConditionId and wom.ItemMasterId = pop.ItemMasterId  
	JOIN dbo.PurchaseOrder P WITH (NOLOCK) ON P.PurchaseOrderId = POP.PurchaseOrderId  
	WHERE POP.PurchaseOrderPartRecordId = @PurchaseOrderPartId  AND POP.isParent = 1 AND PP.ModuleId = 1 and ISNULL(POP.SubWorkOrderId,0)  = 0  AND PP.PurchaseOrderPartId =  @PurchaseOrderPartId
  
	UPDATE dbo.WorkOrderMaterialsKit  
	SET   
	QtyOnOrder = POP.QuantityOrdered, QtyOnBkOrder = CASE WHEN (ISNULL(WOM.Quantity, 0) - (ISNULL(WOM.QuantityReserved, 0) + ISNULL(WOM.QuantityIssued, 0))) < ISNULL(PP.Qty, 0)
		THEN (ISNULL(WOM.Quantity, 0) - (ISNULL(WOM.QuantityReserved, 0) + ISNULL(WOM.QuantityIssued, 0))) 
		ELSE ISNULL(PP.Qty, 0)
	END, PONum = P.PurchaseOrderNumber, POId = pop.PurchaseOrderId, PONextDlvrDate = pop.EstDeliveryDate  
	FROM dbo.PurchaseOrderPart POP WITH (NOLOCK)
	LEFT JOIN dbo.PurchaseOrderPartReference PP WITH (NOLOCK) ON PP.PurchaseOrderId = POP.PurchaseOrderId AND PP.PurchaseOrderPartId =  @PurchaseOrderPartId
	INNER JOIN dbo.WorkOrderMaterialsKit WOM WITH (NOLOCK) ON WOM.WorkOrderId = POP.WorkOrderId and WOM.ConditionCodeId = POP.ConditionId and wom.ItemMasterId = pop.ItemMasterId  
	JOIN dbo.PurchaseOrder P WITH (NOLOCK) ON P.PurchaseOrderId = POP.PurchaseOrderId  
	WHERE POP.PurchaseOrderId = @PurchaseOrderPartId  AND POP.isParent = 1 AND POP.WorkOrderId > 0 and ISNULL(POP.SubWorkOrderId,0)  = 0  AND PP.PurchaseOrderPartId =  @PurchaseOrderPartId
  
	UPDATE dbo.SubWorkOrderMaterials  
	SET QtyOnOrder = POP.QuantityOrdered, QtyOnBkOrder = POP.QuantityBackOrdered, PONum = P.PurchaseOrderNumber ,POId = pop.PurchaseOrderId ,PONextDlvrDate = pop.NeedByDate  
	FROM dbo.PurchaseOrderPart POP WITH (NOLOCK)
	LEFT JOIN dbo.PurchaseOrderPartReference PP WITH (NOLOCK) ON PP.PurchaseOrderId = POP.PurchaseOrderId AND PP.PurchaseOrderPartId =  @PurchaseOrderPartId
	INNER JOIN dbo.SubWorkOrderMaterials WOM WITH (NOLOCK) ON WOM.SubWorkOrderId = PP.ReferenceId and WOM.ConditionCodeId = POP.ConditionId and wom.ItemMasterId = pop.ItemMasterId  
	JOIN dbo.PurchaseOrder P WITH (NOLOCK) ON P.PurchaseOrderId = POP.PurchaseOrderId  
	WHERE POP.PurchaseOrderPartRecordId = @PurchaseOrderPartId  AND POP.isParent = 1 AND PP.ModuleId = 5    AND PP.PurchaseOrderPartId =  @PurchaseOrderPartId
  
	UPDATE dbo.SalesOrderPart  
	SET PONumber = P.PurchaseOrderNumber, POId = pop.PurchaseOrderId, PONextDlvrDate = pop.NeedByDate  
	FROM dbo.PurchaseOrderPart POP WITH (NOLOCK)
	LEFT JOIN dbo.PurchaseOrderPartReference PP WITH (NOLOCK) ON PP.PurchaseOrderId = POP.PurchaseOrderId AND PP.PurchaseOrderPartId =  @PurchaseOrderPartId
	INNER JOIN dbo.SalesOrderPart SOP WITH (NOLOCK) ON SOP.SalesOrderId = PP.ReferenceId and SOP.ConditionId = POP.ConditionId and SOP.ItemMasterId = POP.ItemMasterId  
	JOIN dbo.PurchaseOrder P WITH (NOLOCK) ON P.PurchaseOrderId = POP.PurchaseOrderId  
	WHERE POP.PurchaseOrderPartRecordId = @PurchaseOrderPartId  AND POP.isParent = 1 AND PP.ModuleId = 3   AND PP.PurchaseOrderPartId =  @PurchaseOrderPartId
  
	UPDATE dbo.ExchangeSalesOrderPart  
	SET PONumber = P.PurchaseOrderNumber, POId = pop.PurchaseOrderId, PONextDlvrDate = pop.NeedByDate  
	FROM dbo.PurchaseOrderPart POP WITH (NOLOCK)  
	LEFT JOIN dbo.PurchaseOrderPartReference PP WITH (NOLOCK) ON PP.PurchaseOrderId = POP.PurchaseOrderId AND PP.PurchaseOrderPartId =  @PurchaseOrderPartId
	INNER JOIN dbo.ExchangeSalesOrderPart SOP WITH (NOLOCK) ON SOP.ExchangeSalesOrderId = PP.ReferenceId and SOP.ConditionId = POP.ConditionId and SOP.ItemMasterId = POP.ItemMasterId  
	JOIN dbo.PurchaseOrder P WITH (NOLOCK) ON P.PurchaseOrderId = POP.PurchaseOrderId  
	WHERE POP.PurchaseOrderPartRecordId = @PurchaseOrderPartId  AND POP.isParent = 1 AND PP.ModuleId = 4   AND PP.PurchaseOrderPartId =  @PurchaseOrderPartId
  
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