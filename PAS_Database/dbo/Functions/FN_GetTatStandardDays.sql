-- =============================================
-- Author:		Subhash Saliya
-- Create date: 01 jun 2022
-- Description:	Get Expire Days in Stockline
-- =============================================
Create     FUNCTION [dbo].[FN_GetTatStandardDays]
(
	@WorkOrderPartNoId as bigint
)
RETURNS int
AS
BEGIN
	
				 Declare @WorkScopeId bigint
				  Declare @ItemMasterId bigint
				 Declare @TATDaysStandard int = null 
				 Declare @stdType varchar(100) = null 
	
	            SELECT @WorkScopeId = WorkOrderScopeId,@ItemMasterId=ItemMasterId FROM dbo.WorkOrderPartNumber WOP WITH(NOLOCK) 
				WHERE WOP.ID = @WorkOrderPartNoId  

				SELECT @stdType = WorkScopeCodeNew FROM dbo.WorkScope wosp WITH(NOLOCK) 
				WHERE wosp.WorkScopeId = @WorkScopeId 

				SELECT @TATDaysStandard = (case when @stdType= 'OVERHAUL' then isnull(TurnTimeOverhaulHours,0) when  @stdType= 'REPAIR' then isnull(TurnTimeRepairHours,0) when   @stdType= 'BENCHCHECK' then isnull(turnTimeBenchTest,0) when   @stdType= 'MFG' then isnull(turnTimeMfg,0)  else 0  end) FROM dbo.ItemMaster IM WITH(NOLOCK) 
				WHERE IM.ItemMasterId = @ItemMasterId 
				

	
	return Isnull(@TATDaysStandard,0)


END