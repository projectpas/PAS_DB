
CREATE    VIEW [dbo].[vw_AircraftSection]
AS 
	SELECT 
		A.AircraftSectionId,
		A.Section,
		A.Description,
		A.MasterCompanyId,
		A.CreatedBy,
		A.UpdatedBy,
		A.CreatedDate,
		A.UpdatedDate,
		A.IsActive,
		A.IsDeleted
	FROM [dbo].[AircraftSection] A  WITH (NOLOCK)