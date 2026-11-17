CREATE TABLE [dbo].[ChatConversations] (
    [Id]        UNIQUEIDENTIFIER DEFAULT (newid()) NOT NULL,
    [UserId]    INT              NOT NULL,
    [Title]     NVARCHAR (200)   NULL,
    [CreatedAt] DATETIME2 (7)    DEFAULT (sysutcdatetime()) NOT NULL,
    PRIMARY KEY CLUSTERED ([Id] ASC)
);

