CREATE TYPE [dbo].[WorkOrderTasks] AS TABLE (
    [WorkOrderTaskId] BIGINT          NULL,
    [WorkOrderId]     BIGINT          NULL,
    [TaskId]          BIGINT          NULL,
    [SequenceNumber]  DECIMAL (10, 3) NULL,
    [MasterCompanyId] INT             NULL,
    [UpdatedBy]       VARCHAR (256)   NULL);



