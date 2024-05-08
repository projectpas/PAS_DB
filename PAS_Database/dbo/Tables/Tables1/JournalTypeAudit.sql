CREATE TABLE [dbo].[JournalTypeAudit] (
    [AuditJournalTypeId] BIGINT        IDENTITY (1, 1) NOT NULL,
    [ID]                 BIGINT        NOT NULL,
    [Description]        VARCHAR (50)  NOT NULL,
    [MasterCompanyId]    INT           NOT NULL,
    [CreatedBy]          VARCHAR (256) NOT NULL,
    [UpdatedBy]          VARCHAR (256) NOT NULL,
    [CreatedDate]        DATETIME2 (7) NOT NULL,
    [UpdatedDate]        DATETIME2 (7) NOT NULL,
    [IsActive]           BIT           NOT NULL,
    [IsDeleted]          BIT           NOT NULL,
    [JournalTypeName]    VARCHAR (100) NOT NULL,
    [BatchType]          VARCHAR (20)  NULL,
    [Category]           VARCHAR (100) NULL,
    CONSTRAINT [PK_JournalTypeAudit] PRIMARY KEY CLUSTERED ([AuditJournalTypeId] ASC)
);



