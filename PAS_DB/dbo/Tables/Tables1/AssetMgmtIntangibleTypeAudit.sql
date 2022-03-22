CREATE TABLE [dbo].[AssetMgmtIntangibleTypeAudit] (
    [AssetMgmtIntangibleTypeTypeAuditId] BIGINT         IDENTITY (1, 1) NOT NULL,
    [AssetMgmtIntangibleTypeTypeId]      BIGINT         NULL,
    [AssetMgmtIntangibleTypeId]          VARCHAR (30)   NULL,
    [AssetMgmtIntangibleTypeName]        VARCHAR (50)   NULL,
    [AssetMgmtIntangibleTypeMemo]        NVARCHAR (MAX) NULL,
    [MasterCompanyId]                    INT            NULL,
    [CreatedBy]                          VARCHAR (256)  NULL,
    [UpdatedBy]                          VARCHAR (256)  NULL,
    [CreatedDate]                        DATETIME2 (7)  NULL,
    [UpdatedDate]                        DATETIME2 (7)  NULL,
    [IsActive]                           BIT            NULL,
    [IsDeleted]                          BIT            NULL,
    PRIMARY KEY CLUSTERED ([AssetMgmtIntangibleTypeTypeAuditId] ASC)
);

