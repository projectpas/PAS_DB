﻿CREATE TABLE [dbo].[ManualJournalHeader] (
    [ManualJournalHeaderId]       BIGINT          IDENTITY (1, 1) NOT NULL,
    [LedgerId]                    BIGINT          NULL,
    [JournalNumber]               VARCHAR (100)   NULL,
    [JournalDescription]          VARCHAR (MAX)   NULL,
    [ManualJournalTypeId]         INT             NULL,
    [ManualJournalBalanceTypeId]  INT             NULL,
    [EntryDate]                   DATETIME        NULL,
    [EffectiveDate]               DATETIME        NULL,
    [AccountingPeriodId]          BIGINT          NULL,
    [ManualJournalStatusId]       INT             NULL,
    [IsRecuring]                  INT             NULL,
    [ReversingDate]               DATETIME        NULL,
    [ReversingaccountingPeriodId] BIGINT          NULL,
    [ReversingStatusId]           INT             NULL,
    [FunctionalCurrencyId]        BIGINT          NULL,
    [ReportingCurrencyId]         BIGINT          NULL,
    [ConversionCurrencyDate]      DATETIME        NULL,
    [ConvertionTypeId]            INT             NULL,
    [ConversionRate]              DECIMAL (18, 2) NULL,
    [ManagementStructureId]       BIGINT          NULL,
    [EmployeeId]                  BIGINT          NULL,
    [MasterCompanyId]             INT             NOT NULL,
    [CreatedBy]                   VARCHAR (256)   NOT NULL,
    [UpdatedBy]                   VARCHAR (256)   NOT NULL,
    [CreatedDate]                 DATETIME2 (7)   CONSTRAINT [DF_ManualJournalHeader1_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]                 DATETIME2 (7)   CONSTRAINT [DF_ManualJournalHeader1_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]                    BIT             CONSTRAINT [DF_ManualJournalHeader1_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]                   BIT             CONSTRAINT [DF_ManualJournalHeader1_IsDeleted] DEFAULT ((0)) NOT NULL,
    [IsEnforce]                   BIT             DEFAULT ((0)) NOT NULL,
    [EnforceEffectiveDate]        DATETIME        NULL,
    [IsRecursiveDone]             BIT             DEFAULT ((0)) NULL,
    [ReverseJournalNumber]        VARCHAR (100)   NULL,
    [RecurringNumberOfPeriod]     INT             NULL,
    [PostedDate]                  DATETIME2 (7)   NULL,
    CONSTRAINT [PK_ManualJournalHeader1] PRIMARY KEY CLUSTERED ([ManualJournalHeaderId] ASC)
);


GO


CREATE   TRIGGER [dbo].[Trg_ManualJournalHeaderAudit]

   ON  [dbo].[ManualJournalHeader]

   AFTER INSERT,DELETE,UPDATE

AS 

BEGIN



	INSERT INTO ManualJournalHeaderAudit

	SELECT * FROM INSERTED



	SET NOCOUNT ON;



END