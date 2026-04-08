CREATE TABLE [dbo].[ExchangeQuoteMarginSummaryAudit] (
    [ExchangeQuoteMarginSummaryIdAudit] BIGINT          IDENTITY (1, 1) NOT NULL,
    [ExchangeQuoteMarginSummaryId]      BIGINT          NOT NULL,
    [ExchangeQuoteId]                   BIGINT          NOT NULL,
    [ExchangeFees]                      DECIMAL (18, 6) NULL,
    [OverhaulPrice]                     DECIMAL (18, 6) NULL,
    [OtherCharges]                      DECIMAL (18, 6) NULL,
    [TotalEstRevenue]                   DECIMAL (18, 6) NULL,
    [COGSFees]                          DECIMAL (18, 6) NULL,
    [OverhaulCost]                      DECIMAL (18, 6) NULL,
    [OtherCost]                         DECIMAL (18, 6) NULL,
    [MarginAmount]                      DECIMAL (18, 6) NULL,
    [MarginPercentage]                  DECIMAL (18, 6) NULL,
    [TotalEstCost]                      DECIMAL (18, 6) NULL,
    [FreightAmount]                     DECIMAL (18, 6) NULL,
    CONSTRAINT [PK_ExchangeQuoteMarginSummaryAudit] PRIMARY KEY CLUSTERED ([ExchangeQuoteMarginSummaryIdAudit] ASC)
);

