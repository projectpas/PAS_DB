CREATE TABLE [dbo].[StockLineHistoryDetails] (
    [StocklineHistoryId] BIGINT         IDENTITY (1, 1) NOT NULL,
    [StocklineId]        BIGINT         NOT NULL,
    [ItemMasterId_o]     BIGINT         NOT NULL,
    [ItemMasterId_m]     BIGINT         NULL,
    [StocklineNum]       VARCHAR (150)  NULL,
    [PurchaseOrderId]    BIGINT         NULL,
    [PONum]              VARCHAR (150)  NULL,
    [POCost]             DECIMAL (9, 2) NULL,
    [ConditionId]        INT            NOT NULL,
    [ConditionName]      VARCHAR (50)   NULL,
    [RepairOrderId]      BIGINT         NULL,
    [RONum]              VARCHAR (150)  NULL,
    [WorkscoprId]        INT            NULL,
    [WorkscopeName]      VARCHAR (50)   NULL,
    [RepairCost]         DECIMAL (9, 2) NULL,
    [VendorId]           BIGINT         NULL,
    [VendorName]         VARCHAR (150)  NULL,
    [RecdDate]           DATETIME       NULL,
    [Cost]               DECIMAL (9, 2) NULL,
    [LotNum]             VARCHAR (100)  NULL,
    [WONum]              VARCHAR (150)  NULL,
    [PreviousStockLine]  VARCHAR (150)  NULL,
    [extstocklineId]     BIGINT         NULL,
    [InventoryCost]      DECIMAL (9, 2) NULL,
    [AltEquiPartNumber]  VARCHAR (250)  NULL,
    [VendorRMAId]        BIGINT         NULL,
    [RMANumber]          VARCHAR (50)   NULL,
    CONSTRAINT [PK_StockLineHistoryDetails] PRIMARY KEY CLUSTERED ([StocklineHistoryId] ASC)
);



