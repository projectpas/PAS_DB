CREATE TABLE [dbo].[WorkOrderPublicationDashNumber] (
    [WOPublicationDashNumberId] BIGINT IDENTITY (1, 1) NOT NULL,
    [WorkOrderPublicationId]    BIGINT NOT NULL,
    [DashNumberId]              BIGINT NOT NULL,
    PRIMARY KEY CLUSTERED ([WOPublicationDashNumberId] ASC),
    CONSTRAINT [FK_WorkOrderPublicationDashNumber_WorkOrderPublications] FOREIGN KEY ([WorkOrderPublicationId]) REFERENCES [dbo].[WorkOrderPublications] ([WorkOrderPublicationId])
);

