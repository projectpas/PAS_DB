CREATE VIEW [dbo].[vw_ATAChapter]
AS
SELECT        dbo.ATAChapter.ATAChapterId, dbo.ATAChapter.ATAChapterCode, dbo.ATAChapter.ATAChapterName, dbo.ATAChapter.MasterCompanyId, dbo.ATAChapter.Memo, dbo.ATAChapter.CreatedBy, dbo.ATAChapter.UpdatedBy, 
                         dbo.ATAChapter.CreatedDate, dbo.ATAChapter.UpdatedDate, dbo.ATAChapter.IsActive, dbo.ATAChapter.IsDeleted, dbo.ATAChapter.ATAChapterCategoryId, dbo.ATAChapterCategory.CategoryName as ATAChapterCategory
FROM            dbo.ATAChapter INNER JOIN
                         dbo.ATAChapterCategory ON dbo.ATAChapter.ATAChapterCategoryId = dbo.ATAChapterCategory.ATAChapterCategoryId