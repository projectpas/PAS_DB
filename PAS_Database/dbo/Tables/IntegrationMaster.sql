CREATE TABLE [dbo].[IntegrationMaster] (
    [IntegrationMasterId] BIGINT         IDENTITY (1, 1) NOT NULL,
    [PartNumber]          VARCHAR (200)  NULL,
    [PartDescription]     NVARCHAR (MAX) NULL,
    [Location]            VARCHAR (50)   NULL,
    [RepairStation]       VARCHAR (100)  NULL,
    [IsRepair]            BIT            NULL,
    [PhoneNumber]         VARCHAR (20)   NULL,
    [IntegrationPortalId] INT            NULL,
    [IntegrationPortal]   VARCHAR (50)   NULL,
    [MasterCompanyId]     INT            NOT NULL,
    [CreatedBy]           VARCHAR (256)  NULL,
    [UpdatedBy]           VARCHAR (256)  NULL,
    [CreatedDate]         DATETIME2 (7)  CONSTRAINT [DF_IntegrationMaster_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]         DATETIME2 (7)  CONSTRAINT [DF_IntegrationMaster_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsDeleted]           BIT            CONSTRAINT [DF_IntegrationMaster_IsDeleted] DEFAULT ((0)) NULL,
    [IsActive]            BIT            CONSTRAINT [DF_Table_1_IsDeleted1] DEFAULT ((0)) NULL,
    CONSTRAINT [PK_IntegrationMaster] PRIMARY KEY CLUSTERED ([IntegrationMasterId] ASC)
);

