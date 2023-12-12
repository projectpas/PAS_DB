CREATE TABLE [dbo].[ExchangeSalesOrderMarginSummaryAudit] (
    [ExchangeSalesOrderMarginSummaryIdAudit] BIGINT         IDENTITY (1, 1) NOT NULL,
    [ExchangeSalesOrderMarginSummaryId]      BIGINT         NOT NULL,
    [ExchangeSalesOrderId]                   BIGINT         NOT NULL,
    [ExchangeFees]                           NUMERIC (9, 2) NULL,
    [OverhaulPrice]                          NUMERIC (9, 2) NULL,
    [OtherCharges]                           NUMERIC (9, 2) NULL,
    [TotalEstRevenue]                        NUMERIC (9, 2) NULL,
    [COGSFees]                               NUMERIC (9, 2) NULL,
    [OverhaulCost]                           NUMERIC (9, 2) NULL,
    [OtherCost]                              NUMERIC (9, 2) NULL,
    [MarginAmount]                           NUMERIC (9, 2) NULL,
    [MarginPercentage]                       NUMERIC (9, 2) NULL,
    [TotalEstCost]                           NUMERIC (9, 2) NULL,
    [FreightAmount]                          NUMERIC (9, 2) NULL,
    [IsFreightInsert]                        BIT            NULL,
    [IsChargeInsert]                         BIT            NULL,
    CONSTRAINT [PK_ExchangeSalesOrderMarginSummaryAudit] PRIMARY KEY CLUSTERED ([ExchangeSalesOrderMarginSummaryIdAudit] ASC),
    CONSTRAINT [FK_ExchangeSalesOrderMarginSummaryAudit_ExchangeSalesOrderMarginSummary] FOREIGN KEY ([ExchangeSalesOrderMarginSummaryId]) REFERENCES [dbo].[ExchangeSalesOrderMarginSummary] ([ExchangeSalesOrderMarginSummaryId])
);

