CREATE TYPE [dbo].[StockLineInventoryType] AS TABLE (
    [StockLineId]  BIGINT          NULL,
    [OldQty]       BIGINT          NULL,
    [NewQty]       BIGINT          NULL,
    [UnitPrice]    DECIMAL (18, 2) NULL,
    [OldUnitPrice] DECIMAL (18, 2) NULL,
    [QtyOnHand]    BIGINT          NULL);

