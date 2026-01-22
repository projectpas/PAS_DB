-----------------------------------------------------------------------------------------------------

/*************************************************************           
 ** File:   [USP_AddEdit_WorkOrderTurnArroundTime]           
 ** Author:   Subhash Saliya
 ** Description: This stored procedure is used Create Stockline ForCustomer RMA   
 ** Purpose:         
 ** Date:   12/22/2022        
          
 ** PARAMETERS:           
 @UserType varchar(60)   
         
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    12/22/2022   Subhash Saliya		Created
     
-- EXEC [USP_AddEdit_WorkOrderTurnArroundTime] 44
**************************************************************/

create         PROCEDURE [dbo].[USP_GetWorkorderStageHistory]
 @WorkOrderPartNoId bigint 

AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;

		BEGIN TRY
		BEGIN TRANSACTION
			BEGIN  
				

	Select ROW_NUMBER() OVER(ORDER BY WOTATId) AS SequenceNo,WOTATId,WS.CodeDescription as WorkOrderSatge,
	StatusChangedEndDate as EndDate,
	StatusChangedDate as StartDate,
	case when StatusChangedEndDate is null then ISNULL(DATEDIFF(day, (WTA.StatusChangedDate), GETDATE()), 0)  else
			(isnull(((WTA.[Days])+ ((WTA.[Hours])/24)+ ((WTA.[Mins])/1440)),0)) end  as Days,
		ChangedBy as Employee	 from WorkOrderTurnArroundTime as WTA  with(nolock) 
	JOIN WorkOrderStage WS  with(nolock) on WTA.CurrentStageId=WS.WorkOrderStageId

	where WTA.WorkOrderPartNoId=@WorkOrderPartNoId order by WOTATId desc
	           

                
			END
		COMMIT  TRANSACTION

		END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
				--PRINT 'ROLLBACK'
				ROLLBACK TRAN;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_AddEdit_WorkOrderTurnArroundTime' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@WorkOrderPartNoId, '') + ''
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