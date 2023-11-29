CREATE TABLE [dbo].[WorkflowMeasurementAudit] (
    [WorkflowMeasurementAuditId] BIGINT          IDENTITY (1, 1) NOT NULL,
    [WorkflowMeasurementId]      BIGINT          NOT NULL,
    [WorkflowId]                 BIGINT          NOT NULL,
    [Sequence]                   VARCHAR (50)    NULL,
    [Stage]                      VARCHAR (50)    NULL,
    [Min]                        DECIMAL (18, 2) NULL,
    [Max]                        DECIMAL (18, 2) NULL,
    [Expected]                   DECIMAL (18, 2) NULL,
    [DiagramURL]                 NVARCHAR (512)  NULL,
    [Memo]                       NVARCHAR (MAX)  NULL,
    [TaskId]                     BIGINT          NOT NULL,
    [MasterCompanyId]            INT             NOT NULL,
    [CreatedBy]                  VARCHAR (256)   NOT NULL,
    [UpdatedBy]                  VARCHAR (256)   NULL,
    [CreatedDate]                DATETIME2 (7)   NULL,
    [UpdatedDate]                DATETIME2 (7)   NULL,
    [IsActive]                   BIT             NULL,
    [IsDeleted]                  BIT             NULL,
    [ItemMasterId]               BIGINT          NOT NULL,
    [PartNumber]                 VARCHAR (256)   NULL,
    [Order]                      INT             NULL,
    [PartDescription]            VARCHAR (MAX)   NULL,
    [WFParentId]                 BIGINT          NULL,
    [IsVersionIncrease]          BIT             NULL,
    CONSTRAINT [PK_WorkflowMeasurementAudit] PRIMARY KEY CLUSTERED ([WorkflowMeasurementAuditId] ASC)
);



