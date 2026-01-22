CREATE TABLE [dbo].[ManagementLocationAudit] (
    [ManagementLocationAuditId] BIGINT        IDENTITY (1, 1) NOT NULL,
    [ManagementLocationId]      BIGINT        NOT NULL,
    [ManagementStructureId]     BIGINT        NOT NULL,
    [LocationId]                BIGINT        NOT NULL,
    [MasterCompanyId]           INT           NOT NULL,
    [CreatedBy]                 VARCHAR (256) NOT NULL,
    [UpdatedBy]                 VARCHAR (256) NOT NULL,
    [CreatedDate]               DATETIME2 (7) NOT NULL,
    [UpdatedDate]               DATETIME2 (7) NOT NULL,
    [IsActive]                  BIT           NOT NULL,
    [IsDeleted]                 BIT           NOT NULL,
    CONSTRAINT [PK_ManagementLocationAudit] PRIMARY KEY CLUSTERED ([ManagementLocationAuditId] ASC)
);

