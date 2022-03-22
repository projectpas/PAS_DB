CREATE TABLE [dbo].[JournalManual] (
    [ID]                            BIGINT          IDENTITY (1, 1) NOT NULL,
    [IsManual]                      BIT             DEFAULT ((1)) NOT NULL,
    [BatchNumber]                   VARCHAR (30)    NOT NULL,
    [BatchName]                     VARCHAR (50)    NOT NULL,
    [BatchDescription]              VARCHAR (50)    NOT NULL,
    [GLAccountId]                   BIGINT          NOT NULL,
    [BalanceTypeId]                 BIGINT          NOT NULL,
    [JournalCategoryId]             BIGINT          NOT NULL,
    [JournalTypeId]                 BIGINT          NOT NULL,
    [EntryDate]                     DATETIME        NOT NULL,
    [EffectiveDate]                 DATETIME        NOT NULL,
    [AccountingCalendarId]          BIGINT          NULL,
    [EmployeeId]                    BIGINT          NOT NULL,
    [LocalCurrencyId]               INT             NOT NULL,
    [ReportingCurrencyId]           INT             NOT NULL,
    [CurrencyDate]                  DATE            NULL,
    [JournalCurrencyTypeId]         BIGINT          NOT NULL,
    [IsReversing]                   BIT             CONSTRAINT [JournalManual_DC_IsReversing] DEFAULT ((0)) NOT NULL,
    [ReversingDate]                 DATETIME        NULL,
    [ReversingAccountingCalendarId] BIGINT          NULL,
    [IsRecurring]                   BIT             CONSTRAINT [JournalManual_DC_IsRecurring] DEFAULT ((0)) NOT NULL,
    [RecurringDate]                 DATETIME        NULL,
    [MasterCompanyId]               INT             NOT NULL,
    [LocalDebitCurrency]            NUMERIC (18, 2) NULL,
    [LocalCreditCurrency]           NUMERIC (18, 2) NULL,
    [ReportingDebitCurrency]        NUMERIC (18, 2) NULL,
    [ReportingCreditCurrency]       NUMERIC (18, 2) NULL,
    [Description]                   VARCHAR (50)    NULL,
    [ManagementStructureEntityId]   BIGINT          NULL,
    [CreatedBy]                     VARCHAR (256)   NOT NULL,
    [UpdatedBy]                     VARCHAR (256)   NOT NULL,
    [CreatedDate]                   DATETIME2 (7)   CONSTRAINT [JournalManual_DC_CDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]                   DATETIME2 (7)   CONSTRAINT [JournalManual_DC_UDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]                      BIT             DEFAULT ((1)) NOT NULL,
    [IsDeleted]                     BIT             DEFAULT ((0)) NOT NULL,
    [CurrencyRate]                  DECIMAL (18)    NULL,
    CONSTRAINT [PK_JournalManual] PRIMARY KEY CLUSTERED ([ID] ASC),
    CONSTRAINT [FK_JournalManual_AccountingCalendar] FOREIGN KEY ([AccountingCalendarId]) REFERENCES [dbo].[AccountingCalendar] ([AccountingCalendarId]),
    CONSTRAINT [FK_JournalManual_BalanceType] FOREIGN KEY ([BalanceTypeId]) REFERENCES [dbo].[BalanceType] ([ID]),
    CONSTRAINT [FK_JournalManual_Employee] FOREIGN KEY ([EmployeeId]) REFERENCES [dbo].[Employee] ([EmployeeId]),
    CONSTRAINT [FK_JournalManual_GLAccount] FOREIGN KEY ([GLAccountId]) REFERENCES [dbo].[GLAccount] ([GLAccountId]),
    CONSTRAINT [FK_JournalManual_JournalCategory] FOREIGN KEY ([JournalCategoryId]) REFERENCES [dbo].[JournalCategory] ([ID]),
    CONSTRAINT [FK_JournalManual_JournalCurrencyType] FOREIGN KEY ([JournalCurrencyTypeId]) REFERENCES [dbo].[JournalCurrencyType] ([ID]),
    CONSTRAINT [FK_JournalManual_JournalType] FOREIGN KEY ([JournalTypeId]) REFERENCES [dbo].[JournalType] ([ID]),
    CONSTRAINT [FK_JournalManual_LocalCurrency] FOREIGN KEY ([LocalCurrencyId]) REFERENCES [dbo].[Currency] ([CurrencyId]),
    CONSTRAINT [FK_JournalManual_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [FK_JournalManual_ReportingCurrency] FOREIGN KEY ([ReportingCurrencyId]) REFERENCES [dbo].[Currency] ([CurrencyId]),
    CONSTRAINT [Unique_JournalManual] UNIQUE NONCLUSTERED ([BatchName] ASC, [MasterCompanyId] ASC)
);


GO


CREATE TRIGGER [dbo].[Trg_JournalManualAudit]

   ON  [dbo].[JournalManual]

   AFTER INSERT,UPDATE

AS 

BEGIN



	INSERT INTO [dbo].[JournalManualAudit]

	SELECT * FROM INSERTED



	SET NOCOUNT ON;



END