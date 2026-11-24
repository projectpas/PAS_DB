CREATE VIEW [dbo].[vw_EngineModel]
AS
SELECT EM.[EngineModelId],
	   EM.[EngineTypeId],
	   EM.[ModelName],
	   EM.[MasterCompanyId],
	   EM.[CreatedBy],
	   EM.[CreatedDate],
	   EM.[UpdatedBy],
	   EM.[UpdatedDate],
	   EM.[IsActive],
	   EM.[IsDeleted],
	   MF.[Name] AS EngineType
FROM [dbo].[EngineModel] EM WITH (NOLOCK)
	LEFT JOIN [dbo].[Manufacturer] MF WITH (NOLOCK) ON EM.[EngineTypeId] = MF.[ManufacturerId]
