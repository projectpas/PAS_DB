CREATE TYPE [dbo].[WorkflowPublicationDashNumberType] AS TABLE (
    [WorkflowPublicationDashNumberId] BIGINT NULL,
    [WorkflowId]                      BIGINT NULL,
    [AircraftDashNumberId]            BIGINT NULL,
    [TaskId]                          BIGINT NULL,
    [WorkflowPublicationsId]          BIGINT NULL);

