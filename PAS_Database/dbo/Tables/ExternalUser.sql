CREATE TABLE [dbo].[ExternalUser] (
    [ExternalUserId]    BIGINT         IDENTITY (1, 1) NOT NULL,
    [UserName]          NVARCHAR (256) NOT NULL,
    [PasswordHash]      NVARCHAR (MAX) NOT NULL,
    [FullName]          NVARCHAR (256) NULL,
    [Email]             NVARCHAR (256) NULL,
    [MasterCompanyId]   INT            NOT NULL,
    [AccessFailedCount] INT            CONSTRAINT [DF_ExternalUser_AccessFailedCount] DEFAULT ((0)) NOT NULL,
    [LockoutEnd]        DATETIME2 (7)  NULL,
    [LastLoginDate]     DATETIME2 (7)  NULL,
    [CreatedBy]         VARCHAR (256)  NOT NULL,
    [CreatedDate]       DATETIME2 (7)  CONSTRAINT [DF_ExternalUser_CreatedDate] DEFAULT (getutcdate()) NOT NULL,
    [UpdatedBy]         VARCHAR (256)  NOT NULL,
    [UpdatedDate]       DATETIME2 (7)  CONSTRAINT [DF_ExternalUser_UpdatedDate] DEFAULT (getutcdate()) NOT NULL,
    [IsActive]          BIT            CONSTRAINT [DF_ExternalUser_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]         BIT            CONSTRAINT [DF_ExternalUser_IsDeleted] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_ExternalUser] PRIMARY KEY CLUSTERED ([ExternalUserId] ASC),
    CONSTRAINT [FK_ExternalUser_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId])
);


GO
CREATE UNIQUE NONCLUSTERED INDEX [UX_ExternalUser_UserName]
    ON [dbo].[ExternalUser]([UserName] ASC);

