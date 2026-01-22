CREATE TABLE [dbo].[FileSystemAudit] (
    [FileSystemAuditId] BIGINT         IDENTITY (1, 1) NOT NULL,
    [FileSystemId]      BIGINT         NOT NULL,
    [FilePath]          VARCHAR (1000) NOT NULL,
    [FileType]          VARCHAR (30)   NULL,
    [MasterCompanyId]   INT            NOT NULL,
    [CreatedBy]         VARCHAR (256)  NULL,
    [UpdatedBy]         VARCHAR (256)  NULL,
    [CreatedDate]       DATETIME2 (7)  NOT NULL,
    [UpdatedDate]       DATETIME2 (7)  NOT NULL,
    [IsActive]          BIT            NULL,
    CONSTRAINT [PK_FileSystemAudit] PRIMARY KEY CLUSTERED ([FileSystemAuditId] ASC)
);

