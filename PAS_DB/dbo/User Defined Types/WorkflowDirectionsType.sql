CREATE TYPE [dbo].[WorkflowDirectionsType] AS TABLE (
    [WorkflowDirectionId] BIGINT        NULL,
    [WorkflowId]          BIGINT        NULL,
    [Action]              VARCHAR (500) NULL,
    [Description]         VARCHAR (500) NULL,
    [Sequence]            VARCHAR (500) NULL,
    [Memo]                VARCHAR (MAX) NULL,
    [TaskId]              BIGINT        NULL,
    [Order]               INT           NULL,
    [IsDeleted]           BIT           NULL);

