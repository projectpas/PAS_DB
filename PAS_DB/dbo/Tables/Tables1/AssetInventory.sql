﻿CREATE TABLE [dbo].[AssetInventory] (
    [AssetInventoryId]                  BIGINT          IDENTITY (1, 1) NOT NULL,
    [AssetRecordId]                     BIGINT          NOT NULL,
    [AssetId]                           VARCHAR (30)    NOT NULL,
    [AlternateAssetRecordId]            BIGINT          NULL,
    [Name]                              VARCHAR (50)    NOT NULL,
    [Description]                       NVARCHAR (MAX)  NULL,
    [ManagementStructureId]             BIGINT          NOT NULL,
    [CalibrationRequired]               BIT             CONSTRAINT [AssetInventory_CalibrationRequired] DEFAULT ((0)) NOT NULL,
    [CertificationRequired]             BIT             CONSTRAINT [AssetInventory_CertificationRequired] DEFAULT ((0)) NOT NULL,
    [InspectionRequired]                BIT             CONSTRAINT [AssetInventory_InspectionRequired] DEFAULT ((0)) NOT NULL,
    [VerificationRequired]              BIT             CONSTRAINT [AssetInventory_VerificationRequired] DEFAULT ((0)) NOT NULL,
    [IsTangible]                        BIT             CONSTRAINT [AssetInventory_IsTangible] DEFAULT ((0)) NOT NULL,
    [IsIntangible]                      BIT             CONSTRAINT [AssetInventory_IsIntangible] DEFAULT ((0)) NOT NULL,
    [AssetAcquisitionTypeId]            BIGINT          NULL,
    [ManufacturerId]                    BIGINT          NULL,
    [ManufacturedDate]                  DATETIME2 (7)   NULL,
    [Model]                             VARCHAR (30)    NULL,
    [IsSerialized]                      BIT             CONSTRAINT [AssetInventory_IsSerialized] DEFAULT ((0)) NOT NULL,
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
    [AssetIsMaintenanceReqd]            BIT             CONSTRAINT [AssetInventory_AssetIsMaintenanceReqd] DEFAULT ((0)) NOT NULL,
    [AssetMaintenanceIsContract]        BIT             CONSTRAINT [AssetInventory_AssetMaintenanceIsContract] DEFAULT ((0)) NOT NULL,
    [AssetMaintenanceContractFile]      NVARCHAR (512)  NULL,
    [MaintenanceFrequencyMonths]        INT             CONSTRAINT [AssetInventory_MaintenanceFrequencyMonths] DEFAULT ((0)) NOT NULL,
    [MaintenanceFrequencyDays]          INT             CONSTRAINT [AssetInventory_MaintenanceFrequencyDays] DEFAULT ((0)) NOT NULL,
    [MaintenanceDefaultVendorId]        BIGINT          NULL,
    [MaintenanceGLAccountId]            BIGINT          NULL,
    [MaintenanceMemo]                   NVARCHAR (MAX)  NULL,
    [IsWarrantyRequired]                BIT             CONSTRAINT [AssetInventory_IsWarrantyRequired] DEFAULT ((0)) NOT NULL,
    [WarrantyCompany]                   VARCHAR (30)    NULL,
    [WarrantyStartDate]                 DATETIME2 (7)   NULL,
    [WarrantyEndDate]                   DATETIME2 (7)   NULL,
    [WarrantyStatusId]                  BIGINT          NULL,
    [UnexpiredTime]                     INT             CONSTRAINT [AssetInventory_UnexpiredTime] DEFAULT ((0)) NULL,
    [MasterCompanyId]                   INT             NOT NULL,
    [AssetLocationId]                   BIGINT          NULL,
    [IsDeleted]                         BIT             CONSTRAINT [DF_AssetInventory_IsDeleted] DEFAULT ((0)) NOT NULL,
    [Warranty]                          BIT             CONSTRAINT [AssetInventory_Warranty] DEFAULT ((0)) NOT NULL,
    [IsActive]                          BIT             CONSTRAINT [DF_AssetInventory_IsActive] DEFAULT ((1)) NOT NULL,
    [CalibrationDefaultVendorId]        BIGINT          NULL,
    [CertificationDefaultVendorId]      BIGINT          NULL,
    [InspectionDefaultVendorId]         BIGINT          NULL,
    [VerificationDefaultVendorId]       BIGINT          NULL,
    [CertificationFrequencyMonths]      INT             CONSTRAINT [AssetInventory_CertificationFrequencyMonths] DEFAULT ((0)) NOT NULL,
    [CertificationFrequencyDays]        INT             CONSTRAINT [AssetInventory_CertificationFrequencyDays] DEFAULT ((0)) NOT NULL,
    [CertificationDefaultCost]          DECIMAL (18, 2) CONSTRAINT [AssetInventory_CertificationDefaultCost] DEFAULT ((0)) NULL,
    [CertificationGlAccountId]          BIGINT          NULL,
    [CertificationMemo]                 NVARCHAR (MAX)  NULL,
    [InspectionMemo]                    NVARCHAR (MAX)  NULL,
    [InspectionGlaAccountId]            BIGINT          NULL,
    [InspectionDefaultCost]             DECIMAL (18, 2) CONSTRAINT [AssetInventory_InspectionDefaultCost] DEFAULT ((0)) NULL,
    [InspectionFrequencyMonths]         INT             CONSTRAINT [AssetInventory_InspectionFrequencyMonths] DEFAULT ((0)) NOT NULL,
    [InspectionFrequencyDays]           INT             CONSTRAINT [AssetInventory_InspectionFrequencyDays] DEFAULT ((0)) NOT NULL,
    [VerificationFrequencyDays]         INT             CONSTRAINT [AssetInventory_VerificationFrequencyDays] DEFAULT ((0)) NOT NULL,
    [VerificationFrequencyMonths]       INT             CONSTRAINT [AssetInventory_VerificationFrequencyMonths] DEFAULT ((0)) NOT NULL,
    [VerificationDefaultCost]           DECIMAL (18, 2) CONSTRAINT [AssetInventory_VerificationDefaultCost] DEFAULT ((0)) NULL,
    [CalibrationDefaultCost]            DECIMAL (18, 2) CONSTRAINT [AssetInventory_CalibrationDefaultCost] DEFAULT ((0)) NULL,
    [CalibrationFrequencyMonths]        INT             CONSTRAINT [AssetInventory_CalibrationFrequencyMonths] DEFAULT ((0)) NOT NULL,
    [CalibrationFrequencyDays]          INT             CONSTRAINT [AssetInventory_CalibrationFrequencyDays] DEFAULT ((0)) NOT NULL,
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
    [CreatedDate]                       DATETIME2 (7)   CONSTRAINT [DF_AssetInventory_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]                       DATETIME2 (7)   CONSTRAINT [DF_AssetInventory_UpdatedDate] DEFAULT (getdate()) NOT NULL,
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
    [IsDepreciable]                     BIT             CONSTRAINT [AssetInventory_IsDepreciable] DEFAULT ((0)) NOT NULL,
    [IsNonDepreciable]                  BIT             CONSTRAINT [AssetInventory_IsNonDepreciable] DEFAULT ((0)) NOT NULL,
    [IsAmortizable]                     BIT             CONSTRAINT [AssetInventory_IsAmortizable] DEFAULT ((0)) NOT NULL,
    [IsNonAmortizable]                  BIT             CONSTRAINT [AssetInventory_IsNonAmortizable] DEFAULT ((0)) NOT NULL,
    [SerialNo]                          NVARCHAR (50)   NULL,
    [IsInsurance]                       BIT             CONSTRAINT [AssetInventory_IsInsurance] DEFAULT ((0)) NOT NULL,
    [AssetLife]                         INT             CONSTRAINT [AssetInventory_AssetLife] DEFAULT ((0)) NOT NULL,
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
    CONSTRAINT [PK_AssetInventory] PRIMARY KEY CLUSTERED ([AssetInventoryId] ASC),
    FOREIGN KEY ([MasterPartId]) REFERENCES [dbo].[MasterParts] ([MasterPartId]),
    CONSTRAINT [FK_AssetInventory_AssetAcquisitionType] FOREIGN KEY ([AssetAcquisitionTypeId]) REFERENCES [dbo].[AssetAcquisitionType] ([AssetAcquisitionTypeId]),
    CONSTRAINT [FK_AssetInventory_Currency] FOREIGN KEY ([CurrencyId]) REFERENCES [dbo].[Currency] ([CurrencyId]),
    CONSTRAINT [FK_AssetInventory_ManagementStructure] FOREIGN KEY ([ManagementStructureId]) REFERENCES [dbo].[ManagementStructure] ([ManagementStructureId]),
    CONSTRAINT [FK_AssetInventory_Manufacturer] FOREIGN KEY ([ManufacturerId]) REFERENCES [dbo].[Manufacturer] ([ManufacturerId]),
    CONSTRAINT [FK_AssetInventory_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [FK_AssetInventory_TangibleClassId] FOREIGN KEY ([TangibleClassId]) REFERENCES [dbo].[TangibleClass] ([TangibleClassId]),
    CONSTRAINT [FK_AssetInventory_UnitOfMeasure] FOREIGN KEY ([UnitOfMeasureId]) REFERENCES [dbo].[UnitOfMeasure] ([UnitOfMeasureId]),
    CONSTRAINT [Unique_AssetInventory] UNIQUE NONCLUSTERED ([InventoryNumber] ASC, [MasterCompanyId] ASC)
);


GO




CREATE TRIGGER [dbo].[Trg_AssetInventoryAudit] ON [dbo].[AssetInventory]

   AFTER INSERT,DELETE,UPDATE  

AS   

BEGIN  

  

 INSERT INTO [dbo].[AssetInventoryAudit]  

 SELECT * FROM INSERTED  

  

 SET NOCOUNT ON;  

  

END