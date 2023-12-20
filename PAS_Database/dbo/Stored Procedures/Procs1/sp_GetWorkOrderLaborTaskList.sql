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

     
 EXECUTE [sp_GetWOShippingParentList] 34, 39
**************************************************************/
CREATE       Procedure [dbo].[sp_GetWorkOrderLaborTaskList]
@WorkOrderLaborHeaderId  bigint
AS
BEGIN

	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;

		BEGIN TRY
		  BEGIN TRANSACTION
			BEGIN

	
					
				               SELECT 
					                 cast(wol.AdjustedHours as decimal(18,2)) AdjustedHours,
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
									 case when (select count(WorkOrderLaborTrackingId) FROM DBO.WorkOrderLaborTracking wolt WITH(NOLOCK) where wolt.WorkOrderLaborId= wol.WorkOrderLaborId) >0 then wol.IsBegin else NULL end as IsBeginTemp,
									 CASE WHEN wop.IsTraveler=1 then (select dbo.FN_GetCurrentLaborHours(wol.WorkOrderLaborId,0)) else wol.Hours end as Hours,
									 emp.FirstName + ' '+ emp.LastName as EmployeeName,
									 task.Description as Task,
									 expr.Description as Expertise
				FROM DBO.WorkOrderLabor wol WITH(NOLOCK)
					LEFT JOIN DBO.Task task  WITH(NOLOCK) on task.TaskId = wol.TaskId
					LEFT JOIN DBO.ExpertiseType expr WITH(NOLOCK) on expr.ExpertiseTypeId = wol.ExpertiseId
					LEFT JOIN DBO.Employee emp WITH(NOLOCK) on emp.EmployeeId = wol.EmployeeId
					INNER JOIN DBO.WorkOrderLaborHeader woh WITH(NOLOCK) on woh.WorkOrderLaborHeaderId = wol.WorkOrderLaborHeaderId
					INNER JOIN DBO.WorkOrderWorkFlow wfwo WITH(NOLOCK) ON wfwo.WorkFlowWorkOrderId = woh.WorkFlowWorkOrderId 
					INNER JOIN DBO.WorkOrderPartNumber wop WITH(NOLOCK) ON wfwo.WorkOrderPartNoId = wop.ID 
				WHERE wol.WorkOrderLaborHeaderId = @WorkOrderLaborHeaderId AND wol.IsDeleted = 0  order by IsBeginTemp desc
			END
		COMMIT  TRANSACTION

		END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
				PRINT 'ROLLBACK'
				ROLLBACK TRAN;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'sp_GetWorkOrderLaborTaskList' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@WorkOrderLaborHeaderId, '') + ''
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