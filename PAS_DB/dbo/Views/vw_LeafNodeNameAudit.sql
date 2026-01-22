CREATE   VIEW [DBO].[vw_LeafNodeNameAudit]
AS
SELECT
	LeafNodeNameAuditId AS [PkID],
	LeafNodeNameId AS [ID],
	Name AS [Leaf Node Name] ,
	Description AS [Description],
	Memo AS [Memo],
	CreatedBy AS [Created By],
	UpdatedBy AS [Updated By],
	CreatedDate AS [Created On],
	UpdatedDate AS [Updated On],
	IsActive AS [Is Active],
	IsDeleted AS [Is Deleted]
FROM [DBO].[LeafNodeNameAudit]