CREATE TABLE [dbo].[AssetMgmtType] (
    [AssetMgmtTypeTypeId] BIGINT         IDENTITY (1, 1) NOT NULL,
    [AssetMgmtTypeId]     VARCHAR (30)   NOT NULL,
    [AssetMgmtTypeName]   VARCHAR (50)   NOT NULL,
    [AssetMgmtTypeMemo]   NVARCHAR (MAX) NULL,
    [MasterCompanyId]     INT            NOT NULL,
    [CreatedBy]           VARCHAR (256)  NOT NULL,
    [UpdatedBy]           VARCHAR (256)  NOT NULL,
    [CreatedDate]         DATETIME2 (7)  CONSTRAINT [DF_AssetMgmtType_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]         DATETIME2 (7)  CONSTRAINT [DF_AssetMgmtType_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]            BIT            CONSTRAINT [DF_AssetMgmtType_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]           BIT            CONSTRAINT [DF_AssetMgmtType_IsDeleted] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_AssetMgmtTypeType] PRIMARY KEY CLUSTERED ([AssetMgmtTypeTypeId] ASC),
    CONSTRAINT [FK_AssetMgmtTypeType_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId])
);


GO




CREATE TRIGGER [dbo].[Trg_AssetMgmtTypeAudit] ON [dbo].[AssetMgmtType]

   AFTER INSERT,DELETE,UPDATE  

AS   

BEGIN  

  

	INSERT INTO [dbo].[AssetMgmtTypeAudit] 

    SELECT * FROM INSERTED 

	SET NOCOUNT ON;



  

END