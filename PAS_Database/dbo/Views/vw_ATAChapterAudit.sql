
CREATE   VIEW [DBO].[vw_ATAChapterAudit]
AS	
	SELECT ataca.ATAChapterAuditId AS [PkID],
	ataca.ATAChapterId AS [ID],
	atacc.CategoryName AS [Category],
	ataca.ATAChapterCode AS [Chapter Code],
	ataca.ATAChapterName AS [Chapter Name],
	ataca.Memo AS [Memo],
	ataca.CreatedBy AS [Created By],
	ataca.UpdatedBy AS [Updated By],	
	ataca.CreatedDate AS [Created On],
	ataca.UpdatedDate AS [Updated On],
	ataca.IsActive AS [IsActive],
	ataca.IsDeleted AS [IsDeleted]
	FROM [DBO].[ATAChapterAudit] ataca WITH (NOLOCK)
	LEFT JOIN
	[DBO].[ATAChapterCategory] atacc WITH (NOLOCK)
	ON ataca.ATAChapterCategoryId = atacc.ATAChapterCategoryId