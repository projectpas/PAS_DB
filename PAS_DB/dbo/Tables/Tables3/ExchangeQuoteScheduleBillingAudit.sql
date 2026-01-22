CREATE TABLE [dbo].[ExchangeQuoteScheduleBillingAudit] (
    [ExchangeQuoteScheduleBillingAuditId] BIGINT         IDENTITY (1, 1) NOT NULL,
    [ExchangeQuoteScheduleBillingId]      BIGINT         NOT NULL,
    [ExchangeQuotePartId]                 BIGINT         NOT NULL,
    [ExchangeQuoteId]                     BIGINT         NOT NULL,
    [ScheduleBillingDate]                 DATETIME2 (7)  NOT NULL,
    [PeriodicBillingAmount]               NUMERIC (9, 2) NOT NULL,
    [Cogs]                                INT            NOT NULL,
    [CogsAmount]                          NUMERIC (9, 2) NULL,
    CONSTRAINT [PK_ExchangeQuoteScheduleBillingAudit] PRIMARY KEY CLUSTERED ([ExchangeQuoteScheduleBillingAuditId] ASC)
);

