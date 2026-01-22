CREATE TABLE [dbo].[AssetCapes] (
    [AssetCapesId]         BIGINT        IDENTITY (1, 1) NOT NULL,
    [AssetRecordId]        BIGINT        NOT NULL,
    [CapabilityId]         INT           NULL,
    [MasterCompanyId]      INT           NOT NULL,
    [CreatedBy]            VARCHAR (256) NOT NULL,
    [UpdatedBy]            VARCHAR (256) NOT NULL,
    [CreatedDate]          DATETIME2 (7) CONSTRAINT [DF_AssetCapes_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]          DATETIME2 (7) CONSTRAINT [DF_AssetCapes_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]             BIT           CONSTRAINT [AssetCapes_DC_Active] DEFAULT ((1)) NOT NULL,
    [IsDeleted]            BIT           CONSTRAINT [AssetCapes_DC_Delete] DEFAULT ((0)) NOT NULL,
    [AircraftTypeId]       INT           NULL,
    [AircraftModelId]      BIGINT        NULL,
    [AircraftDashNumberId] BIGINT        NULL,
    [ItemMasterId]         BIGINT        NULL,
    CONSTRAINT [PK_AssetCapes] PRIMARY KEY CLUSTERED ([AssetCapesId] ASC),
    FOREIGN KEY ([ItemMasterId]) REFERENCES [dbo].[ItemMaster] ([ItemMasterId]),
    CONSTRAINT [FK_AssetCapes_AircraftDashNumber] FOREIGN KEY ([AircraftDashNumberId]) REFERENCES [dbo].[AircraftDashNumber] ([DashNumberId]),
    CONSTRAINT [FK_AssetCapes_AircraftModel] FOREIGN KEY ([AircraftModelId]) REFERENCES [dbo].[AircraftModel] ([AircraftModelId]),
    CONSTRAINT [FK_AssetCapes_AircraftType] FOREIGN KEY ([AircraftTypeId]) REFERENCES [dbo].[AircraftType] ([AircraftTypeId]),
    CONSTRAINT [FK_AssetCapes_Asset] FOREIGN KEY ([AssetRecordId]) REFERENCES [dbo].[Asset] ([AssetRecordId]),
    CONSTRAINT [FK_AssetCapes_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [AssetCapes_Capability_Unique] UNIQUE NONCLUSTERED ([CapabilityId] ASC, [ItemMasterId] ASC, [AircraftTypeId] ASC, [AircraftModelId] ASC, [AircraftDashNumberId] ASC, [MasterCompanyId] ASC, [AssetRecordId] ASC)
);


GO




CREATE Trigger [dbo].[trg_Assetcapes_Delete]

on [dbo].[AssetCapes] 

 INSTEAD OF DELETE

As  

Begin  



SET NOCOUNT ON



DELETE AssetCapesAudit FROM DELETED D INNER JOIN AssetCapesAudit T ON T.AssetCapesId = D.AssetCapesId

DELETE AssetCapes FROM DELETED D INNER JOIN AssetCapes T ON T.AssetCapesId = D.AssetCapesId



End
GO


CREATE Trigger [dbo].[trg_Assetcapes]

on [dbo].[AssetCapes] 

 AFTER INSERT,UPDATE 

As  

Begin  



SET NOCOUNT ON

INSERT INTO AssetCapesAudit

SELECT * FROM INSERTED



End