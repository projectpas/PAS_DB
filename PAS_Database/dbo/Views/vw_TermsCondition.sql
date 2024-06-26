CREATE   VIEW [dbo].[vw_TermsCondition]
AS
	SELECT TC.TermsConditionId,
	ET.EmailTemplateTypeId,
	ET.EmailTemplateType,
	TC.[Description],
	TC.Memo,
	TC.MasterCompanyId,
	TC.CreatedDate,
	TC.CreatedBy,
	TC.UpdatedDate,
	TC.UpdatedBy ,
	TC.IsActive,
	TC.IsDeleted
	FROM [dbo].[TermsCondition] TC WITH (NOLOCK)
	LEFT JOIN [dbo].[EmailTemplateType] ET WITH(NOLOCK) ON TC.EmailTemplateTypeId = ET.EmailTemplateTypeId