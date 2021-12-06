CREATE TABLE [dbo].[CustomerDocumentDetailsAudit] (
    [AuditCustomerDocumentDetailId] BIGINT        IDENTITY (1, 1) NOT NULL,
    [CustomerDocumentDetailId]      BIGINT        NOT NULL,
    [CustomerId]                    BIGINT        NOT NULL,
    [AttachmentId]                  BIGINT        NOT NULL,
    [DocName]                       VARCHAR (100) NOT NULL,
    [DocMemo]                       VARCHAR (MAX) NULL,
    [DocDescription]                VARCHAR (MAX) NULL,
    [MasterCompanyId]               INT           NOT NULL,
    [CreatedBy]                     VARCHAR (256) NOT NULL,
    [UpdatedBy]                     VARCHAR (256) NOT NULL,
    [CreatedDate]                   DATETIME2 (7) NOT NULL,
    [UpdatedDate]                   DATETIME2 (7) NOT NULL,
    [IsActive]                      BIT           CONSTRAINT [CustomerDocumentDetailsAudit_DC_Active] DEFAULT ((1)) NOT NULL,
    [IsDeleted]                     BIT           CONSTRAINT [CustomerDocumentDetailsAudit_DC_Delete] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_CustomerDocumentDetailsAudit] PRIMARY KEY CLUSTERED ([AuditCustomerDocumentDetailId] ASC),
    CONSTRAINT [FK_CustomerDocumentDetailsAudit_CustomerDocumentDetails] FOREIGN KEY ([CustomerDocumentDetailId]) REFERENCES [dbo].[CustomerDocumentDetails] ([CustomerDocumentDetailId])
);

