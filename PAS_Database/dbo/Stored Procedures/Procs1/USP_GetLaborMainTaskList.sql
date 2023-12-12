﻿-----------------------------------------------------------------------------------------------------

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
	1    02/21/2023   Hemant Saliya			Updaetd to Upper Case
     
-- EXEC [USP_GetLaborMainTaskList] 692,682
**************************************************************/

CREATE   PROCEDURE [dbo].[USP_GetLaborMainTaskList]
 @WorkFlowWorkOrderId bigint,
 @WorkOrderId bigint
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;

		BEGIN TRY
		BEGIN TRANSACTION
			BEGIN  

				declare @DataEnteredBy bigint =0
				DECLARE @Traveler_setupid AS BIGINT = 0;
				DECLARE @WorkOrderPartId AS BIGINT = 0;
				DECLARE @WorkScopeId AS BIGINT = 0;
				DECLARE @ItemMasterId AS BIGINT = 0;
				declare @IstravelerTask bit =0
			    declare @highestSequence bigint =0
                
				select top 1 @WorkOrderPartId=WorkOrderPartNoId from WorkOrderWorkFlow  where WorkFlowWorkOrderId=@WorkFlowWorkOrderId
                select top 1 @ItemMasterId=ItemMasterId,@WorkScopeId=WorkOrderScopeId,@IstravelerTask=IsTraveler from WorkOrderPartNumber  where ID=@WorkOrderPartId

			     IF(EXISTS (SELECT 1 FROM Traveler_Setup WHERE WorkScopeId = @WorkScopeId and ItemMasterId=@ItemMasterId and IsVersionIncrease=0))
				 BEGIN
				    SELECT top 1 @Traveler_setupid= Traveler_setupid FROM Traveler_Setup WHERE WorkScopeId = @WorkScopeId and ItemMasterId=@ItemMasterId and IsVersionIncrease=0
				 
					select  top 1 @highestSequence= Sequence from Traveler_Setup_Task    where  Traveler_setupid =@Traveler_setupid order by Sequence desc
				 END
				 else IF(EXISTS (SELECT 1 FROM Traveler_Setup WHERE WorkScopeId = @WorkScopeId and ItemMasterId is null and IsVersionIncrease=0))
				 BEGIN
				    SELECT top 1 @Traveler_setupid= Traveler_setupid FROM Traveler_Setup WHERE WorkScopeId = @WorkScopeId and ItemMasterId is null and IsVersionIncrease=0

					select  top 1 @highestSequence= Sequence from Traveler_Setup_Task    where  Traveler_setupid =@Traveler_setupid order by Sequence desc
				 END

				SELECT 
                wl.[TaskId]
                ,Max([TaskInstruction]) as TaskInstruction
	            ,Max(UPPER(T.Description)) as Task
				,Max(WorkOrderLaborId) as WorkOrderLaborId
				,Max(Isnull(TTS.Sequence,9999)) as Sequence,
				 Max(@highestSequence) as HighestSequence
                FROM [dbo].[WorkOrderLabor] wl  WITH(NOLOCK) 
                Inner Join WorkOrderLaborHeader wlh WITH(NOLOCK)  on wlh.WorkOrderLaborHeaderId=wl.WorkOrderLaborHeaderId
                Left Join Task T WITH(NOLOCK) on T.TaskId= wl.TaskId
				Left Join Traveler_Setup_Task TTS WITH(NOLOCK) on TTS.TaskId= wl.TaskId and Traveler_SetupId= @Traveler_setupid
                where wl.IsDeleted=0 and wlh.WorkFlowWorkOrderId=@WorkFlowWorkOrderId and wlh.WorkOrderId =@WorkOrderId group by  wl.[TaskId] order by Sequence asc
                
			END
		COMMIT  TRANSACTION

		END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
				--PRINT 'ROLLBACK'
				ROLLBACK TRAN;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_GetLaborMainTaskList' 
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