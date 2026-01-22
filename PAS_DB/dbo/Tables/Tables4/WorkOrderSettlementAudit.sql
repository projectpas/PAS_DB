CREATE TABLE [dbo].[WorkOrderSettlementAudit] (
    [WorkOrderSettlementAuditId] BIGINT        IDENTITY (1, 1) NOT NULL,
    [WorkOrderSettlementId]      BIGINT        NOT NULL,
    [WorkOrderSettlementName]    VARCHAR (500) NULL,
    [MasterCompanyId]            INT           NOT NULL,
    [CreatedBy]                  VARCHAR (256) NOT NULL,
    [UpdatedBy]                  VARCHAR (256) NOT NULL,
    [CreatedDate]                DATETIME2 (7) NOT NULL,
    [UpdatedDate]                DATETIME2 (7) NOT NULL,
    [IsActive]                   BIT           NOT NULL,
    [IsDeleted]                  BIT           NOT NULL,
    CONSTRAINT [PK_WorkOrderSettlementAudit] PRIMARY KEY CLUSTERED ([WorkOrderSettlementAuditId] ASC)
);

