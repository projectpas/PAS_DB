CREATE TABLE [dbo].[WorkOrderReservedStockAudit] (
    [WOReservedStockAuditId] BIGINT        IDENTITY (1, 1) NOT NULL,
    [WOReservedStockId]      BIGINT        NOT NULL,
    [WorkOrderMaterialsId]   BIGINT        NOT NULL,
    [StockLIneId]            BIGINT        NOT NULL,
    [ConditionId]            BIGINT        NOT NULL,
    [ItemMasterId]           BIGINT        NOT NULL,
    [Quantity]               INT           NOT NULL,
    [AltPartMasterPartId]    BIGINT        NULL,
    [EquPartMasterPartId]    BIGINT        NULL,
    [IsAltPart]              BIT           NULL,
    [IsEquPart]              BIT           NULL,
    [ReservedById]           BIGINT        NOT NULL,
    [ReservedDate]           DATETIME2 (7) NOT NULL,
    [MasterCompanyId]        INT           NOT NULL,
    [CreatedBy]              VARCHAR (256) NOT NULL,
    [UpdatedBy]              VARCHAR (256) NOT NULL,
    [CreatedDate]            DATETIME2 (7) NOT NULL,
    [UpdatedDate]            DATETIME2 (7) NOT NULL,
    [IsActive]               BIT           NOT NULL,
    [IsDeleted]              BIT           NOT NULL,
    CONSTRAINT [PK_WorkOrderReservedStockAudit] PRIMARY KEY CLUSTERED ([WOReservedStockAuditId] ASC)
);

