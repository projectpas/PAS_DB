CREATE TABLE [dbo].[SalesOrderDocumentDetail] (
    [SalesOrderDocumentDetailId] BIGINT        IDENTITY (1, 1) NOT NULL,
    [SalesOrderId]               BIGINT        NOT NULL,
    [AttachmentId]               BIGINT        NOT NULL,
    [DocName]                    VARCHAR (100) NOT NULL,
    [DocMemo]                    VARCHAR (100) NULL,
    [DocDescription]             VARCHAR (100) NULL,
    [MasterCompanyId]            INT           NOT NULL,
    [CreatedBy]                  VARCHAR (256) NOT NULL,
    [UpdatedBy]                  VARCHAR (256) NOT NULL,
    [CreatedDate]                DATETIME2 (7) CONSTRAINT [DF_SalesOrderDocumentDetail_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]                DATETIME2 (7) CONSTRAINT [DF_SalesOrderDocumentDetail_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]                   BIT           CONSTRAINT [DF_SalesOrderDocumentDetail_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]                  BIT           CONSTRAINT [DF_SalesOrderDocumentDetail_IsDeleted] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_SalesOrderDocumentDetail] PRIMARY KEY CLUSTERED ([SalesOrderDocumentDetailId] ASC),
    CONSTRAINT [FK_SalesOrderDocumentDetail_Attachment] FOREIGN KEY ([AttachmentId]) REFERENCES [dbo].[Attachment] ([AttachmentId]),
    CONSTRAINT [FK_SalesOrderDocumentDetail_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [FK_SalesOrderDocumentDetail_SalesOrder] FOREIGN KEY ([SalesOrderId]) REFERENCES [dbo].[SalesOrder] ([SalesOrderId])
);

