CREATE    VIEW [dbo].[vw_GLCashFlowClassificationAudit]
AS
	SELECT ipor.GLClassFlowClassificationAuditId  AS PkID, ipor.GLClassFlowClassificationId AS ID ,ipor.GLClassFlowClassificationName,ipor.Memo,ipor.Description
	,ipor.CreatedBy AS [Created By],
	ipor.CreatedDate AS [Created Date], ipor.UpdatedBy AS [Updated By], ipor.UpdatedDate AS [Updated Date], ipor.IsActive AS [Is Active], ipor.IsDeleted AS [Is Deleted]
	FROM [DBO].GLCashFlowClassificationAudit ipor WITH (NOLOCK)