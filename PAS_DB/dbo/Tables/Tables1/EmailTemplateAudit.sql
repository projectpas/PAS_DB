CREATE TABLE [dbo].[EmailTemplateAudit] (
    [AuditEmailTemplateId] BIGINT         IDENTITY (1, 1) NOT NULL,
    [EmailTemplateId]      INT            NOT NULL,
    [TemplateName]         VARCHAR (100)  NULL,
    [TemplateDescription]  NVARCHAR (MAX) NULL,
    [MasterCompanyId]      INT            NOT NULL,
    [CreatedBy]            VARCHAR (256)  NOT NULL,
    [UpdatedBy]            VARCHAR (256)  NOT NULL,
    [CreatedDate]          DATETIME2 (7)  NOT NULL,
    [UpdatedDate]          DATETIME2 (7)  NOT NULL,
    [IsActive]             BIT            NOT NULL,
    [IsDeleted]            BIT            NOT NULL,
    [EmailBody]            NVARCHAR (MAX) NULL,
    [EmailTemplateTypeId]  BIGINT         NULL,
    [SubjectName]          VARCHAR (50)   NULL,
    [RevNo]                NVARCHAR (50)  NULL,
    [RevDate]              NVARCHAR (50)  NULL,
    CONSTRAINT [PK_EmailTemplateAudit] PRIMARY KEY CLUSTERED ([AuditEmailTemplateId] ASC)
);



