CREATE TABLE [dbo].[AssetTypeAudit] (
    [AssetTypeAuditId] BIGINT         IDENTITY (1, 1) NOT NULL,
    [AssetTypeId]      BIGINT         NOT NULL,
    [AssetTypeName]    VARCHAR (30)   NOT NULL,
    [AssetTypeMemo]    NVARCHAR (MAX) NULL,
    [MasterCompanyId]  INT            NOT NULL,
    [CreatedBy]        VARCHAR (256)  NOT NULL,
    [UpdatedBy]        VARCHAR (256)  NOT NULL,
    [CreatedDate]      DATETIME2 (7)  NOT NULL,
    [UpdatedDate]      DATETIME2 (7)  NOT NULL,
    [IsActive]         BIT            NOT NULL,
    [IsDeleted]        BIT            NOT NULL,
    CONSTRAINT [PK_AssetTypeAudit] PRIMARY KEY CLUSTERED ([AssetTypeAuditId] ASC)
);

