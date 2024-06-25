CREATE     VIEW [dbo].[vw_EmailTemplate]
AS
	SELECT dbo.EmailTemplate.EmailTemplateId,
		   dbo.EmailTemplate.TemplateName, 
		   dbo.EmailTemplate.TemplateDescription, 
		   dbo.EmailTemplate.MasterCompanyId, 
		   dbo.EmailTemplate.CreatedBy, 
		   dbo.EmailTemplate.UpdatedBy, 
           dbo.EmailTemplate.CreatedDate, 
		   dbo.EmailTemplate.UpdatedDate, 
		   dbo.EmailTemplate.IsActive,		   
		   dbo.EmailTemplate.IsDeleted, 
		   dbo.EmailTemplate.EmailBody,
		   dbo.EmailTemplate.SubjectName,
		   dbo.EmailTemplate.EmailTemplateTypeId,
		   dbo.EmailTemplateType.EmailTemplateType,
		   dbo.EmailTemplate.RevNo,
		   dbo.EmailTemplate.RevDate,
		   dbo.EmailTemplateType.EmailTemplateTypeName
	FROM   dbo.EmailTemplate INNER JOIN dbo.EmailTemplateType ON dbo.EmailTemplate.EmailTemplateTypeId = dbo.EmailTemplateType.EmailTemplateTypeId;