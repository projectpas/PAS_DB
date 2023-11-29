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

CREATE     PROCEDURE [dbo].[USP_AddEdit_WorkOrderTurnArroundTime]
 @WorkOrderPartNoId bigint,  
 @CurrentStageId bigint,  
 @CreatedBy varchar(100)  
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;

		BEGIN TRY
		BEGIN TRANSACTION
			BEGIN  
				declare @OldStageId bigint =0
                declare @Days bigint =0
                declare @Hours bigint =0
                declare @Mins bigint =0
                declare @DaysDiff bigint =0
                declare @HoursDiff bigint =0
                declare @MinsDiff bigint =0
                declare @StatusChangedDate datetime
				 declare @WOTATId bigint =0
                
                select top 1 @StatusChangedDate=isnull(StatusChangedDate,GETUTCDATE()),@OldStageId=isnull(CurrentStageId,0),@WOTATId=WOTATId from WorkOrderTurnArroundTime with(nolock)  where WorkOrderPartNoId=@WorkOrderPartNoId order by WOTATId desc
                	
                set @Days=DATEDIFF(minute, isnull(@StatusChangedDate,GETUTCDATE()), GETUTCDATE())/1440
                set @Hours=DATEDIFF(minute, isnull(@StatusChangedDate,GETUTCDATE()), GETUTCDATE())/60
                set @Mins=DATEDIFF(minute, isnull(@StatusChangedDate,GETUTCDATE()), GETUTCDATE())

				
	

	           IF(@OldStageId != @CurrentStageId)
	            BEGIN
				      IF(@OldStageId =0)
				      BEGIN
				      SET @OldStageId=@CurrentStageId
				      END

	                 INSERT INTO [dbo].[WorkOrderTurnArroundTime]
                                          ([WorkOrderPartNoId]
                                          ,[OldStageId]
                                          ,[CurrentStageId]
                                          ,[StatusChangedDate]
                                          ,[ChangedBy]
                                          ,[Days]
                                          ,[Hours]
                                          ,[Mins]
                                          ,[IsActive])
                                    VALUES
                                          (@WorkOrderPartNoId
                                          ,@OldStageId
                                          ,@CurrentStageId
                                          ,GETUTCDATE()
                                          ,@CreatedBy
                                          ,0
                                          ,0
                                          ,0
                                          ,1)

										  if(@WOTATId >0)
										  begin
										  UPDATE WorkOrderTurnArroundTime set Days=CASE WHEN @Days > 0 THEN @Days ELSE 0 END,Hours= CASE WHEN  @Hours % 24 > 0 THEN (@Hours % 24) ELSE 0 END,Mins= CASE WHEN @Mins % 60 > 0 THEN (@Mins % 60) ELSE 0 END,StatusChangedEndDate=GETUTCDATE()
										        WHERE WOTATId =@WOTATId
										  end

	             END
                
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