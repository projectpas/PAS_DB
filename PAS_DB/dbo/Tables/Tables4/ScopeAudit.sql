CREATE TABLE [dbo].[ScopeAudit] (
    [ScopeAuditId] TINYINT       IDENTITY (1, 1) NOT NULL,
    [ScopeId]      TINYINT       NOT NULL,
    [Description]  VARCHAR (100) NOT NULL,
    [CreatedBy]    VARCHAR (256) NULL,
    [UpdatedBy]    VARCHAR (256) NULL,
    [CreatedDate]  DATETIME2 (7) NOT NULL,
    [UpdatedDate]  DATETIME2 (7) NOT NULL,
    [IsActive]     BIT           NULL,
    CONSTRAINT [PK_ScopeAudit] PRIMARY KEY CLUSTERED ([ScopeAuditId] ASC)
);

