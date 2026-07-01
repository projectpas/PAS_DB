CREATE TYPE [dbo].[ReceivingReconciliationDetailsType] AS TABLE (
    [StocklineId] BIGINT          NULL,
    [StockType]   VARCHAR (20)    NULL,
    [InvoicedQty] DECIMAL (18, 6) NULL);

