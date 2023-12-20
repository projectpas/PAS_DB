CREATE TABLE [dbo].[AccountingCalendarHistory] (
    [AccountingCalendarHistoryId] BIGINT        IDENTITY (1, 1) NOT NULL,
    [ReferenceId]                 BIGINT        NOT NULL,
    [PeriodName]                  VARCHAR (30)  NULL,
    [TableName]                   VARCHAR (100) NULL,
    [StatusName]                  VARCHAR (256) NULL,
    [LegalEntityId]               BIGINT        NULL,
    [LegalEntityName]             VARCHAR (256) NULL,
    [ledgerId]                    INT           NULL,
    [ledgerName]                  VARCHAR (256) NOT NULL,
    [MasterCompanyId]             INT           NOT NULL,
    [CreatedBy]                   VARCHAR (256) NULL,
    [UpdatedBy]                   VARCHAR (256) NULL,
    [CreatedDate]                 DATETIME2 (7) NULL,
    [UpdatedDate]                 DATETIME2 (7) NULL,
    [IsActive]                    BIT           NULL,
    [IsDeleted]                   BIT           NULL,
    CONSTRAINT [PK_AccountingCalendarHistory] PRIMARY KEY CLUSTERED ([AccountingCalendarHistoryId] ASC)
);

