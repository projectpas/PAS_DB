CREATE TABLE [dbo].[ManagementBinAudit] (
    [ManagementBinAuditId]  BIGINT        IDENTITY (1, 1) NOT NULL,
    [ManagementBinId]       BIGINT        NOT NULL,
    [ManagementStructureId] BIGINT        NOT NULL,
    [BinId]                 BIGINT        NOT NULL,
    [MasterCompanyId]       INT           NOT NULL,
    [CreatedBy]             VARCHAR (256) NOT NULL,
    [UpdatedBy]             VARCHAR (256) NOT NULL,
    [CreatedDate]           DATETIME2 (7) NOT NULL,
    [UpdatedDate]           DATETIME2 (7) NOT NULL,
    [IsActive]              BIT           NOT NULL,
    [IsDeleted]             BIT           NOT NULL,
    CONSTRAINT [PK_ManagementBinAudit] PRIMARY KEY CLUSTERED ([ManagementBinAuditId] ASC)
);

