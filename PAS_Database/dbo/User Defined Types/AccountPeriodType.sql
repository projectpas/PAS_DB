CREATE TYPE [dbo].[AccountPeriodType] AS TABLE (
    [ACCReferenceId]        BIGINT        NULL,
    [ACPReferenceId]        BIGINT        NULL,
    [ACRReferenceId]        BIGINT        NULL,
    [AssetReferenceId]      BIGINT        NULL,
    [InventoryReferenceId]  BIGINT        NULL,
    [IsACCStatusName]       BIT           NULL,
    [IsACPStatusName]       BIT           NULL,
    [IsACRStatusName]       BIT           NULL,
    [IsAssetStatusName]     BIT           NULL,
    [IsInventoryStatusName] BIT           NULL,
    [UpdatedBy]             VARCHAR (256) NULL,
    [PeriodName]            VARCHAR (100) NULL);

