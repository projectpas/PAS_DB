﻿CREATE TABLE [dbo].[WorkOrderMaterialStockLineKitAudit] (
    [WorkOrderMaterialStockLineKitAuditId] BIGINT          IDENTITY (1, 1) NOT NULL,
    [WorkOrderMaterialStockLineKitId]      BIGINT          NOT NULL,
    [WorkOrderMaterialsKitId]              BIGINT          NOT NULL,
    [StockLineId]                          BIGINT          NOT NULL,
    [ItemMasterId]                         BIGINT          NOT NULL,
    [ConditionId]                          BIGINT          NOT NULL,
    [Quantity]                             INT             NULL,
    [QtyReserved]                          INT             NULL,
    [QtyIssued]                            INT             NULL,
    [MasterCompanyId]                      INT             NOT NULL,
    [CreatedBy]                            VARCHAR (256)   NOT NULL,
    [UpdatedBy]                            VARCHAR (256)   NOT NULL,
    [CreatedDate]                          DATETIME2 (7)   NOT NULL,
    [UpdatedDate]                          DATETIME2 (7)   NOT NULL,
    [IsActive]                             BIT             NOT NULL,
    [IsDeleted]                            BIT             NOT NULL,
    [AltPartMasterPartId]                  BIGINT          NULL,
    [EquPartMasterPartId]                  BIGINT          NULL,
    [IsAltPart]                            BIT             NULL,
    [IsEquPart]                            BIT             NULL,
    [UnitCost]                             DECIMAL (20, 2) NULL,
    [ExtendedCost]                         DECIMAL (20, 2) NULL,
    [UnitPrice]                            DECIMAL (20, 2) NULL,
    [ExtendedPrice]                        DECIMAL (20, 2) NULL,
    [ProvisionId]                          INT             NOT NULL,
    [RepairOrderId]                        BIGINT          NULL,
    [QuantityTurnIn]                       INT             NULL,
    [Figure]                               NVARCHAR (50)   NULL,
    [Item]                                 NVARCHAR (50)   NULL,
    [RepairOrderPartRecordId]              BIGINT          NULL,
    [ReferenceNumber]                      VARCHAR (100)   NULL,
    CONSTRAINT [PK_WorkOrderMaterialStockLineKitAudit] PRIMARY KEY CLUSTERED ([WorkOrderMaterialStockLineKitAuditId] ASC)
);



