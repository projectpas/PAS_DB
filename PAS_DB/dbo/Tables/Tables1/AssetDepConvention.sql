CREATE TABLE [dbo].[AssetDepConvention] (
    [AssetDepConventionId]   BIGINT         IDENTITY (1, 1) NOT NULL,
    [AssetDepConventionCode] VARCHAR (30)   NOT NULL,
    [AssetDepConventionName] VARCHAR (50)   NOT NULL,
    [AssetDepConventionMemo] NVARCHAR (MAX) NULL,
    [MasterCompanyId]        INT            NOT NULL,
    [CreatedBy]              VARCHAR (256)  NOT NULL,
    [UpdatedBy]              VARCHAR (256)  NOT NULL,
    [CreatedDate]            DATETIME2 (7)  CONSTRAINT [AssetDepConvention_DC_CDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]            DATETIME2 (7)  CONSTRAINT [AssetDepConvention_DC_UDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]               BIT            CONSTRAINT [DF_AssetDepConvention_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]              BIT            CONSTRAINT [DF_AssetDepConvention_IsDeleted] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_AssetDepConvention] PRIMARY KEY CLUSTERED ([AssetDepConventionId] ASC),
    CONSTRAINT [FK_AssetDepConvention_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [Unique_AssetDepConvention] UNIQUE NONCLUSTERED ([AssetDepConventionCode] ASC, [MasterCompanyId] ASC),
    CONSTRAINT [Unique_AssetDepConventionName] UNIQUE NONCLUSTERED ([AssetDepConventionName] ASC, [MasterCompanyId] ASC)
);


GO






CREATE TRIGGER [dbo].[Trg_AssetDepConventionAudit] ON [dbo].[AssetDepConvention]

   AFTER INSERT,DELETE,UPDATE  

AS   

BEGIN  



 INSERT INTO [dbo].[AssetDepConventionAudit]  

 SELECT * FROM INSERTED  



 SET NOCOUNT ON;  



END