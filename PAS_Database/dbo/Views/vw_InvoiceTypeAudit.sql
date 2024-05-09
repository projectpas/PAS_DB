
CREATE   VIEW [dbo].[vw_InvoiceTypeAudit] 
AS
	SELECT ITA.InvoiceTypeAuditId AS PkID, InvoiceTypeId AS ID, Description,Memo
	,ITA.CreatedDate, ITA.UpdatedDate, ITA.IsActive, ITA.MasterCompanyId, ITA.CreatedBy, ITA.UpdatedBy, ITA.IsDeleted
	FROM dbo.InvoiceTypeAudit AS ITA WITH (NOLOCK)