﻿CREATE TABLE [dbo].[CommonBatchDetails] (
    [CommonJournalBatchDetailId] BIGINT          IDENTITY (1, 1) NOT NULL,
    [JournalBatchHeaderId]       BIGINT          NOT NULL,
    [JournalBatchDetailId]       BIGINT          NULL,
    [LineNumber]                 INT             NULL,
    [GlAccountId]                BIGINT          NOT NULL,
    [GlAccountNumber]            VARCHAR (200)   NULL,
    [GlAccountName]              VARCHAR (200)   NULL,
    [TransactionDate]            DATETIME        NOT NULL,
    [EntryDate]                  DATETIME        NULL,
    [JournalTypeId]              BIGINT          NULL,
    [JournalTypeName]            VARCHAR (200)   NULL,
    [IsDebit]                    BIT             NULL,
    [DebitAmount]                DECIMAL (18, 2) NULL,
    [CreditAmount]               DECIMAL (18, 2) NULL,
    [ManagementStructureId]      BIGINT          NULL,
    [ModuleName]                 VARCHAR (200)   NULL,
    [MasterCompanyId]            INT             NOT NULL,
    [CreatedBy]                  VARCHAR (256)   NOT NULL,
    [UpdatedBy]                  VARCHAR (256)   NOT NULL,
    [CreatedDate]                DATETIME2 (7)   CONSTRAINT [DF_CommonBatchDetails_CreatedDate] DEFAULT (getutcdate()) NOT NULL,
    [UpdatedDate]                DATETIME2 (7)   CONSTRAINT [DF_CommonBatchDetails_UpdatedDate] DEFAULT (getutcdate()) NOT NULL,
    [IsActive]                   BIT             CONSTRAINT [DF_CommonBatchDetails_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]                  BIT             CONSTRAINT [DF_CommonBatchDetails_IsDeleted] DEFAULT ((0)) NOT NULL,
    [LastMSLevel]                VARCHAR (200)   NULL,
    [AllMSlevels]                VARCHAR (MAX)   NULL,
    [IsManualEntry]              BIT             NULL,
    [DistributionSetupId]        INT             NULL,
    [DistributionName]           VARCHAR (200)   NULL,
    [JournalTypeNumber]          VARCHAR (50)    NULL,
    [CurrentNumber]              BIGINT          NULL,
    [IsYearEnd]                  BIT             NULL,
    [IsVersionIncrease]          BIT             NULL,
    [ReferenceId]                BIGINT          NULL,
    [LotId]                      BIGINT          NULL,
    [LotNumber]                  VARCHAR (50)    NULL,
    CONSTRAINT [PK_CommonBatchDetails] PRIMARY KEY CLUSTERED ([CommonJournalBatchDetailId] ASC)
);

