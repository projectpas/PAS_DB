CREATE TYPE [dbo].[WorkflowExclusionsType] AS TABLE (
    [WorkflowExclusionId]     BIGINT          NULL,
    [WorkflowId]              BIGINT          NULL,
    [ItemMasterId]            BIGINT          NULL,
    [UnitCost]                DECIMAL (18, 2) NULL,
    [Quantity]                INT             NULL,
    [ExtendedCost]            DECIMAL (18, 2) NULL,
    [EstimtPercentOccurrance] TINYINT         NULL,
    [Memo]                    VARCHAR (MAX)   NULL,
    [PartNumber]              VARCHAR (500)   NULL,
    [PartDescription]         VARCHAR (500)   NULL,
    [TaskId]                  BIGINT          NULL,
    [Order]                   INT             NULL,
    [ConditionId]             BIGINT          NULL,
    [ItemClassificationId]    BIGINT          NULL,
    [IsDeleted]               BIT             NULL);

