﻿CREATE TABLE [dbo].[SubWorkOrderMaterialsAudit] (
    [SubWorkOrderMaterialsAuditId]  BIGINT          IDENTITY (1, 1) NOT NULL,
    [SubWorkOrderMaterialsId]       BIGINT          NOT NULL,
    [WorkOrderId]                   BIGINT          NOT NULL,
    [SubWorkOrderId]                BIGINT          NOT NULL,
    [SubWOPartNoId]                 BIGINT          NOT NULL,
    [ItemMasterId]                  BIGINT          NOT NULL,
    [TaskId]                        BIGINT          NOT NULL,
    [ConditionCodeId]               BIGINT          NOT NULL,
    [ItemClassificationId]          BIGINT          NOT NULL,
    [Quantity]                      INT             NOT NULL,
    [UnitOfMeasureId]               BIGINT          NOT NULL,
    [UnitCost]                      DECIMAL (20, 2) NOT NULL,
    [ExtendedCost]                  DECIMAL (20, 2) NOT NULL,
    [Price]                         DECIMAL (20, 2) NULL,
    [ExtendedPrice]                 DECIMAL (20, 2) NULL,
    [Memo]                          NVARCHAR (MAX)  NULL,
    [IsDeferred]                    BIT             NULL,
    [QuantityReserved]              INT             NULL,
    [QuantityIssued]                INT             NULL,
    [IssuedDate]                    DATETIME2 (7)   NULL,
    [ReservedDate]                  DATETIME2 (7)   NULL,
    [IsAltPart]                     BIT             NULL,
    [AltPartMasterPartId]           BIGINT          NULL,
    [IsFromWorkFlow]                BIT             NULL,
    [PartStatusId]                  INT             NULL,
    [IssuedById]                    BIGINT          NULL,
    [ReservedById]                  BIGINT          NULL,
    [IsEquPart]                     BIT             NULL,
    [ParentSubWorkOrderMaterialsId] BIGINT          NULL,
    [ItemMappingId]                 BIGINT          NULL,
    [TotalReserved]                 INT             NULL,
    [TotalIssued]                   INT             NULL,
    [ProvisionId]                   INT             NOT NULL,
    [MaterialMandatoriesId]         INT             NULL,
    [MasterCompanyId]               INT             NOT NULL,
    [CreatedBy]                     VARCHAR (256)   NOT NULL,
    [UpdatedBy]                     VARCHAR (256)   NOT NULL,
    [CreatedDate]                   DATETIME2 (7)   NOT NULL,
    [UpdatedDate]                   DATETIME2 (7)   NOT NULL,
    [IsActive]                      BIT             NOT NULL,
    [IsDeleted]                     BIT             NOT NULL,
    [QuantityTurnIn]                INT             NULL,
    [Condition]                     VARCHAR (50)    NULL,
    [UOM]                           VARCHAR (50)    NULL,
    [ItemClassification]            VARCHAR (100)   NULL,
    [Provision]                     VARCHAR (50)    NULL,
    [TaskName]                      VARCHAR (50)    NULL,
    [Site]                          VARCHAR (50)    NULL,
    [WareHouse]                     VARCHAR (50)    NULL,
    [Locations]                     VARCHAR (50)    NULL,
    [Shelf]                         VARCHAR (50)    NULL,
    [Bin]                           VARCHAR (50)    NULL,
    [TotalStocklineQtyReq]          INT             DEFAULT ((0)) NOT NULL,
    [POId]                          BIGINT          NULL,
    [PONum]                         VARCHAR (50)    NULL,
    [PONextDlvrDate]                DATETIME2 (7)   NULL,
    [QtyOnOrder]                    INT             NULL,
    [QtyOnBkOrder]                  INT             NULL,
    [QtyToTurnIn]                   INT             NULL,
    [Figure]                        NVARCHAR (50)   NULL,
    [Item]                          NVARCHAR (50)   NULL,
    CONSTRAINT [PK_SubWorkOrderMaterialsAudit] PRIMARY KEY CLUSTERED ([SubWorkOrderMaterialsAuditId] ASC)
);







