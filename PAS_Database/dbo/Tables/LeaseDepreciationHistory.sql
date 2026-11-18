CREATE TABLE [dbo].[LeaseDepreciationHistory] (
    [ID]                    BIGINT          IDENTITY (1, 1) NOT NULL,
    [LeaseStocklineId]      BIGINT          NOT NULL,
    [LeaseHeaderId]         BIGINT          NOT NULL,
    [StocklineNumber]       VARCHAR (100)   NULL,
    [SerialNo]              VARCHAR (100)   NULL,
    [InServiceDate]         DATETIME        NULL,
    [DepriciableStatus]     VARCHAR (20)    NULL,
    [CURRENCY]              VARCHAR (10)    NULL,
    [DepriciableLife]       INT             NULL,
    [DepreciationMethod]    VARCHAR (30)    NULL,
    [DepreciationFrequency] VARCHAR (50)    NULL,
    [InstalledCost]         DECIMAL (18, 6) NULL,
    [DepreciationAmount]    DECIMAL (18, 6) NULL,
    [AccumlatedDepr]        DECIMAL (18, 6) NULL,
    [NetBookValue]          DECIMAL (18, 6) NULL,
    [NBVAfterDepreciation]  DECIMAL (18, 6) NULL,
    [ResidualPercentage]    DECIMAL (18, 6) NULL,
    [LastDeprRunPeriod]     VARCHAR (30)    NULL,
    [AccountingCalenderId]  BIGINT          NULL,
    [JournalBatchHeaderId]  BIGINT          NULL,
    [MasterCompanyId]       INT             NOT NULL,
    [CreatedBy]             VARCHAR (256)   NOT NULL,
    [CreatedDate]           DATETIME        CONSTRAINT [DF_LeaseDepreciationHistory_CreatedDate] DEFAULT (getutcdate()) NOT NULL,
    [UpdatedBy]             VARCHAR (256)   NOT NULL,
    [UpdatedDate]           DATETIME        CONSTRAINT [DF_LeaseDepreciationHistory_UpdatedDate] DEFAULT (getutcdate()) NOT NULL,
    [IsActive]              BIT             CONSTRAINT [DF_LeaseDepreciationHistory_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDelete]              BIT             CONSTRAINT [DF_LeaseDepreciationHistory_IsDelete] DEFAULT ((0)) NOT NULL,
    [DepreciationStartDate] DATETIME        NULL,
    CONSTRAINT [PK_LeaseDepreciationHistory] PRIMARY KEY CLUSTERED ([ID] ASC),
    CONSTRAINT [FK_LeaseDepreciationHistory_LeaseStockline] FOREIGN KEY ([LeaseStocklineId]) REFERENCES [dbo].[LeaseStockline] ([LeaseStocklineId])
);


GO
CREATE NONCLUSTERED INDEX [IX_LeaseDepreciationHistory_LeaseStocklineId_AccountingCalenderId]
    ON [dbo].[LeaseDepreciationHistory]([LeaseStocklineId] ASC, [AccountingCalenderId] ASC)
    INCLUDE([AccumlatedDepr], [IsDelete]);

