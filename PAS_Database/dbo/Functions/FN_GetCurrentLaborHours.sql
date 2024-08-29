
-- =============================================
-- Author:		Subhash Saliya
-- Create date: 01 jun 2022
-- Description:	Get Expire Days in Stockline
--select dbo.FN_GetCurrentLaborHours(1,0)
-- =============================================
CREATE       FUNCTION [dbo].[FN_GetCurrentLaborHours]
(
	@WorkOrderLaborId as bigint,
	@IsSubworkorder as bit
)
RETURNS decimal(18,2)
AS
BEGIN
	
	
	             Declare @TotalHours int=0
			     Declare @TotalMinutes int=0,
				 @AdjustedHours decimal(18,2) = 0 ,
				 @AdjustedHourstemp INT = 0 ,
				 @TotalAdjustedHours INT = 0 ,
				 @TotalAdjustedMinutes INT = 0 ,
				 @AdjustedMinutestemp INT = 0 ,
				 @FinalAdjustedHours decimal(18,2) = 0 ,
				 @totalCalulatedHours int = 0, 
				 @totalCalculatedMinutes int = 0,
				 @totalMainHours decimal(10,2) = 0 ,
				 @isrunningtaskcount int = 0

				 if(@IsSubworkorder =0)
				 begin
				   select 	@TotalHours= ISNULL(DATEDIFF(MINUTE, wolt.StartTime,GETUTCDATE())/60,0),
							@TotalMinutes =  DATEDIFF(MINUTE, wolt.StartTime,GETUTCDATE()) % 60  
							FROM DBO.WorkOrderLaborTracking wolt WITH(NOLOCK)
				    LEFT JOIN DBO.WorkOrderLabor wol  WITH(NOLOCK) on wolt.WorkOrderLaborId = wol.WorkOrderLaborId
					LEFT JOIN DBO.WorkOrderLaborHeader woh  WITH(NOLOCK) on woh.WorkOrderLaborHeaderId = wol.WorkOrderLaborHeaderId
				    WHERE wol.WorkOrderLaborId = @WorkOrderLaborId AND wol.IsDeleted = 0 and ISNULL(wolt.IsCompleted,0)=0


					select 	@isrunningtaskcount= count(wolt.WorkOrderLaborTrackingId)  FROM DBO.WorkOrderLaborTracking wolt WITH(NOLOCK)
				    LEFT JOIN DBO.WorkOrderLabor wol  WITH(NOLOCK) on wolt.WorkOrderLaborId = wol.WorkOrderLaborId
					LEFT JOIN DBO.WorkOrderLaborHeader woh  WITH(NOLOCK) on woh.WorkOrderLaborHeaderId = wol.WorkOrderLaborHeaderId
				    WHERE wol.WorkOrderLaborId = @WorkOrderLaborId AND wol.IsDeleted = 0 and ISNULL(wolt.IsCompleted,0)=1

					if(@isrunningtaskcount >0)
					begin
						  SELECT @totalHours =  @totalHours+ SUM(ISNULL(TotalHours,0)), @totalMinutes = @TotalMinutes+ SUM(ISNULL(TotalMinutes,0))  FROM DBO.WorkOrderLaborTracking wolt WITH(NOLOCK)
				          LEFT JOIN DBO.WorkOrderLabor wol  WITH(NOLOCK) on wolt.WorkOrderLaborId = wol.WorkOrderLaborId
					      LEFT JOIN DBO.WorkOrderLaborHeader woh  WITH(NOLOCK) on woh.WorkOrderLaborHeaderId = wol.WorkOrderLaborHeaderId
				          WHERE wol.WorkOrderLaborId = @WorkOrderLaborId AND wol.IsDeleted = 0 and ISNULL(wolt.IsCompleted,0)=1
					END



				 End
				 else
				 begin
				    select 	@TotalHours= ISNULL(DATEDIFF(MINUTE, wolt.StartTime,GETUTCDATE())/60,0),
								@TotalMinutes =  DATEDIFF(MINUTE, wolt.StartTime,GETUTCDATE()) % 60  FROM DBO.SubWorkOrderLaborTracking wolt WITH(NOLOCK)
				    LEFT JOIN DBO.SubWorkOrderLabor wol  WITH(NOLOCK) on wolt.SubWorkOrderLaborId = wol.SubWorkOrderLaborId
					LEFT JOIN DBO.SubWorkOrderLaborHeader woh  WITH(NOLOCK) on woh.SubWorkOrderLaborHeaderId = wol.SubWorkOrderLaborHeaderId
				    WHERE wol.SubWorkOrderLaborId = @WorkOrderLaborId AND wol.IsDeleted = 0 and ISNULL(wolt.IsCompleted,0)=0


					SELECT @isrunningtaskcount= count(wolt.SubWorkOrderLaborTrackingId)  FROM DBO.SubWorkOrderLaborTracking wolt WITH(NOLOCK)
				    LEFT JOIN DBO.SubWorkOrderLabor wol  WITH(NOLOCK) on wolt.SubWorkOrderLaborId = wol.SubWorkOrderLaborId
					LEFT JOIN DBO.SubWorkOrderLaborHeader woh  WITH(NOLOCK) on woh.SubWorkOrderLaborHeaderId = wol.SubWorkOrderLaborHeaderId
				    WHERE wol.SubWorkOrderLaborId = @WorkOrderLaborId AND wol.IsDeleted = 0 and ISNULL(wolt.IsCompleted,0)=1


					if(@isrunningtaskcount >0)
					begin
						  SELECT @totalHours =  @totalHours+ SUM(ISNULL(TotalHours,0)), @totalMinutes = @TotalMinutes+ SUM(ISNULL(TotalMinutes,0))  FROM DBO.SubWorkOrderLaborTracking wolt WITH(NOLOCK)
				    LEFT JOIN DBO.SubWorkOrderLabor wol  WITH(NOLOCK) on wolt.SubWorkOrderLaborId = wol.SubWorkOrderLaborId
					LEFT JOIN DBO.SubWorkOrderLaborHeader woh  WITH(NOLOCK) on woh.SubWorkOrderLaborHeaderId = wol.SubWorkOrderLaborHeaderId
				    WHERE wol.SubWorkOrderLaborId = @WorkOrderLaborId AND wol.IsDeleted = 0 and ISNULL(wolt.IsCompleted,0)=1
					END

					

				 end

				 
					
					set @totalCalulatedHours = @totalHours + (CONVERT(int,(@totalMinutes / 60 + (@totalMinutes % 60) / 100)))
					set @totalCalculatedMinutes = convert(int,(CASE WHEN @totalMinutes > 60 THEN (PARSENAME(CONVERT(decimal(10,2),(convert(int,@totalMinutes) / 60 + (convert(int,@totalMinutes) % 60) / 100.0)),1)) ELSE @totalMinutes END))
					set @totalMainHours = convert(decimal(10,2),(convert(varchar(20),isnull(@totalCalulatedHours,0)) +'.'+ convert(varchar(20),format(isnull(@totalCalculatedMinutes,0),'00'))))
				

	
	return Isnull(@totalMainHours,0)


END