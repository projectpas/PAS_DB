CREATE TABLE [dbo].[SalesOrderQuotePartCost] (
    [SalesOrderQuotePartCostId] BIGINT          IDENTITY (1, 1) NOT NULL,
    [SalesOrderQuoteId]         BIGINT          NOT NULL,
    [SalesOrderQuotePartId]     BIGINT          NOT NULL,
    [UnitSalesPrice]            DECIMAL (18, 4) NULL,
    [UnitSalesPriceExtended]    DECIMAL (18, 4) NULL,
    [UnitCost]                  DECIMAL (18, 4) NULL,
    [UnitCostExtended]          DECIMAL (18, 4) NULL,
    [MarkUpPercentage]          DECIMAL (18, 4) NULL,
    [MarkUpAmount]              DECIMAL (18, 4) NULL,
    [MarginAmount]              DECIMAL (18, 4) NULL,
    [MarginPercentage]          DECIMAL (18, 4) NULL,
    [DiscountPercentage]        DECIMAL (18, 4) NULL,
    [DiscountAmount]            DECIMAL (18, 4) NULL,
    [TaxPercentage]             DECIMAL (18, 4) NULL,
    [TaxAmount]                 DECIMAL (18, 4) NULL,
    [MiscCharges]               DECIMAL (18, 4) NULL,
    [Freight]                   DECIMAL (18, 4) NULL,
    [GrossSaleAmount]           DECIMAL (18, 4) NULL,
    [NetSaleAmount]             DECIMAL (18, 4) NULL,
    [TotalRevenue]              DECIMAL (18, 4) NULL,
    [MasterCompanyId]           INT             NOT NULL,
    [CreatedBy]                 VARCHAR (256)   NOT NULL,
    [CreatedDate]               DATETIME2 (7)   CONSTRAINT [DF_SalesOrderQuotePartCost_CreatedDate] DEFAULT (getutcdate()) NOT NULL,
    [UpdatedBy]                 VARCHAR (256)   NOT NULL,
    [UpdatedDate]               DATETIME2 (7)   CONSTRAINT [DF_SalesOrderQuotePartCost_UpdatedDate] DEFAULT (getutcdate()) NOT NULL,
    [IsActive]                  BIT             CONSTRAINT [DF_SalesOrderQuotePartCost_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]                 BIT             CONSTRAINT [DF_SalesOrderQuotePartCost_IsDeleted] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_SalesOrderQuotePartCost] PRIMARY KEY CLUSTERED ([SalesOrderQuotePartCostId] ASC)
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