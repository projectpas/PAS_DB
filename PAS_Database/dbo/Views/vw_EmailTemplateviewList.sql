
CREATE    VIEW [dbo].[vw_EmailTemplateviewList]
AS
	SELECT
	ET.EmailTemplateId,
	ET.ModuleName,
	ET.SubModuleName,
	ET.IsTemplateType,
	ET.EmailTemplateTypeId,
	ETT.EmailTemplateTypeName,
	ET.SubjectName,
	ET.EmailBody AS [EmailBody],
	ET.RevNo as [RevNo],
	ET.RevDate [RevDate],
	ET.MasterCompanyId,
	ET.CreatedBy AS [CreatedBy],
	ET.CreatedDate AS [CreatedDate],
	ET.UpdatedBy AS [UpdatedBy],
	ET.UpdatedDate AS [UpdatedDate],
	ET.IsActive AS [IsActive],
	ET.IsDeleted AS [IsDeleted]
	FROM [DBO].[EmailTemplate] ET WITH (NOLOCK) 
	JOIN [DBO].[EmailTemplateType] ETT WITH (NOLOCK) ON ET.EmailTemplateTypeId = ETT.EmailTemplateTypeId