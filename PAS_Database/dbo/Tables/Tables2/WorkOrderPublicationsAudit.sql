CREATE TABLE [dbo].[WorkOrderPublicationsAudit] (
    [WorkOrderPublicationAuditId] BIGINT        IDENTITY (1, 1) NOT NULL,
    [WorkOrderPublicationId]      BIGINT        NOT NULL,
    [WorkOrderId]                 BIGINT        NOT NULL,
    [WorkFlowWorkOrderId]         BIGINT        NOT NULL,
    [PublicationId]               BIGINT        NULL,
    [TaskId]                      BIGINT        NOT NULL,
    [MasterCompanyId]             INT           NOT NULL,
    [CreatedBy]                   VARCHAR (256) NOT NULL,
    [UpdatedBy]                   VARCHAR (256) NOT NULL,
    [CreatedDate]                 DATETIME2 (7) NOT NULL,
    [UpdatedDate]                 DATETIME2 (7) NOT NULL,
    [IsActive]                    BIT           NOT NULL,
    [IsDeleted]                   BIT           NOT NULL,
    [AircraftManufacturerId]      BIGINT        NULL,
    [ModelId]                     BIGINT        NULL,
    [IsFromWorkFlow]              BIT           NULL,
    CONSTRAINT [PK_WorkOrderPublicationsAudit] PRIMARY KEY CLUSTERED ([WorkOrderPublicationAuditId] ASC)
);

