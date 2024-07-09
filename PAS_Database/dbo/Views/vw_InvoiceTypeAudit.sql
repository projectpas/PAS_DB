CREATE   VIEW [dbo].[vw_InvoiceTypeAudit] 
AS
	SELECT ITA.InvoiceTypeAuditId AS PkID, InvoiceTypeId AS ID, Description,Memo
	,ITA.CreatedDate As[Created Date], ITA.UpdatedDate As[Updated Date], ITA.IsActive As[Is Active], ITA.CreatedBy As[Created By], ITA.UpdatedBy As[Updated By], ITA.IsDeleted As[Is Deleted]
	FROM dbo.InvoiceTypeAudit AS ITA WITH (NOLOCK)