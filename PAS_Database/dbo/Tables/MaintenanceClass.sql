CREATE TABLE [dbo].[MaintenanceClass] (
    [MaintenanceClassId] BIGINT        IDENTITY (1, 1) NOT NULL,
    [Name]               VARCHAR (256) NOT NULL,
    [Description]        VARCHAR (MAX) NULL,
    [MasterCompanyId]    INT           NOT NULL,
    [CreatedBy]          VARCHAR (256) NOT NULL,
    [UpdatedBy]          VARCHAR (256) NOT NULL,
    [CreatedDate]        DATETIME2 (7) CONSTRAINT [DF_MaintenanceClass_CreatedDate] DEFAULT (sysdatetime()) NOT NULL,
    [UpdatedDate]        DATETIME2 (7) CONSTRAINT [DF_MaintenanceClass_UpdatedDate] DEFAULT (sysdatetime()) NOT NULL,
    [IsActive]           BIT           CONSTRAINT [DF_MaintenanceClass_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]          BIT           CONSTRAINT [DF_MaintenanceClass_IsDeleted] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_MaintenanceClass] PRIMARY KEY CLUSTERED ([MaintenanceClassId] ASC)
);

