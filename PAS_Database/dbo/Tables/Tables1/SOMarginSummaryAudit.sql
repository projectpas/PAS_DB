CREATE TABLE [dbo].[SOMarginSummaryAudit] (
    [AuditSOMarginSummaryId] BIGINT         IDENTITY (1, 1) NOT NULL,
    [SOMarginSummaryId]      BIGINT         NOT NULL,
    [SalesOrderId]           BIGINT         NOT NULL,
    [Sales]                  NUMERIC (9, 2) NOT NULL,
    [Misc]                   NUMERIC (9, 2) NOT NULL,
    [NetSales]               NUMERIC (9, 2) NOT NULL,
    [ProductCost]            NUMERIC (9, 2) NOT NULL,
    [MarginAmount]           NUMERIC (9, 2) NOT NULL,
    [MarginPercentage]       NUMERIC (9, 2) NOT NULL,
    [FreightAmount]          NUMERIC (9, 2) NULL,
    CONSTRAINT [PK_SOMarginSummaryAudit] PRIMARY KEY CLUSTERED ([AuditSOMarginSummaryId] ASC),
    CONSTRAINT [FK_SMarginSummaryAudit_SOMarginSummary] FOREIGN KEY ([SOMarginSummaryId]) REFERENCES [dbo].[SOMarginSummary] ([SOMarginSummaryId])
);

