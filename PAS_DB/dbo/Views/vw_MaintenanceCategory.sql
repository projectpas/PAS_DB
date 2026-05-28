CREATE   VIEW [dbo].[vw_MaintenanceCategory]
AS 
	SELECT 
		A.MtcCategoryId,
		A.MtcCategory,
		A.Description,
		A.MaintenanceCode,
		A.MasterCompanyId,
		A.CreatedBy,
		A.UpdatedBy,
		A.CreatedDate,
		A.UpdatedDate,
		A.IsActive,
		A.IsDeleted
	FROM [dbo].[MaintenanceCategory] A WITH (NOLOCK)