CREATE TABLE [dbo].[AssetDisposalType] (
    [AssetDisposalTypeId] BIGINT         IDENTITY (1, 1) NOT NULL,
    [AssetDisposalCode]   VARCHAR (30)   NOT NULL,
    [AssetDisposalName]   VARCHAR (50)   NOT NULL,
    [AssetDisposalMemo]   NVARCHAR (MAX) NULL,
    [MasterCompanyId]     INT            NOT NULL,
    [CreatedBy]           VARCHAR (256)  NOT NULL,
    [UpdatedBy]           VARCHAR (256)  NOT NULL,
    [CreatedDate]         DATETIME2 (7)  CONSTRAINT [AssetDisposalType_DC_CDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]         DATETIME2 (7)  CONSTRAINT [AssetDisposalType_DC_UDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]            BIT            CONSTRAINT [DF_AssetDisposalType_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]           BIT            CONSTRAINT [DF_AssetDisposalType_IsDeleted] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_AssetDisposalType] PRIMARY KEY CLUSTERED ([AssetDisposalTypeId] ASC),
    CONSTRAINT [FK_AssetDisposalType_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [Unique_AssetDisposalName] UNIQUE NONCLUSTERED ([AssetDisposalName] ASC, [MasterCompanyId] ASC),
    CONSTRAINT [Unique_AssetDisposalType] UNIQUE NONCLUSTERED ([AssetDisposalCode] ASC, [MasterCompanyId] ASC)
);


GO


CREATE TRIGGER [dbo].[Trg_AssetDisposalTypeAudit] ON [dbo].[AssetDisposalType]

   AFTER INSERT,DELETE,UPDATE  

AS  

BEGIN  



 INSERT INTO [dbo].[AssetDisposalTypeAudit]  (AssetDisposalTypeId,AssetDisposalCode,AssetDisposalName, AssetDisposalMemo, MasterCompanyId ,CreatedBy, UpdatedBy, CreatedDate, UpdatedDate, IsActive, IsDeleted)

 SELECT AssetDisposalTypeId,AssetDisposalCode,AssetDisposalName, AssetDisposalMemo, MasterCompanyId ,CreatedBy, UpdatedBy, CreatedDate, UpdatedDate, IsActive, IsDeleted FROM INSERTED  



 SET NOCOUNT ON;  



END