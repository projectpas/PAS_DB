CREATE TABLE [dbo].[SubWorkOrderPartNumber] (
    [SubWOPartNoId]           BIGINT         IDENTITY (1, 1) NOT NULL,
    [WorkOrderId]             BIGINT         NOT NULL,
    [SubWorkOrderId]          BIGINT         NOT NULL,
    [ItemMasterId]            BIGINT         NOT NULL,
    [SubWorkOrderScopeId]     BIGINT         NOT NULL,
    [EstimatedShipDate]       DATETIME2 (7)  NOT NULL,
    [CustomerRequestDate]     DATETIME2 (7)  NOT NULL,
    [PromisedDate]            DATETIME2 (7)  NOT NULL,
    [EstimatedCompletionDate] DATETIME2 (7)  NOT NULL,
    [NTE]                     INT            NULL,
    [Quantity]                INT            NOT NULL,
    [StockLineId]             BIGINT         NULL,
    [CMMId]                   BIGINT         NULL,
    [WorkflowId]              BIGINT         NULL,
    [SubWorkOrderStageId]     BIGINT         NOT NULL,
    [SubWorkOrderStatusId]    BIGINT         NOT NULL,
    [SubWorkOrderPriorityId]  BIGINT         NOT NULL,
    [IsPMA]                   BIT            NULL,
    [IsDER]                   BIT            NULL,
    [TechStationId]           BIGINT         NULL,
    [TATDaysStandard]         INT            NULL,
    [TechnicianId]            BIGINT         NULL,
    [ConditionId]             BIGINT         NOT NULL,
    [TATDaysCurrent]          INT            NULL,
    [MasterCompanyId]         INT            NOT NULL,
    [CreatedBy]               VARCHAR (256)  NOT NULL,
    [UpdatedBy]               VARCHAR (256)  NOT NULL,
    [CreatedDate]             DATETIME2 (7)  CONSTRAINT [DF_SubWorkOrderPartNumber_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]             DATETIME2 (7)  CONSTRAINT [DF_SubWorkOrderPartNumber_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]                BIT            CONSTRAINT [DF_SWOP_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]               BIT            CONSTRAINT [DF_SWOP_IsDeleted] DEFAULT ((0)) NOT NULL,
    [IsClosed]                BIT            NULL,
    [PDFPath]                 NVARCHAR (MAX) NULL,
    [islocked]                BIT            NULL,
    [IsFinishGood]            BIT            DEFAULT ((0)) NULL,
    [RevisedConditionId]      BIGINT         NULL,
    [CustomerReference]       VARCHAR (256)  NULL,
    CONSTRAINT [PK_SubWorkOrderPartNumber] PRIMARY KEY CLUSTERED ([SubWOPartNoId] ASC),
    CONSTRAINT [FK_SubWorkOrderPartNumber_CMM] FOREIGN KEY ([CMMId]) REFERENCES [dbo].[Publication] ([PublicationRecordId]),
    CONSTRAINT [FK_SubWorkOrderPartNumber_Condition] FOREIGN KEY ([ConditionId]) REFERENCES [dbo].[Condition] ([ConditionId]),
    CONSTRAINT [FK_SubWorkOrderPartNumber_ItemMaster] FOREIGN KEY ([ItemMasterId]) REFERENCES [dbo].[ItemMaster] ([ItemMasterId]),
    CONSTRAINT [FK_SubWorkOrderPartNumber_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [FK_SubWorkOrderPartNumber_RevisedConditionId] FOREIGN KEY ([RevisedConditionId]) REFERENCES [dbo].[Condition] ([ConditionId]),
    CONSTRAINT [FK_SubWorkOrderPartNumber_StockLine] FOREIGN KEY ([StockLineId]) REFERENCES [dbo].[Stockline] ([StockLineId]),
    CONSTRAINT [FK_SubWorkOrderPartNumber_SubWorkOrder] FOREIGN KEY ([SubWorkOrderId]) REFERENCES [dbo].[SubWorkOrder] ([SubWorkOrderId]),
    CONSTRAINT [FK_SubWorkOrderPartNumber_SubWorkOrderPriority] FOREIGN KEY ([SubWorkOrderPriorityId]) REFERENCES [dbo].[Priority] ([PriorityId]),
    CONSTRAINT [FK_SubWorkOrderPartNumber_SubWorkOrderScope] FOREIGN KEY ([SubWorkOrderScopeId]) REFERENCES [dbo].[WorkScope] ([WorkScopeId]),
    CONSTRAINT [FK_SubWorkOrderPartNumber_SubWorkOrderStage] FOREIGN KEY ([SubWorkOrderStageId]) REFERENCES [dbo].[WorkOrderStage] ([WorkOrderStageId]),
    CONSTRAINT [FK_SubWorkOrderPartNumber_SubWorkOrderStatus] FOREIGN KEY ([SubWorkOrderStatusId]) REFERENCES [dbo].[WorkOrderStatus] ([Id]),
    CONSTRAINT [FK_SubWorkOrderPartNumber_Technician] FOREIGN KEY ([TechnicianId]) REFERENCES [dbo].[Employee] ([EmployeeId]),
    CONSTRAINT [FK_SubWorkOrderPartNumber_TechStation] FOREIGN KEY ([TechStationId]) REFERENCES [dbo].[EmployeeStation] ([EmployeeStationId]),
    CONSTRAINT [FK_SubWorkOrderPartNumber_Workflow] FOREIGN KEY ([WorkflowId]) REFERENCES [dbo].[Workflow] ([WorkflowId]),
    CONSTRAINT [FK_SubWorkOrderPartNumber_WorkOrder] FOREIGN KEY ([WorkOrderId]) REFERENCES [dbo].[WorkOrder] ([WorkOrderId])
);


GO


----------------------------------------------

CREATE TRIGGER [dbo].[Trg_SubWorkOrderPartNumberAudit]

   ON  [dbo].[SubWorkOrderPartNumber]

   AFTER INSERT,UPDATE

AS 

BEGIN



	INSERT INTO [dbo].[SubWorkOrderPartNumberAudit] 

    SELECT * 

	FROM INSERTED 

	SET NOCOUNT ON;



END