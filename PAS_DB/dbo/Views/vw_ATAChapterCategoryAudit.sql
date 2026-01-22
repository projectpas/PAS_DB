CREATE   VIEW [dbo].[vw_ATAChapterCategoryAudit]
AS
	SELECT ATA.AuditATAChapterCategoryId  AS PkID,
	ATA.ATAChapterCategoryId AS ID,
	ATA.CategoryName as [Category Name],
	ATA.[Description] AS [Description],
	ATA.Memo as [Memo],
	ATA.CreatedBy AS [Created By],
	ATA.CreatedDate AS [Created On],
	ATA.UpdatedBy AS [Updated By],
	ATA.UpdatedDate AS [Updated On],
	ATA.IsActive AS [Is Active],
	ATA.IsDeleted AS [Is Deleted]
	FROM [DBO].ATAChapterCategoryAudit ATA WITH (NOLOCK)