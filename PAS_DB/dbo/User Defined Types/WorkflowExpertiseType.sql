CREATE TYPE [dbo].[WorkflowExpertiseType] AS TABLE (
    [WorkflowExpertiseListId] BIGINT          NULL,
    [WorkflowId]              BIGINT          NULL,
    [ExpertiseTypeId]         TINYINT         NULL,
    [EstimatedHours]          DECIMAL (18, 2) NULL,
    [LaborDirectRate]         DECIMAL (18, 2) NULL,
    [DirectLaborRate]         DECIMAL (18, 2) NULL,
    [OverheadBurden]          DECIMAL (18, 2) NULL,
    [OverheadCost]            DECIMAL (18, 2) NULL,
    [StandardRate]            DECIMAL (18, 2) NULL,
    [LaborOverheadCost]       DECIMAL (18, 2) NULL,
    [TaskId]                  BIGINT          NULL,
    [IsDeleted]               BIT             NULL,
    [Order]                   INT             NULL);

