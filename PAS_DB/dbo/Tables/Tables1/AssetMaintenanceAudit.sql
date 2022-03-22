CREATE TABLE [dbo].[AssetMaintenanceAudit] (
    [AssetMaintenanceAuditId]    BIGINT         IDENTITY (1, 1) NOT NULL,
    [AssetRecordId]              BIGINT         NOT NULL,
    [AssetMaintenanceId]         BIGINT         NOT NULL,
    [AssetIsMaintenanceReqd]     BIT            NULL,
    [MaintenanceFrequencyMonths] INT            NULL,
    [MaintenanceFrequencyDays]   INT            NULL,
    [MaintenanceDefaultVendorId] BIGINT         NULL,
    [MaintenanceGLAccountId]     BIGINT         NULL,
    [MaintenanceMemo]            NVARCHAR (MAX) NULL,
    [IsWarrantyRequired]         BIT            NULL,
    [WarrantyCompany]            VARCHAR (100)  NULL,
    [MasterCompanyId]            INT            NULL,
    [IsDeleted]                  BIT            NULL,
    [IsActive]                   BIT            NULL,
    [CreatedBy]                  VARCHAR (256)  NULL,
    [UpdatedBy]                  VARCHAR (256)  NULL,
    [CreatedDate]                DATETIME2 (7)  NULL,
    [UpdatedDate]                DATETIME2 (7)  NOT NULL,
    [WarrantyDefaultVendorId]    BIGINT         NULL,
    [WarrantyGLAccountId]        BIGINT         NULL,
    CONSTRAINT [PK__AssetMaitenanceAud__88889B1E86626B25] PRIMARY KEY CLUSTERED ([AssetMaintenanceAuditId] ASC),
    CONSTRAINT [FK_AssetMaintenanceAudit_Asset] FOREIGN KEY ([AssetRecordId]) REFERENCES [dbo].[Asset] ([AssetRecordId]),
    CONSTRAINT [FK_AssetMaintenanceAudit_AssetMaintenacne] FOREIGN KEY ([AssetMaintenanceId]) REFERENCES [dbo].[AssetMaintenance] ([AssetMaintenanceId])
);



