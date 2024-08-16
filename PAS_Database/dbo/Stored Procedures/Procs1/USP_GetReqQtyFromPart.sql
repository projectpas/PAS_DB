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
             
 EXECUTE USP_GetReqQtyFromPart 2627, 14599, 1073, 3      
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
       THEN (SELECT DISTINCT ISNULL((ISNULL(SUM(CASE WHEN SOP.QtyRequested IS NOT NULL THEN SOP.QtyRequested ELSE SOP_A.QtyRequested END),0)- ISNULL(SUM(SORP.QtyToReserve),0)),0)
                FROM PurchaseOrderPart POP  WITH (NOLOCK)    
                LEFT JOIN [DBO].[SalesOrderPart] SOP WITH (NOLOCK) ON SOP.ItemMasterId = POP.ItemMasterId AND SOP.ConditionId = POP.ConditionId  
                LEFT JOIN [DBO].[SalesOrderReserveParts] SORP WITH (NOLOCK) ON SORP.SalesOrderPartId = SOP.SalesOrderPartId  AND SORP.ItemMasterId = POP.ItemMasterId 
				LEFT JOIN [DBO].[Nha_Tla_Alt_Equ_ItemMapping] Nha WITH (NOLOCK) ON Nha.ItemMasterId = POP.ItemMasterId
                LEFT JOIN [DBO].[Nha_Tla_Alt_Equ_ItemMapping] MainNha WITH (NOLOCK) ON MainNha.MappingItemMasterId = POP.ItemMasterId
				LEFT JOIN [DBO].[SalesOrderPart] SOP_A WITH (NOLOCK) ON (SOP_A.ItemMasterId = Nha.MappingItemMasterId OR SOP_A.ItemMasterId = MainNha.ItemMasterId) AND SOP_A.ConditionId = POP.ConditionId
                WHERE POP.PurchaseOrderPartRecordId = @PurchaseOrderPartRecordId-- AND SOP.SalesOrderId = @ReferenceId
				Group By SOP.QtyRequested,SORP.QtyToReserve)       
       
     WHEN @ModuleId = 1    
             THEN (SELECT DISTINCT ISNULL((ISNULL(SUM(CASE WHEN SOP.QtyRequested IS NOT NULL THEN SOP.QtyRequested ELSE SOP_A.QtyRequested END),0)- ISNULL(SUM(SORP.QtyToReserve),0)),0)
					FROM PurchaseOrderPart POP  WITH (NOLOCK)    
					LEFT JOIN [DBO].[SalesOrderPart] SOP WITH (NOLOCK) ON SOP.ItemMasterId = POP.ItemMasterId AND SOP.ConditionId = POP.ConditionId AND SOP.SalesOrderId = @ReferenceId
					LEFT JOIN [DBO].[SalesOrderReserveParts] SORP WITH (NOLOCK) ON SORP.SalesOrderPartId = SOP.SalesOrderPartId  AND SORP.ItemMasterId = POP.ItemMasterId 
					LEFT JOIN [DBO].[Nha_Tla_Alt_Equ_ItemMapping] Nha WITH (NOLOCK) ON Nha.ItemMasterId = POP.ItemMasterId
					LEFT JOIN [DBO].[Nha_Tla_Alt_Equ_ItemMapping] MainNha WITH (NOLOCK) ON MainNha.MappingItemMasterId = POP.ItemMasterId
					LEFT JOIN [DBO].[SalesOrderPart] SOP_A WITH (NOLOCK) ON (SOP_A.ItemMasterId = Nha.MappingItemMasterId OR SOP_A.ItemMasterId = MainNha.ItemMasterId) AND SOP_A.ConditionId = POP.ConditionId  AND SOP_A.SalesOrderId = @ReferenceId
					WHERE POP.PurchaseOrderPartRecordId = @PurchaseOrderPartRecordId
					Group By SOP.QtyRequested,SORP.QtyToReserve)
     
       WHEN @ModuleId = 5      
             THEN (SELECT DISTINCT ISNULL(SWP.Quantity,0)      
                     FROM PurchaseOrderPart POP    WITH (NOLOCK)  
                     LEFT JOIN [DBO].[SubWorkOrderMaterials] SWP WITH (NOLOCK) ON SWP.ItemMasterId = POP.ItemMasterId AND SWP.ConditionCodeId = POP.ConditionId      
                     WHERE POP.PurchaseOrderPartRecordId = @PurchaseOrderPartRecordId AND SWP.SubWorkOrderId = @ReferenceId)      
      
       WHEN @ModuleId = 4      
             THEN (SELECT DISTINCT ISNULL(CASE WHEN ESP.QtyRequested IS NOT NULL THEN ESP.QtyRequested ELSE ESP_A.QtyRequested END,0)      
                     FROM PurchaseOrderPart POP    WITH (NOLOCK)  
                     LEFT JOIN [DBO].[ExchangeSalesOrderPart] ESP WITH (NOLOCK) ON ESP.ItemMasterId = POP.ItemMasterId AND ESP.ConditionId = POP.ConditionId AND ESP.ExchangeSalesOrderId = @ReferenceId
					 LEFT JOIN [DBO].[Nha_Tla_Alt_Equ_ItemMapping] Nha WITH (NOLOCK) ON Nha.ItemMasterId = POP.ItemMasterId
					 LEFT JOIN [DBO].[Nha_Tla_Alt_Equ_ItemMapping] MainNha WITH (NOLOCK) ON MainNha.MappingItemMasterId = POP.ItemMasterId
					 LEFT JOIN [DBO].[ExchangeSalesOrderPart] ESP_A WITH (NOLOCK) ON (ESP_A.ItemMasterId = Nha.MappingItemMasterId OR ESP_A.ItemMasterId = MainNha.ItemMasterId) AND ESP_A.ConditionId = POP.ConditionId  AND ESP_A.ExchangeSalesOrderId = @ReferenceId
                     WHERE POP.PurchaseOrderPartRecordId = @PurchaseOrderPartRecordId)      
      
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