

CREATE VIEW [dbo].[vw_TermsCondition]
AS
SELECT	tc.TermsConditionId, tc.Description, ETT.EmailTemplateType, tc.Memo, tc.MasterCompanyId, tc.CreatedBy, tc.UpdatedBy, 
        tc.CreatedDate, tc.UpdatedDate, tc.IsActive, tc.IsDeleted, tc.EmailTemplateTypeId 
FROM  dbo.TermsCondition tc WITH (NOLOCK) INNER JOIN
      dbo.EmailTemplateType ETT WITH (NOLOCK) ON ETT.EmailTemplateTypeId = tc.EmailTemplateTypeId