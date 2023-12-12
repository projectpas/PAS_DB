CREATE TABLE [dbo].[AssetAcquisitionType] (
    [AssetAcquisitionTypeId] BIGINT         IDENTITY (1, 1) NOT NULL,
    [Name]                   VARCHAR (256)  NOT NULL,
    [Memo]                   NVARCHAR (MAX) NULL,
    [MasterCompanyId]        INT            NOT NULL,
    [IsActive]               BIT            CONSTRAINT [AssetAcquisitionType_DC_Active] DEFAULT ((1)) NOT NULL,
    [CreatedBy]              VARCHAR (256)  NOT NULL,
    [UpdatedBy]              VARCHAR (256)  NOT NULL,
    [CreatedDate]            DATETIME2 (7)  CONSTRAINT [AssetAcquisitionType_DC_CDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]            DATETIME2 (7)  CONSTRAINT [AssetAcquisitionType_DC_UDate] DEFAULT (getdate()) NOT NULL,
    [IsDeleted]              BIT            CONSTRAINT [AssetAcquisitionType_DC_Delete] DEFAULT ((0)) NOT NULL,
    [Code]                   VARCHAR (256)  NOT NULL,
    [Description]            VARCHAR (500)  NULL,
    [SequenceNo]             INT            NULL,
    CONSTRAINT [PK__AssetAcq__1FCF1ABE0F921C31] PRIMARY KEY CLUSTERED ([AssetAcquisitionTypeId] ASC),
    CONSTRAINT [FK_AssetAcquisitionType_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [Unique_AssetAcquisitionType] UNIQUE NONCLUSTERED ([Name] ASC, [MasterCompanyId] ASC),
    CONSTRAINT [Unique_AssetAcquisitionTypeCode] UNIQUE NONCLUSTERED ([Code] ASC, [MasterCompanyId] ASC)
);


GO








CREATE Trigger [dbo].[trg_AssetAcquisitionType]

on [dbo].[AssetAcquisitionType]

 AFTER INSERT,DELETE,UPDATE

As  

Begin  



SET NOCOUNT ON

INSERT INTO AssetAcquisitionTypeAudit (AssetAcquisitionTypeId,	[Name],	Memo,	MasterCompanyId,	IsActive,	CreatedBy,	UpdatedBy,	CreatedDate,

	UpdatedDate,	isDeleted,	Code,SequenceNo)

SELECT AssetAcquisitionTypeId,	[Name],	Memo,	MasterCompanyId,	IsActive,	CreatedBy,	UpdatedBy,	CreatedDate,

	UpdatedDate,	isDeleted,	Code,SequenceNo FROM INSERTED



End