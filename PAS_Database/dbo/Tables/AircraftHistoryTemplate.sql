CREATE TABLE [dbo].[AircraftHistoryTemplate] (
    [AircraftHistoryTemplateId] BIGINT         IDENTITY (1, 1) NOT NULL,
    [TemplateCode]              VARCHAR (100)  NOT NULL,
    [TemplateBody]              NVARCHAR (MAX) NOT NULL,
    [TemplateText]              NVARCHAR (500) NOT NULL,
    [TemplateIcon]              VARCHAR (100)  NULL,
    [MasterCompanyId]           INT            NOT NULL,
    [CreatedBy]                 VARCHAR (256)  NULL,
    [CreatedDate]               DATETIME2 (7)  CONSTRAINT [DF_AircraftHistoryTemplate_CreatedDate] DEFAULT (getutcdate()) NOT NULL,
    [UpdatedBy]                 VARCHAR (256)  NULL,
    [UpdatedDate]               DATETIME2 (7)  CONSTRAINT [DF_AircraftHistoryTemplate_UpdatedDate] DEFAULT (getutcdate()) NOT NULL,
    [IsActive]                  BIT            CONSTRAINT [DF_AircraftHistoryTemplate_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]                 BIT            CONSTRAINT [DF_AircraftHistoryTemplate_IsDeleted] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_AircraftHistoryTemplate] PRIMARY KEY CLUSTERED ([AircraftHistoryTemplateId] ASC)
);

