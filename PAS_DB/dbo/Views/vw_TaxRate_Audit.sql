CREATE   VIEW [DBO].[vw_TaxRate_Audit]
AS
SELECT 
	TaxRateAuditId AS [PkID],
	TaxRateId  AS [ID],
	TaxRate AS [TaxRate],
	Memo AS [Memo],
	CreatedBy AS [Created By],
	UpdatedBy AS [Updated By],
	CreatedDate AS [Created On],
	UpdatedDate AS [Updated On],
	IsActive AS [IsActive],
	IsDeleted AS [IsDeleted]
FROM [DBO].[TaxRateAudit]