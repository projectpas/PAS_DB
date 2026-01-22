CREATE   VIEW [DBO].[vw_ATASubChapterList]
AS 
SELECT
	atasc.ATASubChapterId,
	atacc.ATAChapterCategoryId,
	atacc.CategoryName,
	atasc.Description,
	atac.ATAChapterId,
	atac.ATAChapterName,
	atasc.ATASubChapterCode,
	atac.ATAChapterCode,
	atasc.MasterCompanyId,
	atasc.CreatedBy,
	atasc.UpdatedBy,
	atasc.CreatedDate,
	atasc.UpdatedDate,
	atasc.IsActive,
	atasc.IsDeleted
FROM [DBO].[ATASubChapter] atasc WITH (NOLOCK)
LEFT JOIN [DBO].[ATAChapter] atac WITH (NOLOCK) ON atasc.ATAChapterId = atac.ATAChapterId
LEFT JOIN [DBO].[ATAChapterCategory] atacc WITH (NOLOCK) ON atasc.ATAChapterCategoryId = atacc.ATAChapterCategoryId