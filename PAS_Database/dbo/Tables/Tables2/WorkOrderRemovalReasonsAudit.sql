CREATE TABLE [dbo].[WorkOrderRemovalReasonsAudit] (
    [WorkOrderRemovalReasonsAuditId] BIGINT         IDENTITY (1, 1) NOT NULL,
    [WorkOrderRemovalReasonsId]      BIGINT         NOT NULL,
    [WorkOrderTeardownId]            BIGINT         NULL,
    [Memo]                           NVARCHAR (MAX) NULL,
    [ReasonId]                       BIGINT         NULL,
    [SubWorkOrderTeardownId]         BIGINT         NULL,
    [ReasonName]                     VARCHAR (200)  NULL,
    [CreatedBy]                      VARCHAR (256)  NOT NULL,
    [UpdatedBy]                      VARCHAR (256)  NOT NULL,
    [CreatedDate]                    DATETIME2 (7)  NOT NULL,
    [UpdatedDate]                    DATETIME2 (7)  NOT NULL,
    [IsActive]                       BIT            NOT NULL,
    [IsDeleted]                      BIT            NOT NULL,
    [MasterCompanyId]                INT            NOT NULL,
    [IsDocument]                     BIT            NOT NULL,
    CONSTRAINT [PK_WorkOrderRemovalReasonsAudit] PRIMARY KEY CLUSTERED ([WorkOrderRemovalReasonsAuditId] ASC)
);

