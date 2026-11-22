CREATE TABLE [dbo].[EmployeeApiToken] (
    [EmployeeApiTokenId] BIGINT         IDENTITY (1, 1) NOT NULL,
    [EmployeeId]         BIGINT         NOT NULL,
    [MasterCompanyId]    INT            NOT NULL,
    [ClientId]           VARCHAR (100)  NOT NULL,
    [TokenId]            VARCHAR (50)   NOT NULL,
    [IssuedDate]         DATETIME2 (7)  NOT NULL,
    [ExpiryDate]         DATETIME2 (7)  NOT NULL,
    [IsRevoked]          BIT            CONSTRAINT [DF_EmployeeApiToken_IsRevoked] DEFAULT ((0)) NOT NULL,
    [RevokedDate]        DATETIME2 (7)  NULL,
    [RevokedReason]      VARCHAR (100)  NULL,
    [IpAddress]          VARCHAR (50)   NULL,
    [UserAgent]          NVARCHAR (500) NULL,
    [CreatedDate]        DATETIME2 (7)  CONSTRAINT [DF_EmployeeApiToken_CreatedDate] DEFAULT (getutcdate()) NOT NULL,
    CONSTRAINT [PK_EmployeeApiToken] PRIMARY KEY CLUSTERED ([EmployeeApiTokenId] ASC),
    CONSTRAINT [FK_EmployeeApiToken_Employee] FOREIGN KEY ([EmployeeId]) REFERENCES [dbo].[Employee] ([EmployeeId]) ON DELETE CASCADE,
    CONSTRAINT [UQ_EmployeeApiToken_TokenId] UNIQUE NONCLUSTERED ([TokenId] ASC)
);


GO
CREATE NONCLUSTERED INDEX [IX_EmployeeApiToken_EmployeeId_IsRevoked]
    ON [dbo].[EmployeeApiToken]([EmployeeId] ASC, [IsRevoked] ASC);

