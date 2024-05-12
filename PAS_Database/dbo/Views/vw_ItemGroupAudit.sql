
CREATE     VIEW [dbo].[vw_ItemGroupAudit]
AS
	SELECT ct.ItemGroupAuditId  AS PkID, ct.ItemGroupId AS ID	
	,ct.ItemGroupCode AS [ItemGroup Code]
	,ct.CreatedBy AS [Created By],
	ct.CreatedDate AS [Created Date], 
	ct.UpdatedBy AS [Updated By], 
	ct.UpdatedDate AS [Updated Date], ct.IsActive AS [Is Active], ct.IsDeleted AS [Is Deleted]
	FROM [DBO].[ItemGroupAudit] ct WITH (NOLOCK)