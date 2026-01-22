CREATE TABLE [dbo].[AssetType] (
    [AssetTypeId]     BIGINT         IDENTITY (1, 1) NOT NULL,
    [AssetTypeName]   VARCHAR (30)   NOT NULL,
    [AssetTypeMemo]   NVARCHAR (MAX) NULL,
    [MasterCompanyId] INT            NOT NULL,
    [CreatedBy]       VARCHAR (256)  NOT NULL,
    [UpdatedBy]       VARCHAR (256)  NOT NULL,
    [CreatedDate]     DATETIME2 (7)  CONSTRAINT [AssetType_DC_CDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]     DATETIME2 (7)  CONSTRAINT [AssetType_DC_UDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]        BIT            CONSTRAINT [AssetType_DC_Active] DEFAULT ((1)) NOT NULL,
    [IsDeleted]       BIT            CONSTRAINT [AssetType_DC_Delete] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_AssetTypeSingleScreen] PRIMARY KEY CLUSTERED ([AssetTypeId] ASC),
    CONSTRAINT [FK_AssetType_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [Unique_AssetType] UNIQUE NONCLUSTERED ([AssetTypeName] ASC, [MasterCompanyId] ASC)
);


GO




CREATE TRIGGER [dbo].[Trg_AssetTypeAudit] ON [dbo].[AssetType]

   AFTER INSERT,DELETE,UPDATE  

AS   

BEGIN  

  

	INSERT INTO [dbo].[AssetTypeAudit] 

    SELECT * FROM INSERTED 

	SET NOCOUNT ON;



  

END