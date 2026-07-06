CREATE TABLE [dbo].[XeroTokens] (
    [Id]              BIGINT         IDENTITY (1, 1) NOT NULL,
    [AccessToken]     NVARCHAR (MAX) NULL,
    [RefreshToken]    NVARCHAR (MAX) NULL,
    [TenantId]        NVARCHAR (100) NULL,
    [ExpiresAt]       DATETIME2 (7)  NULL,
    [MasterCompanyId] INT            NULL,
    [CreatedDate]     DATETIME2 (7)  CONSTRAINT [DF_XeroTokens_CreatedDate] DEFAULT (getutcdate()) NOT NULL,
    PRIMARY KEY CLUSTERED ([Id] ASC)
);
