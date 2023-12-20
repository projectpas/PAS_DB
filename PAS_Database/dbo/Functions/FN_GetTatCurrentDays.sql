-- =============================================
-- Author:		Subhash Saliya
-- Create date: 01 jun 2022
-- Description:	Get Expire Days in Stockline
-- =============================================
Create       FUNCTION [dbo].[FN_GetTatCurrentDays]
(
	@WorkOrderPartNoId as bigint
)
RETURNS int
AS
BEGIN
	
	DECLARE @DiffDays int = null
	DECLARE @DiffDays1 int = null
	DECLARE @receivedDate Datetime = null
	DECLARE @shippedDate Datetime= null 
	DECLARE @approvedDate Datetime= null 
	DECLARE @sentDate Datetime = null
	DECLARE @currentdate Datetime= GETDATE() 
	DECLARE @WorkOrderId bigint 
	DECLARE @TATDaysCurrent int = null 
	DECLARE @MPNStageId BIGINT = null
	DECLARE @CurrentStageDays int = null 

	SELECT TOP 1 @CurrentStageDays = ISNULL(DATEDIFF(day, TT.StatusChangedDate, GETDATE()), 0)
	FROM dbo.WorkOrderTurnArroundTime TT WITH(NOLOCK)
	JOIN dbo.WorkOrderPartNumber WPN WITH(NOLOCK) ON WPN.ID = tt.WorkOrderPartNoId AND WPN.WorkOrderStageId = TT.CurrentStageId
	WHERE ID = @WorkOrderPartNoId  ORDER BY TT.StatusChangedDate DESC

	SELECT @TATDaysCurrent =  ISNULL((SUM(WTT.[Days])+ (SUM(WTT.[Hours])/24)+ (SUM(WTT.[Mins])/1440)),0)  + @CurrentStageDays
	FROM  dbo.WorkOrderTurnArroundTime WTT WITH(NOLOCK) 
		JOIN dbo.WorkOrderPartNumber WPN WITH(NOLOCK) ON WTT.WorkOrderPartNoId = WPN.ID
		LEFT JOIN dbo.WorkOrderStage WOSG WITH(NOLOCK) ON WTT.CurrentStageId = WOSG.WorkOrderStageId and wosg.IncludeInStageReport=1 
	WHERE WPN.ID = @WorkOrderPartNoId  
	GROUP BY WTT.WorkOrderPartNoId, WPN.ID
	
	RETURN Isnull(@TATDaysCurrent,0)
	             
END