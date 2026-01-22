
CREATE   VIEW [dbo].[vw_IntegrationPortalAudit]
AS
	SELECT ipor.IntegrationPortalAuditId  AS PkID, ipor.IntegrationPortalId AS ID	,ipor.Description,ipor.PortalURL [Portal URL]
	,ipor.CreatedBy AS [Created By],
	ipor.CreatedDate AS [Created Date], ipor.UpdatedBy AS [Updated By], ipor.UpdatedDate AS [Updated Date], ipor.IsActive AS [Is Active], ipor.IsDeleted AS [Is Deleted]
	FROM [DBO].IntegrationPortalAudit ipor WITH (NOLOCK)