CREATE TABLE [dbo].[WorkflowPublicationDashNumber] (
    [WorkflowPublicationDashNumberId] BIGINT IDENTITY (1, 1) NOT NULL,
    [WorkflowId]                      BIGINT NULL,
    [AircraftDashNumberId]            BIGINT NULL,
    [TaskId]                          BIGINT NULL,
    [WorkflowPublicationsId]          BIGINT NULL,
    PRIMARY KEY CLUSTERED ([WorkflowPublicationDashNumberId] ASC),
    FOREIGN KEY ([WorkflowPublicationsId]) REFERENCES [dbo].[WorkflowPublications] ([WorkflowPublicationsId]),
    CONSTRAINT [FK__WorkflowP__Aircr__5290A8E7] FOREIGN KEY ([AircraftDashNumberId]) REFERENCES [dbo].[AircraftDashNumber] ([DashNumberId])
);

