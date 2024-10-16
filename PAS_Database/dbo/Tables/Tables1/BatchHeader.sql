﻿CREATE TABLE [dbo].[BatchHeader] (
    [JournalBatchHeaderId] BIGINT          IDENTITY (1, 1) NOT NULL,
    [BatchName]            VARCHAR (200)   NOT NULL,
    [CurrentNumber]        BIGINT          NULL,
    [EntryDate]            DATETIME        NOT NULL,
    [PostDate]             DATETIME        NULL,
    [AccountingPeriod]     VARCHAR (50)    NULL,
    [StatusId]             BIGINT          NOT NULL,
    [StatusName]           VARCHAR (200)   NULL,
    [JournalTypeId]        BIGINT          NOT NULL,
    [JournalTypeName]      VARCHAR (200)   NULL,
    [TotalDebit]           DECIMAL (18, 2) NULL,
    [TotalCredit]          DECIMAL (18, 2) NULL,
    [TotalBalance]         DECIMAL (18, 2) NULL,
    [MasterCompanyId]      INT             NOT NULL,
    [CreatedBy]            VARCHAR (256)   NOT NULL,
    [UpdatedBy]            VARCHAR (256)   NOT NULL,
    [CreatedDate]          DATETIME2 (7)   CONSTRAINT [JournalBatchHeader_DC_CDate] DEFAULT (getutcdate()) NOT NULL,
    [UpdatedDate]          DATETIME2 (7)   CONSTRAINT [JournalBatchHeader_DC_UDate] DEFAULT (getutcdate()) NOT NULL,
    [IsActive]             BIT             CONSTRAINT [JournalBatchHeader_DC_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]            BIT             CONSTRAINT [JournalBatchHeader_DC_IsDeleted] DEFAULT ((0)) NOT NULL,
    [IsPrinted]            BIT             NULL,
    [PrintedDate]          DATETIME        NULL,
    [AccountingPeriodId]   BIGINT          NULL,
    [Module]               VARCHAR (50)    NULL,
    [CustomerTypeId]       INT             NULL,
    [PostedBy]             VARCHAR (256)   NULL,
    [APPostedDate]         DATETIME        NULL,
    CONSTRAINT [PK_JournalBatchHeader] PRIMARY KEY CLUSTERED ([JournalBatchHeaderId] ASC)
);



