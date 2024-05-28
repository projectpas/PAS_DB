CREATE   VIEW [dbo].[vw_TaxRateAudit]
AS
	SELECT tt.TaxRateAuditId  AS PkID, tt.TaxRateId AS ID	,tt.TaxRate [TaxRate] 
	,tt.CreatedBy AS [Created By],
	tt.CreatedDate AS [Created Date], tt.UpdatedBy AS [Updated By], tt.UpdatedDate AS [Updated Date], tt.IsActive AS [Is Active], tt.IsDeleted AS [Is Deleted]
	FROM [DBO].TaxRateAudit tt WITH (NOLOCK)