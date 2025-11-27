CREATE TYPE [dbo].[WorkOrderShippingItemType] AS TABLE (
    [WorkOrderShippingId] BIGINT         NULL,
    [WorkOrderPartNumId]  BIGINT         NULL,
    [QtyShipped]          INT            NULL,
    [WOPickTicketId]      BIGINT         NULL,
    [CreatedBy]           NVARCHAR (100) NULL,
    [UpdatedBy]           NVARCHAR (100) NULL,
    [MasterCompanyId]     INT            NULL);

