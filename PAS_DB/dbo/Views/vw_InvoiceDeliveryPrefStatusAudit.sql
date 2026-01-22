CREATE   VIEW [dbo].[vw_InvoiceDeliveryPrefStatusAudit]
AS
	SELECT idp.InvDelPrefStatusAuditId  AS PkID,
	idp.InvDelPrefStatusId AS ID	,
	idp.Status,
	idp.Memo,
	idp.SequenceNo [Sequence Num],
	idp.CreatedBy AS [Created By],
	idp.CreatedDate AS [Created Date],
	idp.UpdatedBy AS [Updated By],
	idp.UpdatedDate AS [Updated Date],
	idp.IsActive AS [Is Active],
	idp.IsDeleted AS [Is Deleted]
	FROM [DBO].[InvoiceDeliveryPrefStatusAudit] idp WITH (NOLOCK)