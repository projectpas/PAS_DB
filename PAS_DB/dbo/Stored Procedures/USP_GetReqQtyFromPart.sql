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
 ** PR   Date         Author   Change Description                  
 ** --   --------     -------   --------------------------------                
    1    04/05/2023   Shrey Chandegara  Created      
           
 EXECUTE USP_GetReqQtyFromPart 1898,3503,3632,1    
**************************************************************/       
Create    PROCEDURE [dbo].[USP_GetReqQtyFromPart]    
@PurchaseOrderId BIGINT,    
@PurchaseOrderPartRecordId BIGINT,    
@ReferenceId BIGINT,    
@ModuleId BIGINT    
AS    
BEGIN    
 SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED    
 SET NOCOUNT ON;    
   --DECLARE @ModuleId INT = NULL;    
   --SET @ModuleId = (SELECT ModuleId FROM  PurchaseOrderPartReference WHERE PurchaseOrderId = @PurchaseOrderId);    
  BEGIN TRY    
  BEGIN TRANSACTION    
   BEGIN     
    
    print @ModuleId
   SELECT CASE WHEN @ModuleId = 3    
       THEN (SELECT ISNULL(SOP.QtyRequested ,0)    
                FROM PurchaseOrderPart POP    
                LEFT JOIN [DBO].[SalesOrderPart] SOP WITH (NOLOCK) ON SOP.ItemMasterId = POP.ItemMasterId AND SOP.ConditionId = POP.ConditionId    
                WHERE POP.PurchaseOrderPartRecordId = @PurchaseOrderPartRecordId AND SOP.SalesOrderId = @ReferenceId)     
     
			  WHEN @ModuleId = 1  
             THEN (SELECT  ((ISNULL(WOM.Quantity,0) - (ISNULL(WOM.TotalReserved,0) + ISNULL(WOM.TotalIssued,0) )) + ISNULL(WOMK.Quantity,0))      
                     FROM PurchaseOrderPart POP    
                     LEFT JOIN [DBO].[WorkOrderMaterials] WOM WITH (NOLOCK) ON WOM.ItemMasterId = POP.ItemMasterId AND WOM.ConditionCodeId = POP.ConditionId AND WOM.WorkOrderId = @ReferenceId 
					 LEFT JOIN [DBO].[WorkOrderMaterialsKit] WOMK WITH (NOLOCK) ON WOMK.ItemMasterId = POP.ItemMasterId AND WOMK.ConditionCodeId = POP.ConditionId AND WOMK.WorkOrderId = @ReferenceId
                     WHERE POP.PurchaseOrderPartRecordId = @PurchaseOrderPartRecordId  )
    
       WHEN @ModuleId = 5    
             THEN (SELECT ISNULL(SWP.Quantity,0)    
                     FROM PurchaseOrderPart POP    
                     LEFT JOIN [DBO].[SubWorkOrderMaterials] SWP WITH (NOLOCK) ON SWP.ItemMasterId = POP.ItemMasterId AND SWP.ConditionCodeId = POP.ConditionId    
                     WHERE POP.PurchaseOrderPartRecordId = @PurchaseOrderPartRecordId AND SWP.SubWorkOrderId = @ReferenceId)    
    
       WHEN @ModuleId = 4    
             THEN (SELECT ISNULL(ESP.QtyRequested,0)    
                     FROM PurchaseOrderPart POP    
                     LEFT JOIN [DBO].[ExchangeSalesOrderPart] ESP WITH (NOLOCK) ON ESP.ItemMasterId = POP.ItemMasterId AND ESP.ConditionId = POP.ConditionId    
                     WHERE POP.PurchaseOrderPartRecordId = @PurchaseOrderPartRecordId AND ESP.ExchangeSalesOrderId = @ReferenceId)    
    
       WHEN @ModuleId = 2 THEN 0    
    
       WHEN @ModuleId = 6 THEN 0 ELSE 0 END AS 'ReqQty'    
                    
   END    
  COMMIT  TRANSACTION    
    
  END TRY        
  BEGIN CATCH          
   IF @@trancount > 0    
    --PRINT 'ROLLBACK'    
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