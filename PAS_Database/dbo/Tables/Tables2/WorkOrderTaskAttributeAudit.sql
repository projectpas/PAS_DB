CREATE TABLE [dbo].[WorkOrderTaskAttributeAudit] (
    [WorkOrderTaskAttributeAuditId] BIGINT        IDENTITY (1, 1) NOT NULL,
    [WorkOrderTaskAttributeId]      BIGINT        NOT NULL,
    [WorkOrderTaskId]               BIGINT        NOT NULL,
    [TaskAttributeId]               BIGINT        NOT NULL,
    [MasterCompanyId]               INT           NOT NULL,
    [CreatedBy]                     VARCHAR (256) NOT NULL,
    [UpdatedBy]                     VARCHAR (256) NOT NULL,
    [CreatedDate]                   DATETIME2 (7) NOT NULL,
    [UpdatedDate]                   DATETIME2 (7) NOT NULL,
    [IsActive]                      BIT           NOT NULL,
    [IsDeleted]                     BIT           NOT NULL,
    CONSTRAINT [PK_WorkOrderTaskAttributeAudit] PRIMARY KEY CLUSTERED ([WorkOrderTaskAttributeAuditId] ASC)
);

