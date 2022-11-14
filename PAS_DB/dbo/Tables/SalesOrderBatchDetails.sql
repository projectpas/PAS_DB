CREATE TABLE [dbo].[SalesOrderBatchDetails] (
    [SalesOrderBatchDetailId] BIGINT         IDENTITY (1, 1) NOT NULL,
    [JournalBatchDetailId]    BIGINT         NULL,
    [JournalBatchHeaderId]    BIGINT         NULL,
    [CustomerTypeId]          INT            NULL,
    [CustomerType]            VARCHAR (50)   NULL,
    [CustomerId]              BIGINT         NULL,
    [CustomerName]            VARCHAR (100)  NULL,
    [ItemMasterId]            BIGINT         NULL,
    [PartId]                  BIGINT         NULL,
    [PartNumber]              NVARCHAR (100) NULL,
    [SalesOrderId]            BIGINT         NULL,
    [SalesOrderNumber]        VARCHAR (50)   NULL,
    [DocumentId]              BIGINT         NULL,
    [DocumentNumber]          VARCHAR (50)   NULL,
    [StocklineId]             BIGINT         NULL,
    [StocklineNumber]         VARCHAR (50)   NULL,
    [ARControlNumber]         VARCHAR (50)   NULL,
    [CustomerRef]             VARCHAR (MAX)  NULL,
    CONSTRAINT [PK_SalesOrderBatchDetails] PRIMARY KEY CLUSTERED ([SalesOrderBatchDetailId] ASC)
);

