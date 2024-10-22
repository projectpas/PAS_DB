
/*************************************************************           
 ** File:   [USP_GetSubWorkOrderMPNDetails]
 ** Author:   
 ** Description: This stored procedure is used to Get MPN details for Sub Work Order
 ** Purpose:         
 ** Date:    
          
 ** PARAMETERS: 
         
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date         Author				Change Description            
 ** --   --------     -------				--------------------------------          
    1    Unknown							Created
    2    15/10/2024  Abhishek Jirawla		Modified to return blank instead of GETDATE() for Promise, Ship Date and Completion Date

************************************************************************/

CREATE   PROCEDURE [dbo].[USP_GetSubWorkOrderMPNDetails]  
 @workOrderMaterialsId bigint,  
 @stocklineId bigint,  
 @workOrderPartNoId bigint  
AS  
BEGIN  
  
  SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED  
  SET NOCOUNT ON    
 BEGIN TRY  
   BEGIN TRANSACTION  
    BEGIN    
        SELECT 
				wom.WorkOrderMaterialsId,
                im.PartNumber,
                im.PartDescription,
                im.ManufacturerName,
                wom.ItemMasterId,
                wom.ConditionCodeId,
                woms.Quantity,
                woms.StocklineId,
				ISNULL(wop.WorKOrderScopeId, 0) AS 'SubWorkOrderScopeId',
				ISNULL(wop.WorkOrderStageId,0) AS 'SubWorkOrderStageId',
				ISNULL(wop.WorkOrderStatusId,0) AS 'SubWorkOrderStatusId',
				ISNULL(wop.WorkOrderPriorityId,0) AS 'SubWorkOrderPriorityId',
				ISNULL(wop.CustomerRequestDate,GETDATE()) AS 'CustomerRequestDate',
				ISNULL(wop.EstimatedCompletionDate, NULL) AS 'EstimatedCompletionDate',
				ISNULL(wop.EstimatedShipDate, NULL) AS 'EstimatedShipDate',
				ISNULL(wop.PromisedDate, NULL) AS 'PromisedDate',
				ISNULL(wop.CustomerRequestDate,GETDATE()) AS 'CustomerRequestDatempn',
				ISNULL(wop.PromisedDate,GETDATE()) AS 'PromisedDatempn',
				ISNULL(wop.EstimatedCompletionDate,GETDATE()) AS 'EstimatedCompletionDatempn',
				ISNULL(wop.EstimatedShipDate,GETDATE()) AS 'EstimatedShipDatempn',
				ISNULL(sl.SerialNumber,'') AS 'SerialNumber',
				ISNULL(sl.StockLineNumber,'') AS 'StockLineNumber',
				ISNULL(sl.ControlNumber,'') AS 'ControlNumber',
				ISNULL(sl.IdNumber,'') AS 'ControlerId',
				ISNULL(wop.IsDER,0) AS 'isDER',
				ISNULL(wop.IsPMA,0) AS 'isPMA',
				ISNULL(wop.IsMPNContract,0) AS 'isMPNContract',
				ISNULL(wop.TechStationId,0) AS 'techStationId',
				ISNULL(wop.TechnicianId,0) AS 'technicianId',
				ISNULL(wop.TATDaysCurrent,0) AS 'tatDaysCurrent',
				ISNULL(wop.TATDaysStandard,0) AS 'tatDaysStandard',
				ISNULL(rc.Condition,'') AS 'Condition',
				ISNULL(im.RevisedPart,'') AS 'RevisedPartNo',
				ISNULL(rc.ReceivingCustomerWorkId,0) AS 'ReceivingCustomerWorkId',
				ISNULL(rc.ReceivedDate,GETDATE()) AS 'ReceivedDate',
				ISNULL(rc.ReceivingNumber,'') AS 'ReceivingNumber',
				ISNULL(rc.Reference,'') AS 'CustomerReference',
				ISNULL(ig.ItemGroupCode,'') AS 'ItemGroup',
				wop.WorkflowId,
				CASE
					WHEN wop.WorkflowId > 0 THEN wf.WorkflowExpirationDate
					ELSE NULL END AS 'WorkflowExpirationDate',
				CASE
					WHEN wop.CMMId > 0 THEN pc.ExpirationDate
					ELSE NULL END AS 'publicatonExpirationDate',
				CASE 
					WHEN ws.WorkScopeCodeNew = 'OVERHAUL' OR ws.WorkScopeCodeNew = 'OH' THEN ISNULL(im.OverhaulHours,0)
					WHEN ws.WorkScopeCodeNew = 'REPAIR' OR ws.WorkScopeCodeNew = 'REP' THEN ISNULL(im.RPHours,0)
					WHEN ws.WorkScopeCodeNew = 'BENCHCHECK' THEN ISNULL(im.TestHours,0)
					WHEN ws.WorkScopeCodeNew = 'MFG' THEN ISNULL(im.mfgHours,0)
					ELSE 0 END AS 'nte'
		FROM [dbo].[WorkOrderMaterials] wom WITH(NOLOCK)
		LEFT JOIN [dbo].[ItemMaster] im WITH(NOLOCK) ON wom.ItemMasterId = im.ItemMasterId
		LEFT JOIN [dbo].[WorkOrderMaterialStockLine] woms WITH(NOLOCK) ON wom.WorkOrderMaterialsId = woms.WorkOrderMaterialsId AND woms.StockLineId = @stocklineId
		LEFT JOIN [dbo].[Condition] con WITH(NOLOCK) ON wom.ConditionCodeId = con.ConditionId
		LEFT JOIN [dbo].[ItemGroup] ig WITH(NOLOCK) ON im.ItemGroupId = ig.ItemGroupId
		LEFT JOIN [dbo].[ItemMaster] rp WITH(NOLOCK) ON im.RevisedPartId = rp.ItemMasterId
		LEFT JOIN [dbo].[Stockline] sl WITH(NOLOCK) ON woms.StockLineId = sl.StockLineId
		JOIN [dbo].[WorkOrderWorkFlow] wowf WITH(NOLOCK) ON wom.WorkFlowWorkOrderId = wowf.WorkFlowWorkOrderId
		JOIN [dbo].[WorkOrderPartNumber] wop WITH(NOLOCK) ON wowf.WorkOrderPartNoId = wop.ID
		LEFT JOIN [dbo].[ReceivingCustomerWork] rc WITH(NOLOCK) ON wop.ReceivingCustomerWorkId = rc.ReceivingCustomerWorkId
		LEFT JOIN [dbo].[Workflow] wf WITH(NOLOCK) ON wop.WorkflowId = wf.WorkflowId
		LEFT JOIN [dbo].[Publication] pc WITH(NOLOCK) ON wop.CMMId = pc.PublicationRecordId
		LEFT JOIN [dbo].[WorkScope] ws WITH(NOLOCK) ON wop.WorkOrderScopeId = ws.WorkScopeId AND ws.IsActive = 1 AND ws.IsDeleted = 0 
		WHERE wom.WorkOrderMaterialsId = @workOrderMaterialsId
          
    END  
   COMMIT  TRANSACTION  
  END TRY      
  BEGIN CATCH        
   IF @@trancount > 0  
    PRINT 'ROLLBACK'  
    ROLLBACK TRAN;  
    DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()   
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------  
              , @AdhocComments     VARCHAR(150)    = 'USP_GetSubWorkOrderMPNDetails'   
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@workOrderMaterialsId, '') + ''',  
                @Parameter2 = ' + ISNULL(@stocklineId, '') +'''  
                @Parameter3 = ' + ISNULL(@workOrderPartNoId, '') +''  
              , @ApplicationName VARCHAR(100) = 'PAS'  
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------  
              exec spLogException   
                       @DatabaseName   = @DatabaseName  
                     , @AdhocComments   = @AdhocComments  
                     , @ProcedureParameters  = @ProcedureParameters  
                     , @ApplicationName   = @ApplicationName  
                     , @ErrorLogID              = @ErrorLogID OUTPUT ;  
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)  
              RETURN(1);  
  END CATCH  
END