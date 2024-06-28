CREATE   VIEW [DBO].[vw_ExpenditureCategoryAudit]
AS 
SELECT 
	ExpenditureCategoryAuditId AS [PkID],
	ExpenditureCategoryId AS [ID],
	Description AS [Description],
	Memo AS [Memo],
	CreatedBy AS [Created By],
	UpdatedBy AS [Updated By],
	CreatedDate AS [Created Date],
	UpdatedDate AS [Updated Date],
	IsActive AS [IsActive],
	IsDeleted AS [IsDeleted]
FROM [DBO].[ExpenditureCategoryAudit]