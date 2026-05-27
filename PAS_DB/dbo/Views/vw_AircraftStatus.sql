CREATE  VIEW [dbo].[vw_AircraftStatus]
AS 
	SELECT 
		AIR.AircraftStatusId,
		AIR.Name,
		AIR.Description,
		AIR.SequenceNo,
		AIR.IsActive,
		AIR.IsDeleted,
		AIR.MasterCompanyId,
		AIR.CreatedBy,
		AIR.UpdatedBy,
		AIR.CreatedDate,
		AIR.UpdatedDate
	FROM [dbo].[AircraftStatus] AIR  WITH (NOLOCK)