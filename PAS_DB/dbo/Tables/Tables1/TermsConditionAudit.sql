CREATE TABLE [dbo].[TermsConditionAudit] (
    [TermsConditionAuditId] BIGINT         IDENTITY (1, 1) NOT NULL,
    [TermsConditionId]      BIGINT         NOT NULL,
    [Description]           NVARCHAR (MAX) NOT NULL,
    [Memo]                  NVARCHAR (MAX) NULL,
    [MasterCompanyId]       INT            NOT NULL,
    [CreatedBy]             VARCHAR (256)  NOT NULL,
    [UpdatedBy]             VARCHAR (256)  NOT NULL,
    [CreatedDate]           DATETIME2 (7)  NOT NULL,
    [UpdatedDate]           DATETIME2 (7)  NOT NULL,
    [IsActive]              BIT            NOT NULL,
    [IsDeleted]             BIT            NOT NULL,
    [EmailTemplateTypeId]   BIGINT         NULL,
    [EmailTemplateTypeName] VARCHAR (100)  NULL,
    CONSTRAINT [PK_TermsConditionAudit] PRIMARY KEY CLUSTERED ([TermsConditionAuditId] ASC),
    CONSTRAINT [FK_TermsConditionAudit_EmailTemplateTypeId] FOREIGN KEY ([EmailTemplateTypeId]) REFERENCES [dbo].[EmailTemplateType] ([EmailTemplateTypeId]),
    CONSTRAINT [FK_TermsConditionAudit_TermsCondition] FOREIGN KEY ([TermsConditionId]) REFERENCES [dbo].[TermsCondition] ([TermsConditionId])
);

