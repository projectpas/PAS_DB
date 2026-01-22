CREATE TABLE [dbo].[VendorContactATAMappingAudit] (
    [AuditVendorContactATAMappingId] BIGINT        IDENTITY (1, 1) NOT NULL,
    [VendorContactATAMappingId]      BIGINT        NOT NULL,
    [VendorId]                       BIGINT        NOT NULL,
    [VendorContactId]                BIGINT        NOT NULL,
    [ATAChapterId]                   BIGINT        NOT NULL,
    [ATASubChapterId]                BIGINT        NULL,
    [MasterCompanyId]                INT           NOT NULL,
    [CreatedBy]                      VARCHAR (256) NOT NULL,
    [UpdatedBy]                      VARCHAR (256) NOT NULL,
    [CreatedDate]                    DATETIME2 (7) NOT NULL,
    [UpdatedDate]                    DATETIME2 (7) NOT NULL,
    [IsActive]                       BIT           NOT NULL,
    [IsDeleted]                      BIT           NOT NULL,
    [Level1]                         VARCHAR (50)  NULL,
    [Level2]                         VARCHAR (50)  NULL,
    [Level3]                         VARCHAR (50)  NULL,
    CONSTRAINT [PK_VendorContactATAMappingAudit] PRIMARY KEY CLUSTERED ([AuditVendorContactATAMappingId] ASC),
    CONSTRAINT [FK_VendorContactATAMappingAudit_VendorContactATAMapping] FOREIGN KEY ([VendorContactATAMappingId]) REFERENCES [dbo].[VendorContactATAMapping] ([VendorContactATAMappingId])
);

