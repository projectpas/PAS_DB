CREATE TABLE [dbo].[AccountingIntegrationType] (
    [IntegrationTypeId] INT           IDENTITY (1, 1) NOT NULL,
    [IntegrationType]   VARCHAR (150) NOT NULL,
    [MasterCompanyId]   INT           NOT NULL,
    [CreatedBy]         VARCHAR (50)  NOT NULL,
    [CreatedDate]       DATETIME2 (7) CONSTRAINT [DF_AccountingIntegrationType_CreatedDate] DEFAULT (getutcdate()) NOT NULL,
    [UpdatedBy]         VARCHAR (50)  NOT NULL,
    [UpdatedDate]       DATETIME2 (7) CONSTRAINT [DF_AccountingIntegrationType_UpdatedDate] DEFAULT (getutcdate()) NOT NULL,
    [IsActive]          BIT           CONSTRAINT [DF_AccountingIntegrationType_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]         BIT           CONSTRAINT [DF_AccountingIntegrationType_IsDeleted] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_AccountingIntegrationType] PRIMARY KEY CLUSTERED ([IntegrationTypeId] ASC)
);

