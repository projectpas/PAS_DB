CREATE TYPE [dbo].[SOQStockLineListType] AS TABLE (
    [SalesOrderQuoteId]          BIGINT NULL,
    [SalesOrderQuotePartId]      BIGINT NULL,
    [SalesOrderQuoteStocklineId] BIGINT NULL,
    [StockLineId]                BIGINT NULL,
    [QuantityToQuoted]           INT    NULL);

