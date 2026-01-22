CREATE TYPE [dbo].[POPartsToReceive] AS TABLE (
    [PurchaseOrderId]           BIGINT NULL,
    [PurchaseOrderPartRecordId] BIGINT NULL,
    [QtyToReceive]              INT    NULL);

