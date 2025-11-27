CREATE TYPE [dbo].[WorkOrderShippingItemListType] AS TABLE (
    [WOPickTicketId]          BIGINT NULL,
    [currQtyToShip]           INT    NULL,
    [workOrderPartId]         BIGINT NULL,
    [PackagingSlipId]         BIGINT NULL,
    [WorkOrderShippingId]     BIGINT NULL,
    [WorkOrderShippingItemId] BIGINT NULL);

