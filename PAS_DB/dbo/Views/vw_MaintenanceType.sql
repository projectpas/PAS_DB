CREATE  VIEW [dbo].[vw_MaintenanceType]
AS 
	SELECT 
		MS.MaintenanceTypeId,
		MS.MaintenanceType,
		MS.Description,
		MS.IsActive,
		MS.IsDeleted,
		MS.MasterCompanyId,
		MS.CreatedBy,
		MS.UpdatedBy,
		MS.CreatedDate,
		MS.UpdatedDate
	FROM [dbo].[MaintenanceType] MS  WITH (NOLOCK)