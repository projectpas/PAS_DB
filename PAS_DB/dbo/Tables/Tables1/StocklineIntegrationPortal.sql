CREATE TABLE [dbo].[StocklineIntegrationPortal] (
    [StocklineIntegrationPortalId] BIGINT        IDENTITY (1, 1) NOT NULL,
    [StocklineId]                  BIGINT        NOT NULL,
    [IntegrationPortalId]          INT           NOT NULL,
    [MasterCompanyId]              INT           NOT NULL,
    [CreatedBy]                    VARCHAR (256) NULL,
    [UpdatedBy]                    VARCHAR (256) NULL,
    [CreatedDate]                  DATETIME2 (7) CONSTRAINT [DF_StocklineIntegrationPortal_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]                  DATETIME2 (7) CONSTRAINT [DF_StocklineIntegrationPortal_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]                     BIT           CONSTRAINT [DF_StocklineIntegrationPortal_IsActive] DEFAULT ((1)) NULL,
    [IsListed]                     BIT           NULL,
    CONSTRAINT [PK_StocklineIntegrationPortal] PRIMARY KEY CLUSTERED ([StocklineIntegrationPortalId] ASC),
    CONSTRAINT [FK_StocklineIntegrationPortal_IntegrationPortal] FOREIGN KEY ([IntegrationPortalId]) REFERENCES [dbo].[IntegrationPortal] ([IntegrationPortalId]),
    CONSTRAINT [FK_StocklineIntegrationPortal_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [FK_StocklineIntegrationPortal_Stockline] FOREIGN KEY ([StocklineId]) REFERENCES [dbo].[Stockline] ([StockLineId])
);

