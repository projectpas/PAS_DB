CREATE TABLE [dbo].[AssetInventoryAdjustmentDataTypeAudit] (
    [AuditAssetInventoryAdjustmentDataTypeId] INT           IDENTITY (1, 1) NOT NULL,
    [AssetInventoryAdjustmentDataTypeId]      INT           NOT NULL,
    [Description]                             VARCHAR (100) NOT NULL,
    [MasterCompanyId]                         INT           NOT NULL,
    [CreatedBy]                               VARCHAR (256) NOT NULL,
    [UpdatedBy]                               VARCHAR (256) NOT NULL,
    [CreatedDate]                             DATETIME2 (7) NOT NULL,
    [UpdatedDate]                             DATETIME2 (7) NOT NULL,
    [IsActive]                                BIT           NOT NULL,
    [IsDeleted]                               BIT           NOT NULL,
    CONSTRAINT [PK_AssetInventoryAdjustmentDataTypeAudit] PRIMARY KEY CLUSTERED ([AuditAssetInventoryAdjustmentDataTypeId] ASC)
);

