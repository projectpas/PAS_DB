CREATE TABLE [dbo].[ExchangeQuoteMarginSummaryAudit] (
    [ExchangeQuoteMarginSummaryIdAudit] BIGINT         IDENTITY (1, 1) NOT NULL,
    [ExchangeQuoteMarginSummaryId]      BIGINT         NOT NULL,
    [ExchangeQuoteId]                   BIGINT         NOT NULL,
    [ExchangeFees]                      NUMERIC (9, 2) NULL,
    [OverhaulPrice]                     NUMERIC (9, 2) NULL,
    [OtherCharges]                      NUMERIC (9, 2) NULL,
    [TotalEstRevenue]                   NUMERIC (9, 2) NULL,
    [COGSFees]                          NUMERIC (9, 2) NULL,
    [OverhaulCost]                      NUMERIC (9, 2) NULL,
    [OtherCost]                         NUMERIC (9, 2) NULL,
    [MarginAmount]                      NUMERIC (9, 2) NULL,
    [MarginPercentage]                  NUMERIC (9, 2) NULL,
    [TotalEstCost]                      NUMERIC (9, 2) NULL,
    [FreightAmount]                     NUMERIC (9, 2) NULL,
    CONSTRAINT [PK_ExchangeQuoteMarginSummaryAudit] PRIMARY KEY CLUSTERED ([ExchangeQuoteMarginSummaryIdAudit] ASC)
);

