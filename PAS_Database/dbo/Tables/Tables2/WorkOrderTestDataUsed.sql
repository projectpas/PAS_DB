CREATE TABLE [dbo].[WorkOrderTestDataUsed] (
    [WorkOrderTestDataUsedId] BIGINT         IDENTITY (1, 1) NOT NULL,
    [WorkOrderTeardownId]     BIGINT         NULL,
    [Memo]                    NVARCHAR (MAX) NULL,
    [ReasonId]                BIGINT         NULL,
    [SubWorkOrderTeardownId]  BIGINT         NULL,
    [ReasonName]              VARCHAR (200)  NULL,
    [CreatedBy]               VARCHAR (256)  NOT NULL,
    [UpdatedBy]               VARCHAR (256)  NOT NULL,
    [CreatedDate]             DATETIME2 (7)  DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]             DATETIME2 (7)  DEFAULT (getdate()) NOT NULL,
    [IsActive]                BIT            DEFAULT ((1)) NOT NULL,
    [IsDeleted]               BIT            DEFAULT ((0)) NOT NULL,
    [MasterCompanyId]         INT            DEFAULT ((1)) NOT NULL,
    CONSTRAINT [PK_WorkOrderTestDataUsed] PRIMARY KEY CLUSTERED ([WorkOrderTestDataUsedId] ASC),
    CONSTRAINT [FK_WorkOrderTestDataUsed_MasterCompanyId] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [FK_WorkOrderTestDataUsed_Reason] FOREIGN KEY ([ReasonId]) REFERENCES [dbo].[TeardownReason] ([TeardownReasonId]),
    CONSTRAINT [FK_WorkOrderTestDataUsed_SubWorkOrderTeardown] FOREIGN KEY ([SubWorkOrderTeardownId]) REFERENCES [dbo].[SubWorkOrderTeardown] ([SubWorkOrderTeardownId]),
    CONSTRAINT [FK_WorkOrderTestDataUsed_WorkOrderTeardown] FOREIGN KEY ([WorkOrderTeardownId]) REFERENCES [dbo].[WorkOrderTeardown] ([WorkOrderTeardownId])
);

