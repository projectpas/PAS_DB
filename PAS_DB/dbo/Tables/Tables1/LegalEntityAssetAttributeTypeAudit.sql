CREATE TABLE [dbo].[LegalEntityAssetAttributeTypeAudit] (
    [LegalEntityAssetAttributeTypeAuditId] BIGINT        IDENTITY (1, 1) NOT NULL,
    [LegalEntityAssetAttributeTypeId]      BIGINT        NOT NULL,
    [AssetAttributeTypeId]                 BIGINT        NOT NULL,
    [LegalEntityId]                        BIGINT        NOT NULL,
    [MasterCompanyId]                      INT           NOT NULL,
    [CreatedBy]                            VARCHAR (256) NOT NULL,
    [UpdatedBy]                            VARCHAR (256) NOT NULL,
    [CreatedDate]                          DATETIME2 (7) NOT NULL,
    [UpdatedDate]                          DATETIME2 (7) NOT NULL,
    [IsActive]                             BIT           NOT NULL,
    [IsDeleted]                            BIT           NOT NULL,
    CONSTRAINT [PK_LegalEntityAssetAttributeTypeAuditId] PRIMARY KEY CLUSTERED ([LegalEntityAssetAttributeTypeAuditId] ASC)
);

