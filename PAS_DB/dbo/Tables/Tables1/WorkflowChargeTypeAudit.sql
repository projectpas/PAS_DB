CREATE TABLE [dbo].[WorkflowChargeTypeAudit] (
    [WorkflowChargeTypeAuditId] TINYINT       IDENTITY (1, 1) NOT NULL,
    [WorkflowChargeTypeId]      TINYINT       NOT NULL,
    [Description]               VARCHAR (100) NOT NULL,
    [MasterCompanyId]           INT           NOT NULL,
    [RecordCreateDate]          DATETIME2 (7) NOT NULL,
    [RecordModifiedDate]        DATETIME2 (7) NULL,
    [LastModifiedBy]            INT           NOT NULL,
    [CreatedBy]                 VARCHAR (256) NULL,
    [UpdatedBy]                 VARCHAR (256) NULL,
    [CreatedDate]               DATETIME2 (7) NOT NULL,
    [UpdatedDate]               DATETIME2 (7) NOT NULL,
    [IsActive]                  BIT           NULL,
    [IsDeleted]                 BIT           NOT NULL,
    CONSTRAINT [PK_WorkflowChargeTypeAudit] PRIMARY KEY CLUSTERED ([WorkflowChargeTypeAuditId] ASC)
);

