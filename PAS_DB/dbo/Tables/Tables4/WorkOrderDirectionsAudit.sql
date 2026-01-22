CREATE TABLE [dbo].[WorkOrderDirectionsAudit] (
    [WorkOrderDirectionAuditId] BIGINT         IDENTITY (1, 1) NOT NULL,
    [WorkOrderDirectionId]      BIGINT         NOT NULL,
    [WorkOrderId]               BIGINT         NOT NULL,
    [WorkFlowWorkOrderId]       BIGINT         NOT NULL,
    [Action]                    NVARCHAR (MAX) NULL,
    [DirectionName]             NVARCHAR (MAX) NULL,
    [Sequence]                  INT            NULL,
    [Memo]                      NVARCHAR (MAX) NULL,
    [TaskId]                    BIGINT         NOT NULL,
    [MasterCompanyId]           INT            NOT NULL,
    [CreatedBy]                 VARCHAR (256)  NOT NULL,
    [UpdatedBy]                 VARCHAR (256)  NOT NULL,
    [CreatedDate]               DATETIME2 (7)  NOT NULL,
    [UpdatedDate]               DATETIME2 (7)  NOT NULL,
    [IsActive]                  BIT            NOT NULL,
    [IsDeleted]                 BIT            NOT NULL,
    [IsFromWorkFlow]            BIT            NULL,
    CONSTRAINT [PK_WorkOrderDirectionsAudit] PRIMARY KEY CLUSTERED ([WorkOrderDirectionAuditId] ASC)
);

