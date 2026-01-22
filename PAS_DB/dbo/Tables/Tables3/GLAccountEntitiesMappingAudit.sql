CREATE TABLE [dbo].[GLAccountEntitiesMappingAudit] (
    [GLAccountEntitiesMappingAuditId] BIGINT        IDENTITY (1, 1) NOT NULL,
    [GLAccountEntitiesMappingId]      BIGINT        NOT NULL,
    [EntitiesId]                      BIGINT        NOT NULL,
    [GlAccountId]                     BIGINT        NOT NULL,
    [CreatedBy]                       VARCHAR (256) NOT NULL,
    [UpdatedBy]                       VARCHAR (256) NOT NULL,
    [CreatedDate]                     DATETIME2 (7) NOT NULL,
    [UpdatedDate]                     DATETIME2 (7) NOT NULL,
    [IsActive]                        BIT           NOT NULL,
    [IsDeleted]                       BIT           NOT NULL,
    [MasterCompanyId]                 INT           NULL,
    CONSTRAINT [PK_GLAccountEntitiesMappingAudit] PRIMARY KEY CLUSTERED ([GLAccountEntitiesMappingAuditId] ASC)
);

