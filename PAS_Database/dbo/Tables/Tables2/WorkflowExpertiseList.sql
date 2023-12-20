CREATE TABLE [dbo].[WorkflowExpertiseList] (
    [WorkflowExpertiseListId] BIGINT          IDENTITY (1, 1) NOT NULL,
    [WorkflowId]              BIGINT          NOT NULL,
    [ExpertiseTypeId]         SMALLINT        NULL,
    [EstimatedHours]          DECIMAL (18, 2) NULL,
    [LaborDirectRate]         DECIMAL (18, 2) NULL,
    [DirectLaborRate]         DECIMAL (18, 2) NULL,
    [OverheadBurden]          DECIMAL (18, 2) CONSTRAINT [DF_WorkflowExpertiseList_OverheadBurden] DEFAULT ((0)) NULL,
    [OverheadCost]            DECIMAL (18, 2) NULL,
    [StandardRate]            DECIMAL (18, 2) NULL,
    [LaborOverheadCost]       DECIMAL (18, 2) NULL,
    [TaskId]                  BIGINT          NOT NULL,
    [MasterCompanyId]         INT             NOT NULL,
    [CreatedBy]               VARCHAR (256)   NULL,
    [UpdatedBy]               VARCHAR (256)   NULL,
    [CreatedDate]             DATETIME2 (7)   CONSTRAINT [DF_WorkflowExpertiseList_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]             DATETIME2 (7)   CONSTRAINT [DF_WorkflowExpertiseList_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]                BIT             CONSTRAINT [DF_WorkflowExpertiseList_IsActive] DEFAULT ((1)) NULL,
    [IsDeleted]               BIT             CONSTRAINT [DF_WorkflowExpertiseList_IsDeleted] DEFAULT ((0)) NOT NULL,
    [Order]                   INT             NULL,
    [Memo]                    NVARCHAR (MAX)  NULL,
    [WFParentId]              BIGINT          NULL,
    [IsVersionIncrease]       BIT             NULL,
    [OverheadburdenPercentId] BIGINT          NULL,
    CONSTRAINT [PK_ProcessExpertiseList] PRIMARY KEY CLUSTERED ([WorkflowExpertiseListId] ASC),
    CONSTRAINT [FK_WorkflowExpertiseList_EmployeeExpertiseId] FOREIGN KEY ([ExpertiseTypeId]) REFERENCES [dbo].[EmployeeExpertise] ([EmployeeExpertiseId]),
    CONSTRAINT [FK_WorkflowExpertiseList_PercentId] FOREIGN KEY ([OverheadburdenPercentId]) REFERENCES [dbo].[Percent] ([PercentId]),
    CONSTRAINT [FK_WorkflowExpertiseList_Task_TaskId] FOREIGN KEY ([TaskId]) REFERENCES [dbo].[Task] ([TaskId]),
    CONSTRAINT [FK_WorkflowExpertiseList_WorkflowId] FOREIGN KEY ([WorkflowId]) REFERENCES [dbo].[Workflow] ([WorkflowId])
);


GO




CREATE TRIGGER [dbo].[Trg_WorkflowExpertiseListAudit]

   ON  [dbo].[WorkflowExpertiseList]

   AFTER INSERT,DELETE,UPDATE

AS

BEGIN

	INSERT INTO WorkflowExpertiseListAudit

	SELECT * FROM INSERTED

	SET NOCOUNT ON;

END