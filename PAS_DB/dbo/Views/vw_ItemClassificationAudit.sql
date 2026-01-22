
CREATE     VIEW [dbo].[vw_ItemClassificationAudit]
AS
	SELECT ct.ItemClassificationAuditId  AS PkID, ct.ItemClassificationId AS ID	
	,ct.ItemClassificationCode AS [Classification Code]
	,ct.CreatedBy AS [Created By],
	ct.CreatedDate AS [Created Date], 
	ct.UpdatedBy AS [Updated By], 
	ct.UpdatedDate AS [Updated Date], ct.IsActive AS [Is Active], ct.IsDeleted AS [Is Deleted]
	FROM [DBO].[ItemClassificationAudit] ct WITH (NOLOCK)