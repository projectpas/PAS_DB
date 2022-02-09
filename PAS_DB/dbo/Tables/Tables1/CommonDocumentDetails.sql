CREATE TABLE [dbo].[CommonDocumentDetails] (
    [CommonDocumentDetailId] BIGINT         IDENTITY (1, 1) NOT NULL,
    [ModuleId]               INT            NOT NULL,
    [ReferenceId]            BIGINT         NULL,
    [AttachmentId]           BIGINT         NOT NULL,
    [DocName]                VARCHAR (100)  NULL,
    [DocMemo]                NVARCHAR (MAX) NULL,
    [DocDescription]         VARCHAR (MAX)  NULL,
    [MasterCompanyId]        INT            NOT NULL,
    [CreatedBy]              VARCHAR (256)  NOT NULL,
    [UpdatedBy]              VARCHAR (256)  NOT NULL,
    [CreatedDate]            DATETIME2 (7)  CONSTRAINT [CommonDocumentDetails_DC_CDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]            DATETIME2 (7)  CONSTRAINT [CommonDocumentDetails_DC_UDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]               BIT            CONSTRAINT [CommonDocumentDetails_DC_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]              BIT            CONSTRAINT [CommonDocumentDetails_DC_IsDeleted] DEFAULT ((0)) NOT NULL,
    [DocumentTypeId]         BIGINT         NULL,
    [ExpirationDate]         DATETIME2 (7)  NULL,
    CONSTRAINT [PK_CommonDocumentDetails] PRIMARY KEY CLUSTERED ([CommonDocumentDetailId] ASC),
    CONSTRAINT [FK_CommonDocumentDetails_Attachment] FOREIGN KEY ([AttachmentId]) REFERENCES [dbo].[Attachment] ([AttachmentId])
);




GO






Create TRIGGER [dbo].[Trg_CommonDocumentDetailsAudit] ON [dbo].[CommonDocumentDetails]

   AFTER INSERT,DELETE,UPDATE  

AS   

BEGIN  

  

 INSERT INTO [dbo].[CommonDocumentDetailsAudit]  

 SELECT * FROM INSERTED  

  

 SET NOCOUNT ON;  

  

END