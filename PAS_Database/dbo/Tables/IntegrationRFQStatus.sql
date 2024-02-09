CREATE TABLE [dbo].[IntegrationRFQStatus] (
    [IntegrationRFQStatusId] INT           IDENTITY (1, 1) NOT NULL,
    [Description]            VARCHAR (50)  NULL,
    [Status]                 VARCHAR (50)  NULL,
    [Code]                   VARCHAR (50)  NULL,
    [MasterCompanyId]        INT           NOT NULL,
    [CreatedBy]              VARCHAR (256) NULL,
    [UpdatedBy]              VARCHAR (256) NULL,
    [CreatedDate]            DATETIME2 (7) CONSTRAINT [DF_IntegrationRFQStatus_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]            DATETIME2 (7) CONSTRAINT [DF_IntegrationRFQStatus_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsDeleted]              BIT           CONSTRAINT [DF_IntegrationRFQStatus_IsDeleted] DEFAULT ((0)) NULL,
    [IsActive]               BIT           CONSTRAINT [DF_IntegrationRFQStatus_IsActive] DEFAULT ((0)) NULL,
    CONSTRAINT [PK_IntegrationRFQStatus] PRIMARY KEY CLUSTERED ([IntegrationRFQStatusId] ASC)
);

