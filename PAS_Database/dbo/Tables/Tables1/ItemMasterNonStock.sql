﻿CREATE TABLE [dbo].[ItemMasterNonStock] (
    [ItemMasterNonStockId]         BIGINT          IDENTITY (1, 1) NOT NULL,
    [MasterPartId]                 BIGINT          NOT NULL,
    [PartNumber]                   VARCHAR (50)    NOT NULL,
    [PartDescription]              NVARCHAR (MAX)  NULL,
    [ItemNonStockClassificationId] BIGINT          NOT NULL,
    [ItemTypeId]                   INT             NOT NULL,
    [ItemGroupId]                  BIGINT          CONSTRAINT [DF_ItemMasterNonStock_ItemGroupId] DEFAULT ((0)) NOT NULL,
    [IsAcquiredMethodBuy]          BIT             CONSTRAINT [DF_ItemMasterNonStock_IsAcquiredMethodBuy] DEFAULT ((0)) NOT NULL,
    [ManufacturerId]               BIGINT          NOT NULL,
    [MasterCompanyId]              INT             NOT NULL,
    [DiscountPurchasePercent]      SMALLINT        CONSTRAINT [DF_ItemMasterNonStock_DiscountPurchasePercent] DEFAULT ((0)) NULL,
    [GLAccountId]                  BIGINT          NOT NULL,
    [PurchaseUnitOfMeasureId]      BIGINT          NOT NULL,
    [IsHazardousMaterial]          BIT             CONSTRAINT [DF_ItemMasterNonStock_IsHazardousMaterial] DEFAULT ((0)) NOT NULL,
    [CurrencyId]                   INT             NULL,
    [UnitCost]                     DECIMAL (18, 2) CONSTRAINT [DF_ItemMasterNonStock_UnitCost] DEFAULT ((0)) NOT NULL,
    [ListPrice]                    DECIMAL (18, 2) CONSTRAINT [DF_ItemMasterNonStock_ListPrice] DEFAULT ((0)) NOT NULL,
    [PriceDate]                    DATETIME2 (7)   NULL,
    [IsActive]                     BIT             NOT NULL,
    [IsDeleted]                    BIT             NOT NULL,
    [CreatedBy]                    VARCHAR (256)   NOT NULL,
    [CreatedDate]                  DATETIME2 (7)   NOT NULL,
    [UpdatedBy]                    VARCHAR (256)   NOT NULL,
    [UpdatedDate]                  DATETIME2 (7)   NOT NULL,
    [SiteId]                       BIGINT          NULL,
    [WarehouseId]                  BIGINT          NULL,
    [LocationId]                   BIGINT          NULL,
    [ShelfId]                      BIGINT          NULL,
    [BinId]                        BIGINT          NULL,
    [IsSerialized]                 BIT             NULL,
    [IsMfgExpirationDate]          BIT             NULL,
    [LeadTimeDays]                 INT             NULL,
    [StockLevel]                   INT             NULL,
    [ReorderPoint]                 INT             NULL,
    [ReorderQuantiy]               INT             NULL,
    [InWarranty]                   BIT             NULL,
    [CurrentStlNo]                 BIGINT          NULL,
    [Site]                         VARCHAR (50)    NULL,
    [Warehouse]                    VARCHAR (50)    NULL,
    [Location]                     VARCHAR (50)    NULL,
    [Shelf]                        VARCHAR (50)    NULL,
    [Bin]                          VARCHAR (50)    NULL,
    [ItemNonStockClassification]   VARCHAR (50)    NULL,
    [GLAccount]                    VARCHAR (50)    NULL,
    [Currency]                     VARCHAR (50)    NULL,
    [Manufacturer]                 VARCHAR (50)    NULL,
    [MfgExpirationDate]            DATETIME2 (7)   NULL,
    CONSTRAINT [PK_ItemMasterNonStock] PRIMARY KEY CLUSTERED ([ItemMasterNonStockId] ASC),
    CONSTRAINT [FK_ItemMasterNonStock_Bin] FOREIGN KEY ([BinId]) REFERENCES [dbo].[Bin] ([BinId]),
    CONSTRAINT [FK_ItemMasterNonStock_CurrencyId] FOREIGN KEY ([CurrencyId]) REFERENCES [dbo].[Currency] ([CurrencyId]),
    CONSTRAINT [FK_ItemMasterNonStock_GLAccountId] FOREIGN KEY ([GLAccountId]) REFERENCES [dbo].[GLAccount] ([GLAccountId]),
    CONSTRAINT [FK_ItemMasterNonStock_ItemGroupId] FOREIGN KEY ([ItemGroupId]) REFERENCES [dbo].[ItemGroup] ([ItemGroupId]),
    CONSTRAINT [FK_ItemMasterNonStock_ItemNonStockClassificationId] FOREIGN KEY ([ItemNonStockClassificationId]) REFERENCES [dbo].[ItemClassification] ([ItemClassificationId]),
    CONSTRAINT [FK_ItemMasterNonStock_ItemTypeId] FOREIGN KEY ([ItemTypeId]) REFERENCES [dbo].[ItemType] ([ItemTypeId]),
    CONSTRAINT [FK_ItemMasterNonStock_Location] FOREIGN KEY ([LocationId]) REFERENCES [dbo].[Location] ([LocationId]),
    CONSTRAINT [FK_ItemMasterNonStock_Manufacturer] FOREIGN KEY ([ManufacturerId]) REFERENCES [dbo].[Manufacturer] ([ManufacturerId]),
    CONSTRAINT [FK_ItemMasterNonStock_MasterCompanyId] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [FK_ItemMasterNonStock_MasterParts] FOREIGN KEY ([MasterPartId]) REFERENCES [dbo].[MasterParts] ([MasterPartId]),
    CONSTRAINT [FK_ItemMasterNonStock_Shelf] FOREIGN KEY ([ShelfId]) REFERENCES [dbo].[Shelf] ([ShelfId]),
    CONSTRAINT [FK_ItemMasterNonStock_Site] FOREIGN KEY ([SiteId]) REFERENCES [dbo].[Site] ([SiteId]),
    CONSTRAINT [FK_ItemMasterNonStock_UnitOfMeasure] FOREIGN KEY ([PurchaseUnitOfMeasureId]) REFERENCES [dbo].[UnitOfMeasure] ([UnitOfMeasureId]),
    CONSTRAINT [FK_ItemMasterNonStock_Warehouse] FOREIGN KEY ([WarehouseId]) REFERENCES [dbo].[Warehouse] ([WarehouseId])
);


GO








CREATE TRIGGER [dbo].[Trg_ItemMasterNonStockAudit]

   ON  [dbo].[ItemMasterNonStock]

   AFTER INSERT,DELETE,UPDATE

AS 

BEGIN

	INSERT INTO [dbo].[ItemMasterNonStockAudit]

	SELECT * FROM INSERTED



	SET NOCOUNT ON;



END