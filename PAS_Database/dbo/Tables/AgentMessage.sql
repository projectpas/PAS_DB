CREATE TABLE [dbo].[AgentMessage] (
    [AgentMessageId]           BIGINT         IDENTITY (1, 1) NOT NULL,
    [AgentConversationId]      BIGINT         NOT NULL,
    [Role]                     VARCHAR (20)   NOT NULL,   -- user | assistant
    [Content]                  NVARCHAR (MAX) NOT NULL,
    [ToolCalls]                NVARCHAR (MAX) NULL,       -- JSON audit of tools run for this answer
    [Model]                    VARCHAR (100)  NULL,
    [StopReason]               VARCHAR (50)   NULL,
    [InputTokens]              INT            NULL,
    [OutputTokens]             INT            NULL,
    [CacheReadInputTokens]     INT            NULL,
    [CacheCreationInputTokens] INT            NULL,
    [DurationMs]               INT            NULL,
    [Feedback]                 SMALLINT       NULL,       -- 1 = thumbs up, -1 = thumbs down
    [CreatedDate]              DATETIME2 (7)  CONSTRAINT [DF_AgentMessage_CreatedDate] DEFAULT (getutcdate()) NOT NULL,
    CONSTRAINT [PK_AgentMessage] PRIMARY KEY CLUSTERED ([AgentMessageId] ASC),
    CONSTRAINT [FK_AgentMessage_AgentConversation] FOREIGN KEY ([AgentConversationId]) REFERENCES [dbo].[AgentConversation] ([AgentConversationId])
);


GO
CREATE NONCLUSTERED INDEX [IX_AgentMessage_Conversation]
    ON [dbo].[AgentMessage]([AgentConversationId] ASC, [AgentMessageId] ASC);

