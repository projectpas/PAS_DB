CREATE TABLE [dbo].[IntegrationPortalMaster] (
    [IntegrationPortalMasterId] INT           IDENTITY (1, 1) NOT NULL,
    [Code]                      VARCHAR (256) NOT NULL,
    [Name]                      VARCHAR (256) NULL,
    [Description]               VARCHAR (MAX) NULL,
    [MasterCompanyId]           INT           NOT NULL,
    [CreatedBy]                 VARCHAR (256) NOT NULL,
    [UpdatedBy]                 VARCHAR (256) NOT NULL,
    [CreatedDate]               DATETIME2 (7) CONSTRAINT [IntegrationPortalMaster_DC_CDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]               DATETIME2 (7) CONSTRAINT [IntegrationPortalMaster_DC_UDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]                  BIT           CONSTRAINT [D_IntegrationPortalMaster_Active] DEFAULT ((1)) NOT NULL,
    [IsDeleted]                 BIT           CONSTRAINT [D_IntegrationPortalMaster_Delete] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_IntegrationPortalMaster] PRIMARY KEY CLUSTERED ([IntegrationPortalMasterId] ASC)
);

