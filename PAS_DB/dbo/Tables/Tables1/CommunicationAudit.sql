CREATE TABLE [dbo].[CommunicationAudit] (
    [AuditCommunicationId] BIGINT         IDENTITY (1, 1) NOT NULL,
    [CommunicationId]      BIGINT         NOT NULL,
    [Name]                 VARCHAR (256)  NOT NULL,
    [Contact]              VARCHAR (256)  NOT NULL,
    [Subject]              VARCHAR (MAX)  NULL,
    [ModuleId]             INT            NOT NULL,
    [PostedDate]           DATETIME2 (7)  NULL,
    [MasterCompanyId]      INT            NOT NULL,
    [CreatedBy]            VARCHAR (256)  NOT NULL,
    [UpdatedBy]            VARCHAR (256)  NOT NULL,
    [CreatedDate]          DATETIME2 (7)  NOT NULL,
    [UpdatedDate]          DATETIME2 (7)  NOT NULL,
    [IsActive]             BIT            NOT NULL,
    [IsDeleted]            BIT            NOT NULL,
    [ReferenceId]          BIGINT         NOT NULL,
    [Description]          NVARCHAR (MAX) NULL,
    CONSTRAINT [PK_CRMCommunicationAudit] PRIMARY KEY CLUSTERED ([AuditCommunicationId] ASC),
    CONSTRAINT [FK_CommunicationAudit_Communication] FOREIGN KEY ([CommunicationId]) REFERENCES [dbo].[Communication] ([CommunicationId])
);

