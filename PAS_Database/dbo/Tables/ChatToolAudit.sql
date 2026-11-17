CREATE TABLE [dbo].[ChatToolAudit] (
    [Id]             BIGINT           IDENTITY (1, 1) NOT NULL,
    [ConversationId] UNIQUEIDENTIFIER NOT NULL,
    [UserId]         INT              NOT NULL,
    [ToolName]       NVARCHAR (100)   NOT NULL,
    [InputJson]      NVARCHAR (MAX)   NOT NULL,
    [Succeeded]      BIT              NOT NULL,
    [CreatedAt]      DATETIME2 (7)    DEFAULT (sysutcdatetime()) NOT NULL,
    PRIMARY KEY CLUSTERED ([Id] ASC)
);

