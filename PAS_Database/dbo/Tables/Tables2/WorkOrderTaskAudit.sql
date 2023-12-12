CREATE TABLE [dbo].[WorkOrderTaskAudit] (
    [WorkOrderTaskAuditId] BIGINT        IDENTITY (1, 1) NOT NULL,
    [WorkOrderTaskId]      BIGINT        NOT NULL,
    [WorkOrderId]          BIGINT        NOT NULL,
    [WorkFlowWorkOrderId]  BIGINT        NOT NULL,
    [TaskId]               BIGINT        NOT NULL,
    [MasterCompanyId]      INT           NOT NULL,
    [CreatedBy]            VARCHAR (256) NOT NULL,
    [UpdatedBy]            VARCHAR (256) NOT NULL,
    [CreatedDate]          DATETIME2 (7) NOT NULL,
    [UpdatedDate]          DATETIME2 (7) NOT NULL,
    [IsActive]             BIT           NOT NULL,
    [IsDeleted]            BIT           NOT NULL,
    CONSTRAINT [PK_WorkOrderTaskAudit] PRIMARY KEY CLUSTERED ([WorkOrderTaskAuditId] ASC)
);

