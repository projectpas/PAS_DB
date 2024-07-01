CREATE   VIEW [DBO].[vw_Ledger_Audit]
AS
SELECT
	LedgerAuditId AS [PkID],
	LedgerId AS [ID],
	LedgerName AS [Ledger Name],
	Description AS [Description],
	Memo AS [Memo],
	CreatedBy AS [Created By],
	UpdatedBy AS [Updated By],
	CreatedDate AS [Created On],
	UpdatedDate AS [Updated On],
	IsActive AS [Is Active],
	IsDeleted AS [Is Deleted]
FROM [DBO].[LedgerAudit]