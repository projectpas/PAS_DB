CREATE TABLE [dbo].[ExchangeSalesOrderMarginSummary] (
    [ExchangeSalesOrderMarginSummaryId] BIGINT          IDENTITY (1, 1) NOT NULL,
    [ExchangeSalesOrderId]              BIGINT          NOT NULL,
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
    [IsFreightInsert]                   BIT             NULL,
    [IsChargeInsert]                    BIT             NULL,
    CONSTRAINT [PK_ExchangeSalesOrderMarginSummary] PRIMARY KEY CLUSTERED ([ExchangeSalesOrderMarginSummaryId] ASC),
    CONSTRAINT [FK_ExchangeSalesOrderMarginSummary_ExchangeSalesOrder] FOREIGN KEY ([ExchangeSalesOrderId]) REFERENCES [dbo].[ExchangeSalesOrder] ([ExchangeSalesOrderId])
);




GO


CREATE TRIGGER [dbo].[Trg_ExchangeSalesOrderMarginSummaryAudit]

   ON  [dbo].[ExchangeSalesOrderMarginSummary]

   AFTER INSERT,DELETE,UPDATE

AS 

BEGIN



	INSERT INTO ExchangeSalesOrderMarginSummaryAudit

	SELECT * FROM INSERTED



	SET NOCOUNT ON;



END