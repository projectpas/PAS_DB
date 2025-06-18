/*************************************************************           
 ** File:   [sp_GetWorkOrderLaborTaskList]           
 ** Author:   Subhash Saliya
 ** Description: Get  for Work order Labor List
 ** Purpose:         
 ** Date:   23-Feb-2021        
          
 ** PARAMETERS:           
 @POId varchar(60)   
         
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    02/23/2021   Subhash Saliya Created
	2    06/25/2020   Hemant  Saliya Added Transation & Content Management
	3    01/03/2025   Moin Bloch     Added StandardHours,StandardMinute,VarianceHours,VarianceMinute
	4    21/01/2025   Moin Bloch     Added [WorkOrderFormTypeId]
	5    18/06/2025   Devendra Shekh Hours Calculation Issue Resolved after new Changes for Labor Rename
	
 EXECUTE [sp_GetWorkOrderLaborTaskList] 3814
**************************************************************/
CREATE PROCEDURE [dbo].[sp_GetWorkOrderLaborTaskList]
@WorkOrderLaborHeaderId BIGINT
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;
		BEGIN TRY
	
				DECLARE @WorkOrderId BIGINT = 0
				DECLARE @WorkOrderFormTypeId BIT = 0
				DECLARE @LaborClockInOutTypeId INT = 2;
				SELECT @WorkOrderId = [WorkOrderId] FROM [dbo].[WorkOrderLaborHeader] WITH(NOLOCK) WHERE [WorkOrderLaborHeaderId] = @WorkOrderLaborHeaderId

				SELECT @WorkOrderFormTypeId = [WorkOrderFormTypeId] FROM [dbo].[WorkOrder] WITH(NOLOCK) WHERE [WorkOrderId] = @WorkOrderId;

				SELECT CAST(wol.AdjustedHours AS DECIMAL(18,2)) AdjustedHours,
                       wol.Adjustments,
                       wol.BillableId,
                       wol.CreatedBy,
                       wol.CreatedDate,
                       wol.EmployeeId,
                       wol.EndDate,
                       wol.ExpertiseId,
                       wol.TaskStatusId,
                       wol.StatusChangedDate,
					   wol.IsActive,
                       wol.IsDeleted,
                       wol.IsFromWorkFlow,
                       wol.Memo,
                       wol.StartDate,
                       wol.TaskId,
					   wol.UpdatedBy,
                       wol.UpdatedDate,
                       wol.WorkOrderLaborHeaderId,
                       wol.WorkOrderLaborId,
                       wol.DirectLaborOHCost,
                       wol.BurdaenRatePercentageId,
                       wol.BurdenRateAmount,
                       wol.TotalCostPerHour,
                       wol.TotalCost,
					   wol.IsBegin,
					   CASE WHEN (SELECT COUNT(WorkOrderLaborTrackingId) FROM DBO.WorkOrderLaborTracking wolt WITH(NOLOCK) WHERE wolt.WorkOrderLaborId= wol.WorkOrderLaborId) >0 THEN wol.IsBegin ELSE NULL END AS IsBeginTemp,
					   --CASE WHEN wop.IsTraeler = 1 THEN (SELECT dbo.FN_GetCurrentLaborHours(wol.WorkOrderLaborId,0)) ELSE wol.[Hours] END AS [Hours],
					   CASE WHEN ISNULL(woh.HoursorClockorScan, 0) = @LaborClockInOutTypeId THEN (SELECT dbo.FN_GetCurrentLaborHours(wol.WorkOrderLaborId,0)) ELSE wol.[Hours] END AS [Hours],
					   emp.FirstName + ' '+ emp.LastName AS EmployeeName,
					   --task.[Description] AS Task,
					   CASE WHEN @WorkOrderFormTypeId = 1 THEN WOT.[TaskName] ELSE task.[Description] END AS Task,
					   expr.[Description] AS Expertise,
					   wol.[StandardHours],
					   wol.[StandardMinute],
					   wol.[VarianceHours],
					   wol.[VarianceMinute]
				FROM [dbo].[WorkOrderLabor] wol WITH(NOLOCK)
					LEFT JOIN [dbo].[Task] task  WITH(NOLOCK) ON task.TaskId = wol.TaskId
					LEFT JOIN [dbo].[WorkOrderTask] WOT  WITH(NOLOCK) ON WOT.WorkOrderTaskId = wol.TaskId
					LEFT JOIN [dbo].[ExpertiseType] expr WITH(NOLOCK) ON expr.ExpertiseTypeId = wol.ExpertiseId
					LEFT JOIN [dbo].[Employee] emp WITH(NOLOCK) ON emp.EmployeeId = wol.EmployeeId
					INNER JOIN [dbo].[WorkOrderLaborHeader] woh WITH(NOLOCK) ON woh.WorkOrderLaborHeaderId = wol.WorkOrderLaborHeaderId
					INNER JOIN [dbo].[WorkOrderWorkFlow] wfwo WITH(NOLOCK) ON wfwo.WorkFlowWorkOrderId = woh.WorkFlowWorkOrderId 
					INNER JOIN [dbo].[WorkOrderPartNumber] wop WITH(NOLOCK) ON wfwo.WorkOrderPartNoId = wop.ID 
				WHERE wol.WorkOrderLaborHeaderId = @WorkOrderLaborHeaderId AND wol.IsDeleted = 0  ORDER BY IsBeginTemp DESC

		END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
				PRINT 'ROLLBACK'
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'sp_GetWorkOrderLaborTaskList' 
			  , @ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@WorkOrderLaborHeaderId, '') AS VARCHAR(100)) 
              , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------

              exec spLogException 
                       @DatabaseName           =  @DatabaseName
                     , @AdhocComments          =  @AdhocComments
                     , @ProcedureParameters	   =  @ProcedureParameters
                     , @ApplicationName        =  @ApplicationName
                     , @ErrorLogID             =  @ErrorLogID OUTPUT ;
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
              RETURN(1);
		END CATCH

END