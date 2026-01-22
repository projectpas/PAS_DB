CREATE TYPE [dbo].[StockLineSalesDataType] AS TABLE (
    [StockLineId]          BIGINT          NULL,
    [UnitSalesPrice]       DECIMAL (18, 2) NULL,
    [SalesPriceExpiryDate] DATETIME2 (7)   NULL,
    [UpdatedBy]            VARCHAR (50)    NULL);

