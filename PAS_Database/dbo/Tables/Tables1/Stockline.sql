﻿CREATE TABLE [dbo].[Stockline] (
    [StockLineId]                         BIGINT          IDENTITY (1, 1) NOT NULL,
    [PartNumber]                          VARCHAR (50)    NOT NULL,
    [StockLineNumber]                     VARCHAR (50)    NULL,
    [StocklineMatchKey]                   VARCHAR (100)   NULL,
    [ControlNumber]                       VARCHAR (50)    NULL,
    [ItemMasterId]                        BIGINT          NULL,
    [Quantity]                            INT             NULL,
    [ConditionId]                         BIGINT          NOT NULL,
    [SerialNumber]                        VARCHAR (30)    NULL,
    [ShelfLife]                           BIT             CONSTRAINT [DF_Stockline_ShelfLife] DEFAULT ((0)) NULL,
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
    [PurchaseOrderUnitCost]               DECIMAL (18, 2) CONSTRAINT [DF_Stockline_PurchaseOrderUnitCost] DEFAULT ((0)) NULL,
    [InventoryUnitCost]                   DECIMAL (18, 2) CONSTRAINT [DF_Stockline_InventoryUnitCost] DEFAULT ((0)) NULL,
    [RepairOrderId]                       BIGINT          NULL,
    [RepairOrderUnitCost]                 DECIMAL (18, 2) CONSTRAINT [DF_Stockline_RepairOrderUnitCost] DEFAULT ((0)) NULL,
    [ReceivedDate]                        DATETIME2 (7)   NULL,
    [ReceiverNumber]                      VARCHAR (50)    NULL,
    [ReconciliationNumber]                VARCHAR (50)    NULL,
    [UnitSalesPrice]                      DECIMAL (18, 2) CONSTRAINT [DF_Stockline_UnitSalesPrice] DEFAULT ((0)) NULL,
    [CoreUnitCost]                        DECIMAL (18, 2) CONSTRAINT [DF_Stockline_CoreUnitCost] DEFAULT ((0)) NULL,
    [GLAccountId]                         BIGINT          NULL,
    [AssetId]                             BIGINT          NULL,
    [IsHazardousMaterial]                 BIT             CONSTRAINT [DF_Stockline_IsHazardousMaterial] DEFAULT ((0)) NULL,
    [IsPMA]                               BIT             CONSTRAINT [Stockline_DC_IsPMA] DEFAULT ((0)) NOT NULL,
    [IsDER]                               BIT             CONSTRAINT [Stockline_DC_IsDER] DEFAULT ((0)) NOT NULL,
    [OEM]                                 BIT             CONSTRAINT [Stockline_DC_OEM] DEFAULT ((0)) NOT NULL,
    [Memo]                                NVARCHAR (MAX)  NULL,
    [ManagementStructureId]               BIGINT          NOT NULL,
    [LegalEntityId]                       BIGINT          NULL,
    [MasterCompanyId]                     INT             NOT NULL,
    [CreatedBy]                           VARCHAR (256)   NULL,
    [UpdatedBy]                           VARCHAR (256)   NULL,
    [CreatedDate]                         DATETIME2 (7)   CONSTRAINT [DF_Stockline_CreatedDate] DEFAULT (getdate()) NULL,
    [UpdatedDate]                         DATETIME2 (7)   CONSTRAINT [DF_Stockline_UpdatedDate] DEFAULT (getdate()) NULL,
    [isSerialized]                        BIT             CONSTRAINT [DF_Stockline_isSerialized] DEFAULT ((0)) NULL,
    [ShelfId]                             BIGINT          NULL,
    [BinId]                               BIGINT          NULL,
    [SiteId]                              BIGINT          NOT NULL,
    [ObtainFromType]                      INT             NULL,
    [OwnerType]                           INT             NULL,
    [TraceableToType]                     INT             NULL,
    [UnitCostAdjustmentReasonTypeId]      INT             NULL,
    [UnitSalePriceAdjustmentReasonTypeId] INT             NULL,
    [IdNumber]                            VARCHAR (100)   NULL,
    [QuantityToReceive]                   INT             NULL,
    [PurchaseOrderExtendedCost]           DECIMAL (18)    CONSTRAINT [DF__Stockline__Purch__53E4BFD3] DEFAULT ((0)) NOT NULL,
    [ManufacturingTrace]                  NVARCHAR (200)  NULL,
    [ExpirationDate]                      DATETIME2 (7)   NULL,
    [AircraftTailNumber]                  NVARCHAR (200)  NULL,
    [ShippingViaId]                       BIGINT          NULL,
    [EngineSerialNumber]                  NVARCHAR (200)  NULL,
    [QuantityRejected]                    INT             CONSTRAINT [DF__Stockline__Quant__14BE5EF7] DEFAULT ((0)) NOT NULL,
    [PurchaseOrderPartRecordId]           BIGINT          NULL,
    [ShippingAccount]                     NVARCHAR (200)  NULL,
    [ShippingReference]                   NVARCHAR (200)  NULL,
    [TimeLifeCyclesId]                    BIGINT          NULL,
    [TimeLifeDetailsNotProvided]          BIT             CONSTRAINT [DF__Stockline__TimeL__69BFBDB0] DEFAULT ((0)) NOT NULL,
    [WorkOrderId]                         BIGINT          NULL,
    [WorkOrderMaterialsId]                BIGINT          NULL,
    [QuantityReserved]                    INT             NULL,
    [QuantityTurnIn]                      INT             NULL,
    [QuantityIssued]                      INT             NULL,
    [QuantityOnHand]                      INT             CONSTRAINT [DF_Stockline_QuantityOnHand] DEFAULT ((0)) NOT NULL,
    [QuantityAvailable]                   INT             CONSTRAINT [DF_Stockline_QuantityAvailable] DEFAULT ((0)) NULL,
    [QuantityOnOrder]                     INT             NULL,
    [QtyReserved]                         INT             CONSTRAINT [DF_Stockline_QtyReserved] DEFAULT ((0)) NULL,
    [QtyIssued]                           INT             CONSTRAINT [DF_Stockline_QtyIssued] DEFAULT ((0)) NULL,
    [BlackListed]                         BIT             CONSTRAINT [DF__Stockline__Black__11007AA7] DEFAULT ((0)) NOT NULL,
    [BlackListedReason]                   VARCHAR (MAX)   NULL,
    [Incident]                            BIT             CONSTRAINT [DF__Stockline__Incid__11F49EE0] DEFAULT ((0)) NOT NULL,
    [IncidentReason]                      VARCHAR (MAX)   NULL,
    [Accident]                            BIT             CONSTRAINT [DF__Stockline__Accid__12E8C319] DEFAULT ((0)) NOT NULL,
    [AccidentReason]                      VARCHAR (MAX)   NULL,
    [RepairOrderPartRecordId]             BIGINT          NULL,
    [isActive]                            BIT             CONSTRAINT [DF__Stockline__isAct__13DCE752] DEFAULT ((1)) NOT NULL,
    [isDeleted]                           BIT             CONSTRAINT [DF__Stockline__isDel__14D10B8B] DEFAULT ((0)) NOT NULL,
    [WorkOrderExtendedCost]               DECIMAL (20, 2) NULL,
    [RepairOrderExtendedCost]             DECIMAL (18, 2) NULL,
    [IsCustomerStock]                     BIT             CONSTRAINT [SL_DC_IsCustomerStock] DEFAULT ((0)) NULL,
    [EntryDate]                           DATETIME        CONSTRAINT [DF_Stockline_EntryDate] DEFAULT (getdate()) NULL,
    [LotCost]                             DECIMAL (18, 2) CONSTRAINT [DF_Stockline_LotCost] DEFAULT ((0)) NULL,
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
    [IsParent]                            BIT             CONSTRAINT [DF_Stockline_IsParent] DEFAULT ((1)) NULL,
    [ParentId]                            BIGINT          NULL,
    [IsSameDetailsForAllParts]            BIT             CONSTRAINT [DF_Stockline_IsSameDetailsForAllParts] DEFAULT ((0)) NULL,
    [WorkOrderPartNoId]                   BIGINT          NULL,
    [SubWorkOrderId]                      BIGINT          NULL,
    [SubWOPartNoId]                       BIGINT          NULL,
    [IsOemPNId]                           BIGINT          NULL,
    [PurchaseUnitOfMeasureId]             BIGINT          NOT NULL,
    [ObtainFromName]                      VARCHAR (100)   NULL,
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
    [TLAPartDescription]                  NVARCHAR (MAX)  NULL,
    [NHAPartDescription]                  NVARCHAR (MAX)  NULL,
    [itemType]                            VARCHAR (100)   NULL,
    [CustomerId]                          BIGINT          NULL,
    [CustomerName]                        VARCHAR (200)   NULL,
    [isCustomerstockType]                 BIT             CONSTRAINT [Stockline_DC_isCustomerstockType] DEFAULT ((0)) NULL,
    [PNDescription]                       NVARCHAR (MAX)  NULL,
    [RevicedPNId]                         BIGINT          NULL,
    [RevicedPNNumber]                     NVARCHAR (50)   NULL,
    [OEMPNNumber]                         NVARCHAR (50)   NULL,
    [TaggedBy]                            BIGINT          NULL,
    [TaggedByName]                        NVARCHAR (50)   NULL,
    [UnitCost]                            DECIMAL (18, 2) CONSTRAINT [Stockline_DC_UnitCost] DEFAULT ((0)) NULL,
    [TaggedByType]                        INT             NULL,
    [TaggedByTypeName]                    VARCHAR (250)   NULL,
    [CertifiedById]                       BIGINT          NULL,
    [CertifiedTypeId]                     INT             NULL,
    [CertifiedType]                       VARCHAR (250)   NULL,
    [CertTypeId]                          VARCHAR (MAX)   NULL,
    [CertType]                            VARCHAR (MAX)   NULL,
    [TagTypeId]                           BIGINT          NULL,
    [IsFinishGood]                        BIT             CONSTRAINT [DF__tmp_ms_xx__IsFin__7B35F923] DEFAULT ((0)) NULL,
    [IsTurnIn]                            BIT             CONSTRAINT [Stockline_DC_IsTurnIn] DEFAULT ((0)) NULL,
    [IsCustomerRMA]                       BIT             NULL,
    [RMADeatilsId]                        BIGINT          NULL,
    [DaysReceived]                        INT             NULL,
    [ManufacturingDays]                   INT             NULL,
    [TagDays]                             INT             NULL,
    [OpenDays]                            INT             NULL,
    [ExchangeSalesOrderId]                BIGINT          NULL,
    [RRQty]                               INT             CONSTRAINT [DF__tmp_ms_xx__RRQty__7D1E4195] DEFAULT ((0)) NOT NULL,
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
    [Adjustment]                          DECIMAL (18, 2) CONSTRAINT [DF_Stockline_Adjustment] DEFAULT ((0)) NULL,
    [SalesOrderPartId]                    BIGINT          NULL,
    [FreightAdjustment]                   DECIMAL (18, 2) CONSTRAINT [DF_Stockline_FreightAdjustment] DEFAULT ((0)) NULL,
    [TaxAdjustment]                       DECIMAL (18, 2) CONSTRAINT [DF_Stockline_TaxAdjustment] DEFAULT ((0)) NULL,
    [IsStkTimeLife]                       BIT             NULL,
    [SalesPriceExpiryDate]                DATETIME2 (7)   NULL,
    [SubWorkOrderMaterialsId]             BIGINT          NULL,
    [SubWorkOrderMaterialsKitId]          BIGINT          NULL,
    [EvidenceId]                          INT             NULL,
    [IsGenerateReleaseForm]               BIT             CONSTRAINT [DF__tmp_ms_xx__IsGen__46CC5285] DEFAULT ((0)) NULL,
    [ExistingCustomerId]                  BIGINT          NULL,
    [RepairOrderNumber]                   VARCHAR (100)   NULL,
    [ExistingCustomer]                    VARCHAR (200)   NULL,
    [QuickBooksReferenceId]               VARCHAR (200)   NULL,
    [IsUpdated]                           BIT             NULL,
    [LastSyncDate]                        DATETIME2 (7)   NULL,
    CONSTRAINT [PK_Stockline] PRIMARY KEY CLUSTERED ([StockLineId] ASC),
    CONSTRAINT [FK_StockLine_AcquistionType] FOREIGN KEY ([AcquistionTypeId]) REFERENCES [dbo].[AssetAcquisitionType] ([AssetAcquisitionTypeId]),
    CONSTRAINT [FK_StockLine_Bin] FOREIGN KEY ([BinId]) REFERENCES [dbo].[Bin] ([BinId]),
    CONSTRAINT [FK_StockLine_Condition] FOREIGN KEY ([ConditionId]) REFERENCES [dbo].[Condition] ([ConditionId]),
    CONSTRAINT [FK_StockLine_Employee] FOREIGN KEY ([RequestorId]) REFERENCES [dbo].[Employee] ([EmployeeId]),
    CONSTRAINT [FK_StockLine_InspectionEmployee] FOREIGN KEY ([InspectionBy]) REFERENCES [dbo].[Employee] ([EmployeeId]),
    CONSTRAINT [FK_StockLine_ItemMaster] FOREIGN KEY ([ItemMasterId]) REFERENCES [dbo].[ItemMaster] ([ItemMasterId]),
    CONSTRAINT [FK_StockLine_Location] FOREIGN KEY ([LocationId]) REFERENCES [dbo].[Location] ([LocationId]),
    CONSTRAINT [FK_StockLine_Manfacturer] FOREIGN KEY ([ManufacturerId]) REFERENCES [dbo].[Manufacturer] ([ManufacturerId]),
    CONSTRAINT [FK_StockLine_Module] FOREIGN KEY ([ObtainFromType]) REFERENCES [dbo].[Module] ([ModuleId]),
    CONSTRAINT [FK_StockLine_Shelf] FOREIGN KEY ([ShelfId]) REFERENCES [dbo].[Shelf] ([ShelfId]),
    CONSTRAINT [FK_StockLine_Site] FOREIGN KEY ([SiteId]) REFERENCES [dbo].[Site] ([SiteId]),
    CONSTRAINT [FK_StockLine_Vendor] FOREIGN KEY ([VendorId]) REFERENCES [dbo].[Vendor] ([VendorId]),
    CONSTRAINT [FK_StockLine_Warehouse] FOREIGN KEY ([WarehouseId]) REFERENCES [dbo].[Warehouse] ([WarehouseId]),
    CONSTRAINT [FK_StockLine_WorkOrder] FOREIGN KEY ([WorkOrderId]) REFERENCES [dbo].[WorkOrder] ([WorkOrderId]),
    CONSTRAINT [FK_Stockline_WorkOrderMaterialsId] FOREIGN KEY ([WorkOrderMaterialsId]) REFERENCES [dbo].[WorkOrderMaterials] ([WorkOrderMaterialsId])
);
























GO


----------------------------------------------

CREATE TRIGGER [dbo].[Trg_StockLineAudit]

   ON  [dbo].[Stockline]

   AFTER INSERT,UPDATE

AS 

BEGIN



	INSERT INTO PAS_DEV_logs.[dbo].[StockLineAudit]

	SELECT * FROM INSERTED



	SET NOCOUNT ON;



END