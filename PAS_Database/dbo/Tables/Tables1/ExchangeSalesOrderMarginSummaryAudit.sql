CREATE TABLE [dbo].[ExchangeSalesOrderMarginSummaryAudit] (
    [ExchangeSalesOrderMarginSummaryIdAudit] BIGINT          IDENTITY (1, 1) NOT NULL,
    [ExchangeSalesOrderMarginSummaryId]      BIGINT          NOT NULL,
    [ExchangeSalesOrderId]                   BIGINT          NOT NULL,
    [ExchangeFees]                           DECIMAL (18, 6) NULL,
    [OverhaulPrice]                          DECIMAL (18, 6) NULL,
    [OtherCharges]                           DECIMAL (18, 6) NULL,
    [TotalEstRevenue]                        DECIMAL (18, 6) NULL,
    [COGSFees]                               DECIMAL (18, 6) NULL,
    [OverhaulCost]                           DECIMAL (18, 6) NULL,
    [OtherCost]                              DECIMAL (18, 6) NULL,
    [MarginAmount]                           DECIMAL (18, 6) NULL,
    [MarginPercentage]                       DECIMAL (18, 6) NULL,
    [TotalEstCost]                           DECIMAL (18, 6) NULL,
    [FreightAmount]                          DECIMAL (18, 6) NULL,
    [IsFreightInsert]                        BIT             NULL,
    [IsChargeInsert]                         BIT             NULL,
    CONSTRAINT [PK_ExchangeSalesOrderMarginSummaryAudit] PRIMARY KEY CLUSTERED ([ExchangeSalesOrderMarginSummaryIdAudit] ASC),
    CONSTRAINT [FK_ExchangeSalesOrderMarginSummaryAudit_ExchangeSalesOrderMarginSummary] FOREIGN KEY ([ExchangeSalesOrderMarginSummaryId]) REFERENCES [dbo].[ExchangeSalesOrderMarginSummary] ([ExchangeSalesOrderMarginSummaryId])
);

