CREATE   VIEW [DBO].[vw_Master1099Audit]
AS
SELECT
	AuditMaster1099Id AS [PkID],
	Master1099Id AS [ID],
	Name AS [Name],
	SequenceNo AS [Sequence No],
	Description AS [Description],
	Memo AS [Memo],
	CreatedBy AS [Created By],
	UpdatedBy AS [Updated By],
	CreatedDate AS [Created On],
	UpdatedDate AS [Updated On],
	IsActive AS [Is Active],
	IsDeleted AS [Is Deleted]
FROM [DBO].[Master1099Audit]