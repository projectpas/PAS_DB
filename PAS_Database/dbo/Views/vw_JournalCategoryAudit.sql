CREATE   VIEW [DBO].[vw_JournalCategoryAudit]
AS
	SELECT 
	JournalCategoryID As [PkID],
	Id AS [ID],
	CategoryName AS [NAME],
	Memo As [Memo],
	CreatedBy AS [Created By],
	UpdatedBy AS [Updated By],
	CreatedDate AS [Created Date],
	UpdatedDate AS [Updated Date],
	IsActive AS [IsActive],
	IsDeleted AS [IsDeleted]
FROM [DBO].[JournalCategoryAudit]