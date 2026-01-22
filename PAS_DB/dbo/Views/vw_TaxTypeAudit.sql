CREATE   VIEW [dbo].[vw_TaxTypeAudit]
AS
	SELECT tt.TaxTypeAuditId  AS PkID, tt.TaxTypeId AS ID	,tt.[Description]
	,tt.CreatedBy AS [Created By],
	tt.CreatedDate AS [Created Date],tt.UpdatedBy AS [Updated By], tt.UpdatedDate AS [Updated Date], tt.IsActive AS [Is Active], tt.IsDeleted AS [Is Deleted]
	FROM [DBO].TaxTypeAudit tt WITH (NOLOCK)