CREATE   VIEW [DBO].[vw_GLAccountClassAudit]
AS
SELECT
	GLAccountClassAuditId AS [PkID],
	GLAccountClassId AS [ID],
	GLAccountClassName AS [Name],
	GLAccountClassMemo As [Memo],
	CreatedBy AS [Created By],
	UpdatedBy AS [Updated By],
	UpdatedDate AS [Updated On],
	IsActive AS [IsActive],
	IsDeleted AS [IsDeleted]
FROM [DBO].[GLAccountClassAudit]