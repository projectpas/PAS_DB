CREATE TABLE [dbo].[AccountingIntegrationSetupAudit] (
    [AccountingIntegrationSetupAuditId] BIGINT         IDENTITY (1, 1) NOT NULL,
    [AccountingIntegrationSetupId]      INT            NOT NULL,
    [IntegrationId]                     INT            NOT NULL,
    [ClientId]                          VARCHAR (500)  NULL,
    [ClientSecret]                      VARCHAR (500)  NULL,
    [RedirectUrl]                       VARCHAR (5000) NULL,
    [Environment]                       VARCHAR (200)  NULL,
    [MasterCompanyId]                   INT            NOT NULL,
    [CreatedBy]                         VARCHAR (256)  NOT NULL,
    [UpdatedBy]                         VARCHAR (256)  NOT NULL,
    [CreatedDate]                       DATETIME2 (7)  CONSTRAINT [DF_AccountingIntegrationSetupAudit_CreatedDate] DEFAULT (getutcdate()) NOT NULL,
    [UpdatedDate]                       DATETIME2 (7)  CONSTRAINT [DF_AccountingIntegrationSetupAudit_UpdatedDate] DEFAULT (getutcdate()) NOT NULL,
    [IsActive]                          BIT            CONSTRAINT [DF__AccountingIntegrationSetupAudit__IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]                         BIT            CONSTRAINT [DF__AccountingIntegrationSetupAudit__IsDeleted] DEFAULT ((0)) NOT NULL,
    [IsEnabled]                         BIT            NULL,
    [APIKey]                            VARCHAR (500)  NULL,
    CONSTRAINT [PK_AccountingIntegrationSetupAudit] PRIMARY KEY CLUSTERED ([AccountingIntegrationSetupAuditId] ASC)
);

