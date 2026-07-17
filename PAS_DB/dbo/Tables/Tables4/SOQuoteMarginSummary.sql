CREATE TABLE [dbo].[SOQuoteMarginSummary] (
    [SOQuoteMarginSummaryId] BIGINT          IDENTITY (1, 1) NOT NULL,
    [SalesOrderQuoteId]      BIGINT          NOT NULL,
    [Sales]                  NUMERIC (18, 6) NOT NULL,
    [Misc]                   NUMERIC (18, 6) NOT NULL,
    [NetSales]               NUMERIC (18, 6) NOT NULL,
    [ProductCost]            NUMERIC (18, 6) NOT NULL,
    [MarginAmount]           NUMERIC (18, 6) NOT NULL,
    [MarginPercentage]       NUMERIC (18, 6) NOT NULL,
    [FreightAmount]          NUMERIC (18, 6) NULL,
    CONSTRAINT [PK_SOQuoteMarginSummary] PRIMARY KEY CLUSTERED ([SOQuoteMarginSummaryId] ASC),
    CONSTRAINT [FK_SOQuoteMarginSummary_SalesOrderQuoteId] FOREIGN KEY ([SalesOrderQuoteId]) REFERENCES [dbo].[SalesOrderQuote] ([SalesOrderQuoteId])
);




GO


CREATE TRIGGER [dbo].[Trg_SOQuoteMarginSummaryAudit]

   ON  [dbo].[SOQuoteMarginSummary]

   AFTER INSERT,DELETE,UPDATE

AS 

BEGIN



	INSERT INTO SOQuoteMarginSummaryAudit

	SELECT * FROM INSERTED



	SET NOCOUNT ON;



END