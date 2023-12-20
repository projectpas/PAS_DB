
/*************************************************************           
 ** File:   [USP_AddUpdateWorkOrderLaborTrackingDetailManual]           
 ** Author:   Subhash Saliya
 ** Description: This stored procedure is used Add/Update WorkOrder Labor Tracking Detail 
 ** Purpose:         
 ** Date:   07/02/2023   
       
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    07/02/2023   Subhash Saliya	Created 
	2    19/05/2023   Subhash Saliya	changes update task statusid  
**************************************************************/
CREATE     PROCEDURE [dbo].[USP_AddUpdateWorkOrderLaborTrackingDetailManual]
 @WorkOrderLaborId bigint,
 @IsBegin bit
 
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;

		BEGIN TRY
		BEGIN TRANSACTION
			BEGIN  
				DECLARE @woLaborId bigint = 0, @isCompleted bit, @scanStartTime datetime2(7)=GETDATE(), @woLaborTrackingId bigint = 0, @WorkFlowWOId bigint,
                @TaskId bigint,
                @EmployeeId bigint,
                @MasterCompanyId bigint,
                @UserName varchar(100),
                @TaskStartTime datetime2(7)= null,
                @TaskENDTime datetime2(7)= null,
				@HoursorClockorScan int
				DECLARE @totalHours int = 0 ,
				 @AdjustedHours decimal(18,2) = 0 ,
				 @AdjustedHourstemp INT = 0 ,
				 @TotalAdjustedHours INT = 0 ,
				 @TotalAdjustedMinutes INT = 0 ,
				 @AdjustedMinutestemp INT = 0 ,
				 @FinalAdjustedHours decimal(18,2) = 0 ,
				 @totalCalulatedHours int = 0, 
				 @totalCalculatedMinutes int = 0,
				 @totalMainHours decimal(10,2) = 0 

				DECLARE @totalMinutes INT, 
				@laborTaskStatus varchar(50)

				SELECT top 1 @MasterCompanyId= WL.MasterCompanyId,@UserName=WL.UpdatedBy,@HoursorClockorScan=WLH.HoursorClockorScan,@WorkFlowWOId=WLH.WorkFlowWorkOrderId,@woLaborId = ISNULL(WorkOrderLaborId,0),@TaskId=WL.TaskId,@EmployeeId=WL.EmployeeId 
				, @AdjustedHours=Isnull(Adjustments,0),@laborTaskStatus = (SELECT Top 1 [Description] FROM dbo.TaskStatus TS WHERE TS.TaskStatusId = WL.TaskStatusId)
							FROM dbo.WorkOrderLabor WL WITH(NOLOCK) INNER JOIN dbo.WorkOrderLaborHeader WLH WITH(NOLOCK) on WL.WorkOrderLaborHeaderId = WLH.WorkOrderLaborHeaderId
							where WorkOrderLaborId = @WorkOrderLaborId
				SELECT Top 1 @woLaborTrackingId = ISNULL(WorkOrderLaborTrackingId,0) ,@scanStartTime = StartTime FROM dbo.WorkOrderLaborTracking WITH(NOLOCK) where TaskId = @TaskId AND EmployeeId = @EmployeeId AND ISNULL(IsCompleted,0) = 0 AND WorkOrderLaborId = @woLaborId
				
				IF(@woLaborId != 0 and @HoursorClockorScan=2)
				BEGIN
						IF(@woLaborTrackingId > 0)
						BEGIN
							IF(@IsBegin = 0)
							BEGIN
								Update wot 
									  set wot.EndTime = GETUTCDATE(),
										  wot.TotalHours= ISNULL(DATEDIFF(MINUTE, @scanStartTime,GETUTCDATE())/60,0),
										  wot.TotalMinutes =  DATEDIFF(MINUTE, @scanStartTime,GETUTCDATE()) % 60, 
										  wot.IsCompleted = 1, 
										  wot.UpdatedBy = @UserName, UpdatedDate = GETUTCDATE()
								 From [dbo].[WorkOrderLaborTracking] as wot WITH(NOLOCK)  WHERE WorkOrderLaborTrackingId = @woLaborTrackingId
								 		print 'as'
								     SELECT @totalHours =  SUM(ISNULL(TotalHours,0)), @totalMinutes = SUM(ISNULL(TotalMinutes,0)) FROM [dbo].[WorkOrderLaborTracking] WHERE WorkOrderLaborId =@woLaborId AND TaskId = @TaskId AND EmployeeId = @EmployeeId 
									 set @totalCalulatedHours = @totalHours + (CONVERT(int,(@totalMinutes / 60 + (@totalMinutes % 60) / 100.0)))
									 set @totalCalculatedMinutes = convert(int,(CASE WHEN @totalMinutes > 60 THEN (PARSENAME(CONVERT(decimal(10,2),(convert(int,@totalMinutes) / 60 + (convert(int,@totalMinutes) % 60) / 100.0)),1)) ELSE @totalMinutes END))
									 set @totalMainHours = convert(decimal(10,2),(convert(varchar(20),isnull(@totalCalulatedHours,0)) +'.'+ convert(varchar(20),format(isnull(@totalCalculatedMinutes,0),'00'))))

									 set @AdjustedHourstemp= Isnull(RIGHT('0' + CAST (FLOOR(@AdjustedHours) AS VARCHAR), 2),0)
									 set @AdjustedMinutestemp= Isnull(convert(varchar(20),((100* convert(int,(RIGHT('0' + CAST(FLOOR((((@AdjustedHours * 3600) % 3600) / 60)) AS VARCHAR), 2))))/60)),0)
								
								     Set @TotalAdjustedHours =  (ISNULL(@totalCalulatedHours,0.0) + ISNULL(@AdjustedHourstemp,0.0)) + (CONVERT(int,((ISNULL(@totalCalculatedMinutes,0.0) + ISNULL(@AdjustedMinutestemp,0.0)) / 60 + ((ISNULL(@totalCalculatedMinutes,0.0) + ISNULL(@AdjustedMinutestemp,0.0)) % 60) / 100.0))) 
									 set @TotalAdjustedMinutes = convert(int,(CASE WHEN (ISNULL(@totalCalculatedMinutes,0) + ISNULL(@AdjustedMinutestemp,0)) > 60 THEN (PARSENAME(CONVERT(decimal(10,2),(convert(int,(ISNULL(@totalCalculatedMinutes,0) + ISNULL(@AdjustedMinutestemp,0))) / 60 + (convert(int,(ISNULL(@totalCalculatedMinutes,0) + ISNULL(@AdjustedMinutestemp,0))) % 60) / 100.0)),1)) ELSE (ISNULL(@totalCalculatedMinutes,0) + ISNULL(@AdjustedMinutestemp,0)) END))
									 set @FinalAdjustedHours = CONCAT(Cast(isnull(@TotalAdjustedHours,0) as int),'.', format(isnull(@TotalAdjustedMinutes,0),'00')) --cast((convert(varchar(20),isnull(@TotalAdjustedHours,0)) +'.'+ convert(varchar(20),format(isnull(@TotalAdjustedMinutes,0),'00'))) as decimal(18,2))

									 print @FinalAdjustedHours
								    UPDATE WL set [Hours]= @totalMainHours , AdjustedHours = @FinalAdjustedHours,
											   BurdenRateAmount = (CASE WHEN ISNULL(BurdaenRatePercentageId,0) = 0 THEN BurdenRateAmount ELSE (CONVERT(decimal(10,2),(DirectLaborOHCost * P.PercentValue)/100))END),
											   TotalCostPerHour = (ISNULL(DirectLaborOHCost,0) + (CASE WHEN ISNULL(BurdaenRatePercentageId,0) = 0 THEN BurdenRateAmount ELSE (CONVERT(decimal(10,2),(DirectLaborOHCost * P.PercentValue)/100))END))
											   --TotalCost = ( (ISNULL(DirectLaborOHCost,0) + (CASE WHEN ISNULL(BurdaenRatePercentageId,0) = 0 THEN BurdenRateAmount ELSE (CONVERT(decimal(10,2),(DirectLaborOHCost * P.PercentValue)/100))END)) * ISNULL((Adjustments + @totalMainHours),0) )
									  FROM dbo.WorkOrderLabor WL  WITH(NOLOCK)
									  LEFT JOIN dbo.[Percent] P WITH(NOLOCK) 
											on Wl.BurdaenRatePercentageId = P.PercentId 
									  WHERE  Wl.WorkOrderLaborId = @woLaborId

									    UPDATE WL set 
											   TotalCost = Isnull((CAST(@FinalAdjustedHours AS INT) + (@FinalAdjustedHours - CAST(@FinalAdjustedHours AS INT))/.6)*TotalCostPerHour,0),IsBegin=@IsBegin,UpdatedBy = @UserName,UpdatedDate = GETUTCDATE()
									  FROM dbo.WorkOrderLabor WL  WITH(NOLOCK)
									  WHERE  Wl.WorkOrderLaborId = @woLaborId
							
							END
						END
						ELSE
						BEGIN
							IF(@IsBegin =1)
							BEGIN
								INSERT INTO [dbo].[WorkOrderLaborTracking]
							   ([WorkOrderLaborId]
							   ,[TaskId]
							   ,[EmployeeId]
							   ,[StartTime]
							   ,[IsCompleted]
							   ,[MasterCompanyId]
							   ,[CreatedBy]
							   ,[UpdatedBy]
							   ,[CreatedDate]
							   ,[UpdatedDate]
							   ,[IsActive]
							   ,[IsDeleted])
							VALUES
							   (@woLaborId
							   ,@TaskId
							   ,@EmployeeId
							   ,GETUTCDATE()
							   ,0
							   ,@MasterCompanyId
							   ,@UserName
							   ,@UserName
							   ,GETUTCDATE()
							   ,GETUTCDATE()
							   ,1
							   ,0)	

							   Declare @CurrentTaskStatusId int =0
							   Declare @PendingTaskStatusId int =0
							   Declare @InprogressTaskStatusId int =0

							   select TOP 1 @PendingTaskStatusId=TaskStatusId from TaskStatus  TS  WITH(NOLOCK) WHERE  TS.MasterCompanyId = @MasterCompanyId and UPPER(Description) =UPPER('PENDING')
							   select TOP 1 @InprogressTaskStatusId=TaskStatusId from TaskStatus  TS  WITH(NOLOCK) WHERE  TS.MasterCompanyId = @MasterCompanyId and UPPER(Description) =UPPER('IN-PROCESS')

							   select @CurrentTaskStatusId=TaskStatusId from WorkOrderLabor  WL  WITH(NOLOCK)  WHERE  Wl.WorkOrderLaborId = @woLaborId
							   
							   if(@CurrentTaskStatusId = @PendingTaskStatusId)
							   begin
							      UPDATE WL set 
											   TaskStatusId = @InprogressTaskStatusId,UpdatedBy = @UserName,UpdatedDate = GETUTCDATE()
									  FROM dbo.WorkOrderLabor WL  WITH(NOLOCK)
									  WHERE  Wl.WorkOrderLaborId = @woLaborId
							   end
							 

							END

							
							
						END
				END
				
			END
		COMMIT  TRANSACTION

		END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
				--PRINT 'ROLLBACK'
				SELECT
    ERROR_NUMBER() AS ErrorNumber,
    ERROR_STATE() AS ErrorState,
    ERROR_SEVERITY() AS ErrorSeverity,
    ERROR_PROCEDURE() AS ErrorProcedure,
    ERROR_LINE() AS ErrorLine,
    ERROR_MESSAGE() AS ErrorMessage;

				ROLLBACK TRAN;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_AddUpdateWorkOrderLaborTrackingDetail' 
              , @ProcedureParameters VARCHAR(3000)  = '@WorkFlowWOId = '''+ ISNULL(@WorkFlowWOId, '') + '' +
			  '@EmployeeId = '''+ ISNULL(@EmployeeId, '') + '' +'@TaskId = '''+ ISNULL(@TaskId, '') + '' +
			  '@MasterCompanyId = '''+ ISNULL(@MasterCompanyId, '') + '' +'@UserName = '''+ ISNULL(@UserName, '') + '' 
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