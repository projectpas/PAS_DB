﻿CREATE TABLE [dbo].[AssetInventoryDraft] (
    [AssetInventoryDraftId]             BIGINT          IDENTITY (1, 1) NOT NULL,
    [AssetInventoryId]                  BIGINT          NOT NULL,
    [AssetRecordId]                     BIGINT          NOT NULL,
    [AssetId]                           VARCHAR (30)    NOT NULL,
    [AlternateAssetRecordId]            BIGINT          NULL,
    [Name]                              VARCHAR (50)    NOT NULL,
    [Description]                       NVARCHAR (MAX)  NULL,
    [ManagementStructureId]             BIGINT          NOT NULL,
    [CalibrationRequired]               BIT             CONSTRAINT [AssetInventoryDraft_CalibrationRequired] DEFAULT ((0)) NOT NULL,
    [CertificationRequired]             BIT             CONSTRAINT [AssetInventoryDraft_CertificationRequired] DEFAULT ((0)) NOT NULL,
    [InspectionRequired]                BIT             CONSTRAINT [AssetInventoryDraft_InspectionRequired] DEFAULT ((0)) NOT NULL,
    [VerificationRequired]              BIT             CONSTRAINT [AssetInventoryDraft_VerificationRequired] DEFAULT ((0)) NOT NULL,
    [IsTangible]                        BIT             CONSTRAINT [AssetInventoryDraft_IsTangible] DEFAULT ((0)) NOT NULL,
    [IsIntangible]                      BIT             CONSTRAINT [AssetInventoryDraft_IsIntangible] DEFAULT ((0)) NOT NULL,
    [AssetAcquisitionTypeId]            BIGINT          NULL,
    [ManufacturerId]                    BIGINT          NULL,
    [ManufacturedDate]                  DATETIME2 (7)   NULL,
    [Model]                             VARCHAR (30)    NULL,
    [IsSerialized]                      BIT             CONSTRAINT [AssetInventoryDraft_IsSerialized] DEFAULT ((0)) NOT NULL,
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
    [AssetIsMaintenanceReqd]            BIT             CONSTRAINT [AssetInventoryDraft_AssetIsMaintenanceReqd] DEFAULT ((0)) NOT NULL,
    [AssetMaintenanceIsContract]        BIT             CONSTRAINT [AssetInventoryDraft_AssetMaintenanceIsContract] DEFAULT ((0)) NOT NULL,
    [AssetMaintenanceContractFile]      NVARCHAR (512)  NULL,
    [MaintenanceFrequencyMonths]        INT             CONSTRAINT [AssetInventoryDraft_MaintenanceFrequencyMonths] DEFAULT ((0)) NOT NULL,
    [MaintenanceFrequencyDays]          BIGINT          CONSTRAINT [AssetInventoryDraft_MaintenanceFrequencyDays] DEFAULT ((0)) NULL,
    [MaintenanceDefaultVendorId]        BIGINT          NULL,
    [MaintenanceGLAccountId]            BIGINT          NULL,
    [MaintenanceMemo]                   NVARCHAR (MAX)  NULL,
    [IsWarrantyRequired]                BIT             CONSTRAINT [AssetInventoryDraft_IsWarrantyRequired] DEFAULT ((0)) NOT NULL,
    [WarrantyCompany]                   VARCHAR (30)    NULL,
    [WarrantyStartDate]                 DATETIME2 (7)   NULL,
    [WarrantyEndDate]                   DATETIME2 (7)   NULL,
    [WarrantyStatusId]                  BIGINT          NULL,
    [UnexpiredTime]                     INT             CONSTRAINT [AssetInventoryDraft_UnexpiredTime] DEFAULT ((0)) NULL,
    [MasterCompanyId]                   INT             NOT NULL,
    [AssetLocationId]                   BIGINT          NULL,
    [IsDeleted]                         BIT             CONSTRAINT [DF_AssetInventoryDraft_IsDeleted] DEFAULT ((0)) NOT NULL,
    [Warranty]                          BIT             CONSTRAINT [AssetInventoryDraft_Warranty] DEFAULT ((0)) NOT NULL,
    [IsActive]                          BIT             CONSTRAINT [DF_AssetInventoryDraft_IsActive] DEFAULT ((1)) NOT NULL,
    [CalibrationDefaultVendorId]        BIGINT          NULL,
    [CertificationDefaultVendorId]      BIGINT          NULL,
    [InspectionDefaultVendorId]         BIGINT          NULL,
    [VerificationDefaultVendorId]       BIGINT          NULL,
    [CertificationFrequencyMonths]      INT             CONSTRAINT [AssetInventoryDraft_CertificationFrequencyMonths] DEFAULT ((0)) NOT NULL,
    [CertificationFrequencyDays]        BIGINT          CONSTRAINT [AssetInventoryDraft_CertificationFrequencyDays] DEFAULT ((0)) NULL,
    [CertificationDefaultCost]          DECIMAL (18, 2) CONSTRAINT [AssetInventoryDraft_CertificationDefaultCost] DEFAULT ((0)) NULL,
    [CertificationGlAccountId]          BIGINT          NULL,
    [CertificationMemo]                 NVARCHAR (MAX)  NULL,
    [InspectionMemo]                    NVARCHAR (MAX)  NULL,
    [InspectionGlaAccountId]            BIGINT          NULL,
    [InspectionDefaultCost]             DECIMAL (18, 2) CONSTRAINT [AssetInventoryDraft_InspectionDefaultCost] DEFAULT ((0)) NULL,
    [InspectionFrequencyMonths]         INT             CONSTRAINT [AssetInventoryDraft_InspectionFrequencyMonths] DEFAULT ((0)) NOT NULL,
    [InspectionFrequencyDays]           BIGINT          CONSTRAINT [AssetInventoryDraft_InspectionFrequencyDays] DEFAULT ((0)) NULL,
    [VerificationFrequencyDays]         BIGINT          CONSTRAINT [AssetInventoryDraft_VerificationFrequencyDays] DEFAULT ((0)) NULL,
    [VerificationFrequencyMonths]       INT             CONSTRAINT [AssetInventoryDraft_VerificationFrequencyMonths] DEFAULT ((0)) NOT NULL,
    [VerificationDefaultCost]           DECIMAL (18, 2) CONSTRAINT [AssetInventoryDraft_VerificationDefaultCost] DEFAULT ((0)) NULL,
    [CalibrationDefaultCost]            DECIMAL (18, 2) CONSTRAINT [AssetInventoryDraft_CalibrationDefaultCost] DEFAULT ((0)) NULL,
    [CalibrationFrequencyMonths]        INT             CONSTRAINT [AssetInventoryDraft_CalibrationFrequencyMonths] DEFAULT ((0)) NOT NULL,
    [CalibrationFrequencyDays]          BIGINT          CONSTRAINT [AssetInventoryDraft_CalibrationFrequencyDays] DEFAULT ((0)) NULL,
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
    [CreatedDate]                       DATETIME2 (7)   CONSTRAINT [DF_AssetInventoryDraft_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]                       DATETIME2 (7)   CONSTRAINT [DF_AssetInventoryDraft_UpdatedDate] DEFAULT (getdate()) NOT NULL,
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
    [IsDepreciable]                     BIT             CONSTRAINT [AssetInventoryDraft_IsDepreciable] DEFAULT ((0)) NOT NULL,
    [IsNonDepreciable]                  BIT             CONSTRAINT [AssetInventoryDraft_IsNonDepreciable] DEFAULT ((0)) NOT NULL,
    [IsAmortizable]                     BIT             CONSTRAINT [AssetInventoryDraft_IsAmortizable] DEFAULT ((0)) NOT NULL,
    [IsNonAmortizable]                  BIT             CONSTRAINT [AssetInventoryDraft_IsNonAmortizable] DEFAULT ((0)) NOT NULL,
    [SerialNo]                          NVARCHAR (50)   NULL,
    [IsInsurance]                       BIT             CONSTRAINT [AssetInventoryDraft_IsInsurance] DEFAULT ((0)) NOT NULL,
    [AssetLife]                         INT             CONSTRAINT [AssetInventoryDraft_AssetLife] DEFAULT ((0)) NOT NULL,
    [WarrantyCompanyId]                 BIGINT          NULL,
    [WarrantyCompanyName]               VARCHAR (100)   NULL,
    [WarrantyCompanySelectId]           INT             NULL,
    [WarrantyMemo]                      NVARCHAR (MAX)  NULL,
    [IsQtyReserved]                     BIT             DEFAULT ((0)) NOT NULL,
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
    CONSTRAINT [PK_AssetInventoryDraft] PRIMARY KEY CLUSTERED ([AssetInventoryDraftId] ASC),
    CONSTRAINT [FK_AssetInventoryDraft_AssetAcquisitionType] FOREIGN KEY ([AssetAcquisitionTypeId]) REFERENCES [dbo].[AssetAcquisitionType] ([AssetAcquisitionTypeId]),
    CONSTRAINT [FK_AssetInventoryDraft_Currency] FOREIGN KEY ([CurrencyId]) REFERENCES [dbo].[Currency] ([CurrencyId]),
    CONSTRAINT [FK_AssetInventoryDraft_Manufacturer] FOREIGN KEY ([ManufacturerId]) REFERENCES [dbo].[Manufacturer] ([ManufacturerId]),
    CONSTRAINT [FK_AssetInventoryDraft_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [FK_AssetInventoryDraft_UnitOfMeasure] FOREIGN KEY ([UnitOfMeasureId]) REFERENCES [dbo].[UnitOfMeasure] ([UnitOfMeasureId])
);


GO
CREATE TRIGGER [dbo].[Trg_AssetInventoryDraftAudit]  ON  [dbo].[AssetInventoryDraft]
   AFTER INSERT,DELETE,UPDATE 
AS 
BEGIN
	INSERT INTO [dbo].[AssetInventoryDraftAudit]  

 SELECT * FROM INSERTED  
END