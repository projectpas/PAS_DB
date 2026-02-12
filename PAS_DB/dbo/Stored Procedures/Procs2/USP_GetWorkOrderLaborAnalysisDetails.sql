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
	3    01/09/2025   Moin Bloch    Update Added StandardHours,StandardMinute,VarianceHours,VarianceMinute
	2    02/04/2026   Hemant Saliya Update Adjust -Ve Hours in Calculation
     
 EXECUTE USP_GetWorkOrderLaborAnalysisDetails 270, 254
 EXECUTE USP_GetWorkOrderLaborAnalysisDetails 4135, 3653,true

**************************************************************/ 
    
CREATE PROCEDURE [dbo].[USP_GetWorkOrderLaborAnalysisDetails]    
(    
@WorkOrderId BIGINT = NULL,   
@WorkOrderPartNoId BIGINT  = NULL,
@IsDetailView BIT = 0
)    
AS    
BEGIN    

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
SET NOCOUNT ON    

	BEGIN TRY
				DECLARE @WorkOrderFormTypeId BIT = 0;
				SELECT @WorkOrderFormTypeId = [WorkOrderFormTypeId] FROM [dbo].[WorkOrder] WITH(NOLOCK) WHERE [WorkOrderId] = @WorkOrderId;

				IF(@WorkOrderPartNoId = 0)
				BEGIN
					SELECT 
						im.partnumber AS PartNumber,
						im.PartDescription,
						im.RevisedPart AS RevisedPN,
						ISNULL(ISNULL(SUM(wl.[Hours]), 0) + ISNULL(SUM(wl.Adjustments), 0), 0) AS [Hours],
						ISNULL(ISNULL(SUM(wl.[Hours]), 0) + ISNULL(SUM(wl.Adjustments), 0), 0) - SUM(ISNULL(wfx.EstimatedHours,0)) AS [Adjustments],						
						ISNULL(SUM(wfx.EstimatedHours),0) AS [AdjustedHours],
						ISNULL(SUM(wl.StandardHours),0) AS StandardHours,
						ISNULL(SUM(wl.StandardMinute),0) AS StandardMinute,
						ISNULL(SUM(wl.VarianceHours),0) AS VarianceHours,	
						ISNULL(SUM(wl.VarianceMinute),0) AS VarianceMinute, 
						ISNULL(SUM(wl.BurdenRateAmount),0) AS BurdenRateAmount,
						CASE WHEN wl.BillableId = 1 THEN 'Billable' ELSE 'Non-Billable' END AS BillableOrNonBillable,
						c.[Name] AS Customer,
						wo.WorkOrderNum,
						ws.Stage,
						st.[Description] AS [Status],
						CASE WHEN @WorkOrderFormTypeId = 1 THEN WOT.[TaskName] ELSE t.[Description] END AS [Action],
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
						JOIN dbo.EmployeeExpertise ex WITH (NOLOCK) ON wl.ExpertiseId = ex.EmployeeExpertiseId	
						LEFT JOIN dbo.Task t WITH (NOLOCK) ON t.TaskId = wl.TaskId
						LEFT JOIN [dbo].[WorkOrderTask] WOT  WITH(NOLOCK) ON WOT.WorkOrderTaskId = wl.TaskId
						LEFT JOIN dbo.Employee emp WITH (NOLOCK) ON emp.EmployeeId = wl.EmployeeId
					WHERE wowf.WorkOrderId = @WorkOrderId AND wlh.IsDeleted = 0 AND wlh.IsActive = 1 --AND BillableId = 1
					GROUP BY im.partnumber,im.PartDescription,im.RevisedPart,c.[Name] ,wo.WorkOrderNum,ws.Stage,BillableId,
						st.[Description],t.[Description],ex.[Description],emp.FirstName + ' ' + emp.LastName,wl.EmployeeId,WOT.[TaskName]
				END
				IF(@WorkOrderPartNoId > 0)
				BEGIN
					;WITH LaborCTE AS(
						SELECT 
						im.partnumber AS PartNumber,
						im.PartDescription,
						im.RevisedPart AS RevisedPN,
						CASE WHEN AdjustedHours < 0 THEN -1 * FLOOR(ABS(AdjustedHours))
										   ELSE FLOOR(AdjustedHours)
									  END AS [Hours],

						CASE WHEN AdjustedHours < 0 THEN -1 * CONVERT(int, ROUND((ABS(AdjustedHours) - FLOOR(ABS(AdjustedHours))) * 100.0, 0))
										   ELSE CONVERT(int, ROUND((AdjustedHours - FLOOR(AdjustedHours)) * 100.0, 0))
									  END AS [Minutes],

						--CASE WHEN AdjustedHours < 0 THEN -1 * FLOOR(ABS(AdjustedHours))
						--				   ELSE FLOOR(AdjustedHours)
						--			  END AS [Hours],

						--CASE WHEN AdjustedHours < 0 THEN -1 * CONVERT(int, ROUND((ABS(AdjustedHours) - FLOOR(ABS(AdjustedHours))) * 100.0, 0))
						--				   ELSE CONVERT(int, ROUND((AdjustedHours - FLOOR(AdjustedHours)) * 100.0, 0))
						--			  END AS [Minutes],

						ISNULL(ISNULL(wl.[Hours], 0) + ISNULL(wl.Adjustments, 0), 0) AS [Adjustments],
						ISNULL(wl.StandardHours,0) AS StandardHours,
						ISNULL(wl.StandardMinute,0) AS StandardMinute,
						ISNULL(wl.VarianceHours,0) AS VarianceHours,	
						ISNULL(wl.VarianceMinute,0) AS VarianceMinute, 
						ISNULL(wl.BurdenRateAmount,0) AS BurdenRateAmount,
						CASE WHEN wl.BillableId = 1 THEN 'Billable' ELSE 'Non-Billable' END AS BillableOrNonBillable,
						c.[Name] AS Customer,
						wo.WorkOrderNum,
						ws.Stage,
						st.[Description] AS [Status],
					    CASE WHEN @WorkOrderFormTypeId = 1 THEN WOT.[TaskName] ELSE t.[Description] END AS [Action],
						ex.[Description] AS Expertise,
						emp.FirstName + ' ' + emp.LastName AS EmployeeName,
						wl.EmployeeId
						FROM dbo.WorkOrderLaborHeader wlh WITH (NOLOCK)
							JOIN dbo.WorkOrderLabor wl WITH (NOLOCK) ON wl.WorkOrderLaborHeaderId = wlh.WorkOrderLaborHeaderId
							JOIN dbo.WorkOrderWorkFlow wowf WITH (NOLOCK) ON wlh.WorkFlowWorkOrderId = wowf.WorkFlowWorkOrderId
							JOIN dbo.WorkOrderPartNumber wop WITH (NOLOCK) ON wowf.WorkOrderPartNoId = wop.ID
							JOIN dbo.WorkOrder wo WITH (NOLOCK) ON wlh.WorkOrderId = wo.WorkOrderId
							JOIN dbo.WorkOrderStage ws WITH (NOLOCK) ON ws.WorkOrderStageId = wop.WorkOrderStageId
							JOIN dbo.Customer c WITH (NOLOCK) ON c.CustomerId = wo.CustomerId
							JOIN dbo.ItemMaster im WITH (NOLOCK) ON im.ItemMasterId = wop.ItemMasterId
							JOIN dbo.WorkOrderStatus st WITH (NOLOCK) ON st.Id = wop.WorkOrderStatusId
							JOIN dbo.EmployeeExpertise ex WITH (NOLOCK) ON wl.ExpertiseId = ex.EmployeeExpertiseId	
							LEFT JOIN dbo.Task t WITH (NOLOCK) ON t.TaskId = wl.TaskId
							LEFT JOIN [dbo].[WorkOrderTask] WOT  WITH(NOLOCK) ON WOT.WorkOrderTaskId = wl.TaskId
							LEFT JOIN dbo.Employee emp WITH (NOLOCK) ON emp.EmployeeId = wl.EmployeeId
						WHERE wowf.WorkOrderId = @WorkOrderId AND wop.ID = @workOrderPartNoId AND wlh.IsDeleted = 0 AND wlh.IsActive = 1
					), 
					results As(
						SELECT
							SUM([Hours] * 60 + [Minutes]) AS TotalMinutes,
							lc.PartNumber AS PartNumber,
							lc.PartDescription,
							lc.RevisedPN,
							SUM([Hours]) As [Hours],
							SUM([Minutes]) As [Minutes],
							SUM([Hours]) + SUM([Minutes]) [Adjustments],
							0 AS [AdjustedHours],
							ISNULL(SUM(StandardHours),0) AS StandardHours,
							ISNULL(SUM(StandardMinute),0) AS StandardMinute,
							ISNULL(SUM(VarianceHours),0) AS VarianceHours,	
							ISNULL(SUM(VarianceMinute),0) AS VarianceMinute, 
							ISNULL(SUM(BurdenRateAmount),0) AS BurdenRateAmount,
							BillableOrNonBillable,
							Customer,
							WorkOrderNum,
							Stage,
							[Status],
							[Action],
							Expertise,
							EmployeeName,
							EmployeeId
						FROM LaborCTE lc
						GROUP BY PartNumber,PartDescription,RevisedPN,Customer ,WorkOrderNum,Stage, BillableOrNonBillable,
							Stage,Status,Expertise,EmployeeName ,EmployeeId,[Action])

					SELECT
						lc.PartNumber AS PartNumber,
						lc.PartDescription,
						lc.RevisedPN,	
						
						CAST(CAST((CASE WHEN SUM(TotalMinutes) < 0 THEN -1 ELSE 1 END) * (ABS(SUM(TotalMinutes)) / 60) AS INT) AS VARCHAR(20))
						+ '.'
						+ RIGHT('00' + CAST(ABS(SUM(TotalMinutes)) % 60 AS VARCHAR(2)), 2) AS [Hours],

						CAST(CAST((CASE WHEN SUM(TotalMinutes) < 0 THEN -1 ELSE 1 END) * (ABS(SUM(TotalMinutes)) / 60) AS INT) AS VARCHAR(20))
						+ '.'
						+ RIGHT('00' + CAST(ABS(SUM(TotalMinutes)) % 60 AS VARCHAR(2)), 2) AS [Adjustments],

						0 AS [AdjustedHours],
						ISNULL(SUM(StandardHours),0) AS StandardHours,
						ISNULL(SUM(StandardMinute),0) AS StandardMinute,
						ISNULL(SUM(VarianceHours),0) AS VarianceHours,	
						ISNULL(SUM(VarianceMinute),0) AS VarianceMinute, 
						ISNULL(SUM(BurdenRateAmount),0) AS BurdenRateAmount,
						BillableOrNonBillable,
						Customer,
						WorkOrderNum,
						Stage,
						[Status],
					    [Action],
						Expertise,
						EmployeeName,
						EmployeeId
					FROM results lc	
					GROUP BY PartNumber,PartDescription,RevisedPN,Customer ,WorkOrderNum,Stage, BillableOrNonBillable,
						Stage,Status,Expertise,EmployeeName ,EmployeeId,[Action]
				END
		END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
				PRINT 'ROLLBACK'
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