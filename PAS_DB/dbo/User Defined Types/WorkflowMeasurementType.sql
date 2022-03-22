CREATE TYPE [dbo].[WorkflowMeasurementType] AS TABLE (
    [WorkflowMeasurementId] BIGINT          NULL,
    [WorkflowId]            BIGINT          NULL,
    [ItemMasterId]          BIGINT          NULL,
    [PartNumber]            VARCHAR (500)   NULL,
    [PartDescription]       VARCHAR (500)   NULL,
    [TaskId]                BIGINT          NULL,
    [Sequence]              VARCHAR (500)   NULL,
    [Stage]                 VARCHAR (500)   NULL,
    [Min]                   DECIMAL (18, 2) NULL,
    [Max]                   DECIMAL (18, 2) NULL,
    [Expected]              DECIMAL (18, 2) NULL,
    [DiagramURL]            VARCHAR (500)   NULL,
    [Memo]                  VARCHAR (500)   NULL,
    [Order]                 INT             NULL,
    [IsDeleted]             BIT             NULL);

