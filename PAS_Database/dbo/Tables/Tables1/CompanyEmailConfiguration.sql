CREATE TABLE [dbo].[CompanyEmailConfiguration] (
    [EmailSettingId]  BIGINT         IDENTITY (1, 1) NOT NULL,
    [MasterCompanyId] INT            NULL,
    [Host]            NVARCHAR (255) NULL,
    [Port]            INT            NULL,
    [IsSSLEnable]     BIT            NULL,
    [Name]            NVARCHAR (255) NULL,
    [FromEmail]       NVARCHAR (255) NULL,
    [Password]        NVARCHAR (255) NULL,
    [CreatedBy]       VARCHAR (256)  NULL,
    [CreatedDate]     DATETIME2 (7)  NULL,
    [UpdatedBy]       VARCHAR (256)  NULL,
    [UpdatedDate]     DATETIME2 (7)  NULL,
    [IsActive]        BIT            NULL,
    CONSTRAINT [PK_CompanyEmailConfiguration] PRIMARY KEY CLUSTERED ([EmailSettingId] ASC),
    CONSTRAINT [FK_CompanyEmailConfiguration_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId])
);

