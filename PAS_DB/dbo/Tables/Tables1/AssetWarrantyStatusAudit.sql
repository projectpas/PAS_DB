CREATE TABLE [dbo].[AssetWarrantyStatusAudit] (
    [AuditAssetWarrantyStatusId] BIGINT         IDENTITY (1, 1) NOT NULL,
    [AssetWarrantyStatusId]      BIGINT         NOT NULL,
    [WarrantyStatus]             VARCHAR (100)  NOT NULL,
    [MasterCompanyId]            INT            NOT NULL,
    [CreatedBy]                  VARCHAR (30)   NOT NULL,
    [UpdatedBy]                  VARCHAR (30)   NOT NULL,
    [CreatedDate]                DATETIME2 (7)  NOT NULL,
    [UpdatedDate]                DATETIME2 (7)  NOT NULL,
    [IsActive]                   BIT            NOT NULL,
    [IsDeleted]                  BIT            NOT NULL,
    [Description]                VARCHAR (MAX)  NULL,
    [Memo]                       NVARCHAR (MAX) NULL,
    PRIMARY KEY CLUSTERED ([AuditAssetWarrantyStatusId] ASC)
);

