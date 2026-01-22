CREATE TYPE [dbo].[WorkOrderTasks] AS TABLE (
    [WorkOrderTaskId] BIGINT        NULL,
    [WorkOrderId]     BIGINT        NULL,
    [TaskId]          BIGINT        NULL,
    [SequenceNumber]  VARCHAR (10)  NULL,
    [MasterCompanyId] INT           NULL,
    [UpdatedBy]       VARCHAR (256) NULL);

