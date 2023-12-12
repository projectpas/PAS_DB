CREATE TABLE [dbo].[ExchangeBatchDetails] (
    [ExchangeBatchDetailId]      BIGINT        IDENTITY (1, 1) NOT NULL,
    [CommonJournalBatchDetailId] BIGINT        NOT NULL,
    [JournalBatchDetailId]       BIGINT        NOT NULL,
    [JournalBatchHeaderId]       BIGINT        NOT NULL,
    [ExchangeSalesOrderId]       BIGINT        NOT NULL,
    [ExchangeSalesOrderNumber]   VARCHAR (100) NOT NULL,
    [CustomerId]                 BIGINT        NOT NULL,
    [CustomerReference]          VARCHAR (100) NULL,
    [ExchangeSalesOrderPartId]   BIGINT        NOT NULL,
    [ItemMasterId]               BIGINT        NOT NULL,
    [StockLineId]                BIGINT        NULL,
    [StocklineNumber]            VARCHAR (100) NULL,
    [InvoiceId]                  BIGINT        NULL,
    [InvoiceNo]                  VARCHAR (100) NULL,
    [TypeId]                     INT           NULL,
    [DistSetupCode]              VARCHAR (50)  NULL,
    CONSTRAINT [PK_ExchangeBatchDetails] PRIMARY KEY CLUSTERED ([ExchangeBatchDetailId] ASC)
);

