/*************************************************************                   
 ** File:   [USP_GetReqQtyFromPart]                   
 ** Author:   Shrey Chandegara        
 ** Description:             
 ** Purpose:                 
 ** Date:   20-09-2023                
                  
 ** RETURN VALUE:                   
          
 **************************************************************                   
  ** Change History                   
 **************************************************************                   
 ** PR   Date         Author			Change Description                    
 ** --   --------     -------			--------------------------------                  
    1    04/05/2023   Shrey Chandegara  Created        
    2    12/06/2023   Vishal Suthar		Modified to see qty from material KIT        
             
 EXECUTE USP_GetReqQtyFromPart 2141, 3777, 3573, 1      
**************************************************************/         
CREATE   PROCEDURE [dbo].[USP_GetReqQtyFromPart]
	@PurchaseOrderId BIGINT,      
	@PurchaseOrderPartRecordId BIGINT,      
	@ReferenceId BIGINT,      
	@ModuleId BIGINT      
AS      
BEGIN      
 SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED      
 SET NOCOUNT ON;      
	DECLARE @ModuleddId BIGINT = NULL;      
	BEGIN TRY      
	BEGIN TRANSACTION      
	BEGIN       
	
	SELECT CASE WHEN @ModuleId = 3      
       THEN (SELECT DISTINCT ISNULL((ISNULL(SOP.QtyRequested ,0)- ISNULL(SUM(SORP.QtyToReserve),0)),0)
                FROM PurchaseOrderPart POP  WITH (NOLOCK)    
                LEFT JOIN [DBO].[SalesOrderPart] SOP WITH (NOLOCK) ON SOP.ItemMasterId = POP.ItemMasterId AND SOP.ConditionId = POP.ConditionId  
                LEFT JOIN [DBO].[SalesOrderReserveParts] SORP WITH (NOLOCK) ON SORP.SalesOrderPartId = SOP.SalesOrderPartId  AND SORP.ItemMasterId = POP.ItemMasterId 
                WHERE POP.PurchaseOrderPartRecordId = @PurchaseOrderPartRecordId AND SOP.SalesOrderId = @ReferenceId
				Group By SOP.QtyRequested,SORP.QtyToReserve)       
       
     WHEN @ModuleId = 1    
             THEN (SELECT DISTINCT CASE WHEN  ( (((ISNULL(SUM(WOM.Quantity),0))  -  ((ISNULL(SUM(WOM.TotalReserved),0))  +  (ISNULL(SUM(WOM.TotalIssued),0))))  +   (ISNULL(SUM(WOMK.Quantity),0))) - (SELECT ISNULL(SUM(Sl.QuantityAvailable), 0) FROM dbo.Stockline Sl where Sl.ItemMasterId = POP.ItemMasterId and Sl.ConditionId = POP.ConditionId  AND IsParent = 1 AND IsCustomerStock = 0) )  > 0 THEN  (    (((ISNULL(SUM(WOM.Quantity),0))  -  ((ISNULL(SUM(WOM.TotalReserved),0))  +  (ISNULL(SUM(WOM.TotalIssued),0))))  +  (ISNULL(SUM(WOMK.Quantity),0))) - (SELECT ISNULL(SUM(Sl.QuantityAvailable), 0) FROM dbo.Stockline Sl where Sl.ItemMasterId = POP.ItemMasterId and Sl.ConditionId = POP.ConditionId  AND IsParent = 1 AND IsCustomerStock = 0) ) ELSE 0 END
                     FROM PurchaseOrderPart POP    WITH (NOLOCK)  
                     LEFT JOIN [DBO].[WorkOrderMaterials] WOM WITH (NOLOCK) ON WOM.ItemMasterId = POP.ItemMasterId AND WOM.ConditionCodeId = POP.ConditionId AND WOM.WorkOrderId = @ReferenceId   
					 LEFT JOIN [DBO].[WorkOrderMaterialsKit] WOMK WITH (NOLOCK) ON WOMK.ItemMasterId = POP.ItemMasterId AND WOMK.ConditionCodeId = POP.ConditionId AND WOMK.WorkOrderId = @ReferenceId --AND WOMK.WorkFlowWorkOrderId = WOM.WorkFlowWorkOrderId   
                     WHERE POP.PurchaseOrderPartRecordId = @PurchaseOrderPartRecordId 
					 GROUP BY POP.ItemMasterId, POP.ConditionId)
     
       WHEN @ModuleId = 5      
             THEN (SELECT DISTINCT ISNULL(SWP.Quantity,0)      
                     FROM PurchaseOrderPart POP    WITH (NOLOCK)  
                     LEFT JOIN [DBO].[SubWorkOrderMaterials] SWP WITH (NOLOCK) ON SWP.ItemMasterId = POP.ItemMasterId AND SWP.ConditionCodeId = POP.ConditionId      
                     WHERE POP.PurchaseOrderPartRecordId = @PurchaseOrderPartRecordId AND SWP.SubWorkOrderId = @ReferenceId)      
      
       WHEN @ModuleId = 4      
             THEN (SELECT DISTINCT ISNULL(ESP.QtyRequested,0)      
                     FROM PurchaseOrderPart POP    WITH (NOLOCK)  
                     LEFT JOIN [DBO].[ExchangeSalesOrderPart] ESP WITH (NOLOCK) ON ESP.ItemMasterId = POP.ItemMasterId AND ESP.ConditionId = POP.ConditionId      
                     WHERE POP.PurchaseOrderPartRecordId = @PurchaseOrderPartRecordId AND ESP.ExchangeSalesOrderId = @ReferenceId)      
      
       WHEN @ModuleId = 2 THEN 0      
      
       WHEN @ModuleId = 6 THEN 0 ELSE 0 END AS 'ReqQty'
   END      
  COMMIT  TRANSACTION      
  END TRY          
  BEGIN CATCH            
   IF @@trancount > 0      
    ROLLBACK TRAN;     
    DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()       
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------      
			, @AdhocComments     VARCHAR(150)    = 'USP_GetReqQtyFromPart'       
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