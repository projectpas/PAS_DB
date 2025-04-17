CREATE   VIEW [dbo].[vw_CommonTeardownTemplateAudit]
AS
	SELECT CTT.CommonTeardownTemplateAuditId AS PkID,
	CTT.CommonTeardownTemplateId AS ID,
	CT.[Name] AS [Template Name],
	CTT.CreatedBy AS [Created By],
	CTT.CreatedDate AS [Created On],
	CTT.UpdatedBy AS [Updated By],
	CTT.UpdatedDate AS [Updated On],
	CTT.IsActive AS [Is Active],
	CTT.IsDeleted AS [Is Deleted]
	FROM [DBO].[CommonTeardownTemplateAudit] CTT WITH (NOLOCK) 
	JOIN [DBO].[CommonTeardownType] CT WITH (NOLOCK) ON CTT.CommonTeardownTypeId = CT.CommonTeardownTypeId