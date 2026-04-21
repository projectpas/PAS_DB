CREATE TABLE [dbo].[SalesOrderQuoteStockLineCost] (
    [SalesOrderQuoteStockLineCostId] BIGINT          IDENTITY (1, 1) NOT NULL,
    [SalesOrderQuoteId]              BIGINT          NOT NULL,
    [SalesOrderQuotePartId]          BIGINT          NOT NULL,
    [SalesOrderQuoteStocklineId]     BIGINT          NOT NULL,
    [UnitSalesPrice]                 DECIMAL (18, 6) NULL,
    [UnitSalesPriceExtended]         DECIMAL (18, 6) NULL,
    [UnitCost]                       DECIMAL (18, 6) NULL,
    [UnitCostExtended]               DECIMAL (18, 6) NULL,
    [MarkUpPercentage]               DECIMAL (18, 6) NULL,
    [MarkUpAmount]                   DECIMAL (18, 6) NULL,
    [DiscountPercentage]             DECIMAL (18, 6) NULL,
    [DiscountAmount]                 DECIMAL (18, 6) NULL,
    [MarginAmount]                   DECIMAL (18, 6) NULL,
    [MarginPercentage]               DECIMAL (18, 6) NULL,
    [NetSaleAmount]                  DECIMAL (18, 6) NULL,
    [MasterCompanyId]                INT             NOT NULL,
    [CreatedBy]                      VARCHAR (256)   NOT NULL,
    [CreatedDate]                    DATETIME2 (7)   CONSTRAINT [DF_SalesOrderQuoteStockLineCost_CreatedDate] DEFAULT (getutcdate()) NOT NULL,
    [UpdatedBy]                      VARCHAR (256)   NOT NULL,
    [UpdatedDate]                    DATETIME2 (7)   CONSTRAINT [DF_SalesOrderQuoteStockLineCost_UpdatedDate] DEFAULT (getutcdate()) NOT NULL,
    [IsActive]                       BIT             CONSTRAINT [DF_SalesOrderQuoteStockLineCost_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]                      BIT             CONSTRAINT [DF_SalesOrderQuoteStockLineCost_IsDeleted] DEFAULT ((0)) NOT NULL,
    [NetSaleAmountPerUnit]           DECIMAL (18, 6) NULL,
    CONSTRAINT [PK_SalesOrderQuoteStockLineCost] PRIMARY KEY CLUSTERED ([SalesOrderQuoteStockLineCostId] ASC),
    CONSTRAINT [FK_SalesOrderQuoteStockLineCost_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [FK_SalesOrderQuoteStockLineCost_SalesOrderQuote] FOREIGN KEY ([SalesOrderQuoteId]) REFERENCES [dbo].[SalesOrderQuote] ([SalesOrderQuoteId]),
    CONSTRAINT [FK_SalesOrderQuoteStockLineCost_SalesOrderQuoteStocklineV1] FOREIGN KEY ([SalesOrderQuoteStocklineId]) REFERENCES [dbo].[SalesOrderQuoteStocklineV1] ([SalesOrderQuoteStocklineId])
);










GO
CREATE TRIGGER [dbo].[Trg_SalesOrderQuoteStockLineCostAudit]
   ON  [dbo].[SalesOrderQuoteStockLineCost]
   AFTER INSERT,DELETE,UPDATE
AS 
BEGIN
	INSERT INTO SalesOrderQuoteStockLineCostAudit
	SELECT * FROM INSERTED
	SET NOCOUNT ON;
END