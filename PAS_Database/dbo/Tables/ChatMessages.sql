CREATE TABLE [dbo].[ChatMessages] (
    [Id]             BIGINT           IDENTITY (1, 1) NOT NULL,
    [ConversationId] UNIQUEIDENTIFIER NOT NULL,
    [Role]           NVARCHAR (20)    NOT NULL,
    [ContentJson]    NVARCHAR (MAX)   NOT NULL,
    [CreatedAt]      DATETIME2 (7)    DEFAULT (sysutcdatetime()) NOT NULL,
    PRIMARY KEY CLUSTERED ([Id] ASC),
    FOREIGN KEY ([ConversationId]) REFERENCES [dbo].[ChatConversations] ([Id])
);

