CREATE    VIEW [dbo].[vw_ATAChapterAudit]
AS	
	SELECT ataca.ATAChapterAuditId AS [PkID],
	ataca.ATAChapterId AS [ID],
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