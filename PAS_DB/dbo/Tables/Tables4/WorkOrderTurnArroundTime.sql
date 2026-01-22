CREATE TABLE [dbo].[WorkOrderTurnArroundTime] (
    [WOTATId]              BIGINT        IDENTITY (1, 1) NOT NULL,
    [WorkOrderPartNoId]    BIGINT        NOT NULL,
    [OldStageId]           BIGINT        NOT NULL,
    [CurrentStageId]       BIGINT        NOT NULL,
    [StatusChangedDate]    DATETIME2 (7) NOT NULL,
    [ChangedBy]            VARCHAR (100) NOT NULL,
    [Days]                 INT           NULL,
    [Hours]                INT           NULL,
    [Mins]                 INT           NULL,
    [IsActive]             BIT           CONSTRAINT [WorkOrderTurnArroundTime_DC_Active] DEFAULT ((1)) NOT NULL,
    [StatusChangedEndDate] DATETIME      NULL,
    PRIMARY KEY CLUSTERED ([WOTATId] ASC)
);

