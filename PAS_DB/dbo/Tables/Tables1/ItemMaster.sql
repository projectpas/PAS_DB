﻿CREATE TABLE [dbo].[ItemMaster] (
    [ItemMasterId]                      BIGINT          IDENTITY (1, 1) NOT NULL,
    [ItemTypeId]                        INT             NOT NULL,
    [PartAlternatePartId]               BIGINT          NULL,
    [ItemGroupId]                       BIGINT          NULL,
    [ItemClassificationId]              BIGINT          CONSTRAINT [ItemMaster_ItemClassificationId] DEFAULT ((0)) NOT NULL,
    [IsHazardousMaterial]               BIT             CONSTRAINT [ItemMaster_IsHazardousMaterial] DEFAULT ((0)) NOT NULL,
    [IsExpirationDateAvailable]         BIT             CONSTRAINT [ItemMaster_IsExpirationDateAvailable] DEFAULT ((0)) NOT NULL,
    [ExpirationDate]                    DATE            NULL,
    [IsReceivedDateAvailable]           BIT             CONSTRAINT [ItemMaster_IsReceivedDateAvailable] DEFAULT ((0)) NOT NULL,
    [DaysReceived]                      INT             CONSTRAINT [ItemMaster_DaysReceived] DEFAULT ((0)) NOT NULL,
    [IsManufacturingDateAvailable]      BIT             CONSTRAINT [ItemMaster_IsManufacturingDateAvailable] DEFAULT ((0)) NOT NULL,
    [ManufacturingDays]                 INT             CONSTRAINT [ItemMaster_ManufacturingDays] DEFAULT ((0)) NOT NULL,
    [IsTagDateAvailable]                BIT             CONSTRAINT [ItemMaster_IsTagDateAvailable] DEFAULT ((0)) NOT NULL,
    [TagDays]                           INT             CONSTRAINT [ItemMaster_TagDays] DEFAULT ((0)) NOT NULL,
    [IsOpenDateAvailable]               BIT             CONSTRAINT [ItemMaster_IsOpenDateAvailable] DEFAULT ((0)) NOT NULL,
    [OpenDays]                          INT             CONSTRAINT [ItemMaster_OpenDays] DEFAULT ((0)) NOT NULL,
    [IsShippedDateAvailable]            BIT             CONSTRAINT [ItemMaster_IsShippedDateAvailable] DEFAULT ((0)) NOT NULL,
    [ShippedDays]                       INT             CONSTRAINT [ItemMaster_ShippedDays] DEFAULT ((0)) NOT NULL,
    [IsOtherDateAvailable]              BIT             CONSTRAINT [ItemMaster_IsOtherDateAvailable] DEFAULT ((0)) NOT NULL,
    [OtherDays]                         INT             CONSTRAINT [ItemMaster_OtherDays] DEFAULT ((0)) NOT NULL,
    [ProvisionId]                       INT             NULL,
    [ManufacturerId]                    BIGINT          CONSTRAINT [ItemMaster_ManufacturerId] DEFAULT ((0)) NULL,
    [IsDER]                             BIT             CONSTRAINT [ItemMaster_IsDER] DEFAULT ((0)) NOT NULL,
    [NationalStockNumber]               VARCHAR (50)    NULL,
    [IsSchematic]                       BIT             CONSTRAINT [ItemMaster_IsSchematic] DEFAULT ((0)) NOT NULL,
    [OverhaulHours]                     INT             CONSTRAINT [ItemMaster_OverhaulHours] DEFAULT ((0)) NOT NULL,
    [RPHours]                           INT             CONSTRAINT [ItemMaster_RPHours] DEFAULT ((0)) NOT NULL,
    [TestHours]                         INT             CONSTRAINT [ItemMaster_TestHours] DEFAULT ((0)) NOT NULL,
    [RFQTracking]                       BIT             CONSTRAINT [ItemMaster_RFQTracking] DEFAULT ((0)) NOT NULL,
    [GLAccountId]                       BIGINT          NOT NULL,
    [PurchaseUnitOfMeasureId]           BIGINT          CONSTRAINT [ItemMaster_PurchaseUnitOfMeasureId] DEFAULT ((0)) NOT NULL,
    [StockUnitOfMeasureId]              BIGINT          NULL,
    [ConsumeUnitOfMeasureId]            BIGINT          NULL,
    [LeadTimeDays]                      INT             CONSTRAINT [ItemMaster_LeadTimeDays] DEFAULT ((0)) NOT NULL,
    [ReorderPoint]                      INT             CONSTRAINT [ItemMaster_ReorderPoint] DEFAULT ((0)) NOT NULL,
    [ReorderQuantiy]                    INT             CONSTRAINT [ItemMaster_ReorderQuantiy] DEFAULT ((0)) NOT NULL,
    [MinimumOrderQuantity]              INT             CONSTRAINT [ItemMaster_MinimumOrderQuantity] DEFAULT ((0)) NOT NULL,
    [PartListPrice]                     DECIMAL (18, 2) NULL,
    [PriorityId]                        BIGINT          NULL,
    [WarningId]                         BIGINT          NULL,
    [Memo]                              NVARCHAR (MAX)  NULL,
    [ExportCountryId]                   SMALLINT        NULL,
    [ExportValue]                       NUMERIC (18, 2) NULL,
    [ExportCurrencyId]                  INT             NULL,
    [ExportWeight]                      NUMERIC (18, 2) NULL,
    [ExportWeightUnit]                  VARCHAR (30)    NULL,
    [ExportSizeLength]                  NUMERIC (18, 2) NULL,
    [ExportSizeWidth]                   NUMERIC (18, 2) NULL,
    [ExportSizeHeight]                  NUMERIC (18, 2) NULL,
    [ExportSizeUnit]                    VARCHAR (30)    NULL,
    [ExportClassificationId]            TINYINT         NULL,
    [PurchaseCurrencyId]                INT             NOT NULL,
    [SalesIsFixedPrice]                 BIT             NULL,
    [SalesCurrencyId]                   INT             NOT NULL,
    [SalesLastSalePriceDate]            DATETIME2 (7)   NULL,
    [SalesLastSalesDiscountPercentDate] DATETIME2 (7)   NULL,
    [IsActive]                          BIT             CONSTRAINT [DF_ItemMaster_IsActive] DEFAULT ((1)) NULL,
    [CurrencyId]                        INT             NULL,
    [MasterCompanyId]                   INT             NOT NULL,
    [CreatedBy]                         VARCHAR (256)   NULL,
    [UpdatedBy]                         VARCHAR (256)   NULL,
    [CreatedDate]                       DATETIME2 (7)   CONSTRAINT [DF_ItemMaster_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]                       DATETIME2 (7)   CONSTRAINT [DF_ItemMaster_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [TurnTimeOverhaulHours]             INT             CONSTRAINT [ItemMaster_TurnTimeOverhaulHours] DEFAULT ((0)) NOT NULL,
    [TurnTimeRepairHours]               INT             CONSTRAINT [ItemMaster_TurnTimeRepairHours] DEFAULT ((0)) NOT NULL,
    [SoldUnitOfMeasureId]               BIGINT          NULL,
    [IsDeleted]                         BIT             CONSTRAINT [DF_ItemMaster_isDelete] DEFAULT ((0)) NULL,
    [ExportUomId]                       BIGINT          NULL,
    [partnumber]                        VARCHAR (50)    NULL,
    [PartDescription]                   NVARCHAR (MAX)  NULL,
    [isTimeLife]                        BIT             CONSTRAINT [ItemMaster_IsTimeLife] DEFAULT ((0)) NOT NULL,
    [isSerialized]                      BIT             CONSTRAINT [ItemMaster_IsSerialized] DEFAULT ((0)) NOT NULL,
    [ManagementStructureId]             BIGINT          NULL,
    [ShelfLife]                         BIT             CONSTRAINT [ItemMaster_ShelfLife] DEFAULT ((0)) NOT NULL,
    [DiscountPurchasePercent]           TINYINT         NULL,
    [UnitCost]                          DECIMAL (18, 2) NULL,
    [ListPrice]                         DECIMAL (18, 2) NULL,
    [PriceDate]                         DATETIME2 (7)   NULL,
    [ItemNonStockClassificationId]      BIGINT          NULL,
    [StockLevel]                        INT             CONSTRAINT [ItemMaster_StockLevel] DEFAULT ((0)) NOT NULL,
    [ExportECCN]                        VARCHAR (200)   NULL,
    [ITARNumber]                        VARCHAR (200)   NULL,
    [ShelfLifeAvailable]                NUMERIC (18, 2) CONSTRAINT [ItemMaster_ShelfLifeAvailable] DEFAULT ((0)) NOT NULL,
    [mfgHours]                          NUMERIC (18, 2) CONSTRAINT [ItemMaster_mfgHours] DEFAULT ((0)) NOT NULL,
    [IsPma]                             BIT             CONSTRAINT [ItemMaster_IsPma] DEFAULT ((0)) NOT NULL,
    [turnTimeMfg]                       NUMERIC (18, 2) CONSTRAINT [ItemMaster_turnTimeMfg] DEFAULT ((0)) NOT NULL,
    [turnTimeBenchTest]                 NUMERIC (18, 2) CONSTRAINT [ItemMaster_turnTimeBenchTest] DEFAULT ((0)) NOT NULL,
    [IsExportUnspecified]               BIT             NULL,
    [IsExportNONMilitary]               BIT             NULL,
    [IsExportMilitary]                  BIT             NULL,
    [IsExportDual]                      BIT             NULL,
    [IsOemPNId]                         BIGINT          NULL,
    [MasterPartId]                      BIGINT          NULL,
    [RepairUnitOfMeasureId]             BIGINT          NULL,
    [RevisedPartId]                     BIGINT          NULL,
    [SiteId]                            BIGINT          CONSTRAINT [ItemMaster_SiteId] DEFAULT ((0)) NOT NULL,
    [WarehouseId]                       BIGINT          NULL,
    [LocationId]                        BIGINT          NULL,
    [ShelfId]                           BIGINT          NULL,
    [BinId]                             BIGINT          NULL,
    [ItemMasterAssetTypeId]             BIGINT          CONSTRAINT [ItemMaster_ItemMasterAssetTypeId] DEFAULT ((0)) NOT NULL,
    [IsHotItem]                         BIT             CONSTRAINT [ItemMaster_IsHotItem] DEFAULT ((0)) NOT NULL,
    [ExportSizeUnitOfMeasureId]         BIGINT          NULL,
    [IsAcquiredMethodBuy]               BIT             CONSTRAINT [ItemMaster_IsAcquiredMethodBuy] DEFAULT ((0)) NOT NULL,
    [IsOEM]                             BIT             CONSTRAINT [ItemMaster_IsOEM] DEFAULT ((0)) NOT NULL,
    [RevisedPart]                       VARCHAR (250)   NULL,
    [OEMPN]                             VARCHAR (250)   NULL,
    [ItemClassificationName]            VARCHAR (250)   NULL,
    [ItemGroup]                         VARCHAR (250)   NULL,
    [AssetAcquistionType]               VARCHAR (250)   NULL,
    [ManufacturerName]                  VARCHAR (250)   NULL,
    [PurchaseUnitOfMeasure]             VARCHAR (250)   NULL,
    [StockUnitOfMeasure]                VARCHAR (250)   NULL,
    [ConsumeUnitOfMeasure]              VARCHAR (250)   NULL,
    [PurchaseCurrency]                  VARCHAR (50)    NULL,
    [SalesCurrency]                     VARCHAR (50)    NULL,
    [GLAccount]                         VARCHAR (250)   NULL,
    [Priority]                          VARCHAR (250)   NULL,
    [SiteName]                          VARCHAR (250)   NULL,
    [WarehouseName]                     VARCHAR (250)   NULL,
    [LocationName]                      VARCHAR (250)   NULL,
    [ShelfName]                         VARCHAR (250)   NULL,
    [BinName]                           VARCHAR (250)   NULL,
    [CurrentStlNo]                      BIGINT          NULL,
    CONSTRAINT [PK_ItemMaster] PRIMARY KEY CLUSTERED ([ItemMasterId] ASC),
    CONSTRAINT [FK_ItemMaster_AlternatePart] FOREIGN KEY ([PartAlternatePartId]) REFERENCES [dbo].[Part] ([PartId]),
    CONSTRAINT [FK_ItemMaster_BinId] FOREIGN KEY ([BinId]) REFERENCES [dbo].[Bin] ([BinId]),
    CONSTRAINT [FK_ItemMaster_ConsumeUOM] FOREIGN KEY ([ConsumeUnitOfMeasureId]) REFERENCES [dbo].[UnitOfMeasure] ([UnitOfMeasureId]),
    CONSTRAINT [FK_ItemMaster_Country] FOREIGN KEY ([ExportCountryId]) REFERENCES [dbo].[Countries] ([countries_id]),
    CONSTRAINT [FK_ItemMaster_Currency] FOREIGN KEY ([CurrencyId]) REFERENCES [dbo].[Currency] ([CurrencyId]),
    CONSTRAINT [FK_ItemMaster_ExportClassification] FOREIGN KEY ([ExportClassificationId]) REFERENCES [dbo].[ExportClassification] ([ExportClassificationId]),
    CONSTRAINT [FK_ItemMaster_ExportCountry] FOREIGN KEY ([ExportCountryId]) REFERENCES [dbo].[Countries] ([countries_id]),
    CONSTRAINT [FK_ItemMaster_ExportCurrency] FOREIGN KEY ([ExportCurrencyId]) REFERENCES [dbo].[Currency] ([CurrencyId]),
    CONSTRAINT [FK_ItemMaster_GLAccountId] FOREIGN KEY ([GLAccountId]) REFERENCES [dbo].[GLAccount] ([GLAccountId]),
    CONSTRAINT [FK_ItemMaster_IsOemPNId] FOREIGN KEY ([IsOemPNId]) REFERENCES [dbo].[ItemMaster] ([ItemMasterId]),
    CONSTRAINT [FK_ItemMaster_ItemGroupId] FOREIGN KEY ([ItemGroupId]) REFERENCES [dbo].[ItemGroup] ([ItemGroupId]),
    CONSTRAINT [FK_ItemMaster_ItemMaster] FOREIGN KEY ([ItemMasterId]) REFERENCES [dbo].[ItemMaster] ([ItemMasterId]),
    CONSTRAINT [FK_ItemMaster_ItemMaster1] FOREIGN KEY ([ItemMasterId]) REFERENCES [dbo].[ItemMaster] ([ItemMasterId]),
    CONSTRAINT [FK_ItemMaster_ItemType] FOREIGN KEY ([ItemTypeId]) REFERENCES [dbo].[ItemType] ([ItemTypeId]),
    CONSTRAINT [FK_ItemMaster_LocationId] FOREIGN KEY ([LocationId]) REFERENCES [dbo].[Location] ([LocationId]),
    CONSTRAINT [FK_Itemmaster_ManagementStructure] FOREIGN KEY ([ManagementStructureId]) REFERENCES [dbo].[ManagementStructure] ([ManagementStructureId]),
    CONSTRAINT [FK_ItemMaster_Manufacturer] FOREIGN KEY ([ManufacturerId]) REFERENCES [dbo].[Manufacturer] ([ManufacturerId]),
    CONSTRAINT [FK_ItemMaster_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [FK_ItemMaster_MasterParts] FOREIGN KEY ([MasterPartId]) REFERENCES [dbo].[MasterParts] ([MasterPartId]),
    CONSTRAINT [FK_ItemMaster_Priority] FOREIGN KEY ([PriorityId]) REFERENCES [dbo].[Priority] ([PriorityId]),
    CONSTRAINT [FK_ItemMaster_Provision] FOREIGN KEY ([ProvisionId]) REFERENCES [dbo].[Provision] ([ProvisionId]),
    CONSTRAINT [FK_ItemMaster_PurchaseCurrency] FOREIGN KEY ([PurchaseCurrencyId]) REFERENCES [dbo].[Currency] ([CurrencyId]),
    CONSTRAINT [FK_ItemMaster_PurchaseUOM] FOREIGN KEY ([PurchaseUnitOfMeasureId]) REFERENCES [dbo].[UnitOfMeasure] ([UnitOfMeasureId]),
    CONSTRAINT [FK_ItemMaster_RevisedPartId] FOREIGN KEY ([RevisedPartId]) REFERENCES [dbo].[ItemMaster] ([ItemMasterId]),
    CONSTRAINT [FK_ItemMaster_SalesCurrency] FOREIGN KEY ([SalesCurrencyId]) REFERENCES [dbo].[Currency] ([CurrencyId]),
    CONSTRAINT [FK_ItemMaster_ShelfId] FOREIGN KEY ([ShelfId]) REFERENCES [dbo].[Shelf] ([ShelfId]),
    CONSTRAINT [FK_ItemMaster_StockUnitOfMeasure] FOREIGN KEY ([StockUnitOfMeasureId]) REFERENCES [dbo].[UnitOfMeasure] ([UnitOfMeasureId]),
    CONSTRAINT [FK_ItemMaster_StockUOM] FOREIGN KEY ([StockUnitOfMeasureId]) REFERENCES [dbo].[UnitOfMeasure] ([UnitOfMeasureId]),
    CONSTRAINT [FK_ItemMaster_WarehouseId] FOREIGN KEY ([WarehouseId]) REFERENCES [dbo].[Warehouse] ([WarehouseId]),
    CONSTRAINT [FK_ItemMaster_Warning] FOREIGN KEY ([WarningId]) REFERENCES [dbo].[Warning] ([WarningId]),
    CONSTRAINT [UC_ItemMaster_partnumber] UNIQUE NONCLUSTERED ([partnumber] ASC, [MasterCompanyId] ASC)
);




GO






create TRIGGER [dbo].[Trg_ItemMasterAudit]

   ON  [dbo].[ItemMaster]

   AFTER INSERT,DELETE,UPDATE

AS 

BEGIN



	INSERT INTO [dbo].[ItemMasterAudit]

	SELECT * FROM INSERTED



	SET NOCOUNT ON;



END