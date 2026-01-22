CREATE   VIEW [dbo].[vw_PriorityAudit]
AS
	SELECT ipor.PriorityAuditId  AS PkID, ipor.PriorityId AS ID ,ipor.Description
	,ipor.CreatedBy AS [Created By],
	ipor.CreatedDate AS [Created Date], ipor.UpdatedBy AS [Updated By], ipor.UpdatedDate AS [Updated Date], ipor.IsActive AS [Is Active], ipor.IsDeleted AS [Is Deleted]
	FROM [DBO].PriorityAudit ipor WITH (NOLOCK)