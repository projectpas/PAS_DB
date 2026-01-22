create    VIEW [dbo].[vw_CustomerTypeAudit]
AS
	SELECT  CTA.AuditCustomerTypeId AS [PkID],
	        CTA.CustomerTypeId AS [ID],
			CTA.CustomerTypeName AS [Customer Type Name],
			CTA.SequenceNo AS [Sequence No],
			CTA.[Description] as [Description], 
			CTA.[Memo],
			CTA.CreatedBy AS [Created By],
			CTA.UpdatedBy AS [Updated By],
			CTA.CreatedDate AS [Created Date],
			CTA.UpdatedDate AS [Updated Date],
			CTA.IsActive AS [Is Active],
			CTA.IsDeleted AS [Is Deleted]
	FROM [DBO].[CustomerTypeAudit] CTA WITH (NOLOCK)