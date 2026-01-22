
CREATE     VIEW [dbo].[vw_PublicationTemplateSetting]
AS
	SELECT
	PT.PublicationTemplateId,
	PT.PublicationTypeId,
	PTT.[Name] AS [PublicationTypeName],
	PT.EmailBody AS [EmailBody],
	PT.MasterCompanyId,
	PT.CreatedBy AS [CreatedBy],
	PT.CreatedDate AS [CreatedDate],
	PT.UpdatedBy AS [UpdatedBy],
	PT.UpdatedDate AS [UpdatedDate],
	PT.IsActive AS [IsActive],
	PT.IsDeleted AS [IsDeleted]
	FROM [DBO].[PublicationTemplate] PT WITH (NOLOCK) 
	JOIN [DBO].[PublicationType] PTT WITH (NOLOCK) ON PT.PublicationTypeId = PTT.PublicationTypeId