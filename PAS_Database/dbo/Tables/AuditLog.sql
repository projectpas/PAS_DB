CREATE TABLE [dbo].[AuditLog] (
    [AuditId]      BIGINT         IDENTITY (1, 1) NOT NULL,
    [DatabaseName] [sysname]      DEFAULT (db_name()) NOT NULL,
    [SchemaName]   [sysname]      NOT NULL,
    [TableName]    [sysname]      NOT NULL,
    [PKJson]       NVARCHAR (MAX) NOT NULL,
    [ColumnName]   [sysname]      NOT NULL,
    [Action]       CHAR (1)       NOT NULL,
    [OldValue]     NVARCHAR (MAX) NULL,
    [NewValue]     NVARCHAR (MAX) NULL,
    [UpdatedBy]    NVARCHAR (100) NULL,
    [ChangedBy]    [sysname]      DEFAULT (original_login()) NOT NULL,
    [ChangedAt]    DATETIME2 (3)  DEFAULT (sysdatetime()) NOT NULL,
    [HostName]     [sysname]      DEFAULT (host_name()) NOT NULL,
    [AppName]      NVARCHAR (128) DEFAULT (app_name()) NOT NULL,
    [SessionId]    INT            DEFAULT (@@spid) NOT NULL,
    PRIMARY KEY CLUSTERED ([AuditId] ASC)
);


GO
CREATE NONCLUSTERED INDEX [IX_AuditLog_PK_Column]
    ON [dbo].[AuditLog]([TableName] ASC, [ColumnName] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_AuditLog_Table_Time]
    ON [dbo].[AuditLog]([SchemaName] ASC, [TableName] ASC, [ChangedAt] ASC);

