
CREATE   VIEW [DBO].[vw_ATAChapterList]
AS	
	SELECT 
	atac.ATAChapterId,
	atac.ATAChapterCategoryId,
	atacc.CategoryName AS [CategoryName],
	atac.ATAChapterCode,
	atac.ATAChapterName,
	atac.CreatedBy,
	atac.UpdatedBy,	
	atac.CreatedDate,
	atac.UpdatedDate,
	atac.IsActive,
	atac.IsDeleted,
	atac.Memo,
	atac.MasterCompanyId
	FROM [DBO].[ATAChapter] atac WITH (NOLOCK)
	LEFT JOIN
	[DBO].[ATAChapterCategory] atacc WITH (NOLOCK)
	ON atac.ATAChapterCategoryId = atacc.ATAChapterCategoryId