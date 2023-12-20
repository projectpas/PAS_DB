/*************************************************************           
 ** File:   [sp_GetWOShippingParentList]           
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

     
 EXECUTE [dbo].[sp_GetWorkOrderLaborHeader] 2730, 3221
**************************************************************/
CREATE     Procedure [dbo].[sp_GetWorkOrderLaborHeader]
@wfwoId  bigint,
@workOrderId bigint
AS
BEGIN

	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;

		BEGIN TRY
		  BEGIN TRANSACTION
			BEGIN
				               SELECT DISTINCT
					                 lh.CreatedBy,
                                     lh.CreatedDate,
                                     lh.DataEnteredBy,
                                     lh.EmployeeId,
                                     lh.HoursorClockorScan,
                                     lh.IsActive,
                                     lh.IsDeleted,
                                     lh.IsTaskCompletedByOne,
                                     lh.LabourMemo,
                                     lh.MasterCompanyId,
                                     lh.UpdatedBy,
                                     lh.UpdatedDate,
                                     lh.WorkFlowWorkOrderId,
                                     lh.WorkOrderHoursType,
                                     lh.WorkOrderId,
                                     lh.WorkOrderLaborHeaderId,
                                     lh.ExpertiseId,
                                     lh.TotalWorkHours,
									 wfwo.WorkFlowWorkOrderNo,
									 deby.FirstName + ' ' + deby.LastName as DataEnteredByName,			
									 emp.FirstName + ' '+ emp.LastName as EmployeeName,
									 expr.Description as ExpertiseType
				FROM DBO.WorkOrderLaborHeader lh WITH(NOLOCK)
					LEFT JOIN DBO.WorkOrderLabor WL  WITH(NOLOCK) on lh.WorkOrderLaborHeaderId = WL.WorkOrderLaborHeaderId
					LEFT JOIN DBO.Employee deby WITH(NOLOCK) on deby.EmployeeId = lh.DataEnteredBy
					LEFT JOIN DBO.ExpertiseType expr WITH(NOLOCK) on expr.ExpertiseTypeId = lh.ExpertiseId
					LEFT JOIN DBO.Employee emp WITH(NOLOCK) on emp.EmployeeId = lh.EmployeeId
					LEFT JOIN DBO.WorkOrderWorkFlow wfwo WITH(NOLOCK) ON wfwo.WorkFlowWorkOrderId = lh.WorkFlowWorkOrderId 
				WHERE lh.IsDeleted = 0 AND lh.WorkFlowWorkOrderId = @wfwoId 
			END
		COMMIT  TRANSACTION

		END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
				PRINT 'ROLLBACK'
				ROLLBACK TRAN;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'sp_GetWorkOrderLaborHeader' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@workOrderId, '') + ''
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