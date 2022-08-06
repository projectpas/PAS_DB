﻿CREATE TABLE [dbo].[AssetInventoryDraftAudit] (
    [AssetInventoryDraftAuditId]        BIGINT          IDENTITY (1, 1) NOT NULL,
    [AssetInventoryDraftId]             BIGINT          NOT NULL,
    [AssetInventoryId]                  BIGINT          NOT NULL,
    [AssetRecordId]                     BIGINT          NOT NULL,
    [AssetId]                           VARCHAR (30)    NOT NULL,
    [AlternateAssetRecordId]            BIGINT          NULL,
    [Name]                              VARCHAR (50)    NOT NULL,
    [Description]                       NVARCHAR (MAX)  NULL,
    [ManagementStructureId]             BIGINT          NOT NULL,
    [CalibrationRequired]               BIT             NOT NULL,
    [CertificationRequired]             BIT             NOT NULL,
    [InspectionRequired]                BIT             NOT NULL,
    [VerificationRequired]              BIT             NOT NULL,
    [IsTangible]                        BIT             NOT NULL,
    [IsIntangible]                      BIT             NOT NULL,
    [AssetAcquisitionTypeId]            BIGINT          NULL,
    [ManufacturerId]                    BIGINT          NULL,
    [ManufacturedDate]                  DATETIME2 (7)   NULL,
    [Model]                             VARCHAR (30)    NULL,
    [IsSerialized]                      BIT             NOT NULL,
    [UnitOfMeasureId]                   BIGINT          NULL,
    [CurrencyId]                        INT             NULL,
    [UnitCost]                          DECIMAL (18, 2) NULL,
    [ExpirationDate]                    DATETIME2 (7)   NULL,
    [Memo]                              NVARCHAR (MAX)  NULL,
    [AssetParentRecordId]               BIGINT          NULL,
    [TangibleClassId]                   BIGINT          NULL,
    [AssetIntangibleTypeId]             BIGINT          NULL,
    [AssetCalibrationMin]               VARCHAR (30)    NULL,
    [AssetCalibrationMinTolerance]      VARCHAR (30)    NULL,
    [AssetCalibratonMax]                VARCHAR (30)    NULL,
    [AssetCalibrationMaxTolerance]      VARCHAR (30)    NULL,
    [AssetCalibrationExpected]          VARCHAR (30)    NULL,
    [AssetCalibrationExpectedTolerance] VARCHAR (30)    NULL,
    [AssetCalibrationMemo]              NVARCHAR (MAX)  NULL,
    [AssetIsMaintenanceReqd]            BIT             NOT NULL,
    [AssetMaintenanceIsContract]        BIT             NOT NULL,
    [AssetMaintenanceContractFile]      NVARCHAR (512)  NULL,
    [MaintenanceFrequencyMonths]        INT             NOT NULL,
    [MaintenanceFrequencyDays]          BIGINT          NULL,
    [MaintenanceDefaultVendorId]        BIGINT          NULL,
    [MaintenanceGLAccountId]            BIGINT          NULL,
    [MaintenanceMemo]                   NVARCHAR (MAX)  NULL,
    [IsWarrantyRequired]                BIT             NOT NULL,
    [WarrantyCompany]                   VARCHAR (30)    NULL,
    [WarrantyStartDate]                 DATETIME2 (7)   NULL,
    [WarrantyEndDate]                   DATETIME2 (7)   NULL,
    [WarrantyStatusId]                  BIGINT          NULL,
    [UnexpiredTime]                     INT             NULL,
    [MasterCompanyId]                   INT             NOT NULL,
    [AssetLocationId]                   BIGINT          NULL,
    [IsDeleted]                         BIT             NOT NULL,
    [Warranty]                          BIT             NOT NULL,
    [IsActive]                          BIT             NOT NULL,
    [CalibrationDefaultVendorId]        BIGINT          NULL,
    [CertificationDefaultVendorId]      BIGINT          NULL,
    [InspectionDefaultVendorId]         BIGINT          NULL,
    [VerificationDefaultVendorId]       BIGINT          NULL,
    [CertificationFrequencyMonths]      INT             NOT NULL,
    [CertificationFrequencyDays]        BIGINT          NULL,
    [CertificationDefaultCost]          DECIMAL (18, 2) NULL,
    [CertificationGlAccountId]          BIGINT          NULL,
    [CertificationMemo]                 NVARCHAR (MAX)  NULL,
    [InspectionMemo]                    NVARCHAR (MAX)  NULL,
    [InspectionGlaAccountId]            BIGINT          NULL,
    [InspectionDefaultCost]             DECIMAL (18, 2) NULL,
    [InspectionFrequencyMonths]         INT             NOT NULL,
    [InspectionFrequencyDays]           BIGINT          NULL,
    [VerificationFrequencyDays]         BIGINT          NULL,
    [VerificationFrequencyMonths]       INT             NOT NULL,
    [VerificationDefaultCost]           DECIMAL (18, 2) NULL,
    [CalibrationDefaultCost]            DECIMAL (18, 2) NULL,
    [CalibrationFrequencyMonths]        INT             NOT NULL,
    [CalibrationFrequencyDays]          BIGINT          NULL,
    [CalibrationGlAccountId]            BIGINT          NULL,
    [CalibrationMemo]                   NVARCHAR (MAX)  NULL,
    [VerificationMemo]                  NVARCHAR (MAX)  NULL,
    [VerificationGlAccountId]           BIGINT          NULL,
    [CalibrationCurrencyId]             INT             NULL,
    [CertificationCurrencyId]           INT             NULL,
    [InspectionCurrencyId]              INT             NULL,
    [VerificationCurrencyId]            INT             NULL,
    [CreatedBy]                         VARCHAR (256)   NOT NULL,
    [UpdatedBy]                         VARCHAR (256)   NOT NULL,
    [CreatedDate]                       DATETIME2 (7)   NOT NULL,
    [UpdatedDate]                       DATETIME2 (7)   NOT NULL,
    [AssetMaintenanceContractFileExt]   VARCHAR (50)    NULL,
    [WarrantyFile]                      NVARCHAR (512)  NULL,
    [WarrantyFileExt]                   VARCHAR (50)    NULL,
    [MasterPartId]                      BIGINT          NULL,
    [EntryDate]                         DATETIME2 (7)   NULL,
    [InstallationCost]                  DECIMAL (18, 2) NULL,
    [Freight]                           DECIMAL (18, 2) NULL,
    [Insurance]                         DECIMAL (18, 2) NULL,
    [Taxes]                             DECIMAL (18, 2) NULL,
    [TotalCost]                         DECIMAL (18, 2) NULL,
    [WarrantyDefaultVendorId]           BIGINT          NULL,
    [WarrantyGLAccountId]               BIGINT          NULL,
    [IsDepreciable]                     BIT             NOT NULL,
    [IsNonDepreciable]                  BIT             NOT NULL,
    [IsAmortizable]                     BIT             NOT NULL,
    [IsNonAmortizable]                  BIT             NOT NULL,
    [SerialNo]                          NVARCHAR (50)   NULL,
    [IsInsurance]                       BIT             NOT NULL,
    [AssetLife]                         INT             NOT NULL,
    [WarrantyCompanyId]                 BIGINT          NULL,
    [WarrantyCompanyName]               VARCHAR (100)   NULL,
    [WarrantyCompanySelectId]           INT             NULL,
    [WarrantyMemo]                      NVARCHAR (MAX)  NULL,
    [IsQtyReserved]                     BIT             NOT NULL,
    [InventoryStatusId]                 BIGINT          NULL,
    [InventoryNumber]                   VARCHAR (100)   NULL,
    [AssetStatusId]                     BIGINT          NULL,
    [Level1]                            VARCHAR (200)   NULL,
    [Level2]                            VARCHAR (200)   NULL,
    [Level3]                            VARCHAR (200)   NULL,
    [Level4]                            VARCHAR (200)   NULL,
    [ManufactureName]                   VARCHAR (100)   NULL,
    [LocationName]                      VARCHAR (100)   NULL,
    [Qty]                               DECIMAL (13, 2) NULL,
    [StklineNumber]                     VARCHAR (100)   NULL,
    [AvailStatus]                       VARCHAR (100)   NULL,
    [PartNumber]                        VARCHAR (100)   NULL,
    [ControlNumber]                     VARCHAR (100)   NULL,
    [TagDate]                           DATETIME        NULL,
    [ShippingViaId]                     BIGINT          NULL,
    [ShippingVia]                       VARCHAR (250)   NULL,
    [ShippingAccount]                   NVARCHAR (400)  NULL,
    [ShippingReference]                 NVARCHAR (400)  NULL,
    [RepairOrderId]                     BIGINT          NULL,
    [RepairOrderPartRecordId]           BIGINT          NULL,
    [PurchaseOrderId]                   BIGINT          NULL,
    [PurchaseOrderPartRecordId]         BIGINT          NULL,
    [SiteId]                            BIGINT          NULL,
    [WarehouseId]                       BIGINT          NULL,
    [LocationId]                        BIGINT          NULL,
    [ShelfId]                           BIGINT          NULL,
    [BinId]                             BIGINT          NULL,
    [GLAccountId]                       BIGINT          NULL,
    [GLAccount]                         VARCHAR (100)   NULL,
    [SiteName]                          VARCHAR (250)   NULL,
    [Warehouse]                         VARCHAR (250)   NULL,
    [Location]                          VARCHAR (250)   NULL,
    [ShelfName]                         VARCHAR (250)   NULL,
    [BinName]                           VARCHAR (250)   NULL,
    [IsParent]                          BIT             NULL,
    [ParentId]                          BIGINT          NULL,
    [IsSameDetailsForAllParts]          BIT             NULL,
    [ReceiverNumber]                    VARCHAR (100)   NULL,
    [ReceivedDate]                      DATETIME2 (7)   NULL,
    [CalibrationVendorId]               BIGINT          NULL,
    [PerformedById]                     BIGINT          NULL,
    [LastCalibrationDate]               DATETIME        NULL,
    [NextCalibrationDate]               DATETIME        NULL,
    CONSTRAINT [PK_AssetInventoryDraftAudit] PRIMARY KEY CLUSTERED ([AssetInventoryDraftAuditId] ASC)
);



