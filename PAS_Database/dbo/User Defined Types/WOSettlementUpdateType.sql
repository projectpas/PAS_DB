CREATE TYPE [dbo].[WOSettlementUpdateType] AS TABLE (
    [WorkOrderId]         BIGINT        NULL,
    [WorkOrderPartNoId]   BIGINT        NULL,
    [WorkFlowWorkOrderId] BIGINT        NULL,
    [SubWorkOrderId]      BIGINT        NULL,
    [SubWOPartNoId]       BIGINT        NULL,
    [FinalConditionId]    BIGINT        NULL,
    [IsSubWorkOrder]      BIT           NULL,
    [UpdatedBy]           VARCHAR (256) NULL,
    [RevisedPartId]       BIGINT        NULL,
    [SerialNumber]        VARCHAR (100) NULL);

