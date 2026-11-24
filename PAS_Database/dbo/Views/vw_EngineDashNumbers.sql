CREATE VIEW [dbo].[vw_EngineDashNumbers]
AS
SELECT ED.[EngineDashNumberId],
	   ED.[EngineTypeId],
	   ED.[EngineModelId],
	   ED.[DashNumber],
	   ED.[MasterCompanyId],
	   ED.[CreatedBy],
	   ED.[CreatedDate],
	   ED.[UpdatedBy],
	   ED.[UpdatedDate],
	   ED.[IsActive],
	   ED.[IsDeleted],
	   MF.[Name]      AS EngineType,
	   EM.[ModelName] AS EngineModel
FROM [dbo].[EngineDashNumber] ED WITH (NOLOCK)
	LEFT JOIN [dbo].[Manufacturer] MF WITH (NOLOCK) ON ED.[EngineTypeId] = MF.[ManufacturerId]
	LEFT JOIN [dbo].[EngineModel]  EM WITH (NOLOCK) ON ED.[EngineModelId] = EM.[EngineModelId]
