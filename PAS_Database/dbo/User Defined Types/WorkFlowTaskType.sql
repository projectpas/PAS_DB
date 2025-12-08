CREATE TYPE [dbo].[WorkFlowTaskType] AS TABLE (
    [WorkFlowTaskId]    BIGINT         NULL,
    [WorkFlowId]        BIGINT         NULL,
    [WorkFlowNumber]    VARCHAR (256)  NULL,
    [TaskId]            BIGINT         NULL,
    [TaskDescription]   VARCHAR (200)  NULL,
    [SequenceNumber]    VARCHAR (10)   NULL,
    [Descrepancy]       NVARCHAR (MAX) NULL,
    [Resolution]        NVARCHAR (MAX) NULL,
    [IsVersionIncrease] BIT            NULL,
    [WFParentId]        BIGINT         NULL,
    [MasterCompanyId]   INT            NULL,
    [CreatedBy]         VARCHAR (256)  NULL,
    [CreatedDate]       DATETIME2 (7)  NULL,
    [UpdatedBy]         VARCHAR (256)  NULL,
    [UpdatedDate]       DATETIME2 (7)  NULL,
    [IsActive]          BIT            NULL,
    [IsDeleted]         BIT            NULL);





