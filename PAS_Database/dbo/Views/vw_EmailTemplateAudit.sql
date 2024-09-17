CREATE    VIEW [dbo].[vw_EmailTemplateAudit]
AS
	SELECT ET.AuditEmailTemplateId AS PkID,
	ET.EmailTemplateId AS ID,
	ET.ModuleName as [Module Name],
	ET.SubModuleName as [Sub Module Name],
	ET.IsTemplateType as [Is Email Template],
	ET.EmailTemplateTypeId,
	ETT.EmailTemplateTypeName as [Template Name],
	ET.SubjectName AS [Subject],
	ET.EmailBody AS [Email Body],
	ET.RevNo as [Rev No],
	ET.RevDate [Rev Date],
	ET.TemplateName,
	ET.TemplateDescription,	
	ET.CreatedBy AS [Created By],
	ET.CreatedDate AS [Created On],
	ET.UpdatedBy AS [Updated By],
	ET.UpdatedDate AS [Updated On],
	ET.IsActive AS [Is Active],
	ET.IsDeleted AS [Is Deleted]
	FROM [DBO].[EmailTemplateAudit] ET WITH (NOLOCK) 
	JOIN [DBO].[EmailTemplateType] ETT WITH (NOLOCK) ON ET.EmailTemplateTypeId = ETT.EmailTemplateTypeId