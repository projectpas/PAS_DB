CREATE TYPE [dbo].[LeaseStocklineServiceComponentType] AS TABLE (
    [LeaseStocklineServiceComponentId] BIGINT          NULL,
    [ComponentName]                    NVARCHAR (200)  NULL,
    [GLAccountId]                      BIGINT          NULL,
    [StartDate]                        DATETIME        NULL,
    [EndDate]                          DATETIME        NULL,
    [Amount]                           DECIMAL (18, 6) NULL,
    [Per]                              NVARCHAR (50)   NULL,
    [IsDeleted]                        BIT             NULL);
