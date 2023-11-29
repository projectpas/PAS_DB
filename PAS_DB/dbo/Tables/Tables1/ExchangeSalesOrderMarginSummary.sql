CREATE TABLE [dbo].[ExchangeSalesOrderMarginSummary] (
    [ExchangeSalesOrderMarginSummaryId] BIGINT         IDENTITY (1, 1) NOT NULL,
    [ExchangeSalesOrderId]              BIGINT         NOT NULL,
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
    [IsFreightInsert]                   BIT            NULL,
    [IsChargeInsert]                    BIT            NULL,
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