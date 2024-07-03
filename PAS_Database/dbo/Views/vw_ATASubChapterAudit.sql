
CREATE   VIEW [DBO].[vw_ATASubChapterAudit]
AS
SELECT
	atasca.ATASubChapterAuditId AS [PkID],
	atasca.ATASubChapterId AS [ID],
	atacc.CategoryName AS [ATA Category Name],
	atac.ATAChapterCode AS [Chapter Code],
	atac.ATAChapterName AS [Chapter Name],
	atasca.ATASubChapterCode AS [Sub Chapter Code],
	atasca.Description AS [Sub Chapter Name],
	atasca.Memo AS [Memo],
	atasca.CreatedBy AS [Created By],
	atasca.UpdatedBy AS [Updated By],
	atasca.IsActive AS [IsActive],
	atasca.IsDeleted AS [IsDeleted]
FROM [DBO].[ATASubChapterAudit] atasca WITH (NOLOCK)
LEFT JOIN [DBO].[ATAChapterCategory] atacc WITH (NOLOCK) ON atacc.ATAChapterCategoryId = atasca.ATAChapterCategoryId
LEFT JOIN [dbo].[ATAChapter] atac WITH (NOLOCK) ON atac.ATAChapterId = atasca.ATAChapterId