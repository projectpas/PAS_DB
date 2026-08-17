CREATE TABLE [dbo].[AircraftRegistryHeader] (
    [AircraftRegistryId]     BIGINT          IDENTITY (1, 1) NOT NULL,
    [MakeTypeId]             BIGINT          NOT NULL,
    [MakeType]               VARCHAR (100)   NULL,
    [AircraftModelId]        BIGINT          NULL,
    [AircraftModel]          VARCHAR (100)   NULL,
    [AircraftSubModel]       VARCHAR (100)   NULL,
    [NumOfEngines]           INT             NULL,
    [TailNum]                VARCHAR (50)    NOT NULL,
    [SerialNum]              VARCHAR (100)   NULL,
    [ManufacturedDate]       DATETIME2 (7)   NULL,
    [PlaceInServiceDate]     DATETIME2 (7)   NULL,
    [TotalTSN]               DECIMAL (18, 2) NULL,
    [TotalCSN]               DECIMAL (18, 2) NULL,
    [Hobbs]                  DECIMAL (18, 2) NULL,
    [AircraftLocation]       VARCHAR (200)   NULL,
    [NextScheduled]          DATETIME2 (7)   NULL,
    [MEL]                    BIT             NULL,
    [AircraftStatusId]       BIGINT          NULL,
    [AircraftStatus]         VARCHAR (100)   NULL,
    [MaintenanceStatusId]    BIGINT          NULL,
    [MaintenanceStatus]      VARCHAR (100)   NULL,
    [CustomerId]             BIGINT          NULL,
    [CustomerName]           VARCHAR (100)   NULL,
    [Memo]                   VARCHAR (MAX)   NULL,
    [StockLineId]            BIGINT          NULL,
    [IsActive]               BIT             CONSTRAINT [DF_AircraftRegistry_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]              BIT             CONSTRAINT [DF_AircraftRegistry_IsDeleted] DEFAULT ((0)) NOT NULL,
    [MasterCompanyId]        INT             NOT NULL,
    [CreatedBy]              VARCHAR (256)   NOT NULL,
    [UpdatedBy]              VARCHAR (256)   NOT NULL,
    [CreatedDate]            DATETIME2 (7)   CONSTRAINT [DF_AircraftRegistry_CreatedDate] DEFAULT (sysdatetime()) NOT NULL,
    [UpdatedDate]            DATETIME2 (7)   CONSTRAINT [DF_AircraftRegistry_UpdatedDate] DEFAULT (sysdatetime()) NOT NULL,
    [AircraftRegistryNumber] VARCHAR (30)    NULL,
    [LastMaintenanceDate]    DATETIME        NULL,
    [TotalTSNMM]             DECIMAL (18, 6) NULL,
    [TotalCSNMM]             DECIMAL (18, 6) NULL,
    [LastFlownDate]          DATETIME2 (7)   NULL,
    [Description]            VARCHAR (256)   NULL,
    [EngineRegistryIds]      NVARCHAR (500)  NULL,
    CONSTRAINT [PK_AircraftRegistry] PRIMARY KEY CLUSTERED ([AircraftRegistryId] ASC),
    CONSTRAINT [FK_AircraftRegistry_AircraftStatus] FOREIGN KEY ([AircraftStatusId]) REFERENCES [dbo].[AircraftStatus] ([AircraftStatusId]),
    CONSTRAINT [FK_AircraftRegistry_MaintenanceStatus] FOREIGN KEY ([MaintenanceStatusId]) REFERENCES [dbo].[MaintenanceStatus] ([MaintenanceStatusId]),
    CONSTRAINT [FK_AircraftRegistry_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId])
);














GO
