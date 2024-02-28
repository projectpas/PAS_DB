CREATE TYPE [dbo].[KITPartType] AS TABLE (
    [KitItemMasterMappingId] BIGINT          NULL,
    [KitId]                  BIGINT          NULL,
    [ItemMasterId]           BIGINT          NULL,
    [ManufacturerId]         BIGINT          NULL,
    [ConditionId]            BIGINT          NULL,
    [UOMId]                  BIGINT          NULL,
    [Qty]                    INT             NULL,
    [UnitCost]               DECIMAL (18, 2) NULL,
    [StocklineUnitCost]      DECIMAL (18, 2) NULL,
    [MasterCompanyId]        INT             NULL,
    [CreatedBy]              VARCHAR (256)   NULL,
    [UpdatedBy]              VARCHAR (256)   NULL,
    [CreatedDate]            DATETIME2 (7)   NULL,
    [UpdatedDate]            DATETIME2 (7)   NULL,
    [IsActive]               BIT             NULL,
    [IsDeleted]              BIT             NULL,
    [PartNumber]             VARCHAR (250)   NULL,
    [PartDescription]        VARCHAR (MAX)   NULL,
    [Manufacturer]           VARCHAR (100)   NULL,
    [Condition]              VARCHAR (100)   NULL,
    [UOM]                    VARCHAR (100)   NULL,
    [IsEditable]             BIT             NULL,
    [IsNewItem]              BIT             NULL);



