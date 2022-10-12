﻿CREATE TABLE [dbo].[JournalBatch] (
    [ID]                      BIGINT          IDENTITY (1, 1) NOT NULL,
    [JournalBatchNumber]      VARCHAR (30)    NOT NULL,
    [JournalBatchDescription] VARCHAR (50)    NOT NULL,
    [GLAccountId]             BIGINT          NOT NULL,
    [JournalSourceId]         BIGINT          NOT NULL,
    [JournalTypeId]           BIGINT          NOT NULL,
    [JournalPeriodId]         BIGINT          NOT NULL,
    [LocalCurrencyId]         INT             NULL,
    [LocalDebitAmount]        NUMERIC (18, 2) NULL,
    [LocalCreditAmount]       NUMERIC (18, 2) NULL,
    [ReportingCurrencyId]     INT             NULL,
    [ReportingDebitAmount]    NUMERIC (18, 2) NULL,
    [ReportingCreditAmount]   NUMERIC (18, 2) NULL,
    [IsReversing]             BIT             CONSTRAINT [JournalBatch_DC_IsReversing] DEFAULT ((0)) NOT NULL,
    [IsRecurring]             BIT             CONSTRAINT [JournalBatch_DC_IsRecurring] DEFAULT ((0)) NOT NULL,
    [MasterCompanyId]         INT             NOT NULL,
    [CreatedBy]               VARCHAR (256)   NOT NULL,
    [UpdatedBy]               VARCHAR (256)   NOT NULL,
    [CreatedDate]             DATETIME2 (7)   CONSTRAINT [JournalBatch_DC_CDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]             DATETIME2 (7)   CONSTRAINT [JournalBatch_DC_UDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]                BIT             CONSTRAINT [JournalBatch_DC_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]               BIT             CONSTRAINT [JournalBatch_DC_IsDeleted] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_JournalBatch] PRIMARY KEY CLUSTERED ([ID] ASC),
    CONSTRAINT [FK_JournalBatch_JournalPeriod] FOREIGN KEY ([JournalPeriodId]) REFERENCES [dbo].[JournalPeriod] ([ID]),
    CONSTRAINT [FK_JournalBatch_JournalSource] FOREIGN KEY ([JournalSourceId]) REFERENCES [dbo].[JournalSource] ([ID]),
    CONSTRAINT [FK_JournalBatch_LocalCurrency] FOREIGN KEY ([LocalCurrencyId]) REFERENCES [dbo].[Currency] ([CurrencyId]),
    CONSTRAINT [FK_JournalBatch_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [FK_JournalBatch_ReportingCurrency] FOREIGN KEY ([ReportingCurrencyId]) REFERENCES [dbo].[Currency] ([CurrencyId])
);



