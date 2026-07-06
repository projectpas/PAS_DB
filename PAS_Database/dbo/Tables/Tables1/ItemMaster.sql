CREATE TABLE [dbo].[ItemMaster] (
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
    [ReorderPoint]                      DECIMAL (18, 6) CONSTRAINT [ItemMaster_ReorderPoint] DEFAULT ((0)) NOT NULL,
    [ReorderQuantiy]                    DECIMAL (18, 6) CONSTRAINT [ItemMaster_ReorderQuantiy] DEFAULT ((0)) NOT NULL,
    [MinimumOrderQuantity]              DECIMAL (18, 6) CONSTRAINT [ItemMaster_MinimumOrderQuantity] DEFAULT ((0)) NOT NULL,
    [PartListPrice]                     DECIMAL (18, 6) NULL,
    [PriorityId]                        BIGINT          NULL,
    [WarningId]                         BIGINT          NULL,
    [Memo]                              NVARCHAR (MAX)  NULL,
    [ExportCountryId]                   SMALLINT        NULL,
    [ExportValue]                       DECIMAL (18, 6) NULL,
    [ExportCurrencyId]                  INT             NULL,
    [ExportWeight]                      DECIMAL (18, 6) NULL,
    [ExportWeightUnit]                  VARCHAR (30)    NULL,
    [ExportSizeLength]                  DECIMAL (18, 6) NULL,
    [ExportSizeWidth]                   DECIMAL (18, 6) NULL,
    [ExportSizeHeight]                  DECIMAL (18, 6) NULL,
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
    [UnitCost]                          DECIMAL (18, 6) NULL,
    [ListPrice]                         DECIMAL (18, 6) NULL,
    [PriceDate]                         DATETIME2 (7)   NULL,
    [ItemNonStockClassificationId]      BIGINT          NULL,
    [StockLevel]                        DECIMAL (18, 6) CONSTRAINT [ItemMaster_StockLevel] DEFAULT ((0)) NULL,
    [ExportECCN]                        VARCHAR (200)   NULL,
    [ITARNumber]                        VARCHAR (200)   NULL,
    [ShelfLifeAvailable]                DECIMAL (18, 6) CONSTRAINT [ItemMaster_ShelfLifeAvailable] DEFAULT ((0)) NULL,
    [mfgHours]                          DECIMAL (18, 6) CONSTRAINT [ItemMaster_mfgHours] DEFAULT ((0)) NULL,
    [IsPma]                             BIT             CONSTRAINT [ItemMaster_IsPma] DEFAULT ((0)) NOT NULL,
    [turnTimeMfg]                       DECIMAL (18, 6) CONSTRAINT [ItemMaster_turnTimeMfg] DEFAULT ((0)) NULL,
    [turnTimeBenchTest]                 DECIMAL (18, 6) CONSTRAINT [ItemMaster_turnTimeBenchTest] DEFAULT ((0)) NULL,
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
    [MTBUR]                             INT             DEFAULT ((0)) NOT NULL,
    [NE]                                INT             DEFAULT ((0)) NOT NULL,
    [NS]                                INT             DEFAULT ((0)) NOT NULL,
    [OH]                                INT             DEFAULT ((0)) NOT NULL,
    [REP]                               INT             DEFAULT ((0)) NOT NULL,
    [SVC]                               INT             DEFAULT ((0)) NOT NULL,
    [Figure]                            VARCHAR (15)    NULL,
    [Item]                              VARCHAR (15)    NULL,
    [UNCode]                            BIT             NULL,
    [InventoryGLSettingId]              BIGINT          NULL,
    [GoodsReceivedNotInvoicesGLAccId]   BIGINT          NULL,
    [WorkInProgressGLAccId]             BIGINT          NULL,
    [InventoryToBillGLAccId]            BIGINT          NULL,
    [FinishedGoodsGLAccId]              BIGINT          NULL,
    [InventoryExchAgreementGLAccId]     BIGINT          NULL,
    [InventoryReserveGLAccId]           BIGINT          NULL,
    [COGS_WorkOrderGLAccId]             BIGINT          NULL,
    [COGS_SalesOrderGLAccId]            BIGINT          NULL,
    [COGS_QtyVarianceGLAccId]           BIGINT          NULL,
    [COGS_UnitCostVarianceGLAccId]      BIGINT          NULL,
    [RevenueMroGLAccId]                 BIGINT          NULL,
    [RevenueSoGLAccId]                  BIGINT          NULL,
    [RevenueExchGLAccId]                BIGINT          NULL,
    [COGS_ExchSalesOrderGLAccId]        BIGINT          NULL,
    [GoodsReceivedNotInvoicesGLAccName] VARCHAR (255)   NULL,
    [WorkInProgressGLAccName]           VARCHAR (255)   NULL,
    [InventoryToBillGLAccName]          VARCHAR (255)   NULL,
    [FinishedGoodsGLAccName]            VARCHAR (255)   NULL,
    [InventoryExchAgreementGLAccName]   VARCHAR (255)   NULL,
    [InventoryReserveGLAccName]         VARCHAR (255)   NULL,
    [COGS_WorkOrderGLAccName]           VARCHAR (255)   NULL,
    [COGS_SalesOrderGLAccName]          VARCHAR (255)   NULL,
    [COGS_QtyVarianceGLAccName]         VARCHAR (255)   NULL,
    [COGS_UnitCostVarianceGLAccName]    VARCHAR (255)   NULL,
    [RevenueMroGLAccName]               VARCHAR (255)   NULL,
    [RevenueSoGLAccName]                VARCHAR (255)   NULL,
    [RevenueExchGLAccName]              VARCHAR (255)   NULL,
    [COGS_ExchSalesOrderGLAccName]      VARCHAR (255)   NULL,
    [QuickBooksReferenceId]             VARCHAR (200)   NULL,
    [IsUpdated]                         BIT             NULL,
    [LastSyncDate]                      DATETIME2 (7)   NULL,
    [SyncToken]                         VARCHAR (200)   NULL,
    [WorkOrderFormTypeId]               INT             NULL,
    [IsFlightHoursAvailable]            BIT             NULL,
    [IsFlightCyclesAvailable]           BIT             NULL,
    [IsLandingsAvailable]               BIT             NULL,
    [IsStartsAvailable]                 BIT             NULL,
    [IsCalendarTimeAvailable]           BIT             NULL,
    [FlightHours]                       VARCHAR (200)   NULL,
    [FlightMinutes]                     VARCHAR (200)   NULL,
    [FlightCycles]                      INT             NULL,
    [Landings]                          INT             NULL,
    [Starts]                            INT             NULL,
    [CalendarDate]                      DATETIME2 (7)   NULL,
    [Model]                             VARCHAR (200)   NULL,
    [IntegrationTypeId]                 INT             NULL,
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
    CONSTRAINT [UC_ItemMaster_partnumber_manufacturerId] UNIQUE NONCLUSTERED ([partnumber] ASC, [ManufacturerId] ASC, [MasterCompanyId] ASC)
);


































