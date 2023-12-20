CREATE TABLE [dbo].[DataBaseChangesLog] (
    [Id]           BIGINT        IDENTITY (1, 1) NOT NULL,
    [databasename] VARCHAR (256) NULL,
    [eventtype]    VARCHAR (256) NULL,
    [objectname]   VARCHAR (256) NULL,
    [objecttype]   VARCHAR (256) NULL,
    [sqlcommand]   VARCHAR (MAX) NULL,
    [loginname]    VARCHAR (256) NULL
);

