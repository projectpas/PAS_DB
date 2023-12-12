CREATE TYPE [dbo].[PostStocklineBatchType] AS TABLE (
    [StocklineId]     BIGINT          NOT NULL,
    [Qty]             INT             NOT NULL,
    [Amount]          DECIMAL (18, 2) NULL,
    [ModuleName]      VARCHAR (256)   NULL,
    [UpdateBy]        VARCHAR (256)   NULL,
    [MasterCompanyId] INT             NULL,
    [StockType]       VARCHAR (256)   NULL);

