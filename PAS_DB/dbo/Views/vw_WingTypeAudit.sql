CREATE   VIEW [dbo].[vw_WingTypeAudit]
AS
	SELECT WT.WingTypeAuditId AS PkID,
	WT.WingTypeId AS ID,
	WT.WingTypeName AS [Wing Type],
	WT.[Description] AS [Description],
	WT.[Memo],
	WT.CreatedBy AS [Created By],
	WT.CreatedDate AS [Created On],
	WT.UpdatedBy AS [Updated By],
	WT.UpdatedDate AS [Updated On],
	WT.IsActive AS [Is Active],
	WT.IsDeleted AS [Is Deleted]
	FROM [DBO].[WingTypeAudit] WT WITH (NOLOCK)