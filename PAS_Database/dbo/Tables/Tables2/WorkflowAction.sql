CREATE TABLE [dbo].[WorkflowAction] (
    [WorkflowActionId] TINYINT       IDENTITY (1, 1) NOT NULL,
    [Description]      VARCHAR (100) NOT NULL,
    [MasterCompanyId]  INT           NOT NULL,
    [CreatedBy]        VARCHAR (256) NULL,
    [UpdatedBy]        VARCHAR (256) NULL,
    [CreatedDate]      DATETIME2 (7) CONSTRAINT [DF_WorkflowAction_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]      DATETIME2 (7) CONSTRAINT [DF_WorkflowAction_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]         BIT           CONSTRAINT [DF_WorkflowAction_IsActive] DEFAULT ((1)) NULL,
    CONSTRAINT [PK_ProcessAction] PRIMARY KEY CLUSTERED ([WorkflowActionId] ASC),
    CONSTRAINT [FK_ProcessAction_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId])
);


GO




CREATE TRIGGER [dbo].[Trg_WorkflowActionAudit]

   ON  [dbo].[WorkflowAction]

   AFTER INSERT,DELETE,UPDATE

AS

BEGIN

	INSERT INTO WorkflowActionAudit

	SELECT * FROM INSERTED

	SET NOCOUNT ON;

END