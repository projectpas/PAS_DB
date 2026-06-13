CREATE  VIEW [dbo].[vw_RFQTraceability]
AS 
	SELECT 
		RT.RFQTraceabilityId,
		RT.Traceability,
		RT.Description,
		RT.IsActive,
		RT.IsDeleted,
		RT.MasterCompanyId,
		RT.CreatedBy,
		RT.UpdatedBy,
		RT.CreatedDate,
		RT.UpdatedDate
	FROM [dbo].[RFQTraceability] RT  WITH (NOLOCK)