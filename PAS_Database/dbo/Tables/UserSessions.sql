CREATE TABLE [dbo].[UserSessions] (
    [UserSessionsId] BIGINT           IDENTITY (1, 1) NOT NULL,
    [UserId]         UNIQUEIDENTIFIER NULL,
    [JwtToken]       NVARCHAR (MAX)   NULL,
    [LastLoginTime]  DATETIME         NULL,
    [ClientType]     VARCHAR (100)    NULL,
    CONSTRAINT [PK_UserSessions] PRIMARY KEY CLUSTERED ([UserSessionsId] ASC)
);



