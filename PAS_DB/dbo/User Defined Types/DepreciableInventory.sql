CREATE TYPE [dbo].[DepreciableInventory] AS TABLE (
    [AssetInventoryId]           BIGINT          NULL,
    [Qty]                        INT             NULL,
    [Amount]                     DECIMAL (18, 2) NULL,
    [ModuleName]                 VARCHAR (30)    NULL,
    [UpdateBy]                   VARCHAR (50)    NULL,
    [MasterCompanyId]            BIGINT          NULL,
    [StockType]                  VARCHAR (30)    NULL,
    [SelectedAccountingPeriodId] BIGINT          NULL);

