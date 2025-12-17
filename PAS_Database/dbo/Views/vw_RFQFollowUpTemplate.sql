CREATE   VIEW dbo.vw_RFQFollowUpTemplate
AS
SELECT
    [TemplateId],
    [TemplateName],
    [Description],
    [Subject],
    [EmailBody],
    [MasterCompanyId],
    [CreatedBy],
    [CreatedDate],
    [UpdatedBy],
    [UpdatedDate],
    [IsActive],
    [IsDeleted]
FROM [dbo].[RFQFollowUpTemplate] WITH(NOLOCK);