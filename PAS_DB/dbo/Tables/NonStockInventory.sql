CREATE TABLE [dbo].[NonStockInventory] (
    [NonStockInventoryId]          BIGINT          IDENTITY (1, 1) NOT NULL,
    [PurchaseOrderId]              BIGINT          NULL,
    [PurchaseOrderPartRecordId]    BIGINT          NULL,
    [PurchaseOrderNumber]          VARCHAR (50)    NULL,
    [RepairOrderId]                BIGINT          NULL,
    [IsParent]                     BIT             NULL,
    [ParentId]                     BIGINT          NULL,
    [MasterPartId]                 BIGINT          NOT NULL,
    [PartNumber]                   VARCHAR (50)    NULL,
    [PartDescription]              NVARCHAR (MAX)  NULL,
    [NonStockInventoryNumber]      VARCHAR (50)    NULL,
    [ControlNumber]                VARCHAR (50)    NULL,
    [ControlID]                    VARCHAR (50)    NULL,
    [IdNumber]                     VARCHAR (50)    NULL,
    [ReceiverNumber]               VARCHAR (50)    NULL,
    [ReceivedDate]                 DATETIME2 (7)   NULL,
    [IsSerialized]                 BIT             NOT NULL,
    [SerialNumber]                 VARCHAR (50)    NULL,
    [Quantity]                     INT             NOT NULL,
    [QuantityRejected]             INT             NULL,
    [QuantityOnHand]               INT             NULL,
    [CurrencyId]                   BIGINT          NULL,
    [Currency]                     VARCHAR (50)    NULL,
    [ConditionId]                  BIGINT          NULL,
    [Condition]                    VARCHAR (50)    NULL,
    [GLAccountId]                  BIGINT          NULL,
    [GLAccount]                    VARCHAR (50)    NULL,
    [UnitOfMeasureId]              BIGINT          NULL,
    [UnitOfMeasure]                VARCHAR (50)    NULL,
    [ManufacturerId]               BIGINT          NULL,
    [Manufacturer]                 VARCHAR (50)    NULL,
    [MfgExpirationDate]            DATETIME2 (7)   NULL,
    [UnitCost]                     DECIMAL (18, 2) NULL,
    [ExtendedCost]                 DECIMAL (18, 2) NULL,
    [Acquired]                     BIT             NULL,
    [IsHazardousMaterial]          BIT             NULL,
    [ItemNonStockClassificationId] BIGINT          NULL,
    [NonStockClassification]       VARCHAR (50)    NULL,
    [SiteId]                       BIGINT          NOT NULL,
    [Site]                         VARCHAR (50)    NULL,
    [WarehouseId]                  BIGINT          NULL,
    [Warehouse]                    VARCHAR (50)    NULL,
    [LocationId]                   BIGINT          NULL,
    [Location]                     VARCHAR (50)    NULL,
    [ShelfId]                      BIGINT          NULL,
    [Shelf]                        VARCHAR (50)    NULL,
    [BinId]                        BIGINT          NULL,
    [Bin]                          VARCHAR (50)    NULL,
    [ShippingViaId]                BIGINT          NULL,
    [ShippingVia]                  VARCHAR (50)    NULL,
    [ShippingAccount]              NVARCHAR (200)  NULL,
    [ShippingReference]            NVARCHAR (200)  NULL,
    [IsSameDetailsForAllParts]     BIT             NULL,
    [VendorId]                     BIGINT          NULL,
    [VendorName]                   VARCHAR (50)    NULL,
    [RequisitionerId]              BIGINT          NULL,
    [Requisitioner]                VARCHAR (50)    NULL,
    [OrderDate]                    DATETIME2 (7)   NOT NULL,
    [EntryDate]                    DATETIME2 (7)   NULL,
    [ManagementStructureId]        BIGINT          NOT NULL,
    [Level1]                       VARCHAR (100)   NULL,
    [Level2]                       VARCHAR (100)   NULL,
    [Level3]                       VARCHAR (100)   NULL,
    [Level4]                       VARCHAR (100)   NULL,
    [Memo]                         NVARCHAR (MAX)  NULL,
    [MasterCompanyId]              INT             NOT NULL,
    [CreatedBy]                    VARCHAR (256)   NOT NULL,
    [UpdatedBy]                    VARCHAR (256)   NOT NULL,
    [CreatedDate]                  DATETIME2 (7)   CONSTRAINT [DF_NonStockInventory_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]                  DATETIME2 (7)   CONSTRAINT [DF_NonStockInventory_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]                     BIT             CONSTRAINT [DF_NonStockInventory_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]                    BIT             CONSTRAINT [DF_NonStockInventory_IsDeleted] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_NonStockInventory] PRIMARY KEY CLUSTERED ([NonStockInventoryId] ASC),
    CONSTRAINT [FK_NonStockInventory_Bin] FOREIGN KEY ([BinId]) REFERENCES [dbo].[Bin] ([BinId]),
    CONSTRAINT [FK_NonStockInventory_GLAccountId] FOREIGN KEY ([GLAccountId]) REFERENCES [dbo].[GLAccount] ([GLAccountId]),
    CONSTRAINT [FK_NonStockInventory_ItemMaster] FOREIGN KEY ([MasterPartId]) REFERENCES [dbo].[MasterParts] ([MasterPartId]),
    CONSTRAINT [FK_NonStockInventory_ItemNonStockClassificationId] FOREIGN KEY ([ItemNonStockClassificationId]) REFERENCES [dbo].[ItemClassification] ([ItemClassificationId]),
    CONSTRAINT [FK_NonStockInventory_Location] FOREIGN KEY ([LocationId]) REFERENCES [dbo].[Location] ([LocationId]),
    CONSTRAINT [FK_NonStockInventory_ManagementStructure] FOREIGN KEY ([ManagementStructureId]) REFERENCES [dbo].[ManagementStructure] ([ManagementStructureId]),
    CONSTRAINT [FK_NonStockInventory_Manfacturer] FOREIGN KEY ([ManufacturerId]) REFERENCES [dbo].[Manufacturer] ([ManufacturerId]),
    CONSTRAINT [FK_NonStockInventory_MasterCompanyId] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [FK_NonStockInventory_Shelf] FOREIGN KEY ([ShelfId]) REFERENCES [dbo].[Shelf] ([ShelfId]),
    CONSTRAINT [FK_NonStockInventory_Site] FOREIGN KEY ([SiteId]) REFERENCES [dbo].[Site] ([SiteId]),
    CONSTRAINT [FK_NonStockInventory_UnitOfMeasureId] FOREIGN KEY ([UnitOfMeasureId]) REFERENCES [dbo].[UnitOfMeasure] ([UnitOfMeasureId]),
    CONSTRAINT [FK_NonStockInventory_Vendor] FOREIGN KEY ([VendorId]) REFERENCES [dbo].[Vendor] ([VendorId]),
    CONSTRAINT [FK_NonStockInventory_Warehouse] FOREIGN KEY ([WarehouseId]) REFERENCES [dbo].[Warehouse] ([WarehouseId]),
    CONSTRAINT [FK_NonStockInventorye_Condition] FOREIGN KEY ([ConditionId]) REFERENCES [dbo].[Condition] ([ConditionId])
);


GO



----------------------------------------------

CREATE TRIGGER [dbo].[Trg_NonStockInventoryAudit]

   ON  [dbo].[NonStockInventory]

   AFTER INSERT,UPDATE

AS 

BEGIN



	INSERT INTO [dbo].[NonStockInventoryAudit]

	SELECT * FROM INSERTED



	SET NOCOUNT ON;



END