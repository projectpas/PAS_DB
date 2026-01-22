CREATE TABLE [dbo].[VendorDocumentDetailsAudit] (
    [AuditVendorDocumentDetailId] BIGINT        IDENTITY (1, 1) NOT NULL,
    [VendorDocumentDetailId]      BIGINT        NOT NULL,
    [VendorId]                    BIGINT        NOT NULL,
    [AttachmentId]                BIGINT        NOT NULL,
    [DocName]                     VARCHAR (100) NOT NULL,
    [DocMemo]                     VARCHAR (100) NULL,
    [DocDescription]              VARCHAR (100) NULL,
    [MasterCompanyId]             INT           NOT NULL,
    [CreatedBy]                   VARCHAR (256) NOT NULL,
    [UpdatedBy]                   VARCHAR (256) NOT NULL,
    [CreatedDate]                 DATETIME2 (7) CONSTRAINT [VendorDocumentDetailsAudit_DC_CD] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]                 DATETIME2 (7) CONSTRAINT [VendorDocumentDetailsAudit_DC_UD] DEFAULT (getdate()) NOT NULL,
    [IsActive]                    BIT           CONSTRAINT [VendorDocumentDetailsAudit_DC_Active] DEFAULT ((1)) NOT NULL,
    [IsDeleted]                   BIT           CONSTRAINT [VendorDocumentDetailsAudit_DC_Delete] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_VendorDocumentDetailsAudit] PRIMARY KEY CLUSTERED ([AuditVendorDocumentDetailId] ASC),
    CONSTRAINT [FK_VendorDocumentDetailsAudit_VendorDocumentDetails] FOREIGN KEY ([VendorDocumentDetailId]) REFERENCES [dbo].[VendorDocumentDetails] ([VendorDocumentDetailId])
);

