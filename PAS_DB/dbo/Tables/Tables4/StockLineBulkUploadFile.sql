CREATE TABLE [dbo].[StockLineBulkUploadFile] (
    [StockLineBulkUploadFileId] BIGINT        IDENTITY (1, 1) NOT NULL,
    [FileName]                  VARCHAR (250) NULL,
    [MasterCompanyId]           INT           NOT NULL,
    [CreatedBy]                 VARCHAR (256) NULL,
    [UpdatedBy]                 VARCHAR (256) NULL,
    [CreatedDate]               DATETIME2 (7) CONSTRAINT [DF_StockLineBulkUploadFile_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]               DATETIME2 (7) CONSTRAINT [DF_StockLineBulkUploadFile_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    CONSTRAINT [PK_StockLineBulkUploadFile] PRIMARY KEY CLUSTERED ([StockLineBulkUploadFileId] ASC),
    CONSTRAINT [FK_StockLineBulkUploadFile_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId])
);

