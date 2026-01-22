CREATE TABLE [dbo].[SingleScreenFieldChildren] (
    [SingleScreenFieldChildrenId] BIGINT        IDENTITY (1, 1) NOT NULL,
    [SingleScreenFieldId]         BIGINT        NULL,
    [Children]                    VARCHAR (100) NULL,
    CONSTRAINT [PK_SingleScreenFieldChildren] PRIMARY KEY CLUSTERED ([SingleScreenFieldChildrenId] ASC),
    CONSTRAINT [FK_SingleScreenFieldChildren_SingleScreenField] FOREIGN KEY ([SingleScreenFieldId]) REFERENCES [dbo].[SingleScreenField] ([SingleScreenFieldId])
);

