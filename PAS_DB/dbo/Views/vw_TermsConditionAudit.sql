
CREATE    VIEW [dbo].[vw_TermsConditionAudit]
AS
SELECT TCA.TermsConditionAuditId  AS [PkID], 
	TCA.TermsConditionId AS [ID],
	ET.EmailTemplateType AS [Template Type],
	TCA.[Description] AS [Terms and Condition],
	TCA.Memo,
	TCA.CreatedDate AS [Created On],
	TCA.CreatedBy AS [Created By],
	TCA.UpdatedDate AS [Updated On],
	TCA.UpdatedBy AS [Updated By],
	TCA.IsActive AS [Is Active],
	TCA.IsDeleted AS [Is Deleted]
	FROM [dbo].[TermsConditionAudit] TCA WITH (NOLOCK)
	LEFT JOIN [dbo].[EmailTemplateType] ET WITH(NOLOCK) ON TCA.EmailTemplateTypeId = ET.EmailTemplateTypeId