CREATE TABLE [dbo].[WorkflowMaterial] (
    [WorkflowMaterialListId]  BIGINT          IDENTITY (1, 1) NOT NULL,
    [WorkflowId]              BIGINT          NOT NULL,
    [ItemMasterId]            BIGINT          NOT NULL,
    [TaskId]                  BIGINT          NULL,
    [Quantity]                SMALLINT        NULL,
    [UnitOfMeasureId]         BIGINT          NULL,
    [ConditionCodeId]         BIGINT          NULL,
    [UnitCost]                DECIMAL (18, 2) CONSTRAINT [DF_WorkflowMaterial_UnitCost] DEFAULT ((0)) NULL,
    [ExtendedCost]            DECIMAL (18, 2) CONSTRAINT [DF_WorkflowMaterial_ExtendedCost] DEFAULT ((0)) NULL,
    [Price]                   DECIMAL (18, 2) NULL,
    [ProvisionId]             INT             NULL,
    [IsDeferred]              BIT             NULL,
    [WorkflowActionId]        TINYINT         NOT NULL,
    [Memo]                    NVARCHAR (MAX)  NULL,
    [MasterCompanyId]         INT             NOT NULL,
    [CreatedBy]               VARCHAR (256)   NULL,
    [UpdatedBy]               VARCHAR (256)   NULL,
    [CreatedDate]             DATETIME2 (7)   CONSTRAINT [DF_WorkflowMaterial_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]             DATETIME2 (7)   CONSTRAINT [DF_WorkflowMaterial_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]                BIT             CONSTRAINT [DF_WorkflowMaterial_IsActive] DEFAULT ((1)) NULL,
    [IsDeleted]               BIT             CONSTRAINT [DF_WorkflowMaterial_IsDeleted] DEFAULT ((0)) NOT NULL,
    [MaterialMandatoriesName] VARCHAR (256)   NULL,
    [PartNumber]              VARCHAR (256)   NULL,
    [PartDescription]         VARCHAR (MAX)   NULL,
    [ItemClassificationId]    BIGINT          NULL,
    [ExtendedPrice]           DECIMAL (18, 2) NULL,
    [Order]                   INT             NULL,
    [MaterialMandatoriesId]   INT             NULL,
    [WFParentId]              BIGINT          NULL,
    [IsVersionIncrease]       BIT             NULL,
    [Figure]                  NVARCHAR (50)   NULL,
    [Item]                    NVARCHAR (50)   NULL,
    CONSTRAINT [PK_ProcessMaterial_1] PRIMARY KEY CLUSTERED ([WorkflowMaterialListId] ASC),
    CONSTRAINT [FK_WorkflowMaterial_ConditionCodeId] FOREIGN KEY ([ConditionCodeId]) REFERENCES [dbo].[Condition] ([ConditionId]),
    CONSTRAINT [FK_WorkflowMaterial_ItemClassificationId] FOREIGN KEY ([ItemClassificationId]) REFERENCES [dbo].[ItemClassification] ([ItemClassificationId]),
    CONSTRAINT [FK_WorkflowMaterial_ItemMasterId] FOREIGN KEY ([ItemMasterId]) REFERENCES [dbo].[ItemMaster] ([ItemMasterId]),
    CONSTRAINT [FK_WorkflowMaterial_MaterialMandatoriesId] FOREIGN KEY ([MaterialMandatoriesId]) REFERENCES [dbo].[MaterialMandatories] ([Id]),
    CONSTRAINT [FK_WorkflowMaterial_Task_TaskId] FOREIGN KEY ([TaskId]) REFERENCES [dbo].[Task] ([TaskId]),
    CONSTRAINT [FK_WorkflowMaterial_UnitOfMeasureId] FOREIGN KEY ([UnitOfMeasureId]) REFERENCES [dbo].[UnitOfMeasure] ([UnitOfMeasureId]),
    CONSTRAINT [FK_WorkflowMaterial_WorkflowId] FOREIGN KEY ([WorkflowId]) REFERENCES [dbo].[Workflow] ([WorkflowId])
);




GO




CREATE TRIGGER [dbo].[Trg_WorkflowMaterialAudit]

   ON  [dbo].[WorkflowMaterial]

   AFTER INSERT,DELETE,UPDATE

AS

BEGIN

	INSERT INTO WorkflowMaterialAudit

	SELECT * FROM INSERTED

	SET NOCOUNT ON;

END