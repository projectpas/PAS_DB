CREATE TABLE [dbo].[NonPOInvoiceBatchDetails] (
    [NonPOInvoiceBatchDetailsId] BIGINT        IDENTITY (1, 1) NOT NULL,
    [JournalBatchDetailId]       BIGINT        NULL,
    [JournalBatchHeaderId]       BIGINT        NULL,
    [CommonJournalBatchDetailId] BIGINT        NULL,
    [VendorId]                   BIGINT        NULL,
    [VendorName]                 VARCHAR (150) NULL,
    [NonPOInvoiceId]             BIGINT        NULL,
    [NPONumber]                  VARCHAR (150) NULL,
    [Memo]                       VARCHAR (500) NULL,
    CONSTRAINT [PK_NonPOInvoiceBatchDetails] PRIMARY KEY CLUSTERED ([NonPOInvoiceBatchDetailsId] ASC)
);

