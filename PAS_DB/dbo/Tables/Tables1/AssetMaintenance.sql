CREATE TABLE [dbo].[AssetMaintenance] (
    [AssetMaintenanceId]         BIGINT         IDENTITY (1, 1) NOT NULL,
    [AssetRecordId]              BIGINT         NOT NULL,
    [AssetIsMaintenanceReqd]     BIT            CONSTRAINT [AssetMaintenance_AssetIsMaintenanceReqd] DEFAULT ((0)) NOT NULL,
    [MaintenanceFrequencyMonths] INT            NULL,
    [MaintenanceFrequencyDays]   INT            NULL,
    [MaintenanceDefaultVendorId] BIGINT         NULL,
    [MaintenanceGLAccountId]     BIGINT         NULL,
    [MaintenanceMemo]            NVARCHAR (MAX) NULL,
    [IsWarrantyRequired]         BIT            CONSTRAINT [AssetMaintenance_IsWarrantyRequired] DEFAULT ((0)) NULL,
    [WarrantyCompany]            VARCHAR (100)  NULL,
    [WarrantyDefaultVendorId]    BIGINT         NULL,
    [WarrantyGLAccountId]        BIGINT         NULL,
    [MasterCompanyId]            INT            NOT NULL,
    [IsDeleted]                  BIT            CONSTRAINT [AssetMaintenance_DC_Delete] DEFAULT ((0)) NOT NULL,
    [IsActive]                   BIT            CONSTRAINT [AssetMaintenance_DC_Active] DEFAULT ((1)) NOT NULL,
    [CreatedBy]                  VARCHAR (256)  NOT NULL,
    [UpdatedBy]                  VARCHAR (256)  NOT NULL,
    [CreatedDate]                DATETIME2 (7)  CONSTRAINT [AssetMaintenance_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]                DATETIME2 (7)  CONSTRAINT [AssetMaintenance_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    CONSTRAINT [PK_AssetMaintenance] PRIMARY KEY CLUSTERED ([AssetMaintenanceId] ASC),
    CONSTRAINT [FK_AssetMaintenance_AssetRecordId] FOREIGN KEY ([AssetRecordId]) REFERENCES [dbo].[Asset] ([AssetRecordId]),
    CONSTRAINT [FK_AssetMaintenance_DefaultVendorId] FOREIGN KEY ([MaintenanceDefaultVendorId]) REFERENCES [dbo].[Vendor] ([VendorId]),
    CONSTRAINT [FK_AssetMaintenance_GLAccountId] FOREIGN KEY ([MaintenanceGLAccountId]) REFERENCES [dbo].[GLAccount] ([GLAccountId]),
    CONSTRAINT [FK_AssetMaintenance_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [FK_AssetMaintenance_WarrantyDefaultVendorId] FOREIGN KEY ([WarrantyDefaultVendorId]) REFERENCES [dbo].[Vendor] ([VendorId]),
    CONSTRAINT [FK_AssetMaintenance_WarrantyGLAccountId] FOREIGN KEY ([WarrantyGLAccountId]) REFERENCES [dbo].[GLAccount] ([GLAccountId])
);


GO






Create Trigger [dbo].[trg_AssetMaintenance]

on [dbo].[AssetMaintenance] 

 AFTER INSERT,UPDATE 

As  

Begin  



SET NOCOUNT ON

INSERT INTO AssetMaintenanceAudit (AssetRecordId,AssetMaintenanceId,AssetIsMaintenanceReqd,MaintenanceFrequencyMonths,MaintenanceFrequencyDays,MaintenanceDefaultVendorId,

MaintenanceGLAccountId,MaintenanceMemo,IsWarrantyRequired,WarrantyCompany,MasterCompanyId,IsDeleted,IsActive,

CreatedBy,UpdatedBy,CreatedDate,UpdatedDate,WarrantyDefaultVendorId,WarrantyGLAccountId)

SELECT AssetRecordId,AssetMaintenanceId,AssetIsMaintenanceReqd,MaintenanceFrequencyMonths,MaintenanceFrequencyDays,MaintenanceDefaultVendorId,

MaintenanceGLAccountId,MaintenanceMemo,IsWarrantyRequired,WarrantyCompany,MasterCompanyId,IsDeleted,IsActive,

CreatedBy,UpdatedBy,CreatedDate,UpdatedDate,WarrantyDefaultVendorId,WarrantyGLAccountId FROM INSERTED



End