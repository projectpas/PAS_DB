

CREATE   VIEW [dbo].[vw_VendorAuditTypeAudit]
AS
	SELECT 
	VAA.VendorAuditTypeAuditId AS [PkID],
	VAA.VendorAuditTypeId AS [ID],
	VAA.VendorAuditType AS [Vendor Audit Type],
	VAA.Memo,
	VAA.CreatedDate AS [Created On],
	VAA.CreatedBy AS [Created By],
	VAA.UpdatedDate AS [Updated On],
	VAA.UpdatedBy AS [Updated By],
	VAA.IsActive AS [Is Active],
	VAA.IsDeleted AS [Is Deleted]
	FROM [dbo].[VendorAuditTypeAudit] VAA WITH (NOLOCK)