CREATE TYPE [DBO].[ChargesHistoryType] AS TABLE
(
    [TaskId]              BIGINT         NULL,
    [Quantity]            DECIMAL(18,6)  NULL,
    [MasterCompanyId]     INT            NULL,
    [UpdatedBy]           VARCHAR(256)   NULL,
    [IsTransferredFromWO] BIT            NULL
);
