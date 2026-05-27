CREATE    VIEW [dbo].[vw_MaintenanceClass]
AS 
	SELECT 
		MC.MaintenanceClassId,
		MC.Name,
		MC.Description,
		MC.MasterCompanyId,
		MC.CreatedBy,
		MC.UpdatedBy,
		MC.CreatedDate,
		MC.UpdatedDate,
		MC.IsActive,
		MC.IsDeleted
	FROM [dbo].[MaintenanceClass] MC  WITH (NOLOCK)