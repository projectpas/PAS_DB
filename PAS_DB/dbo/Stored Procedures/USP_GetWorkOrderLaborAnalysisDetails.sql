
/*************************************************************           
 ** File:   [USP_GetWorkOrderLaborAnalysisDetails]           
 ** Author:   Hemant Saliya
 ** Description: This stored procedure is used retrieve WorkOrder Labor Analysis Details    
 ** Purpose:         
 ** Date:   02/22/2021        
          
 ** PARAMETERS:           
 @WorkOrderId BIGINT   
 @WFWOId BIGINT  
         
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    02/22/2021   Hemant Saliya Created
	2    01/19/2022   Hemant Saliya Update Calculated Values
     
 EXECUTE USP_GetWorkOrderLaborAnalysisDetails 270, 254
 EXECUTE USP_GetWorkOrderLaborAnalysisDetails 60, 67,false

**************************************************************/ 
    
CREATE PROCEDURE [dbo].[USP_GetWorkOrderLaborAnalysisDetails]    
(    
@WorkOrderId BIGINT = NULL,   
@WorkOrderPartNoId BIGINT  = NULL,
@IsDetailView BIT = false
)    
AS    
BEGIN    

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
SET NOCOUNT ON    

	BEGIN TRY
		BEGIN TRANSACTION
			BEGIN  
				IF(@WorkOrderPartNoId = 0)
				BEGIN
					SELECT 
						im.partnumber AS PartNumber,
						im.PartDescription,
						im.RevisedPart AS RevisedPN,
						ISNULL(ISNULL(SUM(wl.Hours), 0) + ISNULL(SUM(wl.Adjustments), 0), 0) AS [Hours],
						ISNULL(ISNULL(SUM(wl.Hours), 0) + ISNULL(SUM(wl.Adjustments), 0), 0) - SUM(ISNULL(wfx.EstimatedHours,0)) AS [Adjustments],
						--SUM(wl.Adjustments) AS [Adjustments],
						SUM(ISNULL(wfx.EstimatedHours,0)) AS [AdjustedHours],
						SUM(wl.BurdenRateAmount) AS BurdenRateAmount,
						CASE WHEN wl.BillableId = 1 THEN 'Billable' ELSE 'Non-Billable' END AS BillableOrNonBillable,
						c.Name AS Customer,
						wo.WorkOrderNum,
						ws.Stage,
						st.[Description] As [Status],
						t.[Description] As [Action],
						ex.[Description] AS Expertise,
						emp.FirstName + ' ' + emp.LastName AS EmployeeName,
						wl.EmployeeId
					FROM dbo.WorkOrderLaborHeader wlh WITH (NOLOCK)
						JOIN dbo.WorkOrderLabor wl WITH (NOLOCK) ON wl.WorkOrderLaborHeaderId = wlh.WorkOrderLaborHeaderId
						JOIN dbo.WorkOrderWorkFlow wowf WITH (NOLOCK) ON wlh.WorkFlowWorkOrderId = wowf.WorkFlowWorkOrderId
						JOIN dbo.WorkOrderPartNumber wop WITH (NOLOCK) ON wowf.WorkOrderId = wop.WorkOrderId
						JOIN dbo.WorkOrder wo WITH (NOLOCK) ON wlh.WorkOrderId = wo.WorkOrderId
						LEFT JOIN dbo.Workflow wf WITH (NOLOCK) ON wf.WorkflowId = wowf.WorkflowId and wf.WorkScopeId=wop.WorkOrderScopeId
						LEFT JOIN dbo.WorkflowExpertiseList wfx WITH (NOLOCK) ON wfx.WorkflowId = wowf.WorkflowId and wl.ExpertiseId= wfx.ExpertiseTypeId and wl.TaskId =wfx.TaskId 
						JOIN dbo.WorkOrderStage ws WITH (NOLOCK) ON ws.WorkOrderStageId = wop.WorkOrderStageId
						JOIN dbo.Customer c WITH (NOLOCK) ON c.CustomerId = wo.CustomerId
						JOIN dbo.ItemMaster im WITH (NOLOCK) ON im.ItemMasterId = wop.ItemMasterId
						JOIN dbo.WorkOrderStatus st WITH (NOLOCK) ON st.Id = wop.WorkOrderStatusId
						JOIN dbo.Task t WITH (NOLOCK) ON t.TaskId = wl.TaskId
						JOIN dbo.EmployeeExpertise ex WITH (NOLOCK) ON wl.ExpertiseId = ex.EmployeeExpertiseId	
						LEFT JOIN dbo.Employee emp WITH (NOLOCK) ON emp.EmployeeId = wl.EmployeeId
					WHERE wowf.WorkOrderId = @WorkOrderId AND wlh.IsDeleted = 0 AND wlh.IsActive = 1 --AND BillableId = 1
					GROUP BY im.partnumber,im.PartDescription,im.RevisedPart,c.Name ,wo.WorkOrderNum,ws.Stage,BillableId,
						st.[Description],t.[Description],ex.[Description],emp.FirstName + ' ' + emp.LastName,wl.EmployeeId
				END
				IF(@WorkOrderPartNoId > 0)
				BEGIN
					SELECT 
						im.partnumber AS PartNumber,
						im.PartDescription,
						im.RevisedPart AS RevisedPN,
						ISNULL(ISNULL(SUM(wl.Hours), 0) + ISNULL(SUM(wl.Adjustments), 0), 0) AS [Hours],
						ISNULL(ISNULL(SUM(wl.Hours), 0) + ISNULL(SUM(wl.Adjustments), 0), 0) - SUM(ISNULL(wfx.EstimatedHours,0)) AS [Adjustments],
						--SUM(wl.Adjustments) AS [Adjustments],
						SUM(ISNULL(wfx.EstimatedHours,0)) AS [AdjustedHours],
						SUM(wl.BurdenRateAmount) AS BurdenRateAmount,
						CASE WHEN wl.BillableId = 1 THEN 'Billable' ELSE 'Non-Billable' END AS BillableOrNonBillable,
						c.Name AS Customer,
						wo.WorkOrderNum,
						ws.Stage,
						st.[Description] As [Status],
						t.[Description] As [Action],
						ex.[Description] AS Expertise,
						emp.FirstName + ' ' + emp.LastName AS EmployeeName,
						wl.EmployeeId
					FROM dbo.WorkOrderLaborHeader wlh WITH (NOLOCK)
						JOIN dbo.WorkOrderLabor wl WITH (NOLOCK) ON wl.WorkOrderLaborHeaderId = wlh.WorkOrderLaborHeaderId
						JOIN dbo.WorkOrderWorkFlow wowf WITH (NOLOCK) ON wlh.WorkFlowWorkOrderId = wowf.WorkFlowWorkOrderId
						JOIN dbo.WorkOrderPartNumber wop WITH (NOLOCK) ON wowf.WorkOrderPartNoId = wop.ID
						JOIN dbo.WorkOrder wo WITH (NOLOCK) ON wlh.WorkOrderId = wo.WorkOrderId
						LEFT JOIN dbo.Workflow wf WITH (NOLOCK) ON wf.WorkflowId = wowf.WorkflowId and wf.WorkScopeId=wop.WorkOrderScopeId
						LEFT JOIN dbo.WorkflowExpertiseList wfx WITH (NOLOCK) ON wfx.WorkflowId = wowf.WorkflowId and wl.ExpertiseId= wfx.ExpertiseTypeId and wl.TaskId =wfx.TaskId 
						JOIN dbo.WorkOrderStage ws WITH (NOLOCK) ON ws.WorkOrderStageId = wop.WorkOrderStageId
						JOIN dbo.Customer c WITH (NOLOCK) ON c.CustomerId = wo.CustomerId
						JOIN dbo.ItemMaster im WITH (NOLOCK) ON im.ItemMasterId = wop.ItemMasterId
						JOIN dbo.WorkOrderStatus st WITH (NOLOCK) ON st.Id = wop.WorkOrderStatusId
						JOIN dbo.Task t WITH (NOLOCK) ON t.TaskId = wl.TaskId
						JOIN dbo.EmployeeExpertise ex WITH (NOLOCK) ON wl.ExpertiseId = ex.EmployeeExpertiseId	
						LEFT JOIN dbo.Employee emp WITH (NOLOCK) ON emp.EmployeeId = wl.EmployeeId
					WHERE wowf.WorkOrderId = @WorkOrderId AND wop.ID = @workOrderPartNoId AND wlh.IsDeleted = 0 AND wlh.IsActive = 1 --AND BillableId = 1
					GROUP BY im.partnumber,im.PartDescription,im.RevisedPart,c.Name ,wo.WorkOrderNum,ws.Stage, BillableId,
						st.[Description],t.[Description],ex.[Description],emp.FirstName + ' ' + emp.LastName,wl.EmployeeId
				END
				
			END
		COMMIT  TRANSACTION

		END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
				PRINT 'ROLLBACK'
				ROLLBACK TRAN;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_GetWorkOrderLaborAnalysisDetails' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@WorkOrderId, '') + ''', 
													   @Parameter2 = ' + ISNULL(@workOrderPartNoId ,'') +'''
													   @Parameter2 = ' + ISNULL(CAST(@isDetailView AS varchar(10)) ,'') +''
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