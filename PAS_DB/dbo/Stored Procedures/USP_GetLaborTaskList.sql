-----------------------------------------------------------------------------------------------------

/*************************************************************           
 ** File:   [USP_GetLaborTaskList]           
 ** Author:   Subhash Saliya
 ** Description: This stored procedure is used Create Stockline ForCustomer RMA   
 ** Purpose:         
 ** Date:   01/03/2023        
          
 ** PARAMETERS:           
 @UserType varchar(60)   
         
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    01/03/2023   Subhash Saliya		Created
     
-- EXEC [USP_GetTravelerSetupList] 44
**************************************************************/

Create           PROCEDURE [dbo].[USP_GetLaborTaskList]
 @WorkFlowWorkOrderId bigint,
 @WorkOrderId bigint
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;

		BEGIN TRY
		BEGIN TRANSACTION
			BEGIN  
				SELECT [WorkOrderLaborId]
                ,wl.[TaskId]
                ,[Hours]
                ,wl.[Memo]
                ,wl.[CreatedDate]
                ,TaskInstruction as TaskInstruction
	            ,UPPER(T.Description) as Task
	            ,T.Memo as TaskMeno
	            ,UPPER(EL.FirstName +' '+ EL.LastName) as EmployeeName
				,dbo.InitCap(EEX.Description) as Expertise
                FROM [dbo].[WorkOrderLabor] wl  WITH(NOLOCK) 
                Inner Join WorkOrderLaborHeader wlh WITH(NOLOCK)  on wlh.WorkOrderLaborHeaderId=wl.WorkOrderLaborHeaderId
                Left Join Task T WITH(NOLOCK) on T.TaskId= wl.TaskId
                Left Join Employee EL WITH(NOLOCK) on EL.EmployeeId= wl.EmployeeId
				Left Join EmployeeExpertise EEX WITH(NOLOCK) on EEX.EmployeeExpertiseId= wl.ExpertiseId
                where wl.IsDeleted=0 and wlh.WorkFlowWorkOrderId=@WorkFlowWorkOrderId and wlh.WorkOrderId =@WorkOrderId
                
			END
		COMMIT  TRANSACTION

		END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
				--PRINT 'ROLLBACK'
				ROLLBACK TRAN;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_GetLaborTaskList' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@WorkFlowWorkOrderId, '') + ''
              , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------

              exec spLogException 
                       @DatabaseName			= @DatabaseName
                     , @AdhocComments			= @AdhocComments
                     , @ProcedureParameters		= @ProcedureParameters
                     , @ApplicationName         = @ApplicationName
                     , @ErrorLogID              = @ErrorLogID OUTPUT ;
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
              RETURN(1);
		END CATCH
END