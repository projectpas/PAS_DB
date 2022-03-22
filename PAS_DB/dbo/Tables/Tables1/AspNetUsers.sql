CREATE TABLE [dbo].[AspNetUsers] (
    [Id]                   NVARCHAR (450)     NOT NULL,
    [AccessFailedCount]    INT                NOT NULL,
    [ConcurrencyStamp]     NVARCHAR (MAX)     NULL,
    [Configuration]        NVARCHAR (MAX)     NULL,
    [CreatedBy]            NVARCHAR (MAX)     NULL,
    [CreatedDate]          DATETIME2 (7)      CONSTRAINT [DF_AspNetUsers_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [Email]                NVARCHAR (256)     NULL,
    [EmailConfirmed]       BIT                NOT NULL,
    [FullName]             NVARCHAR (MAX)     NULL,
    [IsEnabled]            BIT                NOT NULL,
    [JobTitle]             NVARCHAR (MAX)     NULL,
    [LockoutEnabled]       BIT                NOT NULL,
    [LockoutEnd]           DATETIMEOFFSET (7) NULL,
    [NormalizedEmail]      NVARCHAR (256)     NULL,
    [NormalizedUserName]   NVARCHAR (256)     NULL,
    [PasswordHash]         NVARCHAR (MAX)     NULL,
    [PhoneNumber]          NVARCHAR (MAX)     NULL,
    [PhoneNumberConfirmed] BIT                NOT NULL,
    [SecurityStamp]        NVARCHAR (MAX)     NULL,
    [TwoFactorEnabled]     BIT                NOT NULL,
    [UpdatedBy]            NVARCHAR (MAX)     NULL,
    [UpdatedDate]          DATETIME2 (7)      CONSTRAINT [DF_AspNetUsers_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [UserName]             NVARCHAR (256)     NULL,
    [EmployeeId]           BIGINT             NULL,
    [IsResetPassword]      BIT                NULL,
    [MasterCompanyId]      INT                NULL,
    CONSTRAINT [PK_AspNetUsers] PRIMARY KEY CLUSTERED ([Id] ASC)
);


GO
CREATE UNIQUE NONCLUSTERED INDEX [UserNameIndex]
    ON [dbo].[AspNetUsers]([NormalizedUserName] ASC) WHERE ([NormalizedUserName] IS NOT NULL);


GO
CREATE NONCLUSTERED INDEX [EmailIndex]
    ON [dbo].[AspNetUsers]([NormalizedEmail] ASC);

