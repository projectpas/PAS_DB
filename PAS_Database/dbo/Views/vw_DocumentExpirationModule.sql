CREATE    VIEW [dbo].[vw_DocumentExpirationModule]
AS
	SELECT DISTINCT
	       CDD.[ModuleId],
	       DMN.[ModuleName],
	       CDD.[MasterCompanyId]
	FROM [dbo].[CommonDocumentDetails] CDD WITH (NOLOCK)
	INNER JOIN [dbo].[vw_DocumentModuleName] DMN ON DMN.[AttachmentModuleId] = CDD.[ModuleId]
	WHERE CDD.[IsActive] = 1
	  AND CDD.[IsDeleted] = 0;