CREATE TYPE [DBO].[LaborHistoryType] AS TABLE
(
    [TaskId]              BIGINT         NULL,
    [Hours]               DECIMAL(10,2)  NULL,
    [MasterCompanyId]     INT            NULL,
    [UpdatedBy]           VARCHAR(256)   NULL,
    [IsTransferredFromWO] BIT            NULL
);
