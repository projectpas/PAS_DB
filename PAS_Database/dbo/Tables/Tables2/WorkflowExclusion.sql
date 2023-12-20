CREATE TABLE [dbo].[WorkflowExclusion] (
    [WorkflowExclusionId]     BIGINT          IDENTITY (1, 1) NOT NULL,
    [WorkflowId]              BIGINT          NOT NULL,
    [ItemMasterId]            BIGINT          NOT NULL,
    [UnitCost]                DECIMAL (18, 2) CONSTRAINT [DF_WorkflowExclusion_UnitCost] DEFAULT ((0)) NULL,
    [Quantity]                INT             NULL,
    [ExtendedCost]            DECIMAL (18, 2) CONSTRAINT [DF_WorkflowExclusion_ExtendedCost] DEFAULT ((0)) NULL,
    [EstimtPercentOccurrance] TINYINT         NULL,
    [Memo]                    NVARCHAR (MAX)  NULL,
    [TaskId]                  BIGINT          NULL,
    [MasterCompanyId]         INT             NOT NULL,
    [CreatedBy]               VARCHAR (256)   NULL,
    [UpdatedBy]               VARCHAR (256)   NULL,
    [CreatedDate]             DATETIME2 (7)   CONSTRAINT [DF_WorkflowExclusion_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]             DATETIME2 (7)   CONSTRAINT [DF_WorkflowExclusion_UpdatedDate] DEFAULT (getdate()) NULL,
    [IsActive]                BIT             CONSTRAINT [DF_WorkflowExclusion_IsActive] DEFAULT ((1)) NULL,
    [IsDeleted]               BIT             CONSTRAINT [DF_WorkflowExclusion_IsDeleted] DEFAULT ((0)) NOT NULL,
    [PartNumber]              VARCHAR (256)   NULL,
    [PartDescription]         VARCHAR (256)   NULL,
    [Order]                   INT             NULL,
    [ConditionId]             BIGINT          NOT NULL,
    [ItemClassificationId]    BIGINT          NULL,
    [WFParentId]              BIGINT          NULL,
    [IsVersionIncrease]       BIT             NULL,
    CONSTRAINT [PK_WorkflowExclusion] PRIMARY KEY CLUSTERED ([WorkflowExclusionId] ASC),
    CONSTRAINT [FK_WorkflowExclusion_ConditionId] FOREIGN KEY ([ConditionId]) REFERENCES [dbo].[Condition] ([ConditionId]),
    CONSTRAINT [FK_WorkflowExclusion_ItemClassificationId] FOREIGN KEY ([ItemClassificationId]) REFERENCES [dbo].[ItemClassification] ([ItemClassificationId]),
    CONSTRAINT [FK_WorkFlowExclusion_ItemMasterId] FOREIGN KEY ([ItemMasterId]) REFERENCES [dbo].[ItemMaster] ([ItemMasterId]),
    CONSTRAINT [FK_WorkFlowExclusion_Task_TaskId] FOREIGN KEY ([TaskId]) REFERENCES [dbo].[Task] ([TaskId]),
    CONSTRAINT [FK_WorkFlowExclusion_WorkflowId] FOREIGN KEY ([WorkflowId]) REFERENCES [dbo].[Workflow] ([WorkflowId])
);


GO




CREATE TRIGGER [dbo].[Trg_WorkflowExclusionAudit]

   ON  [dbo].[WorkflowExclusion]

   AFTER INSERT,DELETE,UPDATE

AS

BEGIN

	INSERT INTO WorkflowExclusionAudit

	SELECT * FROM INSERTED

	SET NOCOUNT ON;

END