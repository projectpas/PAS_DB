/*************************************************************           
 ** File:   [USP_CompleteAllWorkOrderLabor]           
 ** Author:   Vishal Suthar
 ** Description: This stored procedure is used Complete all the pending or open labor details
 ** Purpose:         
 ** Date:   June/01/2023   
       
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date			Author			Change Description            
 ** --   --------		-------			--------------------------------          
    1    June/01/2023   Vishal Suthar	Created 
	2    June/28/2024   Hemant Saliya	Updated for Aounting Entry for Close all Labor 

EXEC USP_CompleteAllWorkOrderLabor 3395
**************************************************************/
CREATE   PROCEDURE [dbo].[USP_CompleteAllWorkOrderLabor]
	@WorkOrderLaborHeaderId bigint
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;

		BEGIN TRY
		BEGIN TRANSACTION
			BEGIN  
				DECLARE @scanStartTime datetime2(7) = GETDATE(), @woLaborTrackingId bigint = 0, @MasterCompanyId bigint, @UserName varchar(100), @UpdatedBy varchar(100);
				DECLARE @totalHours int = 0, @AdjustedHours decimal(18,2) = 0, @AdjustedHourstemp INT = 0, @TotalAdjustedHours INT = 0, @TotalAdjustedMinutes INT = 0,
				@AdjustedMinutestemp INT = 0, @FinalAdjustedHours decimal(18,2) = 0, @totalCalulatedHours int = 0, @totalCalculatedMinutes int = 0, @totalMainHours decimal(10,2) = 0 

				DECLARE @totalMinutes INT, @laborTaskStatus varchar(50);
				DECLARE @CustomerWOTypeId INT= 0;
				DECLARE @InternalWOTypeId INT= 0;
				DECLARE @DistributionCode VARCHAR(50);
				DECLARE @DistributionMasterId BIGINT;

				DECLARE @LoopID AS INT;
				DECLARE @TotCount AS INT;

				SELECT TOP 1 @CustomerWOTypeId =Id FROM dbo.WorkOrderType WITH (NOLOCK) WHERE [Description] = 'Customer'
				SELECT TOP 1 @InternalWOTypeId =Id FROM dbo.WorkOrderType WITH (NOLOCK) WHERE [Description] = 'Internal'

				SELECT @DistributionMasterId = ID, @DistributionCode = DistributionCode FROM dbo.DistributionMaster WITH(NOLOCK) WHERE UPPER(DistributionCode)= UPPER('WOLABORTAB')

				IF OBJECT_ID(N'tempdb..#tmpWorkOrderLabor') IS NOT NULL
				BEGIN
					DROP TABLE #tmpWorkOrderLabor
				END

				CREATE TABLE #tmpWorkOrderLabor
				(
					ID bigint NOT NULL IDENTITY,
					[WorkOrderLaborId] [bigint] NOT NULL,
					[WorkOrderLaborHeaderId] [bigint] NOT NULL,
					[TaskId] [bigint] NOT NULL,
					[ExpertiseId] [smallint] NULL,
					[EmployeeId] [bigint] NULL,
					[Hours] [decimal](10, 2) NULL,
					[Adjustments] [decimal](10, 2) NULL,
					[AdjustedHours] [decimal](10, 2) NULL,
					[Memo] [nvarchar](max) NULL,
					[CreatedBy] [varchar](256) NOT NULL,
					[UpdatedBy] [varchar](256) NOT NULL,
					[CreatedDate] [datetime2](7) NOT NULL,
					[UpdatedDate] [datetime2](7) NOT NULL,
					[IsActive] [bit] NOT NULL,
					[IsDeleted] [bit] NOT NULL,
					[StartDate] [datetime2](7) NULL,
					[EndDate] [datetime2](7) NULL,
					[BillableId] [int] NULL,
					[IsFromWorkFlow] [bit] NULL,
					[MasterCompanyId] [int] NOT NULL,
					[DirectLaborOHCost] [decimal](18, 2) NOT NULL,
					[BurdaenRatePercentageId] [bigint] NULL,
					[BurdenRateAmount] [decimal](18, 2) NULL,
					[TotalCostPerHour] [decimal](18, 2) NOT NULL,
					[TotalCost] [decimal](18, 2) NOT NULL,
					[TaskStatusId] [bigint] NULL,
					[StatusChangedDate] [datetime2](7) NULL,
					[TaskInstruction] [varchar](max) NULL,
					[IsBegin] [bit] NULL
				)

				INSERT INTO #tmpWorkOrderLabor (
					[WorkOrderLaborId],[WorkOrderLaborHeaderId],[TaskId],[ExpertiseId],[EmployeeId],[Hours],[Adjustments],[AdjustedHours],[Memo],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],
					[IsActive],[IsDeleted],[StartDate],[EndDate],[BillableId],[IsFromWorkFlow],[MasterCompanyId],[DirectLaborOHCost],[BurdaenRatePercentageId],[BurdenRateAmount],[TotalCostPerHour],
					[TotalCost],[TaskStatusId],[StatusChangedDate],[TaskInstruction],[IsBegin])
				SELECT [WorkOrderLaborId],[WorkOrderLaborHeaderId],[TaskId],[ExpertiseId],[EmployeeId],[Hours],[Adjustments],[AdjustedHours],[Memo],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],
					[IsActive],[IsDeleted],[StartDate],[EndDate],[BillableId],[IsFromWorkFlow],[MasterCompanyId],[DirectLaborOHCost],[BurdaenRatePercentageId],[BurdenRateAmount],[TotalCostPerHour],
					[TotalCost],[TaskStatusId],[StatusChangedDate],[TaskInstruction],[IsBegin]
				FROM DBO.WorkOrderLabor WHERE [WorkOrderLaborHeaderId] = @WorkOrderLaborHeaderId

				SELECT @TotCount = COUNT(*), @LoopID = MIN(ID) FROM #tmpWorkOrderLabor;

				WHILE (@LoopID <= @TotCount)
				BEGIN
					DECLARE @LaborEmployeeId AS BIGINT = NULL;
					DECLARE @WorkOrderLaborId AS BIGINT = NULL;
					DECLARE @WorkOrderId AS BIGINT = NULL;
					DECLARE @WorkFlowWorkOrderId AS BIGINT = NULL;
					DECLARE @TotalCost AS DECIMAL(18,2) = 0;

					SELECT @MasterCompanyId = WLH.MasterCompanyId , @WorkOrderId = WorkOrderId, @WorkFlowWorkOrderId = WorkFlowWorkOrderId
					FROM DBO.WorkOrderLaborHeader WLH WITH(NOLOCK) WHERE [WorkOrderLaborHeaderId] = @WorkOrderLaborHeaderId;

					SELECT @LaborEmployeeId = tmp.EmployeeId, @WorkOrderLaborId = WorkOrderLaborId, @UpdatedBy = UpdatedBy FROM #tmpWorkOrderLabor tmp WHERE ID = @LoopID;

					IF (ISNULL(@LaborEmployeeId, 0) != 0)
					BEGIN
						DECLARE @CompletedTaskStatusId INT = 0;
						SELECT @CompletedTaskStatusId = TaskStatusId from TaskStatus TS WITH(NOLOCK) WHERE TS.MasterCompanyId = @MasterCompanyId AND UPPER(Description) = UPPER('COMPLETED')

						IF OBJECT_ID(N'tempdb..#tmpWorkOrderLaborTracking') IS NOT NULL
						BEGIN
							DROP TABLE #tmpWorkOrderLaborTracking
						END

						CREATE TABLE #tmpWorkOrderLaborTracking
						(
							ID bigint NOT NULL IDENTITY,
							[WorkOrderLaborTrackingId] [bigint] NOT NULL,
							[WorkOrderLaborId] [bigint] NULL,
							[TaskId] [bigint] NULL,
							[EmployeeId] [bigint] NULL,
							[StartTime] [datetime2](7) NULL,
							[EndTime] [datetime2](7) NULL,
							[TotalHours] [int] NULL,
							[TotalMinutes] [int] NULL,
							[IsCompleted] [bit] NULL,
							[MasterCompanyId] [int] NULL,
							[CreatedBy] [varchar](255) NULL,
							[UpdatedBy] [varchar](255) NULL,
							[CreatedDate] [datetime2](7) NULL,
							[UpdatedDate] [datetime2](7) NULL,
							[IsActive] [bit] NULL,
							[IsDeleted] [bit] NULL
						)

						INSERT INTO #tmpWorkOrderLaborTracking (
							[WorkOrderLaborTrackingId],[WorkOrderLaborId],[TaskId],[EmployeeId],[StartTime],[EndTime],[TotalHours],[TotalMinutes],[IsCompleted],[MasterCompanyId],[CreatedBy],
							[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted])
						SELECT [WorkOrderLaborTrackingId],[WorkOrderLaborId],[TaskId],[EmployeeId],[StartTime],[EndTime],[TotalHours],[TotalMinutes],[IsCompleted],[MasterCompanyId],[CreatedBy],
							[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted]
						FROM DBO.WorkOrderLaborTracking WHERE [WorkOrderLaborId] = @WorkOrderLaborId;

						DECLARE @LoopID_LT AS INT;
						DECLARE @TotCount_LT AS INT;
						DECLARE @LaborTrackingUpdated AS BIT = 0;

						SELECT @TotCount_LT = COUNT(*), @LoopID_LT = MIN(ID) FROM #tmpWorkOrderLaborTracking;

						WHILE (@LoopID_LT <= @TotCount_LT)
						BEGIN
							SET @woLaborTrackingId = NULL;
							SELECT @woLaborTrackingId = WorkOrderLaborTrackingId FROM #tmpWorkOrderLaborTracking WHERE ID = @LoopID_LT;

							IF (ISNULL(@woLaborTrackingId, 0) != 0)
							BEGIN
								SET @LaborTrackingUpdated = 1;
								SELECT Top 1 @scanStartTime = StartTime, @UserName= UpdatedBy FROM dbo.WorkOrderLaborTracking WITH(NOLOCK) WHERE WorkOrderLaborTrackingId = @woLaborTrackingId;

								UPDATE WOT
								SET WOT.EndTime = GETUTCDATE(),
									WOT.TotalHours = ISNULL(DATEDIFF(MINUTE, @scanStartTime,GETUTCDATE())/60,0),
									WOT.TotalMinutes = DATEDIFF(MINUTE, @scanStartTime,GETUTCDATE()) % 60, 
									WOT.IsCompleted = 1, 
									WOT.UpdatedBy = @UserName, 
									WOT.UpdatedDate = GETUTCDATE()
								FROM [dbo].[WorkOrderLaborTracking] AS WOT WITH(NOLOCK)
								WHERE WorkOrderLaborTrackingId = @woLaborTrackingId AND WOT.EndTime IS NULL;
							END

							SET @LoopID_LT = @LoopID_LT + 1;
						END
						
						IF (@LaborTrackingUpdated = 1)
						BEGIN
							SELECT @totalHours = SUM(ISNULL(TotalHours,0)), @totalMinutes = SUM(ISNULL(TotalMinutes,0)) 
							FROM [dbo].[WorkOrderLaborTracking] 
							WHERE [WorkOrderLaborId] = @WorkOrderLaborId;
						
							SET @totalCalulatedHours = @totalHours + (CONVERT(INT, (@totalMinutes / 60 + (@totalMinutes % 60) / 100.0)))
							SET @totalCalculatedMinutes = CONVERT(INT,(CASE WHEN @totalMinutes > 60 THEN (PARSENAME(CONVERT(decimal(10, 2), (CONVERT(INT, @totalMinutes) / 60 + (CONVERT(INT, @totalMinutes) % 60) / 100.0)), 1)) ELSE @totalMinutes END))
							SET @totalMainHours = CONVERT(DECIMAL(10, 2), (CONVERT(VARCHAR(20), ISNULL(@totalCalulatedHours, 0)) + '.' + CONVERT(VARCHAR(20), FORMAT(ISNULL(@totalCalculatedMinutes, 0), '00'))))

							SET @AdjustedHourstemp = ISNULL(RIGHT('0' + CAST (FLOOR(@AdjustedHours) AS VARCHAR), 2), 0)
							SET @AdjustedMinutestemp = ISNULL(CONVERT(VARCHAR(20), ((100 * CONVERT(INT, (RIGHT('0' + CAST(FLOOR((((@AdjustedHours * 3600) % 3600) / 60)) AS VARCHAR), 2)))) / 60)), 0)
						
							SET @TotalAdjustedHours =  (ISNULL(@totalCalulatedHours, 0.0) + ISNULL(@AdjustedHourstemp, 0.0)) + (CONVERT(INT, ((ISNULL(@totalCalculatedMinutes, 0.0) + ISNULL(@AdjustedMinutestemp, 0.0)) / 60 + ((ISNULL(@totalCalculatedMinutes, 0.0) + ISNULL(@AdjustedMinutestemp,0.0)) % 60) / 100.0))) 
							SET @TotalAdjustedMinutes = convert(INT, (CASE WHEN (ISNULL(@totalCalculatedMinutes, 0) + ISNULL(@AdjustedMinutestemp, 0)) > 60 THEN (PARSENAME(CONVERT(DECIMAL(10, 2), (CONVERT(INT, (ISNULL(@totalCalculatedMinutes, 0) + ISNULL(@AdjustedMinutestemp, 0))) / 60 + (CONVERT(INT, (ISNULL(@totalCalculatedMinutes, 0) + ISNULL(@AdjustedMinutestemp, 0))) % 60) / 100.0)), 1)) ELSE (ISNULL(@totalCalculatedMinutes, 0) + ISNULL(@AdjustedMinutestemp, 0)) END))
							SET @FinalAdjustedHours = CONCAT(CAST(ISNULL(@TotalAdjustedHours, 0) AS INT), '.', FORMAT(ISNULL(@TotalAdjustedMinutes,0), '00'))
						
							UPDATE WL 
							SET [Hours]= @totalMainHours,
								AdjustedHours = @FinalAdjustedHours,
								BurdenRateAmount = (CASE WHEN ISNULL(BurdaenRatePercentageId, 0) = 0 THEN BurdenRateAmount ELSE (CONVERT(DECIMAL(10, 2), (DirectLaborOHCost * P.PercentValue) / 100)) END),
								TotalCostPerHour = (ISNULL(DirectLaborOHCost, 0) + (CASE WHEN ISNULL(BurdaenRatePercentageId, 0) = 0 THEN BurdenRateAmount ELSE (CONVERT(DECIMAL(10, 2), (DirectLaborOHCost * P.PercentValue) / 100)) END))
							FROM dbo.WorkOrderLabor WL  WITH(NOLOCK)
							LEFT JOIN dbo.[Percent] P WITH(NOLOCK) ON Wl.BurdaenRatePercentageId = P.PercentId 
							WHERE  Wl.WorkOrderLaborId = @WorkOrderLaborId;
						
							UPDATE WL
							SET TotalCost = ISNULL((CAST(@FinalAdjustedHours AS INT) + (@FinalAdjustedHours - CAST(@FinalAdjustedHours AS INT)) / .6) * TotalCostPerHour, 0),
							WL.TaskStatusId = @CompletedTaskStatusId, 
							IsBegin = 0,
							UpdatedBy = @UserName,
							UpdatedDate = GETUTCDATE()
							FROM dbo.WorkOrderLabor WL WITH(NOLOCK)
							WHERE WL.WorkOrderLaborId = @WorkOrderLaborId;
						END
						ELSE
						BEGIN
							UPDATE WL
							SET WL.TaskStatusId = @CompletedTaskStatusId, 
							IsBegin = 0
							FROM dbo.WorkOrderLabor WL WITH(NOLOCK)
							WHERE WL.WorkOrderLaborId = @WorkOrderLaborId;
						END
					END

					DECLARE @WOTypeId INT= 0;
					DECLARE @IsRestrict INT;
					DECLARE @IsAccountByPass BIT;
					DECLARE @laborType VARCHAR(50);
					DECLARE @ModuleName VARCHAR(50);

					SET @laborType = 'DIRECTLABOR';
					SET @ModuleName = 'WOP-DirectLabor';

					EXEC dbo.USP_GetSubLadgerGLAccountRestriction  @DistributionCode,  @MasterCompanyId,  0,  @UserName, @IsRestrict OUTPUT, @IsAccountByPass OUTPUT;

					SELECT TOP 1 @WOTypeId = WorkOrderTypeId FROM dbo.WorkOrder WITH (NOLOCK) WHERE WorkOrderId = @WorkOrderId

					IF(ISNULL(@TotalCost, 0) > 0 )
					BEGIN
						IF(ISNULL(@WOTypeId,0) = @CustomerWOTypeId AND ISNULL(@IsAccountByPass, 0) = 0)
						BEGIN
							PRINT '7'
							IF NOT EXISTS(SELECT 1 FROM dbo.DistributionSetup WITH(NOLOCK) WHERE DistributionMasterId =@DistributionMasterId AND MasterCompanyId=@MasterCompanyId AND ISNULL(GlAccountId,0) = 0)
							BEGIN
								PRINT '7.1.1'
								 EXEC [dbo].[USP_BatchTriggerBasedonDistribution] 
								 @DistributionMasterId,@WorkOrderId,@WorkFlowWorkOrderId,@WorkOrderLaborId,0,0,0,@laborType,1,@TotalCost,@ModuleName,@MasterCompanyId,@UpdatedBy
							END
							PRINT '7.1'
						END

						IF(ISNULL(@WOTypeId,0) = @InternalWOTypeId AND ISNULL(@IsAccountByPass, 0) = 0)
						BEGIN
							PRINT '8'
							IF NOT EXISTS(SELECT 1 FROM dbo.DistributionSetup WITH(NOLOCK) WHERE DistributionMasterId =@DistributionMasterId AND MasterCompanyId=@MasterCompanyId AND ISNULL(GlAccountId,0) = 0)
							BEGIN
								EXEC [dbo].[USP_BatchTriggerBasedonDistributionForInternalWO] 
								@DistributionMasterId,@WorkOrderId,@WorkFlowWorkOrderId,@WorkOrderLaborId,0,0,0,@laborType,1,@TotalCost,@ModuleName,@MasterCompanyId,@UpdatedBy
							END
							PRINT '8.1'
						END
					END

					SET @LoopID = @LoopID + 1;
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
              , @AdhocComments     VARCHAR(150)    = 'USP_CompleteAllWorkOrderLabor' 
              , @ProcedureParameters VARCHAR(3000)  = '@WorkOrderLaborHeaderId = '''+ ISNULL(@WorkOrderLaborHeaderId, '') + ''
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