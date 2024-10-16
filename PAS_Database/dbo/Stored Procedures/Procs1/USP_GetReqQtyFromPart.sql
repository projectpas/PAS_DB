﻿/*************************************************************                   
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
             
 EXECUTE USP_GetReqQtyFromPart 2688, 14760, 4378, 1      
**************************************************************/         
CREATE    PROCEDURE [dbo].[USP_GetReqQtyFromPart]
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
                LEFT JOIN [DBO].[SalesOrderPart] SOP WITH (NOLOCK) ON SOP.ItemMasterId = POP.ItemMasterId AND SOP.ConditionId = POP.ConditionId AND SOP.SalesOrderId = @ReferenceId    
                LEFT JOIN [DBO].[SalesOrderReserveParts] SORP WITH (NOLOCK) ON SORP.SalesOrderPartId = SOP.SalesOrderPartId  AND SORP.ItemMasterId = POP.ItemMasterId 
				LEFT JOIN [DBO].[Nha_Tla_Alt_Equ_ItemMapping] Nha WITH (NOLOCK) ON Nha.ItemMasterId = POP.ItemMasterId
                LEFT JOIN [DBO].[Nha_Tla_Alt_Equ_ItemMapping] MainNha WITH (NOLOCK) ON MainNha.MappingItemMasterId = POP.ItemMasterId
				LEFT JOIN [DBO].[SalesOrderPart] SOP_A WITH (NOLOCK) ON (SOP_A.ItemMasterId = Nha.MappingItemMasterId OR SOP_A.ItemMasterId = MainNha.ItemMasterId) AND SOP_A.ConditionId = POP.ConditionId AND SOP_A.SalesOrderId = @ReferenceId
                WHERE POP.PurchaseOrderPartRecordId = @PurchaseOrderPartRecordId-- AND SOP.SalesOrderId = @ReferenceId
				Group By SOP.QtyRequested,SORP.QtyToReserve)       
       
     WHEN @ModuleId = 1    
			THEN (SELECT DISTINCT CASE WHEN  ( (((ISNULL(SUM(CASE WHEN WOM.Quantity IS NOT NULL THEN WOM.Quantity ELSE WOM_A.Quantity END),0))  -  ((ISNULL(SUM(CASE WHEN WOM.TotalReserved IS NOT NULL THEN WOM.TotalReserved ELSE WOM_A.TotalReserved END),0))  +  (ISNULL(SUM(CASE WHEN WOM.TotalIssued IS NOT NULL THEN WOM.TotalIssued ELSE WOM_A.TotalIssued END),0))))  +   (ISNULL(SUM(CASE WHEN WOMK.Quantity IS NOT NULL THEN WOMK.Quantity ELSE WOMK_A.Quantity END),0))) - (SELECT ISNULL(SUM(Sl.QuantityAvailable), 0) FROM dbo.Stockline Sl where Sl.ItemMasterId = POP.ItemMasterId and Sl.ConditionId = POP.ConditionId  AND IsParent = 1 AND IsCustomerStock = 0) )  > 0 
				THEN ((((ISNULL(SUM(CASE WHEN WOM.Quantity IS NOT NULL THEN WOM.Quantity ELSE WOM_A.Quantity END),0))  -  ((ISNULL(SUM(CASE WHEN WOM.TotalReserved IS NOT NULL THEN WOM.TotalReserved ELSE WOM_A.TotalReserved END),0))  +  (ISNULL(SUM(CASE WHEN WOM.TotalIssued IS NOT NULL THEN WOM.TotalIssued ELSE WOM_A.TotalIssued END),0))))  +  (ISNULL(SUM(CASE WHEN WOMK.Quantity IS NOT NULL THEN WOMK.Quantity ELSE WOMK_A.Quantity END),0))) - (SELECT ISNULL(SUM(Sl.QuantityAvailable), 0) FROM dbo.Stockline Sl where Sl.ItemMasterId = POP.ItemMasterId and Sl.ConditionId = POP.ConditionId  AND IsParent = 1 AND IsCustomerStock = 0) ) ELSE 0 END
				FROM PurchaseOrderPart POP WITH (NOLOCK)  
				LEFT JOIN [DBO].[WorkOrderMaterials] WOM WITH (NOLOCK) ON WOM.ItemMasterId = POP.ItemMasterId AND WOM.ConditionCodeId = POP.ConditionId AND WOM.WorkOrderId = @ReferenceId   
				LEFT JOIN [DBO].[Nha_Tla_Alt_Equ_ItemMapping] Nha WITH (NOLOCK) ON Nha.ItemMasterId = POP.ItemMasterId
				LEFT JOIN [DBO].[Nha_Tla_Alt_Equ_ItemMapping] MainNha WITH (NOLOCK) ON MainNha.MappingItemMasterId = POP.ItemMasterId
				LEFT JOIN [DBO].[WorkOrderMaterials] WOM_A WITH (NOLOCK) ON (WOM_A.ItemMasterId = Nha.MappingItemMasterId OR WOM_A.ItemMasterId = MainNha.ItemMasterId) AND WOM_A.ConditionCodeId = POP.ConditionId AND WOM_A.WorkOrderId = @ReferenceId
				LEFT JOIN [DBO].[WorkOrderMaterialsKit] WOMK WITH (NOLOCK) ON WOMK.ItemMasterId = POP.ItemMasterId AND WOMK.ConditionCodeId = POP.ConditionId AND WOMK.WorkOrderId = @ReferenceId
				LEFT JOIN [DBO].[WorkOrderMaterialsKit] WOMK_A WITH (NOLOCK) ON (WOMK_A.ItemMasterId = Nha.MappingItemMasterId OR WOMK_A.ItemMasterId = MainNha.ItemMasterId) AND WOMK_A.ConditionCodeId = POP.ConditionId AND WOMK_A.WorkOrderId = @ReferenceId
				WHERE POP.PurchaseOrderPartRecordId = @PurchaseOrderPartRecordId 
				GROUP BY POP.ItemMasterId, POP.ConditionId)
     
       WHEN @ModuleId = 5      
             THEN (SELECT DISTINCT ISNULL(CASE WHEN SWP.Quantity IS NOT NULL THEN SWP.Quantity ELSE SWP_A.Quantity END, 0) + 
					ISNULL(CASE WHEN SWOMK.Quantity IS NOT NULL THEN SWOMK.Quantity ELSE SWOMK_A.Quantity END, 0)
                     FROM PurchaseOrderPart POP    WITH (NOLOCK)  
                     LEFT JOIN [DBO].[SubWorkOrderMaterials] SWP WITH (NOLOCK) ON SWP.ItemMasterId = POP.ItemMasterId AND SWP.ConditionCodeId = POP.ConditionId AND SWP.SubWorkOrderId = @ReferenceId
					 LEFT JOIN [DBO].[Nha_Tla_Alt_Equ_ItemMapping] Nha WITH (NOLOCK) ON Nha.ItemMasterId = POP.ItemMasterId
					 LEFT JOIN [DBO].[Nha_Tla_Alt_Equ_ItemMapping] MainNha WITH (NOLOCK) ON MainNha.MappingItemMasterId = POP.ItemMasterId
					 LEFT JOIN [DBO].[SubWorkOrderMaterials] SWP_A WITH (NOLOCK) ON (SWP_A.ItemMasterId = Nha.MappingItemMasterId OR SWP_A.ItemMasterId = MainNha.ItemMasterId) AND SWP_A.ConditionCodeId = POP.ConditionId AND SWP_A.SubWorkOrderId = @ReferenceId
					 LEFT JOIN [DBO].[SubWorkOrderMaterialsKit] SWOMK WITH (NOLOCK) ON SWOMK.ItemMasterId = POP.ItemMasterId AND SWOMK.ConditionCodeId = POP.ConditionId AND SWOMK.SubWorkOrderId = @ReferenceId
	  				 LEFT JOIN [DBO].[SubWorkOrderMaterialsKit] SWOMK_A WITH (NOLOCK) ON (SWOMK_A.ItemMasterId = Nha.MappingItemMasterId OR SWOMK_A.ItemMasterId = MainNha.ItemMasterId) AND SWOMK_A.ConditionCodeId = POP.ConditionId AND SWOMK_A.SubWorkOrderId = @ReferenceId
                     WHERE POP.PurchaseOrderPartRecordId = @PurchaseOrderPartRecordId)-- AND SWP.SubWorkOrderId = @ReferenceId)      
      
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