CREATE  VIEW [dbo].[vw_LeaseType]
AS 
	SELECT 
		LT.LeaseTypeId,
		LT.LeaseType,
		LT.Description,
		LT.IsActive,
		LT.IsDeleted,
		LT.MasterCompanyId,
		LT.CreatedBy,
		LT.UpdatedBy,
		LT.CreatedDate,
		LT.UpdatedDate
	FROM [dbo].[LeaseType] LT  WITH (NOLOCK)