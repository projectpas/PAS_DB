CREATE TABLE [dbo].[ExternalUserSession] (
    [ExternalUserSessionId] BIGINT        IDENTITY (1, 1) NOT NULL,
    [ExternalUserId]        BIGINT        NOT NULL,
    [JwtId]                 VARCHAR (100) NOT NULL,
    [ExpiresAt]             DATETIME2 (7) NOT NULL,
    [CreatedDate]           DATETIME2 (7) CONSTRAINT [DF_ExternalUserSession_CreatedDate] DEFAULT (getutcdate()) NOT NULL,
    CONSTRAINT [PK_ExternalUserSession] PRIMARY KEY CLUSTERED ([ExternalUserSessionId] ASC),
    CONSTRAINT [FK_ExternalUserSession_ExternalUser] FOREIGN KEY ([ExternalUserId]) REFERENCES [dbo].[ExternalUser] ([ExternalUserId])
);


GO
CREATE UNIQUE NONCLUSTERED INDEX [UX_ExternalUserSession_JwtId]
    ON [dbo].[ExternalUserSession]([JwtId] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_ExternalUserSession_ExternalUserId]
    ON [dbo].[ExternalUserSession]([ExternalUserId] ASC);

