CREATE TABLE [dbo].[LegalEntityContactAudit] (
    [LegalEntityContactAuditId] BIGINT        IDENTITY (1, 1) NOT NULL,
    [LegalEntityContactId]      BIGINT        NOT NULL,
    [LegalEntityId]             BIGINT        NOT NULL,
    [ContactId]                 BIGINT        NOT NULL,
    [IsDefaultContact]          BIT           NOT NULL,
    [Tag]                       VARCHAR (255) NULL,
    [MasterCompanyId]           INT           NOT NULL,
    [CreatedBy]                 VARCHAR (256) NOT NULL,
    [UpdatedBy]                 VARCHAR (256) NOT NULL,
    [CreatedDate]               DATETIME2 (7) NOT NULL,
    [UpdatedDate]               DATETIME2 (7) NOT NULL,
    [IsActive]                  BIT           NOT NULL,
    [IsDeleted]                 BIT           NOT NULL,
    CONSTRAINT [PK_LegalEntityContactAudit] PRIMARY KEY CLUSTERED ([LegalEntityContactAuditId] ASC)
);

