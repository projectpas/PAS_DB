CREATE TABLE [dbo].[SOMarginSummary] (
    [SOMarginSummaryId] BIGINT          IDENTITY (1, 1) NOT NULL,
    [SalesOrderId]      BIGINT          NOT NULL,
    [Sales]             DECIMAL (18, 6) NULL,
    [Misc]              DECIMAL (18, 6) NULL,
    [NetSales]          DECIMAL (18, 6) NULL,
    [ProductCost]       DECIMAL (18, 6) NULL,
    [MarginAmount]      DECIMAL (18, 6) NULL,
    [MarginPercentage]  DECIMAL (18, 6) NULL,
    [FreightAmount]     DECIMAL (18, 6) NULL,
    CONSTRAINT [PK_SOMarginSummary] PRIMARY KEY CLUSTERED ([SOMarginSummaryId] ASC),
    CONSTRAINT [FK_SOMarginSummary_SalesOrderId] FOREIGN KEY ([SalesOrderId]) REFERENCES [dbo].[SalesOrder] ([SalesOrderId])
);




GO


CREATE TRIGGER [dbo].[Trg_SOMarginSummaryAudit]

   ON  [dbo].[SOMarginSummary]

   AFTER INSERT,DELETE,UPDATE

AS 

BEGIN



	INSERT INTO SOMarginSummaryAudit

	SELECT * FROM INSERTED



	SET NOCOUNT ON;



END