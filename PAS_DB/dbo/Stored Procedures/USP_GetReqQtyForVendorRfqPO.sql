/*************************************************************               
 ** File:   [USP_GetReqQtyFromPart]               
 ** Author:   Shrey Chandegara    
 ** Description:         
 ** Purpose:             
 ** Date:   21-09-2023            
              
 ** RETURN VALUE:               
      
 **************************************************************               
  ** Change History               
 **************************************************************               
 ** PR   Date         Author   Change Description                
 ** --   --------     -------   --------------------------------              
    1    04/05/2023   Shrey Chandegara  Created    
         
 EXECUTE USP_GetReqQtyForVendorRfqPO 1839,3431,36,1  
**************************************************************/     
CREATE PROCEDURE [dbo].[USP_GetReqQtyForVendorRfqPO]  
	@VendorRFQPOPartRecordId BIGINT,  
	@ReferenceId BIGINT,  
	@ModuleId BIGINT  
AS  
BEGIN  
 SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED  
 SET NOCOUNT ON;  
	BEGIN TRY  
	BEGIN TRANSACTION  
	BEGIN   
		SELECT CASE 
			WHEN @ModuleId = 3  
				THEN (SELECT ISNULL(SOP.QtyRequested ,0)  
				FROM VendorRFQPurchaseOrderPart POP  
				LEFT JOIN [DBO].[SalesOrderPart] SOP WITH (NOLOCK) ON SOP.ItemMasterId = POP.ItemMasterId AND SOP.ConditionId = POP.ConditionId  
				WHERE POP.VendorRFQPOPartRecordId = @VendorRFQPOPartRecordId AND SOP.SalesOrderId = @ReferenceId)   
  
            WHEN @ModuleId = 1  
				THEN (SELECT ISNULL(WOMK.Quantity,0)  
                FROM VendorRFQPurchaseOrderPart POP  
                LEFT JOIN [DBO].[WorkOrderMaterials] WOM WITH (NOLOCK) ON WOM.ItemMasterId = POP.ItemMasterId AND WOM.ConditionCodeId = POP.ConditionId AND WOM.WorkOrderId = @ReferenceId
				LEFT JOIN [DBO].[WorkOrderMaterialsKit] WOMK WITH (NOLOCK) ON WOMK.ItemMasterId = POP.ItemMasterId AND WOMK.ConditionCodeId = POP.ConditionId AND WOMK.WorkOrderId = @ReferenceId
                WHERE POP.VendorRFQPOPartRecordId = @VendorRFQPOPartRecordId)  
  
			WHEN @ModuleId = 5  
				THEN (SELECT ISNULL(SWP.Quantity,0)  
				FROM VendorRFQPurchaseOrderPart POP  
				LEFT JOIN [DBO].[SubWorkOrderMaterials] SWP WITH (NOLOCK) ON SWP.ItemMasterId = POP.ItemMasterId AND SWP.ConditionCodeId = POP.ConditionId  
				WHERE POP.VendorRFQPOPartRecordId = @VendorRFQPOPartRecordId AND SWP.SubWorkOrderId = @ReferenceId)  
  
			ELSE 0 END AS 'ReqQty'  
   END  
  COMMIT  TRANSACTION  
  
  END TRY      
  BEGIN CATCH        
   IF @@trancount > 0  
    --PRINT 'ROLLBACK'  
    ROLLBACK TRAN;  
    DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()   
  
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------  
              , @AdhocComments     VARCHAR(150)    = 'USP_GetReqQtyForVendorRfqPO'   
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@VendorRFQPOPartRecordId, '') + ''  
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