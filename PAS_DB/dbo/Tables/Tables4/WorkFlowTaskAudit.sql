CREATE TABLE [dbo].[WorkFlowTaskAudit] (
    [WorkFlowTaskAuditId] BIGINT         IDENTITY (1, 1) NOT NULL,
    [WorkFlowTaskId]      BIGINT         NULL,
    [WorkFlowId]          BIGINT         NULL,
    [WorkFlowNumber]      VARCHAR (256)  NULL,
    [TaskId]              BIGINT         NULL,
    [TaskDescription]     VARCHAR (200)  NULL,
    [SequenceNumber]      VARCHAR (10)   NULL,
    [Descrepancy]         NVARCHAR (MAX) NULL,
    [Resolution]          NVARCHAR (MAX) NULL,
    [IsVersionIncrease]   BIT            NULL,
    [WFParentId]          BIGINT         NULL,
    [MasterCompanyId]     INT            NOT NULL,
    [CreatedBy]           VARCHAR (256)  NOT NULL,
    [CreatedDate]         DATETIME2 (7)  NOT NULL,
    [UpdatedBy]           VARCHAR (256)  NOT NULL,
    [UpdatedDate]         DATETIME2 (7)  NOT NULL,
    [IsActive]            BIT            NOT NULL,
    [IsDeleted]           BIT            NOT NULL,
    CONSTRAINT [PK_WorkFlowTaskAudit] PRIMARY KEY CLUSTERED ([WorkFlowTaskAuditId] ASC)
);

