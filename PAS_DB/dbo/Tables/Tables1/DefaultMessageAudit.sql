CREATE TABLE [dbo].[DefaultMessageAudit] (
    [DefaultMessageAuditId] BIGINT         IDENTITY (1, 1) NOT NULL,
    [DefaultMessageId]      BIGINT         NOT NULL,
    [Description]           VARCHAR (500)  NOT NULL,
    [Memo]                  NVARCHAR (MAX) NULL,
    [MasterCompanyId]       INT            NOT NULL,
    [CreatedBy]             VARCHAR (256)  NOT NULL,
    [UpdatedBy]             VARCHAR (256)  NOT NULL,
    [CreatedDate]           DATETIME2 (7)  NOT NULL,
    [UpdatedDate]           DATETIME2 (7)  NOT NULL,
    [IsActive]              BIT            NOT NULL,
    [IsDeleted]             BIT            NOT NULL,
    [ModuleID]              INT            NULL,
    [ModuleName]            VARCHAR (100)  NULL,
    CONSTRAINT [PK_DefaultMessageAudit] PRIMARY KEY CLUSTERED ([DefaultMessageAuditId] ASC),
    CONSTRAINT [FK_DefaultMessageAudit_DefaultMessage] FOREIGN KEY ([DefaultMessageId]) REFERENCES [dbo].[DefaultMessage] ([DefaultMessageId]),
    CONSTRAINT [FK_DefaultMessageAudit_ModuleID] FOREIGN KEY ([ModuleID]) REFERENCES [dbo].[Module] ([ModuleId])
);

