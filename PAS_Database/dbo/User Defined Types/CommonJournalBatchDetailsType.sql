﻿CREATE TYPE [dbo].[CommonJournalBatchDetailsType] AS TABLE (
    [CommonJournalBatchDetailId] BIGINT          NOT NULL,
    [JournalBatchDetailId]       BIGINT          NOT NULL,
    [JournalBatchHeaderId]       BIGINT          NOT NULL,
    [LineNumber]                 BIGINT          NULL,
    [GlAccountId]                BIGINT          NULL,
    [TransactionDate]            DATETIME2 (7)   NULL,
    [EntryDate]                  DATETIME2 (7)   NULL,
    [IsDebit]                    BIT             NULL,
    [DebitAmount]                DECIMAL (18, 2) NULL,
    [CreditAmount]               DECIMAL (18, 2) NULL,
    [MasterCompanyId]            INT             NOT NULL,
    [UpdatedBy]                  VARCHAR (256)   NOT NULL,
    [IsDeleted]                  BIT             NOT NULL,
    [JournalTypeId]              BIGINT          NULL,
    [JournalTypeName]            VARCHAR (256)   NULL,
    [ManagementStructureId]      BIGINT          NULL,
    [LastMSLevel]                VARCHAR (256)   NULL,
    [AllMSlevels]                VARCHAR (256)   NULL,
    [IsUpdated]                  BIT             NULL);



