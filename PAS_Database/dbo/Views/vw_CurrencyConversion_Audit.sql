CREATE    VIEW [dbo].[vw_CurrencyConversion_Audit]
AS
	SELECT C.CurrencyConversionAuditId AS PkID, C.CurrencyConversionId AS ID, CT.[Name] AS [Currency Type], FCur.Code AS [From Currency], TCur.Code AS [To Currency], C.ConversionRate AS [Conversion Rate], C.CreatedBy AS [Created By],
	C.CreatedDate AS [Created Date], C.UpdatedBy AS [Updated By], C.UpdatedDate AS [Updated Date], C.IsActive AS [Is Active], C.IsDeleted AS [Is Deleted]
	FROM [DBO].[CurrencyConversionAudit] C WITH (NOLOCK)
	LEFT JOIN [DBO].[Currency] FCur WITH (NOLOCK) ON FCur.CurrencyId = C.FromCurrencyId
	LEFT JOIN [DBO].[Currency] TCur WITH (NOLOCK) ON TCur.CurrencyId = C.ToCurrencyId
	LEFT JOIN [DBO].[CurrencyType] CT WITH (NOLOCK) ON CT.CurrencyTypeId = C.CurrencyTypeId