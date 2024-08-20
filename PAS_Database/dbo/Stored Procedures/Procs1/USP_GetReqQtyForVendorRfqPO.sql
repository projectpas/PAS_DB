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
CREATE   PROCEDURE [dbo].[USP_GetReqQtyForVendorRfqPO]  
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
				THEN (SELECT ISNULL(CASE WHEN SOP.QtyRequested IS NOT NULL THEN SOP.QtyRequested ELSE SOP_A.QtyRequested END, 0)  
				FROM VendorRFQPurchaseOrderPart POP  
				LEFT JOIN [DBO].[SalesOrderPart] SOP WITH (NOLOCK) ON SOP.ItemMasterId = POP.ItemMasterId AND SOP.ConditionId = POP.ConditionId  
				LEFT JOIN [DBO].[Nha_Tla_Alt_Equ_ItemMapping] Nha WITH (NOLOCK) ON Nha.ItemMasterId = POP.ItemMasterId
                LEFT JOIN [DBO].[Nha_Tla_Alt_Equ_ItemMapping] MainNha WITH (NOLOCK) ON MainNha.MappingItemMasterId = POP.ItemMasterId
				LEFT JOIN [DBO].[SalesOrderPart] SOP_A WITH (NOLOCK) ON (SOP_A.ItemMasterId = Nha.MappingItemMasterId OR SOP_A.ItemMasterId = MainNha.ItemMasterId) AND SOP_A.ConditionId = POP.ConditionId
				WHERE POP.VendorRFQPOPartRecordId = @VendorRFQPOPartRecordId)-- AND SOP.SalesOrderId = @ReferenceId)   
  
            WHEN @ModuleId = 1  
				THEN (SELECT ISNULL(CASE WHEN WOM.Quantity IS NOT NULL THEN WOM.Quantity ELSE WOM_A.Quantity END,0)  
                FROM VendorRFQPurchaseOrderPart POP  
                LEFT JOIN [DBO].[WorkOrderMaterials] WOM WITH (NOLOCK) ON WOM.ItemMasterId = POP.ItemMasterId AND WOM.ConditionCodeId = POP.ConditionId AND WOM.WorkOrderId = @ReferenceId
				LEFT JOIN [DBO].[Nha_Tla_Alt_Equ_ItemMapping] Nha WITH (NOLOCK) ON Nha.ItemMasterId = POP.ItemMasterId
				LEFT JOIN [DBO].[Nha_Tla_Alt_Equ_ItemMapping] MainNha WITH (NOLOCK) ON MainNha.MappingItemMasterId = POP.ItemMasterId
				LEFT JOIN [DBO].[WorkOrderMaterials] WOM_A WITH (NOLOCK) ON (WOM_A.ItemMasterId = Nha.MappingItemMasterId OR WOM_A.ItemMasterId = MainNha.ItemMasterId) AND WOM_A.ConditionCodeId = POP.ConditionId AND WOM_A.WorkOrderId = @ReferenceId
				LEFT JOIN [DBO].[WorkOrderMaterialsKit] WOMK WITH (NOLOCK) ON WOMK.ItemMasterId = POP.ItemMasterId AND WOMK.ConditionCodeId = POP.ConditionId AND WOMK.WorkOrderId = @ReferenceId
                WHERE POP.VendorRFQPOPartRecordId = @VendorRFQPOPartRecordId)  
  
			WHEN @ModuleId = 5  
				THEN (SELECT ISNULL(CASE WHEN SWP.Quantity IS NOT NULL THEN SWP.Quantity ELSE SWP_A.Quantity END,0)  
				FROM VendorRFQPurchaseOrderPart POP  
				LEFT JOIN [DBO].[SubWorkOrderMaterials] SWP WITH (NOLOCK) ON SWP.ItemMasterId = POP.ItemMasterId AND SWP.ConditionCodeId = POP.ConditionId  
				LEFT JOIN [DBO].[Nha_Tla_Alt_Equ_ItemMapping] Nha WITH (NOLOCK) ON Nha.ItemMasterId = POP.ItemMasterId
				LEFT JOIN [DBO].[Nha_Tla_Alt_Equ_ItemMapping] MainNha WITH (NOLOCK) ON MainNha.MappingItemMasterId = POP.ItemMasterId
				LEFT JOIN [DBO].[SubWorkOrderMaterials] SWP_A WITH (NOLOCK) ON (SWP_A.ItemMasterId = Nha.MappingItemMasterId OR SWP_A.ItemMasterId = MainNha.ItemMasterId) AND SWP.ConditionCodeId = POP.ConditionId  
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