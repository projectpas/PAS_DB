CREATE TABLE [dbo].[SOQuoteMarginSummaryAudit] (
    [AuditSOQuoteMarginSummaryId] BIGINT         IDENTITY (1, 1) NOT NULL,
    [SOQuoteMarginSummaryId]      BIGINT         NOT NULL,
    [SalesOrderQuoteId]           BIGINT         NOT NULL,
    [Sales]                       NUMERIC (9, 2) NOT NULL,
    [Misc]                        NUMERIC (9, 2) NOT NULL,
    [NetSales]                    NUMERIC (9, 2) NOT NULL,
    [ProductCost]                 NUMERIC (9, 2) NOT NULL,
    [MarginAmount]                NUMERIC (9, 2) NOT NULL,
    [MarginPercentage]            NUMERIC (9, 2) NOT NULL,
    [FreightAmount]               NUMERIC (9, 2) NULL,
    CONSTRAINT [PK_SOQuoteMarginSummaryAudit] PRIMARY KEY CLUSTERED ([AuditSOQuoteMarginSummaryId] ASC),
    CONSTRAINT [FK_SOQuoteMarginSummaryAudit_SOQuoteMarginSummary] FOREIGN KEY ([SOQuoteMarginSummaryId]) REFERENCES [dbo].[SOQuoteMarginSummary] ([SOQuoteMarginSummaryId])
);

