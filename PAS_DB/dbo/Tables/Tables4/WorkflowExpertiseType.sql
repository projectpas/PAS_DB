CREATE TABLE [dbo].[WorkflowExpertiseType] (
    [WorkflowExpertiseTypeId] SMALLINT      IDENTITY (1, 1) NOT NULL,
    [Description]             VARCHAR (100) NOT NULL,
    [MasterCompanyId]         INT           NOT NULL,
    [CreatedBy]               VARCHAR (256) NULL,
    [UpdatedBy]               VARCHAR (256) NULL,
    [CreatedDate]             DATETIME2 (7) CONSTRAINT [DF_WorkflowExpertiseType_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]             DATETIME2 (7) CONSTRAINT [DF_WorkflowExpertiseType_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]                BIT           CONSTRAINT [DF_WorkflowExpertiseType_IsActive] DEFAULT ((1)) NULL,
    CONSTRAINT [PK_WorkflowExpertiseType] PRIMARY KEY CLUSTERED ([WorkflowExpertiseTypeId] ASC)
);


GO




CREATE TRIGGER [dbo].[Trg_WorkflowExpertiseTypeAudit]

   ON  [dbo].[WorkflowExpertiseType]

   AFTER INSERT,DELETE,UPDATE

AS

BEGIN

	INSERT INTO WorkflowExpertiseTypeAudit

	SELECT * FROM INSERTED

	SET NOCOUNT ON;

END