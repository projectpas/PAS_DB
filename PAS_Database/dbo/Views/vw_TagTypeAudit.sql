CREATE   VIEW [dbo].[vw_TagTypeAudit]
AS
	SELECT ct.AuditTagTypeId  AS PkID, ct.TagTypeId AS ID	
	,ct.Name [Tag Type Name],ct.Description
	,ct.CreatedBy AS [Created By],
	ct.CreatedDate AS [Created Date], ct.UpdatedBy AS [Updated By], ct.UpdatedDate AS [Updated Date], ct.IsActive AS [Is Active], ct.IsDeleted AS [Is Deleted]
	FROM [DBO].TagTypeAudit ct WITH (NOLOCK)