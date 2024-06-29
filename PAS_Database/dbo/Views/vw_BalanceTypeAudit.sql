CREATE   VIEW [DBO].[vw_BalanceTypeAudit]
AS
SELECT
	BalanceTypeId AS [PkID],
	ID AS [ID],
	BalanceTypeName AS [Name],
	Description AS [Description],
	Memo AS [Memo],
	CreatedBy AS [Created By],
	UpdatedBy AS [Updated By],
	CreatedDate AS [Created On],
	UpdatedDate AS [Updated On],
	IsActive AS [Is Active],
	IsDeleted AS [Is Deleted]
FROM [DBO].[BalanceTypeAudit]