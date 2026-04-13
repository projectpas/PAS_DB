CREATE TYPE [dbo].[POPartsToReceive] AS TABLE (
    [PurchaseOrderId]           BIGINT          NULL,
    [PurchaseOrderPartRecordId] BIGINT          NULL,
    [QtyToReceive]              DECIMAL (18, 6) NULL);

