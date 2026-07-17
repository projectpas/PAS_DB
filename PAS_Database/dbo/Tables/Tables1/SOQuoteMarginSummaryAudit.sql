CREATE TABLE [dbo].[SOQuoteMarginSummaryAudit] (
    [AuditSOQuoteMarginSummaryId] BIGINT          IDENTITY (1, 1) NOT NULL,
    [SOQuoteMarginSummaryId]      BIGINT          NOT NULL,
    [SalesOrderQuoteId]           BIGINT          NOT NULL,
    [Sales]                       NUMERIC (18, 6) NOT NULL,
    [Misc]                        NUMERIC (18, 6) NOT NULL,
    [NetSales]                    NUMERIC (18, 6) NOT NULL,
    [ProductCost]                 NUMERIC (18, 6) NOT NULL,
    [MarginAmount]                NUMERIC (18, 6) NOT NULL,
    [MarginPercentage]            NUMERIC (18, 6) NOT NULL,
    [FreightAmount]               NUMERIC (18, 6) NULL,
    CONSTRAINT [PK_SOQuoteMarginSummaryAudit] PRIMARY KEY CLUSTERED ([AuditSOQuoteMarginSummaryId] ASC),
    CONSTRAINT [FK_SOQuoteMarginSummaryAudit_SOQuoteMarginSummary] FOREIGN KEY ([SOQuoteMarginSummaryId]) REFERENCES [dbo].[SOQuoteMarginSummary] ([SOQuoteMarginSummaryId])
);

