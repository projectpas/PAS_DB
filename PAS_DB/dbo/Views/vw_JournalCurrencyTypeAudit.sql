CREATE   VIEW [DBO].[vw_JournalCurrencyTypeAudit]
AS
SELECT 
	AuditJournalCurrencyTypeId AS [PkID],
	ID AS [ID],
	JournalCurrencyTypeName AS [Name],
	Description AS [Description],
	CreatedBy AS [Created By],
	UpdatedBy AS [Updated By],
	CreatedDate AS [Created On],
	UpdatedDate AS [Updated On],
	IsActive AS [IsActive],
	IsDeleted AS [IsDeleted]
FROM [dbo].[JournalCurrencyTypeAudit]