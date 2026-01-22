CREATE TABLE [dbo].[IntegrationEmailSmtpConfigration] (
    [IntegrationEmailConfigId] BIGINT         IDENTITY (1, 1) NOT NULL,
    [SmtpUserEmail]            NVARCHAR (MAX) NOT NULL,
    [smtpserver]               NVARCHAR (500) NULL,
    [SmtpEmailPassword]        NVARCHAR (500) NULL,
    [SmtpPort]                 INT            NULL,
    [UseSsl]                   BIT            NULL,
    [MasterCompanyId]          INT            NOT NULL,
    [CreatedBy]                VARCHAR (256)  NOT NULL,
    [UpdatedBy]                VARCHAR (256)  NOT NULL,
    [CreatedDate]              DATETIME2 (7)  CONSTRAINT [DF_IntegrationEmailSmtpConfigration_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]              DATETIME2 (7)  CONSTRAINT [DF_IntegrationEmailSmtpConfigration_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]                 BIT            CONSTRAINT [DF_IntegrationEmailSmtpConfigration_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]                BIT            CONSTRAINT [DF_IntegrationEmailSmtpConfigration_IsDeleted] DEFAULT ((0)) NOT NULL,
    [AuthTypeId]               INT            NULL,
    [EmployeeId]               BIGINT         NULL,
    [AccessToken]              VARCHAR (MAX)  NULL,
    [RefreshToken]             VARCHAR (MAX)  NULL,
    [TokenExpiresIn]           INT            NULL,
    [TokenCreatedAt]           DATETIME2 (7)  NULL,
    CONSTRAINT [PK_IntegrationEmailSmtpConfigration] PRIMARY KEY CLUSTERED ([IntegrationEmailConfigId] ASC)
);

