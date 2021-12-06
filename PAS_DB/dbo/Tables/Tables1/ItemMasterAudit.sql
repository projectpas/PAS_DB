﻿CREATE TABLE [dbo].[ItemMasterAudit] (
    [ItemMasterAuditId]                 BIGINT          IDENTITY (1, 1) NOT NULL,
    [ItemMasterId]                      BIGINT          NOT NULL,
    [ItemTypeId]                        INT             NOT NULL,
    [PartAlternatePartId]               BIGINT          NULL,
    [ItemGroupId]                       BIGINT          NULL,
    [ItemClassificationId]              BIGINT          CONSTRAINT [DF_ItemMasterAudit_ItemClassificationId_1] DEFAULT ((0)) NOT NULL,
    [IsHazardousMaterial]               BIT             CONSTRAINT [DF_ItemMasterAudit_IsHazardousMaterial_1] DEFAULT ((0)) NOT NULL,
    [IsExpirationDateAvailable]         BIT             CONSTRAINT [DF_ItemMasterAudit_IsExpirationDateAvailable_1] DEFAULT ((0)) NOT NULL,
    [ExpirationDate]                    DATE            NULL,
    [IsReceivedDateAvailable]           BIT             CONSTRAINT [DF_ItemMasterAudit_IsReceivedDateAvailable_1] DEFAULT ((0)) NOT NULL,
    [DaysReceived]                      INT             CONSTRAINT [DF_ItemMasterAudit_DaysReceived_1] DEFAULT ((0)) NOT NULL,
    [IsManufacturingDateAvailable]      BIT             CONSTRAINT [DF_ItemMasterAudit_IsManufacturingDateAvailable_1] DEFAULT ((0)) NOT NULL,
    [ManufacturingDays]                 INT             CONSTRAINT [DF_ItemMasterAudit_ManufacturingDays_1] DEFAULT ((0)) NOT NULL,
    [IsTagDateAvailable]                BIT             CONSTRAINT [DF_ItemMasterAudit_IsTagDateAvailable_1] DEFAULT ((0)) NOT NULL,
    [TagDays]                           INT             CONSTRAINT [DF_ItemMasterAudit_TagDays_1] DEFAULT ((0)) NOT NULL,
    [IsOpenDateAvailable]               BIT             CONSTRAINT [DF_ItemMasterAudit_IsOpenDateAvailable_1] DEFAULT ((0)) NOT NULL,
    [OpenDays]                          INT             CONSTRAINT [DF_ItemMasterAudit_OpenDays_1] DEFAULT ((0)) NOT NULL,
    [IsShippedDateAvailable]            BIT             CONSTRAINT [DF_ItemMasterAudit_IsShippedDateAvailable_1] DEFAULT ((0)) NOT NULL,
    [ShippedDays]                       INT             CONSTRAINT [DF_ItemMasterAudit_ShippedDays_1] DEFAULT ((0)) NOT NULL,
    [IsOtherDateAvailable]              BIT             CONSTRAINT [DF_ItemMasterAudit_IsOtherDateAvailable_1] DEFAULT ((0)) NOT NULL,
    [OtherDays]                         INT             CONSTRAINT [DF_ItemMasterAudit_OtherDays_1] DEFAULT ((0)) NOT NULL,
    [ProvisionId]                       INT             NULL,
    [ManufacturerId]                    BIGINT          CONSTRAINT [DF_ItemMasterAudit_ManufacturerId_1] DEFAULT ((0)) NULL,
    [IsDER]                             BIT             CONSTRAINT [DF_ItemMasterAudit_IsDER_1] DEFAULT ((0)) NOT NULL,
    [NationalStockNumber]               VARCHAR (50)    NULL,
    [IsSchematic]                       BIT             CONSTRAINT [DF_ItemMasterAudit_IsSchematic_1] DEFAULT ((0)) NOT NULL,
    [OverhaulHours]                     INT             CONSTRAINT [DF_ItemMasterAudit_OverhaulHours_1] DEFAULT ((0)) NOT NULL,
    [RPHours]                           INT             CONSTRAINT [DF_ItemMasterAudit_RPHours_1] DEFAULT ((0)) NOT NULL,
    [TestHours]                         INT             CONSTRAINT [DF_ItemMasterAudit_TestHours_1] DEFAULT ((0)) NOT NULL,
    [RFQTracking]                       BIT             CONSTRAINT [DF_ItemMasterAudit_RFQTracking_1] DEFAULT ((0)) NOT NULL,
    [GLAccountId]                       BIGINT          NULL,
    [PurchaseUnitOfMeasureId]           BIGINT          CONSTRAINT [DF_ItemMasterAudit_PurchaseUnitOfMeasureId_1] DEFAULT ((0)) NOT NULL,
    [StockUnitOfMeasureId]              BIGINT          NULL,
    [ConsumeUnitOfMeasureId]            BIGINT          NULL,
    [LeadTimeDays]                      INT             CONSTRAINT [DF_ItemMasterAudit_LeadTimeDays_1] DEFAULT ((0)) NOT NULL,
    [ReorderPoint]                      INT             CONSTRAINT [DF_ItemMasterAudit_ReorderPoint_1] DEFAULT ((0)) NOT NULL,
    [ReorderQuantiy]                    INT             CONSTRAINT [DF_ItemMasterAudit_ReorderQuantiy_1] DEFAULT ((0)) NOT NULL,
    [MinimumOrderQuantity]              INT             CONSTRAINT [DF_ItemMasterAudit_MinimumOrderQuantity_1] DEFAULT ((0)) NOT NULL,
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
    [IsActive]                          BIT             CONSTRAINT [DF_ItemMasterAudit_IsActive_1] DEFAULT ((1)) NULL,
    [CurrencyId]                        INT             NULL,
    [MasterCompanyId]                   INT             NOT NULL,
    [CreatedBy]                         VARCHAR (256)   NULL,
    [UpdatedBy]                         VARCHAR (256)   NULL,
    [CreatedDate]                       DATETIME2 (7)   CONSTRAINT [DF_ItemMasterAudit_CreatedDate_1] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]                       DATETIME2 (7)   CONSTRAINT [DF_ItemMasterAudit_UpdatedDate_1] DEFAULT (getdate()) NOT NULL,
    [TurnTimeOverhaulHours]             INT             CONSTRAINT [DF_ItemMasterAudit_TurnTimeOverhaulHours_1] DEFAULT ((0)) NOT NULL,
    [TurnTimeRepairHours]               INT             CONSTRAINT [DF_ItemMasterAudit_TurnTimeRepairHours_1] DEFAULT ((0)) NOT NULL,
    [SoldUnitOfMeasureId]               BIGINT          NULL,
    [IsDeleted]                         BIT             CONSTRAINT [DF_ItemMasterAudit_IsDeleted_1] DEFAULT ((0)) NULL,
    [ExportUomId]                       BIGINT          NULL,
    [partnumber]                        VARCHAR (50)    NULL,
    [PartDescription]                   NVARCHAR (MAX)  NULL,
    [isTimeLife]                        BIT             CONSTRAINT [DF_ItemMasterAudit_isTimeLife_1] DEFAULT ((0)) NOT NULL,
    [isSerialized]                      BIT             CONSTRAINT [DF_ItemMasterAudit_isSerialized_1] DEFAULT ((0)) NOT NULL,
    [ManagementStructureId]             BIGINT          NULL,
    [ShelfLife]                         BIT             CONSTRAINT [DF_ItemMasterAudit_ShelfLife_1] DEFAULT ((0)) NOT NULL,
    [DiscountPurchasePercent]           TINYINT         NULL,
    [UnitCost]                          DECIMAL (18, 2) NULL,
    [ListPrice]                         DECIMAL (18, 2) NULL,
    [PriceDate]                         DATETIME2 (7)   NULL,
    [ItemNonStockClassificationId]      BIGINT          NULL,
    [StockLevel]                        INT             CONSTRAINT [DF_ItemMasterAudit_StockLevel_1] DEFAULT ((0)) NOT NULL,
    [ExportECCN]                        VARCHAR (200)   NULL,
    [ITARNumber]                        VARCHAR (200)   NULL,
    [ShelfLifeAvailable]                NUMERIC (18, 2) CONSTRAINT [DF_ItemMasterAudit_ShelfLifeAvailable_1] DEFAULT ((0)) NOT NULL,
    [mfgHours]                          NUMERIC (18, 2) CONSTRAINT [DF_ItemMasterAudit_mfgHours_1] DEFAULT ((0)) NOT NULL,
    [IsPma]                             BIT             CONSTRAINT [DF_ItemMasterAudit_IsPma_1] DEFAULT ((0)) NOT NULL,
    [turnTimeMfg]                       NUMERIC (18, 2) CONSTRAINT [DF_ItemMasterAudit_turnTimeMfg_1] DEFAULT ((0)) NOT NULL,
    [turnTimeBenchTest]                 NUMERIC (18, 2) CONSTRAINT [DF_ItemMasterAudit_turnTimeBenchTest_1] DEFAULT ((0)) NOT NULL,
    [IsExportUnspecified]               BIT             NULL,
    [IsExportNONMilitary]               BIT             NULL,
    [IsExportMilitary]                  BIT             NULL,
    [IsExportDual]                      BIT             NULL,
    [IsOemPNId]                         BIGINT          NULL,
    [MasterPartId]                      BIGINT          NULL,
    [RepairUnitOfMeasureId]             BIGINT          NULL,
    [RevisedPartId]                     BIGINT          NULL,
    [SiteId]                            BIGINT          CONSTRAINT [DF_ItemMasterAudit_SiteId_1] DEFAULT ((0)) NOT NULL,
    [WarehouseId]                       BIGINT          NULL,
    [LocationId]                        BIGINT          NULL,
    [ShelfId]                           BIGINT          NULL,
    [BinId]                             BIGINT          NULL,
    [ItemMasterAssetTypeId]             BIGINT          CONSTRAINT [DF_ItemMasterAudit_ItemMasterAssetTypeId_1] DEFAULT ((0)) NOT NULL,
    [IsHotItem]                         BIT             CONSTRAINT [DF_ItemMasterAudit_IsHotItem_1] DEFAULT ((0)) NOT NULL,
    [ExportSizeUnitOfMeasureId]         BIGINT          NULL,
    [IsAcquiredMethodBuy]               BIT             CONSTRAINT [DF_ItemMasterAudit_IsAcquiredMethodBuy_1] DEFAULT ((0)) NOT NULL,
    [IsOEM]                             BIT             CONSTRAINT [DF_ItemMasterAudit_IsOEM_1] DEFAULT ((0)) NOT NULL,
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
    CONSTRAINT [PK_ItemMasterAudit] PRIMARY KEY CLUSTERED ([ItemMasterAuditId] ASC)
);

