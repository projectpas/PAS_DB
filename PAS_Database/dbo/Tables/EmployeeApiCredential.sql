CREATE TABLE [dbo].[EmployeeApiCredential] (
    [EmployeeApiCredentialId] BIGINT        IDENTITY (1, 1) NOT NULL,
    [EmployeeId]              BIGINT        NOT NULL,
    [MasterCompanyId]         INT           NOT NULL,
    [ClientId]                VARCHAR (100) NOT NULL,
    [ClientSecretHash]        VARCHAR (256) NOT NULL,
    [IsApiAccessEnabled]      BIT           CONSTRAINT [DF_EmployeeApiCredential_IsApiAccessEnabled] DEFAULT ((0)) NOT NULL,
    [CredentialVersion]       INT           CONSTRAINT [DF_EmployeeApiCredential_CredentialVersion] DEFAULT ((1)) NOT NULL,
    [SecretRotatedDate]       DATETIME2 (7) CONSTRAINT [DF_EmployeeApiCredential_SecretRotatedDate] DEFAULT (getutcdate()) NOT NULL,
    [CreatedBy]               VARCHAR (256) NOT NULL,
    [UpdatedBy]               VARCHAR (256) NOT NULL,
    [CreatedDate]             DATETIME2 (7) CONSTRAINT [DF_EmployeeApiCredential_CreatedDate] DEFAULT (getutcdate()) NOT NULL,
    [UpdatedDate]             DATETIME2 (7) CONSTRAINT [DF_EmployeeApiCredential_UpdatedDate] DEFAULT (getutcdate()) NOT NULL,
    CONSTRAINT [PK_EmployeeApiCredential] PRIMARY KEY CLUSTERED ([EmployeeApiCredentialId] ASC),
    CONSTRAINT [FK_EmployeeApiCredential_Employee] FOREIGN KEY ([EmployeeId]) REFERENCES [dbo].[Employee] ([EmployeeId]) ON DELETE CASCADE,
    CONSTRAINT [UQ_EmployeeApiCredential_ClientId] UNIQUE NONCLUSTERED ([ClientId] ASC),
    CONSTRAINT [UQ_EmployeeApiCredential_EmployeeId] UNIQUE NONCLUSTERED ([EmployeeId] ASC)
);

