CREATE TABLE [dbo].[BatchDetails] (
    [JournalBatchDetailId]  BIGINT          IDENTITY (1, 1) NOT NULL,
    [JournalBatchHeaderId]  BIGINT          NOT NULL,
    [LineNumber]            INT             NULL,
    [GlAccountId]           BIGINT          NOT NULL,
    [GlAccountNumber]       VARCHAR (200)   NULL,
    [GlAccountName]         VARCHAR (200)   NULL,
    [TransactionDate]       DATETIME        NOT NULL,
    [EntryDate]             DATETIME        NULL,
    [JournalTypeId]         BIGINT          NULL,
    [JournalTypeName]       VARCHAR (200)   NULL,
    [IsDebit]               BIT             NULL,
    [DebitAmount]           DECIMAL (18, 2) NULL,
    [CreditAmount]          DECIMAL (18, 2) NULL,
    [ManagementStructureId] BIGINT          NULL,
    [ModuleName]            VARCHAR (200)   NULL,
    [MasterCompanyId]       INT             NOT NULL,
    [CreatedBy]             VARCHAR (256)   NOT NULL,
    [UpdatedBy]             VARCHAR (256)   NOT NULL,
    [CreatedDate]           DATETIME2 (7)   CONSTRAINT [JournalBatchDetails_DC_CDate] DEFAULT (getutcdate()) NOT NULL,
    [UpdatedDate]           DATETIME2 (7)   CONSTRAINT [JournalBatchDetails_DC_UDate] DEFAULT (getutcdate()) NOT NULL,
    [IsActive]              BIT             CONSTRAINT [JournalBatchDetails_DC_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]             BIT             CONSTRAINT [JournalBatchDetails_DC_IsDeleted] DEFAULT ((0)) NOT NULL,
    [LastMSLevel]           VARCHAR (200)   NULL,
    [AllMSlevels]           VARCHAR (MAX)   NULL,
    [IsManualEntry]         BIT             NULL,
    [DistributionSetupId]   INT             NULL,
    [DistributionName]      VARCHAR (200)   NULL,
    [JournalTypeNumber]     VARCHAR (50)    NULL,
    [CurrentNumber]         BIGINT          NULL,
    [StatusId]              INT             DEFAULT ((1)) NOT NULL,
    [PostedDate]            DATETIME        NULL,
    [AccountingPeriodId]    BIGINT          NULL,
    [AccountingPeriod]      VARCHAR (100)   NULL,
    CONSTRAINT [PK_JournalBatchDetails] PRIMARY KEY CLUSTERED ([JournalBatchDetailId] ASC)
);









