CREATE TABLE [dbo].[WorkflowDirection] (
    [WorkflowDirectionId] BIGINT         IDENTITY (1, 1) NOT NULL,
    [WorkflowId]          BIGINT         NOT NULL,
    [Action]              VARCHAR (50)   NOT NULL,
    [Description]         VARCHAR (500)  NULL,
    [Sequence]            VARCHAR (50)   NULL,
    [Memo]                NVARCHAR (MAX) NULL,
    [TaskId]              BIGINT         NULL,
    [MasterCompanyId]     INT            NOT NULL,
    [CreatedBy]           VARCHAR (256)  NULL,
    [UpdatedBy]           VARCHAR (256)  NULL,
    [CreatedDate]         DATETIME2 (7)  CONSTRAINT [DF_WorkflowDirection_CreatedDate] DEFAULT (getdate()) NULL,
    [UpdatedDate]         DATETIME2 (7)  CONSTRAINT [DF_WorkflowDirection_UpdaedDate] DEFAULT (getdate()) NULL,
    [IsActive]            BIT            CONSTRAINT [DF_WorkflowDirection_IsActive] DEFAULT ((1)) NULL,
    [IsDeleted]           BIT            CONSTRAINT [DF_WorkflowDirection_IsDeleted] DEFAULT ((0)) NOT NULL,
    [Order]               INT            NULL,
    [WFParentId]          BIGINT         NULL,
    [IsVersionIncrease]   BIT            NULL,
    CONSTRAINT [PK_WorkflowDirection] PRIMARY KEY CLUSTERED ([WorkflowDirectionId] ASC),
    CONSTRAINT [FK_WorkFlowDirection_Task_TaskId] FOREIGN KEY ([TaskId]) REFERENCES [dbo].[Task] ([TaskId]),
    CONSTRAINT [FK_WorkFlowDirection_WorkflowId] FOREIGN KEY ([WorkflowId]) REFERENCES [dbo].[Workflow] ([WorkflowId])
);


GO




CREATE TRIGGER [dbo].[Trg_WorkflowDirectionAudit]

   ON  [dbo].[WorkflowDirection]

   AFTER INSERT,DELETE,UPDATE

AS

BEGIN

	INSERT INTO WorkflowDirectionAudit

	SELECT * FROM INSERTED

	SET NOCOUNT ON;

END