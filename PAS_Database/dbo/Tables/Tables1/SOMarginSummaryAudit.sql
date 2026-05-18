CREATE TABLE [dbo].[SOMarginSummaryAudit] (
    [AuditSOMarginSummaryId] BIGINT          IDENTITY (1, 1) NOT NULL,
    [SOMarginSummaryId]      BIGINT          NOT NULL,
    [SalesOrderId]           BIGINT          NOT NULL,
    [Sales]                  DECIMAL (18, 6) NULL,
    [Misc]                   DECIMAL (18, 6) NULL,
    [NetSales]               DECIMAL (18, 6) NULL,
    [ProductCost]            DECIMAL (18, 6) NULL,
    [MarginAmount]           DECIMAL (18, 6) NULL,
    [MarginPercentage]       DECIMAL (18, 6) NULL,
    [FreightAmount]          DECIMAL (18, 6) NULL,
    CONSTRAINT [PK_SOMarginSummaryAudit] PRIMARY KEY CLUSTERED ([AuditSOMarginSummaryId] ASC),
    CONSTRAINT [FK_SMarginSummaryAudit_SOMarginSummary] FOREIGN KEY ([SOMarginSummaryId]) REFERENCES [dbo].[SOMarginSummary] ([SOMarginSummaryId])
);

