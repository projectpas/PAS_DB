CREATE TABLE [dbo].[CustomerDocumentDetails] (
    [CustomerDocumentDetailId] BIGINT        IDENTITY (1, 1) NOT NULL,
    [CustomerId]               BIGINT        NOT NULL,
    [AttachmentId]             BIGINT        NOT NULL,
    [DocName]                  VARCHAR (100) NOT NULL,
    [DocMemo]                  VARCHAR (MAX) NULL,
    [DocDescription]           VARCHAR (MAX) NULL,
    [MasterCompanyId]          INT           NOT NULL,
    [CreatedBy]                VARCHAR (256) NOT NULL,
    [UpdatedBy]                VARCHAR (256) NOT NULL,
    [CreatedDate]              DATETIME2 (7) CONSTRAINT [DF_CustomerDocumentDetails_CreatedDate] DEFAULT (sysdatetime()) NOT NULL,
    [UpdatedDate]              DATETIME2 (7) CONSTRAINT [DF_CustomerDocumentDetails_UpdatedDate] DEFAULT (sysdatetime()) NOT NULL,
    [IsActive]                 BIT           CONSTRAINT [CustomerDocumentDetails_DC_Active] DEFAULT ((1)) NOT NULL,
    [IsDeleted]                BIT           CONSTRAINT [CustomerDocumentDetails_DC_Delete] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_CustomerDocumentDetails] PRIMARY KEY CLUSTERED ([CustomerDocumentDetailId] ASC),
    CONSTRAINT [FK_CustomerDocumentDetails_Attachment] FOREIGN KEY ([AttachmentId]) REFERENCES [dbo].[Attachment] ([AttachmentId]),
    CONSTRAINT [FK_CustomerDocumentDetails_Customer] FOREIGN KEY ([CustomerId]) REFERENCES [dbo].[Customer] ([CustomerId]),
    CONSTRAINT [FK_CustomerDocumentDetails_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [UQ_CustomerDocumentDeatails] UNIQUE NONCLUSTERED ([CustomerId] ASC, [MasterCompanyId] ASC, [AttachmentId] ASC)
);


GO




------------------------



CREATE TRIGGER [dbo].[Trg_CustomerDocumentDetailsAudit]

   ON  [dbo].[CustomerDocumentDetails]

   AFTER INSERT,UPDATE

AS 

BEGIN



	INSERT INTO [dbo].[CustomerDocumentDetailsAudit]

	SELECT * FROM INSERTED



	SET NOCOUNT ON;



END