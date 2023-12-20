CREATE TABLE [dbo].[UserRoleMapper] (
    [Id]         BIGINT           IDENTITY (1, 1) NOT NULL,
    [UserId]     UNIQUEIDENTIFIER NOT NULL,
    [UserRoleId] BIGINT           NOT NULL,
    PRIMARY KEY CLUSTERED ([Id] ASC),
    FOREIGN KEY ([UserRoleId]) REFERENCES [dbo].[UserRole] ([Id])
);

