CREATE TABLE [dbo].[WorkOrderExclusions] (
    [WorkOrderExclusionsId]     BIGINT          IDENTITY (1, 1) NOT NULL,
    [WorkOrderId]               BIGINT          NOT NULL,
    [WorkFlowWorkOrderId]       BIGINT          NOT NULL,
    [ItemMasterId]              BIGINT          NOT NULL,
    [EstimtPercentOccurranceId] INT             NULL,
    [Memo]                      NVARCHAR (MAX)  NULL,
    [Quantity]                  INT             NOT NULL,
    [UnitCost]                  DECIMAL (20, 3) NOT NULL,
    [ExtendedCost]              DECIMAL (20, 3) NOT NULL,
    [MasterCompanyId]           INT             NOT NULL,
    [CreatedBy]                 VARCHAR (256)   NOT NULL,
    [UpdatedBy]                 VARCHAR (256)   NOT NULL,
    [CreatedDate]               DATETIME2 (7)   CONSTRAINT [DF_WorkOrderExclusions_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]               DATETIME2 (7)   CONSTRAINT [DF_WorkOrderExclusions_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]                  BIT             CONSTRAINT [WorkOrderExclusions_DC_Active] DEFAULT ((1)) NOT NULL,
    [IsDeleted]                 BIT             CONSTRAINT [WorkOrderExclusions_DC_Delete] DEFAULT ((0)) NOT NULL,
    [TaskId]                    BIGINT          DEFAULT ((0)) NOT NULL,
    [IsFromWorkFlow]            BIT             DEFAULT ((0)) NULL,
    [ConditionCodeId]           BIGINT          NOT NULL,
    [ItemClassificationId]      BIGINT          NULL,
    CONSTRAINT [PK_WorkOrderExclusions] PRIMARY KEY CLUSTERED ([WorkOrderExclusionsId] ASC),
    CONSTRAINT [FK_WorkOrderExclusions_ConditionCodeId] FOREIGN KEY ([ConditionCodeId]) REFERENCES [dbo].[Condition] ([ConditionId]),
    CONSTRAINT [FK_WorkOrderExclusions_ItemClassificationId] FOREIGN KEY ([ItemClassificationId]) REFERENCES [dbo].[ItemClassification] ([ItemClassificationId]),
    CONSTRAINT [FK_WorkOrderExclusions_ItemMaster] FOREIGN KEY ([ItemMasterId]) REFERENCES [dbo].[ItemMaster] ([ItemMasterId]),
    CONSTRAINT [FK_WorkOrderExclusions_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [FK_WorkOrderExclusions_Task] FOREIGN KEY ([TaskId]) REFERENCES [dbo].[Task] ([TaskId]),
    CONSTRAINT [FK_WorkOrderExclusions_WorkFlowWorkOrder] FOREIGN KEY ([WorkFlowWorkOrderId]) REFERENCES [dbo].[WorkOrderWorkFlow] ([WorkFlowWorkOrderId]),
    CONSTRAINT [FK_WorkOrderExclusions_WorkOrder] FOREIGN KEY ([WorkOrderId]) REFERENCES [dbo].[WorkOrder] ([WorkOrderId])
);


GO




CREATE TRIGGER [dbo].[Trg_WorkOrderExclusionsAudit]

   ON  [dbo].[WorkOrderExclusions]

   AFTER INSERT,DELETE,UPDATE

AS

BEGIN

	INSERT INTO WorkOrderExclusionsAudit

	SELECT * FROM INSERTED

	SET NOCOUNT ON;

END