/*************************************************************           
 ** File:   [USP_AddUpdateWorkOrderLaborTrackingDetail]           
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
**  2    05/26/2023	  HEMANT SALIYA		Updated For WorkOrder Settings
**************************************************************/
CREATE   PROCEDURE [dbo].[USP_AddUpdateWorkOrderLaborTrackingDetailManualSubWorkOrderScheduler]
 @WorkOrderLaborId BIGINT,
 @IsBegin bit
 
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;

		BEGIN TRY
		BEGIN TRANSACTION
			BEGIN  
				DECLARE @woLaborId BIGINT = 0, @isCompleted bit, @scanStartTime datetime2(7)=GETDATE(), @woLaborTrackingId BIGINT = 0, @WorkFlowWOId BIGINT,
                @TaskId BIGINT,
                @EmployeeId BIGINT,
                @MasterCompanyId BIGINT,
				@WorkOrderId BIGINT,
				@WorkOrderTypeId BIGINT,
                @UserName varchar(100),
                @TaskStartTime datetime2(7)= null,
                @TaskENDTime datetime2(7)= null,
				@HoursorClockorScan INT

				DECLARE @totalHours INT = 0 ,
				@AdjustedHours decimal(18,2) = 0 ,
				@AdjustedHourstemp INT = 0 ,
				@TotalAdjustedHours INT = 0 ,
				@TotalAdjustedMinutes INT = 0 ,
				@AdjustedMinutestemp INT = 0 ,
				@FinalAdjustedHours decimal(18,2) = 0 ,
				@totalCalulatedHours INT = 0, 
				@totalCalculatedMinutes INT = 0,
				@totalMainHours decimal(10,2) = 0 

				DECLARE @totalMinutes INT, 
				@laborTaskStatus varchar(50)

				DECLARE  @LaborlogoffHours INT= 0;

				SELECT top 1 @MasterCompanyId= WL.MasterCompanyId,@UserName=WL.UpdatedBy,@HoursorClockorScan=WLH.HoursorClockorScan,@woLaborId = ISNULL(WL.SubWorkOrderLaborId,0),@TaskId=WL.TaskId,@EmployeeId=WL.EmployeeId, 
						@WorkOrderId = WLH.WorkOrderId , @AdjustedHours=Isnull(Adjustments,0),@laborTaskStatus = (SELECT Top 1 [Description] FROM dbo.TaskStatus TS WHERE TS.TaskStatusId = WL.TaskStatusId)
				FROM dbo.SubWorkOrderLabor WL WITH(NOLOCK) INNER JOIN dbo.SubWorkOrderLaborHeader WLH WITH(NOLOCK) on WL.SubWorkOrderLaborHeaderId = WLH.SubWorkOrderLaborHeaderId
				WHERE SubWorkOrderLaborId = @WorkOrderLaborId
				SELECT Top 1 @woLaborTrackingId = ISNULL(SubWorkOrderLaborTrackingId,0) ,@scanStartTime = StartTime 
				FROM dbo.SubWorkOrderLaborTracking WITH(NOLOCK) where TaskId = @TaskId AND EmployeeId = @EmployeeId AND ISNULL(IsCompleted,0) = 0 AND SubWorkOrderLaborId = @woLaborId

				SELECT @WorkOrderTypeId = WorkOrderTypeId FROM dbo.WorkOrder WITH(NOLOCK) WHERE WorkOrderId = @WorkOrderId
				
				IF(@woLaborId != 0 and @HoursorClockorScan=2)
				BEGIN
						IF(@woLaborTrackingId > 0)
						BEGIN
							IF(@IsBegin = 0)
							BEGIN

							SELECT @LaborlogoffHours=isnull(LaborlogoffHours,0) FROM dbo.WorkOrderSettings wos WITH(NOLOCK)  where wos.MasterCompanyId=@MasterCompanyId AND wos.WorkOrderTypeId = @WorkOrderTypeId
								
								UPDATE wot 
									  SET wot.EndTime = DateAdd(Hour, @LaborlogoffHours ,@scanStartTime ),
										  wot.TotalHours= @LaborlogoffHours,
										  wot.TotalMinutes = 0, 
										  wot.IsCompleted = 1, 
										  wot.UpdatedBy = @UserName, UpdatedDate = GETUTCDATE()
								 FROM [dbo].SubWorkOrderLaborTracking as wot WITH(NOLOCK)  WHERE SubWorkOrderLaborTrackingId = @woLaborTrackingId
								 
								 SELECT @totalHours =  SUM(ISNULL(TotalHours,0)), @totalMinutes = SUM(ISNULL(TotalMinutes,0)) FROM [dbo].SubWorkOrderLaborTracking WHERE SubWorkOrderLaborId =@woLaborId AND TaskId = @TaskId AND EmployeeId = @EmployeeId 
									 
								 SET @totalCalulatedHours = @totalHours + (CONVERT(INT,(@totalMinutes / 60 + (@totalMinutes % 60) / 100.0)))
								 SET @totalCalculatedMinutes = convert(INT,(CASE WHEN @totalMinutes > 60 THEN (PARSENAME(CONVERT(decimal(10,2),(convert(INT,@totalMinutes) / 60 + (convert(INT,@totalMinutes) % 60) / 100.0)),1)) ELSE @totalMinutes END))
								 SET @totalMainHours = convert(decimal(10,2),(convert(varchar(20),isnull(@totalCalulatedHours,0)) +'.'+ convert(varchar(20),format(isnull(@totalCalculatedMinutes,0),'00'))))
								 
								 SET @AdjustedHourstemp= Isnull(RIGHT('0' + CAST (FLOOR(@AdjustedHours) AS VARCHAR), 2),0)
								 SET @AdjustedMinutestemp= Isnull(convert(varchar(20),((100* convert(INT,(RIGHT('0' + CAST(FLOOR((((@AdjustedHours * 3600) % 3600) / 60)) AS VARCHAR), 2))))/60)),0)
								 
								 SET @TotalAdjustedHours =  (ISNULL(@totalCalulatedHours,0.0) + ISNULL(@AdjustedHourstemp,0.0)) + (CONVERT(INT,((ISNULL(@totalCalculatedMinutes,0.0) + ISNULL(@AdjustedMinutestemp,0.0)) / 60 + ((ISNULL(@totalCalculatedMinutes,0.0) + ISNULL(@AdjustedMinutestemp,0.0)) % 60) / 100.0))) 
								 SET @TotalAdjustedMinutes = convert(INT,(CASE WHEN (ISNULL(@totalCalculatedMinutes,0) + ISNULL(@AdjustedMinutestemp,0)) > 60 THEN (PARSENAME(CONVERT(decimal(10,2),(convert(INT,(ISNULL(@totalCalculatedMinutes,0) + ISNULL(@AdjustedMinutestemp,0))) / 60 + (convert(INT,(ISNULL(@totalCalculatedMinutes,0) + ISNULL(@AdjustedMinutestemp,0))) % 60) / 100.0)),1)) ELSE (ISNULL(@totalCalculatedMinutes,0) + ISNULL(@AdjustedMinutestemp,0)) END))
								 SET @FinalAdjustedHours = CONCAT(Cast(isnull(@TotalAdjustedHours,0) as INT),'.', format(isnull(@TotalAdjustedMinutes,0),'00')) --cast((convert(varchar(20),isnull(@TotalAdjustedHours,0)) +'.'+ convert(varchar(20),format(isnull(@TotalAdjustedMinutes,0),'00'))) as decimal(18,2))
								 
								 print @FinalAdjustedHours
								 UPDATE WL set [Hours]= @totalMainHours , AdjustedHours = @FinalAdjustedHours,
											   BurdenRateAmount = (CASE WHEN ISNULL(BurdaenRatePercentageId,0) = 0 THEN BurdenRateAmount ELSE (CONVERT(decimal(10,2),(DirectLaborOHCost * P.PercentValue)/100))END),
											   TotalCostPerHour = (ISNULL(DirectLaborOHCost,0) + (CASE WHEN ISNULL(BurdaenRatePercentageId,0) = 0 THEN BurdenRateAmount ELSE (CONVERT(decimal(10,2),(DirectLaborOHCost * P.PercentValue)/100))END))
								FROM dbo.SubWorkOrderLabor WL  WITH(NOLOCK) LEFT JOIN dbo.[Percent] P WITH(NOLOCK) on Wl.BurdaenRatePercentageId = P.PercentId 
								WHERE  Wl.SubWorkOrderLaborId = @woLaborId

								UPDATE WL set 
								   TotalCost = Isnull((CAST(@FinalAdjustedHours AS INT) + (@FinalAdjustedHours - CAST(@FinalAdjustedHours AS INT))/.6)*TotalCostPerHour,0),IsBegin=@IsBegin,UpdatedBy=@UserName,UpdatedDate=GETUTCDATE()
								FROM dbo.SubWorkOrderLabor WL  WITH(NOLOCK)
								WHERE  Wl.SubWorkOrderLaborId = @woLaborId
							
							END
						END
						ELSE
						BEGIN
							IF(@IsBegin =1)
							BEGIN
								INSERT INTO [dbo].SubWorkOrderLaborTracking
							   ([SubWorkOrderLaborId]
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

							END
						END
				END
				
			END
		COMMIT  TRANSACTION

		END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
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