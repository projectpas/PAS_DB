CREATE TABLE [dbo].[WorkOrderFinalTestAudit] (
    [WorkOrderFinalTestAuditId] BIGINT         IDENTITY (1, 1) NOT NULL,
    [WorkOrderFinalTestId]      BIGINT         NOT NULL,
    [WorkOrderTeardownId]       BIGINT         NULL,
    [Memo]                      NVARCHAR (MAX) NULL,
    [TechnicianId]              BIGINT         NULL,
    [TechnicianDate]            DATETIME2 (7)  NULL,
    [InspectorId]               BIGINT         NULL,
    [InspectorDate]             DATETIME2 (7)  NULL,
    [ReasonId]                  BIGINT         NULL,
    [SubWorkOrderTeardownId]    BIGINT         NULL,
    [ReasonName]                VARCHAR (200)  NULL,
    [InspectorName]             VARCHAR (100)  NULL,
    [TechnicalName]             VARCHAR (100)  NULL,
    [CreatedBy]                 VARCHAR (256)  NOT NULL,
    [UpdatedBy]                 VARCHAR (256)  NOT NULL,
    [CreatedDate]               DATETIME2 (7)  NOT NULL,
    [UpdatedDate]               DATETIME2 (7)  NOT NULL,
    [IsActive]                  BIT            NOT NULL,
    [IsDeleted]                 BIT            NOT NULL,
    [MasterCompanyId]           INT            NOT NULL,
    CONSTRAINT [PK_WorkOrderFinalTestAudit] PRIMARY KEY CLUSTERED ([WorkOrderFinalTestAuditId] ASC)
);

