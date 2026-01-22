CREATE    VIEW [dbo].[vw_POROCategoryAudit]
AS
	SELECT ipor.POROCategoryAuditId  AS PkID,
	ipor.POROCategoryId AS ID 
	,ipor.CategoryName as [Category Name],
	ipor.Memo,
	Ipor.IsPO as [Is PO],
	Ipor.IsRO as [Is RO]
	,ipor.CreatedBy AS [Created By],
	ipor.CreatedDate AS [Created Date], ipor.UpdatedBy AS [Updated By], ipor.UpdatedDate AS [Updated Date], ipor.IsActive AS [Is Active], ipor.IsDeleted AS [Is Deleted]
	FROM [DBO].POROCategoryAudit ipor WITH (NOLOCK)