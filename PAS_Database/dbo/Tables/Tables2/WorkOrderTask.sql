CREATE TABLE [dbo].[WorkOrderTask] (
    [WorkOrderTaskId]     BIGINT        IDENTITY (1, 1) NOT NULL,
    [WorkOrderId]         BIGINT        NOT NULL,
    [WorkFlowWorkOrderId] BIGINT        NOT NULL,
    [TaskId]              BIGINT        NOT NULL,
    [MasterCompanyId]     INT           NOT NULL,
    [CreatedBy]           VARCHAR (256) NOT NULL,
    [UpdatedBy]           VARCHAR (256) NOT NULL,
    [CreatedDate]         DATETIME2 (7) CONSTRAINT [DF_WorkOrderTask_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]         DATETIME2 (7) CONSTRAINT [DF_WorkOrderTask_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]            BIT           CONSTRAINT [DF_WorkOrderTask_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]           BIT           CONSTRAINT [DF_WorkOrderTask_IsDeleted] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_WorkOrderTask] PRIMARY KEY CLUSTERED ([WorkOrderTaskId] ASC),
    CONSTRAINT [FK_WorkOrderTask_WorkFlowWorkOrder] FOREIGN KEY ([WorkFlowWorkOrderId]) REFERENCES [dbo].[WorkOrderWorkFlow] ([WorkFlowWorkOrderId]),
    CONSTRAINT [FK_WorkOrderTask_WorkOrder] FOREIGN KEY ([WorkOrderId]) REFERENCES [dbo].[WorkOrder] ([WorkOrderId])
);


GO




CREATE TRIGGER [dbo].[Trg_WorkOrderTaskAudit]

   ON  [dbo].[WorkOrderTask]

   AFTER INSERT,DELETE,UPDATE

AS

BEGIN

	INSERT INTO WorkOrderTaskAudit

	SELECT * FROM INSERTED

	SET NOCOUNT ON;

END