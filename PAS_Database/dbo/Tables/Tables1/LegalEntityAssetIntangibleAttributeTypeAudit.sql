CREATE TABLE [dbo].[LegalEntityAssetIntangibleAttributeTypeAudit] (
    [LegalEntityAssetIntangibleAttributeTypeAuditId] BIGINT        IDENTITY (1, 1) NOT NULL,
    [LegalEntityAssetIntangibleAttributeTypeId]      BIGINT        NOT NULL,
    [AssetIntangibleAttributeTypeId]                 BIGINT        NOT NULL,
    [LegalEntityId]                                  BIGINT        NOT NULL,
    [MasterCompanyId]                                INT           NOT NULL,
    [CreatedBy]                                      VARCHAR (256) NOT NULL,
    [UpdatedBy]                                      VARCHAR (256) NOT NULL,
    [CreatedDate]                                    DATETIME2 (7) NOT NULL,
    [UpdatedDate]                                    DATETIME2 (7) NOT NULL,
    [IsActive]                                       BIT           NOT NULL,
    [IsDeleted]                                      BIT           NOT NULL,
    CONSTRAINT [PK_LegalEntityAssetIntangibleAttributeTypeAuditId] PRIMARY KEY CLUSTERED ([LegalEntityAssetIntangibleAttributeTypeAuditId] ASC)
);

