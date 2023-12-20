
/*************************************************************           
 ** File:   [sp_GetListSubWorkOrderLaborTask]           
 ** Author:   Subhash Saliya
 ** Description: Get  for Work order Shipping List    
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

     
 EXECUTE [sp_GetListSubWorkOrderLaborTask] 34, 39
**************************************************************/
CREATE   Procedure [dbo].[sp_GetListSubWorkOrderLaborTask]
@SubWorkOrderLaborHeaderId  bigint
AS
BEGIN

	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;

		BEGIN TRY
		  BEGIN TRANSACTION
			BEGIN

				               SELECT 
					                 wol.AdjustedHours,
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
                                     wol.SubWorkOrderLaborHeaderId,
                                     wol.SubWorkOrderLaborId,
                                     wol.DirectLaborOHCost,
                                     wol.BurdaenRatePercentageId,
                                     wol.BurdenRateAmount,
                                     wol.TotalCostPerHour,
                                     wol.TotalCost,
									 wol.IsBegin,
									case when (select count(SubWorkOrderLaborTrackingId) FROM DBO.SubWorkOrderLaborTracking wolt WITH(NOLOCK) where wolt.SubWorkOrderLaborId= wol.SubWorkOrderLaborId) >0 then wol.IsBegin else NULL end as IsBeginTemp,
									 CASE WHEN wop.IsTraveler=1 then (select dbo.FN_GetCurrentLaborHours(wol.SubWorkOrderLaborId,1)) else wol.Hours end as Hours,
									 emp.FirstName + ' '+ emp.LastName as EmployeeName,
									 task.Description as Task,
									 expr.Description as Expertise
				FROM DBO.SubWorkOrderLabor wol WITH(NOLOCK)
					LEFT JOIN DBO.Task task  WITH(NOLOCK) on task.TaskId = wol.TaskId
					LEFT JOIN DBO.ExpertiseType expr WITH(NOLOCK) on expr.ExpertiseTypeId = wol.ExpertiseId
					LEFT JOIN DBO.Employee emp WITH(NOLOCK) on emp.EmployeeId = wol.EmployeeId
					INNER JOIN DBO.SubWorkOrderLaborHeader lh WITH(NOLOCK) ON lh.SubWorkOrderLaborHeaderId = wol.SubWorkOrderLaborHeaderId 
					INNER JOIN DBO.SubWorkOrderPartNumber wop WITH(NOLOCK) ON wop.SubWOPartNoId = lh.SubWOPartNoId 
				WHERE wol.SubWorkOrderLaborHeaderId = @SubWorkOrderLaborHeaderId AND wol.IsDeleted = 0 order by IsBeginTemp desc 
			END
		COMMIT  TRANSACTION

		END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
				PRINT 'ROLLBACK'
				ROLLBACK TRAN;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'sp_GetSubWorkOrderLaborTaskList' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@SubWorkOrderLaborHeaderId, '') + ''
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