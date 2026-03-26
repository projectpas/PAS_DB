CREATE TABLE [dbo].[AircraftStatus] (
    [AircraftStatusId] BIGINT        IDENTITY (1, 1) NOT NULL,
    [Name]             VARCHAR (100) NOT NULL,
    [Description]      VARCHAR (500) NULL,
    [SequenceNo]       INT           NULL,
    [MasterCompanyId]  INT           NOT NULL,
    [CreatedBy]        VARCHAR (256) NOT NULL,
    [UpdatedBy]        VARCHAR (256) NOT NULL,
    [CreatedDate]      DATETIME2 (7) CONSTRAINT [DF_AircraftStatus_CreatedDate] DEFAULT (sysdatetime()) NOT NULL,
    [UpdatedDate]      DATETIME2 (7) CONSTRAINT [DF_AircraftStatus_UpdatedDate] DEFAULT (sysdatetime()) NOT NULL,
    [IsActive]         BIT           CONSTRAINT [DF_AircraftStatus_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]        BIT           CONSTRAINT [DF_AircraftStatus_IsDeleted] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_AircraftStatus] PRIMARY KEY CLUSTERED ([AircraftStatusId] ASC),
    CONSTRAINT [FK_AircraftStatus_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [UQ_AircraftStatus_Name_MasterCompany] UNIQUE NONCLUSTERED ([Name] ASC, [MasterCompanyId] ASC)
);

