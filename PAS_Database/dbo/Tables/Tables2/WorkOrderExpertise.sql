CREATE TABLE [dbo].[WorkOrderExpertise] (
    [WorkOrderExpertiseId] BIGINT          IDENTITY (1, 1) NOT NULL,
    [WorkOrderId]          BIGINT          NOT NULL,
    [WorkFlowWorkOrderId]  BIGINT          NOT NULL,
    [ExpertiseTypeId]      SMALLINT        NULL,
    [EstimatedHours]       DECIMAL (18, 2) NULL,
    [StandardRate]         DECIMAL (18, 2) NULL,
    [TaskId]               BIGINT          NOT NULL,
    [MasterCompanyId]      INT             NOT NULL,
    [CreatedBy]            VARCHAR (256)   NOT NULL,
    [UpdatedBy]            VARCHAR (256)   NOT NULL,
    [CreatedDate]          DATETIME2 (7)   CONSTRAINT [DF_WorkOrderExpertise_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]          DATETIME2 (7)   CONSTRAINT [DF_WorkOrderExpertise_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]             BIT             CONSTRAINT [DF_WorkOrderExpertise_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]            BIT             CONSTRAINT [DF_WorkOrderExpertise_IsDeleted] DEFAULT ((0)) NOT NULL,
    [LaborDirectRate]      DECIMAL (20, 2) NULL,
    [DirectLaborRate]      DECIMAL (20, 2) NULL,
    [OverHeadBurden]       DECIMAL (20, 2) NULL,
    [OverHeadCost]         DECIMAL (20, 2) NULL,
    [LaborOverHeadCost]    DECIMAL (20, 2) NULL,
    [IsFromWorkFlow]       BIT             DEFAULT ((0)) NULL,
    CONSTRAINT [PK_WorkOrderExpertise] PRIMARY KEY CLUSTERED ([WorkOrderExpertiseId] ASC),
    CONSTRAINT [FK_WorkOrderExpertise_ExpertiseTypeId] FOREIGN KEY ([ExpertiseTypeId]) REFERENCES [dbo].[EmployeeExpertise] ([EmployeeExpertiseId]),
    CONSTRAINT [FK_WorkOrderExpertise_Task] FOREIGN KEY ([TaskId]) REFERENCES [dbo].[Task] ([TaskId]),
    CONSTRAINT [FK_WorkOrderExpertise_WorkFlowWorkOrder] FOREIGN KEY ([WorkFlowWorkOrderId]) REFERENCES [dbo].[WorkOrderWorkFlow] ([WorkFlowWorkOrderId]),
    CONSTRAINT [FK_WorkOrderExpertise_WorkOrder] FOREIGN KEY ([WorkOrderId]) REFERENCES [dbo].[WorkOrder] ([WorkOrderId])
);


GO




CREATE TRIGGER [dbo].[Trg_WorkOrderExpertiseAudit]

   ON  [dbo].[WorkOrderExpertise]

   AFTER INSERT,DELETE,UPDATE

AS

BEGIN

	INSERT INTO WorkOrderExpertiseAudit

	SELECT * FROM INSERTED

	SET NOCOUNT ON;

END