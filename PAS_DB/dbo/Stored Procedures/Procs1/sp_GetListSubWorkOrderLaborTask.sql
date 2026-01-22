
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
	3    01/08/2025   Moin Bloch     Added StandardHours,StandardMinute,VarianceHours,VarianceMinute
	4	 22/01/2025	  Moin Bloch		Modified (Added WorkOrderTask Table For conditionally check table for Task)
     
 EXECUTE [sp_GetListSubWorkOrderLaborTask] 126
**************************************************************/
CREATE   PROCEDURE [dbo].[sp_GetListSubWorkOrderLaborTask]
@SubWorkOrderLaborHeaderId  BIGINT
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;
		BEGIN TRY
		 -- BEGIN TRANSACTION
			--BEGIN
			DECLARE	@WorkOrderId BIGINT = NULL   
			DECLARE @WorkOrderFormTypeId BIT = 0; 
			SELECT @WorkOrderId = WorkOrderId FROM [dbo].[SubWorkOrderLaborHeader] WITH(NOLOCK) WHERE [SubWorkOrderLaborHeaderId] = @SubWorkOrderLaborHeaderId;
			SELECT @WorkOrderFormTypeId = ISNULL([WorkOrderFormTypeId],0) FROM [dbo].[WorkOrder] WITH (NOLOCK) WHERE WorkOrderId = @WorkOrderId
			
				              SELECT wol.AdjustedHours,
                                     wol.Adjustments,
									 wol.StandardHours,
									 wol.StandardMinute,
									 wol.VarianceHours,
									 wol.VarianceMinute,
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
									 CASE WHEN (SELECT COUNT(SubWorkOrderLaborTrackingId) FROM DBO.SubWorkOrderLaborTracking wolt WITH(NOLOCK) WHERE wolt.SubWorkOrderLaborId = wol.SubWorkOrderLaborId) > 0 THEN wol.IsBegin ELSE NULL END AS IsBeginTemp,
									 CASE WHEN wop.IsTraveler = 1 THEN (SELECT dbo.FN_GetCurrentLaborHours(wol.SubWorkOrderLaborId,1)) ELSE wol.[Hours] END AS [Hours],
									 emp.FirstName + ' '+ emp.LastName AS EmployeeName,
									 --task.[Description] AS Task,
									 CASE WHEN @WorkOrderFormTypeId = 1 THEN WOT.[TaskName] ELSE task.[Description] END AS Task,
									 expr.[Description] AS Expertise
				FROM [dbo].[SubWorkOrderLabor] wol WITH(NOLOCK)
					LEFT JOIN [dbo].[Task] task  WITH(NOLOCK) ON task.TaskId = wol.TaskId
					LEFT JOIN [dbo].[SubWorkOrderTask] WOT WITH (NOLOCK) ON WOT.SubWorkOrderTaskId = wol.TaskId
					LEFT JOIN [dbo].[ExpertiseType] expr WITH(NOLOCK) ON expr.ExpertiseTypeId = wol.ExpertiseId
					LEFT JOIN [dbo].[Employee] emp WITH(NOLOCK) ON emp.EmployeeId = wol.EmployeeId
					INNER JOIN [dbo].[SubWorkOrderLaborHeader] lh WITH(NOLOCK) ON lh.SubWorkOrderLaborHeaderId = wol.SubWorkOrderLaborHeaderId 
					INNER JOIN [dbo].[SubWorkOrderPartNumber] wop WITH(NOLOCK) ON wop.SubWOPartNoId = lh.SubWOPartNoId 
				WHERE wol.SubWorkOrderLaborHeaderId = @SubWorkOrderLaborHeaderId AND wol.IsDeleted = 0 ORDER BY IsBeginTemp DESC 
		--	END
		--COMMIT  TRANSACTION

		END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
				PRINT 'ROLLBACK'
				--ROLLBACK TRAN;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'sp_GetSubWorkOrderLaborTaskList' 
			  , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = ''' + CAST(ISNULL(@SubWorkOrderLaborHeaderId, '') AS VARCHAR(100))  
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