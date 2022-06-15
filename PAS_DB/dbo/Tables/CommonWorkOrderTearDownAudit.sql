CREATE TABLE [dbo].[CommonWorkOrderTearDownAudit] (
    [CommonWorkOrderTearDownAuditId] BIGINT         IDENTITY (1, 1) NOT NULL,
    [CommonWorkOrderTearDownId]      BIGINT         NULL,
    [CommonTeardownTypeId]           BIGINT         NULL,
    [WorkOrderId]                    BIGINT         NOT NULL,
    [WorkFlowWorkOrderId]            BIGINT         NOT NULL,
    [WOPartNoId]                     BIGINT         NOT NULL,
    [Memo]                           NVARCHAR (MAX) NULL,
    [ReasonId]                       BIGINT         NULL,
    [TechnicianId]                   BIGINT         NULL,
    [TechnicianDate]                 DATETIME2 (7)  NULL,
    [InspectorId]                    BIGINT         NULL,
    [InspectorDate]                  DATETIME2 (7)  NULL,
    [IsDocument]                     BIT            NOT NULL,
    [ReasonName]                     VARCHAR (200)  NULL,
    [InspectorName]                  VARCHAR (100)  NULL,
    [TechnicalName]                  VARCHAR (100)  NULL,
    [CreatedBy]                      VARCHAR (256)  NOT NULL,
    [UpdatedBy]                      VARCHAR (256)  NOT NULL,
    [CreatedDate]                    DATETIME2 (7)  NOT NULL,
    [UpdatedDate]                    DATETIME2 (7)  NOT NULL,
    [IsActive]                       BIT            NOT NULL,
    [IsDeleted]                      BIT            NOT NULL,
    [MasterCompanyId]                INT            NOT NULL,
    [IsSubWorkOrder]                 BIT            NULL,
    [SubWorkOrderId]                 BIGINT         NULL,
    [SubWOPartNoId]                  BIGINT         NULL,
    CONSTRAINT [PK_CommonWorkOrderTearDownAudit] PRIMARY KEY CLUSTERED ([CommonWorkOrderTearDownAuditId] ASC)
);





