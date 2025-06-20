CREATE TABLE [dbo].[UserTwoFactorVerification] (
    [Id]              BIGINT        IDENTITY (1, 1) NOT NULL,
    [UserId]          VARCHAR (256) NULL,
    [OtpCode]         VARCHAR (20)  NULL,
    [ExpiryTime]      DATETIME2 (7) NULL,
    [IsUsed]          BIT           NULL,
    [MasterCompanyId] INT           NULL,
    [CreatedBy]       VARCHAR (256) NULL,
    [CreatedDate]     DATETIME2 (7) CONSTRAINT [DF_UserTwoFactorVerification_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedBy]       VARCHAR (256) NULL,
    [UpdatedDate]     DATETIME2 (7) CONSTRAINT [DF_UserTwoFactorVerification_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]        BIT           CONSTRAINT [DF_UserTwoFactorVerification_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]       BIT           CONSTRAINT [DF_UserTwoFactorVerification_IsDeleted] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_UserTwoFactorVerification] PRIMARY KEY CLUSTERED ([Id] ASC)
);

