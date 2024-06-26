--DROP VIEW [dbo].[vw_LeadSourceAudit]
CREATE VIEW [dbo].[vw_LeadSourceAudit]
AS
	SELECT ipor.LeadSourceAuditId  AS PkID, ipor.LeadSourceId AS ID	,ipor.Description , ipor.LeadSources,
	ipor.CreatedBy AS [Created By],
	ipor.CreatedDate AS [Created Date], ipor.UpdatedBy AS [Updated By], ipor.UpdatedDate AS [Updated Date], ipor.IsActive AS [Is Active], ipor.IsDeleted AS [Is Deleted]
	FROM [DBO].LeadSourceAudit ipor WITH (NOLOCK)