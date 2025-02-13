
CREATE     VIEW [dbo].[vw_PublicationTemplateSettingAudit]
AS
	SELECT PT.AuditPublicationTemplateId AS PkID,
	PT.PublicationTemplateId AS ID,
	PTT.[Name] AS [Template Name],
	PT.CreatedBy AS [Created By],
	PT.CreatedDate AS [Created On],
	PT.UpdatedBy AS [Updated By],
	PT.UpdatedDate AS [Updated On],
	PT.IsActive AS [Is Active],
	PT.IsDeleted AS [Is Deleted]
	FROM [DBO].[PublicationTemplateAudit] PT WITH (NOLOCK) 
	JOIN [DBO].[PublicationType] PTT WITH (NOLOCK) ON PT.PublicationTypeId = PTT.PublicationTypeId