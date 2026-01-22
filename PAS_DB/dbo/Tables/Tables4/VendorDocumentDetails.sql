CREATE TABLE [dbo].[VendorDocumentDetails] (
    [VendorDocumentDetailId] BIGINT        IDENTITY (1, 1) NOT NULL,
    [VendorId]               BIGINT        NOT NULL,
    [AttachmentId]           BIGINT        NOT NULL,
    [DocName]                VARCHAR (100) NOT NULL,
    [DocMemo]                VARCHAR (100) NULL,
    [DocDescription]         VARCHAR (100) NULL,
    [MasterCompanyId]        INT           NOT NULL,
    [CreatedBy]              VARCHAR (256) NOT NULL,
    [UpdatedBy]              VARCHAR (256) NOT NULL,
    [CreatedDate]            DATETIME2 (7) CONSTRAINT [VendorDocumentDetails_DC_CD] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]            DATETIME2 (7) CONSTRAINT [VendorDocumentDetails_DC_UD] DEFAULT (getdate()) NOT NULL,
    [IsActive]               BIT           CONSTRAINT [VendorDocumentDetails_DC_Active] DEFAULT ((1)) NOT NULL,
    [IsDeleted]              BIT           CONSTRAINT [VendorDocumentDetails_DC_Delete] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_VendorDocumentDetails] PRIMARY KEY CLUSTERED ([VendorDocumentDetailId] ASC),
    CONSTRAINT [FK_VendorDocumentDetails_Attachment] FOREIGN KEY ([AttachmentId]) REFERENCES [dbo].[Attachment] ([AttachmentId]),
    CONSTRAINT [FK_VendorDocumentDetails_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [FK_VendorDocumentDetails_Vendor] FOREIGN KEY ([VendorId]) REFERENCES [dbo].[Vendor] ([VendorId]),
    CONSTRAINT [UQ_VendorDocumentDeatails] UNIQUE NONCLUSTERED ([VendorId] ASC, [MasterCompanyId] ASC, [AttachmentId] ASC)
);


GO




CREATE TRIGGER [dbo].[Trg_VendorDocumentDetailsAudit]

   ON  [dbo].[VendorDocumentDetails]

   AFTER INSERT,DELETE,UPDATE

AS 

BEGIN



	INSERT INTO [dbo].[VendorDocumentDetailsAudit]

	SELECT * FROM INSERTED



	SET NOCOUNT ON;



END