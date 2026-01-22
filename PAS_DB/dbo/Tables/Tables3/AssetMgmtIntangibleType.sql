CREATE TABLE [dbo].[AssetMgmtIntangibleType] (
    [AssetMgmtIntangibleTypeTypeId] BIGINT         IDENTITY (1, 1) NOT NULL,
    [AssetMgmtIntangibleTypeId]     VARCHAR (30)   NOT NULL,
    [AssetMgmtIntangibleTypeName]   VARCHAR (50)   NOT NULL,
    [AssetMgmtIntangibleTypeMemo]   NVARCHAR (MAX) NULL,
    [MasterCompanyId]               INT            NOT NULL,
    [CreatedBy]                     VARCHAR (256)  NOT NULL,
    [UpdatedBy]                     VARCHAR (256)  NOT NULL,
    [CreatedDate]                   DATETIME2 (7)  CONSTRAINT [DF_AssetMgmtIntangibleType_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]                   DATETIME2 (7)  CONSTRAINT [DF_AssetMgmtIntangibleType_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]                      BIT            CONSTRAINT [DF_AssetMgmtIntangibleType_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]                     BIT            CONSTRAINT [DF_AssetMgmtIntangibleType_IsDelete] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_AssetMgmtIntangibleTypeType] PRIMARY KEY CLUSTERED ([AssetMgmtIntangibleTypeTypeId] ASC),
    CONSTRAINT [FK_AssetMgmtIntangibleTypeType_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId])
);


GO




CREATE TRIGGER [dbo].[Trg_AssetMgmtIntangibleTypeAudit]

   ON  [dbo].[AssetMgmtIntangibleType]

   AFTER INSERT,UPDATE

AS 

BEGIN

	

	INSERT INTO [dbo].[AssetMgmtIntangibleTypeAudit] 

    SELECT * FROM INSERTED 

	SET NOCOUNT ON;



END