CREATE   VIEW [DBO].[vw_RMAReasonAudit]
AS
SELECT
	RMAReasonAuditId AS [PkID],
	RMAReasonId AS [ID],
	Reason AS [Reason],
	Memo AS [Memo],
	CreatedBy AS [Created By],
	UpdatedBy AS [Updated By],
	CreatedDate AS [Created On],
	UpdatedDate AS [Updated On],
	IsActive AS [Is Active],
	IsDeleted AS [Is Deleted]
FROM [DBO].[RMAReasonAudit]