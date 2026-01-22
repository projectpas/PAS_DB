CREATE VIEW [dbo].[vw_ATAReferenceAudit]
AS
	SELECT AuditATAReferenceId AS PkID,
	ATAReferenceId AS ID,
	ATAReference AS [ATA Reference],
	AR.CreatedBy AS [Created By], 
	AR.UpdatedBy AS [Updated By],
	AR.CreatedDate AS [Created Date], 
	AR.UpdatedDate AS [Updated Date],
	AR.IsActive AS [Is Active], 
	AR.IsDeleted AS [Is Deleted]
	FROM [DBO].[ATAReferenceAudit] AR WITH (NOLOCK)