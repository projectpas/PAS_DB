CREATE   VIEW [DBO].[vw_GLAccountCategoryAudit]
AS
SELECT
	GLAccountCategoryAuditId AS [PkID],
	GLAccountCategoryId AS [ID],
	GLCID AS [GL Code ID],
	GLAccountCategoryName AS [Name],
	CreatedBy AS [Created By],
	UpdatedBy AS [Updated By],
	CreatedDate AS [Created On],
	UpdatedDate AS [Updated On],
	IsActive AS [IsActive],
	IsDeleted AS [IsDeleted]
FROM [DBO].[GLAccountCategoryAudit]