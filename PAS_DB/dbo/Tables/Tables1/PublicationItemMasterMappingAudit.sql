CREATE TABLE [dbo].[PublicationItemMasterMappingAudit] (
    [PublicationItemMasterMappingAuditId] BIGINT        IDENTITY (1, 1) NOT NULL,
    [PublicationItemMasterMappingId]      BIGINT        NOT NULL,
    [PublicationRecordId]                 BIGINT        NOT NULL,
    [ItemMasterId]                        BIGINT        NOT NULL,
    [MasterCompanyId]                     INT           NOT NULL,
    [CreatedBy]                           VARCHAR (256) NOT NULL,
    [UpdatedBy]                           VARCHAR (256) NOT NULL,
    [CreatedDate]                         DATETIME2 (7) NOT NULL,
    [UpdatedDate]                         DATETIME2 (7) NOT NULL,
    [IsActive]                            BIT           NOT NULL,
    [IsDeleted]                           BIT           NOT NULL,
    CONSTRAINT [PK_PublicationItemMasterMappingAudit] PRIMARY KEY CLUSTERED ([PublicationItemMasterMappingAuditId] ASC)
);

