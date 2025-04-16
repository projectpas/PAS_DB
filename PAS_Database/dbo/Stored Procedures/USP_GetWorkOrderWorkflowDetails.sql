-- =============================================
-- Author:		HEMANT SALIYA	
-- Create date: 15-04-2025
-- Description:	This stored procedure is used to Detete kit Stockline 
-- =============================================

/*************************************************************   
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author				Change Description            
 ** --   --------     -------				--------------------------------          
    1    15-04-2025   HEMANT SALIYA			Created

	EXEC USP_GetWorkOrderWorkflowDetails 8635
**************************************************************/


CREATE   PROCEDURE [dbo].[USP_GetWorkOrderWorkflowDetails]
    @WorkOrderId INT
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
    SET NOCOUNT ON;
	BEGIN TRY
		DECLARE @QuoteStatusId INT;

		SET @QuoteStatusId = 5; -- Approved

		-- Temp table to hold distinct quote list
		SELECT DISTINCT 
			woq.WorkOrderId,
			woq.WorkOrderQuoteId,
			woqd.WOPartNoId,
			woq.QuoteStatusId
		INTO #QuoteList
		FROM dbo.WorkOrderQuote woq WITH(NOLOCK)
		INNER JOIN dbo.WorkOrderQuoteDetails woqd WITH(NOLOCK) ON woq.WorkOrderQuoteId = woqd.WorkOrderQuoteId
		WHERE woq.WorkOrderId = @WorkOrderId AND ISNULL(woqd.IsVersionIncrease, 0) = 0;

		-- Main query
		SELECT DISTINCT
			w.WorkFlowWorkOrderId AS value,
			w.WorkFlowWorkOrderNo AS label,
			w.WorkFlowWorkOrderId,
			wo.WorkOrderId,
			wop.ItemMasterId,
			wop.RevisedPartNumber AS RevisedPartNo,
			wop.WorkOrderStatusId,
			wop.IsClosed AS IsWOClose,
			wop.IsFinishGood,
			ISNULL(st.Status, '') AS Status,
			ISNULL(wf.WorkflowId, 0) AS WorkflowId,
			ISNULL(wf.WorkOrderNumber, '') AS WorkflowNo,
			CASE WHEN ISNULL(wop.RevisedSerialNumber, '') != '' THEN wop.RevisedPartNumber ELSE im.PartNumber END PartNumber,
			im.PartDescription AS Description,
			CASE WHEN ISNULL(wop.RevisedSerialNumber, '') != '' THEN wop.RevisedPartNumber + '-' + wop.RevisedSerialNumber ELSE wop.RevisedPartNumber + '-' + sl.ControlNumber END AS PartNumberLabel,
			im.ManufacturerName AS Manufacturer,
			ws.Description AS Workscope,
			wop.NTE,
			wop.Quantity AS Qty,
			pri.[Description] AS [priority],
			stage.Stage,
			wop.ID AS workOrderPartNumberId,
			wop.WorkOrderScopeId,
			wop.ID AS woPartNoId,
			sl.StockLineNumber AS StockLineNo,
			CASE WHEN ISNULL(wop.RevisedSerialNumber, '') != '' THEN wop.RevisedSerialNumber ELSE ISNULL(sl.ControlNumber, '') END AS ControlNumber,
			wop.ManagementStructureId,
			wop.IsTraveler,
			ISNULL(rc.Reference, '') AS CustomerReference,
			CASE 
				WHEN EXISTS (
					SELECT 1 FROM #QuoteList q 
					WHERE q.WOPartNoId = wop.ID AND q.QuoteStatusId = @QuoteStatusId
				) THEN 'Approved'
				ELSE ''
			END AS QuoteStatus,
			ISNULL((
				SELECT TOP 1 q.QuoteStatusId 
				FROM #QuoteList q 
				WHERE q.WOPartNoId = wop.ID
			), 0) AS QuoteStatusId,
			wop.WorkOrderStageId,
			CASE WHEN ISNULL(wop.RevisedSerialNumber, '') != '' THEN wop.RevisedSerialNumber ELSE ISNULL(sl.SerialNumber, '') END AS SerialNumber,
			wo.workOrderFormTypeId,
			wo.IsWoAlwaysOrOndemandId
		FROM [dbo].WorkOrderWorkFlow w WITH(NOLOCK)
			INNER JOIN [dbo].WorkOrderPartNumber wop WITH(NOLOCK) ON w.WorkOrderPartNoId = wop.ID
			INNER JOIN [dbo].WorkOrder wo WITH(NOLOCK) ON wop.WorkOrderId = wo.WorkOrderId
			INNER JOIN [dbo].ItemMaster im WITH(NOLOCK) ON wop.ItemMasterId = im.ItemMasterId
			LEFT JOIN  [dbo].Workflow wf WITH(NOLOCK) ON wop.WorkflowId = wf.WorkflowId
			INNER JOIN [dbo].WorkScope ws WITH(NOLOCK) ON wop.WorkOrderScopeId = ws.WorkScopeId
			INNER JOIN [dbo].WorkOrderStage stage WITH(NOLOCK) ON wop.WorkOrderStageId = stage.WorkOrderStageId
			INNER JOIN [dbo].[Priority] pri WITH(NOLOCK) ON wop.WorkOrderPriorityId = pri.PriorityId
			LEFT JOIN  [dbo].StockLine sl WITH(NOLOCK) ON wop.StockLineId = sl.StockLineId
			LEFT JOIN  [dbo].ReceivingCustomerWork rc WITH(NOLOCK) ON sl.StockLineId = rc.StockLineId
			LEFT JOIN WorkOrderStatus st WITH(NOLOCK) ON wop.WorkOrderStatusId = st.Id
		WHERE wop.IsDeleted = 0 
		  AND w.WorkOrderId = @WorkOrderId 
		  AND wop.WorkOrderId = @WorkOrderId 
		  AND wop.WorkOrderStatusId != 3; -- Not Cancelled

		DROP TABLE #QuoteList;
	END TRY 
	BEGIN CATCH      
		 IF @@trancount > 0		 
			DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            , @AdhocComments     VARCHAR(150)    = 'USP_GetWorkOrderWorkflowDetails' 
            , @ProcedureParameters VARCHAR(3000)  = ''
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