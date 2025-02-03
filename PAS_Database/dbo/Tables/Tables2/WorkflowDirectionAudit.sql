CREATE TABLE [dbo].[WorkflowDirectionAudit] (
    [WorkflowDirectionAuditId] BIGINT         IDENTITY (1, 1) NOT NULL,
    [WorkflowDirectionId]      BIGINT         NOT NULL,
    [WorkflowId]               BIGINT         NOT NULL,
    [Action]                   NVARCHAR (MAX) NOT NULL,
    [Description]              NVARCHAR (MAX) NOT NULL,
    [Sequence]                 VARCHAR (100)  NOT NULL,
    [Memo]                     NVARCHAR (MAX) NULL,
    [TaskId]                   BIGINT         NULL,
    [MasterCompanyId]          INT            NOT NULL,
    [CreatedBy]                VARCHAR (256)  NULL,
    [UpdatedBy]                VARCHAR (256)  NULL,
    [CreatedDate]              DATETIME2 (7)  NULL,
    [UpdatedDate]              DATETIME2 (7)  NULL,
    [IsActive]                 BIT            NULL,
    [IsDeleted]                BIT            NOT NULL,
    [Order]                    INT            NULL,
    [WFParentId]               BIGINT         NULL,
    [IsVersionIncrease]        BIT            NULL,
    [TaskName]                 VARCHAR (200)  NULL,
    CONSTRAINT [PK_WorkflowDirectionAudit] PRIMARY KEY CLUSTERED ([WorkflowDirectionAuditId] ASC)
);



