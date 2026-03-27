CREATE TABLE [dbo].[MaintenanceStatus] (
    [MaintenanceStatusId] BIGINT        IDENTITY (1, 1) NOT NULL,
    [Name]                VARCHAR (100) NOT NULL,
    [Description]         VARCHAR (500) NULL,
    [SequenceNo]          INT           NULL,
    [MasterCompanyId]     INT           NOT NULL,
    [CreatedBy]           VARCHAR (256) NOT NULL,
    [UpdatedBy]           VARCHAR (256) NOT NULL,
    [CreatedDate]         DATETIME2 (7) CONSTRAINT [DF_MaintenanceStatus_CreatedDate] DEFAULT (sysdatetime()) NOT NULL,
    [UpdatedDate]         DATETIME2 (7) CONSTRAINT [DF_MaintenanceStatus_UpdatedDate] DEFAULT (sysdatetime()) NOT NULL,
    [IsActive]            BIT           CONSTRAINT [DF_MaintenanceStatus_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]           BIT           CONSTRAINT [DF_MaintenanceStatus_IsDeleted] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_MaintenanceStatus] PRIMARY KEY CLUSTERED ([MaintenanceStatusId] ASC),
    CONSTRAINT [FK_MaintenanceStatus_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [UQ_MaintenanceStatus_Name_MasterCompany] UNIQUE NONCLUSTERED ([Name] ASC, [MasterCompanyId] ASC)
);

