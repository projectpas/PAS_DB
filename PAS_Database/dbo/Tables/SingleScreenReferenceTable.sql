CREATE TABLE [dbo].[SingleScreenReferenceTable] (
    [SingleScreenReferenceTableId] BIGINT        IDENTITY (1, 1) NOT NULL,
    [SingleScreenId]               BIGINT        NULL,
    [tableName]                    VARCHAR (100) NULL,
    [priority]                     INT           NULL,
    CONSTRAINT [PK_SingleScreenReferenceTable] PRIMARY KEY CLUSTERED ([SingleScreenReferenceTableId] ASC),
    CONSTRAINT [FK_SingleScreenReferenceTable_SingleScreen] FOREIGN KEY ([SingleScreenId]) REFERENCES [dbo].[SingleScreen] ([SingleScreenId])
);

