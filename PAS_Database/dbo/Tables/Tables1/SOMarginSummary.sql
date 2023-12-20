CREATE TABLE [dbo].[SOMarginSummary] (
    [SOMarginSummaryId] BIGINT         IDENTITY (1, 1) NOT NULL,
    [SalesOrderId]      BIGINT         NOT NULL,
    [Sales]             NUMERIC (9, 2) NOT NULL,
    [Misc]              NUMERIC (9, 2) NOT NULL,
    [NetSales]          NUMERIC (9, 2) NOT NULL,
    [ProductCost]       NUMERIC (9, 2) NOT NULL,
    [MarginAmount]      NUMERIC (9, 2) NOT NULL,
    [MarginPercentage]  NUMERIC (9, 2) NOT NULL,
    [FreightAmount]     NUMERIC (9, 2) NULL,
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