CREATE TABLE [dbo].[CommonTeardownTemplateAudit] (
    [CommonTeardownTemplateAuditId] BIGINT        IDENTITY (1, 1) NOT NULL,
    [CommonTeardownTemplateId]      BIGINT        NOT NULL,
    [CommonTeardownTypeId]          BIGINT        NOT NULL,
    [TemplateName]                  VARCHAR (100) NULL,
    [TemplateCode]                  VARCHAR (50)  NULL,
    [Description]                   VARCHAR (500) NULL,
    [TemplateBody]                  VARCHAR (MAX) NULL,
    [MasterCompanyId]               INT           NOT NULL,
    [CreatedBy]                     VARCHAR (50)  NOT NULL,
    [CreatedDate]                   DATETIME2 (7) CONSTRAINT [DF_CommonTeardownTemplateAudit_CreatedDate] DEFAULT (getutcdate()) NOT NULL,
    [UpdatedBy]                     VARCHAR (50)  NOT NULL,
    [UpdatedDate]                   DATETIME2 (7) CONSTRAINT [DF_CommonTeardownTemplateAudit_UpdatedDate] DEFAULT (getutcdate()) NOT NULL,
    [IsActive]                      BIT           CONSTRAINT [DF__CommonTeardownTemplateAudit__IsActi__59FA5E80] DEFAULT ((1)) NOT NULL,
    [IsDeleted]                     BIT           CONSTRAINT [DF__CommonTeardownTemplateAudit__IsDele__5AEE82B9] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_CommonTeardownTemplateAudit] PRIMARY KEY CLUSTERED ([CommonTeardownTemplateAuditId] ASC)
);

