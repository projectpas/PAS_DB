CREATE TYPE [dbo].[UnIssueWorkOrderMaterialStocklineType] AS TABLE (
    [WorkOrderId]           BIGINT        NULL,
    [WorkOrderPartNoId]     BIGINT        NULL,
    [WorkOrderMaterialsId]  BIGINT        NULL,
    [WOMaterialStocklineId] BIGINT        NULL,
    [StocklineId]           BIGINT        NULL,
    [ItemMasterId]          BIGINT        NULL,
    [ConditionId]           BIGINT        NULL,
    [ProvisionId]           BIGINT        NULL,
    [UpdatedById]           BIGINT        NULL,
    [QtyToBeUnIssued]       INT           NULL,
    [QuantityActUnIssued]   INT           NULL,
    [UpdatedBy]             VARCHAR (100) NULL,
    [IsStocklineAdded]      BIT           NULL,
    [MasterCompanyId]       INT           NULL);

