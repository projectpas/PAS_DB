CREATE TABLE [dbo].[WorkOrderPublications] (
    [WorkOrderPublicationId] BIGINT        IDENTITY (1, 1) NOT NULL,
    [WorkOrderId]            BIGINT        NOT NULL,
    [WorkFlowWorkOrderId]    BIGINT        NOT NULL,
    [PublicationId]          BIGINT        NULL,
    [TaskId]                 BIGINT        NOT NULL,
    [MasterCompanyId]        INT           NOT NULL,
    [CreatedBy]              VARCHAR (256) NOT NULL,
    [UpdatedBy]              VARCHAR (256) NOT NULL,
    [CreatedDate]            DATETIME2 (7) CONSTRAINT [DF_WorkOrderPublications_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]            DATETIME2 (7) CONSTRAINT [DF_WorkOrderPublications_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]               BIT           CONSTRAINT [DF_WorkOrderPublications_IsActive] DEFAULT ((0)) NOT NULL,
    [IsDeleted]              BIT           CONSTRAINT [DF_WorkOrderPublications_IsDeleted] DEFAULT ((0)) NOT NULL,
    [AircraftManufacturerId] BIGINT        NULL,
    [ModelId]                BIGINT        NULL,
    [IsFromWorkFlow]         BIT           DEFAULT ((0)) NULL,
    CONSTRAINT [PK_WorkOrderPublications] PRIMARY KEY CLUSTERED ([WorkOrderPublicationId] ASC),
    CONSTRAINT [FK_WorkOrderPublications_MasterCompanyId] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [FK_WorkOrderPublications_TaskId] FOREIGN KEY ([TaskId]) REFERENCES [dbo].[Task] ([TaskId]),
    CONSTRAINT [FK_WorkOrderPublications_WorkFlowWorkOrder] FOREIGN KEY ([WorkFlowWorkOrderId]) REFERENCES [dbo].[WorkOrderWorkFlow] ([WorkFlowWorkOrderId]),
    CONSTRAINT [FK_WorkOrderPublications_WorkOrder] FOREIGN KEY ([WorkOrderId]) REFERENCES [dbo].[WorkOrder] ([WorkOrderId])
);


GO




CREATE TRIGGER [dbo].[Trg_WorkOrderPublicationsAudit]

   ON  [dbo].[WorkOrderPublications]

   AFTER INSERT,DELETE,UPDATE

AS

BEGIN

	INSERT INTO WorkOrderPublicationsAudit

	SELECT * FROM INSERTED

	SET NOCOUNT ON;

END