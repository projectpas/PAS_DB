CREATE   VIEW [dbo].[vw_CreditTerms]
AS
	SELECT cdt.CreditTermsId,
	       cdt.[Name] ,
		   pr.PercentValue AS [Percentage],
		   pr.PercentId AS [PercentId],
		   cdt.Days,
		   cdt.NetDays,
		   cdt.Memo,
		   cdt.CreatedBy AS [CreatedBy],
		   cdt.CreatedDate AS [CreatedDate],
		   cdt.UpdatedBy AS [UpdatedBy],
		   cdt.UpdatedDate AS [UpdatedDate],
		   cdt.IsActive AS [IsActive],
		   cdt.IsDeleted AS [IsDeleted],
		   cdt.MasterCompanyId AS MasterCompanyId
	FROM [DBO].[CreditTerms] cdt WITH (NOLOCK)
	LEFT JOIN [dbo].[Percent] pr WITH (NOLOCK) ON pr.PercentId = cdt.PercentId