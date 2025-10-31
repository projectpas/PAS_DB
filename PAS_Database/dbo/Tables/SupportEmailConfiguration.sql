CREATE TABLE [dbo].[SupportEmailConfiguration] (
    [SupportEmailConfigurationId] INT            IDENTITY (1, 1) NOT NULL,
    [SmtpUserEmail]               NVARCHAR (MAX) NOT NULL,
    [smtpserver]                  NVARCHAR (500) NULL,
    [SmtpEmailPassword]           NVARCHAR (500) NULL,
    [SmtpPort]                    INT            NULL,
    [UseSsl]                      BIT            NULL,
    [MasterCompanyId]             INT            NOT NULL,
    [CreatedBy]                   VARCHAR (256)  NOT NULL,
    [UpdatedBy]                   VARCHAR (256)  NOT NULL,
    [CreatedDate]                 DATETIME2 (7)  CONSTRAINT [DF_SupportEmailConfiguration_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]                 DATETIME2 (7)  CONSTRAINT [DF_SupportEmailConfiguration_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]                    BIT            CONSTRAINT [DF_SupportEmailConfiguration_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]                   BIT            CONSTRAINT [DF_SupportEmailConfiguration_IsDeleted] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_SupportEmailConfiguration] PRIMARY KEY CLUSTERED ([SupportEmailConfigurationId] ASC)
);

