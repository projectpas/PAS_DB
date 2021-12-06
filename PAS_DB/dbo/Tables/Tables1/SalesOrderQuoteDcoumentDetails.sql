CREATE TABLE [dbo].[SalesOrderQuoteDcoumentDetails] (
    [SalesOrderQuoteDocumentDetailId] BIGINT        IDENTITY (1, 1) NOT NULL,
    [SalesOrderQuoteId]               BIGINT        NOT NULL,
    [AttachmentId]                    BIGINT        NOT NULL,
    [DocName]                         VARCHAR (100) NOT NULL,
    [DocMemo]                         VARCHAR (100) NULL,
    [DocDescription]                  VARCHAR (100) NULL,
    [MasterCompanyId]                 INT           NOT NULL,
    [CreatedBy]                       VARCHAR (256) NOT NULL,
    [UpdatedBy]                       VARCHAR (256) NOT NULL,
    [CreatedDate]                     DATETIME2 (7) CONSTRAINT [DF_SalesOrderQuoteDocumentDetails_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]                     DATETIME2 (7) CONSTRAINT [DF_SalesOrderQuoteDocumentDetails_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]                        BIT           CONSTRAINT [DF_SalesOrderQuoteDocumentDetails_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]                       BIT           CONSTRAINT [DF_SalesOrderQuoteDocumentDetails_IsDeleted] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_SalesOrderQuoteDocumentDetails] PRIMARY KEY CLUSTERED ([SalesOrderQuoteDocumentDetailId] ASC),
    CONSTRAINT [FK_SalesOrderQuoteDocumentDetails_Attachment] FOREIGN KEY ([AttachmentId]) REFERENCES [dbo].[Attachment] ([AttachmentId]),
    CONSTRAINT [FK_SalesOrderQuoteDocumentDetails_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [FK_SalesOrderQuoteDocumentDetails_SalesOrderQuote] FOREIGN KEY ([SalesOrderQuoteId]) REFERENCES [dbo].[SalesOrderQuote] ([SalesOrderQuoteId])
);

