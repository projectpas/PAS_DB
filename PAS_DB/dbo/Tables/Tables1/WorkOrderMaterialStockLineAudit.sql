CREATE TABLE [dbo].[WorkOrderMaterialStockLineAudit] (
    [WOMStockLineAuditId]  BIGINT          IDENTITY (1, 1) NOT NULL,
    [WOMStockLineId]       BIGINT          NOT NULL,
    [WorkOrderMaterialsId] BIGINT          NOT NULL,
    [StockLineId]          BIGINT          NOT NULL,
    [ItemMasterId]         BIGINT          NOT NULL,
    [ConditionId]          BIGINT          NOT NULL,
    [Quantity]             INT             NULL,
    [QtyReserved]          INT             NULL,
    [QtyIssued]            INT             NULL,
    [MasterCompanyId]      INT             NOT NULL,
    [CreatedBy]            VARCHAR (256)   NOT NULL,
    [UpdatedBy]            VARCHAR (256)   NOT NULL,
    [CreatedDate]          DATETIME2 (7)   NOT NULL,
    [UpdatedDate]          DATETIME2 (7)   NOT NULL,
    [IsActive]             BIT             NOT NULL,
    [IsDeleted]            BIT             NOT NULL,
    [AltPartMasterPartId]  BIGINT          NULL,
    [EquPartMasterPartId]  BIGINT          NULL,
    [IsAltPart]            BIT             NULL,
    [IsEquPart]            BIT             NULL,
    [UnitCost]             DECIMAL (20, 2) NULL,
    [ExtendedCost]         DECIMAL (20, 2) NULL,
    [UnitPrice]            DECIMAL (20, 2) NULL,
    [ExtendedPrice]        DECIMAL (20, 2) NULL,
    [ProvisionId]          INT             NOT NULL,
    [RepairOrderId]        BIGINT          NULL,
    [QuantityTurnIn]       INT             DEFAULT ((0)) NULL,
    CONSTRAINT [PK_WorkOrderMaterialStockLineAudit] PRIMARY KEY CLUSTERED ([WOMStockLineAuditId] ASC)
);



