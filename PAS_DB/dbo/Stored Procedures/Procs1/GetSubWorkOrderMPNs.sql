/*************************************************************           
 ** File:   [GetSubWorkOrderMPNs]           
 ** Author:  Abhishek Jirawla
 ** Description: This stored procedure is used to Get sub work order MPNs
 ** Purpose:         
 ** Date:   20/05/2025
          
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date         Author			Change Description            
 ** --   ----------  -----------		-------------------------------- 
	1	 20/05/2025	  Abhishek Jirawla  Created
	2    01/July/2026			 RAJESH GAMI						[PN-17008] - Merge Non Stock Inventory to ItemMaster : Get only Stock Inventory Data Where IsNonStock = 0
	3    09/July/2026			 RAJESH GAMI						[PN-17009] - Merge Non-Stock Inventory to Stockline : Get only Stock Inventory Data Where IsNonStock = 0
************************************************************************/
CREATE   PROCEDURE [dbo].[GetSubWorkOrderMPNs]
    @SubWorkOrderId BIGINT
AS
BEGIN
    SET NOCOUNT ON;
	BEGIN TRY
		SELECT DISTINCT
			wop.ItemMasterId,
			im.PartNumber,
			wp.ManagementStructureId,
			im.PartDescription AS Description,
			ws.Description AS SubWorkOrderWorkscope,
			ISNULL(im.OverhaulHours, 0) + ISNULL(im.RPHours, 0) + ISNULL(im.mfgHours, 0) + ISNULL(im.TestHours, 0) AS NTE,
			wop.Quantity AS Qty,
			pri.Description AS SubWorkOrderPriority,
			stage.Stage AS SubWorkOrderStage,
			wop.SubWorkOrderScopeId,
			wop.SubWOPartNoId,
			ISNULL(sl.StockLineNumber, '') AS StockLineNo,
			ISNULL(sl.ControlNumber, '') AS ControllerNo,
			ISNULL(sl.IdNumber, '') AS IdNumber,
			wop.WorkflowId,
			ISNULL(wf.WorkOrderNumber, '') AS WorkFlowNo,
			im.IsPma AS isPMA,
			im.IsDER AS isDER,
			wop.SubWorkOrderStatusId,
			status.Status AS WorkOrderStatus,
			wop.IsClosed AS isWOClose,
			wop.IsFinishGood,
			wop.IsTraveler,
			wop.IsManualForm,
			CASE 
				WHEN wop.RevisedSerialNumber IS NOT NULL THEN wop.RevisedSerialNumber
				WHEN sl.SerialNumber IS NOT NULL THEN sl.SerialNumber
				ELSE ''
			END AS SerialNumber,
			CASE 
				WHEN wo.WorkOrderFormTypeId = 1 THEN CAST(1 AS BIT)
				ELSE CAST(0 AS BIT)
			END AS WorkOrderFormTypeId,
			CASE 
				WHEN wo.IsWoAlwaysOrOndemandId = 1 THEN CAST(1 AS BIT)
				ELSE CAST(0 AS BIT)
			END AS IsWoAlwaysOrOndemandId,
			CASE 
				WHEN wop.RevisedSerialNumber IS NOT NULL THEN CAST(1 AS BIT)
				WHEN sl.SerialNumber IS NOT NULL THEN CAST(1 AS BIT)
				ELSE CAST(0 AS BIT)
			END AS IsSerialNumber,
			CASE 
				WHEN wop.RevisedSerialNumber IS NOT NULL THEN wop.RevisedSerialNumber
				WHEN sl.SerialNumber IS NOT NULL THEN sl.SerialNumber
				WHEN sl.ControlNumber IS NOT NULL THEN sl.ControlNumber
				ELSE ''
			END AS ControlNumber
		FROM DBO.SubWorkOrderPartNumber wop WITH(NOLOCK) 
		INNER JOIN DBO.SubWorkOrder swo WITH(NOLOCK)  ON wop.SubWorkOrderId = swo.SubWorkOrderId
		INNER JOIN DBO.WorkOrder wo WITH(NOLOCK)  ON swo.WorkOrderId = wo.WorkOrderId
		INNER JOIN DBO.WorkOrderPartNumber wp WITH(NOLOCK)  ON swo.WorkOrderPartNumberId = wp.ID
		INNER JOIN DBO.ItemMaster im WITH(NOLOCK)  ON wop.ItemMasterId = im.ItemMasterId
		LEFT JOIN DBO.Workflow wf WITH(NOLOCK)  ON wop.WorkflowId = wf.WorkflowId
		INNER JOIN DBO.WorkScope ws WITH(NOLOCK)  ON wop.SubWorkOrderScopeId = ws.WorkScopeId
		INNER JOIN DBO.WorkOrderStage stage WITH(NOLOCK)  ON wop.SubWorkOrderStageId = stage.WorkOrderStageId
		INNER JOIN DBO.WorkOrderStatus status WITH(NOLOCK)  ON wop.SubWorkOrderStatusId = status.Id
		INNER JOIN DBO.Priority pri WITH(NOLOCK)  ON wop.SubWorkOrderPriorityId = pri.PriorityId
		LEFT JOIN DBO.StockLine sl WITH(NOLOCK)  ON wop.StockLineId = sl.StockLineId AND ISNULL(sl.IsNonStock,0) = 0
		WHERE ISNULL(wop.IsDeleted,0) = 0
		  AND wop.SubWorkOrderId = @SubWorkOrderId

	 AND ISNULL(im.IsNonStock,0) = 0
		   END TRY    
	BEGIN CATCH      
		SELECT  
        ERROR_NUMBER() AS ErrorNumber  
        ,ERROR_SEVERITY() AS ErrorSeverity  
        ,ERROR_STATE() AS ErrorState  
        ,ERROR_PROCEDURE() AS ErrorProcedure  
        ,ERROR_LINE() AS ErrorLine  
        ,ERROR_MESSAGE() AS ErrorMessage;  

		IF @@trancount > 0
			PRINT 'ROLLBACK'
			ROLLBACK TRAN;
			DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            , @AdhocComments     VARCHAR(150)    = 'GetSubWorkOrderMPNs' 
            , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ CAST(ISNULL(@SubWorkOrderId, '') AS VARCHAR(100)) + ''
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