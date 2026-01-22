CREATE TABLE [dbo].[PublicationTemplateAudit] (
    [AuditPublicationTemplateId] BIGINT         IDENTITY (1, 1) NOT NULL,
    [PublicationTemplateId]      BIGINT         NULL,
    [PublicationTypeId]          BIGINT         NULL,
    [EmailBody]                  NVARCHAR (MAX) NULL,
    [MasterCompanyId]            INT            NOT NULL,
    [CreatedBy]                  VARCHAR (256)  NOT NULL,
    [UpdatedBy]                  VARCHAR (256)  NOT NULL,
    [CreatedDate]                DATETIME2 (7)  CONSTRAINT [DF_PublicationTemplateAudit_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]                DATETIME2 (7)  CONSTRAINT [DF_PublicationTemplateAudit_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]                   BIT            CONSTRAINT [DF_PublicationTemplateAudit_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]                  BIT            CONSTRAINT [DF_PublicationTemplateAudit_IsDeleted] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_PublicationTemplateAudit] PRIMARY KEY CLUSTERED ([AuditPublicationTemplateId] ASC)
);

