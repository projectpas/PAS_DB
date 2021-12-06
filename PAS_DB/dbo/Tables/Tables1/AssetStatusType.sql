CREATE TABLE [dbo].[AssetStatusType] (
    [AssetStatusTypeId] BIGINT         IDENTITY (1, 1) NOT NULL,
    [AssetStatusId]     VARCHAR (30)   NOT NULL,
    [AssetStatusName]   VARCHAR (50)   NOT NULL,
    [AssetStatusMemo]   NVARCHAR (MAX) NULL,
    [MasterCompanyId]   INT            NOT NULL,
    [CreatedBy]         VARCHAR (256)  NOT NULL,
    [UpdatedBy]         VARCHAR (256)  NOT NULL,
    [CreatedDate]       DATETIME2 (7)  CONSTRAINT [DF_AssetStatusType_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]       DATETIME2 (7)  CONSTRAINT [DF_AssetStatusType_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]          BIT            CONSTRAINT [DF_AssetStatusType_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]         BIT            CONSTRAINT [DF_AssetStatusType_IsDeleted] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_AssetStatusType] PRIMARY KEY CLUSTERED ([AssetStatusTypeId] ASC),
    CONSTRAINT [FK_AssetStatusType_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId])
);


GO




CREATE TRIGGER [dbo].[Trg_AssetStatusTypeAudit] ON [dbo].[AssetStatusType]

   AFTER INSERT,DELETE,UPDATE  

AS   

BEGIN  

  

	INSERT INTO [dbo].[AssetStatusTypeAudit] 

    SELECT * FROM INSERTED 

	SET NOCOUNT ON;



  

END