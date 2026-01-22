CREATE TABLE [dbo].[AssetDepreciationInterval] (
    [AssetDepreciationIntervalId]   BIGINT         IDENTITY (1, 1) NOT NULL,
    [AssetDepreciationIntervalCode] VARCHAR (30)   NOT NULL,
    [AssetDepreciationIntervalName] VARCHAR (50)   NOT NULL,
    [AssetDepreciationIntervalMemo] NVARCHAR (MAX) NULL,
    [MasterCompanyId]               INT            NOT NULL,
    [CreatedBy]                     VARCHAR (256)  NOT NULL,
    [UpdatedBy]                     VARCHAR (256)  NOT NULL,
    [CreatedDate]                   DATETIME2 (7)  CONSTRAINT [AssetDepreciationInterval_DC_CDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]                   DATETIME2 (7)  CONSTRAINT [AssetDepreciationInterval_DC_UDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]                      BIT            CONSTRAINT [DF_AssetDepreciationInterval_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]                     BIT            CONSTRAINT [DF_AssetDepreciationInterval_IsDeleted] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_AssetDepreciationIntervalType] PRIMARY KEY CLUSTERED ([AssetDepreciationIntervalId] ASC),
    CONSTRAINT [FK_AssetDepreciationInterval_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [Unique_AssetDepreciationInterval] UNIQUE NONCLUSTERED ([AssetDepreciationIntervalCode] ASC, [MasterCompanyId] ASC)
);


GO






CREATE TRIGGER [dbo].[Trg_AssetDepreciationIntervalAudit] ON [dbo].[AssetDepreciationInterval]

   AFTER INSERT,DELETE,UPDATE  

AS   

BEGIN  



 INSERT INTO [dbo].[AssetDepreciationIntervalAudit]  

 SELECT * FROM INSERTED  



 SET NOCOUNT ON;  



END