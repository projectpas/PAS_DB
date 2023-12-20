CREATE TABLE [dbo].[JournalCurrencyTypeAudit] (
    [AuditJournalCurrencyTypeId] BIGINT        IDENTITY (1, 1) NOT NULL,
    [ID]                         BIGINT        NOT NULL,
    [Description]                VARCHAR (50)  NOT NULL,
    [MasterCompanyId]            INT           NOT NULL,
    [CreatedBy]                  VARCHAR (256) NOT NULL,
    [UpdatedBy]                  VARCHAR (256) NOT NULL,
    [CreatedDate]                DATETIME2 (7) NOT NULL,
    [UpdatedDate]                DATETIME2 (7) NOT NULL,
    [IsActive]                   BIT           NOT NULL,
    [IsDeleted]                  BIT           NOT NULL,
    [JournalCurrencyTypeName]    VARCHAR (100) NOT NULL,
    CONSTRAINT [PK_JournalCurrencyTypeAudit] PRIMARY KEY CLUSTERED ([AuditJournalCurrencyTypeId] ASC)
);

