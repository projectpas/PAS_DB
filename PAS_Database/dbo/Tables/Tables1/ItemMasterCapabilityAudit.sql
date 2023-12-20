CREATE TABLE [dbo].[ItemMasterCapabilityAudit] (
    [ItemMasterCapabilityAuditId] BIGINT        IDENTITY (1, 1) NOT NULL,
    [ItemMasterCapability]        BIGINT        NOT NULL,
    [ItemMasterId]                BIGINT        NOT NULL,
    [CapabilityId]                BIGINT        NOT NULL,
    [MasterCompanyId]             INT           NOT NULL,
    [CreatedBy]                   VARCHAR (256) NULL,
    [UpdatedBy]                   VARCHAR (256) NULL,
    [CreatedDate]                 DATETIME2 (7) NOT NULL,
    [UpdatedDate]                 DATETIME2 (7) NOT NULL,
    [IsActive]                    BIT           NULL,
    [IsDelete]                    BIT           NULL,
    CONSTRAINT [PK_ItemMasterCapabilityAudit] PRIMARY KEY CLUSTERED ([ItemMasterCapabilityAuditId] ASC)
);

