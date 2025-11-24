CREATE TABLE [dbo].[WorkOrderTaskAudit] (
    [WorkOrderTaskAuditId]  BIGINT          IDENTITY (1, 1) NOT NULL,
    [WorkOrderTaskId]       BIGINT          NOT NULL,
    [WorkOrderId]           BIGINT          NOT NULL,
    [WorkFlowWorkOrderId]   BIGINT          NOT NULL,
    [TaskId]                BIGINT          NOT NULL,
    [MasterCompanyId]       INT             NOT NULL,
    [CreatedBy]             VARCHAR (256)   NOT NULL,
    [UpdatedBy]             VARCHAR (256)   NOT NULL,
    [CreatedDate]           DATETIME2 (7)   NOT NULL,
    [UpdatedDate]           DATETIME2 (7)   NOT NULL,
    [IsActive]              BIT             NOT NULL,
    [IsDeleted]             BIT             NOT NULL,
    [WorkOrderPartNumberId] BIGINT          NOT NULL,
    [SequenceNumber]        DECIMAL (10, 3) NULL,
    [OpenDate]              DATETIME2 (7)   NULL,
    [OpenBy]                VARCHAR (100)   NULL,
    [IsIncludeInPrint]      BIT             NULL,
    [HasInstruction]        BIT             NULL,
    [TaskName]              VARCHAR (200)   NULL,
    [IsFromWorkFlow]        BIT             NULL,
    CONSTRAINT [PK_WorkOrderTaskAudit] PRIMARY KEY CLUSTERED ([WorkOrderTaskAuditId] ASC)
);