GO

GO
CREATE     TRIGGER [dbo].[trg_Audit_dbo_ItemMaster]
        ON [dbo].[ItemMaster]
        AFTER INSERT, UPDATE, DELETE
        AS
        BEGIN
            SET NOCOUNT ON;
            ;WITH
             d AS (SELECT d.[ItemMasterId],d.[ItemTypeId],d.[PartAlternatePartId],d.[ItemGroupId],d.[ItemClassificationId],d.[IsHazardousMaterial],d.[IsExpirationDateAvailable],d.[ExpirationDate],d.[IsReceivedDateAvailable],d.[DaysReceived],d.[IsManufacturingDateAvailable],d.[ManufacturingDays],d.[IsTagDateAvailable],d.[TagDays],d.[IsOpenDateAvailable],d.[OpenDays],d.[IsShippedDateAvailable],d.[ShippedDays],d.[IsOtherDateAvailable],d.[OtherDays],d.[ProvisionId],d.[ManufacturerId],d.[IsDER],d.[NationalStockNumber],d.[IsSchematic],d.[OverhaulHours],d.[RPHours],d.[TestHours],d.[RFQTracking],d.[GLAccountId],d.[PurchaseUnitOfMeasureId],d.[StockUnitOfMeasureId],d.[ConsumeUnitOfMeasureId],d.[LeadTimeDays],d.[ReorderPoint],d.[ReorderQuantiy],d.[MinimumOrderQuantity],d.[PartListPrice],d.[PriorityId],d.[WarningId],d.[Memo],d.[ExportCountryId],d.[ExportValue],d.[ExportCurrencyId],d.[ExportWeight],d.[ExportWeightUnit],d.[ExportSizeLength],d.[ExportSizeWidth],d.[ExportSizeHeight],d.[ExportSizeUnit],d.[ExportClassificationId],d.[PurchaseCurrencyId],d.[SalesIsFixedPrice],d.[SalesCurrencyId],d.[SalesLastSalePriceDate],d.[SalesLastSalesDiscountPercentDate],d.[IsActive],d.[CurrencyId],d.[MasterCompanyId],d.[CreatedBy],d.[UpdatedBy],d.[CreatedDate],d.[UpdatedDate],d.[TurnTimeOverhaulHours],d.[TurnTimeRepairHours],d.[SoldUnitOfMeasureId],d.[IsDeleted],d.[ExportUomId],d.[partnumber],d.[PartDescription],d.[isTimeLife],d.[isSerialized],d.[ManagementStructureId],d.[ShelfLife],d.[DiscountPurchasePercent],d.[UnitCost],d.[ListPrice],d.[PriceDate],d.[ItemNonStockClassificationId],d.[StockLevel],d.[ExportECCN],d.[ITARNumber],d.[ShelfLifeAvailable],d.[mfgHours],d.[IsPma],d.[turnTimeMfg],d.[turnTimeBenchTest],d.[IsExportUnspecified],d.[IsExportNONMilitary],d.[IsExportMilitary],d.[IsExportDual],d.[IsOemPNId],d.[MasterPartId],d.[RepairUnitOfMeasureId],d.[RevisedPartId],d.[SiteId],d.[WarehouseId],d.[LocationId],d.[ShelfId],d.[BinId],d.[ItemMasterAssetTypeId],d.[IsHotItem],d.[ExportSizeUnitOfMeasureId],d.[IsAcquiredMethodBuy],d.[IsOEM],d.[RevisedPart],d.[OEMPN],d.[ItemClassificationName],d.[ItemGroup],d.[AssetAcquistionType],d.[ManufacturerName],d.[PurchaseUnitOfMeasure],d.[StockUnitOfMeasure],d.[ConsumeUnitOfMeasure],d.[PurchaseCurrency],d.[SalesCurrency],d.[GLAccount],d.[Priority],d.[SiteName],d.[WarehouseName],d.[LocationName],d.[ShelfName],d.[BinName],d.[CurrentStlNo],d.[MTBUR],d.[NE],d.[NS],d.[OH],d.[REP],d.[SVC],d.[Figure],d.[Item],d.[UNCode],d.[InventoryGLSettingId],d.[GoodsReceivedNotInvoicesGLAccId],d.[WorkInProgressGLAccId],d.[InventoryToBillGLAccId],d.[FinishedGoodsGLAccId],d.[InventoryExchAgreementGLAccId],d.[InventoryReserveGLAccId],d.[COGS_WorkOrderGLAccId],d.[COGS_SalesOrderGLAccId],d.[COGS_QtyVarianceGLAccId],d.[COGS_UnitCostVarianceGLAccId],d.[RevenueMroGLAccId],d.[RevenueSoGLAccId],d.[RevenueExchGLAccId],d.[COGS_ExchSalesOrderGLAccId],d.[GoodsReceivedNotInvoicesGLAccName],d.[WorkInProgressGLAccName],d.[InventoryToBillGLAccName],d.[FinishedGoodsGLAccName],d.[InventoryExchAgreementGLAccName],d.[InventoryReserveGLAccName],d.[COGS_WorkOrderGLAccName],d.[COGS_SalesOrderGLAccName],d.[COGS_QtyVarianceGLAccName],d.[COGS_UnitCostVarianceGLAccName],d.[RevenueMroGLAccName],d.[RevenueSoGLAccName],d.[RevenueExchGLAccName],d.[COGS_ExchSalesOrderGLAccName],d.[QuickBooksReferenceId],d.[IsUpdated],d.[LastSyncDate],d.[SyncToken],d.[WorkOrderFormTypeId] FROM deleted d),
             i AS (SELECT i.[ItemMasterId],i.[ItemTypeId],i.[PartAlternatePartId],i.[ItemGroupId],i.[ItemClassificationId],i.[IsHazardousMaterial],i.[IsExpirationDateAvailable],i.[ExpirationDate],i.[IsReceivedDateAvailable],i.[DaysReceived],i.[IsManufacturingDateAvailable],i.[ManufacturingDays],i.[IsTagDateAvailable],i.[TagDays],i.[IsOpenDateAvailable],i.[OpenDays],i.[IsShippedDateAvailable],i.[ShippedDays],i.[IsOtherDateAvailable],i.[OtherDays],i.[ProvisionId],i.[ManufacturerId],i.[IsDER],i.[NationalStockNumber],i.[IsSchematic],i.[OverhaulHours],i.[RPHours],i.[TestHours],i.[RFQTracking],i.[GLAccountId],i.[PurchaseUnitOfMeasureId],i.[StockUnitOfMeasureId],i.[ConsumeUnitOfMeasureId],i.[LeadTimeDays],i.[ReorderPoint],i.[ReorderQuantiy],i.[MinimumOrderQuantity],i.[PartListPrice],i.[PriorityId],i.[WarningId],i.[Memo],i.[ExportCountryId],i.[ExportValue],i.[ExportCurrencyId],i.[ExportWeight],i.[ExportWeightUnit],i.[ExportSizeLength],i.[ExportSizeWidth],i.[ExportSizeHeight],i.[ExportSizeUnit],i.[ExportClassificationId],i.[PurchaseCurrencyId],i.[SalesIsFixedPrice],i.[SalesCurrencyId],i.[SalesLastSalePriceDate],i.[SalesLastSalesDiscountPercentDate],i.[IsActive],i.[CurrencyId],i.[MasterCompanyId],i.[CreatedBy],i.[UpdatedBy],i.[CreatedDate],i.[UpdatedDate],i.[TurnTimeOverhaulHours],i.[TurnTimeRepairHours],i.[SoldUnitOfMeasureId],i.[IsDeleted],i.[ExportUomId],i.[partnumber],i.[PartDescription],i.[isTimeLife],i.[isSerialized],i.[ManagementStructureId],i.[ShelfLife],i.[DiscountPurchasePercent],i.[UnitCost],i.[ListPrice],i.[PriceDate],i.[ItemNonStockClassificationId],i.[StockLevel],i.[ExportECCN],i.[ITARNumber],i.[ShelfLifeAvailable],i.[mfgHours],i.[IsPma],i.[turnTimeMfg],i.[turnTimeBenchTest],i.[IsExportUnspecified],i.[IsExportNONMilitary],i.[IsExportMilitary],i.[IsExportDual],i.[IsOemPNId],i.[MasterPartId],i.[RepairUnitOfMeasureId],i.[RevisedPartId],i.[SiteId],i.[WarehouseId],i.[LocationId],i.[ShelfId],i.[BinId],i.[ItemMasterAssetTypeId],i.[IsHotItem],i.[ExportSizeUnitOfMeasureId],i.[IsAcquiredMethodBuy],i.[IsOEM],i.[RevisedPart],i.[OEMPN],i.[ItemClassificationName],i.[ItemGroup],i.[AssetAcquistionType],i.[ManufacturerName],i.[PurchaseUnitOfMeasure],i.[StockUnitOfMeasure],i.[ConsumeUnitOfMeasure],i.[PurchaseCurrency],i.[SalesCurrency],i.[GLAccount],i.[Priority],i.[SiteName],i.[WarehouseName],i.[LocationName],i.[ShelfName],i.[BinName],i.[CurrentStlNo],i.[MTBUR],i.[NE],i.[NS],i.[OH],i.[REP],i.[SVC],i.[Figure],i.[Item],i.[UNCode],i.[InventoryGLSettingId],i.[GoodsReceivedNotInvoicesGLAccId],i.[WorkInProgressGLAccId],i.[InventoryToBillGLAccId],i.[FinishedGoodsGLAccId],i.[InventoryExchAgreementGLAccId],i.[InventoryReserveGLAccId],i.[COGS_WorkOrderGLAccId],i.[COGS_SalesOrderGLAccId],i.[COGS_QtyVarianceGLAccId],i.[COGS_UnitCostVarianceGLAccId],i.[RevenueMroGLAccId],i.[RevenueSoGLAccId],i.[RevenueExchGLAccId],i.[COGS_ExchSalesOrderGLAccId],i.[GoodsReceivedNotInvoicesGLAccName],i.[WorkInProgressGLAccName],i.[InventoryToBillGLAccName],i.[FinishedGoodsGLAccName],i.[InventoryExchAgreementGLAccName],i.[InventoryReserveGLAccName],i.[COGS_WorkOrderGLAccName],i.[COGS_SalesOrderGLAccName],i.[COGS_QtyVarianceGLAccName],i.[COGS_UnitCostVarianceGLAccName],i.[RevenueMroGLAccName],i.[RevenueSoGLAccName],i.[RevenueExchGLAccName],i.[COGS_ExchSalesOrderGLAccName],i.[QuickBooksReferenceId],i.[IsUpdated],i.[LastSyncDate],i.[SyncToken],i.[WorkOrderFormTypeId] FROM inserted i),
             paired AS (
                SELECT
                    COALESCE(i.ItemMasterId, d.ItemMasterId ) AS ItemMasterId,
                    (SELECT d.* FOR JSON PATH, WITHOUT_ARRAY_WRAPPER) AS old_row_json,
                    (SELECT i.* FOR JSON PATH, WITHOUT_ARRAY_WRAPPER) AS new_row_json, 
                    CASE
                        WHEN i.ItemMasterId IS NOT NULL AND d.ItemMasterId IS NOT NULL THEN 'U'
                        WHEN i.ItemMasterId IS NOT NULL AND d.ItemMasterId IS NULL     THEN 'I'
                        WHEN i.ItemMasterId IS NULL     AND d.ItemMasterId IS NOT NULL THEN 'D'
                    END AS Action,

                    (SELECT COALESCE(i.ItemMasterId, d.ItemMasterId) AS ItemMasterId
                     FOR JSON PATH, WITHOUT_ARRAY_WRAPPER) AS PKJson
                FROM d
                FULL OUTER JOIN i
                    ON i.ItemMasterId = d.ItemMasterId
            ),

            oldv AS (
                SELECT
                    p.PKJson,
                    p.ItemMasterId,
                    v.[key]  AS ColumnName,
                    v.value  AS OldValue
                FROM paired p
                CROSS APPLY OPENJSON(p.old_row_json) v
                WHERE NOT EXISTS (
                    SELECT 1
                    FROM dbo.IgnoreColumn ign
                    WHERE ign.SchemaName = N'dbo'
                      AND ign.TableName  = N'ItemMaster'
                      AND ign.ColumnName COLLATE DATABASE_DEFAULT = v.[key] COLLATE DATABASE_DEFAULT
                )),
            newv AS (
                SELECT
                    p.PKJson,
                    p.ItemMasterId ,
                    v.[key]  AS ColumnName,
                    v.value  AS NewValue
                FROM paired p
                CROSS APPLY OPENJSON(p.new_row_json) v
                WHERE NOT EXISTS (
                    SELECT 1
                    FROM dbo.IgnoreColumn ign
                    WHERE ign.SchemaName = N'dbo'
                      AND ign.TableName  = N'ItemMaster'
                      AND ign.ColumnName COLLATE DATABASE_DEFAULT = v.[key] COLLATE DATABASE_DEFAULT
                )),
            merged AS (
                SELECT
                    COALESCE(n.PKJson, o.PKJson)                AS PKJson,
                    COALESCE(n.ColumnName, o.ColumnName)        AS ColumnName,
                    o.OldValue,
                    n.NewValue,
                    p.Action
                FROM paired p
                LEFT JOIN oldv o
                    ON o.ItemMasterId = p.ItemMasterId
                LEFT JOIN newv n
                    ON n.ItemMasterId = p.ItemMasterId
                   AND n.ColumnName = o.ColumnName
                UNION ALL
                SELECT
                    n.PKJson,
                    n.ColumnName,
                    NULL AS OldValue,
                    n.NewValue,
                    p.Action
                FROM paired p
                LEFT JOIN newv n
                    ON n.ItemMasterId = p.ItemMasterId
                WHERE NOT EXISTS (
                    SELECT 1
                    FROM oldv o2
                    WHERE o2.ItemMasterId = p.ItemMasterId
                      AND o2.ColumnName    = n.ColumnName
                )
            )
            INSERT dbo.AuditLog (SchemaName, TableName, PKJson, ColumnName, Action, OldValue, NewValue)
            SELECT
                N'dbo' AS SchemaName,
                N'ItemMaster' AS TableName,
                m.PKJson,
                m.ColumnName,
                m.Action,
                m.OldValue,
                m.NewValue
            FROM merged m
            WHERE
                (m.Action = 'U' AND (
                     (m.OldValue IS NULL AND m.NewValue IS NOT NULL)
                  OR (m.OldValue IS NOT NULL AND m.NewValue IS NULL)
                  OR (m.OldValue <> m.NewValue)
                ))
                OR
                (m.Action = 'I' AND m.NewValue IS NOT NULL)
                OR
                (m.Action = 'D' AND m.OldValue IS NOT NULL);
        END;