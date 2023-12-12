CREATE TABLE [dbo].[WorkOrderAdditionalCommentsAudit] (
    [WorkOrderAdditionalCommentsAuditId] BIGINT         IDENTITY (1, 1) NOT NULL,
    [WorkOrderAdditionalCommentsId]      BIGINT         NOT NULL,
    [WorkOrderTeardownId]                BIGINT         NULL,
    [Memo]                               NVARCHAR (MAX) NULL,
    [ReasonId]                           BIGINT         NULL,
    [SubWorkOrderTeardownId]             BIGINT         NULL,
    [ReasonName]                         VARCHAR (200)  NULL,
    [CreatedBy]                          VARCHAR (256)  NOT NULL,
    [UpdatedBy]                          VARCHAR (256)  NOT NULL,
    [CreatedDate]                        DATETIME2 (7)  NOT NULL,
    [UpdatedDate]                        DATETIME2 (7)  NOT NULL,
    [IsActive]                           BIT            NOT NULL,
    [IsDeleted]                          BIT            NOT NULL,
    [MasterCompanyId]                    INT            NOT NULL,
    CONSTRAINT [PK_WorkOrderAdditionalCommentsAudit] PRIMARY KEY CLUSTERED ([WorkOrderAdditionalCommentsAuditId] ASC)
);

