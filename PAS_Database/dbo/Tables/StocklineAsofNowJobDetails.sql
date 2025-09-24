CREATE TABLE [dbo].[StocklineAsofNowJobDetails] (
    [StocklineAsofNowJobId] BIGINT          IDENTITY (1, 1) NOT NULL,
    [Name]                  NVARCHAR (100)  NOT NULL,
    [Path]                  NVARCHAR (500)  NOT NULL,
    [TotalInventory]        DECIMAL (18, 2) NULL,
    [JobDate]               DATETIME2 (7)   NOT NULL,
    [NextRunDate]           DATETIME2 (7)   NULL,
    [ReportType]            INT             NULL,
    [MasterCompanyId]       INT             NOT NULL,
    [CreatedDate]           DATETIME2 (7)   CONSTRAINT [DF_StocklineAsofNowJobDetails_CreatedDate] DEFAULT (getutcdate()) NOT NULL,
    CONSTRAINT [PK_StocklineAsofNowJobDetails] PRIMARY KEY CLUSTERED ([StocklineAsofNowJobId] ASC)
);



