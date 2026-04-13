CREATE TABLE [dbo].[SalesOrderQuotePartCost] (
    [SalesOrderQuotePartCostId] BIGINT          IDENTITY (1, 1) NOT NULL,
    [SalesOrderQuoteId]         BIGINT          NOT NULL,
    [SalesOrderQuotePartId]     BIGINT          NOT NULL,
    [UnitSalesPrice]            DECIMAL (18, 6) NULL,
    [UnitSalesPriceExtended]    DECIMAL (18, 6) NULL,
    [UnitCost]                  DECIMAL (18, 6) NULL,
    [UnitCostExtended]          DECIMAL (18, 6) NULL,
    [MarkUpPercentage]          DECIMAL (18, 6) NULL,
    [MarkUpAmount]              DECIMAL (18, 6) NULL,
    [MarginAmount]              DECIMAL (18, 6) NULL,
    [MarginPercentage]          DECIMAL (18, 4) NULL,
    [DiscountPercentage]        DECIMAL (18, 4) NULL,
    [DiscountAmount]            DECIMAL (18, 6) NULL,
    [TaxPercentage]             DECIMAL (18, 4) NULL,
    [TaxAmount]                 DECIMAL (18, 6) NULL,
    [MiscCharges]               DECIMAL (18, 4) NULL,
    [Freight]                   DECIMAL (18, 4) NULL,
    [GrossSaleAmount]           DECIMAL (18, 6) NULL,
    [NetSaleAmount]             DECIMAL (18, 6) NULL,
    [TotalRevenue]              DECIMAL (18, 6) NULL,
    [MasterCompanyId]           INT             NOT NULL,
    [CreatedBy]                 VARCHAR (256)   NOT NULL,
    [CreatedDate]               DATETIME2 (7)   CONSTRAINT [DF_SalesOrderQuotePartCost_CreatedDate] DEFAULT (getutcdate()) NOT NULL,
    [UpdatedBy]                 VARCHAR (256)   NOT NULL,
    [UpdatedDate]               DATETIME2 (7)   CONSTRAINT [DF_SalesOrderQuotePartCost_UpdatedDate] DEFAULT (getutcdate()) NOT NULL,
    [IsActive]                  BIT             CONSTRAINT [DF_SalesOrderQuotePartCost_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]                 BIT             CONSTRAINT [DF_SalesOrderQuotePartCost_IsDeleted] DEFAULT ((0)) NOT NULL,
    [NetSaleAmountPerUnit]      DECIMAL (18, 6) NULL,
    CONSTRAINT [PK_SalesOrderQuotePartCost] PRIMARY KEY CLUSTERED ([SalesOrderQuotePartCostId] ASC),
    CONSTRAINT [FK_SalesOrderQuotePartCost_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [FK_SalesOrderQuotePartCost_SalesOrderQuote] FOREIGN KEY ([SalesOrderQuoteId]) REFERENCES [dbo].[SalesOrderQuote] ([SalesOrderQuoteId]),
    CONSTRAINT [FK_SalesOrderQuotePartCost_SalesOrderQuotePartV1] FOREIGN KEY ([SalesOrderQuotePartId]) REFERENCES [dbo].[SalesOrderQuotePartV1] ([SalesOrderQuotePartId])
);








GO
CREATE TRIGGER [dbo].[Trg_SalesOrderQuotePartCostAudit]
   ON  [dbo].[SalesOrderQuotePartCost]
   AFTER INSERT,DELETE,UPDATE
AS 
BEGIN
	INSERT INTO SalesOrderQuotePartCostAudit
	SELECT * FROM INSERTED
	SET NOCOUNT ON;
END