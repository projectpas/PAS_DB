CREATE TABLE [dbo].[IgnoreColumn] (
    [SchemaName] [sysname] NOT NULL,
    [TableName]  [sysname] NOT NULL,
    [ColumnName] [sysname] NOT NULL,
    CONSTRAINT [PK_IgnoreColumn] PRIMARY KEY CLUSTERED ([SchemaName] ASC, [TableName] ASC, [ColumnName] ASC)
);

