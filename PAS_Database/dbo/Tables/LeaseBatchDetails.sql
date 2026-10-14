CREATE TABLE [dbo].[LeaseBatchDetails] (
    [LeaseBatchDetailId]         BIGINT         IDENTITY (1, 1) NOT NULL,
    [JournalBatchDetailId]       BIGINT         NULL,
    [JournalBatchHeaderId]       BIGINT         NULL,
    [CommonJournalBatchDetailId] BIGINT         NULL,
    [CustomerTypeId]             INT            NULL,
    [CustomerType]               VARCHAR (50)   NULL,
    [CustomerId]                 BIGINT         NULL,
    [CustomerName]               VARCHAR (100)  NULL,
    [ItemMasterId]               BIGINT         NULL,
    [PartId]                     BIGINT         NULL,
    [PartNumber]                 NVARCHAR (100) NULL,
    [LeaseHeaderId]              BIGINT         NULL,
    [LeaseNumber]                VARCHAR (50)   NULL,
    [LeaseStocklineId]           BIGINT         NULL,
    [StocklineId]                BIGINT         NULL,
    [StocklineNumber]            VARCHAR (50)   NULL,
    [DocumentId]                 BIGINT         NULL,
    [DocumentNumber]             VARCHAR (50)   NULL,
    [LineType]                   VARCHAR (50)   NULL,
    [ARControlNumber]            VARCHAR (50)   NULL,
    [CustomerRef]                VARCHAR (MAX)  NULL,
    [MasterCompanyId]            INT            NULL,
    [CreatedBy]                  VARCHAR (256)  NULL,
    [CreatedDate]                DATETIME2 (7)  CONSTRAINT [DF_LeaseBatchDetails_CreatedDate] DEFAULT (getutcdate()) NOT NULL,
    CONSTRAINT [PK_LeaseBatchDetails] PRIMARY KEY CLUSTERED ([LeaseBatchDetailId] ASC)
);


GO
CREATE NONCLUSTERED INDEX [IX_LeaseBatchDetails_DocumentId]
    ON [dbo].[LeaseBatchDetails]([DocumentId] ASC, [LeaseHeaderId] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_LeaseBatchDetails_CommonJournalBatchDetailId]
    ON [dbo].[LeaseBatchDetails]([CommonJournalBatchDetailId] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_LeaseBatchDetails_LeaseHeaderId]
    ON [dbo].[LeaseBatchDetails]([LeaseHeaderId] ASC)
    INCLUDE([CommonJournalBatchDetailId], [DocumentId]);

