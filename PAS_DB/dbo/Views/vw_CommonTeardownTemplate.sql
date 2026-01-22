CREATE   VIEW [dbo].[vw_CommonTeardownTemplate]
AS
	SELECT
	CTT.CommonTeardownTemplateId,
	CTT.CommonTeardownTypeId,
	CT.[Name] AS [CommonTeardownTypeName],
	CTT.TemplateBody AS [TemplateBody],
	CTT.MasterCompanyId,
	CTT.CreatedBy AS [CreatedBy],
	CTT.CreatedDate AS [CreatedDate],
	CTT.UpdatedBy AS [UpdatedBy],
	CTT.UpdatedDate AS [UpdatedDate],
	CTT.IsActive AS [IsActive],
	CTT.IsDeleted AS [IsDeleted]
	FROM [DBO].[CommonTeardownTemplate] CTT WITH (NOLOCK) 
	JOIN [DBO].[CommonTeardownType] CT WITH (NOLOCK) ON CTT.CommonTeardownTypeId = CT.CommonTeardownTypeId