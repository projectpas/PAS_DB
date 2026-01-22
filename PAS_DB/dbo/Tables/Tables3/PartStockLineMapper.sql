CREATE TABLE [dbo].[PartStockLineMapper] (
    [Id]                  BIGINT IDENTITY (1, 1) NOT NULL,
    [PurchaseOrderPartId] BIGINT NULL,
    [StockLineId]         BIGINT NULL,
    CONSTRAINT [PK__PartStoc__3214EC076D713E4B] PRIMARY KEY CLUSTERED ([Id] ASC),
    CONSTRAINT [FK_PartStockLineMapper_StockLineId] FOREIGN KEY ([StockLineId]) REFERENCES [dbo].[Stockline] ([StockLineId])
);

