CREATE TYPE [dbo].[WorkflowExclusionsType] AS TABLE (
    [WorkflowExclusionId]     BIGINT          NULL,
    [WorkflowId]              BIGINT          NULL,
    [ItemMasterId]            BIGINT          NULL,
    [UnitCost]                DECIMAL (18, 6) NULL,
    [Quantity]                DECIMAL (18, 6) NULL,
    [ExtendedCost]            DECIMAL (18, 6) NULL,
    [EstimtPercentOccurrance] TINYINT         NULL,
    [Memo]                    VARCHAR (MAX)   NULL,
    [PartNumber]              VARCHAR (500)   NULL,
    [PartDescription]         VARCHAR (500)   NULL,
    [TaskId]                  BIGINT          NULL,
    [Order]                   INT             NULL,
    [ConditionId]             BIGINT          NULL,
    [ItemClassificationId]    BIGINT          NULL,
    [IsDeleted]               BIT             NULL);

