﻿CREATE TABLE [dbo].[StocklineAudit] (
    [AuditStockLineId]                    BIGINT          IDENTITY (1, 1) NOT NULL,
    [StockLineId]                         BIGINT          NOT NULL,
    [PartNumber]                          VARCHAR (50)    NOT NULL,
    [StockLineNumber]                     VARCHAR (50)    NULL,
    [StocklineMatchKey]                   VARCHAR (100)   NULL,
    [ControlNumber]                       VARCHAR (50)    NULL,
    [ItemMasterId]                        BIGINT          NULL,
    [Quantity]                            INT             NULL,
    [ConditionId]                         BIGINT          NULL,
    [SerialNumber]                        VARCHAR (30)    NULL,
    [ShelfLife]                           BIT             NULL,
    [ShelfLifeExpirationDate]             DATETIME2 (7)   NULL,
    [WarehouseId]                         BIGINT          NULL,
    [LocationId]                          BIGINT          NULL,
    [ObtainFrom]                          BIGINT          NULL,
    [Owner]                               BIGINT          NULL,
    [TraceableTo]                         BIGINT          NULL,
    [ManufacturerId]                      BIGINT          NULL,
    [Manufacturer]                        VARCHAR (50)    NULL,
    [ManufacturerLotNumber]               VARCHAR (50)    NULL,
    [ManufacturingDate]                   DATETIME2 (7)   NULL,
    [ManufacturingBatchNumber]            VARCHAR (50)    NULL,
    [PartCertificationNumber]             VARCHAR (50)    NULL,
    [CertifiedBy]                         VARCHAR (100)   NULL,
    [CertifiedDate]                       DATETIME2 (7)   NULL,
    [TagDate]                             DATETIME2 (7)   NULL,
    [TagType]                             VARCHAR (500)   NULL,
    [CertifiedDueDate]                    DATETIME2 (7)   NULL,
    [CalibrationMemo]                     NVARCHAR (MAX)  NULL,
    [OrderDate]                           DATETIME2 (7)   NULL,
    [PurchaseOrderId]                     BIGINT          NULL,
    [PurchaseOrderUnitCost]               DECIMAL (18, 2) NULL,
    [InventoryUnitCost]                   DECIMAL (18, 2) NULL,
    [RepairOrderId]                       BIGINT          NULL,
    [RepairOrderUnitCost]                 DECIMAL (18, 2) NULL,
    [ReceivedDate]                        DATETIME2 (7)   NULL,
    [ReceiverNumber]                      VARCHAR (50)    NULL,
    [ReconciliationNumber]                VARCHAR (50)    NULL,
    [UnitSalesPrice]                      DECIMAL (18, 2) NULL,
    [CoreUnitCost]                        DECIMAL (18, 2) NULL,
    [GLAccountId]                         BIGINT          NULL,
    [AssetId]                             BIGINT          NULL,
    [IsHazardousMaterial]                 BIT             NULL,
    [IsPMA]                               BIT             NULL,
    [IsDER]                               BIT             NULL,
    [OEM]                                 BIT             NULL,
    [Memo]                                NVARCHAR (MAX)  NULL,
    [ManagementStructureId]               BIGINT          NULL,
    [LegalEntityId]                       BIGINT          NULL,
    [MasterCompanyId]                     INT             NOT NULL,
    [CreatedBy]                           VARCHAR (256)   NULL,
    [UpdatedBy]                           VARCHAR (256)   NULL,
    [CreatedDate]                         DATETIME2 (7)   NULL,
    [UpdatedDate]                         DATETIME2 (7)   NULL,
    [isSerialized]                        BIT             NULL,
    [ShelfId]                             BIGINT          NULL,
    [BinId]                               BIGINT          NULL,
    [SiteId]                              BIGINT          NULL,
    [ObtainFromType]                      INT             NULL,
    [OwnerType]                           INT             NULL,
    [TraceableToType]                     INT             NULL,
    [UnitCostAdjustmentReasonTypeId]      INT             NULL,
    [UnitSalePriceAdjustmentReasonTypeId] INT             NULL,
    [IdNumber]                            VARCHAR (100)   NULL,
    [QuantityToReceive]                   INT             NULL,
    [PurchaseOrderExtendedCost]           DECIMAL (18)    NOT NULL,
    [ManufacturingTrace]                  NVARCHAR (200)  NULL,
    [ExpirationDate]                      DATETIME2 (7)   NULL,
    [AircraftTailNumber]                  NVARCHAR (200)  NULL,
    [ShippingViaId]                       BIGINT          NULL,
    [EngineSerialNumber]                  NVARCHAR (200)  NULL,
    [QuantityRejected]                    INT             NOT NULL,
    [PurchaseOrderPartRecordId]           BIGINT          NULL,
    [ShippingAccount]                     NVARCHAR (200)  NULL,
    [ShippingReference]                   NVARCHAR (200)  NULL,
    [TimeLifeCyclesId]                    BIGINT          NULL,
    [TimeLifeDetailsNotProvided]          BIT             NOT NULL,
    [WorkOrderId]                         BIGINT          NULL,
    [WorkOrderMaterialsId]                BIGINT          NULL,
    [QuantityReserved]                    INT             NULL,
    [QuantityTurnIn]                      INT             NULL,
    [QuantityIssued]                      INT             NULL,
    [QuantityOnHand]                      INT             NULL,
    [QuantityAvailable]                   INT             NULL,
    [QuantityOnOrder]                     INT             NULL,
    [QtyReserved]                         INT             NULL,
    [QtyIssued]                           INT             NULL,
    [BlackListed]                         BIT             NOT NULL,
    [BlackListedReason]                   VARCHAR (MAX)   NULL,
    [Incident]                            BIT             NOT NULL,
    [IncidentReason]                      VARCHAR (MAX)   NULL,
    [Accident]                            BIT             NOT NULL,
    [AccidentReason]                      VARCHAR (MAX)   NULL,
    [RepairOrderPartRecordId]             BIGINT          NULL,
    [isActive]                            BIT             NOT NULL,
    [isDeleted]                           BIT             NOT NULL,
    [WorkOrderExtendedCost]               DECIMAL (20, 2) NULL,
    [RepairOrderExtendedCost]             DECIMAL (18, 2) NULL,
    [IsCustomerStock]                     BIT             NULL,
    [EntryDate]                           DATETIME        NULL,
    [LotCost]                             DECIMAL (18, 2) NULL,
    [NHAItemMasterId]                     BIGINT          NULL,
    [TLAItemMasterId]                     BIGINT          NULL,
    [ItemTypeId]                          INT             NULL,
    [AcquistionTypeId]                    BIGINT          NULL,
    [RequestorId]                         BIGINT          NULL,
    [LotNumber]                           VARCHAR (50)    NULL,
    [LotDescription]                      VARCHAR (250)   NULL,
    [TagNumber]                           VARCHAR (50)    NULL,
    [InspectionBy]                        BIGINT          NULL,
    [InspectionDate]                      DATETIME2 (7)   NULL,
    [VendorId]                            BIGINT          NULL,
    [IsParent]                            BIT             NULL,
    [ParentId]                            BIGINT          NULL,
    [IsSameDetailsForAllParts]            BIT             NULL,
    [WorkOrderPartNoId]                   BIGINT          NULL,
    [SubWorkOrderId]                      BIGINT          NULL,
    [SubWOPartNoId]                       BIGINT          NULL,
    [IsOemPNId]                           BIGINT          NULL,
    [PurchaseUnitOfMeasureId]             BIGINT          NOT NULL,
    [ObtainFromName]                      VARCHAR (50)    NULL,
    [OwnerName]                           VARCHAR (50)    NULL,
    [TraceableToName]                     VARCHAR (50)    NULL,
    [Level1]                              VARCHAR (100)   NULL,
    [Level2]                              VARCHAR (100)   NULL,
    [Level3]                              VARCHAR (100)   NULL,
    [Level4]                              VARCHAR (100)   NULL,
    [Condition]                           VARCHAR (100)   NULL,
    [GlAccountName]                       VARCHAR (100)   NULL,
    [Site]                                VARCHAR (100)   NULL,
    [Warehouse]                           VARCHAR (100)   NULL,
    [Location]                            VARCHAR (100)   NULL,
    [Shelf]                               VARCHAR (100)   NULL,
    [Bin]                                 VARCHAR (100)   NULL,
    [UnitOfMeasure]                       VARCHAR (100)   NULL,
    [WorkOrderNumber]                     VARCHAR (500)   NULL,
    [itemGroup]                           VARCHAR (256)   NULL,
    [TLAPartNumber]                       VARCHAR (100)   NULL,
    [NHAPartNumber]                       VARCHAR (100)   NULL,
    [TLAPartDescription]                  VARCHAR (100)   NULL,
    [NHAPartDescription]                  VARCHAR (100)   NULL,
    [itemType]                            VARCHAR (100)   NULL,
    [CustomerId]                          BIGINT          NULL,
    [CustomerName]                        VARCHAR (200)   NULL,
    [isCustomerstockType]                 BIT             NULL,
    [PNDescription]                       NVARCHAR (MAX)  NULL,
    [RevicedPNId]                         BIGINT          NULL,
    [RevicedPNNumber]                     NVARCHAR (50)   NULL,
    [OEMPNNumber]                         NVARCHAR (50)   NULL,
    [TaggedBy]                            BIGINT          NULL,
    [TaggedByName]                        NVARCHAR (50)   NULL,
    [UnitCost]                            DECIMAL (18, 2) NULL,
    [TaggedByType]                        INT             NULL,
    [TaggedByTypeName]                    VARCHAR (250)   NULL,
    [CertifiedById]                       BIGINT          NULL,
    [CertifiedTypeId]                     INT             NULL,
    [CertifiedType]                       VARCHAR (250)   NULL,
    [CertTypeId]                          VARCHAR (MAX)   NULL,
    [CertType]                            VARCHAR (MAX)   NULL,
    [TagTypeId]                           BIGINT          NULL,
    [IsFinishGood]                        BIT             DEFAULT ((0)) NULL,
    [IsTurnIn]                            BIT             NULL,
    [IsCustomerRMA]                       BIT             NULL,
    [RMADeatilsId]                        BIGINT          NULL,
    [DaysReceived]                        INT             NULL,
    [ManufacturingDays]                   INT             NULL,
    [TagDays]                             INT             NULL,
    [OpenDays]                            INT             NULL,
    [ExchangeSalesOrderId]                BIGINT          NULL,
    [RRQty]                               INT             DEFAULT ((0)) NOT NULL,
    [SubWorkOrderNumber]                  VARCHAR (50)    NULL,
    [IsManualEntry]                       BIT             NULL,
    [WorkOrderMaterialsKitId]             BIGINT          NULL,
    [LotId]                               BIGINT          NULL,
    [IsLotAssigned]                       BIT             NULL,
    [LOTQty]                              INT             NULL,
    [LOTQtyReserve]                       INT             NULL,
    [OriginalCost]                        DECIMAL (18, 2) NULL,
    [POOriginalCost]                      DECIMAL (18, 2) NULL,
    [ROOriginalCost]                      DECIMAL (18, 2) NULL,
    [VendorRMAId]                         BIGINT          NULL,
    [VendorRMADetailId]                   BIGINT          NULL,
    [LotMainStocklineId]                  BIGINT          NULL,
    [IsFromInitialPO]                     BIT             NULL,
    [LotSourceId]                         INT             NULL,
    [Adjustment]                          DECIMAL (18, 2) CONSTRAINT [DF_StocklineAudit_Adjustment] DEFAULT ((0)) NULL,
    [SalesOrderPartId]                    BIGINT          NULL,
    [FreightAdjustment]                   DECIMAL (18, 2) CONSTRAINT [DF_StocklineAudit_FreightAdjustment] DEFAULT ((0)) NULL,
    [TaxAdjustment]                       DECIMAL (18, 2) CONSTRAINT [DF_StocklineAudit_TaxAdjustment] DEFAULT ((0)) NULL,
    [IsStkTimeLife]                       BIT             NULL,
    [SalesPriceExpiryDate]                DATETIME2 (7)   NULL,
    CONSTRAINT [PK_StocklineAudit] PRIMARY KEY CLUSTERED ([AuditStockLineId] ASC)
);





