CREATE TABLE [dbo].[AgentConversation] (
    [AgentConversationId] BIGINT         IDENTITY (1, 1) NOT NULL,
    [MasterCompanyId]     INT            NOT NULL,
    [UserId]              NVARCHAR (450) NOT NULL,
    [EmployeeId]          BIGINT         NULL,
    [Title]               NVARCHAR (200) NULL,
    [Model]               VARCHAR (100)  NULL,
    [CreatedBy]           VARCHAR (256)  NOT NULL,
    [CreatedDate]         DATETIME2 (7)  CONSTRAINT [DF_AgentConversation_CreatedDate] DEFAULT (getutcdate()) NOT NULL,
    [UpdatedDate]         DATETIME2 (7)  CONSTRAINT [DF_AgentConversation_UpdatedDate] DEFAULT (getutcdate()) NOT NULL,
    [IsDeleted]           BIT            CONSTRAINT [DF_AgentConversation_IsDeleted] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_AgentConversation] PRIMARY KEY CLUSTERED ([AgentConversationId] ASC)
);


GO
CREATE NONCLUSTERED INDEX [IX_AgentConversation_User]
    ON [dbo].[AgentConversation]([MasterCompanyId] ASC, [UserId] ASC, [IsDeleted] ASC, [UpdatedDate] DESC);

