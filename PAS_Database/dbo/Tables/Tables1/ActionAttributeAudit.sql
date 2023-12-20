CREATE TABLE [dbo].[ActionAttributeAudit] (
    [ActionAttributeAuditId] BIGINT         IDENTITY (1, 1) NOT NULL,
    [ActionAttributeId]      BIGINT         NOT NULL,
    [Description]            VARCHAR (100)  NULL,
    [Memo]                   NVARCHAR (MAX) NULL,
    [MasterCompanyId]        INT            NULL,
    [CreatedBy]              VARCHAR (256)  NULL,
    [UpdatedBy]              VARCHAR (256)  NULL,
    [CreatedDate]            DATETIME2 (7)  NULL,
    [UpdatedDate]            DATETIME2 (7)  NULL,
    [IsActive]               BIT            NULL,
    [IsDeleted]              BIT            NULL,
    [Sequence]               BIGINT         NULL,
    CONSTRAINT [PK__ActionAt__5B77CFBD270ECE92] PRIMARY KEY CLUSTERED ([ActionAttributeAuditId] ASC),
    CONSTRAINT [FK_ActionAttributeAudit_ActionAttribute] FOREIGN KEY ([ActionAttributeId]) REFERENCES [dbo].[ActionAttribute] ([ActionAttributeId])
);

