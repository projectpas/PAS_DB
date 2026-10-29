CREATE TYPE [DBO].[MaterialHistoryType] AS TABLE
(
    [ItemMasterId]        BIGINT         NULL,
    [Quantity]            DECIMAL(18,6)  NULL,
    [MasterCompanyId]     INT            NULL,
    [UpdatedBy]           VARCHAR(256)   NULL,
    [IsTransferredFromWO] BIT            NULL
);
