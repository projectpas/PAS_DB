CREATE TABLE [dbo].[IntegrationStatus] (
    [IntegrationStatusId] INT           IDENTITY (1, 1) NOT NULL,
    [IntegrationStatus]   VARCHAR (50)  NOT NULL,
    [MasterCompanyId]     INT           NOT NULL,
    [CreatedBy]           VARCHAR (256) NOT NULL,
    [UpdatedBy]           VARCHAR (256) NOT NULL,
    [CreatedDate]         DATETIME2 (7) CONSTRAINT [DF_IntegrationStatus_CreatedDate] DEFAULT (getutcdate()) NOT NULL,
    [UpdatedDate]         DATETIME2 (7) CONSTRAINT [DF_IntegrationStatus_UpdatedDate] DEFAULT (getutcdate()) NOT NULL,
    [IsActive]            BIT           CONSTRAINT [DF_IntegrationStatus_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]           BIT           CONSTRAINT [DF_IntegrationStatus_IsDeleted] DEFAULT ((0)) NOT NULL,
    [Code]                VARCHAR (20)  NOT NULL,
    CONSTRAINT [PK_IntegrationStatus] PRIMARY KEY CLUSTERED ([IntegrationStatusId] ASC)
);

