CREATE TABLE [dbo].[ExchangeQuoteMarginSummary] (
    [ExchangeQuoteMarginSummaryId] BIGINT         IDENTITY (1, 1) NOT NULL,
    [ExchangeQuoteId]              BIGINT         NOT NULL,
    [ExchangeFees]                 NUMERIC (9, 2) NULL,
    [OverhaulPrice]                NUMERIC (9, 2) NULL,
    [OtherCharges]                 NUMERIC (9, 2) NULL,
    [TotalEstRevenue]              NUMERIC (9, 2) NULL,
    [COGSFees]                     NUMERIC (9, 2) NULL,
    [OverhaulCost]                 NUMERIC (9, 2) NULL,
    [OtherCost]                    NUMERIC (9, 2) NULL,
    [MarginAmount]                 NUMERIC (9, 2) NULL,
    [MarginPercentage]             NUMERIC (9, 2) NULL,
    [TotalEstCost]                 NUMERIC (9, 2) NULL,
    [FreightAmount]                NUMERIC (9, 2) NULL,
    CONSTRAINT [PK_ExchangeQuoteMarginSummary] PRIMARY KEY CLUSTERED ([ExchangeQuoteMarginSummaryId] ASC),
    CONSTRAINT [FK_ExchangeQuoteMarginSummary_ExchangeQuote] FOREIGN KEY ([ExchangeQuoteId]) REFERENCES [dbo].[ExchangeQuote] ([ExchangeQuoteId])
);


GO


CREATE TRIGGER [dbo].[Trg_ExchangeQuoteMarginSummaryAudit]

   ON  [dbo].[ExchangeQuoteMarginSummary]

   AFTER INSERT,DELETE,UPDATE

AS 

BEGIN



	INSERT INTO ExchangeQuoteMarginSummaryAudit

	SELECT * FROM INSERTED



	SET NOCOUNT ON;



END