CREATE TABLE [dbo].[RFQFollowUpTemplateAudit] (
    [TemplateAuditId] BIGINT         IDENTITY (1, 1) NOT NULL,
    [TemplateId]      BIGINT         NOT NULL,
    [TemplateName]    VARCHAR (200)  NOT NULL,
    [Description]     VARCHAR (400)  NULL,
    [Subject]         VARCHAR (200)  NULL,
    [EmailBody]       NVARCHAR (MAX) NULL,
    [MasterCompanyId] INT            NOT NULL,
    [CreatedBy]       VARCHAR (50)   NOT NULL,
    [CreatedDate]     DATETIME2 (7)  CONSTRAINT [DF_RFQFollowUpTemplateAudit_CreatedDate] DEFAULT (getutcdate()) NOT NULL,
    [UpdatedBy]       VARCHAR (50)   NOT NULL,
    [UpdatedDate]     DATETIME2 (7)  CONSTRAINT [DF_RFQFollowUpTemplateAudit_UpdatedDate] DEFAULT (getutcdate()) NOT NULL,
    [IsActive]        BIT            CONSTRAINT [DF__RFQFollowUpTemplateAudit__IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]       BIT            CONSTRAINT [DF__RFQFollowUpTemplateAudit__IsDeleted] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_RFQFollowUpTemplateAudit] PRIMARY KEY CLUSTERED ([TemplateAuditId] ASC)
);

