
/*************************************************************           
 ** File:   [USP_CompleteAllSubWorkOrderLabor]           
 ** Author:   Moin Bloch
 ** Description: This stored procedure is used Complete all the pending or open labor details
 ** Purpose:         
 ** Date:   08/31/2023
       
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date			Author			Change Description            
 ** --   --------		-------			--------------------------------          
    1    08/31/2023     Moin Bloch	    Created 

EXEC USP_CompleteAllSubWorkOrderLabor 2953
**************************************************************/
CREATE   PROCEDURE [dbo].[USP_CompleteAllSubWorkOrderLabor]
@SubWorkOrderLaborHeaderId bigint
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;

		BEGIN TRY
		BEGIN TRANSACTION
			BEGIN  
				DECLARE @scanStartTime DATETIME2(7) = GETUTCDATE()
				DECLARE @swoLaborTrackingId BIGINT = 0
				DECLARE @MasterCompanyId bigint
				DECLARE @UserName varchar(100)
				DECLARE @totalHours int = 0
				DECLARE @AdjustedHours decimal(18,2) = 0 
				DECLARE @AdjustedHourstemp INT = 0 
				DECLARE @TotalAdjustedHours INT = 0
				DECLARE @TotalAdjustedMinutes INT = 0
				DECLARE @AdjustedMinutestemp INT = 0 
				DECLARE @FinalAdjustedHours decimal(18,2) = 0
				DECLARE @totalCalulatedHours int = 0
				DECLARE @totalCalculatedMinutes int = 0
				DECLARE @totalMainHours decimal(10,2) = 0 
				DECLARE @totalMinutes INT 
				DECLARE @laborTaskStatus varchar(50)
				DECLARE @LoopID AS INT
				DECLARE @TotCount AS INT

				IF OBJECT_ID(N'tempdb..#tmpSubWorkOrderLabor') IS NOT NULL
				BEGIN
					DROP TABLE #tmpSubWorkOrderLabor
				END

				CREATE TABLE #tmpSubWorkOrderLabor
				(
					ID bigint NOT NULL IDENTITY,
					[SubWorkOrderLaborId] [bigint] NOT NULL,
					[SubWorkOrderLaborHeaderId] [bigint] NOT NULL,
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

				INSERT INTO #tmpSubWorkOrderLabor (
					[SubWorkOrderLaborId],[SubWorkOrderLaborHeaderId],[TaskId],[ExpertiseId],[EmployeeId],[Hours],[Adjustments],[AdjustedHours],[Memo],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],
					[IsActive],[IsDeleted],[StartDate],[EndDate],[BillableId],[IsFromWorkFlow],[MasterCompanyId],[DirectLaborOHCost],[BurdaenRatePercentageId],[BurdenRateAmount],[TotalCostPerHour],
					[TotalCost],[TaskStatusId],[StatusChangedDate],[TaskInstruction],[IsBegin])
				SELECT [SubWorkOrderLaborId],[SubWorkOrderLaborHeaderId],[TaskId],[ExpertiseId],[EmployeeId],[Hours],[Adjustments],[AdjustedHours],[Memo],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],
					[IsActive],[IsDeleted],[StartDate],[EndDate],[BillableId],[IsFromWorkFlow],[MasterCompanyId],[DirectLaborOHCost],[BurdaenRatePercentageId],[BurdenRateAmount],[TotalCostPerHour],
					[TotalCost],[TaskStatusId],[StatusChangedDate],[TaskInstruction],[IsBegin]
				FROM [dbo].[SubWorkOrderLabor] WITH(NOLOCK) WHERE [SubWorkOrderLaborHeaderId] = @SubWorkOrderLaborHeaderId

				SELECT @TotCount = COUNT(*), @LoopID = MIN(ID) FROM #tmpSubWorkOrderLabor;

				WHILE (@LoopID <= @TotCount)
				BEGIN
					DECLARE @LaborEmployeeId AS BIGINT = NULL;
					DECLARE @SubWorkOrderLaborId AS BIGINT = NULL;

					SELECT @MasterCompanyId = WLH.[MasterCompanyId] FROM [dbo].[SubWorkOrderLaborHeader] WLH WITH(NOLOCK) WHERE [SubWorkOrderLaborHeaderId] = @SubWorkOrderLaborHeaderId;

					SELECT @LaborEmployeeId = tmp.[EmployeeId], @SubWorkOrderLaborId = [SubWorkOrderLaborId] FROM #tmpSubWorkOrderLabor tmp WHERE [ID] = @LoopID;

					IF (ISNULL(@LaborEmployeeId, 0) != 0)
					BEGIN
						DECLARE @CompletedTaskStatusId INT = 0;
						SELECT @CompletedTaskStatusId = [TaskStatusId] FROM [dbo].[TaskStatus] TS WITH(NOLOCK) WHERE TS.MasterCompanyId = @MasterCompanyId AND UPPER([Description]) = UPPER('COMPLETED')

						IF OBJECT_ID(N'tempdb..#tmpSubWorkOrderLaborTracking') IS NOT NULL
						BEGIN
							DROP TABLE #tmpSubWorkOrderLaborTracking
						END

						CREATE TABLE #tmpSubWorkOrderLaborTracking
						(
							ID bigint NOT NULL IDENTITY,
							[SubWorkOrderLaborTrackingId] [bigint] NOT NULL,
							[SubWorkOrderLaborId] [bigint] NULL,
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

						INSERT INTO #tmpSubWorkOrderLaborTracking (
							[SubWorkOrderLaborTrackingId],[SubWorkOrderLaborId],[TaskId],[EmployeeId],[StartTime],[EndTime],[TotalHours],[TotalMinutes],[IsCompleted],[MasterCompanyId],[CreatedBy],
							[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted])
						SELECT [SubWorkOrderLaborTrackingId],[SubWorkOrderLaborId],[TaskId],[EmployeeId],[StartTime],[EndTime],[TotalHours],[TotalMinutes],[IsCompleted],[MasterCompanyId],[CreatedBy],
							[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted]
						FROM [dbo].[SubWorkOrderLaborTracking] WITH(NOLOCK) WHERE [SubWorkOrderLaborId] = @SubWorkOrderLaborId;

						DECLARE @LoopID_LT AS INT;
						DECLARE @TotCount_LT AS INT;
						DECLARE @LaborTrackingUpdated AS BIT = 0;

						SELECT @TotCount_LT = COUNT(*), @LoopID_LT = MIN(ID) FROM #tmpSubWorkOrderLaborTracking;

						WHILE (@LoopID_LT <= @TotCount_LT)
						BEGIN
							SET @swoLaborTrackingId = NULL;
							SELECT @swoLaborTrackingId = [SubWorkOrderLaborTrackingId] FROM #tmpSubWorkOrderLaborTracking WHERE ID = @LoopID_LT;

							IF (ISNULL(@swoLaborTrackingId, 0) != 0)
							BEGIN
								SET @LaborTrackingUpdated = 1;
								SELECT TOP 1 @scanStartTime = StartTime, @UserName= UpdatedBy FROM [dbo].[SubWorkOrderLaborTracking] WITH(NOLOCK) WHERE [SubWorkOrderLaborTrackingId] = @swoLaborTrackingId;

								UPDATE WOT
								SET WOT.[EndTime] = GETUTCDATE(),
									WOT.[TotalHours] = ISNULL(DATEDIFF(MINUTE, @scanStartTime,GETUTCDATE())/60,0),
									WOT.[TotalMinutes] = DATEDIFF(MINUTE, @scanStartTime,GETUTCDATE()) % 60, 
									WOT.[IsCompleted] = 1, 
									WOT.[UpdatedBy] = @UserName, 
									WOT.[UpdatedDate] = GETUTCDATE()
								FROM [dbo].[SubWorkOrderLaborTracking] AS WOT WITH(NOLOCK)
								WHERE WOT.[SubWorkOrderLaborTrackingId] = @swoLaborTrackingId AND WOT.EndTime IS NULL;
							END

							SET @LoopID_LT = @LoopID_LT + 1;
						END
						
						IF (@LaborTrackingUpdated = 1)
						BEGIN
							SELECT @totalHours = SUM(ISNULL(TotalHours,0)), @totalMinutes = SUM(ISNULL(TotalMinutes,0)) 
							FROM [dbo].[SubWorkOrderLaborTracking] 
							WHERE [SubWorkOrderLaborId] = @SubWorkOrderLaborId;
													   						
							SET @totalCalulatedHours = @totalHours + (CONVERT(INT, (@totalMinutes / 60 + (@totalMinutes % 60) / 100.0)))
							SET @totalCalculatedMinutes = CONVERT(INT,(CASE WHEN @totalMinutes > 60 THEN (PARSENAME(CONVERT(DECIMAL(10, 2), (CONVERT(INT, @totalMinutes) / 60 + (CONVERT(INT, @totalMinutes) % 60) / 100.0)), 1)) ELSE @totalMinutes END))
							SET @totalMainHours = CONVERT(DECIMAL(10, 2), (CONVERT(VARCHAR(20), ISNULL(@totalCalulatedHours, 0)) + '.' + CONVERT(VARCHAR(20), FORMAT(ISNULL(@totalCalculatedMinutes, 0), '00'))))

							SET @AdjustedHourstemp = ISNULL(RIGHT('0' + CAST (FLOOR(@AdjustedHours) AS VARCHAR), 2), 0)
							SET @AdjustedMinutestemp = ISNULL(CONVERT(VARCHAR(20), ((100 * CONVERT(INT, (RIGHT('0' + CAST(FLOOR((((@AdjustedHours * 3600) % 3600) / 60)) AS VARCHAR), 2)))) / 60)), 0)
						
							SET @TotalAdjustedHours =  (ISNULL(@totalCalulatedHours, 0.0) + ISNULL(@AdjustedHourstemp, 0.0)) + (CONVERT(INT, ((ISNULL(@totalCalculatedMinutes, 0.0) + ISNULL(@AdjustedMinutestemp, 0.0)) / 60 + ((ISNULL(@totalCalculatedMinutes, 0.0) + ISNULL(@AdjustedMinutestemp,0.0)) % 60) / 100.0))) 
							SET @TotalAdjustedMinutes = convert(INT, (CASE WHEN (ISNULL(@totalCalculatedMinutes, 0) + ISNULL(@AdjustedMinutestemp, 0)) > 60 THEN (PARSENAME(CONVERT(DECIMAL(10, 2), (CONVERT(INT, (ISNULL(@totalCalculatedMinutes, 0) + ISNULL(@AdjustedMinutestemp, 0))) / 60 + (CONVERT(INT, (ISNULL(@totalCalculatedMinutes, 0) + ISNULL(@AdjustedMinutestemp, 0))) % 60) / 100.0)), 1)) ELSE (ISNULL(@totalCalculatedMinutes, 0) + ISNULL(@AdjustedMinutestemp, 0)) END))
							SET @FinalAdjustedHours = CONCAT(CAST(ISNULL(@TotalAdjustedHours, 0) AS INT), '.', FORMAT(ISNULL(@TotalAdjustedMinutes,0), '00'))
						
							UPDATE WL 
							SET [Hours]= @totalMainHours,
								[AdjustedHours] = @FinalAdjustedHours,
								[BurdenRateAmount] = (CASE WHEN ISNULL(BurdaenRatePercentageId, 0) = 0 THEN BurdenRateAmount ELSE (CONVERT(DECIMAL(10, 2), (DirectLaborOHCost * P.PercentValue) / 100)) END),
								[TotalCostPerHour] = (ISNULL(DirectLaborOHCost, 0) + (CASE WHEN ISNULL(BurdaenRatePercentageId, 0) = 0 THEN BurdenRateAmount ELSE (CONVERT(DECIMAL(10, 2), (DirectLaborOHCost * P.PercentValue) / 100)) END))
							FROM [dbo].[SubWorkOrderLabor] WL  WITH(NOLOCK)
							LEFT JOIN dbo.[Percent] P WITH(NOLOCK) ON Wl.BurdaenRatePercentageId = P.PercentId 
							WHERE Wl.[SubWorkOrderLaborId] = @SubWorkOrderLaborId;
						
							UPDATE WL 
							SET [TotalCost] = ISNULL((CAST(@FinalAdjustedHours AS INT) + (@FinalAdjustedHours - CAST(@FinalAdjustedHours AS INT)) / .6) * [TotalCostPerHour], 0),
							    [TaskStatusId] = @CompletedTaskStatusId, 
							    [IsBegin] = 0,
							    [UpdatedBy] = @UserName,
							    [UpdatedDate] = GETUTCDATE()
							FROM [dbo].[SubWorkOrderLabor] WL WITH(NOLOCK)
							WHERE WL.[SubWorkOrderLaborId] = @SubWorkOrderLaborId;
						END
						ELSE
						BEGIN
							UPDATE WL SET TaskStatusId = @CompletedTaskStatusId, [IsBegin] = 0 FROM [dbo].[SubWorkOrderLabor] WL WITH(NOLOCK) WHERE WL.[SubWorkOrderLaborId] = @SubWorkOrderLaborId;
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
              , @AdhocComments     VARCHAR(150)    = 'USP_CompleteAllSubWorkOrderLabor' 
              , @ProcedureParameters VARCHAR(3000)  = '@SubWorkOrderLaborHeaderId = '''+ ISNULL(@SubWorkOrderLaborHeaderId, '') + ''
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