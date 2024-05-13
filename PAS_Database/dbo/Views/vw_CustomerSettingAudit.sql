
create    VIEW [dbo].[vw_CustomerSettingAudit]
AS
	SELECT  CSA.CustomerSettingsAuditId AS [PkID],
	        CSA.Id AS [ID],
			LE.[Name] AS [LegalEntity Name], 
			CT.Name AS [CreditTerms],
			CSA.CreditLimit AS [Credit Limit],
			C.Code AS Currency,
			CSA.CreatedBy AS [Created By],
			CSA.UpdatedBy AS [Updated By],
			CSA.CreatedDate AS [Created Date],
			CSA.UpdatedDate AS [Updated Date],
			CSA.IsActive AS [Is Active],
			CSA.IsDeleted AS [Is Deleted]
	FROM [DBO].[CustomerSettingsAudit] CSA WITH (NOLOCK)
	LEFT JOIN [DBO].[LegalEntity] LE WITH (NOLOCK) ON CSA.LegalEntityId = LE.LegalEntityId
	LEFT JOIN [DBO].[CreditTerms] CT WITH (NOLOCK) ON CSA.CreditTermsId = CT.CreditTermsId
	LEFT JOIN [DBO].[Currency] C WITH (NOLOCK) ON CSA.CurrencyId = C.CurrencyId