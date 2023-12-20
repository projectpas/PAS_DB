CREATE TABLE [dbo].[ItemMasterIntegrationPortalAudit] (
    [ItemMasterIntegrationPortalAuditId] BIGINT        IDENTITY (1, 1) NOT NULL,
    [ItemMasterIntegrationPortalId]      BIGINT        NOT NULL,
    [ItemMasterId]                       BIGINT        NOT NULL,
    [IntegrationPortalId]                INT           NOT NULL,
    [MasterCompanyId]                    INT           NOT NULL,
    [CreatedBy]                          VARCHAR (256) NULL,
    [UpdatedBy]                          VARCHAR (256) NULL,
    [CreatedDate]                        DATETIME2 (7) NOT NULL,
    [UpdatedDate]                        DATETIME2 (7) NOT NULL,
    [IsActive]                           BIT           NULL,
    [IsDeleted]                          BIT           CONSTRAINT [DF_ItemMasterIntegrationPortalAudit_IsDeleted] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_ItemMasterIntegrationPortalAudit] PRIMARY KEY CLUSTERED ([ItemMasterIntegrationPortalAuditId] ASC)
);

