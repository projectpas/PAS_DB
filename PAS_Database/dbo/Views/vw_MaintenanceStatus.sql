CREATE  VIEW [dbo].[vw_MaintenanceStatus]
AS 
	SELECT 
		MS.MaintenanceStatusId,
		MS.Name,
		MS.Description,
		MS.SequenceNo,
		MS.IsActive,
		MS.IsDeleted,
		MS.MasterCompanyId,
		MS.CreatedBy,
		MS.UpdatedBy,
		MS.CreatedDate,
		MS.UpdatedDate
	FROM [dbo].[MaintenanceStatus] MS  WITH (NOLOCK)