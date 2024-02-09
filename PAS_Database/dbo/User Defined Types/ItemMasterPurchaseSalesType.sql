CREATE TYPE [dbo].[ItemMasterPurchaseSalesType] AS TABLE (
    [ItemMasterId]      BIGINT          NULL,
    [ConditionId]       BIGINT          NULL,
    [MasterCompanyId]   BIGINT          NULL,
    [UnitSalePrice]     DECIMAL (18, 2) NULL,
    [UnitPurchasePrice] DECIMAL (18, 2) NULL);

