

CREATE   VIEW [dbo].[vw_VendorStatusAudit]
AS
	SELECT 
	VSA.[VendorStatusAuditId] AS [PkID],
	VSA.[VendorStatusId] AS [ID],
	VSA.[Description] AS [Vendor Status],
	VSA.Memo,
	VSA.CreatedDate AS [Created On],
	VSA.CreatedBy AS [Created By],
	VSA.UpdatedDate AS [Updated On],
	VSA.UpdatedBy AS [Updated By],
	VSA.IsActive AS [Is Active],
	VSA.IsDeleted AS [Is Deleted]
	FROM [dbo].[VendorStatusAudit] VSA WITH (NOLOCK)