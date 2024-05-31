
CREATE   VIEW [dbo].[vw_CreditTermsAudit]
AS
	SELECT cdt.CreditTermsAuditId  AS PkID, cdt.CreditTermsId AS ID	,cdt.Name ,pr.PercentValue AS [Percentage],cdt.Days,cdt.NetDays,cdt.Memo
	,cdt.CreatedBy AS [Created By],
	cdt.CreatedDate AS [Created Date], cdt.UpdatedBy AS [Updated By], cdt.UpdatedDate AS [Updated Date], cdt.IsActive AS [Is Active], cdt.IsDeleted AS [Is Deleted]
	FROM [DBO].CreditTermsAudit cdt WITH (NOLOCK)
	LEFT JOIN [dbo].[Percent] pr WITH (NOLOCK) ON pr.PercentId = cdt.PercentId