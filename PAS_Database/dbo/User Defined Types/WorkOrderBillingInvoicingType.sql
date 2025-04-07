CREATE TYPE [dbo].[WorkOrderBillingInvoicingType] AS TABLE (
    [WorkOrderShippingId] BIGINT NULL,
    [NoOfPieces]          INT    NULL,
    [OrderPartId]         BIGINT NULL,
    [WorkOrderPartId]     BIGINT NULL,
    [ConditionId]         BIGINT NULL,
    [BillingInvoicingId]  BIGINT NULL);

