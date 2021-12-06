CREATE TABLE [dbo].[ItemMasterATAMappingAudit] (
    [AuditItemMasterATAMappingId] BIGINT        IDENTITY (1, 1) NOT NULL,
    [ItemMasterATAMappingId]      BIGINT        NOT NULL,
    [ItemMasterId]                BIGINT        NOT NULL,
    [PartNumber]                  VARCHAR (50)  NOT NULL,
    [ATAChapterId]                BIGINT        NOT NULL,
    [ATAChapterCode]              VARCHAR (250) NOT NULL,
    [ATAChapterName]              VARCHAR (250) NOT NULL,
    [ATASubChapterId]             BIGINT        NULL,
    [ATASubChapterDescription]    VARCHAR (250) NULL,
    [MasterCompanyId]             INT           NOT NULL,
    [CreatedBy]                   VARCHAR (256) NOT NULL,
    [UpdatedBy]                   VARCHAR (256) NOT NULL,
    [CreatedDate]                 DATETIME2 (7) NULL,
    [UpdatedDate]                 DATETIME2 (7) NULL,
    [IsActive]                    BIT           NOT NULL,
    [IsDeleted]                   BIT           NOT NULL,
    CONSTRAINT [PK_ItemMasterATAMappingAudit] PRIMARY KEY CLUSTERED ([AuditItemMasterATAMappingId] ASC)
);

