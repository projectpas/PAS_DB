CREATE TABLE [dbo].[TmpStockLineBulkUpload] (
    [TmpStockLineBulkUploadId] BIGINT          IDENTITY (1, 1) NOT NULL,
    [partNumber]               VARCHAR (250)   NULL,
    [partDescription]          NVARCHAR (MAX)  NULL,
    [manufacturerName]         VARCHAR (100)   NULL,
    [condition]                VARCHAR (256)   NULL,
    [unitCost]                 DECIMAL (18, 2) NULL,
    [message]                  VARCHAR (100)   NULL,
    [srno]                     VARCHAR (100)   NULL,
    [MasterCompanyId]          INT             NOT NULL,
    [CreatedBy]                VARCHAR (256)   NULL,
    [UpdatedBy]                VARCHAR (256)   NULL,
    [CreatedDate]              DATETIME2 (7)   CONSTRAINT [DF_TmpStockLineBulkUpload_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]              DATETIME2 (7)   CONSTRAINT [DF_TmpStockLineBulkUpload_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    CONSTRAINT [PK_TmpStockLineBulkUpload] PRIMARY KEY CLUSTERED ([TmpStockLineBulkUploadId] ASC),
    CONSTRAINT [FK_TmpStockLineBulkUpload_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId])
);

