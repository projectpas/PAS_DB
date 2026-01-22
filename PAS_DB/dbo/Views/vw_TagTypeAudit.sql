CREATE   VIEW [dbo].[vw_TagTypeAudit]
AS
	SELECT ipor.AuditTagTypeId  AS PkID, ipor.TagTypeId AS ID ,ipor.Name,Ipor.Description
	,ipor.CreatedBy AS [Created By],
	ipor.CreatedDate AS [Created Date], ipor.UpdatedBy AS [Updated By], ipor.UpdatedDate AS [Updated Date], ipor.IsActive AS [Is Active], ipor.IsDeleted AS [Is Deleted]
	FROM [DBO].TagTypeAudit ipor WITH (NOLOCK)