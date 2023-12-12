

CREATE VIEW [dbo].[vw_atasubchapter]
AS
SELECT        dbo.ATASubChapter.ATASubChapterId, dbo.ATASubChapter.ATASubChapterCode, dbo.ATASubChapter.Description, dbo.ATASubChapter.Memo, dbo.ATASubChapter.MasterCompanyId, dbo.ATASubChapter.CreatedBy, 
                         dbo.ATASubChapter.UpdatedBy, dbo.ATASubChapter.CreatedDate, dbo.ATASubChapter.UpdatedDate, dbo.ATASubChapter.IsActive, dbo.ATASubChapter.IsDeleted, dbo.ATASubChapter.ATAChapterId, 
                         dbo.ATAChapter.ATAChapterCode,dbo.ATAChapter.ATAChapterName, dbo.ATAChapterCategory.CategoryName as ATAChapterCategory, dbo.ATAChapterCategory.ATAChapterCategoryId
FROM            dbo.ATAChapterCategory INNER JOIN
                         dbo.ATAChapter ON dbo.ATAChapterCategory.ATAChapterCategoryId = dbo.ATAChapter.ATAChapterCategoryId INNER JOIN
                         dbo.ATASubChapter ON dbo.ATAChapter.ATAChapterId = dbo.ATASubChapter.ATAChapterId