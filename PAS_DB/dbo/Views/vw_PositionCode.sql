CREATE    VIEW [dbo].[vw_PositionCode]
AS 
	SELECT 
		PC.PositionCodeId,
		PC.Code,
		PC.Description,
		PC.MasterCompanyId,
		PC.CreatedBy,
		PC.UpdatedBy,
		PC.CreatedDate,
		PC.UpdatedDate,
		PC.IsActive,
		PC.IsDeleted
	FROM [dbo].[PositionCode] PC  WITH (NOLOCK)