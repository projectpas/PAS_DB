CREATE TYPE [dbo].[PurchaseOrderPartWOSOEXCHType] AS TABLE (
    [PoPartSrNum]               INT    NULL,
    [PurchaseOrderPartRecordId] BIGINT NULL,
    [PurchaseOrderId]           BIGINT NULL,
    [QuantityOrdered]           INT    DEFAULT ((0)) NULL,
    [WorkOrderId]               BIGINT NULL,
    [SubWorkOrderId]            BIGINT NULL,
    [RepairOrderId]             BIGINT NULL,
    [SalesOrderId]              BIGINT NULL,
    [ExchangeSalesOrderId]      BIGINT NULL,
    [LotId]                     BIGINT NULL,
    [RequestedQtyFromWO]        INT    NULL,
    [IsFromSubWorkOrder]        BIT    DEFAULT ((0)) NULL);

