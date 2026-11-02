CREATE TYPE [DBO].[FreightHistoryType] AS TABLE
(
    [TaskId]              BIGINT         NULL,
    [Amount]              DECIMAL(20,3)  NULL,
    [MasterCompanyId]     INT            NULL,
    [UpdatedBy]           VARCHAR(256)   NULL,
    [IsTransferredFromWO] BIT            NULL
);
