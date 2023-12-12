CREATE TABLE [dbo].[WorkOrderPreliinaryReviewAudit] (
    [WorkOrderPreliinaryReviewAuditId] BIGINT         IDENTITY (1, 1) NOT NULL,
    [WorkOrderPreliinaryReviewId]      BIGINT         NOT NULL,
    [WorkOrderTeardownId]              BIGINT         NULL,
    [Memo]                             NVARCHAR (MAX) NULL,
    [InspectorId]                      BIGINT         NULL,
    [InspectorDate]                    DATETIME2 (7)  NULL,
    [ReasonId]                         BIGINT         NULL,
    [SubWorkOrderTeardownId]           BIGINT         NULL,
    [ReasonName]                       VARCHAR (200)  NULL,
    [InspectorName]                    VARCHAR (100)  NULL,
    [CreatedBy]                        VARCHAR (256)  NOT NULL,
    [UpdatedBy]                        VARCHAR (256)  NOT NULL,
    [CreatedDate]                      DATETIME2 (7)  NOT NULL,
    [UpdatedDate]                      DATETIME2 (7)  NOT NULL,
    [IsActive]                         BIT            NOT NULL,
    [IsDeleted]                        BIT            NOT NULL,
    [MasterCompanyId]                  INT            NOT NULL,
    [IsDocument]                       BIT            NOT NULL,
    CONSTRAINT [PK_WorkOrderPreliinaryReviewAudit] PRIMARY KEY CLUSTERED ([WorkOrderPreliinaryReviewAuditId] ASC)
);

