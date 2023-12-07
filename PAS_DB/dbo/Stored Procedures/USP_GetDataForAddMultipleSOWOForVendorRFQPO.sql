/*************************************************************                     
 ** File:   [USP_GetDataForAddMultipleSOWOForVendorRFQPO]                     
 ** Author:   Shrey Chandegara        
 ** Description:         
 ** Purpose:                   
 ** Date:   13-10-2023                 
                    
 ** RETURN VALUE:                     
            
 **************************************************************                     
  ** Change History                     
 **************************************************************                     
 ** PR   Date         Author			Change Description                      
 ** --   --------     -------			--------------------------------                    
    1    17-11-2023   Shrey Chandegara  Created
	2    12/06/2023   Vishal Suthar		Modified to see work order from material KIT
               
 EXECUTE USP_GetDataForAddMultipleSOWOForVendorRFQPO 'loadeso',7,7,2114,3765        
**************************************************************/           
CREATE PROCEDURE [dbo].[USP_GetDataForAddMultipleSOWOForVendorRFQPO]
	@viewType VARCHAR (50) = NULL,        
	@ItemMasterId BIGINT,        
	@ConditionId BIGINT,        
	@VendorRFQPoId BIGINT,        
	@VendorRFQPPoPartId BIGINT        
AS        
BEGIN        
 SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED        
 SET NOCOUNT ON;        
  BEGIN TRY        
  BEGIN TRANSACTION        
   BEGIN         
        IF(@viewType = 'woview')        
        BEGIN        
			SELECT DISTINCT        
				IM.partnumber AS 'PartNumber',        
				C.Code AS 'Condition',        
				WO.WorkOrderNum AS 'ReferenceNum',        
				WO.WorkOrderId AS 'ReferenceId',        
				((((ISNULL(SUM(WOM.Quantity),0))-((ISNULL(SUM(WOM.TotalReserved),0))+(ISNULL(SUM(WOM.TotalIssued),0))))+(ISNULL(SUM(WOMK.Quantity),0)))) as RequestedQty,        
				WOP.PromisedDate AS 'PromisedDate',        
				WOP.EstimatedCompletionDate AS 'EstimatedCompletionDate',        
				WOP.EstimatedShipDate AS 'EstimatedShipDate',        
				@viewType AS 'ViewType'        
			FROM [WorkOrderMaterials] WOM WITH (NOLOCK)
			LEFT JOIN [DBO].[WorkOrder] WO WITH (NOLOCK) ON WO.WorkOrderId = WOM.WorkOrderId        
			LEFT JOIN [DBO].[WorkOrderMaterialsKit] WOMK WITH (NOLOCK) ON WOMK.ItemMasterId = @ItemMasterId AND WOMK.ConditionCodeId = @ConditionId AND WOMK.WorkOrderId = WOM.WorkOrderId  AND WOMK.WorkFlowWorkOrderId = WOM.WorkFlowWorkOrderId       
			LEFT JOIN [DBO].[WorkOrderPartNumber] WOP WITH (NOLOCK) ON WOP.WorkOrderId = WOM.WorkOrderId        
			LEFT JOIN [DBO].[ItemMaster] IM WITH (NOLOCK) ON IM.ItemMasterId = @ItemMasterId        
			LEFT JOIN [DBO].[Condition] C WITH (NOLOCK) ON C.ConditionId = @ConditionId        
			WHERE WOM.ItemMasterId = @ItemMasterId AND WOM.ConditionCodeId = @ConditionId         
			GROUP BY         
			WO.WorkOrderNum,        
			WOP.PromisedDate,        
			WOP.EstimatedCompletionDate,        
			WOP.EstimatedShipDate,IM.partnumber,C.code,WO.WorkOrderId        
			ORDER BY WO.WorkOrderId DESC        
        END
		ELSE IF(@viewType = 'soview')        
        BEGIN        
			SELECT DISTINCT        
				IM.partnumber AS 'PartNumber',        
				C.Code AS 'Condition',        
				SO.SalesOrderNumber AS 'ReferenceNum',        
				SO.SalesOrderId As 'ReferenceId',        
				ISNULL((ISNULL(SOP.QtyRequested ,0)- ISNULL(SUM(SOR.QtyToReserve),0)),0) as RequestedQty, -- ISNULL(SOP.qty ,0)  - ISNULL(SOP.QtyRequested ,0)) as RequestedQty,        
				SOP.PromisedDate AS 'PromisedDate',        
				SOP.CustomerRequestDate AS 'EstimatedCompletionDate',        
				SOP.EstimatedShipDate 'EstimatedShipDate',        
				@viewType AS 'ViewType'        
			FROM [SalesOrderPart] SOP WITH(NOLOCK)        
			LEFT JOIN [DBO].[SalesOrderReserveParts] SOR WITH (NOLOCK) ON SOR.SalesOrderPartId = SOP.SalesOrderPartId        
			LEFT JOIN [DBO].[SalesOrder] SO WITH (NOLOCK) ON SO.SalesOrderId = SOP.SalesOrderId        
			LEFT JOIN [DBO].[ItemMaster] IM WITH (NOLOCK) ON IM.ItemMasterId = @ItemMasterId        
			LEFT JOIN [DBO].[Condition] C WITH (NOLOCK) ON C.ConditionId = @ConditionId        
			WHERE SOP.ItemMasterId = @ItemMasterId AND SOP.ConditionId = @ConditionId        
			GROUP BY SOP.QtyRequested,SOR.QtyToReserve,SO.SalesOrderNumber,SO.SalesOrderId,  SOP.PromisedDate,SOP.CustomerRequestDate,SOP.EstimatedShipDate,IM.partnumber,C.Code        
			ORDER BY SO.SalesOrderId DESC        
		END        
		ELSE IF(@viewType = 'loadwo')        
		BEGIN        
			SELECT DISTINCT        
				IM.partnumber AS 'PartNumber',        
				C.Code AS 'Condition',        
				WO.WorkOrderNum AS 'ReferenceNum',        
				WO.WorkOrderId AS 'ReferenceId',        
				(((ISNULL(SUM(WOM.Quantity),0))-((ISNULL(SUM(WOM.TotalReserved),0))+(ISNULL(SUM(WOM.TotalIssued),0))))+(ISNULL(SUM(WOMK.Quantity),0))) as RequestedQty,        
				WOP.PromisedDate AS 'PromisedDate',        
				WOP.EstimatedCompletionDate AS 'EstimatedCompletionDate',        
				WOP.EstimatedShipDate AS 'EstimatedShipDate',        
				@viewType AS 'ViewType'        
			FROM [DBO].[WorkOrder] WO WITH (NOLOCK)         
			LEFT JOIN [WorkOrderMaterials] WOM WITH (NOLOCK) ON WO.WorkOrderId = WOM.WorkOrderId        
			LEFT JOIN [DBO].[WorkOrderMaterialsKit] WOMK WITH (NOLOCK) ON WOMK.ItemMasterId = @ItemMasterId AND WOMK.ConditionCodeId = @ConditionId AND WOMK.WorkOrderId = WO.WorkOrderId-- AND WOMK.WorkFlowWorkOrderId = WOM.WorkFlowWorkOrderId        
			LEFT JOIN [DBO].[WorkOrderPartNumber] WOP WITH (NOLOCK) ON WOP.WorkOrderId = WOM.WorkOrderId        
			LEFT JOIN [DBO].[ItemMaster] IM WITH (NOLOCK) ON IM.ItemMasterId = @ItemMasterId        
			LEFT JOIN [DBO].[Condition] C WITH (NOLOCK) ON C.ConditionId = @ConditionId        
			WHERE ((WOM.ItemMasterId = @ItemMasterId AND WOM.ConditionCodeId = @ConditionId) OR (WOMK.ItemMasterId = @ItemMasterId AND WOMK.ConditionCodeId = @ConditionId))
			GROUP BY         
			WO.WorkOrderNum,        
			WOP.PromisedDate,        
			WOP.EstimatedCompletionDate,        
			WOP.EstimatedShipDate,IM.partnumber,C.code,WO.WorkOrderId        
			ORDER BY WO.WorkOrderId DESC        
		END        
		ELSE IF(@viewType = 'loadso')        
        BEGIN        
			SELECT DISTINCT        
				IM.partnumber AS 'PartNumber',        
				C.Code AS 'Condition',        
				SO.SalesOrderNumber AS 'ReferenceNum',        
				SO.SalesOrderId As 'ReferenceId',        
				ISNULL((ISNULL(SOP.QtyRequested ,0)- ISNULL(SUM(SOR.QtyToReserve),0)),0) as RequestedQty,        
				SOP.PromisedDate AS 'PromisedDate',        
				SOP.CustomerRequestDate AS 'EstimatedCompletionDate',        
				SOP.EstimatedShipDate 'EstimatedShipDate',        
				@viewType AS 'ViewType'        
			FROM [SalesOrderPart] SOP WITH(NOLOCK)        
			LEFT JOIN [DBO].[SalesOrderReserveParts] SOR WITH (NOLOCK) ON SOR.SalesOrderPartId = SOP.SalesOrderPartId        
			LEFT JOIN [DBO].[SalesOrder] SO WITH (NOLOCK) ON SO.SalesOrderId = SOP.SalesOrderId        
			LEFT JOIN [DBO].[ItemMaster] IM WITH (NOLOCK) ON IM.ItemMasterId = @ItemMasterId        
			LEFT JOIN [DBO].[Condition] C WITH (NOLOCK) ON C.ConditionId = @ConditionId        
			WHERE SOP.ItemMasterId = @ItemMasterId AND SOP.ConditionId = @ConditionId        
			GROUP BY SOP.QtyRequested,SOR.QtyToReserve,SO.SalesOrderNumber,SO.SalesOrderId,  SOP.PromisedDate,SOP.CustomerRequestDate,SOP.EstimatedShipDate,IM.partnumber,C.Code        
			ORDER BY SO.SalesOrderId DESC        
		END        
		ELSE IF(@viewType = 'loadro')        
        BEGIN        
			SELECT DISTINCT        
				IM.partnumber AS 'PartNumber',        
				C.Code AS 'Condition',        
				RO.RepairOrderNumber AS 'ReferenceNum',        
				RO.RepairOrderId As 'ReferenceId',        
				0 as RequestedQty, -- ISNULL(SOP.qty ,0)  - ISNULL(SOP.QtyRequested ,0)) as RequestedQty,        
				NULL AS 'PromisedDate',        
				NULL AS 'EstimatedCompletionDate',        
				NULL 'EstimatedShipDate',        
				@viewType AS 'ViewType'        
			FROM [RepairOrderPart] ROP WITH(NOLOCK)        
			LEFT JOIN [DBO].[RepairOrder] RO WITH (NOLOCK) ON RO.RepairOrderId = ROP.RepairOrderId         
			LEFT JOIN [DBO].[ItemMaster] IM WITH (NOLOCK) ON IM.ItemMasterId = @ItemMasterId        
			LEFT JOIN [DBO].[Condition] C WITH (NOLOCK) ON C.ConditionId = @ConditionId        
			WHERE ROP.ItemMasterId = @ItemMasterId AND ROP.ConditionId = @ConditionId        
			ORDER BY RO.RepairOrderId DESC        
		END        
		ELSE IF(@viewType = 'loadeso')        
        BEGIN        
			SELECT DISTINCT        
				IM.partnumber AS 'PartNumber',        
				C.Code AS 'Condition',        
				ESO.ExchangeSalesOrderNumber AS 'ReferenceNum',        
				ESO.ExchangeSalesOrderId As 'ReferenceId',        
				ISNULL((ISNULL(ESOP.QtyRequested ,0)- ISNULL(SUM(SL.QuantityReserved),0)),0) as RequestedQty, -- ISNULL(SOP.qty ,0)  - ISNULL(SOP.QtyRequested ,0)) as RequestedQty,        
				NULL AS 'PromisedDate',        
				NULL AS 'EstimatedCompletionDate',        
				NULL 'EstimatedShipDate',        
				@viewType AS 'ViewType'        
			FROM [ExchangeSalesOrderPart] ESOP WITH(NOLOCK)        
			LEFT JOIN [DBO].[ExchangeSalesOrder] ESO WITH (NOLOCK) ON ESO.ExchangeSalesOrderId = ESOP.ExchangeSalesOrderId        
			LEFT JOIN [DBO].[Stockline] SL WITH (NOLOCK) ON SL.StockLineId = ESOP.StockLineId  
			LEFT JOIN [DBO].[ItemMaster] IM WITH (NOLOCK) ON IM.ItemMasterId = @ItemMasterId        
			LEFT JOIN [DBO].[Condition] C WITH (NOLOCK) ON C.ConditionId = @ConditionId        
			WHERE ESOP.ItemMasterId = @ItemMasterId AND ESOP.ConditionId = @ConditionId      
			GROUP BY IM.partnumber,C.Code,ESO.ExchangeSalesOrderNumber,ESO.ExchangeSalesOrderId,ESOP.QtyRequested,SL.QuantityReserved  
			ORDER BY ESO.ExchangeSalesOrderId DESC        
		END        
		ELSE IF(@viewType = 'loadswo')        
        BEGIN        
			SELECT DISTINCT        
				IM.partnumber AS 'PartNumber',        
				C.Code AS 'Condition',        
				SWO.SubWorkOrderNo AS 'ReferenceNum',        
				SWO.SubWorkOrderId As 'ReferenceId',        
				ISNULL(SWM.Quantity,0)  as RequestedQty, -- ISNULL(SOP.qty ,0)  - ISNULL(SOP.QtyRequested ,0)) as RequestedQty,        
				NULL AS 'PromisedDate',        
				NULL AS 'EstimatedCompletionDate',        
				NULL 'EstimatedShipDate',        
				@viewType AS 'ViewType'        
			FROM [SubWorkOrderMaterials] SWM  WITH(NOLOCK)        
			LEFT JOIN [DBO]. [SubWorkOrder] SWO WITH (NOLOCK) ON SWO.SubWorkOrderId = SWM.SubWorkOrderId        
			LEFT JOIN [DBO].[ItemMaster] IM WITH (NOLOCK) ON IM.ItemMasterId = @ItemMasterId        
			LEFT JOIN [DBO].[Condition] C WITH (NOLOCK) ON C.ConditionId = @ConditionId        
			WHERE SWM.ItemMasterId = @ItemMasterId AND SWM.ConditionCodeId = @ConditionId        
		END        
		ELSE         
		BEGIN        
			SELECT '' as PartNumber        
		END        
   END        
  COMMIT  TRANSACTION        
        
  END TRY            
  BEGIN CATCH              
   IF @@trancount > 0        
 --PRINT 'ROLLBACK'        
    ROLLBACK TRAN;        
    DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()         
        
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------        
              , @AdhocComments     VARCHAR(150)    = 'USP_GetDataForAddMultipleSOWOForVendorRFQPO'         
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@ItemMasterId, '') + ''        
              , @ApplicationName VARCHAR(100) = 'PAS'        
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------        
        
              exec spLogException         
                       @DatabaseName   = @DatabaseName        
                     , @AdhocComments   = @AdhocComments        
                     , @ProcedureParameters  = @ProcedureParameters        
                     , @ApplicationName         = @ApplicationName        
                     , @ErrorLogID = @ErrorLogID OUTPUT ;        
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)        
              RETURN(1);        
  END CATCH        
END