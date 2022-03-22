CREATE TABLE [dbo].[Log] (
    [Id]              INT            IDENTITY (1, 1) NOT NULL,
    [Message]         NVARCHAR (MAX) NULL,
    [MessageTemplate] NVARCHAR (MAX) NULL,
    [Level]           NVARCHAR (128) NULL,
    [TimeStamp]       DATETIME       NOT NULL,
    [Exception]       NVARCHAR (MAX) NULL,
    [Properties]      NVARCHAR (MAX) NULL,
    CONSTRAINT [PK_Log] PRIMARY KEY CLUSTERED ([Id] ASC)
);

