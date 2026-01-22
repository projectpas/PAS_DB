CREATE TABLE [dbo].[AssetStatus] (
    [AssetStatusId]   BIGINT         IDENTITY (1, 1) NOT NULL,
    [Code]            VARCHAR (100)  NULL,
    [Name]            VARCHAR (100)  NOT NULL,
    [Memo]            NVARCHAR (MAX) NULL,
    [MasterCompanyId] INT            NOT NULL,
    [CreatedBy]       VARCHAR (30)   NOT NULL,
    [UpdatedBy]       VARCHAR (30)   NOT NULL,
    [CreatedDate]     DATETIME2 (7)  CONSTRAINT [AssetStatus_DC_CDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]     DATETIME2 (7)  CONSTRAINT [AssetStatus_DC_UDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]        BIT            CONSTRAINT [DF_AssetStatus_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]       BIT            CONSTRAINT [DF_AssetStatus_IsDeleted] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK__AssetSta__3214EC077E893104] PRIMARY KEY CLUSTERED ([AssetStatusId] ASC),
    CONSTRAINT [FK_AssetStatus_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [Unique_AssetStatus] UNIQUE NONCLUSTERED ([Name] ASC, [MasterCompanyId] ASC)
);


GO




CREATE TRIGGER [dbo].[Trg_AssetStatusAudit] ON [dbo].[AssetStatus]

   AFTER INSERT,DELETE,UPDATE  

AS   

BEGIN  

  

 INSERT INTO [dbo].[AssetStatusAudit]  (AssetStatusId,	Code,	[Name],	Memo,	MasterCompanyId,	CreatedBy,	UpdatedBy,	CreatedDate	,UpdatedDate,	IsActive, IsDeleted)

 SELECT AssetStatusId,	Code,	[Name],	Memo,	MasterCompanyId,	CreatedBy,	UpdatedBy,	CreatedDate	,UpdatedDate,	IsActive,	IsDeleted FROM INSERTED  

  

 SET NOCOUNT ON;  

  

END