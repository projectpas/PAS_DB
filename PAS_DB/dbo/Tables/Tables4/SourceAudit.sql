CREATE TABLE [dbo].[SourceAudit] (
    [AuditSourceId]   BIGINT         IDENTITY (1, 1) NOT NULL,
    [SourceId]        BIGINT         NOT NULL,
    [SourceName]      VARCHAR (256)  NOT NULL,
    [Description]     VARCHAR (MAX)  NULL,
    [Memo]            NVARCHAR (MAX) NULL,
    [MasterCompanyId] INT            NOT NULL,
    [CreatedBy]       VARCHAR (256)  NOT NULL,
    [UpdatedBy]       VARCHAR (256)  NOT NULL,
    [CreatedDate]     DATETIME2 (7)  NOT NULL,
    [UpdatedDate]     DATETIME2 (7)  NOT NULL,
    [IsActive]        BIT            NOT NULL,
    [IsDeleted]       BIT            NOT NULL,
    CONSTRAINT [PK_SourceAudit] PRIMARY KEY CLUSTERED ([AuditSourceId] ASC)
);

