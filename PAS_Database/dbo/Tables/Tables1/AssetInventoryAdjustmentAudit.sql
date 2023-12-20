CREATE TABLE [dbo].[AssetInventoryAdjustmentAudit] (
    [AuditAssetInventoryAdjustmentId]    BIGINT         IDENTITY (1, 1) NOT NULL,
    [AssetInventoryAdjustmentId]         BIGINT         NOT NULL,
    [AssetInventoryId]                   BIGINT         NOT NULL,
    [AssetInventoryAdjustmentDataTypeId] INT            NOT NULL,
    [ChangedFrom]                        VARCHAR (50)   NULL,
    [ChangedTo]                          VARCHAR (50)   NULL,
    [AdjustmentMemo]                     NVARCHAR (MAX) NULL,
    [MasterCompanyId]                    INT            NOT NULL,
    [CreatedBy]                          VARCHAR (256)  NOT NULL,
    [UpdatedBy]                          VARCHAR (256)  NOT NULL,
    [CreatedDate]                        DATETIME2 (7)  NOT NULL,
    [UpdatedDate]                        DATETIME2 (7)  NOT NULL,
    [IsActive]                           BIT            NOT NULL,
    [AdjustmentReasonId]                 INT            NULL,
    [IsDeleted]                          BIT            NOT NULL,
    [CurrencyId]                         INT            NULL,
    [AdjustmentReason]                   VARCHAR (250)  NULL,
    CONSTRAINT [PK_AssetInventoryAdjustmentAudit] PRIMARY KEY CLUSTERED ([AuditAssetInventoryAdjustmentId] ASC)
);

