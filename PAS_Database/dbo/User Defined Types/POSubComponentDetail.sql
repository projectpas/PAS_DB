CREATE TYPE [dbo].[POSubComponentDetail] AS TABLE (
    [PurchaseOrderPartRecordId] BIGINT          NULL,
    [SubItemMasterId]           BIGINT          NULL,
    [OriginalConditionId]       BIGINT          NULL,
    [ConditionId]               BIGINT          NULL,
    [QtyReceived]               DECIMAL (18, 6) NULL,
    [UnitCost]                  DECIMAL (18, 6) NULL);

