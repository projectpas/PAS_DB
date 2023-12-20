CREATE TABLE [dbo].[PartRepairStations] (
    [PartRepairStationsId] BIGINT        IDENTITY (1, 1) NOT NULL,
    [PartNumber]           VARCHAR (250) NOT NULL,
    [Manufacturer]         VARCHAR (150) NULL,
    [AirCraftType]         VARCHAR (150) NULL,
    [ATAChapterId]         VARCHAR (150) NULL,
    [ItemMasterId]         BIGINT        NOT NULL,
    [MasterCompanyId]      INT           NOT NULL,
    [CreatedBy]            VARCHAR (50)  NOT NULL,
    [CreatedDate]          DATETIME2 (7) CONSTRAINT [DF_PartRepairStations_CreatedDate] DEFAULT (getutcdate()) NOT NULL,
    [UpdatedBy]            VARCHAR (50)  NOT NULL,
    [UpdatedDate]          DATETIME2 (7) CONSTRAINT [DF_PartRepairStations_UpdatedDate] DEFAULT (getutcdate()) NOT NULL,
    [IsActive]             BIT           CONSTRAINT [DF_PartRepairStationsIsActi_59FA5E80] DEFAULT ((1)) NOT NULL,
    [IsDeleted]            BIT           CONSTRAINT [DF_PartRepairStationsIsDele_5AEE82B9] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_PartRepairStations] PRIMARY KEY CLUSTERED ([PartRepairStationsId] ASC),
    CONSTRAINT [FK_PartRepairStations_ItemMaster] FOREIGN KEY ([ItemMasterId]) REFERENCES [dbo].[ItemMaster] ([ItemMasterId]),
    CONSTRAINT [FK_PartRepairStations_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId])
);

