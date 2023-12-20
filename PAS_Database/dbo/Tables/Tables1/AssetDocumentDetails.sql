CREATE TABLE [dbo].[AssetDocumentDetails] (
    [AssetDocumentDetailId] BIGINT         IDENTITY (1, 1) NOT NULL,
    [AssetRecordId]         BIGINT         NOT NULL,
    [AttachmentId]          BIGINT         NOT NULL,
    [DocName]               VARCHAR (100)  NOT NULL,
    [DocMemo]               NVARCHAR (MAX) NULL,
    [DocDescription]        VARCHAR (100)  NULL,
    [MasterCompanyId]       INT            NOT NULL,
    [CreatedBy]             VARCHAR (256)  NOT NULL,
    [UpdatedBy]             VARCHAR (256)  NOT NULL,
    [CreatedDate]           DATETIME2 (7)  CONSTRAINT [DF_AssetDocumentDetails_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]           DATETIME2 (7)  CONSTRAINT [DF_AssetDocumentDetails_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]              BIT            CONSTRAINT [AssetDocumentDetails_DC_Active] DEFAULT ((1)) NOT NULL,
    [IsDeleted]             BIT            CONSTRAINT [AssetDocumentDetails_DC_Delete] DEFAULT ((0)) NOT NULL,
    [IsMaintenance]         BIT            NULL,
    [IsWarranty]            BIT            NULL,
    CONSTRAINT [PK_AssetDocumentDetails] PRIMARY KEY CLUSTERED ([AssetDocumentDetailId] ASC),
    CONSTRAINT [FK_AssetDocumentDetails_Asset] FOREIGN KEY ([AssetRecordId]) REFERENCES [dbo].[Asset] ([AssetRecordId]),
    CONSTRAINT [FK_AssetDocumentDetails_Attachment] FOREIGN KEY ([AttachmentId]) REFERENCES [dbo].[Attachment] ([AttachmentId]),
    CONSTRAINT [FK_AssetDocumentDetails_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [UQ_AssetDocumentDetails] UNIQUE NONCLUSTERED ([AssetRecordId] ASC, [MasterCompanyId] ASC, [AttachmentId] ASC)
);


GO




CREATE TRIGGER [dbo].[Trg_AssetDocumentDetailsAudit] ON [dbo].[AssetDocumentDetails]

   AFTER INSERT,DELETE,UPDATE  

AS   

BEGIN  

  

 INSERT INTO [dbo].[AssetDocumentDetailsAudit]  

 SELECT * FROM INSERTED  

  

 SET NOCOUNT ON;  

  

END