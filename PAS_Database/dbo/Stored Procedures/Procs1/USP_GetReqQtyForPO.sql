/*************************************************************                   
 ** File:   [USP_GetReqQtyForPO]                   
 ** Author:   Shrey Chandegara        
 ** Description:             
 ** Purpose:                 
 ** Date:   09-11-2023                
                  
 ** RETURN VALUE:                   
          
 **************************************************************                   
  ** Change History                   
 **************************************************************                   
 ** PR   Date         Author   Change Description                    
 ** --   --------     -------   --------------------------------                  
    1    09-11-2023   Shrey Chandegara  Created        
             
 EXECUTE USP_GetReqQtyForPO 3697,7,7      
**************************************************************/         
Create     PROCEDURE [dbo].[USP_GetReqQtyForPO]      
@WorkOrderId BIGINT,      
@ItemMasterId BIGINT,      
@ConditionId BIGINT   
AS      
BEGIN      
 SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED      
 SET NOCOUNT ON;      
   --DECLARE @ModuleId INT = NULL;      
   --SET @ModuleId = (SELECT ModuleId FROM  PurchaseOrderPartReference WHERE PurchaseOrderId = @PurchaseOrderId);      
  BEGIN TRY      
  BEGIN TRANSACTION      
   BEGIN       
             SELECT DISTINCT (    (((ISNULL(SUM(WOM.Quantity),0))  -     ((ISNULL(SUM(WOM.TotalReserved),0))  +    (ISNULL(SUM(WOM.TotalIssued),0))))  +   (ISNULL(SUM(WOMK.Quantity),0)))   )   AS 'ReqQty'    
                     FROM WorkOrder WO    WITH (NOLOCK)  
                     LEFT JOIN [DBO].[WorkOrderMaterials] WOM WITH (NOLOCK) ON WOM.ItemMasterId = @ItemMasterId AND WOM.ConditionCodeId = @ConditionId AND WOM.WorkOrderId = @WorkOrderId   
					 LEFT JOIN [DBO].[WorkOrderMaterialsKit] WOMK WITH (NOLOCK) ON WOMK.ItemMasterId = @ItemMasterId AND WOMK.ConditionCodeId = @ConditionId AND WOMK.WorkOrderId = @WorkOrderId AND WOMK.WorkFlowWorkOrderId = WOM.WorkFlowWorkOrderId   
                     WHERE WO.WorkOrderId = @WorkOrderId
                      
   END      
  COMMIT  TRANSACTION      
      
  END TRY          
  BEGIN CATCH            
   IF @@trancount > 0      
    --PRINT 'ROLLBACK'      
    ROLLBACK TRAN;     
    DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()       
      
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------      
              , @AdhocComments     VARCHAR(150)    = 'USP_GetReqQtyForPO'       
        , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@WorkOrderId, '') + ''      
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