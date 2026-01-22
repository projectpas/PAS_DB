CREATE TABLE [dbo].[AssetIntangibleType] (
    [AssetIntangibleTypeId] BIGINT         IDENTITY (1, 1) NOT NULL,
    [AssetIntangibleName]   VARCHAR (256)  NOT NULL,
    [AssetIntangibleMemo]   NVARCHAR (MAX) NULL,
    [MasterCompanyId]       INT            NOT NULL,
    [CreatedBy]             VARCHAR (256)  NOT NULL,
    [UpdatedBy]             VARCHAR (256)  NOT NULL,
    [CreatedDate]           DATETIME2 (7)  CONSTRAINT [AssetIntangibleType_DC_CDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]           DATETIME2 (7)  CONSTRAINT [AssetIntangibleType_DC_UDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]              BIT            CONSTRAINT [AssetIntangibleType_DC_Active] DEFAULT ((1)) NOT NULL,
    [IsDeleted]             BIT            CONSTRAINT [AssetIntangibleTypeDC_Delete] DEFAULT ((0)) NOT NULL,
    [AssetIntangibleCode]   VARCHAR (50)   NOT NULL,
    [Description]           VARCHAR (MAX)  NULL,
    CONSTRAINT [PK_AssetIntangibleTypeSingleScreen] PRIMARY KEY CLUSTERED ([AssetIntangibleTypeId] ASC),
    CONSTRAINT [FK_AssetIntangibleType_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [Unique_AssetIntangibleType] UNIQUE NONCLUSTERED ([AssetIntangibleCode] ASC, [MasterCompanyId] ASC),
    CONSTRAINT [Unique_AssetIntangibleTypeName] UNIQUE NONCLUSTERED ([AssetIntangibleName] ASC, [MasterCompanyId] ASC)
);


GO




CREATE TRIGGER [dbo].[Trg_AssetIntangibleType] 

ON [dbo].[AssetIntangibleType] 

FOR INSERT, UPDATE, DELETE

AS

BEGIN

	SET NOCOUNT ON;

 

	INSERT INTO  AssetIntangibleTypeAudit

	SELECT *  FROM INSERTED

END