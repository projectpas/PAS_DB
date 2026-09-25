CREATE TYPE [dbo].[LeaseShippingItemsType] AS TABLE (
    [LeaseShippingItemId] BIGINT          NOT NULL,
    [LeasePickTicketId]   BIGINT          NOT NULL,
    [QtyShipped]          DECIMAL (18, 6) NOT NULL);

