CREATE TABLE [dbo].[ManagementSiteAudit] (
    [ManagementSiteAuditId] BIGINT        IDENTITY (1, 1) NOT NULL,
    [ManagementSiteId]      BIGINT        NOT NULL,
    [ManagementStructureId] BIGINT        NOT NULL,
    [SiteId]                BIGINT        NOT NULL,
    [MasterCompanyId]       INT           NOT NULL,
    [CreatedBy]             VARCHAR (256) NOT NULL,
    [UpdatedBy]             VARCHAR (256) NOT NULL,
    [CreatedDate]           DATETIME2 (7) NOT NULL,
    [UpdatedDate]           DATETIME2 (7) NOT NULL,
    [IsActive]              BIT           NOT NULL,
    [IsDeleted]             BIT           NOT NULL,
    CONSTRAINT [PK_ManagementSiteAudit] PRIMARY KEY CLUSTERED ([ManagementSiteAuditId] ASC)
);

