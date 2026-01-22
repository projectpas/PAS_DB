CREATE VIEW [dbo].[vw_OrganizationTagTypeAudit]
AS
	SELECT C.AuditOrganizationTagTypeId AS PkID, C.OrganizationTagTypeId AS ID, C.[Name] AS [Name], C.CreatedBy AS [Created By],
	C.CreatedDate AS [Created Date], C.UpdatedBy AS [Updated By], C.UpdatedDate AS [Updated Date], C.IsActive AS [Is Active], C.IsDeleted AS [Is Deleted]
	FROM [DBO].[OrganizationTagTypeAudit] C WITH (NOLOCK)