CREATE   VIEW [dbo].[vw_VendorAuditType]
AS
	SELECT 
	VA.VendorAuditTypeId,
	VA.VendorAuditType,
	VA.Memo,
	VA.MasterCompanyId,
	VA.CreatedDate,
	VA.CreatedBy,
	VA.UpdatedDate,
	VA.UpdatedBy,
	VA.IsActive,
	VA.IsDeleted
	FROM [dbo].[VendorAuditType] VA WITH (NOLOCK)