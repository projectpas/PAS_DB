CREATE   VIEW [DBO].[vw_CreditMemoReasonAudit]
AS
SELECT
	CreditMemoAuditId AS [PkID],
	Id AS [ID],
	Name AS [Credit Memo Reason],
	Description AS [Description],
	CreatedBy AS [Created By],
	UpdatedBy AS [Updated By],
	CreatedDate AS [Created On],
	UpdatedDate AS [Updated On],
	IsActive AS [Is Active],
	IsDeleted AS [Is Deleted]
FROM [DBO].[CreditMemoReasonAudit]