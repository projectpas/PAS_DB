CREATE TABLE [dbo].[VendorProformaInvoiceBatchDetails] (
    [VendorProformaInvoiceBatchDetailsId] BIGINT        IDENTITY (1, 1) NOT NULL,
    [JournalBatchDetailId]                BIGINT        NULL,
    [JournalBatchHeaderId]                BIGINT        NULL,
    [CommonJournalBatchDetailId]          BIGINT        NULL,
    [VendorId]                            BIGINT        NULL,
    [VendorName]                          VARCHAR (150) NULL,
    [VendorProformaInvoiceId]             BIGINT        NULL,
    [VendorProformaInvoiceNo]             VARCHAR (150) NULL,
    [Memo]                                VARCHAR (500) NULL,
    CONSTRAINT [PK_VendorProformaInvoiceBatchDetails] PRIMARY KEY CLUSTERED ([VendorProformaInvoiceBatchDetailsId] ASC)
);

