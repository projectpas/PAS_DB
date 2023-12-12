CREATE TABLE [dbo].[AssetLocation] (
    [AssetLocationId] BIGINT         IDENTITY (1, 1) NOT NULL,
    [Code]            VARCHAR (100)  NOT NULL,
    [Name]            VARCHAR (100)  NOT NULL,
    [Memo]            NVARCHAR (MAX) NULL,
    [MasterCompanyId] INT            NOT NULL,
    [CreatedBy]       VARCHAR (30)   NOT NULL,
    [UpdatedBy]       VARCHAR (30)   NOT NULL,
    [CreatedDate]     DATETIME2 (7)  CONSTRAINT [AssetLocation_DC_CDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]     DATETIME2 (7)  CONSTRAINT [AssetLocation_DC_UDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]        BIT            CONSTRAINT [DF_AssetLocation_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]       BIT            CONSTRAINT [DF_AssetLocation_IsDeleted] DEFAULT ((0)) NOT NULL,
    PRIMARY KEY CLUSTERED ([AssetLocationId] ASC),
    CONSTRAINT [FK_AssetLocation_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [Unique_AssetLocation] UNIQUE NONCLUSTERED ([Code] ASC, [MasterCompanyId] ASC),
    CONSTRAINT [Unique_AssetLocationName] UNIQUE NONCLUSTERED ([Name] ASC, [MasterCompanyId] ASC)
);


GO




CREATE Trigger [dbo].[trg_Assetlocation]

on [dbo].[AssetLocation]

 AFTER INSERT,UPDATE

As  

Begin  



SET NOCOUNT ON

INSERT INTO AssetLocationAudit (AssetLocationId ,Code, [Name], Memo, MasterCompanyId, CreatedBy, UpdatedBy, CreatedDate, UpdatedDate, IsActive, IsDeleted)

SELECT AssetLocationId ,Code, [Name], Memo, MasterCompanyId, CreatedBy, UpdatedBy, CreatedDate, UpdatedDate, IsActive, IsDeleted FROM INSERTED



End
GO


CREATE Trigger [dbo].[trg_Assetlocation_Delete]

on [dbo].[AssetLocation] 

 INSTEAD OF DELETE

As  

Begin  



SET NOCOUNT ON



DELETE AssetlocationAudit FROM DELETED D INNER JOIN AssetlocationAudit T ON T.AssetLocationId = D.AssetLocationId

DELETE Assetlocation FROM DELETED D INNER JOIN Assetlocation T ON T.AssetLocationId = D.AssetLocationId



End