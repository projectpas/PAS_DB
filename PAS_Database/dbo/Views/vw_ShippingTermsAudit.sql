CREATE   VIEW [dbo].[vw_ShippingTermsAudit]
AS
	SELECT ST.AuditShippingTermsId  AS PkID,
	ST.ShippingTermsId AS ID,
	ST.Name as [Shipping Term Name],
	ST.[Description] AS [Description],
	ST.SequenceNo as [Sequence Num],
	ST.Memo,
	ST.CreatedBy AS [Created By],
	ST.CreatedDate AS [Created On],
	ST.UpdatedBy AS [Updated By],
	ST.UpdatedDate AS [Updated On],
	ST.IsActive AS [Is Active],
	ST.IsDeleted AS [Is Deleted]
	FROM [DBO].ShippingTermsAudit ST WITH (NOLOCK)