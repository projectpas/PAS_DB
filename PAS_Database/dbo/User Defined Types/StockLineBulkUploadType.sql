CREATE TYPE [dbo].[StockLineBulkUploadType] AS TABLE (
    [partNumber]               VARCHAR (250)   NULL,
    [partDescription]          NVARCHAR (MAX)  NULL,
    [manufacturerName]         VARCHAR (100)   NULL,
    [condition]                VARCHAR (256)   NULL,
    [unitCost]                 DECIMAL (18, 2) NULL,
    [message]                  VARCHAR (100)   NULL,
    [srno]                     VARCHAR (100)   NULL,
    [tmpStockLineBulkUploadId] BIGINT          NULL,
    [createdBy]                VARCHAR (100)   NULL,
    [MasterCompanyId]          INT             NULL);

