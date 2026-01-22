CREATE TABLE [dbo].[WorkOrderTeardown] (
    [WorkOrderTeardownId]     BIGINT        IDENTITY (1, 1) NOT NULL,
    [WorkOrderId]             BIGINT        NOT NULL,
    [WorkFlowWorkOrderId]     BIGINT        NOT NULL,
    [MasterCompanyId]         INT           NOT NULL,
    [CreatedBy]               VARCHAR (256) NULL,
    [UpdatedBy]               VARCHAR (256) NULL,
    [CreatedDate]             DATETIME2 (7) CONSTRAINT [DF_WorkOrderTeardown_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]             DATETIME2 (7) CONSTRAINT [DF_WorkOrderTeardown_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]                BIT           DEFAULT ((1)) NOT NULL,
    [IsDeleted]               BIT           DEFAULT ((0)) NOT NULL,
    [IsAdditionalComments]    BIT           NULL,
    [IsBulletinsModification] BIT           NULL,
    [IsDiscovery]             BIT           NULL,
    [IsFinalInspection]       BIT           NULL,
    [IsFinalTest]             BIT           NULL,
    [IsPmaDerBulletins]       BIT           NULL,
    [IsPreAssemblyInspection] BIT           NULL,
    [IsPreAssmentResults]     BIT           NULL,
    [IsPreliinaryReview]      BIT           NULL,
    [IsRemovalReasons]        BIT           NULL,
    [IsTestDataUsed]          BIT           NULL,
    [IsWorkPerformed]         BIT           NULL,
    [WOPartNoId]              BIGINT        DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_WorkOrderTeardown] PRIMARY KEY CLUSTERED ([WorkOrderTeardownId] ASC),
    CONSTRAINT [FK_WorkOrderTeardown_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [FK_WorkOrderTeardown_WorkFlowWorkOrderId] FOREIGN KEY ([WorkFlowWorkOrderId]) REFERENCES [dbo].[WorkOrderWorkFlow] ([WorkFlowWorkOrderId]),
    CONSTRAINT [FK_WorkOrderTeardown_WorkOrder] FOREIGN KEY ([WorkOrderId]) REFERENCES [dbo].[WorkOrder] ([WorkOrderId])
);


GO




CREATE TRIGGER [dbo].[Trg_WorkOrderTeardownAudit]

   ON  [dbo].[WorkOrderTeardown]

   AFTER INSERT,DELETE,UPDATE

AS

BEGIN

	INSERT INTO WorkOrderTeardownAudit

	SELECT * FROM INSERTED

	SET NOCOUNT ON;

END