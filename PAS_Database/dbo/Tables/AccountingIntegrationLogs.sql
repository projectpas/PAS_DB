CREATE TABLE [dbo].[AccountingIntegrationLogs] (
    [AccountingIntegrationLogsId] BIGINT        IDENTITY (1, 1) NOT NULL,
    [IntegrationId]               INT           NOT NULL,
    [ModuleId]                    BIGINT        NOT NULL,
    [ReferenceId]                 BIGINT        NOT NULL,
    [ModuleName]                  VARCHAR (200) NOT NULL,
    [Payload]                     VARCHAR (MAX) NULL,
    [MasterCompanyId]             INT           NOT NULL,
    [CreatedBy]                   VARCHAR (256) NOT NULL,
    [UpdatedBy]                   VARCHAR (256) NOT NULL,
    [CreatedDate]                 DATETIME2 (7) NOT NULL,
    [UpdatedDate]                 DATETIME2 (7) NOT NULL,
    [IsActive]                    BIT           NOT NULL,
    [IsDeleted]                   BIT           NOT NULL,
    CONSTRAINT [PK_AccountingIntegrationLogs] PRIMARY KEY CLUSTERED ([AccountingIntegrationLogsId] ASC)
);

