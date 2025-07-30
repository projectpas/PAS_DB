CREATE TABLE [dbo].[IntegrationEmailSmtpConfigrationAudit] (
    [IntegrationEmailConfigAuditId] BIGINT         IDENTITY (1, 1) NOT NULL,
    [IntegrationEmailConfigId]      BIGINT         NOT NULL,
    [SmtpUserEmail]                 NVARCHAR (MAX) NOT NULL,
    [smtpserver]                    NVARCHAR (500) NOT NULL,
    [SmtpEmailPassword]             NVARCHAR (500) NOT NULL,
    [SmtpPort]                      INT            NOT NULL,
    [UseSsl]                        BIT            NULL,
    [MasterCompanyId]               INT            NOT NULL,
    [CreatedBy]                     VARCHAR (256)  NOT NULL,
    [UpdatedBy]                     VARCHAR (256)  NOT NULL,
    [CreatedDate]                   DATETIME2 (7)  NOT NULL,
    [UpdatedDate]                   DATETIME2 (7)  NOT NULL,
    [IsActive]                      BIT            NOT NULL,
    [IsDeleted]                     BIT            NOT NULL,
    CONSTRAINT [PK_IntegrationEmailConfigrationAudit] PRIMARY KEY CLUSTERED ([IntegrationEmailConfigAuditId] ASC)
);

