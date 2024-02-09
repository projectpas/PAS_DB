CREATE TABLE [dbo].[IntegrationRFQType] (
    [IntegrationRFQTypeId] INT           IDENTITY (1, 1) NOT NULL,
    [Description]          VARCHAR (50)  NULL,
    [Type]                 VARCHAR (50)  NULL,
    [Code]                 VARCHAR (50)  NULL,
    [MasterCompanyId]      INT           NOT NULL,
    [CreatedBy]            VARCHAR (256) NULL,
    [UpdatedBy]            VARCHAR (256) NULL,
    [CreatedDate]          DATETIME2 (7) CONSTRAINT [DF_IntegrationRFQType_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]          DATETIME2 (7) CONSTRAINT [DF_IntegrationRFQType_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsDeleted]            BIT           CONSTRAINT [DF_IntegrationRFQType_IsDeleted] DEFAULT ((0)) NULL,
    [IsActive]             BIT           CONSTRAINT [DF_IntegrationRFQType_IsActive] DEFAULT ((0)) NULL,
    CONSTRAINT [PK_IntegrationRFQType] PRIMARY KEY CLUSTERED ([IntegrationRFQTypeId] ASC)
);

