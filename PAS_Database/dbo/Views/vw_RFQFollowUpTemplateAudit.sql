CREATE   VIEW dbo.vw_RFQFollowUpTemplateAudit
AS
SELECT
    [TemplateAuditId] AS PkID,
    [TemplateId] AS ID,
    [TemplateName] AS [Template Name],
    [Description],
    [Subject],
    [EmailBody] AS [Email Body],
    --[MasterCompanyId],
    [CreatedBy] AS [Created By],
    [CreatedDate] AS [Created On],
    [UpdatedBy] AS [Updated By],
    [UpdatedDate] AS [Updated On],
    [IsActive] AS [Is Active],
    [IsDeleted] AS [Is Deleted]
FROM [dbo].[RFQFollowUpTemplateAudit] WITH(NOLOCK);