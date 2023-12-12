CREATE TABLE [dbo].[NonStockInventoryDraft] (
    [NonStockInventoryDraftId]     BIGINT          IDENTITY (1, 1) NOT NULL,
    [NonStockDraftNumber]          VARCHAR (50)    NULL,
    [PurchaseOrderId]              BIGINT          NOT NULL,
    [PurchaseOrderPartRecordId]    BIGINT          NOT NULL,
    [PurchaseOrderNumber]          VARCHAR (50)    NOT NULL,
    [IsParent]                     BIT             NULL,
    [ParentId]                     BIGINT          NULL,
    [MasterPartId]                 BIGINT          NOT NULL,
    [PartNumber]                   VARCHAR (50)    NULL,
    [PartDescription]              NVARCHAR (MAX)  NULL,
    [NonStockInventoryId]          BIGINT          NULL,
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
    [Acquired]                     INT             NULL,
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
    [OrderDate]                    DATETIME2 (7)   NULL,
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
    [CreatedDate]                  DATETIME2 (7)   CONSTRAINT [DF_NonStockInventoryDraft_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]                  DATETIME2 (7)   CONSTRAINT [DF_NonStockInventoryDraft_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]                     BIT             CONSTRAINT [DF_NonStockInventoryDraft_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]                    BIT             CONSTRAINT [DF_NonStockInventoryDraft_IsDeleted] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_NonStockInventoryDraft] PRIMARY KEY CLUSTERED ([NonStockInventoryDraftId] ASC)
);


GO



---------------------------------------------------------------------------------------------

CREATE TRIGGER [dbo].[Trg_NonStockInventoryDraftAudit]
   ON  [dbo].[NonStockInventoryDraft]
   AFTER INSERT,DELETE,UPDATE
AS 
BEGIN
		INSERT INTO NonStockInventoryDraftAudit
		SELECT * FROM INSERTED
		SET NOCOUNT ON;
END