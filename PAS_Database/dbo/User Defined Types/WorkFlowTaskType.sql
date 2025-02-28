CREATE TYPE [dbo].[WorkFlowTaskType] AS TABLE (
    [WorkFlowTaskId]  BIGINT        NULL,
    [WorkFlowId]      BIGINT        NULL,
    [WorkFlowNumber]  VARCHAR (256) NULL,
    [TaskId]          BIGINT        NULL,
    [TaskDescription] VARCHAR (200) NULL,
    [SequenceNumber]  INT           NULL,
    [MasterCompanyId] INT           NULL,
    [CreatedBy]       VARCHAR (256) NULL,
    [CreatedDate]     DATETIME2 (7) NULL,
    [UpdatedBy]       VARCHAR (256) NULL,
    [UpdatedDate]     DATETIME2 (7) NULL,
    [IsActive]        BIT           NULL,
    [IsDeleted]       BIT           NULL);

