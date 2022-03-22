CREATE TABLE [dbo].[POPartSplitUserType] (
    [POPartSplitUserTypeId] SMALLINT     IDENTITY (1, 1) NOT NULL,
    [Description]           VARCHAR (30) NOT NULL,
    CONSTRAINT [PK_POPartSplitUserType] PRIMARY KEY CLUSTERED ([POPartSplitUserTypeId] ASC)
);

