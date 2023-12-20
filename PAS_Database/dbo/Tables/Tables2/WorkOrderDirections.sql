CREATE TABLE [dbo].[WorkOrderDirections] (
    [WorkOrderDirectionId] BIGINT         IDENTITY (1, 1) NOT NULL,
    [WorkOrderId]          BIGINT         NOT NULL,
    [WorkFlowWorkOrderId]  BIGINT         NOT NULL,
    [Action]               VARCHAR (256)  NULL,
    [DirectionName]        VARCHAR (256)  NULL,
    [Sequence]             INT            NULL,
    [Memo]                 NVARCHAR (MAX) NULL,
    [TaskId]               BIGINT         NOT NULL,
    [MasterCompanyId]      INT            NOT NULL,
    [CreatedBy]            VARCHAR (256)  NOT NULL,
    [UpdatedBy]            VARCHAR (256)  NOT NULL,
    [CreatedDate]          DATETIME2 (7)  CONSTRAINT [DF_WorkOrderDirections_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]          DATETIME2 (7)  CONSTRAINT [DF_WorkOrderDirections_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]             BIT            CONSTRAINT [DF_WorkOrderDirections_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]            BIT            CONSTRAINT [DF_WorkOrderDirections_IsDeleted] DEFAULT ((0)) NOT NULL,
    [IsFromWorkFlow]       BIT            DEFAULT ((0)) NULL,
    CONSTRAINT [PK_WorkOrderDirections] PRIMARY KEY CLUSTERED ([WorkOrderDirectionId] ASC),
    CONSTRAINT [FK_WorkOrderDirections_MasterCompanyId] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [FK_WorkOrderDirections_TaskId] FOREIGN KEY ([TaskId]) REFERENCES [dbo].[Task] ([TaskId]),
    CONSTRAINT [FK_WorkOrderDirections_WorkFlowWorkOrder] FOREIGN KEY ([WorkFlowWorkOrderId]) REFERENCES [dbo].[WorkOrderWorkFlow] ([WorkFlowWorkOrderId]),
    CONSTRAINT [FK_WorkOrderDirections_WorkOrder] FOREIGN KEY ([WorkOrderId]) REFERENCES [dbo].[WorkOrder] ([WorkOrderId])
);


GO




CREATE TRIGGER [dbo].[Trg_WorkOrderDirectionsAudit]

   ON  [dbo].[WorkOrderDirections]

   AFTER INSERT,DELETE,UPDATE

AS

BEGIN

	INSERT INTO WorkOrderDirectionsAudit

	SELECT * FROM INSERTED

	SET NOCOUNT ON;

END