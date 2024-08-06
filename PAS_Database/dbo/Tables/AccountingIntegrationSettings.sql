CREATE TABLE [dbo].[AccountingIntegrationSettings] (
    [AccountingIntegrationSettingsId] BIGINT        IDENTITY (1, 1) NOT NULL,
    [IntegrationId]                   INT           NOT NULL,
    [IntegrationWith]                 VARCHAR (200) NULL,
    [LastRun]                         DATETIME2 (7) NOT NULL,
    [Interval]                        INT           NOT NULL,
    [ModuleId]                        BIGINT        NULL,
    [ModuleName]                      VARCHAR (200) NULL,
    [MasterCompanyId]                 INT           NOT NULL,
    [CreatedBy]                       VARCHAR (256) NOT NULL,
    [UpdatedBy]                       VARCHAR (256) NOT NULL,
    [CreatedDate]                     DATETIME2 (7) NOT NULL,
    [UpdatedDate]                     DATETIME2 (7) NOT NULL,
    [IsActive]                        BIT           NOT NULL,
    [IsDeleted]                       BIT           NOT NULL,
    CONSTRAINT [PK_AccountingIntegrationSettings] PRIMARY KEY CLUSTERED ([AccountingIntegrationSettingsId] ASC)
);



