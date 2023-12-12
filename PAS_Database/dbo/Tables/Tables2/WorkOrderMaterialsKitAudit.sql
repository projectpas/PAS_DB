﻿CREATE TABLE [dbo].[WorkOrderMaterialsKitAudit] (
    [WorkOrderMaterialsKitAuditId]   BIGINT          IDENTITY (1, 1) NOT NULL,
    [WorkOrderMaterialsKitId]        BIGINT          NOT NULL,
    [WorkOrderMaterialsKitMappingId] BIGINT          NOT NULL,
    [WorkOrderId]                    BIGINT          NOT NULL,
    [WorkFlowWorkOrderId]            BIGINT          NOT NULL,
    [ItemMasterId]                   BIGINT          NOT NULL,
    [MasterCompanyId]                INT             NOT NULL,
    [CreatedBy]                      VARCHAR (256)   NOT NULL,
    [UpdatedBy]                      VARCHAR (256)   NOT NULL,
    [CreatedDate]                    DATETIME2 (7)   NOT NULL,
    [UpdatedDate]                    DATETIME2 (7)   NOT NULL,
    [IsActive]                       BIT             NOT NULL,
    [IsDeleted]                      BIT             NOT NULL,
    [TaskId]                         BIGINT          NOT NULL,
    [ConditionCodeId]                BIGINT          NOT NULL,
    [ItemClassificationId]           BIGINT          NOT NULL,
    [Quantity]                       INT             NOT NULL,
    [UnitOfMeasureId]                BIGINT          NOT NULL,
    [UnitCost]                       DECIMAL (20, 2) NOT NULL,
    [ExtendedCost]                   DECIMAL (20, 2) NOT NULL,
    [Memo]                           NVARCHAR (MAX)  NULL,
    [IsDeferred]                     BIT             NULL,
    [QuantityReserved]               INT             NULL,
    [QuantityIssued]                 INT             NULL,
    [IssuedDate]                     DATETIME2 (7)   NULL,
    [ReservedDate]                   DATETIME2 (7)   NULL,
    [IsAltPart]                      BIT             NULL,
    [AltPartMasterPartId]            BIGINT          NULL,
    [IsFromWorkFlow]                 BIT             NULL,
    [PartStatusId]                   INT             NULL,
    [UnReservedQty]                  INT             NULL,
    [UnIssuedQty]                    INT             NULL,
    [IssuedById]                     BIGINT          NULL,
    [ReservedById]                   BIGINT          NULL,
    [IsEquPart]                      BIT             NULL,
    [ParentWorkOrderMaterialsId]     BIGINT          NULL,
    [ItemMappingId]                  BIGINT          NULL,
    [TotalReserved]                  INT             NULL,
    [TotalIssued]                    INT             NULL,
    [TotalUnReserved]                INT             NULL,
    [TotalUnIssued]                  INT             NULL,
    [ProvisionId]                    INT             NOT NULL,
    [MaterialMandatoriesId]          INT             NULL,
    [WOPartNoId]                     BIGINT          NOT NULL,
    [TotalStocklineQtyReq]           INT             NOT NULL,
    [QtyOnOrder]                     INT             NULL,
    [QtyOnBkOrder]                   INT             NULL,
    [POId]                           BIGINT          NULL,
    [PONum]                          VARCHAR (100)   NULL,
    [PONextDlvrDate]                 DATETIME        NULL,
    [QtyToTurnIn]                    INT             NULL,
    [Figure]                         NVARCHAR (50)   NULL,
    [Item]                           NVARCHAR (50)   NULL,
    CONSTRAINT [PK_WorkOrderMaterialsKitAudit] PRIMARY KEY CLUSTERED ([WorkOrderMaterialsKitAuditId] ASC)
);

