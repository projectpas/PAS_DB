CREATE TABLE [dbo].[WorkflowExpertiseTypeAudit] (
    [WorkflowExpertiseTypeAuditId] SMALLINT      IDENTITY (1, 1) NOT NULL,
    [WorkflowExpertiseTypeId]      SMALLINT      NOT NULL,
    [Description]                  VARCHAR (100) NOT NULL,
    [MasterCompanyId]              INT           NOT NULL,
    [CreatedBy]                    VARCHAR (256) NULL,
    [UpdatedBy]                    VARCHAR (256) NULL,
    [CreatedDate]                  DATETIME2 (7) NOT NULL,
    [UpdatedDate]                  DATETIME2 (7) NOT NULL,
    [IsActive]                     BIT           NULL,
    CONSTRAINT [PK_WorkflowExpertiseTypeAudit] PRIMARY KEY CLUSTERED ([WorkflowExpertiseTypeAuditId] ASC)
);

