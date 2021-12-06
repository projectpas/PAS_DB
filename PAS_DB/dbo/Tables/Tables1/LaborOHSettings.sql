CREATE TABLE [dbo].[LaborOHSettings] (
    [LaborOHSettingsId]       BIGINT          IDENTITY (1, 1) NOT NULL,
    [LaborRateId]             INT             DEFAULT ((1)) NOT NULL,
    [AverageRate]             DECIMAL (20, 2) DEFAULT ((0)) NULL,
    [LaborHoursId]            INT             DEFAULT ((1)) NOT NULL,
    [BurdenRateId]            INT             DEFAULT ((1)) NOT NULL,
    [HourlyRate]              DECIMAL (20, 2) NULL,
    [FlatAmount]              DECIMAL (20, 2) NOT NULL,
    [FlatAmountWeek]          DECIMAL (20, 2) NULL,
    [FunctionalCurrencyId]    INT             NULL,
    [TransactionalCurrencyId] INT             NULL,
    [ManagementStructureId]   BIGINT          NULL,
    [MasterCompanyId]         INT             NOT NULL,
    [CreatedDate]             DATETIME2 (7)   CONSTRAINT [DF_LaborOHSettings_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]             DATETIME2 (7)   CONSTRAINT [DF_LaborOHSettings_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [CreatedBy]               VARCHAR (256)   NOT NULL,
    [UpdatedBy]               VARCHAR (256)   NOT NULL,
    [IsActive]                BIT             DEFAULT ((1)) NOT NULL,
    [IsDeleted]               BIT             DEFAULT ((0)) NOT NULL,
    [laborHoursMedthodId]     BIGINT          NULL,
    [Level1]                  VARCHAR (200)   NULL,
    [Level2]                  VARCHAR (200)   NULL,
    [Level3]                  VARCHAR (200)   NULL,
    [Level4]                  VARCHAR (200)   NULL,
    [QuoteAverageRate]        DECIMAL (18, 2) DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_LaborOHSettings] PRIMARY KEY CLUSTERED ([LaborOHSettingsId] ASC),
    CONSTRAINT [FK_LaborOHSettings_FunctionalCurrency] FOREIGN KEY ([FunctionalCurrencyId]) REFERENCES [dbo].[Currency] ([CurrencyId]),
    CONSTRAINT [FK_LaborOHSettings_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [FK_LaborOHSettings_TransactionalCurrency] FOREIGN KEY ([TransactionalCurrencyId]) REFERENCES [dbo].[Currency] ([CurrencyId]),
    CONSTRAINT [UC_LaborOHSettings] UNIQUE NONCLUSTERED ([ManagementStructureId] ASC, [MasterCompanyId] ASC)
);


GO




CREATE TRIGGER [dbo].[Trg_LaborOHSettingsAudit]

   ON  [dbo].[LaborOHSettings]

   AFTER INSERT,UPDATE

AS 

BEGIN



	INSERT INTO [dbo].[LaborOHSettingsAudit]

	SELECT * FROM INSERTED



	SET NOCOUNT ON;



END