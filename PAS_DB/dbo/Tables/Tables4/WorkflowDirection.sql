CREATE TABLE [dbo].[WorkflowDirection] (
    [WorkflowDirectionId] BIGINT         IDENTITY (1, 1) NOT NULL,
    [WorkflowId]          BIGINT         NOT NULL,
    [Action]              NVARCHAR (MAX) NULL,
    [Description]         NVARCHAR (MAX) NULL,
    [Sequence]            VARCHAR (100)  NULL,
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
    [TaskName]            VARCHAR (200)  NULL,
    [ParentId]            BIGINT         NULL,
    [IsParent]            BIT            NULL,
    [IsTaskDetails]       BIT            NULL,
    CONSTRAINT [PK_WorkflowDirection] PRIMARY KEY CLUSTERED ([WorkflowDirectionId] ASC),
    CONSTRAINT [FK_WorkFlowDirection_WorkflowId] FOREIGN KEY ([WorkflowId]) REFERENCES [dbo].[Workflow] ([WorkflowId])
);


GO
CREATE TRIGGER trg_UpdateTaskName
ON WorkFlowDirection
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE wfd
    SET wfd.TaskName = t.Description
    FROM WorkFlowDirection wfd
    INNER JOIN inserted i ON wfd.WorkflowDirectionId = i.WorkflowDirectionId
    INNER JOIN Task t ON i.TaskId = t.TaskId;
END;
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