CREATE TABLE [dbo].[StocklineDraft] (
    [StockLineDraftId]                    BIGINT          IDENTITY (1, 1) NOT NULL,
    [PartNumber]                          VARCHAR (50)    NOT NULL,
    [StockLineNumber]                     VARCHAR (50)    NULL,
    [StocklineMatchKey]                   VARCHAR (100)   NULL,
    [ControlNumber]                       VARCHAR (50)    NULL,
    [ItemMasterId]                        BIGINT          NULL,
    [Quantity]                            INT             NOT NULL,
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
    [TagTypeIds]                          VARCHAR (MAX)   NULL,
    [TagType]                             VARCHAR (MAX)   NULL,
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
    [ManagementStructureEntityId]         BIGINT          NULL,
    [LegalEntityId]                       BIGINT          NULL,
    [MasterCompanyId]                     INT             NOT NULL,
    [CreatedBy]                           VARCHAR (256)   NOT NULL,
    [UpdatedBy]                           VARCHAR (256)   NOT NULL,
    [CreatedDate]                         DATETIME2 (7)   CONSTRAINT [DF_StocklineDraft_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]                         DATETIME2 (7)   CONSTRAINT [DF_StocklineDraft_UpdatedDate] DEFAULT (getdate()) NOT NULL,
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
    [QuantityToReceive]                   INT             NOT NULL,
    [PurchaseOrderExtendedCost]           DECIMAL (18)    CONSTRAINT [DF__StocklineDraft__Purch__53E4BFD3] DEFAULT ((0)) NOT NULL,
    [ManufacturingTrace]                  NVARCHAR (200)  NULL,
    [ExpirationDate]                      DATETIME2 (7)   NULL,
    [AircraftTailNumber]                  NVARCHAR (200)  NULL,
    [ShippingViaId]                       BIGINT          NULL,
    [EngineSerialNumber]                  NVARCHAR (200)  NULL,
    [QuantityRejected]                    INT             CONSTRAINT [DF__StocklineDraft__Quant__14BE5EF7] DEFAULT ((0)) NOT NULL,
    [PurchaseOrderPartRecordId]           BIGINT          NULL,
    [ShippingAccount]                     NVARCHAR (200)  NULL,
    [ShippingReference]                   NVARCHAR (200)  NULL,
    [TimeLifeCyclesId]                    BIGINT          NULL,
    [TimeLifeDetailsNotProvided]          BIT             CONSTRAINT [DF__StocklineDraft__TimeL__69BFBDB0] DEFAULT ((0)) NOT NULL,
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
    [BlackListed]                         BIT             CONSTRAINT [DF__Stockline__Black__2CA96073] DEFAULT ((0)) NOT NULL,
    [BlackListedReason]                   VARCHAR (500)   NULL,
    [Incident]                            BIT             CONSTRAINT [DF__Stockline__Incid__2D9D84AC] DEFAULT ((0)) NOT NULL,
    [IncidentReason]                      VARCHAR (500)   NULL,
    [Accident]                            BIT             CONSTRAINT [DF__Stockline__Accid__2E91A8E5] DEFAULT ((0)) NOT NULL,
    [AccidentReason]                      VARCHAR (500)   NULL,
    [RepairOrderPartRecordId]             BIGINT          NULL,
    [isActive]                            BIT             CONSTRAINT [DF__Stockline__isAct__2F85CD1E] DEFAULT ((1)) NOT NULL,
    [isDeleted]                           BIT             CONSTRAINT [DF__Stockline__isDel__3079F157] DEFAULT ((0)) NOT NULL,
    [WorkOrderExtendedCost]               DECIMAL (20, 2) NOT NULL,
    [RepairOrderExtendedCost]             DECIMAL (18, 2) NULL,
    [NHAItemMasterId]                     BIGINT          NULL,
    [TLAItemMasterId]                     BIGINT          NULL,
    [IsParent]                            BIT             NULL,
    [ParentId]                            BIGINT          NULL,
    [IsSameDetailsForAllParts]            BIT             NULL,
    [Level1]                              VARCHAR (200)   NULL,
    [Level2]                              VARCHAR (200)   NULL,
    [Level3]                              VARCHAR (200)   NULL,
    [Level4]                              VARCHAR (200)   NULL,
    [Condition]                           VARCHAR (250)   NULL,
    [Warehouse]                           VARCHAR (250)   NULL,
    [Location]                            VARCHAR (250)   NULL,
    [ObtainFromName]                      VARCHAR (250)   NULL,
    [OwnerName]                           VARCHAR (250)   NULL,
    [TraceableToName]                     VARCHAR (250)   NULL,
    [GLAccount]                           VARCHAR (250)   NULL,
    [AssetName]                           VARCHAR (250)   NULL,
    [LegalEntityName]                     VARCHAR (250)   NULL,
    [ShelfName]                           VARCHAR (250)   NULL,
    [BinName]                             VARCHAR (250)   NULL,
    [SiteName]                            VARCHAR (250)   NULL,
    [ObtainFromTypeName]                  VARCHAR (250)   NULL,
    [OwnerTypeName]                       VARCHAR (250)   NULL,
    [TraceableToTypeName]                 VARCHAR (250)   NULL,
    [UnitCostAdjustmentReasonType]        VARCHAR (250)   NULL,
    [UnitSalePriceAdjustmentReasonType]   VARCHAR (250)   NULL,
    [ShippingVia]                         VARCHAR (250)   NULL,
    [WorkOrder]                           VARCHAR (250)   NULL,
    [WorkOrderMaterialsName]              VARCHAR (250)   NULL,
    [TagTypeId]                           BIGINT          NULL,
    [StockLineDraftNumber]                VARCHAR (250)   NULL,
    [StockLineId]                         BIGINT          NULL,
    [TaggedBy]                            BIGINT          NULL,
    [TaggedByName]                        VARCHAR (250)   NULL,
    [UnitOfMeasureId]                     BIGINT          NULL,
    [UnitOfMeasure]                       VARCHAR (250)   NULL,
    [RevisedPartId]                       BIGINT          NULL,
    [RevisedPartNumber]                   VARCHAR (250)   NULL,
    [TaggedByType]                        INT             NULL,
    [TaggedByTypeName]                    VARCHAR (250)   NULL,
    [CertifiedById]                       BIGINT          NULL,
    [CertifiedTypeId]                     INT             NULL,
    [CertifiedType]                       VARCHAR (250)   NULL,
    [CertTypeId]                          VARCHAR (MAX)   NULL,
    [CertType]                            VARCHAR (MAX)   NULL,
    [IsCustomerStock]                     BIT             DEFAULT ((0)) NULL,
    [isCustomerstockType]                 BIT             NULL,
    [CustomerId]                          BIGINT          NULL,
    [CalibrationVendorId]                 BIGINT          NULL,
    [PerformedById]                       BIGINT          NULL,
    [LastCalibrationDate]                 DATETIME        NULL,
    [NextCalibrationDate]                 DATETIME        NULL,
    CONSTRAINT [PK_StocklineDraft] PRIMARY KEY CLUSTERED ([StockLineDraftId] ASC),
    CONSTRAINT [FK_StocklineDraft_BinId] FOREIGN KEY ([BinId]) REFERENCES [dbo].[Bin] ([BinId]),
    CONSTRAINT [FK_StocklineDraft_ConditionId] FOREIGN KEY ([ConditionId]) REFERENCES [dbo].[Condition] ([ConditionId]),
    CONSTRAINT [FK_StocklineDraft_GLAccountId] FOREIGN KEY ([GLAccountId]) REFERENCES [dbo].[GLAccount] ([GLAccountId]),
    CONSTRAINT [FK_StocklineDraft_ItemMasterId] FOREIGN KEY ([ItemMasterId]) REFERENCES [dbo].[ItemMaster] ([ItemMasterId]),
    CONSTRAINT [FK_StocklineDraft_LocationId] FOREIGN KEY ([LocationId]) REFERENCES [dbo].[Location] ([LocationId]),
    CONSTRAINT [FK_StocklineDraft_ManufacturerId] FOREIGN KEY ([ManufacturerId]) REFERENCES [dbo].[Manufacturer] ([ManufacturerId]),
    CONSTRAINT [FK_StocklineDraft_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [FK_StocklineDraft_PurchaseOrderId] FOREIGN KEY ([PurchaseOrderId]) REFERENCES [dbo].[PurchaseOrder] ([PurchaseOrderId]),
    CONSTRAINT [FK_StocklineDraft_PurchaseOrderPartRecordId] FOREIGN KEY ([PurchaseOrderPartRecordId]) REFERENCES [dbo].[PurchaseOrderPart] ([PurchaseOrderPartRecordId]),
    CONSTRAINT [FK_StocklineDraft_RepairOrderId] FOREIGN KEY ([RepairOrderId]) REFERENCES [dbo].[RepairOrder] ([RepairOrderId]),
    CONSTRAINT [FK_StocklineDraft_repairOrderPartRecordId] FOREIGN KEY ([RepairOrderPartRecordId]) REFERENCES [dbo].[RepairOrderPart] ([RepairOrderPartRecordId]),
    CONSTRAINT [FK_StocklineDraft_ShelfId] FOREIGN KEY ([ShelfId]) REFERENCES [dbo].[Shelf] ([ShelfId]),
    CONSTRAINT [FK_StocklineDraft_ShippingViaId] FOREIGN KEY ([ShippingViaId]) REFERENCES [dbo].[ShippingVia] ([ShippingViaId]),
    CONSTRAINT [FK_StocklineDraft_SiteId] FOREIGN KEY ([SiteId]) REFERENCES [dbo].[Site] ([SiteId]),
    CONSTRAINT [FK_StocklineDraft_WarehouseId] FOREIGN KEY ([WarehouseId]) REFERENCES [dbo].[Warehouse] ([WarehouseId])
);








GO




-- =============================================

create TRIGGER [dbo].[Trg_StocklineDraftAudit]

   ON  [dbo].[StocklineDraft]

   AFTER INSERT,DELETE,UPDATE

AS 

BEGIN



	INSERT INTO [dbo].[StockLineDraftAudit]

	SELECT * FROM INSERTED



	SET NOCOUNT ON;



END