CREATE TABLE [dbo].[ExchangeQuoteMarginSummary] (
    [ExchangeQuoteMarginSummaryId] BIGINT          IDENTITY (1, 1) NOT NULL,
    [ExchangeQuoteId]              BIGINT          NOT NULL,
    [ExchangeFees]                 DECIMAL (18, 6) NULL,
    [OverhaulPrice]                DECIMAL (18, 6) NULL,
    [OtherCharges]                 DECIMAL (18, 6) NULL,
    [TotalEstRevenue]              DECIMAL (18, 6) NULL,
    [COGSFees]                     DECIMAL (18, 6) NULL,
    [OverhaulCost]                 DECIMAL (18, 6) NULL,
    [OtherCost]                    DECIMAL (18, 6) NULL,
    [MarginAmount]                 DECIMAL (18, 6) NULL,
    [MarginPercentage]             DECIMAL (18, 6) NULL,
    [TotalEstCost]                 DECIMAL (18, 6) NULL,
    [FreightAmount]                DECIMAL (18, 6) NULL,
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