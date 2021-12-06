CREATE TABLE [dbo].[Asset] (
    [AssetRecordId]                   BIGINT          IDENTITY (1, 1) NOT NULL,
    [AssetId]                         VARCHAR (30)    NOT NULL,
    [Name]                            VARCHAR (50)    NOT NULL,
    [Description]                     VARCHAR (500)   NULL,
    [ManagementStructureId]           BIGINT          NOT NULL,
    [IsTangible]                      BIT             CONSTRAINT [Asset_IsTangible] DEFAULT ((0)) NOT NULL,
    [IsIntangible]                    BIT             CONSTRAINT [Asset_IsIntangible] DEFAULT ((0)) NOT NULL,
    [AssetAcquisitionTypeId]          BIGINT          NULL,
    [ManufacturerId]                  BIGINT          NULL,
    [ManufacturedDate]                DATETIME2 (7)   NULL,
    [Model]                           VARCHAR (30)    NULL,
    [IsSerialized]                    BIT             CONSTRAINT [Asset_IsSerialized] DEFAULT ((0)) NOT NULL,
    [UnitOfMeasureId]                 BIGINT          NULL,
    [CurrencyId]                      INT             NULL,
    [UnitCost]                        DECIMAL (18, 2) NULL,
    [ExpirationDate]                  DATETIME2 (7)   NULL,
    [Memo]                            NVARCHAR (MAX)  NULL,
    [TangibleClassId]                 BIGINT          NULL,
    [AssetIntangibleTypeId]           BIGINT          NULL,
    [AssetMaintenanceIsContract]      BIT             CONSTRAINT [Asset_AssetMaintenanceIsContract] DEFAULT ((0)) NOT NULL,
    [AssetMaintenanceContractFile]    NVARCHAR (512)  NULL,
    [UnexpiredTime]                   INT             NULL,
    [MasterCompanyId]                 INT             NOT NULL,
    [AssetLocationId]                 INT             NULL,
    [IsDeleted]                       BIT             CONSTRAINT [Asset_DC_Delete] DEFAULT ((0)) NOT NULL,
    [IsActive]                        BIT             CONSTRAINT [Asset_DC_Active] DEFAULT ((1)) NOT NULL,
    [CreatedBy]                       VARCHAR (256)   NOT NULL,
    [UpdatedBy]                       VARCHAR (256)   NOT NULL,
    [CreatedDate]                     DATETIME2 (7)   CONSTRAINT [DF_Asset_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]                     DATETIME2 (7)   CONSTRAINT [DF_Asset_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [AssetMaintenanceContractFileExt] VARCHAR (50)    NULL,
    [MasterPartId]                    BIGINT          NULL,
    [EntryDate]                       DATETIME2 (7)   NULL,
    [IsDepreciable]                   BIT             CONSTRAINT [Asset_IsDepreciable] DEFAULT ((0)) NOT NULL,
    [IsNonDepreciable]                BIT             CONSTRAINT [Asset_NonDepreciable] DEFAULT ((0)) NOT NULL,
    [IsAmortizable]                   BIT             CONSTRAINT [Asset_Amortizable] DEFAULT ((0)) NOT NULL,
    [IsNonAmortizable]                BIT             CONSTRAINT [Asset_NonAmortizable] DEFAULT ((0)) NOT NULL,
    [AlternateAssetRecordId]          BIGINT          NULL,
    [AssetParentRecordId]             BIGINT          NULL,
    [ControlNumber]                   VARCHAR (20)    NULL,
    [Level1]                          VARCHAR (200)   NULL,
    [Level2]                          VARCHAR (200)   NULL,
    [Level3]                          VARCHAR (200)   NULL,
    [Level4]                          VARCHAR (200)   NULL,
    CONSTRAINT [PK_Asset] PRIMARY KEY CLUSTERED ([AssetRecordId] ASC),
    FOREIGN KEY ([MasterPartId]) REFERENCES [dbo].[MasterParts] ([MasterPartId]),
    CONSTRAINT [FK_Asset_AssetAcquisitionType] FOREIGN KEY ([AssetAcquisitionTypeId]) REFERENCES [dbo].[AssetAcquisitionType] ([AssetAcquisitionTypeId]),
    CONSTRAINT [FK_Asset_Currency] FOREIGN KEY ([CurrencyId]) REFERENCES [dbo].[Currency] ([CurrencyId]),
    CONSTRAINT [FK_Asset_ManagementStructure] FOREIGN KEY ([ManagementStructureId]) REFERENCES [dbo].[ManagementStructure] ([ManagementStructureId]),
    CONSTRAINT [FK_Asset_Manufacturer] FOREIGN KEY ([ManufacturerId]) REFERENCES [dbo].[Manufacturer] ([ManufacturerId]),
    CONSTRAINT [FK_Asset_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [FK_Asset_TangibleClassId] FOREIGN KEY ([TangibleClassId]) REFERENCES [dbo].[TangibleClass] ([TangibleClassId]),
    CONSTRAINT [FK_Asset_UnitOfMeasure] FOREIGN KEY ([UnitOfMeasureId]) REFERENCES [dbo].[UnitOfMeasure] ([UnitOfMeasureId]),
    CONSTRAINT [Asset_Assetid] UNIQUE NONCLUSTERED ([AssetId] ASC, [MasterCompanyId] ASC),
    CONSTRAINT [Asset_Name] UNIQUE NONCLUSTERED ([Name] ASC, [MasterCompanyId] ASC)
);


GO




CREATE Trigger [dbo].[trg_Asset]

on [dbo].[Asset] 

 AFTER INSERT,UPDATE 

As  

Begin  



SET NOCOUNT ON

INSERT INTO AssetAudit (AssetRecordId,AssetId,[Name],[Description],ManagementStructureId,IsIntangible,AssetAcquisitionTypeId,IsTangible,ManufacturerId,ManufacturedDate,Model,IsSerialized,UnitOfMeasureId,CurrencyId,UnitCost,

ExpirationDate,Memo,TangibleClassId,AssetIntangibleTypeId,AssetMaintenanceIsContract,AssetMaintenanceContractFile,UnexpiredTime,MasterCompanyId,AssetLocationId,

IsDeleted,IsActive,CreatedBy,UpdatedBy,CreatedDate,UpdatedDate,AssetMaintenanceContractFileExt,MasterPartId,EntryDate,IsDepreciable,IsNonDepreciable,IsAmortizable,IsNonAmortizable,AlternateAssetRecordId,AssetParentRecordId)

SELECT AssetRecordId,AssetId,[Name],[Description],ManagementStructureId,IsIntangible,AssetAcquisitionTypeId,ManufacturerId,IsTangible,ManufacturedDate,Model,IsSerialized,UnitOfMeasureId,CurrencyId,UnitCost,

ExpirationDate,Memo,TangibleClassId,AssetIntangibleTypeId,AssetMaintenanceIsContract,AssetMaintenanceContractFile,UnexpiredTime,MasterCompanyId,AssetLocationId,

IsDeleted,IsActive,CreatedBy,UpdatedBy,CreatedDate,UpdatedDate,AssetMaintenanceContractFileExt,MasterPartId,EntryDate,IsDepreciable,IsNonDepreciable,IsAmortizable,IsNonAmortizable,AlternateAssetRecordId,AssetParentRecordId FROM INSERTED



End
GO




CREATE Trigger [dbo].[trg_Asset_Delete]

on [dbo].[Asset] 

 INSTEAD OF DELETE

As  

Begin  



SET NOCOUNT ON



DELETE AssetCapesAudit FROM DELETED D INNER JOIN AssetCapesAudit T ON T.AssetRecordId = D.AssetRecordId

DELETE AssetCapes FROM DELETED D INNER JOIN AssetCapes T ON T.AssetRecordId = D.AssetRecordId



DELETE AssetAudit FROM DELETED D INNER JOIN AssetAudit T ON T.AssetRecordId = D.AssetRecordId

DELETE Asset FROM DELETED D INNER JOIN Asset T ON T.AssetRecordId = D.AssetRecordId



Delete AssetCalibrationAudit From deleted D inner join AssetCalibrationAudit T on T.AssetRecordId = D.AssetRecordId

Delete AssetCalibration from Deleted D inner join AssetCalibration T ON T.AssetRecordId = D.AssetRecordId



Delete AssetMaintenanceAudit From deleted D inner join AssetMaintenanceAudit T on T.AssetRecordId = D.AssetRecordId

Delete AssetMaintenance from Deleted D inner join AssetMaintenance T ON T.AssetRecordId = D.AssetRecordId







End