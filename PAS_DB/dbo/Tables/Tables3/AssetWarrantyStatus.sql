CREATE TABLE [dbo].[AssetWarrantyStatus] (
    [AssetWarrantyStatusId] BIGINT         IDENTITY (1, 1) NOT NULL,
    [WarrantyStatus]        VARCHAR (100)  NOT NULL,
    [MasterCompanyId]       INT            NOT NULL,
    [CreatedBy]             VARCHAR (30)   NOT NULL,
    [UpdatedBy]             VARCHAR (30)   NOT NULL,
    [CreatedDate]           DATETIME2 (7)  CONSTRAINT [AssetWarrantyStatus_DC_CDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]           DATETIME2 (7)  CONSTRAINT [AssetWarrantyStatus_DC_UDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]              BIT            CONSTRAINT [DF_AssetWarrantyStatus_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]             BIT            CONSTRAINT [DF_AssetWarrantyStatus_IsDeleted] DEFAULT ((0)) NOT NULL,
    [Description]           VARCHAR (MAX)  NULL,
    [Memo]                  NVARCHAR (MAX) NULL,
    PRIMARY KEY CLUSTERED ([AssetWarrantyStatusId] ASC),
    CONSTRAINT [Unique_AssetWarrantyStatus] UNIQUE NONCLUSTERED ([WarrantyStatus] ASC, [MasterCompanyId] ASC)
);

